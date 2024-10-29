/*
  This script defines the configuration for deploying a Container App, including specifying the container name, location,
  Azure Container Registry (ACR) details, Application Insights keys, Container App identity, and environment settings. It
  outlines parameters for the container image name and tag, Dapr App ID for microservices communication, ingress settings,
  and the workload profile. The script is tailored to facilitate the setup of a Container App with optional Dapr integration,
  supporting both internal and external ingress, and allowing for a flexible deployment model based on the specified workload
  profile. This setup is crucial for applications leveraging Azure's Container Apps for scalable, microservices-based
  architectures.
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
param containerAppEnvironmentId string = 'gatewaydapr'
@description('Name of the Container App Image')
param imageName string
@description('Tag of the Container App image')
param imageTag string = 'latest'
@description('Dapr App Id of the Container App')
param daprAppId string
@description('Internal Ingress')
param externalIngress bool = false
@description('Workload Profile')
param workloadProfile string = 'Consumption'
@description('Job Message Type')
param jobMessageType string
@description('Service Bus Namespace')
param serviceBusNamespace string
@description('Service Bus Connection String Secret Name')
param sbConnectionStringSecretName string

@description('Key Vault Name')
param keyVaultUrl string

param loggingLevel string = 'Information'
param lastUpdated string = utcNow()

var globalStoragePublicUrl = '${keyVaultUrl}GlobalStoragePublic'
var globalStoragePrivateUrl = '${keyVaultUrl}GlobalStoragePrivate'
var compendiumAccessKeyUrl = '${keyVaultUrl}CompendiumAccessKey'
var mailgunSigningKeyUrl = '${keyVaultUrl}MailgunSigningKey'
var mailgunEarthdiverAPIKeyUrl = '${keyVaultUrl}MailgunEarthdiverAPIKey'
var mailgunGoTravelSitesAPIKeyUrl = '${keyVaultUrl}MailgunGoTravelSitesAPIKey'
var sbConnectionStringUrl = '${keyVaultUrl}${sbConnectionStringSecretName}'

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
      secrets: [
        {
          identity: caIdentityId
          keyVaultUrl: globalStoragePublicUrl
          name: 'globalstoragepublic'
        }
        {
          identity: caIdentityId
          keyVaultUrl: globalStoragePrivateUrl
          name: 'globalstorageprivate'
        }
        {
          identity: caIdentityId
          keyVaultUrl: compendiumAccessKeyUrl
          name: 'compendiumaccesskey'
        }
        {
          identity: caIdentityId
          keyVaultUrl: mailgunSigningKeyUrl
          name: 'mailgunsigningkey'
        }
        {
          identity: caIdentityId
          keyVaultUrl: mailgunEarthdiverAPIKeyUrl
          name: 'mailgunearthdiverapikey'
        }
        {
          identity: caIdentityId
          keyVaultUrl: mailgunGoTravelSitesAPIKeyUrl
          name: 'mailgungotravelsitesapikey'
        }
        {
          identity: caIdentityId
          keyVaultUrl: sbConnectionStringUrl
          name: 'sbconnectionstring'
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
              name: 'ED_CACHE_NAME'
              value: 'atlascache'
            }
            {
              name: 'ED_JOB_MESSAGE_TYPE'
              value: jobMessageType
            }
            {
              name: 'ED_EARTHDIVER_DB_CACHE'
              value: 'earthdiverdatabasecache'
            }
            {
              name: 'ED_EARTHDIVER_DB_HOSTNAME'
              value: 'earthdiverdatabasereader'
            }
            {
              name: 'ED_ATLAS_DB_CACHE'
              value: 'atlasdatabasecache'
            }
            {
              name: 'ED_ATLAS_DB_HOSTNAME'
              value: 'atlasdatabasereader'
            }
            {
              name: 'ED_ARMSTRONG_DB_CACHE'
              value: 'armstrongdatabasecache'
            }
            {
              name: 'ED_ARMSTRONG_DB_HOSTNAME'
              value: 'armstrongdatabasereader'
            }
            {
              name: 'ED_GLOBAL_STORAGE_PUBLIC'
              secretRef: 'globalstoragepublic'
            }
            {
              name: 'ED_GLOBAL_STORAGE_PRIVATE'
              secretRef: 'globalstorageprivate'
            }
            {
              name: 'ED_TABULA_MERGE_KEY'
              secretRef: 'compendiumaccesskey'
            }
            {
              name: 'ED_MAILGUN_SIGNING_KEY'
              secretRef: 'mailgunsigningkey'
            }
            {
              name: 'ED_MAILGUN_EARTHDIVER_API_KEY'
              secretRef: 'mailgunearthdiverapikey'
            }
            {
              name: 'ED_MAILGUN_GOTRAVELSITES_API_KEY'
              secretRef: 'mailgungotravelsitesapikey'
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
