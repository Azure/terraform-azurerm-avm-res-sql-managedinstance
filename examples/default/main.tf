terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_network_security_group" "this" {
  location            = azurerm_resource_group.this.location
  name                = "mi-security-group"
  resource_group_name = azurerm_resource_group.this.name
}


resource "azurerm_network_security_rule" "allow_management_inbound" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_management_inbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 106
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "*"
  destination_port_ranges     = ["9000", "9003", "1438", "1440", "1452"]
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_misubnet_inbound" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_misubnet_inbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 200
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/24"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_health_probe_inbound" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_health_probe_inbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 300
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_tds_inbound" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_tds_inbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 1000
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  access                      = "Deny"
  direction                   = "Inbound"
  name                        = "deny_all_inbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 4096
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_management_outbound" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "allow_management_outbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 102
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "*"
  destination_port_ranges     = ["80", "443", "12000"]
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_misubnet_outbound" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "allow_misubnet_outbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 200
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/24"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "deny_all_outbound" {
  access                      = "Deny"
  direction                   = "Outbound"
  name                        = "deny_all_outbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 4096
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  source_port_range           = "*"
}

resource "azurerm_virtual_network" "this" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = "vnet-mi"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "subnet-mi"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name

  delegation {
    name = "managedinstancedelegation"

    service_delegation {
      name    = "Microsoft.Sql/managedInstances"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  network_security_group_id = azurerm_network_security_group.this.id
  subnet_id                 = azurerm_subnet.this.id
}

resource "azurerm_route_table" "this" {
  location                      = azurerm_resource_group.this.location
  name                          = "routetable-mi"
  resource_group_name           = azurerm_resource_group.this.name
  bgp_route_propagation_enabled = false

  depends_on = [
    azurerm_subnet.this,
  ]
}

resource "azurerm_subnet_route_table_association" "this" {
  route_table_id = azurerm_route_table.this.id
  subnet_id      = azurerm_subnet.this.id
}

resource "random_password" "myadminpassword" {
  length = 16
  keepers = {
    trigger = timestamp()
  }
  override_special = "@#%*()-_=+[]{}:?"
  special          = true
}

resource "azurerm_user_assigned_identity" "uami" {
  location            = azurerm_resource_group.this.location
  name                = "user-identity"
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
module "sqlmi_test" {
  source = "../../"
  # source             = "Azure/avm-res-sql-managedinstance/azurerm"
  # ...
  location                     = azurerm_resource_group.this.location
  name                         = module.naming.mssql_managed_instance.name_unique
  resource_group_name          = azurerm_resource_group.this.name
  administrator_login          = "myspecialsqladmin"
  administrator_login_password = random_password.myadminpassword.result
  license_type                 = "LicenseIncluded"
  sku_name                     = "GP_Gen5"
  storage_size_in_gb           = 32
  subnet_id                    = azurerm_subnet.this.id
  vcores                       = "4"
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.uami.id]
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.this,
    azurerm_subnet_route_table_association.this,
  ]
}
