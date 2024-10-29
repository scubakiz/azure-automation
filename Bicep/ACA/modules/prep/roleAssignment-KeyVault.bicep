@description('Key Vault Name')
param kvName string
@description('Principal Id to assign Key Vault Secrets User to.')
param principalId string

@description('Reference to existing Key Vault.')
resource mainKv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
}

@description('''
This is the built-in Key Vault Secrets User role. 
See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#acrpull
''')
resource kvRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // 'Key Vault Secrets User' 
  name: '4633458b-17de-408a-b874-0445c86b69e6'  
}

@description('Assign Key Vault Secrets User to ca Identity.')
resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, kvRoleDefinition.id)
  scope: mainKv
  properties: {
    roleDefinitionId: kvRoleDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

