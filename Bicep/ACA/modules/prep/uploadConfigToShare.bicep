@description('Name of the file share')
param fileShareName string = 'config'
@description('Desired name of the storage account')
param storageAccountName string 
@description('Location of the resource group')
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName 
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployscript-upload-file'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: loadTextContent('../../data/action-mappings.json')
      }
    ]
    scriptContent: 'echo "$CONTENT" > action-mappings.json && az storage file upload --source action-mappings.json -s ${fileShareName}'
  }
}
