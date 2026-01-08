using 'mg-hierarchy.bicep'

param tenantRootManagementGroupId = 'your-tenant-id'
param orgName = 'org-name'
param orgDisplayName = 'Organization Name'

param managementGroups = [
  {
    id: orgName
    displayName: orgDisplayName
    parentId: tenantRootManagementGroupId
  }
  {
    id: 'platform'
    displayName: 'Platform'
    parentId: orgName
  }
  {
    id: 'landing-zone'
    displayName: 'Landing Zone'
    parentId: orgName
  }
  {
    id: 'sandbox'
    displayName: 'Sandbox'
    parentId: orgName
  }
  {
    id: 'decommissioned'
    displayName: 'Decommissioned'
    parentId: orgName
  }
  {
    id: 'management'
    displayName: 'Management'
    parentId: 'platform'
  }
  {
    id: 'connectivity'
    displayName: 'Connectivity'
    parentId: 'platform'
  }
  {
    id: 'corp-prod'
    displayName: 'Corp Production'
    parentId: 'landing-zone'
  }
  {
    id: 'corp-non-prod'
    displayName: 'Corp Non-Production'
    parentId: 'landing-zone'
  }
  {
    id: 'online-prod'
    displayName: 'Online Production'
    parentId: 'landing-zone'
  }
  {
    id: 'online-non-prod'
    displayName: 'Online Non-Production'
    parentId: 'landing-zone'
  }
]
