// =============================================================================
// Management Group Hierarchy Deployment
// =============================================================================
// This template deploys a hierarchical structure of management groups.
//
// RBAC REQUIREMENTS:
// The deploying identity (user or service principal) requires BOTH of the
// following roles at the Tenant Root Management Group:
//
//   1. Management Group Contributor - Create/update/delete management groups
//   2. Contributor - Microsoft.Resources/deployments/write permission
//
// The Contributor role is required because ARM creates deployment resources
// at each management group scope during nested module deployments. Since child
// management groups don't exist during initial deployment, these permissions
// must be inherited from the Tenant Root Group.
//
// See: docs/Management-Group-Hierarchy/Creating-Management-Group-Hierarchy.md
// =============================================================================

targetScope = 'managementGroup'

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

@batchSize(1) // Deploy sequentially to ensure parents exist before children (array must be sorted: parents first)
module managementGroupModule 'br/public:avm/res/management/management-group:0.1.0' = [
  for mg in managementGroups: {
    name: mg.id
    scope: managementGroup(mg.parentId)
    params: {
      name: mg.id
      displayName: mg.displayName
      parentId: mg.parentId
    }
  }
]

output managementGroupIds array = [
  for (mg, i) in managementGroups: {
    id: mg.id
    resourceId: managementGroupModule[i].outputs.resourceId
    name: managementGroupModule[i].outputs.name
  }
]
