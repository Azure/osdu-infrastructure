# osdu-infrastructure

[![Build Status](https://dev.azure.com/osdu-demo/OSDU_Rx/_apis/build/status/osdu-infrastructure-integration?branchName=master)](https://dev.azure.com/osdu-demo/OSDU_Rx/_build/latest?definitionId=892&branchName=master)
[![Go Report Card](https://goreportcard.com/badge/github.com/Azure/osdu-infrastructure)](https://goreportcard.com/report/github.com/Azure/osdu-infrastructure)

This project is an implementation of the Infrastructure as Code and Pipelines necessary to build and deploy the required infrastructure necessary for the [Open Subsurface Data Universe](https://community.opengroup.org/osdu) (OSDU).  Project Development for this code base is performed and maintained on osdu-infrastructure here in [GitHub](http://github.com/azure/osdu-infrastructure) with some information also located in [GitLab](https://community.opengroup.org/osdu/platform/deployment-and-operations/infrastructure-templates) in order for this project to be discoverable to OSDU.

All patterns for this have been built and leverage Microsoft Projects, for detailed design principals, operation and tutorials on those patterns it is best to review information directly from those projects. Code and modules have been forked and located here with no direct references in terraform modules to code outside of this project space.

1. [Project Cobalt](https://github.com/microsoft/cobalt)
2. [Project Bedrock](https://github.com/microsoft/bedrock)


## Architecture Solutions
Currently this project holds 2 different Solution Architectures for OSDU on Azure.

- [R3 - Azure OSDU AKS Architecture Solution with Elastic Cloud SaaS](infra/templates/osdu-r3-resources)
- [R2 - Azure OSDU AppService Architecture Solution with Elastic Cloud SaaS](infra/templates/osdu-r2-resources)

> IMPORTANT: Current OSDU releases should only use the AppService Architecture at this time until R3 is officially released.


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



[0]: ./docs/osdu/images/r2_arch.png "R2 Infrastructure Architecture"