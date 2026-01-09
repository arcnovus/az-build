targetScope = 'tenant'

@description('The display name for the subscription to be created (used when existingSubscriptionId is empty).')
param subscriptionDisplayName string

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

@description('Optional. If provided, skips subscription creation and only moves the existing subscription to the management group.')
param existingSubscriptionId string = ''

// Convention: subcr-<workloadAlias>-<environment>-<locationcode>-<instance number>
var subscriptionAliasName = 'subcr-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Management group resource ID string used by alias + move
var targetMgResourceId = '/providers/Microsoft.Management/managementGroups/${managementGroupId}'

// The subscriptionId to output - for new subscriptions we get it from the alias, for existing we use the parameter
var subscriptionIdToUse = empty(existingSubscriptionId)
  ? subscriptionAlias.properties.subscriptionId
  : existingSubscriptionId

// 1) Create subscription (alias) if existingSubscriptionId is not provided
resource subscriptionAlias 'Microsoft.Subscription/aliases@2024-08-01-preview' = if (empty(existingSubscriptionId)) {
  name: subscriptionAliasName
  properties: {
    displayName: subscriptionDisplayName
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

// 2) Move subscription to the target management group (explicitly enforce placement)
// Docs: use Microsoft.Management/managementGroups/subscriptions to move an existing subscription. :contentReference[oaicite:3]{index=3}
resource targetMg 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: managementGroupId
}

// Only move subscription if using an existing one (new subscriptions are placed via additionalProperties.managementGroupId)
resource mgSubscriptionAssociation 'Microsoft.Management/managementGroups/subscriptions@2024-02-01-preview' = if (!empty(existingSubscriptionId)) {
  parent: targetMg
  name: existingSubscriptionId
}

output subscriptionAliasName string = subscriptionAliasName
output subscriptionId string = subscriptionIdToUse
output managementGroupResourceId string = targetMgResourceId
