targetScope = 'tenant'

@description('The management group ID (name) where the subscription will be placed (e.g. "corp-platform").')
param managementGroupId string

@description('The billing scope for the subscription. Required for EA/MCA/MPA. See Microsoft docs for formats.')
param billingScope string = ''

@description('The workload type for the subscription. Valid values: Production, DevTest')
@allowed([
  'Production'
  'DevTest'
])
param workload string = 'Production'

@description('The workload alias used in naming conventions (e.g., hub, mngmnt, cloudops).')
param workloadAlias string

@description('The environment for the subscription (e.g., dev, test, prod).')
param environment string

@description('The location code for the subscription (e.g., cac).')
param locationCode string = 'cac'

@description('The instance number for the subscription (e.g., 001).')
param instanceNumber string

@description('The owner tag value.')
param owner string

@description('ManagedBy tag value.')
param managedBy string = 'Bicep'

// Convention: subcr-<workloadAlias>-<environment>-<locationcode>-<instance number>
var subscriptionAliasName = 'subcr-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Management group resource ID string used by alias + move
var targetMgResourceId = '/providers/Microsoft.Management/managementGroups/${managementGroupId}'

resource subscriptionAlias 'Microsoft.Subscription/aliases@2024-08-01-preview' = {
  name: subscriptionAliasName
  properties: {
    displayName: subscriptionAliasName
    workload: workload
    // Only set billingScope if provided (some scenarios may not require it)
    billingScope: empty(billingScope) ? null : billingScope
    additionalProperties: {
      managementGroupId: targetMgResourceId
      tags: {
        Project: workloadAlias
        Environment: environment
        Owner: owner
        ManagedBy: managedBy
      }
    }
  }
}

output subscriptionAliasName string = subscriptionAlias.name
output subscriptionId string = subscriptionAlias.properties.subscriptionId
output managementGroupResourceId string = subscriptionAlias.properties.managementGroupId
