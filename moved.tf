# State migration blocks to preserve existing resources during provider conversion
# This file ensures that azurerm resources are properly moved to their azapi equivalents
# without requiring resource destruction and recreation.

# Core Managed Instance - azurerm to azapi
moved {
  from = azurerm_mssql_managed_instance.this
  to   = azapi_resource.mssql_managed_instance
}

# Active Directory Administrator
moved {
  from = azurerm_mssql_managed_instance_active_directory_administrator.this
  to   = azapi_resource.mssql_managed_instance_active_directory_administrator
}

# Managed Databases
moved {
  from = azurerm_mssql_managed_database.this
  to   = azapi_resource.mssql_managed_database
}

# Failover Groups
moved {
  from = azurerm_mssql_managed_instance_failover_group.this
  to   = azapi_resource.mssql_managed_instance_failover_group
}

# Private Endpoints - Managed DNS Zone Groups
moved {
  from = azurerm_private_endpoint.this_managed_dns_zone_groups
  to   = azapi_resource.private_endpoint_managed_dns_zone_groups
}

# Private Endpoints - Unmanaged DNS Zone Groups
moved {
  from = azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  to   = azapi_resource.private_endpoint_unmanaged_dns_zone_groups
}

# Private Endpoint Application Security Group Association
moved {
  from = azurerm_private_endpoint_application_security_group_association.this
  to   = azapi_resource.private_endpoint_application_security_group_association
}

# Transparent Data Encryption - migrating from azurerm to azapi_resource_action
moved {
  from = azurerm_mssql_managed_instance_transparent_data_encryption.this
  to   = azapi_resource_action.mssql_managed_instance_transparent_data_encryption
}

# Management Lock
moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.management_lock
}

# Role Assignments - from azurerm to azapi
moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignment
}

# Role Assignment for Vulnerability Assessment Storage
moved {
  from = azurerm_role_assignment.sqlmi_system_assigned
  to   = azapi_resource.role_assignment_vulnerability_assessment_storage
}

# Diagnostic Settings
moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource_action.diagnostic_setting
}
