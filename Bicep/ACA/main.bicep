/*
  This script defines the configuration for deploying a Container App, including specifying the container name, location,
  Azure Container Registry (ACR) details, Application Insights keys, Container App identity, and environment settings. It
  outlines parameters for the container image name and tag, Dapr App ID for microservices communication, ingress settings,
  and the workload profile. The script is tailored to facilitate the setup of a Container App with optional Dapr integration,
  supporting both internal and external ingress, and allowing for a flexible deployment model based on the specified workload
  profile. This setup is crucial for applications leveraging Azure's Container Apps for scalable, microservices-based
  architectures.
*/

// Set the scope for deployment to 'subscription'
targetScope = 'subscription'

// Define parameters for various configurations needed for deployment
param prefix string
param suffix string
param location string
param registryName string
param registryResourceGroup string
param registrySubscriptionId string
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceResourceGroup string
param keyVaultName string
param keyVaultResourceGroup string
param loggingLevel string = 'Information'
param keyVaultBaseUrl string

// Define variables for resource names based on prefix and suffix
var resourceGroupName = '${prefix}-${suffix}-rg'
var storageAccountName = '${prefix}${suffix}sa'
var serviceBusNamespaceName = '${prefix}-${suffix}-sbn'
var redisCacheName = '${prefix}-${suffix}-rc'
var serviceBusQueues = '${prefix}-${suffix}-sb-queues'
var appInsightsName = '${prefix}-${suffix}-ai'
var appName = '${prefix}-${suffix}-app'
var caEnvironmentName = '${prefix}-ca-env-${suffix}'
var sbConnectionStringSecretName = '${suffix}-sbconnectionstring'

////////////////////////////// Existing resources
// Reference an existing Log Analytics workspace
@description('Reference existing Log Analytics workspace.')
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsWorkspaceResourceGroup)
}

/////////////////////////////// New Resources
//
// Create a new resource group
@description('Create Resource Group.')
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

// Create an Application Insights resource
@description('Create Application Insights.')
module appInsights 'modules/prep/appInsights.bicep' = {
  name: 'appInsights'
  scope: rg
  params: {
    appInsightsName: appInsightsName
    location: rg.location
    appName: appName
    logAnalyticsId: logAnalytics.id
  }
  dependsOn: [
    logAnalytics
  ]
}

// Create a Storage Account
@description('Create Storage Account.')
module storageAccount 'modules/prep/storageAccount.bicep' = {
  name: 'storageAccount'
  scope: rg
  params: {
    storageAccountName: storageAccountName
    location: location
  } 
}


// Create a File Share within the Storage Account
@description('Create File Share')
module fileShare 'modules/prep/fileShare.bicep' = {
  name: 'fileShare'
  scope: rg
  params: {
    storageAccountName: storageAccount.outputs.NewStorageAccountName
    fileShareName: 'atlasconfig'
  }
  dependsOn: [
    storageAccount
  ]
}

// Upload configuration files to the File Share
@description('Upload files to File Share')
module fileUpload 'modules/prep/uploadConfigToShare.bicep' = {
  name: 'fileUpload'
  scope: rg
  params: {
    storageAccountName: storageAccount.outputs.NewStorageAccountName
    fileShareName: 'atlasconfig'
    location: location
  }
  dependsOn: [
    fileShare
  ]
}

// Create a Service Bus Namespace
@description('Create Service Bus Namespace.')
module serviceBus 'modules/prep/serviceBusNamespace.bicep' = {
  name: serviceBusNamespaceName
  scope: rg
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    logAnalyticsWorkspaceResourceId: logAnalytics.id
    location: location
  }
  dependsOn: [
    logAnalytics
  ]
}

// Create a secret for the Service Bus Connection String in Key Vault
@description('Create Service Bus Connection Secret.')
module sbConnectionSecret 'modules/prep/serviceBusConnectionSecret.bicep' = {
  name: sbConnectionStringSecretName
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    keyVaultName: keyVaultName
    sbConnectionStringSecretName: sbConnectionStringSecretName
    sbConnectionString: serviceBus.outputs.ServiceBusConnectionString
  }
  dependsOn: [
    serviceBus
  ]
}

