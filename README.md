# osdu-infrastructure

[![Build Status](https://dev.azure.com/osdu-demo/OSDU_Rx/_apis/build/status/osdu-infrastructure-integration?branchName=master)](https://dev.azure.com/osdu-demo/OSDU_Rx/_build/latest?definitionId=892&branchName=master)
[![Go Report Card](https://goreportcard.com/badge/github.com/Azure/osdu-infrastructure)](https://goreportcard.com/report/github.com/Azure/osdu-infrastructure)

This project is an implementation of the Infrastructure as Code and Pipelines necessary to build and deploy the required infrastructure necessary for the [Open Subsurface Data Universe](https://community.opengroup.org/osdu) (OSDU).  Project Development for this code base is performed and maintained on osdu-infrastructure in [GitHub](http://github.com/azure/osdu-infrastructure) with a mirrored copy located in [GitLab](https://community.opengroup.org/osdu/platform/deployment-and-operations/infrastructure-templates).

All patterns for this have been built and leverage to Microsoft Projects, for detailed design principals, operation and tutorials and those patterns it is best to review information directly from those projects.

1. [Project Cobalt](https://github.com/microsoft/cobalt)
2. [Project Bedrock](https://github.com/microsoft/bedrock)

## BootStrap a Pipeline

_Eventually a bootstrap process will be handled by an [ado terraform provider](https://github.com/microsoft/terraform-provider-azuredevops) but for now this is a manual process._

__Prerequisites__

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) installed or alternately [Azure Cloud Shell](https://shell.azure.com/).

  >Assumes CLI Version = azure-cli (2.0.75)

__Execute Install Script__

The script ./scripts/install.sh will conveniently setup the common things that are necessary to execute a pipeline.


```bash
cd scripts
./install.sh <your_subscription> <unique_alphanumeric>
```

### Installed Common Resources 

1. Resource Group
2. Storage Account
3. Key Vault
4. Applications for Integration Testing (2)

__Elastic Search Setup__

Infrastructure assumes bring your own Elastic Search Instance at a version of `6.8.3` and access information must be stored in the Common KeyVault.

```bash
AZURE_VAULT="<your_keyvault>"
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-endpoint-ado-demo" --value <your_es_endpoint>
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-username-ado-demo" --value <your_es_username>
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-password-ado-demo" --value <your_es_password>

# Dump all secrets to output
for i in `az keyvault secret list --vault-name $AZURE_VAULT --query [].id -otsv`
do
   echo "export ${i##*/}=\"$(az keyvault secret show --vault-name $AZURE_VAULT --id $i --query value -otsv)\""
done
```

### Configure Azure DevOps


1. Create a new ADO Project in your organization called `osdu-r2`
2. Import the osdu-infrastructure to the ADO Project Repo from this URL `https://github.com/Azure/osdu-infrastructure.git`
3. Configure an ARM Resources Service Connection for the desired subscription.
    > This will create a Service Principal.
4. Configure Service Principal API permissions.
    - Azure Active Directory Graph - Application.ReadWrite.OwnedBy
    - Microsoft Graph - Application.ReadWrite.OwnedBy
5. Setup and Configure the ADO Library `Infrastructure Pipeline Variables`
    - AGENT_POOL = `Hosted Ubuntu 1604`
    - BUILD_ARTIFACT_NAME = `infra-templates`
    - SERVICE_CONNECTION_NAME = <your_service_connection_name>
    - TF_VAR_elasticsearch_secrets_keyvault_name = `osducommon<your_unique>-kv`
    - TF_VAR_elasticsearch_secrets_keyvault_resource_group = `osdu-common-<your_unique>`
    - TF_VAR_remote_state_account = `osducommon<your_unique>`
    - TF_VAR_remote_state_container = `remote-state-container`
6. Setup and Configure the ADO Library `Infrastructure Pipeline Variables - demo`
    - ARM_SUBSCRIPTION_ID = `<your_subscription_id>`
    - TF_VAR_cosmosdb_replica_location = `eastus2`
    - TF_VAR_resource_group_location = `centralus`
7. Setup and Configure the ADO Library `Infrastructure Pipeline Secrets - demo`
    > This should be linked Secrets from Azure Key Vault `osducommon<your_unique>-kv`
    - elastic-endpoint-ado-demo = `*********`
    - elastic-username-ado-demo = `*********`
    - elastic-password-ado-demo = `*********`
8. Setup 2 Secure Files
    > This is for future AKS work but the keys will be located after running install.sh in the scripts/.ssh directory
    - azure-aks-gitops-ssh-key
    - azure-aks-node-ssh-key.pub
9. Create a New Azure Pipeline from the Azure Repo using the pipeline `/azure-pipeline.yml`
10. Run the Pipeline and the Infrastructure will deploy
    > Pipelines automatically check for changes. Set a runtime variable of FORCE_RUN=true to bypass Change Detection.


# Contributing

We do not claim to have all the answers and would greatly appreciate your ideas and pull requests.

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

For project level questions, please contact [Daniel Scholl](mailto:Daniel.Scholl@microsoft.com) or [Dania Kodeih](mailto:Dania.Kodeih@microsoft.com).


## License
Copyright © Microsoft Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.