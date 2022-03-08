# Module Azure Container Registry

Simplify container development by easily storing and managing container images for Azure deployments in a central registry. Azure Container Registry allows you to build, store, and manage images for all types of container deployments.

More information for Azure Container Registry can be found [here](https://azure.microsoft.com/en-us/services/container-registry/)

A terraform module in Cobalt to provide the Container Registry with the following characteristics:

- Ability to specify resource group name in which the Container Registry is deployed.
- Ability to specify resource group location in which the Azure Container Registry is deployed.
- Also gives ability to specify the following for Azure Container Registry based on the requirements:
  - name : (Required) Specifies the name of the Container Registry. Changing this forces a new resource to be created.
  - resource_group_name : (Required) The name of the resource group in which to create the Container Registry. Changing this forces a new resource to be created.
  - location : (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  - admin_enabled : (Optional) Specifies whether the admin user is enabled. Defaults to false.
  - sku : (Optional) The SKU name of the the container registry. Possible values are Basic, Standard and Premium.
  - tags : (Optional) A mapping of tags to assign to the resource.

Please click the [link](https://www.terraform.io/docs/providers/azurerm/r/container_registry.html) to get additional details on settings in Terraform for Azure Container Registry.

## Usage

### Module Definitions

- Container Registry Module        : infra/modules/providers/azure/container-registry

```
module "container_registry" {
  source                           = "github.com/Microsoft/cobalt/infra/modules/providers/azure/container-registry"
  container_registry_name          = "test-container_registry-name"
  resource_group_name              = ${azurerm_resource_group.container_registry.name} 
  container_registry_sku           = "Basic" | "Standard" | "Premium"
  container_registry_admin_enabled = true | false
  container_registry_tags          = {test:test}
}
```
## Outputs

Once the deployments are completed successfully, the output for the current module will be in the format mentioned below:

```hcl
Outputs:

container_registry_id             = <container_egistryid>
container_registry_login_server   = <containerregistryloginserver>
container_registry_admin_username = <containerregistryadminusername>
```


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