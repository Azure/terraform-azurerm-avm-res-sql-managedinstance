resource "azapi_resource" "mssql_managed_instance" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Sql/managedInstances@2023-05-01-preview"
  body = {
    properties = {
      administratorLogin         = var.administrator_login
      administratorLoginPassword = var.administrator_login_password
      collation                  = var.collation
      dnsZonePartnerId           = var.dns_zone_partner_id
      licenseType                = var.license_type
      maintenanceConfigurationId = var.maintenance_configuration_name != null ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Maintenance/publicMaintenanceConfigurations/${var.maintenance_configuration_name}" : null
      minimumTlsVersion          = var.minimum_tls_version
      proxyOverride              = var.proxy_override
      publicDataEndpointEnabled  = var.public_data_endpoint_enabled
      skuName                    = var.sku_name
      storageSizeInGB            = var.storage_size_in_gb
      storageAccountType         = var.storage_account_type
      subnetId                   = var.subnet_id
      timezoneId                 = var.timezone_id
      vCores                     = var.vcores
      zoneRedundant              = var.zone_redundant_enabled
    }
    tags = var.tags
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # identity is handled via azapi_resource_action (sql_managed_instance_patch_identities)
  # due to provider limitations with system & user assigned identities.
  # See: https://github.com/hashicorp/terraform-provider-azurerm/issues/19802
  lifecycle {
    ignore_changes = [
      body.properties.proxyOverride,
      # Azure automatically sets these after creation with default values
      body.properties.collation,
      body.properties.timezoneId,
      body.properties.publicDataEndpointEnabled,
      body.properties.maintenanceConfigurationId,
    ]
  }
}

