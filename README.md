# osdu-infrastructure


[![Go Report Card](https://goreportcard.com/badge/github.com/Azure/osdu-infrastructure)](https://goreportcard.com/report/github.com/Azure/osdu-infrastructure)

This project is an implementation of the Infrastructure as Code and Pipelines necessary to build and deploy the required infrastructure necessary for the [Open Subsurface Data Universe](https://community.opengroup.org/osdu) (OSDU). Links and additional information is located in [GitLab](https://community.opengroup.org/osdu/platform/deployment-and-operations/infrastructure-templates) for OSDU discoverability.


Patterns used leverage Microsoft Projects, for detailed design principals, operation and tutorials on these patterns it is best to review information directly from those projects. 

1. [Project Cobalt](https://github.com/microsoft/cobalt)
2. [Project Bedrock](https://github.com/microsoft/bedrock)

Please be aware that branching strategies are aligned with OSDU and the master branch is intended to be used as a [Current Delivery](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-continuous-delivery) mechanism that aligns with master branches for the [OSDU Platform]((https://community.opengroup.org/osdu/platform))

## Architecture Solutions
This project is an active project and the master branch is constantly changing to support OSDU features. Rhe master branch is intended to be in sync with the master branches of the OSDU Service branches.

This project holds 2 different Solution Architectures for OSDU on Azure.

- [R3 - Azure OSDU AKS Architecture Solution with Elastic Cloud SaaS](infra/templates/osdu-r3-resources)  

  _common-resources_  
  [![Build Status](https://dev.azure.com/osdu-demo/OSDU_Rx/_apis/build/status/github-osdu-infrastructure-r3-cr?branchName=master)](https://dev.azure.com/osdu-demo/OSDU_Rx/_build/latest?definitionId=1186&branchName=master)

  _data-resources_  
  [![Build Status](https://dev.azure.com/osdu-demo/OSDU_Rx/_apis/build/status/github-osdu-infrastructure-r3-dr?branchName=master)](https://dev.azure.com/osdu-demo/OSDU_Rx/_build/latest?definitionId=1190&branchName=master) 

  _service-resources_  
  [![Build Status](https://dev.azure.com/osdu-demo/OSDU_Rx/_apis/build/status/github-osdu-infrastructure-r3-sr?branchName=master)](https://dev.azure.com/osdu-demo/OSDU_Rx/_build/latest?definitionId=1191&branchName=master)

- [R2 - Azure OSDU AppService Architecture Solution with Elastic Cloud SaaS](infra/templates/osdu-r2-resources)

  _osdu-r2-resources_  
  [![Build Status](https://dev.azure.com/osdu-demo/OSDU_Rx/_apis/build/status/osdu-infrastructure-integration?branchName=master)](https://dev.azure.com/osdu-demo/OSDU_Rx/_build/latest?definitionId=892&branchName=master) 



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
