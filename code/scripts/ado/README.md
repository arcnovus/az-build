# Azure DevOps Scripts

This directory contains scripts for managing Azure DevOps resources, specifically variable groups required by the infrastructure deployment pipelines.

## Quick Start

```bash
# 1. Create your configuration file
cp config.sh.example config.sh

# 2. Edit config.sh with your values
# Required values:
#   - AAD_TENANT_ID: Your Azure AD tenant ID
#   - ADO_PAT_TOKEN: Personal Access Token with Variable Groups permissions
#   - ADO_ORGANIZATION_URL: e.g., https://dev.azure.com/myorg
#   - ADO_PROJECT_NAME: Your Azure DevOps project name

# 3. Verify prerequisites
./check-prerequisites.sh

# 4. Create variable groups
./create-variable-groups.sh
```

## Scripts

| Script | Description |
|--------|-------------|
| `check-prerequisites.sh` | Verifies all prerequisites are met (CLI tools, extensions, config) |
| `create-variable-groups.sh` | Orchestrates creation of all variable groups |
| `create-common-variables.sh` | Creates/updates the `common-variables` variable group |
| `create-mg-hierarchy-variables.sh` | Creates/updates the `mg-hierarchy-variables` variable group |
| `create-monitoring-variables.sh` | Creates/updates the `monitoring-variables` variable group |
| `delete-variable-groups.sh` | Deletes variable groups (use with caution!) |
| `show-variable-groups.sh` | Displays details of existing variable groups |
| `lib.sh` | Shared library functions |
| `config.sh` | Your configuration (gitignored - create from example) |
| `config.sh.example` | Configuration template with documentation |

## Variable Groups Created

### `common-variables`

This variable group is used by **all** infrastructure deployment pipelines and contains:

| Variable | Description | Source |
|----------|-------------|--------|
| `azureServiceConnection` | Name of the Azure service connection | `AZURE_SERVICE_CONNECTION_NAME` in config.sh |
| `deploymentLocation` | Default Azure region for deployments | `DEPLOYMENT_LOCATION` in config.sh |
| `azureTenantId` | Azure AD tenant ID | `AAD_TENANT_ID` in config.sh |
| `locationCode` | Default location code for naming (e.g., "cac") | `DEFAULT_LOCATION_CODE` in config.sh |
| `defaultOwner` | Default owner contact for resources | `DEFAULT_OWNER` in config.sh |
| `managedBy` | Infrastructure management tool (e.g., "Bicep") | `MANAGED_BY` in config.sh |
| `denySettingsMode` | Default deployment stack deny settings | `DEFAULT_DENY_SETTINGS_MODE` in config.sh |
| `actionOnUnmanage` | Default action on unmanaged resources | `DEFAULT_ACTION_ON_UNMANAGE` in config.sh |

### `mg-hierarchy-variables`

This variable group is used by the management group hierarchy pipeline and contains:

| Variable | Description | Source |
|----------|-------------|--------|
| `orgName` | Organization name used for management group IDs (e.g., "contoso" → "mg-contoso") | `ORG_NAME` in config.sh |
| `orgDisplayName` | Organization display name shown in Azure Portal | `ORG_DISPLAY_NAME` in config.sh |

### `monitoring-variables`

This variable group is used by the monitoring infrastructure pipeline and contains:

| Variable | Description | Source |
|----------|-------------|--------|
| `monitoringSubscriptionId` | Subscription ID for monitoring resources | `MONITORING_SUBSCRIPTION_ID` in config.sh |
| `dataRetention` | Log Analytics data retention in days (30-730) | `DATA_RETENTION_DAYS` in config.sh |

> **Note:** The `monitoringSubscriptionId` can be left empty during initial setup. Set it after the monitoring subscription is created via the sub-vending pipeline.

## Prerequisites

### Required Tools

1. **Azure CLI** (v2.50.0+)
   ```bash
   # macOS
   brew install azure-cli
   
   # Ubuntu/Debian
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Verify
   az --version
   ```

2. **Azure DevOps CLI Extension**
   ```bash
   az extension add --name azure-devops
   
   # Verify
   az extension show --name azure-devops
   ```

