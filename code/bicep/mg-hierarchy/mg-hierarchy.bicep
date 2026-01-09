// =============================================================================
// Management Group Hierarchy Deployment
// =============================================================================
// This template deploys a hierarchical structure of management groups.
//
// DEPLOYMENT SCOPE:
// This template uses 'tenant' scope to avoid validation issues when creating
// management groups with parent MGs that don't exist yet. ARM validates all
// module scopes BEFORE deployment starts, so using managementGroup scope with
// non-existent parent MGs would fail validation.
//
// RBAC REQUIREMENTS:
// The deploying identity (user or service principal) requires these roles
// at the Tenant Root Management Group:
//
//   - Management Group Contributor - Create/update/delete management groups
//   - Contributor - Microsoft.Resources/deployments/write permission
//
// See: docs/Management-Group-Hierarchy/Creating-Management-Group-Hierarchy.md
// =============================================================================

targetScope = 'tenant'

@description('The tenant root management group ID')
#disable-next-line no-unused-params // Used in bicepparam to construct managementGroups array
param tenantRootManagementGroupId string

@description('The organization name. This will be used to create the root management group for your organization.')
#disable-next-line no-unused-params // Used in bicepparam to construct managementGroups array
param orgName string

@description('The organization display name. This will be used to display the root management group for your organization.')
#disable-next-line no-unused-params // Used in bicepparam to construct managementGroups array
param orgDisplayName string

@description('Array of management groups to create')
param managementGroups array

// Deploy management groups sequentially using tenant scope
// Using @batchSize(1) ensures parents are created before children
@batchSize(1)
resource managementGroupResource 'Microsoft.Management/managementGroups@2023-04-01' = [
  for mg in managementGroups: {
    name: mg.id
    properties: {
      displayName: mg.displayName
      details: {
        parent: {
          id: '/providers/Microsoft.Management/managementGroups/${mg.parentId}'
        }
      }
    }
  }
]

output managementGroupIds array = [
  for (mg, i) in managementGroups: {
    id: mg.id
    resourceId: managementGroupResource[i].id
    name: managementGroupResource[i].name
  }
]
