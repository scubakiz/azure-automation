@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('List of queues to be created')
var queues = [
  'armstrongdatabasecache'
  'atlasdatabasecache'
  'earthdiverdatabasecache'
  'classifyimagerequest'  
  'imagedeleterequest'
  'mailprocessworkerrequest'
  'sampledbworkerrequest'
  'sampleworkerrequest'
  'storagemessage'
  'tabulageocoderequest'
  'tabulamergerequest'
  'tabulapostgresrequest'
  'tabulaspatializerrequest'
  'tabulatargetingrequest'
  'tabulayentarequest'
  'visitorguidecollectrequest'
]

@description('Create queues')
module serviceBusQueue 'serviceBusQueue.bicep' = [for currentQueue in queues: {
  name: currentQueue
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    queueName: currentQueue
  }
}]
