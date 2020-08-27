# Module network

A terraform module that provisions PostgreSQL databases with the following characteristics: 

## Usage

```
module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = "eastus2"
}

module "network" {
  source = "../../network"

  name                = "osdu-module-vnet-${module.resource_group.random}"
  resource_group_name = module.resource_group.name
  address_space       = "10.0.1.0/24"
  dns_servers         = ["8.8.8.8"]
  subnet_prefixes     = ["10.0.1.0/26"]
  subnet_names        = ["Web-Tier"]

  # Tags
  resource_tags = {
    osdu = "module"
  }

}

module "postgreSQL" {
  source = "../"

  resource_group_name = module.resource_group.name
  name = "osdu-module-db-${module.resource_group.random}"
  databases = [ "osdu-module-database" ]
  admin_user = "test"
  admin_password = "AzurePassword@123"

  # Tags
  resource_tags = {
    osdu = "module"
  }

  firewall_rules = [{
    start_ip = "10.0.0.2"
    end_ip = "10.0.0.8"
  }]

  vnet_rules = [{
    subnet_id = module.network.subnets[0]
  }]

  postgresql_configurations = {
    config = "test"
  }
}
```

## Inputs

| Variable Name                     | Type       | Description                          | 
| --------------------------------- | ---------- | ------------------------------------ |
| `name`                            | _string_   | The name of the postgreSQL db.     |
| `resource_group_name`             | _string_   | The name of an existing resource group. |
| `resource_tags`                   | _list_     | Map of tags to apply to taggable resources in this module. |
| `databases`                       | _list_     | The list of names of the PostgreSQL Database, which needs to be a valid PostgreSQL identifier. Changing this forces a new resource to be created. |
| `admin_user`                      | _string_   | The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created. |
| `admin_password`                  | _string_   | The Password associated with the administrator_login for the PostgreSQL Server. |
| `sku`                             | _string_   | Name of the server's SKU. Default: "GP_Gen5_4". |
| `storage_mb`                      | _int_      | Max storage allowed for a server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB). Default: 5120. |
| `server_version`                  | _string_   | Specifies the version of PostgreSQL to use. Valid values are 9.5, 9.6, and 10.0. Changing this forces a new resource to be created. Default: "10.0". |
| `backup_retention_days`           | _int_      | Number of days to retain backup data. Default: 7. |
| `geo_redundant_backup_enabled`    | _bool_     | Enable geo-redundancy. Default: true. |
| `auto_grow_enabled`               | _bool_     | Enable auto grow. Default: true. |
| `ssl_enforcement_enabled`         | _bool_     | Enable SSL enforcement. Default: true. |
| `public_network_access`           | _bool_     | Enable or Disable public network access to the VM. Default: true. |
| `db_charset`                      | _string_   | Specifies the Charset for the PostgreSQL Database, which needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created. Default: "UTF8". |
| `db_collation`                    | _string_   | Specifies the Collation for the PostgreSQL Database, which needs to be a valid PostgreSQL Collation. Note that Microsoft uses different notation - en-US instead of en_US. Changing this forces a new resource to be created. Default: "English_United States.1252". |
| `firewall_rule_prefix`            | _string_   | Specifies prefix for firewall rule names. Default: "firewall-"
| `firewall_rules`                  | _list_     | The list of maps, describing firewall rules. Valid map items: name, start_ip, end_ip. Default: [] |
| `vnet_rule_name_prefix`           | _string_   | Specifies prefix for vnet rule names. Default: "postgresql-vnet-rule-". |
| `vnet_rules`                      | _list_     | The list of maps, describing vnet rules. Valud map items: name, subnet_id. Default: []
| `postgresql_configurations`       | _map(_string_)_  | A map with PostgreSQL configurations to enable. Default: {} |


## Outputs

Once the deployments are completed successfully, the output for the current module will be in the format mentioned below:

- `db_names` : List of db names.
- `db_ids`: List of db ids.
- `server_name`: The server name.
- `server_id`: The server id.
- `server_fqdn`: The server FQDN.


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
