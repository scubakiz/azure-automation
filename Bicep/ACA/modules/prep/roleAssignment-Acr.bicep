@description('Name of the Azure Container Registry.')
param acrName string
@description('Principal Id to assign AcrPull to.')
param principalId string

@description('Reference to existing Azure Container Registry.')
resource mainAcr 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: acrName
}

@description('''
This is the built-in AcrPull role. 
See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#acrpull
''')
resource acrRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  //'AcrPull'  
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

@description('Assign AcrPull role to Identity for ACR.')
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, acrRoleDefinition.id)
  scope: mainAcr
  properties: {
    roleDefinitionId: acrRoleDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
