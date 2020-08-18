//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

output "db_names" {
  description = "The db names as an ordered list"
  value       = azurerm_postgresql_database.main.*.name
}

output "server_name" {
  description = "The server name"
  value       = azurerm_postgresql_server.main.name
}

output "db_ids" {
  description = "The db ids as an ordered list"
  value       = azurerm_postgresql_database.main.*.id
}

output "server_id" {
  description = "The server id."
  value       = azurerm_postgresql_server.main.id
}

output "server_fqdn" {
  description = "The server FQDN"
  value       = azurerm_postgresql_server.main.fqdn
}