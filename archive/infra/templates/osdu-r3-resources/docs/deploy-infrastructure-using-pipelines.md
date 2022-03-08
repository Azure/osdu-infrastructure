# Deploying OSDU Infrastructure Using Azure Devops Pipelines

## Elastic Search Setup

Infrastructure assumes bring your own Elastic Search Instance at a version of `6.8.x` and access information must be stored in a Common KeyVault.


```bash
AZURE_VAULT="<your_keyvault>"
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-endpoint-osdu-r3-env" --value <your_es_endpoint>
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-username-osdu-r3-env" --value <your_es_username>
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-password-osdu-r3-env" --value <your_es_password>

# This command will extract all Key Vault Secrets
for i in `az keyvault secret list --vault-name $AZURE_VAULT --query [].id -otsv`
do
   echo "export ${i##*/}=\"$(az keyvault secret show --vault-name $AZURE_VAULT --id $i --query value -otsv)\""
done

```
> The Elastic endpoint provided should include `https` and the appropriate port number. A `http` endpoint will not work. 

## Configure Azure DevOps Service Connection

- Configure an [ARM Resources Service Connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops)
with name `osdu-infrastructure` for the desired subscription.
> ADO -> Project Settings -> Service Connection -> New service connection -> Azure Resource Manager -> Service principal (automatic)

  - Scope should be to the desired Subscription but do not apply scope to a Resource Group

- Locate the Service Principal created (<organization-project-subscription>) in Azure Active Directory and elevate the principal capability by adding in 2 API Permissions
  - Azure Active Directory Graph - Application.ReadWrite.OwnedBy
  - Microsoft Graph - Application.ReadWrite.OwnedBy

> These 2 API's require `Grant Admin Consent`


## Setup ADO required Libraries

- Setup and Configure the ADO Library `Infrastructure Pipeline Variables`

  | Variable | Value |
  |----------|-------|
  | AGENT_POOL | Hosted Ubuntu 1604 |
  | BUILD_ARTIFACT_NAME | osdu-infrastructure |
  | SERVICE_CONNECTION_NAME | osdu-infrastructure |
  | TF_VAR_elasticsearch_secrets_keyvault_name | osducommon<your_unique>-kv |
  | TF_VAR_elasticsearch_secrets_keyvault_resource_group | osdu-common-<your_unique> |
  | TF_VAR_remote_state_account | osducommon<your_unique> |
  | TF_VAR_remote_state_container | remote-state-container |

- Setup and Configure the ADO Library `Infrastructure Pipeline Variables - env`

  | Variable | Value |
  |----------|-------|
  | ARM_SUBSCRIPTION_ID | <your_subscription_id> |
  | TF_VAR_aks_agent_vm_count | 3 |
  | TF_VAR_common_resources_workspace_name | cr-env |
  | TF_VAR_cosmosdb_replica_location | eastus2 |
  | TF_VAR_data_resources_workspace_name | dr-env |
  | TF_VAR_elasticsearch_version | 6.8.12 |
  | TF_VAR_gitops_branch | master |
  | TF_VAR_gitops_ssh_url | git@<your_flux_manifest_repo> |
  | TF_VAR_resource_group_location | centralus |

> You can specify the desired region locations you wish. Change the Elastic version as required.

- Setup and Configure the ADO Library `Infrastructure Pipeline Secrets - env`

  | Variable | Value |
  |----------|-------|
  | elastic-endpoint-osdu-r3-env | `*********` |
  | elastic-username-osdu-r3-env | `*********` |
  | elastic-password-osdu-r3-env | `*********` |

> This should be linked Secrets from Azure Key Vault `osducommon<your_unique>-kv`

- Setup 2 Secure Files
  - azure-aks-gitops-ssh-key
  - azure-aks-node-ssh-key.pub

> These files were created above.

- Add a Pipeline __osdu-infrastructure-r3-common__ -->  `azure-pipeline-common.yml` and execute it.

- Add a Pipeline __osdu-infrastructure-r3-data__ -->  `azure-pipeline-data.yml` and execute it.

- Add a Pipeline __osdu-infrastructure-r3-services__ -->  `azure-pipeline-services.yml` and execute it.

- Once Infrastructure is deployed grant admin_consent to the Service Principal.