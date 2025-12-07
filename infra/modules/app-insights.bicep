// ============================================================================
// Application Insights Module
// ============================================================================

@description('Name prefix for resources')
param namePrefix string

@description('Azure region')
param location string

@description('Environment')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Tags')
param tags object = {}

var appInsightsName = '${namePrefix}-ai'
var logAnalyticsName = '${namePrefix}-logs'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: env == 'prod' ? 90 : 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    RetentionInDays: env == 'prod' ? 90 : 30
  }
}

// Availability test (basic ping)
resource availabilityTest 'Microsoft.Insights/webtests@2022-06-15' = if (env == 'prod') {
  name: '${namePrefix}-ping'
  location: location
  tags: union(tags, {
    'hidden-link:${appInsights.id}': 'Resource'
  })
  kind: 'ping'
  properties: {
    SyntheticMonitorId: '${namePrefix}-ping'
    Name: 'Health Check'
    Enabled: true
    Frequency: 300
    Timeout: 30
    Kind: 'ping'
    RetryEnabled: true
    Locations: [
      { Id: 'emea-nl-ams-azr' }
      { Id: 'us-va-ash-azr' }
    ]
    Configuration: {
      WebTest: '<WebTest Name="HealthCheck" Enabled="True" Timeout="30" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010"><Items><Request Method="GET" Version="1.1" Url="https://{{FQDN}}/health" /></Items></WebTest>'
    }
  }
}

output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
output logAnalyticsId string = logAnalytics.id
