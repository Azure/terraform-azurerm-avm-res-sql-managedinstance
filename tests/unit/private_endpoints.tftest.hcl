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

override_resource {
  target = azurerm_private_endpoint.this_managed_dns_zone_groups
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/privateEndpoints/managed"
  }
}

override_resource {
  target = azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/privateEndpoints/unmanaged"
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

run "empty_endpoints_preserve_defaults" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0 &&
      length(module.private_endpoint_interfaces) == 0 &&
      length(output.private_endpoints) == 0
    )
    error_message = "Omitted private endpoints must not create endpoints or extension resources."
  }

  assert {
    condition = (
      azapi_resource_action.sql_managed_instance_patch_identities[0].retry == null &&
      azapi_resource_action.sql_managed_instance_patch_identities[0].type == "Microsoft.Sql/managedInstances@2025-02-01-preview"
    )
    error_message = "Existing SQL API and resource-specific retry defaults must remain unchanged."
  }
}

run "managed_endpoint_preserves_legacy_defaults" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      default = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.1.4"
          }
        }
      }
    }
  }

  assert {
    condition = (
      azurerm_private_endpoint.this_managed_dns_zone_groups["default"].name == "pe-test-sqlmi" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["default"].location == "eastus" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["default"].resource_group_name == "rg-sqlmi" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["default"].private_service_connection[0].name == "pse-test-sqlmi" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["default"].private_service_connection[0].subresource_names == tolist(["managedInstance"]) &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["default"].ip_configuration[0].member_name == "managedInstance" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["default"].ip_configuration[0].subresource_name == "managedInstance" &&
      length(azurerm_private_endpoint.this_managed_dns_zone_groups["default"].private_dns_zone_group) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0
    )
    error_message = "Managed endpoints must retain existing addresses, naming, location, static IP, service and DNS defaults."
  }

  assert {
    condition     = output.private_endpoints["default"].id == azurerm_private_endpoint.this_managed_dns_zone_groups["default"].id
    error_message = "The endpoint output must retain the managed endpoint resource shape."
  }
}

run "managed_endpoint_applies_all_supported_settings" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      custom = {
        name                            = "pe-custom"
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        subresource_name                = "managedInstance"
        location                        = "westus2"
        resource_group_name             = "rg-endpoints"
        network_interface_name          = "nic-custom"
        private_service_connection_name = "connection-custom"
        private_dns_zone_group_name     = "custom-dns"
        private_dns_zone_resource_ids   = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.example.database.windows.net"]
        application_security_group_associations = {
          app = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/applicationSecurityGroups/app"
        }
        tags = {
          purpose = "endpoint"
        }
        ip_configurations = {
          primary = {
            name               = "custom-ip"
            private_ip_address = "10.0.1.5"
            member_name        = "managedInstance"
          }
        }
        lock = {
          kind  = "ReadOnly"
          name  = "custom-lock"
          notes = "Protect this endpoint."
        }
        role_assignments = {
          by_name = {
            name                                   = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name             = "Reader"
            principal_id                           = "33333333-3333-3333-3333-333333333333"
            principal_type                         = "ServicePrincipal"
            description                            = "Read this endpoint."
            skip_service_principal_aad_check       = true
            condition                              = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEqualsIgnoreCase 'example'"
            condition_version                      = "2.0"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
          }
          by_id = {
            role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            principal_id               = "44444444-4444-4444-4444-444444444444"
            principal_type             = "Group"
          }
        }
      }
    }
  }

  assert {
    condition = (
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].name == "pe-custom" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].location == "westus2" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].resource_group_name == "rg-endpoints" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].custom_network_interface_name == "nic-custom" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].tags["purpose"] == "endpoint" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].private_service_connection[0].name == "connection-custom" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].private_service_connection[0].private_connection_resource_id == azurerm_mssql_managed_instance.this.id &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].ip_configuration[0].name == "custom-ip" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].ip_configuration[0].private_ip_address == "10.0.1.5" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].ip_configuration[0].member_name == "managedInstance" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].private_dns_zone_group[0].name == "custom-dns" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].private_dns_zone_group[0].private_dns_zone_ids == tolist(var.private_endpoints["custom"].private_dns_zone_resource_ids) &&
      azurerm_private_endpoint_application_security_group_association.this["custom-app"].application_security_group_id == var.private_endpoints["custom"].application_security_group_associations["app"] &&
      azurerm_private_endpoint_application_security_group_association.this["custom-app"].private_endpoint_id == azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].id
    )
    error_message = "Existing endpoint, DNS, static IP and application security group settings must be preserved."
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_locks["custom"].parent_id == azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].id &&
      azapi_resource.private_endpoint_locks["custom"].name == "custom-lock" &&
      azapi_resource.private_endpoint_locks["custom"].body.properties.level == "ReadOnly" &&
      azapi_resource.private_endpoint_locks["custom"].body.properties.notes == "Protect this endpoint."
    )
    error_message = "The endpoint lock must use its endpoint scope, explicit name, level and notes."
  }

  assert {
    condition = (
      length(azapi_resource.private_endpoint_role_assignments) == 2 &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_name"])].parent_id == azurerm_private_endpoint.this_managed_dns_zone_groups["custom"].id &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_name"])].name == "22222222-2222-2222-2222-222222222222" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_name"])].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_name"])].body.properties.principalId == "33333333-3333-3333-3333-333333333333" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_name"])].body.properties.principalType == "ServicePrincipal" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_name"])].body.properties.description == "Read this endpoint." &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_name"])].body.properties.condition == var.private_endpoints["custom"].role_assignments["by_name"].condition &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_name"])].body.properties.conditionVersion == "2.0" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_name"])].body.properties.delegatedManagedIdentityResourceId == var.private_endpoints["custom"].role_assignments["by_name"].delegated_managed_identity_resource_id &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_id"])].name == "11111111-1111-1111-1111-111111111111" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_id"])].body.properties.roleDefinitionId == var.private_endpoints["custom"].role_assignments["by_id"].role_definition_id_or_name &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["custom", "by_id"])].body.properties.principalType == "Group"
    )
    error_message = "Named and generated role assignments must preserve every supported role property and resolve role names."
  }
}

