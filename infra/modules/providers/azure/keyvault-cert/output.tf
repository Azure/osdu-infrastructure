output "cert_name" {
  value = var.key_vault_cert_name
}

output "secret_id" {
  value = azurerm_key_vault_certificate.kv_cert_import.secret_id
}
