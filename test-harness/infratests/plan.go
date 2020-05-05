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

/*
Package infratests this file provides a model for the JSON representation of a terraform plan. It describes
a minimal set of metadata produced by the plan and can be expanded to support other attributes
if needed
*/
package infratests

// TerraformPlan a JSON schema for the output of `terraform plan <planfile>`
type TerraformPlan struct {
	ResourceChanges []struct {
		Address string `json:"address"`
		Change  struct {
			Actions []string               `json:"actions"`
			After   map[string]interface{} `json:"after"`
		} `json:"change"`
	} `json:"resource_changes"`
}
