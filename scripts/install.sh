#!/usr/bin/env bash
#
#  Purpose: Initialize the common resources for osdu-infrastructure
#  Usage:
#    install.sh


###############################
## ARGUMENT INPUT            ##
###############################

usage() { echo "Usage: install.sh <subscription_id> <unique>" 1>&2; exit 1; }

if [ ! -z $1 ]; then ARM_SUBSCRIPTION_ID=$1; fi
if [ -z $ARM_SUBSCRIPTION_ID ]; then
  tput setaf 1; echo 'ERROR: ARM_SUBSCRIPTION_ID not provided' ; tput sgr0
  usage;
fi

if [ ! -z $2 ]; then UNIQUE=$2; fi
if [ -z $UNIQUE ]; then
  UNIQUE=$(echo $((RANDOM%999+100)))
  echo "export UNIQUE=${UNIQUE}" >> .envrc
fi

if [ -z $AZURE_LOCATION ]; then
  AZURE_LOCATION="centralus"
fi

if [ -z $AZURE_GROUP ]; then
  AZURE_GROUP="osdu-common-${UNIQUE}"
fi

if [ -z $AZURE_STORAGE ]; then
  AZURE_STORAGE="osducommon${UNIQUE}"
fi

if [ -z $AZURE_VAULT ]; then
  AZURE_VAULT="osducommon${UNIQUE}-kv"
fi

if [ -z $REMOTE_STATE_CONTAINER ]; then
  REMOTE_STATE_CONTAINER="remote-state-container"
fi

if [ -z $AZURE_AKS_USER ]; then
  AZURE_AKS_USER="osdu.${UNIQUE}"
fi



###############################
## FUNCTIONS                 ##
###############################
function CreateResourceGroup() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (LOCATION) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az group show --name $1)
  if [ "$_result"  == "" ]
    then
      OUTPUT=$(az group create --name $1 \
        --location $2 \
        -ojsonc)
      LOCK=$(az group lock create --name "OSDU-PROTECTED" \
        --resource-group $1 \
        --lock-type CanNotDelete \
        -ojsonc) 
    else
      tput setaf 3;  echo "Resource Group $1 already exists."; tput sgr0
    fi
}
function CreateServicePrincipal() {
    # Required Argument $1 = PRINCIPAL_NAME
    # Required Argument $2 = VAULT_NAME
    # Required Argument $3 = true/false (Add Scope)

    if [ -z $1 ]; then
        tput setaf 1; echo 'ERROR: Argument $1 (PRINCIPAL_NAME) not received'; tput sgr0
        exit 1;
    fi

    local _result=$(az ad sp list --display-name $1 --query [].appId -otsv)
    if [ "$_result"  == "" ]
    then

      PRINCIPAL_SECRET=$(az ad sp create-for-rbac \
        --name $1 \
        --skip-assignment \
        --role owner \
        --scopes subscription/${ARM_SUBSCRIPTION_ID} \
        --query password -otsv)

      PRINCIPAL_ID=$(az ad sp list \
        --display-name $1 \
        --query [].appId -otsv)

      # Azure AD Graph API Access Application.ReadWrite.OwnedBy
      AD_GRAPH_API=$(az ad app permission add \
        --id $PRINCIPAL_ID \
        --api 00000002-0000-0000-c000-000000000000 \
        --api-permissions 824c81eb-e3f8-4ee6-8f6d-de7f50d565b7=Role \
        -ojsonc)

      # MS Graph API Application.ReadWrite.OwnedBy
      MS_GRAPH_API=$(az ad app permission add \
        --id $PRINCIPAL_ID \
        --api 00000003-0000-0000-c000-000000000000 \
        --api-permissions 18a4783c-866b-4cc7-a460-3d5e5662c884=Role \
        -ojsonc)

      # MS Graph API User.Read | Delegated
      MS_GRAPH=$(az ad app permission add \
        --id $PRINCIPAL_ID \
        --api 00000003-0000-0000-c000-000000000000 \
        --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope \
        -ojsonc)

      tput setaf 2; echo "Adding AD Application Credentials to Vault..." ; tput sgr0
      AddKeyToVault $2 "${1}-id" $PRINCIPAL_ID
      AddKeyToVault $2 "${1}-key" $PRINCIPAL_SECRET

    else
        tput setaf 3;  echo "Service Principal $1 already exists."; tput sgr0
    fi
}
function CreateADApplication() {
    # Required Argument $1 = APPLICATION_NAME
    # Required Argument $2 = VAULT_NAME

    if [ -z $1 ]; then
        tput setaf 1; echo 'ERROR: Argument $1 (APPLICATION_NAME) not received'; tput sgr0
        exit 1;
    fi

    local _result=$(az ad sp list --display-name $1 --query [].appId -otsv)
    if [ "$_result"  == "" ]
    then
      $APP_SECRET=$(az ad sp create-for-rbac \
        --name "${1}" \
        --skip-assignment \
        --query password -otsv)
      $APP_ID=$(az ad sp list \
        --display-name "${1}" \
        --query [].appId -otsv)

      tput setaf 2; echo "Adding AD Application to Vault..." ; tput sgr0
      AddKeyToVault $2 "${1}-id" $APP_ID
      AddKeyToVault $2 "${1}-key" $APP_SECRET

    else
        tput setaf 3;  echo "AD Application $1 already exists."; tput sgr0
    fi
}
function CreateSSHKeys() {
  # Required Argument $1 = SSH_USER
  # Required Argument $2 = KEY_NAME

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (SSH_USER) not received'; tput sgr0
    exit 1;
  fi

  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (KEY_NAME) not received'; tput sgr0
    exit 1;
  fi

  if [ ! -d ./.ssh ]
  then
    mkdir .ssh
  fi

  if [ -f ./.ssh/$2 ]; then
    tput setaf 3;  echo "SSH Keys already exist."; tput sgr0
  else
    cd .ssh

    PASSPHRASE=$(echo $((RANDOM%20000000000000000000+100000000000000000000)))
    ssh-keygen -t rsa -b 2048 -C $1 -f $2 -N $PASSPHRASE && cd ..
    AddKeyToVault $AZURE_VAULT "${2}-passphrase" $PASSPHRASE
  fi

  AddKeyToVault $AZURE_VAULT "${2}" ".ssh/${2}" "file"
  AddKeyToVault $AZURE_VAULT "${2}-pub" ".ssh/${2}.pub" "file"

 _result=`cat ./.ssh/${2}.pub`
 echo $_result
}

