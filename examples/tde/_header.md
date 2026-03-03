# Transparent Data Encryption (TDE) with Key Vault example

This example deploys the SQL Managed Instance module with Transparent Data Encryption (TDE) configured to use a customer-managed key stored in Azure Key Vault.

The example demonstrates:
- Creating an Azure Key Vault
- Generating a key encryption key in the Key Vault
- Configuring the SQL Managed Instance with system-assigned managed identity
- Granting the managed identity permissions to access the Key Vault key
- Enabling TDE with the customer-managed key
