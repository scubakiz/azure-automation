@description('Location for all resources.')
param location string = resourceGroup().location
@description('Name of the Azure Container Registry')
param acrName string
@description('Application Insights Instrumentation Key')
param aiInstrumentationKey string
@description('Application Insights Connection String')
param aiConnectionString string
@description('The identity of the Container App')
param caIdentityId string
@description('Id of the Container App Environment')
param containerAppEnvironmentId string
@description('The name of the Service Bus Namespace')
param serviceBusNamespace string
@description('The name of the Key Vault')
param keyVaultName string
@description('The base URL of the Key Vault')
param keyVaultBaseUrl string 
var keyVaultUrl = 'https://${keyVaultName}${keyVaultBaseUrl}'
@description('The name of the Service Bus Connection String Secret')
param sbConnectionStringSecretName string

param loggingLevel string = 'Information'

type WorkerAppType = {
  @description('Name of the Worker App')
  name: string
  @description('Workload Profile of the Worker App')
  workload_profile: string
  @description('Name of the Image')
  image_name: string
  @description('Tag of the Image')
  image_tag: string
  @description('Dapr Id of the Worker App')
  dapr_id: string
  @description('Message Type of the Worker App')
  message_type: string
}

// Worker image tages
param workerImageTags object = {
  classifyworker: {
    tag: 'latest'
  }
  imagedeleteworker: {
    tag: 'latest'
  }
  mailprocessworker: {
    tag: 'latest'
  }
  sampledbworker: {
    tag: 'latest'
  }
  sampleworker: {
    tag: 'latest'
  }
  storageworker: {
    tag: 'latest'
  }
  tabulageocodeworker: {
    tag: 'latest'
  }
  tabulamergeworker: {
    tag: 'latest'
  }
  tabulapostgresworker: {
    tag: 'latest'
  }
  tabulaspatializerorchestrator: {
    tag: 'latest'
  }
  tabulatargetingworker: {
    tag: 'latest'
  }
  tabulayentaworker: {
    tag: 'latest'
  }
  visitorguidecollectworker: {
    tag: 'latest'
  }  
}

var workerApps = [
  {
    name             : 'classifyworker'
    dapr_id          : 'atlas-classify-worker'
    message_type     : 'classifyimagerequest'
  }
  {
    name             : 'imagedeleteworker'
    dapr_id          : 'atlas-image-delete-worker'
    message_type     : 'imagedeleterequest'
  }
  {
    name             : 'mailprocessworker'
    dapr_id          : 'atlas-mailprocess-worker'
    message_type     : 'mailprocessworkerrequest'
  }
  {
    name             : 'sampledbworker'
    dapr_id          : 'atlas-sample-db-worker'
    message_type     : 'sampledbworkerrequest'
  }
  {
    name             : 'sampleworker'
    dapr_id          : 'atlas-sample-worker'
    message_type     : 'sampleworkerrequest'
  }
  {
    name             : 'storageworker'
    dapr_id          : 'atlas-storage-worker'
    message_type     : 'storagemessage'
  }
  {
    name             : 'tabulageocodeworker'
    dapr_id          : 'atlas-tabula-geocode-worker'
    message_type     : 'tabulageocoderequest'
  }
  {
    name             : 'tabulamergeworker'
    dapr_id          : 'atlas-tabula-merge-worker'
    message_type     : 'tabulamergerequest'
  }
  {
    name             : 'tabulapostgresworker'
    dapr_id          : 'atlas-tabula-postgres-worker'
    message_type     : 'tabulapostgresrequest'
  }
  {
    name             : 'tabulaspatializerorchestrator'
    dapr_id          : 'atlas-tabula-spatializer-worker'
    message_type     : 'tabulaspatializerrequest'
  }
  {
    name             : 'tabulatargetingworker'
    dapr_id          : 'atlas-tabula-targeting-worker'
    message_type     : 'tabulatargetingrequest'
  }
  {
    name             : 'tabulayentaworker'
    dapr_id          : 'atlas-tabula-yenta-worker'
    message_type     : 'tabulayentarequest'
  }
  {
    name             : 'visitorguidecollectworker'
    dapr_id          : 'atlas-visitor-guide-collect-worker'
    message_type     : 'visitorguidecollectrequest'
  }  
]

@description('Create Worker Container App.')
module workerApp 'createWorkerCA.bicep' = [for app in workerApps: {
  name: 'worker_${app.name}'  
  params: {
    containerAppName: '${app.name}'
    location: location
    acrName: acrName
    keyVaultUrl: keyVaultUrl
    aiInstrumentationKey: aiInstrumentationKey
    aiConnectionString: aiConnectionString
    caIdentityId: caIdentityId
    containerAppEnvironmentId: containerAppEnvironmentId
    imageName: app.name
    imageTag: workerImageTags[app.name].tag
    daprAppId: app.dapr_id
    externalIngress: false
    jobMessageType: app.message_type
    serviceBusNamespace: serviceBusNamespace
    sbConnectionStringSecretName: sbConnectionStringSecretName
    workloadProfile: 'Consumption'
    loggingLevel: loggingLevel
  }
}]


