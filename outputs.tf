output "identity" {
  description = "Managed identities for the SQL MI instance.  This is not available from the `resource` output because AzureRM doesn't yet support adding both User and System Assigned identities."
  value       = try(jsondecode(data.azapi_resource.identity.output).identity, null)
}

output "is_general_purpose_v2" {
  description = "Whether the SQL Managed Instance is using the Next-gen General Purpose (GPv2) service tier."
  value       = try(jsondecode(data.azapi_resource.identity.output).properties.isGeneralPurposeV2, false)
}

output "memory_size_in_gb" {
  description = "The actual memory size in GB allocated to the SQL Managed Instance."
  value       = try(jsondecode(data.azapi_resource.identity.output).properties.memorySizeInGB, null)
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = "This is the full output for the resource."
  value       = azurerm_mssql_managed_instance.this
}

output "resource_id" {
  description = "This is the resource ID of the resource."
  value       = azurerm_mssql_managed_instance.this.id
}

output "service_principal" {
  description = "The system-assigned service principal details for the SQL Managed Instance. Required for Windows Authentication with Microsoft Entra ID."
  value       = try(jsondecode(data.azapi_resource.identity.output).properties.servicePrincipal, null)
}

output "storage_iops" {
  description = "The actual storage IOPS allocated to the SQL Managed Instance."
  value       = try(jsondecode(data.azapi_resource.identity.output).properties.storageIOps, null)
}
