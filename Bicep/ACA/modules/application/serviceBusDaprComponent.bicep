@description('Name of the Container App Enviornment')
param containerAppsEnvName string
@description('Name of Dapr component')
param daprComponentName string
// @description('Name of the Service Bus connection string secret')
// param sbConnectionStringSecretName string

@description('Name of the Service Bus Namespace')
param serviceBusNamespaceName string

// @description('Name of the Identity to use to access Key Vault')
// param caIdentityId string

// @description('Name of the Key Vault')
// param keyVaultName string
// @description('Base url of Key Vault')
// param keyVaultBaseUrl string
// param keyVaultUrl = 'https://${keyVaultName}${keyVaultBaseUrl}'

// var sbConnectionStringUrl = '${keyVaultUrl}${sbConnectionStringSecretName}'

@description('Container App Environment')
resource cappsEnv 'Microsoft.App/managedEnvironments@2022-10-01' existing = {
  name: containerAppsEnvName
}

@description('Service Bus')
resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusNamespaceName
}

// @description('Dapr component for Secret Store')
// resource daprSecretComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
//   name: '${daprComponentName}-secretstore'
//   parent: cappsEnv
//   properties: {
//     componentType: 'secretstores.azure.keyvault'
//     version: 'v1'
//     metadata: [
//       {
//         name: 'vaultName'
//         value: keyVaultName
//       }
//       {
//         name: 'azureClientId'
//         value: caIdentityId
//       }
//     ]
//     secrets: [
//       {
//         identity: caIdentityId
//         keyVaultUrl: sbConnectionStringUrl
//         name: 'sbconnectionstring'
//       }
//     ]
//   }
// }

//#disable-next-line outputs-should-not-contain-secrets
//var ServiceBusConnectionString = listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString

@description('Dapr component for Service Bus')
resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
  name: daprComponentName
  parent: cappsEnv
  properties: {
    componentType: 'pubsub.azure.servicebus.queues'
    version: 'v1'
    metadata: [
      {
        name: 'connectionString'
        value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
        //secretRef: 'sbconnectionstring'
      }
      {
        name: 'maxDeliveryCount'
        value: '1'
      }
      // {
      //   name: 'principalId'
      //   value: caPrincipalId
      // }
      // {
      //   name: 'tenantId'
      //   value: subscription().tenantId
      // }
      // {
      //   name: 'type'
      //   value: 'UserAssigned'
      // }
      // {
      //   name: 'namespaceName'
      //   value: '${serviceBusNamespaceName}.servicebus.windows.net'
      // }
      // {
      //   name: 'consumerID'
      //   value: 'atlas'
      // }
    ]
    //secretStoreComponent: '${daprComponentName}-secretstore'
    // secrets: [
    //   {
    //     identity: caIdentityId
    //     keyVaultUrl: sbConnectionStringUrl
    //     name: 'sbconnectionstring'
    //   }
    // ]
    scopes: [
      'atlas-work-coordinator'
      'atlas-sample-worker'
      'atlas-sample-db-worker'
      'atlas-storage-worker'
      'atlas-mailprocess-worker'
      'atlas-classify-worker'
      'atlas-image-delete-worker'
      'atlas-tabula-merge-worker'
      'atlas-tabula-spatializer-worker'
      'atlas-tabula-targeting-worker'
      'atlas-tabula-yenta-worker'
      'atlas-tabula-geocode-worker'
      'atlas-tabula-postgres-worker'
      'atlas-visitor-guide-collect-worker'
      'armstrongdatabasewriter'
      'atlasdatabasewriter'
      'earthdiverdatabasewriter'
    ]
  }
  // dependsOn: [
  //   daprSecretComponent
  // ]
}
