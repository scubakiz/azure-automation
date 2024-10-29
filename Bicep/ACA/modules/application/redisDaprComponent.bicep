@description('Name of the Container App Enviornment')
param containerAppsEnvName string
@description('Name of Dapr component')
param daprComponentName string

@description('Name of the Redis Host')
param redisHostName string

@description('Name of the Identity to use to access Key Vault')
param caIdentityName string

@description('Container App Environment')
resource cappsEnv 'Microsoft.App/managedEnvironments@2022-10-01' existing = {
  name: containerAppsEnvName
}

@description('Redis Cache')
resource redisHost 'Microsoft.Cache/redis@2023-08-01' existing = {
  name: redisHostName
}

// resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
//   name: caIdentityName
// }

var redisPassword = redisHost.listKeys().primaryKey



@description('Dapr component for Service Bus')
resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-08-01-preview' = {
  name: daprComponentName
  parent: cappsEnv
  properties: {
    componentType: 'state.redis'
    version: 'v1'
    scopes: [
      'atlas-visitor-guide-collect-worker'
    ]
    metadata: [
      {
        name: 'redisHost'
        value: '${redisHost.properties.hostName}:${redisHost.properties.sslPort}'        
      }
      {
        name: 'ttlInSeconds'
        value: '120'
      }
      {
        name: 'redisDatabase'
        value: '0'
      }
      {
        name: 'redisPassword'
        value: redisPassword
      }
      {
        name: 'enableTLS'
        value: 'true'
      }
      // {
      //   name: 'principalId'
      //   value: managedIdentity.properties.principalId
      // }
      //  {
      //   name: 'azureClientId'
      //   value: managedIdentity.properties.clientId
      // }
      // {
      //   name: 'azureTenantId'
      //   value: managedIdentity.properties.tenantId
      // }
      // {
      //   name: 'userAssignedIdentity'
      //   value: managedIdentity.properties.clientId
      // }
      // {
      //   name: 'tenantId'
      //   value: subscription().tenantId
      // }
    ]
  }
}
