# Plan-level tests that verify the combined behaviour of multiple new features.
# Tests that the Terraform plan is generated correctly when the new variables are used together.
# All tests use mock providers — no Azure credentials required.

mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

# ---------------------------------------------------------------------------
# Shared base variables
# ---------------------------------------------------------------------------
variables {
  location            = "eastus"
  name                = "test-sqlmi"
  resource_group_name = "test-rg"
  license_type        = "LicenseIncluded"
  sku_name            = "GP_Gen5"
  storage_size_in_gb  = 32
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
  vcores              = 4
  administrator_login = "sqladminuser"

  administrator_login_password = "P@ssw0rd1234!"
  zone_redundant_enabled       = false
}

# ---------------------------------------------------------------------------
# AlwaysUpToDate policy (SQL Server 2025 engine) with GPv2 and GZRS backup storage
# ---------------------------------------------------------------------------
run "always_up_to_date_policy_with_gpv2_and_gzrs" {
  command = plan

  variables {
    database_format       = "AlwaysUpToDate"
    is_general_purpose_v2 = true
    storage_account_type  = "GZRS"
    storage_size_in_gb    = 128
    memory_size_in_gb     = 32
    storage_iops          = 3000
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.database_format == "AlwaysUpToDate"
    error_message = "Expected AlwaysUpToDate update policy to be set."
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.storage_account_type == "GZRS"
    error_message = "Expected GZRS backup storage to be configured."
  }

  assert {
    condition     = length(azapi_resource_action.sql_managed_instance_patch_identities) == 1
    error_message = "Expected GPv2 PATCH resource to be created."
  }
}

# ---------------------------------------------------------------------------
# Always-up-to-date policy with Redirect connection and Passive DR replica
# ---------------------------------------------------------------------------
run "always_up_to_date_with_redirect_and_passive_replica" {
  command = plan

  variables {
    database_format        = "AlwaysUpToDate"
    proxy_override         = "Redirect"
    hybrid_secondary_usage = "Passive"
    license_type           = "BasePrice"
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.database_format == "AlwaysUpToDate"
    error_message = "Expected AlwaysUpToDate database format."
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.hybrid_secondary_usage == "Passive"
    error_message = "Expected Passive hybrid secondary usage for DR replica cost savings."
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.proxy_override == "Redirect"
    error_message = "Expected Redirect connection type."
  }
}

# ---------------------------------------------------------------------------
# Free offer — pricingModel patch triggered
# ---------------------------------------------------------------------------
run "free_offer_with_sql_server_2022" {
  command = plan

  variables {
    database_format    = "SQLServer2022"
    free_offer_enabled = true
  }

  assert {
    condition     = length(azapi_resource_action.sql_managed_instance_patch_identities) == 1
    error_message = "Expected azapi PATCH resource to be created for free offer."
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.database_format == "SQLServer2022"
    error_message = "Expected SQLServer2022 database format with free offer."
  }
}

# ---------------------------------------------------------------------------
# Start/stop schedule — schedule-based with business hours
# ---------------------------------------------------------------------------
run "start_stop_schedule_creates_resource" {
  command = plan

  variables {
    start_stop_schedule = {
      description = "Weekday business hours"
      timezone_id = "UTC"
      schedule = [
        {
          start_day  = "Monday"
          start_time = "07:00"
          stop_day   = "Monday"
          stop_time  = "19:00"
        },
        {
          start_day  = "Friday"
          start_time = "07:00"
          stop_day   = "Friday"
          stop_time  = "19:00"
        }
      ]
    }
  }

  assert {
    condition     = length(azurerm_mssql_managed_instance_start_stop_schedule.this) == 1
    error_message = "Expected start_stop_schedule resource to be created."
  }
}

# ---------------------------------------------------------------------------
# Start/stop schedule — cross-day entry (start Monday, stop Tuesday)
# ---------------------------------------------------------------------------
run "start_stop_schedule_cross_day" {
  command = plan

  variables {
    start_stop_schedule = {
      timezone_id = "Pacific Standard Time"
      schedule = [
        {
          start_day  = "Monday"
          start_time = "22:00"
          stop_day   = "Tuesday"
          stop_time  = "06:00"
        }
      ]
    }
  }

  assert {
    condition     = length(azurerm_mssql_managed_instance_start_stop_schedule.this) == 1
    error_message = "Expected start_stop_schedule resource to be created for AlwaysOff."
  }
}

# ---------------------------------------------------------------------------
# No optional features — start_stop_schedule and free_offer omitted
# ---------------------------------------------------------------------------
run "defaults_no_optional_features" {
  command = plan

  assert {
    condition     = length(azurerm_mssql_managed_instance_start_stop_schedule.this) == 0
    error_message = "Expected no start_stop_schedule resource when not configured."
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.database_format == "SQLServer2022"
    error_message = "Expected default database_format of SQLServer2022."
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.proxy_override == "Redirect"
    error_message = "Expected default proxy_override of Redirect."
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.storage_account_type == "ZRS"
    error_message = "Expected default storage_account_type of ZRS."
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.hybrid_secondary_usage == null
    error_message = "Expected hybrid_secondary_usage to be null when not specified."
  }
}
