# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance_start_stop_schedule
# https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/instance-stop-start-how-to
resource "azurerm_mssql_managed_instance_start_stop_schedule" "this" {
  count = var.start_stop_schedule == null ? 0 : 1

  managed_instance_id = azurerm_mssql_managed_instance.this.id
  description         = var.start_stop_schedule.description
  timezone_id         = var.start_stop_schedule.timezone_id

  dynamic "schedule" {
    for_each = var.start_stop_schedule.schedule

    content {
      start_day  = schedule.value.start_day
      start_time = schedule.value.start_time
      stop_day   = schedule.value.stop_day
      stop_time  = schedule.value.stop_time
    }
  }

  dynamic "timeouts" {
    for_each = try(var.start_stop_schedule.timeouts, null) == null ? [] : [var.start_stop_schedule.timeouts]

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
