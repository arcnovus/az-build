targetScope = 'managementGroup'

@description('The display name for the subscription to be created')
param subscriptionDisplayName string

@description('The management group ID where the subscription will be placed')
param managementGroupId string

@description('The billing scope for the subscription. Required for EA and MCA scenarios. Format: /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/invoiceSections/{invoiceSectionId}')
param billingScope string = ''

@description('The workload type for the subscription. Valid values: Production, DevTest')
@allowed(['Production', 'DevTest'])
param workload string = 'Production'

@description('The workload alias used in naming conventions (e.g., hub, mngmnt, cloudops)')
param workloadAlias string

@description('The environment for the subscription (e.g., dev, test, prod)')
param environment string

@description('The location code for the subscription')
param locationCode string = 'cac'

@description('The instance number for the subscription')
param instanceNumber string

@description('The owner of the subscription')
param owner string

@description('What manages this subscription (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

// Construct subscription alias name following naming convention: subcr-<workloadAlias>-<environment>-<locationcode>-<instance number>
var subscriptionAliasName = 'subcr-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Use AVM sub-vending module to create subscription and assign to management group
// Note: Using 0.4.1 (stable) - versions 0.5.x have reported issues with API version 2025-04-01
// for managementGroups. Version 0.4.1 is sufficient since we don't need IPAM features.
module subVending 'br/public:avm/ptn/lz/sub-vending:0.4.1' = {
  name: 'sub-vending-${subscriptionAliasName}'
  params: {
    subscriptionDisplayName: subscriptionDisplayName
    subscriptionAliasName: subscriptionAliasName
    subscriptionBillingScope: !empty(billingScope) ? billingScope : ''
    subscriptionWorkload: workload
    subscriptionManagementGroupId: '/providers/Microsoft.Management/managementGroups/${managementGroupId}'
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionAliasEnabled: true
    virtualNetworkEnabled: false
    subscriptionTags: {
      Project: workloadAlias
      Environment: environment
      Owner: owner
      ManagedBy: managedBy
    }
  }
}

output subscriptionId string = subVending.outputs.subscriptionId
output subscriptionResourceId string = subVending.outputs.subscriptionResourceId
output subscriptionDisplayName string = subscriptionDisplayName
output managementGroupId string = managementGroupId
