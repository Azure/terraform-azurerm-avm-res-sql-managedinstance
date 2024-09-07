<!-- BEGIN_TF_DOCS -->
# AVM module for SQL Managed Instance

This is an Azure Verified Modules for SQL Managed Instances.

The module supports the following capabilities:

* All supported AzureRM parameters for the `azurerm_mssql_managed_instance` resource.
* Advanced Threat Protection, enabled by default.
* Vulnerability Assessments & Security Access Policies with a restricted storage account (supplied via `storage_account_resource_id`)
* Configuration for a failover group
* A map of databases, along with support for all parameters, such as long term backup retention policies.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.13)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azapi_resource_action.mssql_managed_instance_security_alert_policy](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) (resource)
- [azapi_resource_action.mssql_managed_instance_vulnerability_assessment](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) (resource)
- [azapi_resource_action.sql_advanced_threat_protection](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) (resource)
- [azapi_resource_action.sql_managed_instance_patch_identities](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_mssql_managed_database.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_database) (resource)
- [azurerm_mssql_managed_instance.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance) (resource)
- [azurerm_mssql_managed_instance_active_directory_administrator.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance_active_directory_administrator) (resource)
- [azurerm_mssql_managed_instance_failover_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance_failover_group) (resource)
- [azurerm_mssql_managed_instance_transparent_data_encryption.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance_transparent_data_encryption) (resource)
- [azurerm_private_endpoint.this_managed_dns_zone_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint.this_unmanaged_dns_zone_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint_application_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint_application_security_group_association) (resource)
- [azurerm_role_assignment.sqlmi_system_assigned](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_resource.identity](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_resource_group.parent](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login)

Description: (Required) The administrator login name for the new SQL Managed Instance. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_administrator_login_password"></a> [administrator\_login\_password](#input\_administrator\_login\_password)

Description: (Required) The password associated with the `administrator_login` user. Needs to comply with Azure's [Password Policy](https://msdn.microsoft.com/library/ms161959.aspx)

Type: `string`

### <a name="input_license_type"></a> [license\_type](#input\_license\_type)

Description: (Required) What type of license the Managed Instance will use. Possible values are `LicenseIncluded` and `BasePrice`.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the this resource.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name)

Description: (Required) Specifies the SKU Name for the SQL Managed Instance. Valid values include `GP_Gen4`, `GP_Gen5`, `GP_Gen8IM`, `GP_Gen8IH`, `BC_Gen4`, `BC_Gen5`, `BC_Gen8IM` or `BC_Gen8IH`.

Type: `string`

### <a name="input_storage_size_in_gb"></a> [storage\_size\_in\_gb](#input\_storage\_size\_in\_gb)

Description: (Required) Maximum storage space for the SQL Managed instance. This should be a multiple of 32 (GB).

Type: `number`

### <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id)

Description: (Required) The subnet resource id that the SQL Managed Instance will be associated with. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_vcores"></a> [vcores](#input\_vcores)

Description: (Required) Number of cores that should be assigned to the SQL Managed Instance. Values can be `8`, `16`, or `24` for Gen4 SKUs, or `4`, `6`, `8`, `10`, `12`, `16`, `20`, `24`, `32`, `40`, `48`, `56`, `64`, `80`, `96` or `128` for Gen5 SKUs.

Type: `number`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_active_directory_administrator"></a> [active\_directory\_administrator](#input\_active\_directory\_administrator)

Description: - `azuread_authentication_only` - (Optional) When `true`, only permit logins from AAD users and administrators. When `false`, also allow local database users.
- `login_username` - (Required) The login name of the principal to set as the Managed Instance Administrator.
- `object_id` - (Required) The Object ID of the principal to set as the Managed Instance Administrator.
- `tenant_id` - (Required) The Azure Active Directory Tenant ID.

---
`timeouts` block supports the following:
- `create` - (Defaults to 30 minutes) Used when creating the SQL Active Directory Administrator.
- `delete` - (Defaults to 30 minutes) Used when deleting the SQL Active Directory Administrator.
- `read` - (Defaults to 5 minutes) Used when retrieving the SQL Active Directory Administrator.
- `update` - (Defaults to 30 minutes) Used when updating the SQL Active Directory Administrator.

Type:

```hcl
object({
    azuread_authentication_only = optional(bool)
    login_username              = optional(string)
    object_id                   = optional(string)
    tenant_id                   = optional(string)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
```

Default: `{}`

### <a name="input_collation"></a> [collation](#input\_collation)

