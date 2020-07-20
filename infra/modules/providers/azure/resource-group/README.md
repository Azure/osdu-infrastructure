# Module Azure Resource Group

Module for creating and managing Azure Resource Groups.

## Usage

```
module "resource_group" {
  source = "github.com/azure/osdu-infrastructure/modules/resource-group"

  name     = "osdu-module"
  location = "eastus2"

  resource_tags = {
    environment = "test-environment"
  } 
}
```

## Inputs

| Variable Name                     | Type       | Description                          | 
| --------------------------------- | ---------- | ------------------------------------ |
| `name`                            | _string_   | The name of the web app service.     |
| `location`                        | _string_   | The location of the resource group.  |
| `resource_tags`                   | _list_     | Map of tags to apply to taggable resources in this module. |


## Outputs

Once the deployments are completed successfully, the output for the current module will be in the format mentioned below:

- `name`: The name of the Resource Group.
- `location`: The location of the Resource Group.
- `id`: The id of the Resource Group.
- `random`: A random string derived from the Resource Group.


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