// Create Service Bus Queues
@description('Create Service Bus Queues.')
module serviceQueues 'modules/prep/serviceBusAllQueues.bicep' = {
  name: serviceBusQueues
  scope: rg
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
  }
  dependsOn: [
    serviceBus
  ]
}

// Define the name for the Work Coordinator managed identity
var wcIdentityName = '${prefix}-wc-mi-${suffix}'

// Create a managed identity for the Work Coordinator application
@description('Create Identity for Work Coordinator App.')
module wcIdentity 'modules/prep/managedIdentityAndAssignments.bicep' = {
  name: wcIdentityName
  scope: rg
  params: {
    identityName: wcIdentityName
    location: location
    registryName: registryName
    registryResourceGroup: registryResourceGroup
    registrySubscriptionId: registrySubscriptionId
    keyVaultName: keyVaultName
    keyVaultResourceGroup: keyVaultResourceGroup
    serviceBusNamespaceName: serviceBusNamespaceName    
  }
  dependsOn: [
    serviceBus
  ]
}



////////////////////////////////////////////// Work Coordinator
// Create the Container App Environment
@description('Create Container App Enviornment.')
module containerAppEnv 'modules/application/containerAppEnv.bicep' = {
  name: 'containerAppEnv'
  scope: rg
  params: {
    location: location    
    logAnalyticsWorkspaceId: logAnalytics.properties.customerId
    logAnalyticsWorkspaceSharedKey: logAnalytics.listKeys().primarySharedKey
    aiInstrumentationKey: appInsights.outputs.AIInstrumentationKey
    aiConnectionString: appInsights.outputs.AIConnectionString
    keyVaultName: keyVaultName
    sbConnectionStringSecretName: sbConnectionStringSecretName
    serviceBusNamespaceName: serviceBusNamespaceName    
    containerAppEnvironmentName: caEnvironmentName
    caIdentityName: wcIdentityName
    storageAccountName: storageAccount.outputs.NewStorageAccountName
    storageAccountKey: storageAccount.outputs.NewStorageAccountKey
    fileShareName: 'atlasconfig'
  }
  dependsOn: [
    serviceBus
    wcIdentity
  ]
}

@description('Create Work Coordinator Container App.')
// Image tags
param workCoordinatorImageTag string = 'latest'
var workCoordintorAppName = 'workcoordinator'
var workCoordinatorImageName = 'workcoordinator'
var workCoordinatorDaprId = 'atlas-work-coordinator'

@description('Create Work Coordinator Container App.')
module workCoordinatorApp 'modules/application/workcoordinator/createWorkCoordinatorCA.bicep' = {
  name: 'workCoordinator'
  scope: rg
  params: {
    containerAppName: workCoordintorAppName
    location: location
    acrName: registryName
    aiInstrumentationKey: appInsights.outputs.AIInstrumentationKey
    aiConnectionString: appInsights.outputs.AIConnectionString
    caIdentityId: wcIdentity.outputs.IdentityId
    containerAppEnvironmentId: containerAppEnv.outputs.ContainerAppEnvironmentId
    imageName: workCoordinatorImageName
    imageTag: workCoordinatorImageTag
    daprAppId: workCoordinatorDaprId
    storageName: storageAccount.outputs.NewStorageAccountName
    externalIngress: true
    loggingLevel: loggingLevel
  }
  dependsOn: [
    containerAppEnv
  ]
}

// @description('Assign Container App Identity to ACR Pull Role.')
// module caAcrRoleAssignment 'modules/prep/roleAssignment-Acr.bicep' = {
//   name: 'caAcrRoleAssignment'
//   scope: resourceGroup(registrySubscriptionId, registryResourceGroup)
//   params: {
//     acrName: registryName
//     principalId: caIdentity.outputs.PrincipalId
//   }
//   dependsOn: [
//     caIdentity
//   ]
// }

