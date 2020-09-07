# Azure OSDU R3 MVP Architecture supporting Data Partitions

The `osdu` - R3 MVP Architecture solution template is intended to provision Managed Kubernetes resources like AKS and other core OSDU cloud managed services like Cosmos, Blob Storage and Keyvault. 

We decided to create another configuration that will support data partitions due to the complexity of migrating the osdu-r3-resources architecture to support data partitions without incurring a lot of breaking changes.

## Use-Case



## Scenarios this template should avoid




## Cloud Resource Architecture

![Architecture](./docs/images/architecture.png "Architecture")




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