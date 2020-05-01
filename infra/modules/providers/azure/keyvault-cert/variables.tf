variable "keyvault_id" {
  type        = string
  description = "The id of the Key Vault where the Certificate should be created."
}

variable "key_vault_cert_name" {
  description = "Name of the certifacte to create"
  type        = string
  default     = "pfx-certificate"
}

variable "key_vault_content_type" {
  type        = string
  description = " The Content-Type of the Certificate, such as application/x-pkcs12 for a PFX or application/x-pem-file for a PEM. Changing this forces a new resource to be created."
  default     = "application/x-pkcs12"
}

variable "key_vault_cert_import_filepath" {
  type        = string
  description = "The base64-encoded certificate file path. Changing this forces a new resource to be created."
}
