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
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Get current client config for Key Vault access policies
data "azurerm_client_config" "current" {}

## Section to provide a random Azure region for the resource group
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.8.2"
}

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
  location = "malaysiawest"
  name     = module.naming.resource_group.name_unique
  tags = {
    SecurityControl = "Ignore"
  }
}

# Key Vault for TDE key storage
resource "azurerm_key_vault" "tde" {
  location            = azurerm_resource_group.this.location
  name                = "${replace(module.naming.key_vault.name_unique, "-", "")}tde"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  access_policy {
    object_id               = data.azurerm_client_config.current.object_id
    key_permissions         = ["Get", "List", "Create", "Delete", "Update", "Recover", "GetRotationPolicy"]
    secret_permissions      = ["Get", "List", "Set", "Delete"]
    certificate_permissions = ["Get", "List", "Create", "Delete", "Update"]
    tenant_id               = data.azurerm_client_config.current.tenant_id
  }

  network_acls {
    default_action             = "Allow"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.this.id]
  }

  lifecycle {
    ignore_changes = [access_policy]
  }

  depends_on = [azurerm_subnet.this]
}

# Key Vault key for TDE
resource "azurerm_key_vault_key" "tde" {
  key_vault_id = azurerm_key_vault.tde.id
  name         = "sqlmi-tde-key"
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

# Network security group
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

resource "azurerm_network_security_rule" "allow_redirect_outbound" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "allow_redirect_outbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 1100
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
}

resource "azurerm_network_security_rule" "allow_azure_key_vault_outbound" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "allow_azure_key_vault_outbound"
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 1200
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "AzureKeyVault"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
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

# Virtual network and subnet
resource "azurerm_virtual_network" "this" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = "vnet-mi"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  address_prefixes                               = ["10.0.0.0/24"]
  name                                           = "subnet-mi"
  resource_group_name                            = azurerm_resource_group.this.name
  virtual_network_name                           = azurerm_virtual_network.this.name
  service_endpoints                = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql"]
  private_endpoint_network_policies = "Disabled"

  delegation {
    name = "managedInstances"

    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      ]
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
  length           = 16
  override_special = "@#%*()-_=+[]{}:?"
  special          = true
}

resource "azurerm_user_assigned_identity" "sqlmi" {
  location            = azurerm_resource_group.this.location
  name                = "sqlmi-identity"
  resource_group_name = azurerm_resource_group.this.name
}

# Grant Key Vault access to the SQL MI managed identity
resource "azurerm_key_vault_access_policy" "sqlmi" {
  key_vault_id       = azurerm_key_vault.tde.id
  object_id          = azurerm_user_assigned_identity.sqlmi.principal_id
  key_permissions    = ["Get", "WrapKey", "UnwrapKey"]
  secret_permissions = ["Get", "Set", "List"]
  tenant_id          = data.azurerm_client_config.current.tenant_id
}

# This is the module call with TDE enabled
module "sqlmi_tde" {
  source = "../../"

  administrator_login          = "myspecialsqladmin"
  administrator_login_password = random_password.myadminpassword.result
  license_type                 = "LicenseIncluded"
  location                     = azurerm_resource_group.this.location
  name                         = module.naming.mssql_managed_instance.name_unique
  resource_group_name          = azurerm_resource_group.this.name
  sku_name                     = "GP_Gen5"
  storage_size_in_gb           = 32
  subnet_id                    = azurerm_subnet.this.id
  vcores                       = "4"

  # TDE configuration with Key Vault key
  transparent_data_encryption = {
    key_vault_key_id      = azurerm_key_vault_key.tde.id
    auto_rotation_enabled = true
  }

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.sqlmi.id]
  }

  zone_redundant_enabled = false

  depends_on = [
    azurerm_subnet_network_security_group_association.this,
    azurerm_subnet_route_table_association.this,
    azurerm_key_vault_access_policy.sqlmi,
  ]
}
