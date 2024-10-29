/*
  This script focuses on the provisioning of Application Insights within Azure, aiming to enhance monitoring and
  observability for web applications. It defines a resource for Application Insights, specifying its name, location, and
  relevant tags, including a display name and project name. The configuration emphasizes the web application type and
  integrates with a Log Analytics workspace for comprehensive analytics and monitoring. Additionally, the script outputs the
  Instrumentation Key and Connection String of the Application Insights resource, facilitating easy integration with
  applications for telemetry and diagnostics. This setup is crucial for developers and IT professionals looking to gain
  insights into application performance and user experiences.
*/
@description('Name of the Application Insights')
param appInsightsName string
@description('Name of the Application')
param appName string
@description('Location for all resources.')
param location string = resourceGroup().location
@description('Existing Log Analytics Workspace')
param logAnalyticsId string

@description('Create Application Insights')
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'string'
  tags: {
    displayName: 'AppInsight'
    ProjectName: appName
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsId
  }
}

@description('Output Application Insights Instrumentation Key and Connection String')
output AIInstrumentationKey string = appInsights.properties.InstrumentationKey
output AIConnectionString string = appInsights.properties.ConnectionString
