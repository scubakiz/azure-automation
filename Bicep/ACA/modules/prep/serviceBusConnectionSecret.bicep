@description('Name of the Key vault')
param keyVaultName string

@description('Name of the secret in the Key vault')
param sbConnectionStringSecretName string

@secure()
@description('Value of the secret in the Key vault')
param sbConnectionString string

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName 
} 

resource sbConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
   parent: kv
   name: sbConnectionStringSecretName   
   properties: {
    value: sbConnectionString
  }
}
