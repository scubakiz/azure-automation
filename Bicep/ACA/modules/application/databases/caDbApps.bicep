

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
@description('The name of the Service Bus Namespace')
param serviceBusNamespace string
@description('Id of the Container App Environment')
param containerAppEnvironmentId string = 'gatewaydapr'
@description('Name of the Key Vault')
param keyVaultName string
@description('Url of the Key Vault')
param keyVaultBaseUrl string
var keyVaultUrl = 'https://${keyVaultName}${keyVaultBaseUrl}'

param loggingLevel string = 'Information'

var armstrongDbStringUri = '${keyVaultUrl}ArmstrongDBString'
var atlasDbStringUri = '${keyVaultUrl}AtlasDBString'
var earthdiverDbStringUri = '${keyVaultUrl}EarthdiverDBString'

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

param dbImageSettings object = {
  armstrongdatabasereader: {
    tag: 'latest'
  }
  armstrongdatabasewriter: {
    tag: 'latest'
  }
  atlasdatabasereader: {
    tag: 'latest'
  }
  atlasdatabasewriter: {
    tag: 'latest'
  }
  earthdiverdatabasereader: {
    tag: 'latest'
  }
  earthdiverdatabasewriter: {
    tag: 'latest'
  }
}

var dbApps = [
  {
    name: 'armstrongdatabasereader'
    image_name: 'postgresqldatabasecache'
    dapr_id: 'armstrongdatabasereader'
    db_connection: armstrongDbStringUri
    message_type: 'not used'
  }
  {
    name: 'armstrongdatabasewriter'
    image_name: 'postgresqldatabasecache'
    dapr_id: 'armstrongdatabasewriter'
    db_connection: armstrongDbStringUri
    message_type: 'armstrongdatabasecache'
  }
  {
    name: 'atlasdatabasereader'
    image_name: 'mysqldatabasecache'
    dapr_id: 'atlasdatabasereader'
    db_connection: atlasDbStringUri
    message_type: 'not used'
  }
  {
    name: 'atlasdatabasewriter'
    image_name: 'mysqldatabasecache'
    dapr_id: 'atlasdatabasewriter'
    db_connection: atlasDbStringUri
    message_type: 'atlasdatabasecache'
  }
  {
    name: 'earthdiverdatabasereader'
    image_name: 'mysqldatabasecache'
    dapr_id: 'earthdiverdatabasereader'
    db_connection: earthdiverDbStringUri
    message_type: 'not used'
  }
  {
    name: 'earthdiverdatabasewriter'
    image_name: 'mysqldatabasecache'
    dapr_id: 'earthdiverdatabasewriter'
    db_connection: earthdiverDbStringUri
    message_type: 'earthdiverdatabasecache'
  }
]

@description('Create Worker Container App.')
module workerApp 'createDatabaseCA.bicep' = [for app in dbApps: {
  name: 'db_${app.name}'
  params: {
    containerAppName: '${app.name}'
    location: location
    acrName: acrName
    aiInstrumentationKey: aiInstrumentationKey
    aiConnectionString: aiConnectionString
    caIdentityId: caIdentityId
    containerAppEnvironmentId: containerAppEnvironmentId
    imageName: app.image_name
    imageTag: dbImageSettings[app.name].tag
    daprAppId: app.dapr_id
    jobMessageType: app.message_type
    workloadProfile: 'Consumption'
    serviceBusNamespace: serviceBusNamespace
    dbConnectionStringUri: app.db_connection
    loggingLevel: loggingLevel
  }
}]