// @description('Assign Container App Identity to Key Vault Secret Reader.')
// module caKvRoleAssignment 'modules/prep/roleAssignment-KeyVault.bicep' = {
//   name: 'caKvRoleAssignment'
//   scope: resourceGroup(keyVaultResourceGroup)
//   params: {
//     kvName: keyVaultName
//     principalId: caIdentity.outputs.PrincipalId
//   }
//   dependsOn: [
//     caIdentity
//   ]
// }

// @description('Assign Container App Identity to Service Bus.')
// module caSbRoleAssignment 'modules/prep/roleAssignment-ServiceBus.bicep' = {
//   name: 'caSbRoleAssignment'
//   scope: rg
//   params: {
//     sbName: serviceBusNamespaceName
//     principalId: caIdentity.outputs.PrincipalId
//   }
//   dependsOn: [
//     caIdentity
//     serviceBus
//   ]
// }

// //////////////////////////////////////////////// Workers
var workerIdentityName = '${prefix}-worker-mi-${suffix}'

@description('Create Identity for Worker Coordinator Apps.')
module workerIdentity 'modules/prep/managedIdentityAndAssignments.bicep' = {
  name: workerIdentityName
  scope: rg
  params: {
    identityName: workerIdentityName
    location: location
    registryName: registryName
    registryResourceGroup: registryResourceGroup
    registrySubscriptionId: registrySubscriptionId
    keyVaultName: keyVaultName
    keyVaultResourceGroup: keyVaultResourceGroup
    serviceBusNamespaceName: serviceBusNamespaceName    
  }
  dependsOn: [
    serviceBus
  ]
}

@description('Create Redis Cache.')
module redisCache 'modules/prep/redisCache.bicep' = {
  name: redisCacheName
  scope: rg
  params: {
    redisHostName: redisCacheName    
    logAnalyticsWorkspaceResourceId: logAnalytics.id
    location: location
    caIdentityName: workerIdentityName
  }
  dependsOn: [
    workerIdentity
  ]
}


@description('Create Dapr Component for Service Bus')
module daprComponentCache 'modules/application/redisDaprComponent.bicep' = {
  name: 'daprComponentCache'
  scope: rg
  params: {
    containerAppsEnvName: caEnvironmentName
    daprComponentName: 'atlascache'
    redisHostName: redisCacheName
    caIdentityName: workerIdentityName 
  }
  dependsOn: [
    containerAppEnv
    redisCache
    workerIdentity
  ]
}


param classifyWorkerImageTag string = 'latest'
param imageDeleteWorkerImageTag string = 'latest'
param mailProcessWorkerImageTag string = 'latest'
param sampleDbWorkerImageTag string = 'latest'
param sampleWorkerImageTag string = 'latest'
param storageWorkerImageTag string = 'latest'
param tabulaGeocodeWorkerImageTag string = 'latest'
param tabulaMergeWorkerImageTag string = 'latest'
param tabulaPostgresWorkerImageTag string = 'latest'
param tabulaSpatializerOrchestratorImageTag string = 'latest'
param tabulaTargetingWorkerImageTag string = 'latest'
param tabulaYentaWorkerImageTag string = 'latest'
param visitorGuideCollectWorkerImageTag string = 'latest'

param workerImageTags object = {
  classifyworker: {
    tag: classifyWorkerImageTag
  }
  imagedeleteworker: {
    tag: imageDeleteWorkerImageTag
  }
  mailprocessworker: {
    tag: mailProcessWorkerImageTag
  }
  sampledbworker: {
    tag: sampleDbWorkerImageTag
  }
  sampleworker: {
    tag: sampleWorkerImageTag
  }
  storageworker: {
    tag: storageWorkerImageTag
  }
  tabulageocodeworker: {
    tag: tabulaGeocodeWorkerImageTag
  }
  tabulamergeworker: {
    tag: tabulaMergeWorkerImageTag
  }
  tabulapostgresworker: {
    tag: tabulaPostgresWorkerImageTag
  }
  tabulaspatializerorchestrator: {
    tag: tabulaSpatializerOrchestratorImageTag
  }
  tabulatargetingworker: {
    tag: tabulaTargetingWorkerImageTag
  }
  tabulayentaworker: {
    tag: tabulaYentaWorkerImageTag
  }
  visitorguidecollectworker: {
    tag: visitorGuideCollectWorkerImageTag
  }
}