resource "azapi_resource" "mssql_managed_instance_active_directory_administrator" {
  count = try(var.active_directory_administrator.object_id, null) == null ? 0 : 1

  name      = "ActiveDirectory"
  parent_id = azapi_resource.mssql_managed_instance.id
  type      = "Microsoft.Sql/managedInstances/administrators@2023-05-01-preview"
  body = {
    properties = {
      administratorType         = "ActiveDirectory"
      login                     = var.active_directory_administrator.login_username
      objectId                  = var.active_directory_administrator.object_id
      tenantId                  = var.active_directory_administrator.tenant_id
      azureADOnlyAuthentication = var.active_directory_administrator.azuread_authentication_only
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.active_directory_administrator.timeouts == null ? [] : [var.active_directory_administrator.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource_action" "mssql_managed_instance_security_alert_policy" {
  count = var.security_alert_policy == {} ? 0 : 1

  method      = "PUT"
  resource_id = "${azapi_resource.mssql_managed_instance.id}/securityAlertPolicies/Default"
  type        = "Microsoft.Sql/managedInstances/securityAlertPolicies@2023-08-01-preview"
  body = {
    properties = {
      disabledAlerts          = try(var.security_alert_policy.disabled_alerts, [])
      emailAccountAdmins      = try(var.security_alert_policy.email_account_admins_enabled, false)
      emailAddresses          = try(var.security_alert_policy.email_addresses, [])
      retentionDays           = try(var.security_alert_policy.retention_days, 0)
      state                   = try(var.security_alert_policy.enabled ? "Enabled" : "Disabled", "Enabled")
      storageAccountAccessKey = try(var.security_alert_policy.storage_account_access_key, null)
      storageEndpoint         = try(var.security_alert_policy.storage_endpoint, null)
    }
  }
  locks = [
    azapi_resource.mssql_managed_instance.id
  ]
  retry = var.retry.mssql_managed_instance_security_alert_policy

  timeouts {
    create = var.timeout.mssql_managed_instance_security_alert_policy.create
    delete = var.timeout.mssql_managed_instance_security_alert_policy.delete
    read   = var.timeout.mssql_managed_instance_security_alert_policy.read
    update = var.timeout.mssql_managed_instance_security_alert_policy.update
  }

  depends_on = [
    azapi_resource.mssql_managed_instance_active_directory_administrator,
  ]
}

# Register the Key Vault key as a server key on the Managed Instance before setting it as the encryption protector
resource "azapi_resource" "mssql_managed_instance_server_key" {
  count = var.transparent_data_encryption != null ? 1 : 0

  name      = "${split(".", split("/", var.transparent_data_encryption.key_vault_key_id)[2])[0]}_${split("/", var.transparent_data_encryption.key_vault_key_id)[4]}_${split("/", var.transparent_data_encryption.key_vault_key_id)[5]}"
  parent_id = azapi_resource.mssql_managed_instance.id
  type      = "Microsoft.Sql/managedInstances/keys@2023-05-01-preview"
  body = {
    properties = {
      serverKeyType = "AzureKeyVault"
      uri           = var.transparent_data_encryption.key_vault_key_id
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource_action.sql_managed_instance_patch_identities,
  ]
}

# Revert the encryption protector to ServiceManaged on destroy, before the server key is deleted.
# Azure prevents deletion of a key that is currently set as the encryption protector.
# Destroy order: this resource is destroyed first (runs the PUT to revert), then transparent_data_encryption,
# then server_key — because destroy order is the reverse of the dependency chain.
resource "azapi_resource_action" "mssql_managed_instance_revert_encryption_protector" {
  count = var.transparent_data_encryption != null ? 1 : 0

  method      = "PUT"
  resource_id = "${azapi_resource.mssql_managed_instance.id}/encryptionProtector/current"
  type        = "Microsoft.Sql/managedInstances/encryptionProtector@2023-05-01-preview"
  body = {
    properties = {
      serverKeyType = "ServiceManaged"
      serverKeyName = "ServiceManaged"
    }
  }
  when = "destroy"

  depends_on = [
    azapi_resource_action.mssql_managed_instance_transparent_data_encryption,
  ]
}

resource "azapi_resource_action" "mssql_managed_instance_transparent_data_encryption" {
  count = var.transparent_data_encryption != null ? 1 : 0

  method      = "PUT"
  resource_id = "${azapi_resource.mssql_managed_instance.id}/encryptionProtector/current"
  type        = "Microsoft.Sql/managedInstances/encryptionProtector@2023-05-01-preview"
  body = {
    properties = {
      autoRotationEnabled = var.transparent_data_encryption.auto_rotation_enabled
      serverKeyName       = "${split(".", split("/", var.transparent_data_encryption.key_vault_key_id)[2])[0]}_${split("/", var.transparent_data_encryption.key_vault_key_id)[4]}_${split("/", var.transparent_data_encryption.key_vault_key_id)[5]}"
      serverKeyType       = "AzureKeyVault"
    }
  }

  dynamic "timeouts" {
    for_each = var.transparent_data_encryption.timeouts == null ? [] : [var.transparent_data_encryption.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [
    azapi_resource.mssql_managed_instance_server_key,
  ]
}

# API:
# https://learn.microsoft.com/en-us/rest/api/sql/managed-instance-vulnerability-assessments/create-or-update?view=rest-sql-2023-08-01-preview&tabs=HTTP
#
# Note that user assigned identities are not support for vulnerability assessments, so must use user assigned & system assigned, or just system assigned.
# https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-database-vulnerability-assessment-storage?view=azuresql#store-va-scan-results-for-azure-sql-managed-instance-in-a-storage-account-that-can-be-accessed-behind-a-firewall-or-vnet
resource "azapi_resource_action" "mssql_managed_instance_vulnerability_assessment" {
  count = var.vulnerability_assessment == null ? 0 : 1

  method      = "PUT"
  resource_id = "${azapi_resource.mssql_managed_instance.id}/vulnerabilityAssessments/default"
  type        = "Microsoft.Sql/managedInstances/vulnerabilityAssessments@2023-08-01-preview"
  body = {
    properties = {
      storageAccountAccessKey = try(var.vulnerability_assessment.storage_account_access_key, null)
      storageContainerPath    = try(var.vulnerability_assessment.storage_container_path, null)
      storageContainerSasKey  = try(var.vulnerability_assessment.storage_container_sas_key, null)
      recurringScans = var.vulnerability_assessment.recurring_scans != {} ? {
        isEnabled               = try(var.vulnerability_assessment.recurring_scans.enabled, true)
        emailSubscriptionAdmins = try(var.vulnerability_assessment.recurring_scans.email_subscription_admins, true),
        emails                  = try(var.vulnerability_assessment.recurring_scans.emails, [])
      } : null
    }
  }
  locks = [
    azapi_resource.mssql_managed_instance.id
  ]

  depends_on = [
    azapi_resource_action.mssql_managed_instance_transparent_data_encryption,
  ]
}

# this is required for vulnerability assessments to function - user assigned identities are not supported
# https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-database-vulnerability-assessment-storage?view=azuresql
resource "azapi_resource" "role_assignment_vulnerability_assessment_storage" {
  count = var.vulnerability_assessment == null ? 0 : 1

  name      = uuid()
  parent_id = var.storage_account_resource_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = jsondecode(data.azapi_resource.identity.output).identity.principalId
      roleDefinitionId = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

# required AVM resources interfaces
resource "azapi_resource" "management_lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.mssql_managed_instance.id
  type      = "Microsoft.Authorization/locks@2017-04-01"
  body = {
    properties = {
      level = var.lock.kind
      notes = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_resource" "role_assignment" {
  for_each = var.role_assignments

  name      = uuid()
  parent_id = azapi_resource.mssql_managed_instance.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId                        = each.value.principal_id
      roleDefinitionId                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${data.azurerm_role_definition.this[each.value.role_definition_id_or_name].id}"
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
      principalType                      = "ServicePrincipal"
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    data.azurerm_role_definition.this,
  ]
}

# identity is done via an azapi_resource_action, because of this bug that
# prevents system & user assigned identities being set at the same time.
# https://github.com/hashicorp/terraform-provider-azurerm/issues/19802
resource "azapi_resource_action" "sql_managed_instance_patch_identities" {
  count = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0 || var.service_principal_enabled || var.is_general_purpose_v2 || var.storage_iops != null || var.memory_size_in_gb != null) ? 1 : 0

  method      = "PATCH"
  resource_id = azapi_resource.mssql_managed_instance.id
  type        = "Microsoft.Sql/managedInstances@2023-05-01-preview"
  body = {
    identity = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      type = local.managed_identities.system_assigned_user_assigned.this.type
      userAssignedIdentities = (local.managed_identities.system_assigned_user_assigned.this.type == "UserAssigned") || (local.managed_identities.system_assigned_user_assigned.this.type == "SystemAssigned, UserAssigned") ? {
        for id in tolist(local.managed_identities.system_assigned_user_assigned.this.user_assigned_resource_ids) : id => {}
      } : null
    } : null,
    properties = merge(
      length(local.managed_identities.system_assigned_user_assigned.this.user_assigned_resource_ids) > 0 ? {
        primaryUserAssignedIdentityId = tolist(local.managed_identities.system_assigned_user_assigned.this.user_assigned_resource_ids)[0]
      } : {},
      (var.service_principal_enabled || local.current_service_principal_enabled) ? {
        servicePrincipal = {
          type = "SystemAssigned"
        }
      } : {},
      var.is_general_purpose_v2 ? {
        isGeneralPurposeV2 = true
      } : {},
      var.storage_iops != null ? {
        storageIOps = var.storage_iops
      } : {},
      var.memory_size_in_gb != null ? {
        memorySizeInGB = var.memory_size_in_gb
      } : {}
    )
  }
  locks = [
    azapi_resource.mssql_managed_instance.id
  ]
  retry = var.retry.sql_managed_instance_patch_identities

  timeouts {
    create = var.timeout.sql_managed_instance_patch_identities.create
    delete = var.timeout.sql_managed_instance_patch_identities.delete
    read   = var.timeout.sql_managed_instance_patch_identities.read
    update = var.timeout.sql_managed_instance_patch_identities.update
  }

  depends_on = [
    azapi_resource_action.mssql_managed_instance_security_alert_policy,
  ]

  lifecycle {
    ignore_changes = [resource_id]
  }
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "parent" {
  name = var.resource_group_name
}

data "azapi_resource" "identity" {
  name                   = azapi_resource.mssql_managed_instance.name
  parent_id              = data.azurerm_resource_group.parent.id
  type                   = "Microsoft.Sql/managedInstances@2023-05-01-preview"
  response_export_values = ["identity", "properties"]
}

data "azurerm_role_definition" "this" {
  for_each = {
    for k, v in var.role_assignments :
    v.role_definition_id_or_name => v
    if !strcontains(lower(v.role_definition_id_or_name), lower(local.role_definition_resource_substring))
  }

  name = each.key
}

resource "azapi_resource_action" "sql_advanced_threat_protection" {
  method      = "PUT"
  resource_id = "${azapi_resource.mssql_managed_instance.id}/advancedThreatProtectionSettings/Default"
  type        = "Microsoft.Sql/managedInstances/advancedThreatProtectionSettings@2023-08-01-preview"
  body = {
    properties = {
      state = var.advanced_threat_protection_enabled ? "Enabled" : "Disabled"
    }
  }
  locks = [
    azapi_resource.mssql_managed_instance.id
  ]
  retry = var.retry.sql_advanced_threat_protection

  timeouts {
    create = var.timeout.sql_advanced_threat_protection.create
    delete = var.timeout.sql_advanced_threat_protection.delete
    read   = var.timeout.sql_advanced_threat_protection.read
    update = var.timeout.sql_advanced_threat_protection.update
  }

  depends_on = [
    azapi_resource_action.sql_managed_instance_patch_identities,
  ]
}

resource "azapi_resource_action" "diagnostic_setting" {
  for_each = var.diagnostic_settings

  method      = "PUT"
  resource_id = "${azapi_resource.mssql_managed_instance.id}/providers/Microsoft.Insights/diagnosticSettings/${coalesce(each.value.name, "diag-${var.name}")}"
  type        = "Microsoft.Insights/diagnosticSettings@2017-05-01-preview"
  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      logs = concat(
        [for log in each.value.log_categories : {
          category = log
          enabled  = true
        }],
        [for log in each.value.log_groups : {
          categoryGroup = log
          enabled       = true
        }]
      )
      marketplacePartnerId = each.value.marketplace_partner_resource_id
      metrics = [for metric in each.value.metric_categories : {
        category = metric
        enabled  = true
      }]
      storageAccountId = each.value.storage_account_resource_id
      workspaceId      = each.value.workspace_resource_id
    }
  }

  depends_on = [
    azapi_resource_action.sql_advanced_threat_protection,
  ]
}
