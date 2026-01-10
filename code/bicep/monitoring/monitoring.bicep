targetScope = 'subscription'

@description('The workload alias used in naming conventions (e.g., monitoring, hub, mngmnt)')
param workloadAlias string

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

@description('Daily ingestion limit in GB. -1 for unlimited.')
@minValue(-1)
param dailyQuotaGb int = -1

@description('Enable public network access for ingestion')
param publicNetworkAccessForIngestion string = 'Enabled'

@description('Enable public network access for query')
param publicNetworkAccessForQuery string = 'Enabled'

@description('Enable resource or workspace permissions for log access')
param enableLogAccessUsingOnlyResourcePermissions bool = false

@description('Email addresses for alert notifications (semicolon separated)')
param alertEmailAddresses string = ''

@description('Webhook URI for alert notifications (optional)')
param alertWebhookUri string = ''

@description('Enable alert rules for workspace monitoring')
param enableAlertRules bool = true

@description('Storage Account Resource ID for workspace diagnostics (optional - for archival of workspace audit logs)')
param diagnosticStorageAccountId string = ''

// Construct workspace name following naming convention: law-<workloadAlias>-<environment>-<loc>-<instance>
var workspaceName = 'law-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Resource group name for monitoring resources
var resourceGroupName = 'rg-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Action group and alert names
var actionGroupName = 'ag-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var alertRulePrefix = 'alert-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Deploy resource group for monitoring resources
resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Project: workloadAlias
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
    dailyQuotaGb: dailyQuotaGb
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    useResourcePermissions: enableLogAccessUsingOnlyResourcePermissions
    diagnosticSettings: !empty(diagnosticStorageAccountId) ? [
      {
        name: 'law-audit-diagnostics'
        storageAccountResourceId: diagnosticStorageAccountId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'audit'
          }
        ]
      }
    ] : []
    tags: {
      Project: workloadAlias
      Environment: environment
      Owner: owner
      ManagedBy: managedBy
    }
  }
}

// ============================================================================
// ACTION GROUP for Alerts
// ============================================================================

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (enableAlertRules && !empty(alertEmailAddresses)) {
  name: actionGroupName
  location: 'global'
  tags: {
    Project: workloadAlias
    Environment: environment
    Owner: owner
    ManagedBy: managedBy
  }
  properties: {
    groupShortName: substring(actionGroupName, 0, min(12, length(actionGroupName)))
    enabled: true
    emailReceivers: [for email in split(alertEmailAddresses, ';'): {
      name: 'email-${uniqueString(email)}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
    webhookReceivers: !empty(alertWebhookUri) ? [
      {
        name: 'webhook-receiver'
        serviceUri: alertWebhookUri
        useCommonAlertSchema: true
      }
    ] : []
  }
}

// ============================================================================
// ALERT RULES for Workspace Monitoring
// ============================================================================

// Alert when daily ingestion quota is approaching (90% of limit)
resource quotaAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlertRules && !empty(alertEmailAddresses) && dailyQuotaGb > 0) {
  name: '${alertRulePrefix}-quota-limit'
  location: location
  tags: {
    Project: workloadAlias
    Environment: environment
    Owner: owner
    ManagedBy: managedBy
  }
  properties: {
    displayName: 'Log Analytics Workspace - Daily Quota Warning'
    description: 'Alert when workspace ingestion approaches 90% of daily quota'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspace.outputs.resourceId
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'Usage | where IsBillable == true | summarize DataGB = sum(Quantity) / 1000'
          timeAggregation: 'Total'
          dimensions: []
          operator: 'GreaterThan'
          threshold: dailyQuotaGb * 0.9
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// Alert when workspace ingestion rate is unusually high
resource ingestionSpikeAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlertRules && !empty(alertEmailAddresses)) {
  name: '${alertRulePrefix}-ingestion-spike'
  location: location
  tags: {
    Project: workloadAlias
    Environment: environment
    Owner: owner
    ManagedBy: managedBy
  }
  properties: {
    displayName: 'Log Analytics Workspace - Ingestion Spike Detected'
    description: 'Alert when workspace ingestion rate increases significantly compared to baseline'
    severity: 3
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      logAnalyticsWorkspace.outputs.resourceId
    ]
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          query: 'Usage | where IsBillable == true | summarize IngestedGB = sum(Quantity) / 1000 by bin(TimeGenerated, 1h) | where IngestedGB > 10'
          timeAggregation: 'Total'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// Alert for query performance issues
resource queryPerformanceAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlertRules && !empty(alertEmailAddresses)) {
  name: '${alertRulePrefix}-query-performance'
  location: location
  tags: {
    Project: workloadAlias
    Environment: environment
    Owner: owner
    ManagedBy: managedBy
  }
  properties: {
    displayName: 'Log Analytics Workspace - Slow Query Performance'
    description: 'Alert when queries are taking longer than expected to execute'
    severity: 3
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      logAnalyticsWorkspace.outputs.resourceId
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'LAQueryLogs | where ResponseCode == 200 | summarize AvgDuration = avg(StatsCPUTimeMs) by bin(TimeGenerated, 15m) | where AvgDuration > 30000'
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('Log Analytics Workspace Resource ID')
output workspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId

@description('Log Analytics Workspace Name')
output workspaceName string = logAnalyticsWorkspace.outputs.name

@description('Log Analytics Workspace ID (Customer ID) - used for agent configuration')
output workspaceId string = logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId

@description('Resource Group Name')
output resourceGroupName string = monitoringResourceGroup.name

@description('Action Group Resource ID')
output actionGroupId string = (enableAlertRules && !empty(alertEmailAddresses)) ? actionGroup.id : ''

@description('Action Group Name')
output actionGroupName string = (enableAlertRules && !empty(alertEmailAddresses)) ? actionGroup.name : ''

@description('Location of deployed resources')
output location string = location
