<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.8.2"
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
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "eastus" #module.regions.regions[random_integer.region_index.result].name
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
  priority                    = 106
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
  location            = azurerm_resource_group.this.location
  name                = "vnet-mi"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
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

  administrator_login          = "myspecialsqladmin"
  administrator_login_password = random_password.myadminpassword.result
  license_type                 = "LicenseIncluded"
  # source             = "Azure/avm-res-sql-managedinstance/azurerm"
  # ...
  location            = azurerm_resource_group.this.location
  name                = module.naming.mssql_managed_instance.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "GP_Gen5"
  storage_size_in_gb  = 32
  subnet_id           = azurerm_subnet.this.id
  vcores              = "4"
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.uami.id]
  }
  timeouts = {
    create = "60m"
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.this,
    azurerm_subnet_route_table_association.this,
  ]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4.0.0, < 5.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_network_security_rule.allow_health_probe_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_network_security_rule.allow_management_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_network_security_rule.allow_management_outbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_network_security_rule.allow_misubnet_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_network_security_rule.allow_misubnet_outbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_network_security_rule.allow_tds_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_network_security_rule.deny_all_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_network_security_rule.deny_all_outbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_route_table.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)
- [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_subnet_route_table_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) (resource)
- [azurerm_user_assigned_identity.uami](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_password.myadminpassword](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.2

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: 0.8.2

### <a name="module_sqlmi_test"></a> [sqlmi\_test](#module\_sqlmi\_test)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->