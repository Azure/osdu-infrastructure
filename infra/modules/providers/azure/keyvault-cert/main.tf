resource "azurerm_key_vault_certificate" "kv_cert_import" {
  name         = var.key_vault_cert_name
  key_vault_id = var.keyvault_id

  certificate {
    contents = filebase64(var.key_vault_cert_import_filepath)
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 4096
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = var.key_vault_content_type
    }
  }
}
