@description('Service Bus Name')
param sbName string
@description('Principal Id to assign Service Bus roles to.')
param principalId string

@description('Reference to existing Service Bus.')
resource mainSb 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: sbName
}

@description('See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#acrpull')
resource sbReceiverRoleDefinition0 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // 'Azure Service Bus Data Owner' 
  name: '090c5cfd-751d-490a-894a-3ce6f1109419'
}

@description('Assign SB roles to Identity.')
resource sbReceiverRoleAssignment0 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, sbReceiverRoleDefinition0.id)
  scope: mainSb
  properties: {
    roleDefinitionId: sbReceiverRoleDefinition0.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

@description('See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#acrpull')
resource sbReceiverRoleDefinition1 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // 'Azure Service Bus Data Receiver' 
  name: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'  
}

@description('Assign SB roles to Identity.')
resource sbReceiverRoleAssignment1 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, sbReceiverRoleDefinition1.id)
  scope: mainSb
  properties: {
    roleDefinitionId: sbReceiverRoleDefinition1.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

@description('See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#acrpull')
resource sbSenderRoleDefinition2 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // 'Azure Service Bus Data Sender' 
  name: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'  
}

@description('Assign SB roles to Identity.')
resource sbSenderRoleAssignment2 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, sbSenderRoleDefinition2.id)
  scope: mainSb
  properties: {
    roleDefinitionId: sbSenderRoleDefinition2.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
