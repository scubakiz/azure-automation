/*
  This script is focused on creating a user-assigned managed identity in Azure, providing a secure, scalable way to manage
    credentials for accessing various Azure services. It starts by defining two parameters: the name of the identity and its
    location, which defaults to the location of the resource group. A managed identity resource is then declared, specifying
    its name and location. The script concludes by outputting the identity's ID and principal ID, which can be used to grant
    it access to other Azure resources. This approach enhances security by avoiding hard-coded credentials and simplifies
    identity management for Azure resources.
*/
@description('The name of the identity to create.')
param identityName string
@description('The location of the identity to create.')
param location string = resourceGroup().location

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

output IdentityId string = managedIdentity.id
output PrincipalId string = managedIdentity.properties.principalId
