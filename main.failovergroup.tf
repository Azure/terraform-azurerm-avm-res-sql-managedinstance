resource "azurerm_mssql_managed_instance_failover_group" "this" {
  count = var.failover_group != {} ? 1 : 0

  location                                  = var.failover_group.location
  managed_instance_id                       = azurerm_mssql_managed_instance.this.id
  name                                      = var.failover_group.name
  partner_managed_instance_id               = var.failover_group.partner_managed_instance_id
  readonly_endpoint_failover_policy_enabled = var.failover_group.readonly_endpoint_failover_policy_enabled

  dynamic "read_write_endpoint_failover_policy" {
    for_each = [var.failover_group.read_write_endpoint_failover_policy]
    content {
      mode          = read_write_endpoint_failover_policy.value.mode
      grace_minutes = read_write_endpoint_failover_policy.value.grace_minutes
    }
  }
  dynamic "timeouts" {
    for_each = var.failover_group.timeouts == null ? [] : [var.failover_group.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

