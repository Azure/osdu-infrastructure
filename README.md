# osdu-infrastructure


[![Go Report Card](https://goreportcard.com/badge/github.com/Azure/osdu-infrastructure)](https://goreportcard.com/report/github.com/Azure/osdu-infrastructure)

This project is an implementation of the Infrastructure as Code and Pipelines necessary to build and deploy the required infrastructure necessary for the [Open Subsurface Data Universe](https://community.opengroup.org/osdu) (OSDU). Links and additional information is located in [GitLab](https://community.opengroup.org/osdu/platform/deployment-and-operations/infrastructure-templates) for OSDU discoverability.


Patterns used here derived from concepts in other Microsoft Projects, for detailed design principals, operation and tutorials on some of these patterns it is best to review information directly from those projects. 

1. [Project Cobalt](https://github.com/microsoft/cobalt)
2. [Project Bedrock](https://github.com/microsoft/bedrock)

Please be aware that branching strategies are aligned with OSDU and the master branch is intended to be used as a [Current Delivery](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-continuous-delivery) mechanism that aligns with master branches for the [OSDU Platform]((https://community.opengroup.org/osdu/platform))

This project is an active project and the master branch changes frequently to support OSDU features.  The intent is for Master to be in sync with OSDU Service master branches.

## Architecture Solutions

- [R3 MVP - Azure OSDU R3 MVP Architecture Solution](infra/templates/osdu-r3-mvp)  

  _central-resources_  
  [![Build Status](https://dev.azure.com/osdu-demo/OSDU_Rx/_apis/build/status/github-osdu-infra-mvp-cr?branchName=master)](https://dev.azure.com/osdu-demo/OSDU_Rx/_build/latest?definitionId=1206&branchName=master)

  _service-resources_  
  [![Build Status](https://dev.azure.com/osdu-demo/OSDU_Rx/_apis/build/status/github-osdu-infra-mvp-services?branchName=master)](https://dev.azure.com/osdu-demo/OSDU_Rx/_build/latest?definitionId=1207&branchName=master)

  _data-partition_  
  [![Build Status](https://dev.azure.com/osdu-demo/OSDU_Rx/_apis/build/status/github-osdu-infra-mvp-partitions?branchName=master)](https://dev.azure.com/osdu-demo/OSDU_Rx/_build/latest?definitionId=1208&branchName=master)


- [R2 on AKS - Azure OSDU AKS Architecture Solution](infra/templates/osdu-r3-resources)  
  > Retired, no longer maintained _9/22_
  

- [R2 - Azure OSDU AppService Architecture Solution](infra/templates/osdu-r2-resources)
  > Retired, no longer maintained _9/1_



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