@description('Create Workers Container Apps.')
module workersApps 'modules/application/workers/caWorkers.bicep' = {
  name: 'workers'
  scope: rg
  params: {
    location: location
    acrName: registryName
    aiInstrumentationKey: appInsights.outputs.AIInstrumentationKey
    aiConnectionString: appInsights.outputs.AIConnectionString
    caIdentityId: workerIdentity.outputs.IdentityId
    containerAppEnvironmentId: containerAppEnv.outputs.ContainerAppEnvironmentId
    serviceBusNamespace: serviceBusNamespaceName
    workerImageTags: workerImageTags
    keyVaultName: keyVaultName
    keyVaultBaseUrl: keyVaultBaseUrl
    sbConnectionStringSecretName: sbConnectionStringSecretName
    loggingLevel: loggingLevel
  }
  dependsOn: [
    workerIdentity
    containerAppEnv
  ]
}

////////////////////////////////////////////// Databases
var dbIdentityName = '${prefix}-db-mi-${suffix}'

@description('Create Identity for db Coordinator Apps.')
module dbIdentity 'modules/prep/managedIdentityAndAssignments.bicep' = {
  name: dbIdentityName
  scope: rg
  params: {
    identityName: dbIdentityName
    location: location
    registryName: registryName
    registryResourceGroup: registryResourceGroup
    registrySubscriptionId: registrySubscriptionId
    keyVaultName: keyVaultName
    keyVaultResourceGroup: keyVaultResourceGroup
    serviceBusNamespaceName: serviceBusNamespaceName
  }
  dependsOn: [
    serviceBus
  ]
}

param mySqlDatabaseCacheImageTag string = 'latest'
param postgreSqlDatabaseCacheImageTag string = 'latest'

param dbImageSettings object = {
  armstrongdatabasereader: {
    tag: postgreSqlDatabaseCacheImageTag
  }
  armstrongdatabasewriter: {
    tag: postgreSqlDatabaseCacheImageTag
  }
  atlasdatabasereader: {
    tag: mySqlDatabaseCacheImageTag
  }
  atlasdatabasewriter: {
    tag: mySqlDatabaseCacheImageTag
  }
  earthdiverdatabasereader: {
    tag: mySqlDatabaseCacheImageTag
  }
  earthdiverdatabasewriter: {
    tag: mySqlDatabaseCacheImageTag
  }
}

@description('Create Worker Container Apps.')
module dbApps 'modules/application/databases/caDbApps.bicep' = {
  name: 'dbApps'
  scope: rg
  params: {
    location: location
    acrName: registryName
    aiInstrumentationKey: appInsights.outputs.AIInstrumentationKey
    aiConnectionString: appInsights.outputs.AIConnectionString
    caIdentityId: dbIdentity.outputs.IdentityId
    containerAppEnvironmentId: containerAppEnv.outputs.ContainerAppEnvironmentId
    dbImageSettings: dbImageSettings
    serviceBusNamespace: serviceBusNamespaceName
    keyVaultName: keyVaultName
    keyVaultBaseUrl: keyVaultBaseUrl
    loggingLevel: loggingLevel
  }
  dependsOn: [
    dbIdentity
    containerAppEnv
  ]
}

@description('Reference outputs from other modules.')
output NewAIInstrumentationKey string = appInsights.outputs.AIInstrumentationKey
output NewAIConnectionString string = appInsights.outputs.AIConnectionString
output NewServiceBusNamespaceName string = serviceBus.outputs.ServiceBusNamespaceName
output NewStorageAccountName string = storageAccount.outputs.NewStorageAccountName
