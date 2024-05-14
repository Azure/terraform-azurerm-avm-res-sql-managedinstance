variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
  default     = "myResourceGroup"
}

variable "location" {
  description = "Azure region in which to create the resources."
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "avm"
}

variable "license_type" {
  description = "SQL Server license type."
  type        = string
  default     = "LicenseIncluded"
}

variable "sku_name" {
  description = "SQL Server SKU name."
  type        = string
  default     = "BC_Gen5"
}

variable "vcores" {
  description = "Number of vCores for SQL Server."
  type        = number
  default     = 4
}

variable "storage_size_in_gb" {
  description = "Storage size in GB for SQL Server."
  type        = number
  default     = 32
}
