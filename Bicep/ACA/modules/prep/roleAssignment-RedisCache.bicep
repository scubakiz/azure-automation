@description('Redis Cache Name')
param rcName string
@description('Principal Id to assign Service Bus roles to.')
param principalId string

@description('Reference to existing Redis Cache')
resource mainRc 'Microsoft.Cache/redis@2023-08-01' existing = {
  name: rcName
}

@description('See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#acrpull')
resource rcReceiverRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // 'Redis Cache Contributor'
  name: 'e0f68234-74aa-48ed-b826-c38b57376e17'
}

@description('Assign RC roles to Identity.')
resource rcReceiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, rcReceiverRoleDefinition.id)
  scope: mainRc
  properties: {
    roleDefinitionId: rcReceiverRoleDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
