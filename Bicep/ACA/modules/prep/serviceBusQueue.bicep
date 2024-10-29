@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Service Bus queue')
param queueName string


resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01'  existing = {
  name: serviceBusNamespaceName
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespace
  name: queueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 1
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}
