/*
  This script is designed to create a managed identity and assign it to various Azure resources including Azure Container
    Registry (ACR), Key Vault, and Service Bus Namespace. It begins by defining parameters for the identity's name and
    location, with the location defaulting to the resource group's location. Additional parameters specify the names,
    subscription IDs, and resource groups for the ACR, Key Vault, and Service Bus Namespace to which the identity will be
    assigned. This setup facilitates secure access management by leveraging Azure's managed identities, eliminating the need
    for explicit credentials while ensuring that the identity has the necessary permissions to interact with specified
    resources.
*/
@description('The name of the identity to create.')
param identityName string
@description('The location of the identity to create.')
param location string = resourceGroup().location

@description('The name of the ACR to assign to')
param registryName string
@description('The subscription of the ACR')
param registrySubscriptionId string
@description('The resource group of the ACR')
param registryResourceGroup string
@description('The name of the Key Vault to assign to')
param keyVaultName string
@description('The resource group of the Key Vault')
param keyVaultResourceGroup string
@description('The name of the Service Bus Namespace to assign to')
param serviceBusNamespaceName string
// @description('Name of Redis Cache')
// param redisCacheName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

@description('Assign Container App Identity to ACR Pull Role.')
module caAcrRoleAssignment 'roleAssignment-Acr.bicep' = {
  name: 'caAcrRoleAssignment-${identityName}'
  scope: resourceGroup(registrySubscriptionId, registryResourceGroup)
  params: {
    acrName: registryName
    principalId: managedIdentity.properties.principalId
  }
}

@description('Assign Container App Identity to Key Vault Secret Reader.')
module caKvRoleAssignment 'roleAssignment-KeyVault.bicep' = {
  name: 'caKvRoleAssignment-${identityName}'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    kvName: keyVaultName
    principalId: managedIdentity.properties.principalId
  }
}

@description('Assign Container App Identity to Service Bus.')
module caSbRoleAssignment 'roleAssignment-ServiceBus.bicep' = {
  name: 'caSbRoleAssignment-${identityName}'
  params: {
    sbName: serviceBusNamespaceName
    principalId: managedIdentity.properties.principalId
  }
}

// @description('Assign Container App Identity to Service Bus.')
// module caRcRoleAssignment 'roleAssignment-RedisCache.bicep' = {
//   name: 'caRcRoleAssignment-${identityName}'
//   params: {
//     rcName: redisCacheName
//     principalId: managedIdentity.properties.principalId
//   }
// }

output IdentityId string = managedIdentity.id
output PrincipalId string = managedIdentity.properties.principalId
output ClientId string = managedIdentity.properties.clientId
