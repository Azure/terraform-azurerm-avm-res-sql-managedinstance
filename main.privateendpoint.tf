resource "azapi_resource" "private_endpoint_managed_dns_zone_groups" {
  for_each = var.private_endpoints

  location  = each.value.location != null ? each.value.location : var.location
  name      = each.value.name != null ? each.value.name : "pe-${var.name}"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  type      = "Microsoft.Network/privateEndpoints@2023-04-01"
  body = {
    properties = {
      subnet = {
        id = each.value.subnet_resource_id
      }
      privateLinkServiceConnections = [
        {
          name = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
          properties = {
            privateLinkServiceId = azapi_resource.mssql_managed_instance.id
            groupIds             = ["managedInstance"]
            requestMessage       = null
            privateLinkServiceConnectionState = {
              status      = "Approved"
              description = "Auto-approved by Terraform"
            }
          }
        }
      ]
      ipConfigurations = [
        for ip_config in each.value.ip_configurations : {
          name = ip_config.name
          properties = {
            privateIPAddress = ip_config.private_ip_address
            groupId          = "managedInstance"
            memberName       = "managedInstance"
          }
        }
      ]
      privateDnsZoneConfigs = length(each.value.private_dns_zone_resource_ids) > 0 ? [
        for zone_id in each.value.private_dns_zone_resource_ids : {
          name = "config-${basename(zone_id)}"
          properties = {
            privateDnsZoneId = zone_id
          }
        }
      ] : null
      customNetworkInterfaceName = each.value.network_interface_name
    }
    tags = each.value.tags
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.mssql_managed_instance,
  ]
}

# The PE resource when we are managing **not** the private_dns_zone_group block
# An example use case is customers using Azure Policy to create private DNS zones
# e.g. <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale>
resource "azapi_resource" "private_endpoint_unmanaged_dns_zone_groups" {
  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  location  = each.value.location != null ? each.value.location : var.location
  name      = each.value.name != null ? each.value.name : "pe-${var.name}"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  type      = "Microsoft.Network/privateEndpoints@2023-04-01"
  body = {
    properties = {
      subnet = {
        id = each.value.subnet_resource_id
      }
      privateLinkServiceConnections = [
        {
          name = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
          properties = {
            privateLinkServiceId = azapi_resource.mssql_managed_instance.id
            groupIds             = ["managedInstance"]
            requestMessage       = null
            privateLinkServiceConnectionState = {
              status      = "Approved"
              description = "Auto-approved by Terraform"
            }
          }
        }
      ]
      ipConfigurations = [
        for ip_config in each.value.ip_configurations : {
          name = ip_config.name
          properties = {
            privateIPAddress = ip_config.private_ip_address
            groupId          = "managedInstance"
            memberName       = "managedInstance"
          }
        }
      ]
      customNetworkInterfaceName = each.value.network_interface_name
    }
    tags = each.value.tags
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.mssql_managed_instance,
  ]

  lifecycle {
    ignore_changes = [body.properties.privateDnsZoneConfigs]
  }
}

resource "azapi_resource" "private_endpoint_application_security_group_association" {
  for_each = local.private_endpoint_application_security_group_associations

  name      = "asg-${each.value.asg_name}"
  parent_id = "${var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoint_managed_dns_zone_groups[each.value.pe_key].id : azapi_resource.private_endpoint_unmanaged_dns_zone_groups[each.value.pe_key].id}/privateLinkServiceConnections/${each.value.pe_key}"
  type      = "Microsoft.Network/privateEndpoints/privateLinkServiceConnections/groupMembers@2023-04-01"
  body = {
    properties = {
      applicationSecurityGroup = {
        id = each.value.asg_resource_id
      }
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
