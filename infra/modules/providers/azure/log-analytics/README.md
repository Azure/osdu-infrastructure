# Module Azure Log Analytics

Module for creating and managing a Log Analytics Workspace.

## Usage

```
module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = "eastus2"
}

module "log_analytics" {
  source = "../"

  name                = "osdu-module-logs-${module.resource_group.random}"
  resource_group_name = module.resource_group.name

  solutions = [
    {
        solution_name = "ContainerInsights",
        publisher = "Microsoft",
        product = "OMSGallery/ContainerInsights",
    }
  ]

  # Tags
  resource_tags = {
    osdu = "module"
  }
}
```

### Input Variables

Please refer to [variables.tf](./variables.tf).

### Output Variables

Please refer to [output.tf](./output.tf).


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