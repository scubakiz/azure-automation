/*
  This script is designed to configure a Container App by specifying various parameters including the name of the container,
    its location, and details about the Azure Container Registry (ACR) it utilizes. It also integrates Application Insights
    for monitoring by providing both the Instrumentation Key and Connection String. The identity of the Container App and
    the ID of its environment are specified to ensure proper deployment and management. Additionally, details about the
    Service Bus Namespace are included to facilitate messaging capabilities. The script concludes with parameters for the
    Container App's image name and tag, enabling precise control over the deployed container image version.
*/
@description('Name of the Container App container.')
param containerAppName string
@description('Location for all resources.')
param location string = resourceGroup().location
@description('Name of the Azure Container Registry')
param acrName string
@description('Application Insights Instrumentation Key')
param aiInstrumentationKey string
@description('Application Insights Connection String')
param aiConnectionString string
@description('The identity of the Container App')
param caIdentityId string
@description('Id of the Container App Environment')
param containerAppEnvironmentId string
@description('The name of the Service Bus Namespace')
param serviceBusNamespace string
@description('Name of the Container App Image')
param imageName string
@description('Tag of the Container App image')
param imageTag string = 'latest'
@description('Dapr App Id of the Container App')
param daprAppId string
@description('Workload Profile')
param workloadProfile string = 'Consumption'
@description('Db Connection String Key Vault Secret Uri')
param dbConnectionStringUri string
@description('Job Message Type')
param jobMessageType string

@description('Logging Level')
param loggingLevel string = 'Information'

param lastUpdated string = utcNow()

@description('Create Container App')
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${caIdentityId}': {}
    }
  }
  properties: {
    environmentId: containerAppEnvironmentId
    configuration: {
      dapr: {
        enabled: true
        appId: daprAppId
        appPort: 5000
      }
      ingress: {
        external: false
        transport: 'auto'
        targetPort: 5000
      }
      registries: [
        {
          identity: caIdentityId
          server: '${acrName}.azurecr.io'
        }
      ]
      secrets: [
        {
          identity: caIdentityId
          keyVaultUrl: dbConnectionStringUri
          name: 'dbconnectionstring'
        }
      ]
    }

    template: {
      containers: [
        {
          name: containerAppName
          image: '${acrName}.azurecr.io/atlas/${imageName}:${imageTag}'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
             {
              name: 'LAST_UPDATED'
              value: lastUpdated
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:5000'
            }
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: aiInstrumentationKey
            }
            {
              name: 'APPINSIGHTS_CONNECTIONSTRING'
              value: aiConnectionString
            }
            {
              name: 'ED_PUB_SUB_NAME'
              value: 'atlaspubsub'              
            }
            {
              name: 'ED_JOB_MESSAGE_TYPE'
              value: jobMessageType
            }
            {
              name: 'ED_DB_POSTGRESQL_CONNECTION_STRING'
              secretRef: 'dbconnectionstring'
            }
            {
              name: 'ED_DB_MYSQL_CONNECTION_STRING'
              secretRef: 'dbconnectionstring'
            }
              {
              name: 'Logging__LogLevel__Microsoft'
              value: loggingLevel
            }         
            {              
              name: 'Logging__LogLevel__Default'
              value: loggingLevel                     
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: '${containerAppName}-sb-scale'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: jobMessageType
                namespace: serviceBusNamespace
                messageCount: '1'
              }
              auth: [  {
                  secretRef: 'sbconnectionstring'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
    workloadProfileName: workloadProfile
  }
}

@description('The API endpoint')
output APIEndpoint string = containerApp.properties.configuration.ingress.fqdn
