# Azure OSDU R3 MVP Architecture supporting Data Partitions

The `osdu` - R3 MVP Architecture solution template is intended to provision Managed Kubernetes resources like AKS and other core OSDU cloud managed services like Cosmos, Blob Storage and Keyvault. 

We decided to create another configuration that will support data partitions due to the complexity of migrating the osdu-r3-resources architecture to support data partitions without incurring a lot of breaking changes.

## Use-Case

### 1. Bring your own service principal (BYO)
In this setup, we operate with two Service principals. One SP used by terraform, and another one should be created for service_resources.
The use-case describes two options for creating a Service Principal needed for service_resources:
- Option 1: Use "Bring your own service principal (BYO)":
    - The system allows a service principal created in an alternate manner to be provided and used. In this case, we don't have to create SP automatically which allows us not to give terraform extra permission to the Azure Active Directory and follow the principle of least privilege.
    - Means that terraform SP should not have AD permissions for creating another Service Principal.
    - One extra step is required to manually create SP in service_resources [Prerequisites](./service_resources/README.md#__PreRequisites__).
- Option 2: Don't use "Bring your own service principal (BYO)" and automatically create a new one.
    - The system should automatically create a Service Principal if one is not provided. It requires elevated permission to the Azure Active Directory.
    - Means that terraform SP should have extra AD permissions for creating another Service Principal.
    - No manual extra steps. Less secure.
> Using "Bring your own service principal (BYO)" is strongly recommended due to Security best practices.


### 2. Resource Tagging
All resources should have the ability to have a tag(s) applied to them by values set in the template terraform.tfvars.


### 3. Data Partition Key Vault Value Naming
Values for items hosted in a keyvault that are created by a Data Partition need to be prefixed with the datapartition name.


### 4. Event Grid Topic Naming
Event Grid topics are DNS unique name values.  To get the unique name the value needs to be looked up in KV.


### 5. Deployment Order
Central Resources are required to be provisioned before Service or Data Partition Resources


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