run "unmanaged_dns_endpoints_apply_extensions" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      unmanaged = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.example.database.windows.net"]
        subresource_name              = "managedInstance"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.1.6"
            member_name        = null
          }
        }
        lock = {
          kind = "CanNotDelete"
        }
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "33333333-3333-3333-3333-333333333333"
          }
        }
      }
    }
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["unmanaged"].private_dns_zone_group) == 0 &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["unmanaged"].private_service_connection[0].subresource_names == tolist(["managedInstance"]) &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["unmanaged"].ip_configuration[0].member_name == "managedInstance" &&
      azapi_resource.private_endpoint_locks["unmanaged"].parent_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["unmanaged"].id &&
      azapi_resource.private_endpoint_locks["unmanaged"].name == "lock-CanNotDelete" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["unmanaged", "reader"])].parent_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["unmanaged"].id &&
      output.private_endpoints["unmanaged"].id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["unmanaged"].id
    )
    error_message = "Unmanaged DNS mode must preserve endpoint selection and apply extensions to the unmanaged endpoint."
  }
}

run "endpoint_locks_inherit_override_and_opt_out" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    lock = {
      kind = "CanNotDelete"
    }
    private_endpoints = {
      inherited = {
        name               = "pe-inherited"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
      }
      overridden = {
        name               = "pe-overridden"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        lock = {
          kind  = "ReadOnly"
          notes = "Endpoint override."
        }
      }
      unlocked = {
        name               = "pe-unlocked"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        lock = {
          kind = "None"
        }
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.private_endpoint_locks) == 2 &&
      azapi_resource.private_endpoint_locks["inherited"].body.properties.level == "CanNotDelete" &&
      azapi_resource.private_endpoint_locks["inherited"].name == "lock-CanNotDelete" &&
      azapi_resource.private_endpoint_locks["overridden"].body.properties.level == "ReadOnly" &&
      azapi_resource.private_endpoint_locks["overridden"].body.properties.notes == "Endpoint override." &&
      !contains(keys(azapi_resource.private_endpoint_locks), "unlocked")
    )
    error_message = "Endpoint locks must inherit the primary lock unless explicitly overridden or disabled."
  }
}

