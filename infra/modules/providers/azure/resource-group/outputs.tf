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

output "name" {
  description = "The name of the Resource Group."
  value       = "${azurerm_resource_group.main.name}"
}

output "location" {
  description = "The location of the Resource Group."
  value       = "${azurerm_resource_group.main.location}"
}

output "id" {
  description = "The id of the Resource Group."
  value       = "${azurerm_resource_group.main.id}"
}

output "random" {
  description = "A random string derived from the Resource Group."
  value       = "${random_id.main.hex}"
}