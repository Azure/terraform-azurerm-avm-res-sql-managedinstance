output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "network_security_group_id" {
  value = azurerm_network_security_group.example.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.example.id
}

output "subnet_id" {
  value = azurerm_subnet.example.id
}

output "route_table_id" {
  value = azurerm_route_table.example.id
}

output "managed_instance_id" {
  value = azurerm_mssql_managed_instance.main.id
}
