/*
  This script focuses on provisioning a Redis Cache instance and integrating it with a Log Analytics workspace for
    monitoring purposes. It starts by defining parameters for the Redis Cache name, the Log Analytics workspace resource ID,
    a user-assigned identity resource ID, and a default location for all resources. The script then references an existing
    user-assigned managed identity and proceeds to create a Redis Cache resource. The configuration includes specifying the
    Redis Cache name and leveraging the managed identity for secure access. This setup ensures that the Redis Cache instance
    is monitored and managed efficiently, utilizing Azure's managed identities for enhanced security and simplified
    resource access management.
*/
@description('Name of the Redis Cache')
param redisHostName string

@description('Log Analytics workspace resource ID')
param logAnalyticsWorkspaceResourceId string

@description('User assigned identity resource ID')
param caIdentityName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: caIdentityName
}

resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisHostName
  location: location
  // identity: {
  //     type: 'UserAssigned'
  //     userAssignedIdentities: {
  //     '${managedIdentity.id}': {}
  //     }
  //   }
  properties: {
    enableNonSslPort: false    
    redisConfiguration: {
      'aad-enabled': 'true'
    }   

    sku: {
      capacity: 0
      family: 'C'
      name: 'Basic'
    }
  }
}

@allowed([
  'Data Owner'
  'Data Contributor'
  'Data Reader'
])
param builtInAccessPolicyName string = 'Data Owner'

@description('Specify name of custom access policy to create.')
param builtInAccessPolicyAssignmentName string = 'builtInAccessPolicyAssignment-${uniqueString(caIdentityName)}'

@description('Specify human readable name of principal Id of the Microsoft Entra Application name or Managed Identity name used for built-in policy assignment.')
param builtInAccessPolicyAssignmentObjectAlias string = 'builtInAccessPolicyApplication-${uniqueString(caIdentityName)}'

resource redisCacheBuiltInAccessPolicyAssignment 'Microsoft.Cache/redis/accessPolicyAssignments@2023-08-01' = {
  name: builtInAccessPolicyAssignmentName
  parent: redisCache
  properties: {
    accessPolicyName: builtInAccessPolicyName
    objectId: managedIdentity.properties.principalId
    objectIdAlias: builtInAccessPolicyAssignmentObjectAlias
  }
}


resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'main'
  scope: redisCache
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId // Log Analytics workspace resource ID
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    // logs: [
    //   {
    //     category: 'OperationalLogs'
    //     enabled: true
    //   }
    // ]
  }
}

// output RedisCacheId string = redisCache.id
// output RedisCacheHostName string = redisCache.properties.hostName
// output RedisCachePort int = redisCache.properties.port

