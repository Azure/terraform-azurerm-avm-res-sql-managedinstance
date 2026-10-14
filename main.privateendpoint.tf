resource "azurerm_private_endpoint" "this_managed_dns_zone_groups" {
  for_each = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pe-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azurerm_mssql_managed_instance.this.id
    subresource_names              = [coalesce(each.value.subresource_name, "managedInstance")]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = coalesce(ip_configuration.value.member_name, "managedInstance")
      subresource_name   = coalesce(each.value.subresource_name, "managedInstance")
    }
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}

# The PE resource when we are managing **not** the private_dns_zone_group block
# An example use case is customers using Azure Policy to create private DNS zones
# e.g. <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale>
resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pe-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azurerm_mssql_managed_instance.this.id
    subresource_names              = [coalesce(each.value.subresource_name, "managedInstance")]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = coalesce(ip_configuration.value.member_name, "managedInstance")
      subresource_name   = coalesce(each.value.subresource_name, "managedInstance")
    }
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_key].id : azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_key].id
}

module "private_endpoint_interfaces" {
  source   = "Azure/avm-utl-interfaces/azure"
  version  = "0.7.0"
  for_each = var.private_endpoints

  enable_telemetry = var.enable_telemetry
  private_endpoints = {
    this = merge(each.value, {
      lock             = local.private_endpoint_locks[each.key]
      subresource_name = coalesce(each.value.subresource_name, "managedInstance")
    })
  }
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_group
  private_endpoints_scope                 = azurerm_mssql_managed_instance.this.id
  role_assignment_definition_scope        = azurerm_mssql_managed_instance.this.id
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = local.private_endpoint_role_assignments

  name                = module.private_endpoint_interfaces[each.value.endpoint_key].role_assignments_private_endpoint_azapi["this-${each.value.assignment_key}"].name
  parent_id           = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.endpoint_key].id : azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.endpoint_key].id
  type                = var.resource_types.authorization_role_assignments
  body                = module.private_endpoint_interfaces[each.value.endpoint_key].role_assignments_private_endpoint_azapi["this-${each.value.assignment_key}"].body
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  replace_triggers_refs = [
    "properties.principalId",
    "properties.roleDefinitionId",
    "properties.delegatedManagedIdentityResourceId",
  ]
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = { for key, lock in local.private_endpoint_locks : key => lock if lock != null }

  name                   = coalesce(each.value.name, "lock-${each.value.kind}")
  parent_id              = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.key].id : azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.key].id
  type                   = var.resource_types.authorization_locks
  body                   = module.private_endpoint_interfaces[each.key].lock_private_endpoint_azapi.this.body
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [
    azapi_resource.private_endpoint_role_assignments,
    azurerm_private_endpoint_application_security_group_association.this,
  ]
}
