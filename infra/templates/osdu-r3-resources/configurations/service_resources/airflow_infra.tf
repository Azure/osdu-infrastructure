locals {
  dag_storage_name       = "${replace(local.base_name_21, "-", "")}dag"
  airflow_admin_password = coalesce(var.airflow_admin_password, random_password.airflow_admin_password[0].result)
}

resource "random_password" "airflow_admin_password" {
  count = var.airflow_admin_password == "" ? 1 : 0

  length           = 8
  special          = true
  override_special = "_%@"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

#-------------------------------
# Airflow secret
#-------------------------------

resource "random_string" "airflow_fernete_key_rnd" {
  keepers = {
    postgresql_name = local.postgresql_name
  }
  length      = 32
  special     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_key_vault_secret" "airflow_fernet_key_secret" {
  name         = "airflow-fernet-key"
  value        = base64encode(random_string.airflow_fernete_key_rnd.result)
  key_vault_id = module.keyvault.keyvault_id
}

resource "azurerm_key_vault_secret" "airflow_admin_password" {
  name         = "airflow-admin-password"
  value        = local.airflow_admin_password
  key_vault_id = module.keyvault.keyvault_id
}


resource "azurerm_key_vault_secret" "airflow_remote_log_connection" {
  name         = "airflow-remote-log-connection"
  value        = format("wasb://%s:%s@", local.storage_name, urlencode(module.storage_account.primary_access_key))
  key_vault_id = module.keyvault.keyvault_id
}


#-------------------------------
# Airflow logging 
#-------------------------------
resource "azurerm_storage_queue" "airflow_log_queue" {
  name                 = "airflowlogqueue"
  storage_account_name = module.storage_account.name
}

resource "azurerm_role_assignment" "airflow_log_queue_reader_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Storage Queue Data Reader"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.storage_account.id
}

resource "azurerm_role_assignment" "airflow_log_queue_processor_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Storage Queue Data Message Processor"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.storage_account.id
}

resource "azurerm_eventgrid_event_subscription" "airflow_log_event_subscription" {
  name  = "airflowlogeventsubscription"
  scope = module.storage_account.id

  storage_queue_endpoint {
    storage_account_id = module.storage_account.id
    queue_name         = azurerm_storage_queue.airflow_log_queue.name
  }

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/airflow-logs/blobs"
  }

}

resource "azurerm_key_vault_secret" "airflow_log_storage_connectionstring" {
  name         = "airflow-log-storage-connectionstring"
  value        = format("DefaultEndpointsProtocol=https;AccountName=%s;AccountKey=%s;EndpointSuffix=core.windows.net", local.storage_name,module.storage_account.primary_access_key)
  key_vault_id = module.keyvault.keyvault_id
}

resource "azurerm_key_vault_secret" "airflow_log_workspace_key" {
  name         = "airflow-log-workspace-key"
  value        = module.aks-gitops.log_workspace_key
  key_vault_id = module.keyvault.keyvault_id  
}

#-------------------------------
# DAG Storage
#-------------------------------
module "airflow_dag_storage_account" {
  source = "../../../../modules/providers/azure/storage-account"

  name                = local.dag_storage_name
  resource_group_name = azurerm_resource_group.main.name
  container_names     = []
  kind                = "StorageV2"
  replication_type    = "LRS"
}

resource "azurerm_storage_share" "airflow_dag_share" {
  name                 = "airflowdags"
  storage_account_name = module.airflow_dag_storage_account.name
  quota                = 50
}


resource "azurerm_role_assignment" "dag_storage_roles" {
  count                = length(local.rbac_principals)
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.airflow_dag_storage_account.id
}

resource "azurerm_key_vault_secret" "dag-storage-account-name" {
  name         = "airflow-dag-share-storage-account"
  value        = module.airflow_dag_storage_account.name
  key_vault_id = module.keyvault.keyvault_id
}

resource "azurerm_key_vault_secret" "dag-storage-account-key" {
  name         = "airflow-dag-share-storage-key"
  value        = module.airflow_dag_storage_account.primary_access_key
  key_vault_id = module.keyvault.keyvault_id
}
