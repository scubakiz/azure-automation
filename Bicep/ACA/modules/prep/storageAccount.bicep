@description('The name of the storage account')
param storageAccountName string
@description('Location for all resources.')
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

output NewStorageAccountName string = storageAccount.name
#disable-next-line outputs-should-not-contain-secrets
output NewStorageAccountKey string = listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value

