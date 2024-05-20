
variable "administrator_login" {
  type        = string
  description = "(Required) The administrator login name for the new SQL Managed Instance. Changing this forces a new resource to be created."
  nullable    = false
}

variable "administrator_login_password" {
  type        = string
  description = "(Required) The password associated with the `administrator_login` user. Needs to comply with Azure's [Password Policy](https://msdn.microsoft.com/library/ms161959.aspx)"
  nullable    = false
  sensitive   = true
}

variable "license_type" {
  type        = string
  description = "(Required) What type of license the Managed Instance will use. Possible values are `LicenseIncluded` and `BasePrice`."
  nullable    = false
}

variable "sku_name" {
  type        = string
  description = "(Required) Specifies the SKU Name for the SQL Managed Instance. Valid values include `GP_Gen4`, `GP_Gen5`, `GP_Gen8IM`, `GP_Gen8IH`, `BC_Gen4`, `BC_Gen5`, `BC_Gen8IM` or `BC_Gen8IH`."
  nullable    = false
}

variable "storage_size_in_gb" {
  type        = number
  description = "(Required) Maximum storage space for the SQL Managed instance. This should be a multiple of 32 (GB)."
  nullable    = false
}

variable "subnet_id" {
  type        = string
  description = "(Required) The subnet resource id that the SQL Managed Instance will be associated with. Changing this forces a new resource to be created."
  nullable    = false
}

variable "vcores" {
  type        = number
  description = "(Required) Number of cores that should be assigned to the SQL Managed Instance. Values can be `8`, `16`, or `24` for Gen4 SKUs, or `4`, `6`, `8`, `10`, `12`, `16`, `20`, `24`, `32`, `40`, `48`, `56`, `64`, `80`, `96` or `128` for Gen5 SKUs."
  nullable    = false
}

variable "collation" {
  type        = string
  default     = null
  description = "(Optional) Specifies how the SQL Managed Instance will be collated. Default value is `SQL_Latin1_General_CP1_CI_AS`. Changing this forces a new resource to be created."
}

variable "dns_zone_partner_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the SQL Managed Instance which will share the DNS zone. This is a prerequisite for creating an `azurerm_sql_managed_instance_failover_group`. Setting this after creation forces a new resource to be created."
}

variable "maintenance_configuration_name" {
  type        = string
  default     = null
  description = "(Optional) The name of the Public Maintenance Configuration window to apply to the SQL Managed Instance. Valid values include `SQL_Default` or an Azure Location in the format `SQL_{Location}_MI_{Size}`(for example `SQL_EastUS_MI_1`). Defaults to `SQL_Default`."
}

variable "minimum_tls_version" {
  type        = string
  default     = null
  description = "(Optional) The Minimum TLS Version. Default value is `1.2` Valid values include `1.0`, `1.1`, `1.2`."
}

variable "proxy_override" {
  type        = string
  default     = null
  description = "(Optional) Specifies how the SQL Managed Instance will be accessed. Default value is `Default`. Valid values include `Default`, `Proxy`, and `Redirect`."
}

variable "public_data_endpoint_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Is the public data endpoint enabled? Default value is `false`."
}

variable "storage_account_type" {
  type        = string
  default     = null
  description = "(Optional) Specifies the storage account type used to store backups for this database. Changing this forces a new resource to be created. Possible values are `GRS`, `LRS` and `ZRS`. Defaults to `GRS`."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-DESCRIPTION
 - `create` - (Defaults to 24 hours) Used when creating the Microsoft SQL Managed Instance.
 - `delete` - (Defaults to 24 hours) Used when deleting the Microsoft SQL Managed Instance.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Microsoft SQL Managed Instance.
 - `update` - (Defaults to 24 hours) Used when updating the Microsoft SQL Managed Instance.
DESCRIPTION
}

variable "timezone_id" {
  type        = string
  default     = null
  description = "(Optional) The TimeZone ID that the SQL Managed Instance will be operating in. Default value is `UTC`. Changing this forces a new resource to be created."
}

variable "transparent_data_encryption" {
  type = object({
    auto_rotation_enabled = optional(bool)
    key_vault_key_id      = optional(string)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  description = <<-DESCRIPTION
 - `auto_rotation_enabled` - (Optional) When enabled, the SQL Managed Instance will continuously check the key vault for any new versions of the key being used as the TDE protector. If a new version of the key is detected, the TDE protector on the SQL Managed Instance will be automatically rotated to the latest key version within 60 minutes.
 - `key_vault_key_id` - (Optional) To use customer managed keys from Azure Key Vault, provide the AKV Key ID. To use service managed keys, omit this field.
 
 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the MSSQL.
 - `delete` - (Defaults to 30 minutes) Used when deleting the MSSQL.
 - `read` - (Defaults to 5 minutes) Used when retrieving the MSSQL.
 - `update` - (Defaults to 30 minutes) Used when updating the MSSQL.
DESCRIPTION
  nullable    = false
}
