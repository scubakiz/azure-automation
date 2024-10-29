/*
  This script is designed to leverage Azure's storage capabilities by provisioning a file share within an existing storage
  account. It begins by defining parameters for the storage account and file share names, ensuring that the resources are
  accurately identified. The script then references the existing storage account, specifying its name to establish a
  connection. Following this, it creates a file service under the specified storage account, setting it to 'default' and
  configuring SMB protocol settings to use NTLMv2 authentication. This setup is essential for applications requiring secure,
  scalable file storage solutions in the cloud, facilitating easy access and management of files across distributed systems.
*/
@description('The name of the storage account')
param storageAccountName string
@description('The name of the file share.')
param fileShareName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName 
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {
        authenticationMethods: 'NTLMv2'        
      }
    }
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: fileServices
  name: fileShareName
  properties: {
    accessTier: 'Hot'
    enabledProtocols: 'SMB'
  }
}