Description: (Optional) Specifies how the SQL Managed Instance will be collated. Default value is `SQL_Latin1_General_CP1_CI_AS`. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key)

Description: A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.

Type:

```hcl
object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
```

Default: `null`

### <a name="input_databases"></a> [databases](#input\_databases)

Description: - `name` - (Required) The name of the Managed Database to create. Changing this forces a new resource to be created.
- `short_term_retention_days` - (Optional) The backup retention period in days. This is how many days Point-in-Time Restore will be supported.

---
`long_term_retention_policy` block supports the following:
- `monthly_retention` - (Optional) The monthly retention policy for an LTR backup in an ISO 8601 format. Valid value is between 1 to 120 months. e.g. `P1Y`, `P1M`, `P4W` or `P30D`.
- `week_of_year` - (Optional) The week of year to take the yearly backup. Value has to be between `1` and `52`.
- `weekly_retention` - (Optional) The weekly retention policy for an LTR backup in an ISO 8601 format. Valid value is between 1 to 520 weeks. e.g. `P1Y`, `P1M`, `P1W` or `P7D`.
- `yearly_retention` - (Optional) The yearly retention policy for an LTR backup in an ISO 8601 format. Valid value is between 1 to 10 years. e.g. `P1Y`, `P12M`, `P52W` or `P365D`.

---
`point_in_time_restore` block supports the following:
- `restore_point_in_time` - (Required) The point in time for the restore from `source_database_id`. Changing this forces a new resource to be created.
- `source_database_id` - (Required) The source database id that will be used to restore from. Changing this forces a new resource to be created.

---
`timeouts` block supports the following:
- `create` - (Defaults to 30 minutes) Used when creating the Mssql Managed Database.
- `delete` - (Defaults to 30 minutes) Used when deleting the Mssql Managed Database.
- `read` - (Defaults to 5 minutes) Used when retrieving the Mssql Managed Database.
- `update` - (Defaults to 30 minutes) Used when updating the Mssql Managed Database.

Type:

```hcl
map(object({
    name                      = string
    short_term_retention_days = optional(number)
    long_term_retention_policy = optional(object({
      monthly_retention = optional(string)
      week_of_year      = optional(number)
      weekly_retention  = optional(string)
      yearly_retention  = optional(string)
    }))
    point_in_time_restore = optional(object({
      restore_point_in_time = string
      source_database_id    = string
    }))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
```

Default: `{}`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_dns_zone_partner_id"></a> [dns\_zone\_partner\_id](#input\_dns\_zone\_partner\_id)

Description: (Optional) The ID of the SQL Managed Instance which will share the DNS zone. This is a prerequisite for creating an `azurerm_sql_managed_instance_failover_group`. Setting this after creation forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_enable_advanced_threat_protection"></a> [enable\_advanced\_threat\_protection](#input\_enable\_advanced\_threat\_protection)

Description: (Optional) Whether to enabled Defender for SQL Advanced Threat Protection.

Type: `bool`

Default: `true`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_failover_group"></a> [failover\_group](#input\_failover\_group)

Description:   
Map of failover groups.  There can only be one failover group in the map.

 - `location` - (Required) The Azure Region where the Managed Instance Failover Group should exist. Changing this forces a new resource to be created.
 - `name` - (Required) The name which should be used for this Managed Instance Failover Group. Changing this forces a new resource to be created.
 - `partner_managed_instance_id` - (Required) The ID of the Azure SQL Managed Instance which will be replicated to. Changing this forces a new resource to be created.
 - `readonly_endpoint_failover_policy_enabled` - (Optional) Failover policy for the read-only endpoint. Defaults to `true`.

 ---
 `read_write_endpoint_failover_policy` block supports the following:
 - `grace_minutes` - (Optional) Applies only if `mode` is `Automatic`. The grace period in minutes before failover with data loss is attempted.
 - `mode` - (Required) The failover mode. Possible values are `Automatic` or `Manual`.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Managed Instance Failover Group.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Managed Instance Failover Group.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Managed Instance Failover Group.
 - `update` - (Defaults to 30 minutes) Used when updating the Managed Instance Failover Group.

Type:

```hcl
map(object({
    location                                  = optional(string)
    name                                      = optional(string)
    partner_managed_instance_id               = optional(string)
    readonly_endpoint_failover_policy_enabled = optional(bool)
    read_write_endpoint_failover_policy = optional(object({
      grace_minutes = optional(number)
      mode          = optional(string)
    }))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
```

