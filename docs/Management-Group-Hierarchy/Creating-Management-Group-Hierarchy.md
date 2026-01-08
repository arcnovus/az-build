# Creating Management Group Hierarchy

This guide walks you through the process of creating your Azure Management Group hierarchy.

## Prerequisites

Before creating the management group hierarchy, ensure you have:

1. **Azure AD Tenant**: Access to an Azure AD tenant
2. **Required Permissions**: 
   - Owner or Management Group Contributor role at the Tenant Root Management Group
   - Or Global Administrator role in Azure AD
3. **Azure CLI**: Installed and configured (for local deployment)
4. **Azure DevOps**: Access to the pipeline (for automated deployment)
5. **Service Connection**: Configured in Azure DevOps (for pipeline deployment)

## Configuration

### Step 1: Update Parameters File

Edit the `mg-hierarchy.bicepparam` file to configure your hierarchy:

```bicep
using 'mg-hierarchy.bicep'

param tenantRootManagementGroupId = 'your-tenant-id'
param orgName = 'org-name'
param orgDisplayName = 'Organization Name'

param managementGroups = [
  // Define your management groups here
  // Parents must be defined before children
]
```

### Step 2: Configure Management Groups Array

The `managementGroups` array defines all management groups to create. **Important**: Parents must be listed before their children.

**Required Parameters for Each Management Group:**
- `id`: Unique identifier (alphanumeric, hyphens, underscores only)
- `displayName`: Human-readable display name
- `parentId`: ID of the parent management group

**Example Configuration:**

```bicep
param managementGroups = [
  {
    id: 'contoso'
    displayName: 'Contoso Corporation'
    parentId: tenantRootManagementGroupId
  }
  {
    id: 'platform'
    displayName: 'Platform'
    parentId: 'contoso'
  }
  {
    id: 'landing-zone'
    displayName: 'Landing Zone'
    parentId: 'contoso'
  }
  // Add more management groups as needed
]
```

## Deployment Methods

### Method 1: Azure DevOps Pipeline (Recommended)

The pipeline provides automated validation, what-if analysis, and deployment.

#### Pipeline Stages

1. **Validate**: Validates the Bicep template syntax and parameters
2. **What-If**: Shows what changes will be made before deployment
3. **Deploy**: Creates the management group hierarchy

#### Running the Pipeline

1. Navigate to Azure DevOps Pipelines
2. Select `01-mg-hierarchy-pipeline`
3. Click "Run pipeline"
4. Review the validation and what-if results
5. Approve the deployment if everything looks correct

#### Required Pipeline Variables

Ensure these variables are configured in your variable group (`common-variables`):

- `azureServiceConnection`: Service connection name
- `azureTenantId`: Your Azure AD tenant ID
- `deploymentLocation`: Azure region for deployment (e.g., `canadacentral`)

### Method 2: Azure CLI (Local Deployment)

For local testing or manual deployment:

#### Validate Template

```bash
az deployment mg validate \
  --management-group-id <tenant-id> \
  --location canadacentral \
  --template-file code/bicep/mg-hierarchy/mg-hierarchy.bicep \
  --parameters code/bicep/mg-hierarchy/mg-hierarchy.bicepparam \
  --parameters tenantRootManagementGroupId=<tenant-id>
```

#### What-If Analysis

```bash
az deployment mg what-if \
  --management-group-id <tenant-id> \
  --location canadacentral \
  --template-file code/bicep/mg-hierarchy/mg-hierarchy.bicep \
  --parameters code/bicep/mg-hierarchy/mg-hierarchy.bicepparam \
  --parameters tenantRootManagementGroupId=<tenant-id>
```

#### Deploy

```bash
az deployment mg create \
  --name mg-hierarchy-$(date +%Y%m%d-%H%M%S) \
  --management-group-id <tenant-id> \
  --location canadacentral \
  --template-file code/bicep/mg-hierarchy/mg-hierarchy.bicep \
  --parameters code/bicep/mg-hierarchy/mg-hierarchy.bicepparam \
  --parameters tenantRootManagementGroupId=<tenant-id>
```

## Deployment Behavior

### Sequential Deployment

The template uses `@batchSize(1)` to ensure management groups are deployed sequentially. This guarantees that parent management groups exist before their children are created.

### Idempotency

The deployment is idempotent. Running it multiple times with the same parameters will not create duplicate management groups. It will update existing management groups if their properties change.

## Verification

After deployment, verify the hierarchy:

1. **Azure Portal**:
   - Navigate to Management Groups
   - Verify all management groups are created
   - Check the hierarchy structure

2. **Azure CLI**:
   ```bash
   az account management-group list --output table
   ```

3. **Check Deployment Outputs**:
   The deployment outputs an array of created management groups with their IDs and resource IDs.

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure you have Owner or Management Group Contributor role at Tenant Root
   - Global Administrators automatically have these permissions

2. **Parent Not Found**
   - Verify management groups are listed in correct order (parents before children)
   - Check that parent IDs match exactly (case-sensitive)

3. **Invalid Management Group ID**
   - IDs must be alphanumeric with hyphens or underscores
   - Maximum 90 characters
   - Cannot contain spaces or special characters

4. **Deployment Timeout**
   - Management group creation can take several minutes
   - Sequential deployment increases total time
   - Be patient and monitor the deployment status

## Next Steps

After creating the hierarchy:

1. [Managing Management Group Hierarchy](Managing-Management-Group-Hierarchy.md) - Learn about ongoing management
2. Assign subscriptions to appropriate management groups
3. Apply policies and governance at the management group level
4. Configure access controls using Azure RBAC