3. **jq** (for JSON processing)
   ```bash
   # macOS
   brew install jq
   
   # Ubuntu/Debian
   sudo apt-get install jq
   ```

### Azure DevOps PAT Token

Create a Personal Access Token at:
`https://dev.azure.com/{organization}/_usersSettings/tokens`

Required permissions:
- **Variable Groups**: Read & Manage
- **Build**: Read (optional, for pipeline integration)

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `AAD_TENANT_ID` | Azure AD tenant ID (GUID) | `12345678-1234-1234-1234-123456789012` |
| `ADO_PAT_TOKEN` | Personal Access Token | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| `ADO_ORGANIZATION_URL` | Azure DevOps org URL | `https://dev.azure.com/myorg` |
| `ADO_PROJECT_NAME` | Project name | `MyProject` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AZURE_SERVICE_CONNECTION_NAME` | Service connection name | `azure-infra-connection` |
| `DEPLOYMENT_LOCATION` | Default Azure region | `canadacentral` |
| `DEFAULT_LOCATION_CODE` | Default location code for naming | `cac` |
| `DEFAULT_OWNER` | Default owner contact for resources | (empty) |
| `MANAGED_BY` | Infrastructure management tool | `Bicep` |
| `DEFAULT_DENY_SETTINGS_MODE` | Deployment stack deny settings | `denyWriteAndDelete` |
| `DEFAULT_ACTION_ON_UNMANAGE` | Action on unmanaged resources | `detachAll` |
| `ORG_NAME` | Organization name for management group IDs | `org` |
| `ORG_DISPLAY_NAME` | Organization display name | `Organization Name` |
| `MONITORING_SUBSCRIPTION_ID` | Monitoring subscription ID | (empty) |
| `DATA_RETENTION_DAYS` | Log Analytics data retention | `60` |

## Usage Examples

### Check Prerequisites
```bash
./check-prerequisites.sh
```

### Create Variable Groups (with confirmation)
```bash
./create-variable-groups.sh
```

### Dry Run (see what would be done)
```bash
./create-variable-groups.sh --dry-run
```

### List Existing Variable Groups
```bash
./create-variable-groups.sh --list
# or
./show-variable-groups.sh --list
```

### Show Variable Group Details
```bash
./show-variable-groups.sh common-variables
# or show all
./show-variable-groups.sh --all
```

### Delete Variable Groups
```bash
# Delete specific group
./delete-variable-groups.sh common-variables

# Delete all managed groups
./delete-variable-groups.sh --all

# Force delete without confirmation
./delete-variable-groups.sh --all --force
```

## Pipelines Using These Variable Groups

All infrastructure pipelines in `/code/pipelines/` reference the `common-variables` group:

- `hub-pipeline.yaml` - Hub networking infrastructure
- `spoke-networking-pipeline.yaml` - Spoke networking
- `governance-pipeline.yaml` - Governance policies
- `mg-hierarchy-pipeline.yaml` - Management group hierarchy (also uses `mg-hierarchy-variables`)
- `monitoring-pipeline.yaml` - Monitoring infrastructure (also uses `monitoring-variables`)
- `sub-vending-pipeline.yaml` - Subscription vending
- `cloudops-pipeline.yaml` - CloudOps (Managed DevOps Pools)
- `cloudops-devcenter-pipeline.yaml` - DevCenter infrastructure

## Troubleshooting

### "Azure DevOps extension is not installed"
```bash
az extension add --name azure-devops
```

### "Failed to connect to Azure DevOps"
1. Verify your PAT token hasn't expired
2. Check the organization URL is correct
3. Ensure the PAT has required permissions

### "Variable group not found"
The group may not exist yet. Run:
```bash
./create-variable-groups.sh
```

### "Access denied"
Your PAT needs these permissions:
- Variable Groups: Read & Manage

## Security Notes

- `config.sh` is gitignored and should **never** be committed
- PAT tokens should be rotated regularly
- Consider using Azure Key Vault for production secrets
- The scripts mask sensitive values in output where possible
