variable "prefix" {
  description = "(Required) An identifier used to construct the names of all resources in this template."
  type        = string
}

variable "resource_group_location" {
  description = "The Azure region where container registry resources in this template should be created."
  type        = string
}

variable "container_registry_sku" {
  description = "(Optional) The SKU name of the the container registry. Possible values are Basic, Standard and Premium."
  type        = string
  default     = "Standard"
}
