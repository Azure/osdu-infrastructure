# osdu-infrastructure

[![Go Report Card](https://goreportcard.com/badge/github.com/azure/osdu-infrastructure)](https://goreportcard.com/report/github.com/azure/osdu-infrastructure)

This project is an implementation of the Infrastructure as Code and Pipelines necessary to build and deploy the required infrastructure necessary for the [Open Subsurface Data Universe](https://community.opengroup.org/osdu) (OSDU).  Project Development for this code base is performed and maintained on osdu-infrastructure in [GitHub](http://github.com/azure/osdu-infrastructure) with a mirrored copy located in [GitLab](https://community.opengroup.org/osdu/platform/deployment-and-operations/infrastructure-templates).

All patterns for this have been built and leverage to Microsoft Projects, for detailed design principals, operation and tutorials and those patterns it is best to review information directly from those projects.

1. [Project Cobalt](https://github.com/microsoft/cobalt)
2. [Project Bedrock](https://github.com/microsoft/bedrock)

## Getting Started

__Prerequisites__

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) installed or alternately [Azure Cloud Shell](https://shell.azure.com/).

  >Assumes CLI Version = azure-cli (2.0.75)

__Execute Install Script__

The script ./scripts/install.sh will conveniently setup the common things that are necessary to execute a pipeline.

```bash
cd scripts
ARM_SUBSCRIPTION_ID="<your_subscription>" ./install.sh
```

### Installed Common Resources

1. Resource Group
2. Storage Account
3. Key Vault
4. Service Principal (Elevated)
5. 2 Applications for Integration Testing

__Setup a Elevated Permissions Service Principal__

The installed service principal `osdu-deploy-XXX` must now be given access to the following API's.

    - Azure Active Directory Graph - Application.ReadWrite.OwnedBy
    - Microsoft Graph - Application.ReadWrite.OwnedBy

__Elastic Search Setup__

Elastic Search Service is required by the Infrastructure and information must be stored in the KeyVault.

```bash
# NOTE: UNIQUE is the 3 digit Random Number assigned
VAULT="osdu-kv-${UNIQUE}"
ENV="int"
az keyvault secret set --vault-name $VAULT --name "elastic-endpoint-ado-${ENV}" --value <ed_endpoint>
az keyvault secret set --vault-name $VAULT --name "elastic-username-ado-${ENV}" --value <es_username>
az keyvault secret set --vault-name $VAULT --name "elastic-password-ado-${ENV}" --value <es_password>

# Dump to Output all secrets
for i in `az keyvault secret list --vault-name $VAULT | jq  --raw-output '.[]|(.id / "/")[4]'`
do 
  az keyvault secret show --vault-name $VAULT --name $i 
done | jq --raw-output '[(.id / "/")[4], .value] | join("=")'

az keyvault secret show --name "ExamplePassword" --vault-name "Contoso-Vault2"
```



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
Copyright � Microsoft Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.