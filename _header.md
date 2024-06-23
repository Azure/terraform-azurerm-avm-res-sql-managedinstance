# AVM module for SQL Managed Instance

This is an Azure Verified Modules for SQL Managed Instances.

The module supports the following capabilities:

* All supported AzureRM parameters for the `azurerm_mssql_managed_instance` resource.
* Advanced Threat Protection, enabled by default.
* Vulnerability Assessments & Security Access Policies with a restricted storage account (supplied via `storage_account_resource_id`)
* Configuration for a failover group
* A map of databases, along with support for all parameters, such as long term backup retention policies.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.
