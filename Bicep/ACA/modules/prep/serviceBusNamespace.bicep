@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string
@description('Log Analytics workspace resource ID')
param logAnalyticsWorkspaceResourceId string

@description('Location for all resources.')
param location string = resourceGroup().location

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'main'
  scope: serviceBus
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId // Log Analytics workspace resource ID
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'OperationalLogs'
        enabled: true
      }
    ]
  }
}


output ServiceBusNamespaceName string = serviceBus.name
output ServiceBusNamespaceId string = serviceBus.id
#disable-next-line outputs-should-not-contain-secrets
output ServiceBusConnectionString string = listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
