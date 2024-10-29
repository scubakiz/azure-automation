@description('Location for all resources.')
param location string = resourceGroup().location
@description('Log Analytics Workspace Name')
param logAnalyticsWorkspaceId string
@description('Log Analytics Workspace Shared Key')
param logAnalyticsWorkspaceSharedKey string

@description('Service Bus Namespace Name')
param serviceBusNamespaceName string


@description('Application Insights Instrumentation Key')
param aiInstrumentationKey string
@description('Application Insights Connection String')
param aiConnectionString string
@description('Service Bus Connection String Secret Name')
param sbConnectionStringSecretName string
@description('Identity Id')
param caIdentityName string
@description('Name of the Container App Environment')
param containerAppEnvironmentName string 
@description('Name of Storage Account')
param storageAccountName string
@description('Name of the Key Vault')
param keyVaultName string
@description('Name of File Share')
param fileShareName string 

@description('Name of Storage Account Key')
@secure()
param storageAccountKey string 

@description('Create Container App Environment')
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvironmentName
  location: location
  
  properties: {
    workloadProfiles: [
      {
        name: 'D4'
        workloadProfileType: 'D4'
        minimumCount: 1
        maximumCount: 6
      }
    ]
    daprAIConnectionString: aiConnectionString
    daprAIInstrumentationKey: aiInstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspaceId
        sharedKey: logAnalyticsWorkspaceSharedKey
      }
    }      
  }
}

resource symbolicname 'Microsoft.App/managedEnvironments/storages@2022-10-01' = {
  name: storageAccountName
  parent: containerAppEnvironment
  properties: {
    azureFile: {
      accessMode: 'ReadWrite'
      accountKey: storageAccountKey
      accountName: storageAccountName
      shareName: fileShareName
    }    
  }
}

@description('Create Dapr Component for Service Bus')
module daprComponentPubSub 'serviceBusDaprComponent.bicep' = {
  name: 'daprComponentPubSub'
  params: {
    containerAppsEnvName: containerAppEnvironmentName
//    sbConnectionStringSecretName: sbConnectionStringSecretName
    serviceBusNamespaceName: serviceBusNamespaceName
    daprComponentName: 'atlaspubsub'
    // caIdentityId: caIdentityId 
    // keyVaultName: keyVaultName  
  }
  dependsOn: [
    containerAppEnvironment
  ]
}


output ContainerAppEnvironmentId string = containerAppEnvironment.id