Default: `{}`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_maintenance_configuration_name"></a> [maintenance\_configuration\_name](#input\_maintenance\_configuration\_name)

Description: (Optional) The name of the Public Maintenance Configuration window to apply to the SQL Managed Instance. Valid values include `SQL_Default` or an Azure Location in the format `SQL_{Location}_MI_{Size}`(for example `SQL_EastUS_MI_1`). Defaults to `SQL_Default`.

Type: `string`

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description: Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version)

Description: (Optional) The Minimum TLS Version. Default value is `1.2` Valid values include `1.0`, `1.1`, `1.2`.

Type: `string`

Default: `"1.2"`

### <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints)

Description: A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of this resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_private_endpoints_manage_dns_zone_group"></a> [private\_endpoints\_manage\_dns\_zone\_group](#input\_private\_endpoints\_manage\_dns\_zone\_group)

Description: Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy.

Type: `bool`

Default: `true`

### <a name="input_proxy_override"></a> [proxy\_override](#input\_proxy\_override)

Description: (Optional) Specifies how the SQL Managed Instance will be accessed. Default value is `Default`. Valid values include `Default`, `Proxy`, and `Redirect`.

Type: `string`

Default: `null`

### <a name="input_public_data_endpoint_enabled"></a> [public\_data\_endpoint\_enabled](#input\_public\_data\_endpoint\_enabled)

Description: (Optional) Is the public data endpoint enabled? Default value is `false`.

Type: `bool`

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_security_alert_policy"></a> [security\_alert\_policy](#input\_security\_alert\_policy)

