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
param containerAppEnvironmentId string = 'gatewaydapr'
@description('Name of the Container App Image')
param imageName string
@description('Tag of the Container App image')
param imageTag string = 'latest'
@description('Dapr App Id of the Container App')
param daprAppId string
@description('Internal Ingress')
param externalIngress bool = false
@description('Storage Name')
param storageName string
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
        external: externalIngress
        transport: 'auto'
        targetPort: 5000
      }
      registries: [
        {
          identity: caIdentityId
          server: '${acrName}.azurecr.io'
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
              name: 'Logging__LogLevel__Microsoft'
              value: loggingLevel
            }         
            {              
              name: 'Logging__LogLevel__Default'
              value: loggingLevel                     
            }
          ]
          volumeMounts: [
            {
              mountPath: '/app/config'
              volumeName: 'config-volume'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
      }
      volumes: [
        {
          name: 'config-volume'
          storageName: storageName
          storageType: 'AzureFile'
        }
      ]
    }
    workloadProfileName: 'D4'
  }
}

@description('The API endpoint')
output APIEndpoint string = containerApp.properties.configuration.ingress.fqdn