run "arbitrary_endpoint_and_role_keys_remain_distinct" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      a-b = {
        name               = "pe-first"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        role_assignments = {
          c = {
            name                       = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name = "Reader"
            principal_id               = "33333333-3333-3333-3333-333333333333"
          }
        }
      }
      a = {
        name               = "pe-second"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        role_assignments = {
          b-c = {
            name                       = "44444444-4444-4444-4444-444444444444"
            role_definition_id_or_name = "Reader"
            principal_id               = "55555555-5555-5555-5555-555555555555"
          }
        }
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.private_endpoint_role_assignments) == 2 &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["a-b", "c"])].name == "22222222-2222-2222-2222-222222222222" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["a", "b-c"])].name == "44444444-4444-4444-4444-444444444444"
    )
    error_message = "Arbitrary endpoint and role keys must not collide when their hyphenated concatenations match."
  }
}

run "extension_resource_controls_are_forwarded" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    resource_types = {
      authorization_locks            = "Microsoft.Authorization/locks@2017-04-01"
      authorization_role_assignments = "Microsoft.Authorization/roleAssignments@2020-10-01-preview"
    }
    retry = {
      error_message_regex  = ["ScopeLocked"]
      interval_seconds     = 15
      max_interval_seconds = 60
    }
    timeouts = {
      create = "20m"
      read   = "5m"
      update = "20m"
      delete = "10m"
    }
    ignore_body_changes = {
      authorization_locks            = ["properties.notes"]
      authorization_role_assignments = ["properties.description"]
    }
    private_endpoints = {
      controlled = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        lock = {
          kind = "CanNotDelete"
        }
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "33333333-3333-3333-3333-333333333333"
          }
        }
      }
    }
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_locks["controlled"].type == var.resource_types.authorization_locks &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["controlled", "reader"])].type == var.resource_types.authorization_role_assignments &&
      azapi_resource.private_endpoint_locks["controlled"].timeouts.delete == "10m" &&
      azapi_resource.private_endpoint_role_assignments[jsonencode(["controlled", "reader"])].timeouts.create == "20m"
    )
    error_message = "Consumer API and timeout settings must reach private endpoint extension resources."
  }

  assert {
    condition = alltrue([
      for retry in [
        azapi_resource.private_endpoint_locks["controlled"].retry,
        azapi_resource.private_endpoint_role_assignments[jsonencode(["controlled", "reader"])].retry,
        azapi_resource_action.sql_managed_instance_patch_identities[0].retry,
      ] :
      retry.error_message_regex == var.retry.error_message_regex &&
      retry.interval_seconds == var.retry.interval_seconds &&
      retry.max_interval_seconds == var.retry.max_interval_seconds
    ])
    error_message = "Every shared retry field must reach endpoint extension resources and existing SQL actions."
  }
}

run "resource_specific_retry_is_preserved" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    resource_retry = {
      sql_managed_instance_patch_identities = {
        error_message_regex  = ["CustomConflict"]
        interval_seconds     = 10
        max_interval_seconds = 30
      }
    }
  }

  assert {
    condition = (
      azapi_resource_action.sql_managed_instance_patch_identities[0].retry.error_message_regex == var.resource_retry.sql_managed_instance_patch_identities.error_message_regex &&
      azapi_resource_action.sql_managed_instance_patch_identities[0].retry.interval_seconds == var.resource_retry.sql_managed_instance_patch_identities.interval_seconds &&
      azapi_resource_action.sql_managed_instance_patch_identities[0].retry.max_interval_seconds == var.resource_retry.sql_managed_instance_patch_identities.max_interval_seconds
    )
    error_message = "The renamed resource-specific retry input must retain existing per-resource settings."
  }
}

run "invalid_subresource_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        subresource_name   = "sqlServer"
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_member_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.1.5"
            member_name        = "default"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_lock_kind_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        lock = {
          kind = "Invalid"
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_role_name_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        role_assignments = {
          reader = {
            name                       = "not-a-guid"
            role_definition_id_or_name = "Reader"
            principal_id               = "33333333-3333-3333-3333-333333333333"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_subnet_id_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet"
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_dns_zone_id_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/virtualNetworks/not-a-zone"]
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_application_security_group_id_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        application_security_group_associations = {
          invalid = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/networkSecurityGroups/not-an-asg"
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_delegated_identity_id_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
  }

  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        role_assignments = {
          reader = {
            role_definition_id_or_name             = "Reader"
            principal_id                           = "33333333-3333-3333-3333-333333333333"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sqlmi/providers/Microsoft.Network/applicationSecurityGroups/not-an-identity"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}
