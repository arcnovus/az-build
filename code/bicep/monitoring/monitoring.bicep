targetScope = 'subscription'

@description('The purpose of the monitoring infrastructure')
param purpose string

@description('The environment (e.g., live, dev, test)')
param environment string

@description('The location code for naming convention (e.g., cac)')
param locationCode string = 'cac'

@description('The instance number for naming convention')
param instanceNumber string

@description('The Azure region for the Log Analytics workspace')
param location string = 'canadacentral'

@description('Number of days for data retention')
@minValue(30)
@maxValue(730)
param dataRetention int = 60

@description('The owner of the monitoring infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

// Construct workspace name following naming convention: law-<purpose>-<environment>-<loc>-<instance>
var workspaceName = 'law-${purpose}-${environment}-${locationCode}-${instanceNumber}'

// Resource group name for monitoring resources
var resourceGroupName = 'rg-${purpose}-${environment}-${locationCode}-${instanceNumber}'

// Deploy resource group for monitoring resources
resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Project: purpose
    Environment: environment
    Owner: owner
    ManagedBy: managedBy
  }
}

// Deploy Log Analytics Workspace using AVM
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.14.0' = {
  name: 'deploy-${workspaceName}'
  scope: monitoringResourceGroup
  params: {
    name: workspaceName
    location: location
    dataRetention: dataRetention
    tags: {
      Project: purpose
      Environment: environment
      Owner: owner
      ManagedBy: managedBy
    }
  }
}

output workspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId
output workspaceName string = logAnalyticsWorkspace.outputs.name
output resourceGroupName string = monitoringResourceGroup.name
