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

output "id" {
  description = "The Log Analytics Workspace Id"
  value       = azurerm_log_analytics_workspace.main.id
}

output "name" {
  description = "The Log Analytics Workspace Name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_workspace_id" {
  value = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_workspace_key" {
  value = azurerm_log_analytics_workspace.main.primary_shared_key
}