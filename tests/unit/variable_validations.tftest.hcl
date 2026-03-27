# Unit tests for variable validation rules introduced with the March 2026 feature additions.
# These tests verify that invalid inputs are rejected and valid inputs are accepted.
# All tests use mock providers so no Azure credentials are required.

mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

# ---------------------------------------------------------------------------
# Shared required-variable defaults used across all run blocks
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
}

# ---------------------------------------------------------------------------
# database_format  — valid values
# ---------------------------------------------------------------------------

run "database_format_default_is_sql_server_2022" {
  command = plan

  assert {
    condition     = azurerm_mssql_managed_instance.this.database_format == "SQLServer2022"
    error_message = "Expected database_format default to be 'SQLServer2022'."
  }
}

run "database_format_always_up_to_date" {
  command = plan

  variables {
    database_format = "AlwaysUpToDate"
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.database_format == "AlwaysUpToDate"
    error_message = "Expected database_format to be 'AlwaysUpToDate'."
  }
}

run "database_format_invalid_value_rejected" {
  command = plan

  variables {
    database_format = "SQLServer2019"
  }

  expect_failures = [var.database_format]
}

# ---------------------------------------------------------------------------
# proxy_override  — default changed to Redirect (Oct 2025 Azure default)
# ---------------------------------------------------------------------------

run "proxy_override_default_is_redirect" {
  command = plan

  assert {
    condition     = azurerm_mssql_managed_instance.this.proxy_override == "Redirect"
    error_message = "Expected proxy_override default to be 'Redirect' (Azure default since Oct 2025)."
  }
}

run "proxy_override_accepts_proxy" {
  command = plan

  variables {
    proxy_override = "Proxy"
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.proxy_override == "Proxy"
    error_message = "Expected proxy_override to accept 'Proxy'."
  }
}

run "proxy_override_accepts_default" {
  command = plan

  variables {
    proxy_override = "Default"
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.proxy_override == "Default"
    error_message = "Expected proxy_override to accept 'Default' (legacy Proxy)."
  }
}

run "proxy_override_invalid_value_rejected" {
  command = plan

  variables {
    proxy_override = "INVALID"
  }

  expect_failures = [var.proxy_override]
}

# ---------------------------------------------------------------------------
# storage_account_type  — now includes GZRS
# ---------------------------------------------------------------------------

run "storage_account_type_accepts_gzrs" {
  command = plan

  variables {
    storage_account_type = "GZRS"
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.storage_account_type == "GZRS"
    error_message = "Expected storage_account_type to accept 'GZRS'."
  }
}

run "storage_account_type_accepts_grs" {
  command = plan

  variables {
    storage_account_type = "GRS"
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.storage_account_type == "GRS"
    error_message = "Expected storage_account_type to accept 'GRS'."
  }
}

run "storage_account_type_accepts_lrs" {
  command = plan

  variables {
    storage_account_type = "LRS"
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.storage_account_type == "LRS"
    error_message = "Expected storage_account_type to accept 'LRS'."
  }
}

run "storage_account_type_invalid_value_rejected" {
  command = plan

  variables {
    storage_account_type = "RAGRS"
  }

  expect_failures = [var.storage_account_type]
}

# ---------------------------------------------------------------------------
# hybrid_secondary_usage  — new variable for DR replica licensing
# ---------------------------------------------------------------------------

run "hybrid_secondary_usage_default_is_null" {
  command = plan

  assert {
    condition     = azurerm_mssql_managed_instance.this.hybrid_secondary_usage == null
    error_message = "Expected hybrid_secondary_usage default to be null."
  }
}

run "hybrid_secondary_usage_accepts_passive" {
  command = plan

  variables {
    hybrid_secondary_usage = "Passive"
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.hybrid_secondary_usage == "Passive"
    error_message = "Expected hybrid_secondary_usage to accept 'Passive'."
  }
}

run "hybrid_secondary_usage_accepts_active" {
  command = plan

  variables {
    hybrid_secondary_usage = "Active"
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.hybrid_secondary_usage == "Active"
    error_message = "Expected hybrid_secondary_usage to accept 'Active'."
  }
}

run "hybrid_secondary_usage_invalid_value_rejected" {
  command = plan

  variables {
    hybrid_secondary_usage = "Standby"
  }

  expect_failures = [var.hybrid_secondary_usage]
}

# ---------------------------------------------------------------------------
# start_stop_schedule  — disabled by default, validated when provided
# ---------------------------------------------------------------------------

run "start_stop_schedule_disabled_by_default" {
  command = plan

  assert {
    condition     = var.start_stop_schedule == null
    error_message = "Expected start_stop_schedule to be null (disabled) by default."
  }
}

run "start_stop_schedule_empty_schedule_list_rejected" {
  command = plan

  variables {
    start_stop_schedule = {
      schedule = []
    }
  }

  expect_failures = [var.start_stop_schedule]
}

run "start_stop_schedule_valid_with_single_weekday_entry" {
  command = plan

  variables {
    start_stop_schedule = {
      description = "Business hours"
      timezone_id = "Pacific Standard Time"
      schedule = [
        {
          start_day  = "Monday"
          start_time = "08:00"
          stop_day   = "Friday"
          stop_time  = "18:00"
        }
      ]
    }
  }

  assert {
    condition     = length(azurerm_mssql_managed_instance_start_stop_schedule.this) == 1
    error_message = "Expected one start_stop_schedule resource to be created."
  }
}

run "start_stop_schedule_multiple_entries" {
  command = plan

  variables {
    start_stop_schedule = {
      timezone_id = "UTC"
      schedule = [
        {
          start_day  = "Monday"
          start_time = "07:00"
          stop_day   = "Monday"
          stop_time  = "19:00"
        },
        {
          start_day  = "Wednesday"
          start_time = "07:00"
          stop_day   = "Wednesday"
          stop_time  = "19:00"
        }
      ]
    }
  }

  assert {
    condition     = length(azurerm_mssql_managed_instance_start_stop_schedule.this) == 1
    error_message = "Expected start_stop_schedule resource to be created with multiple entries."
  }
}

# ---------------------------------------------------------------------------
# free_offer_enabled  — disabled by default
# ---------------------------------------------------------------------------

run "free_offer_disabled_by_default" {
  command = plan

  assert {
    condition     = var.free_offer_enabled == false
    error_message = "Expected free_offer_enabled to be false by default."
  }
}

run "free_offer_enabled_triggers_api_patch" {
  command = plan

  variables {
    free_offer_enabled = true
  }

  assert {
    condition     = length(azapi_resource_action.sql_managed_instance_patch_identities) == 1
    error_message = "Expected the azapi PATCH resource to be triggered when free_offer_enabled is true."
  }
}
