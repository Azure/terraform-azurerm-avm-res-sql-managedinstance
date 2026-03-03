resource "azapi_resource" "mssql_managed_database" {
  for_each = var.databases

  name      = each.value.name
  parent_id = azapi_resource.mssql_managed_instance.id
  type      = "Microsoft.Sql/managedInstances/databases@2023-05-01-preview"
  body = {
    properties = merge(
      {
        restorePointInTime = each.value.point_in_time_restore != null ? each.value.point_in_time_restore.restore_point_in_time : null
        sourceDatabaseId   = each.value.point_in_time_restore != null ? each.value.point_in_time_restore.source_database_id : null
      },
      each.value.short_term_retention_days != null ? {
        shortTermRetentionPolicy = {
          retentionDays = each.value.short_term_retention_days
        }
      } : {},
      each.value.long_term_retention_policy != null ? {
        longTermRetentionPolicy = {
          monthlyRetention = each.value.long_term_retention_policy.monthly_retention
          weekOfYear       = each.value.long_term_retention_policy.week_of_year
          weeklyRetention  = each.value.long_term_retention_policy.weekly_retention
          yearlyRetention  = each.value.long_term_retention_policy.yearly_retention
        }
      } : {}
    )
    tags = each.value.tags
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

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
    azapi_resource_action.sql_advanced_threat_protection,
  ]
}