Description: - `disabled_alerts` - (Optional) Specifies an array of alerts that are disabled. Possible values are `Sql_Injection`, `Sql_Injection_Vulnerability`, `Access_Anomaly`, `Data_Exfiltration`, `Unsafe_Action` and `Brute_Force`.
- `email_account_admins_enabled` - (Optional) Boolean flag which specifies if the alert is sent to the account administrators or not. Defaults to `false`.
- `email_addresses` - (Optional) Specifies an array of email addresses to which the alert is sent.
- `enabled` - (Optional) Specifies the state of the Security Alert Policy, whether it is enabled or disabled. Possible values are `true`, `false`.
- `retention_days` - (Optional) Specifies the number of days to keep in the Threat Detection audit logs. Defaults to `0`.
- `storage_account_access_key` - (Optional) Specifies the identifier key of the Threat Detection audit storage account. This is mandatory when you use `storage_endpoint` to specify a storage account blob endpoint.
- `storage_endpoint` - (Optional) Specifies the blob storage endpoint (e.g. https://example.blob.core.windows.net). This blob storage will hold all Threat Detection audit logs.

---
`timeouts` block supports the following:
- `create` - (Defaults to 30 minutes) Used when creating the MS SQL Managed Instance Security Alert Policy.
- `delete` - (Defaults to 30 minutes) Used when deleting the MS SQL Managed Instance Security Alert Policy.
- `read` - (Defaults to 5 minutes) Used when retrieving the MS SQL Managed Instance Security Alert Policy.
- `update` - (Defaults to 30 minutes) Used when updating the MS SQL Managed Instance Security Alert Policy.

Type:

```hcl
object({
    disabled_alerts              = optional(set(string))
    email_account_admins_enabled = optional(bool)
    email_addresses              = optional(set(string))
    enabled                      = optional(bool)
    retention_days               = optional(number)
    storage_account_access_key   = optional(string)
    storage_endpoint             = optional(string)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
```

Default: `{}`

### <a name="input_storage_account_resource_id"></a> [storage\_account\_resource\_id](#input\_storage\_account\_resource\_id)

Description: (Optional) Storage Account to store vulnerability assessments.

The System Assigned Managed Identity will be granted Storage Blob Data Contributor over this storage account.

Note these limitations documented in Microsoft Learn - <https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-database-vulnerability-assessment-storage?view=azuresql#store-va-scan-results-for-azure-sql-managed-instance-in-a-storage-account-that-can-be-accessed-behind-a-firewall-or-vnet>

* User Assigned MIs are not supported
* The storage account firewall public network access must be allowed.  If "Enabled from selected virtual networks and IP addresses" is set (recommended), the SQL MI subnet ID must be added to the storage account firewall.

Type: `string`

Default: `null`

### <a name="input_storage_account_type"></a> [storage\_account\_type](#input\_storage\_account\_type)

Description: (Optional) Specifies the storage account type used to store backups for this database. Changing this forces a new resource to be created. Possible values are `GRS`, `LRS` and `ZRS`. Defaults to `GRS`.

Type: `string`

Default: `"ZRS"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_timeouts"></a> [timeouts](#input\_timeouts)

Description: - `create` - (Defaults to 24 hours) Used when creating the Microsoft SQL Managed Instance.
- `delete` - (Defaults to 24 hours) Used when deleting the Microsoft SQL Managed Instance.
- `read` - (Defaults to 5 minutes) Used when retrieving the Microsoft SQL Managed Instance.
- `update` - (Defaults to 24 hours) Used when updating the Microsoft SQL Managed Instance.

Type:

```hcl
object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
```

Default: `null`

### <a name="input_timezone_id"></a> [timezone\_id](#input\_timezone\_id)

Description: (Optional) The TimeZone ID that the SQL Managed Instance will be operating in. Default value is `UTC`. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_transparent_data_encryption"></a> [transparent\_data\_encryption](#input\_transparent\_data\_encryption)

Description: - `auto_rotation_enabled` - (Optional) When enabled, the SQL Managed Instance will continuously check the key vault for any new versions of the key being used as the TDE protector. If a new version of the key is detected, the TDE protector on the SQL Managed Instance will be automatically rotated to the latest key version within 60 minutes.
- `key_vault_key_id` - (Optional) To use customer managed keys from Azure Key Vault, provide the AKV Key ID. To use service managed keys, omit this field.

---
`timeouts` block supports the following:
- `create` - (Defaults to 30 minutes) Used when creating the MSSQL.
- `delete` - (Defaults to 30 minutes) Used when deleting the MSSQL.
- `read` - (Defaults to 5 minutes) Used when retrieving the MSSQL.
- `update` - (Defaults to 30 minutes) Used when updating the MSSQL.

Type:

```hcl
object({
    auto_rotation_enabled = optional(bool)
    key_vault_key_id      = optional(string)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
```

Default: `{}`

### <a name="input_vulnerability_assessment"></a> [vulnerability\_assessment](#input\_vulnerability\_assessment)

Description: - `storage_account_access_key` - (Optional) Specifies the identifier key of the storage account for vulnerability assessment scan results. If `storage_container_sas_key` isn't specified, `storage_account_access_key` is required.  Set to `null` if the storage account is protected by a resource firewall.
- `storage_container_path` - (Required) A blob storage container path to hold the scan results (e.g. <https://myStorage.blob.core.windows.net/VaScans/>).
- `storage_container_sas_key` - (Optional) A shared access signature (SAS Key) that has write access to the blob container specified in `storage_container_path` parameter. If `storage_account_access_key` isn't specified, `storage_container_sas_key` is required.  Set to `null` if the storage account is protected by a resource firewall.

---
`recurring_scans` block supports the following:
- `email_subscription_admins` - (Optional) Boolean flag which specifies if the schedule scan notification will be sent to the subscription administrators. Defaults to `true`.
- `emails` - (Optional) Specifies an array of e-mail addresses to which the scan notification is sent.
- `enabled` - (Optional) Boolean flag which specifies if recurring scans is enabled or disabled. Defaults to `false`.

---
`timeouts` block supports the following:
- `create` - (Defaults to 60 minutes) Used when creating the Vulnerability Assessment.
- `delete` - (Defaults to 60 minutes) Used when deleting the Vulnerability Assessment.
- `read` - (Defaults to 5 minutes) Used when retrieving the Vulnerability Assessment.
- `update` - (Defaults to 60 minutes) Used when updating the Vulnerability Assessment.

Type:

```hcl
object({
    storage_account_access_key = optional(string)
    storage_container_path     = optional(string)
    storage_container_sas_key  = optional(string)
    recurring_scans = optional(object({
      email_subscription_admins = optional(bool)
      emails                    = optional(list(string))
      enabled                   = optional(bool)
    }))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
```

Default: `{}`

### <a name="input_zone_redundant_enabled"></a> [zone\_redundant\_enabled](#input\_zone\_redundant\_enabled)

Description: (Optional) If true, the SQL Managed Instance will be deployed with zone redundancy.  Defaults to `true`.

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### <a name="output_identity"></a> [identity](#output\_identity)

Description: Managed identities for the SQL MI instance.  This is not available from the `resource` output because AzureRM doesn't yet support adding both User and System Assigned identities.

### <a name="output_private_endpoints"></a> [private\_endpoints](#output\_private\_endpoints)

Description:   A map of the private endpoints created.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: This is the full output for the resource.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: This is the resource ID of the resource.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->