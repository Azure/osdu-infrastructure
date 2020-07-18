# Module network

A terraform module that provisions networks with the following characteristics: 

- Vnet and Subnets with DNS Prefix


## Usage

```
module "resource_group" {
  source = "github.com/azure/osdu-infrastructure/modules/resource-group"

  name     = "osdu-module"
  location = "eastus2"
}


module "network" {
    source = "github.com/azure/osdu-infrastructure/modules/network"

    name                = "osdu-module-vnet-${module.resource_group.random}"
    resource_group_name = module.resource_group.name
    address_space       = "10.0.1.0/24"
    dns_servers         = ["8.8.8.8"]
    subnet_prefixes     = ["10.0.1.0/26", "10.0.1.64/26", "10.0.1.128/26", "10.0.1.192/27", "10.0.1.224/28"]
    subnet_names        = ["Web-Tier", "App-Tier", "Data-Tier", "Mgmt-Tier", "GatewaySubnet"]

    # Tags
    resource_tags = {
      osdu = "module"
    }
}
```

## Inputs

| Variable Name                     | Type       | Description                          | 
| --------------------------------- | ---------- | ------------------------------------ |
| `name`                            | _string_   | The name of the web app service.     |
| `resource_group_name`             | _string_   | The name of an existing resource group. |
| `resource_tags`                   | _list_     | Map of tags to apply to taggable resources in this module. |
| `address_space`                   | _string_   | The address space that is used by the virtual network. Default: `10.0.0.0/16` |
| `dns_servers`                     | _list_     | The DNS servers to be used with vNet. |
| `subnet_prefixes`                 | _list_     | The address prefix to use for the subnet. Default: `["10.0.1.0/24"]`
| `subnet_names`                    | _list_     | A list of public subnets inside the vNet. Default: `["subnet1"]`


## Outputs

Once the deployments are completed successfully, the output for the current module will be in the format mentioned below:

- `id`: The virtual network Id.
- `name`: The Application Insights Instrumentation Key.
- `address_space`: The address space of the virtual network.
- `subnets`: The ids of subnets created inside the virtual network.


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