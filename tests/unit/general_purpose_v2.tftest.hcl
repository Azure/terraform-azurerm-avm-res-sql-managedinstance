mock_provider "azapi" {
  mock_data "azapi_resource" {
    defaults = {
      output = {
        properties = {
          servicePrincipal = {
            type = "None"
          }
        }
      }
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            role_name = "Reader"
          },
        ]
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  mock_resource "azurerm_mssql_managed_instance" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Sql/managedInstances/test-sqlmi"
    }
  }
}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "11111111-1111-1111-1111-111111111111"
    }
  }
}

variables {
  administrator_login          = "testadmin"
  administrator_login_password = "SyntheticTestPassword!42"
  enable_telemetry             = false
  license_type                 = "LicenseIncluded"
  location                     = "eastus"
  name                         = "test-sqlmi"
  resource_group_name          = "rg-sqlmi"
  sku_name                     = "GP_Gen5"
  storage_size_in_gb           = 32
  subnet_id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/instance"
  vcores                       = 4
  managed_identities = {
    system_assigned = true
  }
}

run "general_purpose_v2_disabled_by_default" {
  command = plan

  assert {
    condition     = azurerm_mssql_managed_instance.this.general_purpose_v2_enabled == false
    error_message = "general_purpose_v2_enabled should default to false on azurerm_mssql_managed_instance."
  }
}

run "general_purpose_v2_set_on_create" {
  command = plan

  variables {
    is_general_purpose_v2 = true
  }

  assert {
    condition     = azurerm_mssql_managed_instance.this.general_purpose_v2_enabled == true
    error_message = "is_general_purpose_v2 must be passed to azurerm_mssql_managed_instance.general_purpose_v2_enabled so the instance is created as GPv2 (and existing GPv2 instances do not plan true -> false)."
  }
}
