@maxLength(24)
@description('Required. Name of the Storage Account.')
param storageAccountName string

@description('Optional. The name of the blob service')
param name string = 'default'

@description('Optional. Indicates whether DeleteRetentionPolicy is enabled for the Blob service.')
param deleteRetentionPolicy bool = true

@description('Optional. Indicates the number of days that the deleted blob should be retained. The minimum specified value can be 1 and the maximum value can be 365.')
param deleteRetentionPolicyDays int = 7

@description('Optional. Automatic Snapshot is enabled if set to true.')
param automaticSnapshotPolicyEnabled bool = false

@description('Optional. Blob containers to create.')
param containers array = []

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of a log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered')
param cuaId string = ''

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'StorageRead'
  'StorageWrite'
  'StorageDelete'
])
param logsToEnable array = [
  'StorageRead'
  'StorageWrite'
  'StorageDelete'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'Transaction'
])
param metricsToEnable array = [
  'Transaction'
]

var diagnosticsLogs = [for log in logsToEnable: {
  category: log
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in metricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: name
  parent: storageAccount
  properties: {
    deleteRetentionPolicy: {
      enabled: deleteRetentionPolicy
      days: deleteRetentionPolicyDays
    }
    automaticSnapshotPolicyEnabled: automaticSnapshotPolicyEnabled
  }
}

resource blobServices_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if ((!empty(diagnosticStorageAccountId)) || (!empty(diagnosticWorkspaceId)) || (!empty(diagnosticEventHubAuthorizationRuleId)) || (!empty(diagnosticEventHubName))) {
  name: '${blobServices.name}-diagnosticSettings'
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: blobServices
}

module blobServices_container 'containers/deploy.bicep' = [for (container, index) in containers: {
  name: '${deployment().name}-Container-${index}'
  params: {
    storageAccountName: storageAccount.name
    blobServicesName: blobServices.name
    name: container.name
    publicAccess: contains(container, 'publicAccess') ? container.publicAccess : 'None'
    roleAssignments: contains(container, 'roleAssignments') ? container.roleAssignments : []
    immutabilityPolicyProperties: contains(container, 'immutabilityPolicyProperties') ? container.immutabilityPolicyProperties : {}
  }
}]

@description('The name of the deployed blob service')
output blobServicesName string = blobServices.name

@description('The resource ID of the deployed blob service')
output blobServicesResourceId string = blobServices.id

@description('The name of the deployed blob service')
output blobServicesResourceGroup string = resourceGroup().name