function CreateKeyVault() {
  # Required Argument $1 = KV_NAME
  # Required Argument $2 = RESOURCE_GROUP
  # Required Argument $3 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (KV_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (LOCATION) not received' ; tput sgr0
    exit 1;
  fi

  local _vault=$(az keyvault list --resource-group $2 --query [].name -otsv)
  if [ "$_vault"  == "" ]
    then
      OUTPUT=$(az keyvault create --name $1 --resource-group $2 --location $3 --query [].name -otsv)
    else
      tput setaf 3;  echo "Key Vault $1 already exists."; tput sgr0
    fi
}
function CreateStorageAccount() {
  # Required Argument $1 = STORAGE_ACCOUNT
  # Required Argument $2 = RESOURCE_GROUP
  # Required Argument $3 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (STORAGE_ACCOUNT) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (LOCATION) not received' ; tput sgr0
    exit 1;
  fi

  local _storage=$(az storage account show --name $1 --resource-group $2 --query name -otsv)
  if [ "$_storage"  == "" ]
      then
      OUTPUT=$(az storage account create \
        --name $1 \
        --resource-group $2 \
        --location $3 \
        --sku Standard_LRS \
        --kind StorageV2 \
        --encryption-services blob \
        --query name -otsv)
      else
        tput setaf 3;  echo "Storage Account $1 already exists."; tput sgr0
      fi
}
function GetStorageAccountKey() {
  # Required Argument $1 = STORAGE_ACCOUNT
  # Required Argument $2 = RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (STORAGE_ACCOUNT) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az storage account keys list \
    --account-name $1 \
    --resource-group $2 \
    --query '[0].value' \
    --output tsv)
  echo ${_result}
}
function CreateBlobContainer() {
  # Required Argument $1 = CONTAINER_NAME
  # Required Argument $2 = STORAGE_ACCOUNT
  # Required Argument $3 = STORAGE_KEY

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (CONTAINER_NAME) not received' ; tput sgr0
    exit 1;
  fi

  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (STORAGE_ACCOUNT) not received' ; tput sgr0
    exit 1;
  fi

  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (STORAGE_KEY) not received' ; tput sgr0
    exit 1;
  fi

  local _container=$(az storage container show --name $1 --account-name $2 --account-key $3 --query name -otsv)
  if [ "$_container"  == "" ]
      then
        OUTPUT=$(az storage container create \
              --name $1 \
              --account-name $2 \
              --account-key $3 -otsv)
        if [ $OUTPUT == True ]; then
          tput setaf 3;  echo "Storage Container $1 created."; tput sgr0
        else
          tput setaf 1;  echo "Storage Container $1 not created."; tput sgr0
        fi
      else
        tput setaf 3;  echo "Storage Container $1 already exists."; tput sgr0
      fi
}
function AddKeyToVault() {
  # Required Argument $1 = KEY_VAULT
  # Required Argument $2 = SECRET_NAME
  # Required Argument $3 = SECRET_VALUE
  # Optional Argument $4 = isFile (bool)

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (KEY_VAULT) not received' ; tput sgr0
    exit 1;
  fi

  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (SECRET_NAME) not received' ; tput sgr0
    exit 1;
  fi

  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (SECRET_VALUE) not received' ; tput sgr0
    exit 1;
  fi

  if [ "$4" == "file" ]; then
    local _secret=$(az keyvault secret set --vault-name $1 --name $2 --file $3)
  else
    local _secret=$(az keyvault secret set --vault-name $1 --name $2 --value $3)  
  fi  
}


