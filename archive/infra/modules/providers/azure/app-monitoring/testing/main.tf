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

provider "azurerm" {
  features {}
}

module "resource_group" {
  source   = "../../resource-group"
  name     = "osdu-module"
  location = "eastus2"
}

module "app_monitoring" {
  source = "../"

  resource_group_name = module.resource_group.name
  action_group_name   = var.action_group_name

  # action_group_email_receiver       = "${var.action_group_email_receiver}"
  # metric_alert_name                 = "${var.metric_alert_name}"
  # metric_alert_frequency            = "${var.metric_alert_frequency}"
  # metric_alert_period               = "${var.metric_alert_period}"
  # metric_alert_criteria_namespace   = "${var.metric_alert_criteria_namespace}"
  # metric_alert_criteria_name        = "${var.metric_alert_criteria_name}"
  # metric_alert_criteria_aggregation = "${var.metric_alert_criteria_aggregation}"
  # metric_alert_criteria_operator    = "${var.metric_alert_criteria_operator}"
  # metric_alert_criteria_threshold   = "${var.metric_alert_criteria_threshold}"
  # monitoring_dimension_values       = "${var.monitoring_dimension_values}"
}