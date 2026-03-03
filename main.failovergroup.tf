resource "azapi_resource" "mssql_managed_instance_failover_group" {
  for_each = var.failover_group

  type      = "Microsoft.Sql/locations/instanceFailoverGroups@2023-05-01-preview"
  name      = each.value.name
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Sql/locations/${each.value.location}"

  body = {
    properties = {
      managedInstancePairs = [
        {
          partnerServer = {
            id = each.value.partner_managed_instance_id
          }
          primaryServer = {
            id = azapi_resource.mssql_managed_instance.id
          }
        }
      ]
      readOnlyEndpoint = {
        failoverPolicy = each.value.readonly_endpoint_failover_policy_enabled ? "Automatic" : "Manual"
      }
      readWriteEndpoint = {
        failoverPolicy                         = each.value.read_write_endpoint_failover_policy.mode
        failoverWithDataLossGracePeriodMinutes = each.value.read_write_endpoint_failover_policy.grace_minutes
      }
    }
  }

  schema_validation_enabled = false

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [
    azapi_resource.mssql_managed_database,
  ]
}