###############################
## Azure Intialize           ##
###############################

printf "\n"
tput setaf 2; echo "Creating OSDU Common Resources" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0

tput setaf 2; echo 'Logging in and setting subscription...' ; tput sgr0
az account set --subscription ${ARM_SUBSCRIPTION_ID}

tput setaf 2; echo 'Creating Resource Group...' ; tput sgr0
CreateResourceGroup $AZURE_GROUP $AZURE_LOCATION

tput setaf 2; echo "Creating the Key Vault..." ; tput sgr0
CreateKeyVault $AZURE_VAULT $AZURE_GROUP $AZURE_LOCATION

tput setaf 2; echo "Creating the Storage Account..." ; tput sgr0
CreateStorageAccount $AZURE_STORAGE $AZURE_GROUP $AZURE_LOCATION

tput setaf 2; echo "Retrieving the Storage Account Key..." ; tput sgr0
STORAGE_KEY=$(GetStorageAccountKey $AZURE_STORAGE $AZURE_GROUP)

tput setaf 2; echo "Creating the Storage Account Container..." ; tput sgr0
CreateBlobContainer $REMOTE_STATE_CONTAINER $AZURE_STORAGE $STORAGE_KEY

tput setaf 2; echo "Adding Storage Account to Vault..." ; tput sgr0
AddKeyToVault $AZURE_VAULT "${AZURE_STORAGE}-storage" $AZURE_STORAGE
AddKeyToVault $AZURE_VAULT "${AZURE_STORAGE}-storage-key" $STORAGE_KEY

tput setaf 2; echo 'Creating AD Application...' ; tput sgr0
CreateServicePrincipal "osdu-infra-${UNIQUE}-test-app" $AZURE_VAULT
CreateServicePrincipal "osdu-infra-${UNIQUE}-test-app-noaccess" $AZURE_VAULT

tput setaf 2; echo 'Creating SSH Keys...' ; tput sgr0
GITOPS_KEY="azure-aks-gitops-ssh-key"
CreateSSHKeys $AZURE_AKS_USER $GITOPS_KEY
AddKeyToVault $AZURE_VAULT "azure-aks-gitops-ssh-key" ".ssh/${GITOPS_KEY}" "file"

CreateSSHKeys $AZURE_AKS_USER "azure-aks-node-ssh-key"

tput setaf 2; echo 'Extracting Key Information...' ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0
for i in `az keyvault secret list --vault-name $AZURE_VAULT --query [].id -otsv`
do
   echo "${i##*/}=\"$(az keyvault secret show --vault-name $AZURE_VAULT --id $i --query value -otsv)\""
done 
