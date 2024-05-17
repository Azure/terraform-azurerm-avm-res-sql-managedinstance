locals {
  resource_group_name = "Test-RG"
  location            = "eastus"
  subnet_name         = "${random_pet.prefix.id}-subnet"
  vnet_name           = "${random_pet.prefix.id}-vnet"
  nsg_name            = "${random_pet.prefix.id}-nsg"
  route_table_name    = "${random_pet.prefix.id}-rt"
  mssql_instance_name = "${random_pet.prefix.id}-mssql"
  prefix              = "avm"
  license_type        = "LicenseIncluded"
  sku_name            = "BC_Gen5"
  vcores              = 4
  storage_size_in_gb  = 32
}
