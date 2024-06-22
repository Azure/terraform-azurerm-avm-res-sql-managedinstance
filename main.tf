resource "azurerm_mssql_managed_instance" "this" {
  administrator_login            = var.administrator_login
  administrator_login_password   = var.administrator_login_password
  license_type                   = var.license_type
  location                       = var.location
  name                           = var.name
  resource_group_name            = var.resource_group_name
  sku_name                       = var.sku_name
  storage_size_in_gb             = var.storage_size_in_gb
  subnet_id                      = var.subnet_id
  vcores                         = var.vcores
  collation                      = var.collation
  dns_zone_partner_id            = var.dns_zone_partner_id
  maintenance_configuration_name = var.maintenance_configuration_name
  minimum_tls_version            = var.minimum_tls_version
  proxy_override                 = var.proxy_override
  public_data_endpoint_enabled   = var.public_data_endpoint_enabled
  storage_account_type           = var.storage_account_type
  tags                           = var.tags
  timezone_id                    = var.timezone_id

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # identity is done via an azapi_resource_action further on, because of this bug that
  # prevents system & user assigned identities being set at the same time.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/19802
  lifecycle {
    ignore_changes = [
      identity
    ]
  }
}

resource "azurerm_mssql_managed_instance_active_directory_administrator" "this" {
  count = try(var.active_directory_administrator.object_id, null) == null ? 0 : 1

  login_username              = var.active_directory_administrator.login_username
  managed_instance_id         = azurerm_mssql_managed_instance.this.id
  object_id                   = var.active_directory_administrator.object_id
  tenant_id                   = var.active_directory_administrator.tenant_id
  azuread_authentication_only = var.active_directory_administrator.azuread_authentication_only

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

resource "azapi_resource" "mssql_managed_instance_security_alert_policy" {
  count = var.security_alert_policy == {} ? 0 : 1

  type                      = "Microsoft.Sql/managedInstances/securityAlertPolicies@2023-05-01-preview"
  name                      = "Default"
  parent_id                 = azurerm_mssql_managed_instance.this.id
  schema_validation_enabled = true

  body = jsonencode({
    properties = {
      state                   = var.security_alert_policy.enabled ? "Enabled" : "Disabled"
      disabledAlerts          = var.security_alert_policy.disabled_alerts
      emailAccountAdmins      = var.security_alert_policy.email_account_admins_enabled
      emailAddresses          = var.security_alert_policy.email_addresses
      retentionDays           = var.security_alert_policy.retention_days
      storageAccountAccessKey = var.security_alert_policy.storage_account_access_key
      storageEndpoint         = var.security_alert_policy.storage_endpoint
    }
  })
}

resource "azurerm_mssql_managed_instance_transparent_data_encryption" "this" {
  count = var.transparent_data_encryption == {} ? 0 : 1

  managed_instance_id   = azurerm_mssql_managed_instance.this.id
  auto_rotation_enabled = var.transparent_data_encryption.auto_rotation_enabled
  key_vault_key_id      = var.transparent_data_encryption.key_vault_key_id

  dynamic "timeouts" {
    for_each = var.transparent_data_encryption.timeouts == null ? [] : [var.transparent_data_encryption.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azurerm_mssql_managed_instance_vulnerability_assessment" "this" {
  count = var.vulnerability_assessment == {} ? 0 : 1

  managed_instance_id        = azurerm_mssql_managed_instance.this.id
  storage_container_path     = var.vulnerability_assessment.storage_container_path
  storage_account_access_key = var.vulnerability_assessment.storage_account_access_key
  storage_container_sas_key  = var.vulnerability_assessment.storage_container_sas_key

  dynamic "recurring_scans" {
    for_each = var.vulnerability_assessment.recurring_scans == null ? [] : [var.vulnerability_assessment.recurring_scans]
    content {
      email_subscription_admins = recurring_scans.value.email_subscription_admins
      emails                    = recurring_scans.value.emails
      enabled                   = recurring_scans.value.enabled
    }
  }
  dynamic "timeouts" {
    for_each = var.vulnerability_assessment.timeouts == null ? [] : [var.vulnerability_assessment.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}




# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_mssql_managed_instance.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_mssql_managed_instance.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

# identity is done via an azapi_resource_action further on, because of this bug that
# prevents system & user assigned identities being set at the same time.
# https://github.com/hashicorp/terraform-provider-azurerm/issues/19802
resource "azapi_resource_action" "sql_managed_instance_patch_identities" {
  count       = local.managed_identities.system_assigned_user_assigned == {} ? 0 : 1
  type        = "Microsoft.Sql/managedInstances@2023-05-01-preview"
  resource_id = azurerm_mssql_managed_instance.this.id
  method      = "PATCH"
  body = {
    identity = {
      type = local.managed_identities.system_assigned_user_assigned.this.type
      userAssignedIdentities = {
        for id in tolist(local.managed_identities.system_assigned_user_assigned.this.user_assigned_resource_ids) : id => {}
      }
    },
    properties = {
      primaryUserAssignedIdentityId = length(local.managed_identities.system_assigned_user_assigned.this.user_assigned_resource_ids) > 0 ? tolist(local.managed_identities.system_assigned_user_assigned.this.user_assigned_resource_ids)[0] : null
    }
  }
}

data "azurerm_resource_group" "parent" {
  name = azurerm_mssql_managed_instance.this.resource_group_name
}

data "azapi_resource" "identity" {
  name      = azurerm_mssql_managed_instance.this.name
  parent_id = data.azurerm_resource_group.parent.id
  type      = "Microsoft.Sql/managedInstances@2023-05-01-preview"

  response_export_values = ["identity"]

  depends_on = [azapi_resource_action.sql_managed_instance_patch_identities]
}
