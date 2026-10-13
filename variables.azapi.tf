variable "ignore_body_changes" {
  type = object({
    authorization_locks            = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore on private endpoint extension resources. Paths use dot notation. Ignored configuration is not sent to Azure until the path is removed, and changes take effect only after apply. Non-empty values require Terraform 1.11 or later.

- `authorization_locks` - Paths ignored on private endpoint locks.
- `authorization_role_assignments` - Paths ignored on private endpoint role assignments.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    authorization_locks                                       = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments                            = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    sql_managed_instances                                     = optional(string, "Microsoft.Sql/managedInstances@2025-02-01-preview")
    sql_managed_instances_advanced_threat_protection_settings = optional(string, "Microsoft.Sql/managedInstances/advancedThreatProtectionSettings@2023-08-01-preview")
    sql_managed_instances_security_alert_policies             = optional(string, "Microsoft.Sql/managedInstances/securityAlertPolicies@2023-08-01-preview")
    sql_managed_instances_vulnerability_assessments           = optional(string, "Microsoft.Sql/managedInstances/vulnerabilityAssessments@2023-08-01-preview")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module. Existing SQL API-version defaults are retained.

- `authorization_locks` - Private endpoint locks.
- `authorization_role_assignments` - Private endpoint role assignments.
- `sql_managed_instances` - Managed instance identity and feature actions and reads.
- `sql_managed_instances_advanced_threat_protection_settings` - Advanced Threat Protection settings.
- `sql_managed_instances_security_alert_policies` - Security alert policies.
- `sql_managed_instances_vulnerability_assessments` - Vulnerability assessments.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Shared retry configuration for AzAPI resources. Defaults to null. When set, it overrides the resource-specific `resource_retry` settings.

- `error_message_regex` - Error patterns that trigger a retry.
- `interval_seconds` - Initial interval between retries in seconds.
- `max_interval_seconds` - Maximum interval between retries in seconds.
DESCRIPTION
}
