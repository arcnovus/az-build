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

@description('Optional: The ID of an existing subscription to move. If provided, skips subscription creation.')
param existingSubscriptionId string = ''

// Convention: subcr-<workloadAlias>-<environment>-<locationcode>-<instance number>
var subscriptionAliasName = 'subcr-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Management group resource ID string used by alias + move
var targetMgResourceId = '/providers/Microsoft.Management/managementGroups/${managementGroupId}'

// Reference the target management group
resource targetMg 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: managementGroupId
}

// Only create a new subscription if no existing subscription ID is provided
resource subscriptionAlias 'Microsoft.Subscription/aliases@2024-08-01-preview' = if (empty(existingSubscriptionId)) {
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

// Move existing subscription to the target management group
resource mgSubscriptionAssociationExisting 'Microsoft.Management/managementGroups/subscriptions@2024-02-01-preview' = if (!empty(existingSubscriptionId)) {
  parent: targetMg
  name: existingSubscriptionId
}

// Outputs - handle both new and existing subscription scenarios
output subscriptionAliasName string = subscriptionAliasName
output subscriptionId string = subscriptionAlias.properties.subscriptionId
output managementGroupResourceId string = targetMgResourceId
output isExistingSubscription bool = !empty(existingSubscriptionId)
