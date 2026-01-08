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

@description('The subscription alias name')
param subscriptionAliasName string

// Use AVM sub-vending module to create subscription and assign to management group
module subVending 'br/public:avm/ptn/lz/sub-vending:0.5.0' = {
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
  }
}

output subscriptionId string = subVending.outputs.subscriptionId
output subscriptionResourceId string = subVending.outputs.subscriptionResourceId
output subscriptionDisplayName string = subscriptionDisplayName
output managementGroupId string = managementGroupId
