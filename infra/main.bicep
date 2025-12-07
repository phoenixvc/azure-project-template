// ============================================================================
// Main Infrastructure Deployment
// ============================================================================

targetScope = 'subscription'

// ============================================================================
// Parameters
// ============================================================================

@description('Organization code')
@allowed(['nl', 'pvc', 'tws', 'mys'])
param org string

@description('Environment')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Project name')
@minLength(2)
@maxLength(20)
param project string

@description('Azure region code')
@allowed(['euw', 'eus', 'wus', 'san', 'saf'])
param region string

@description('Azure location')
param location string = 'westeurope'

// Feature flags
@description('Deploy API (App Service or Container App)')
param deployApi bool = true

@description('Use Container Apps instead of App Service')
param useContainerApps bool = false

@description('Deploy Web frontend')
param deployWeb bool = true

@description('Deploy PostgreSQL database')
param deployDatabase bool = true

@description('Deploy Storage Account')
param deployStorage bool = true

@description('Deploy Key Vault')
param deployKeyVault bool = true

@description('Deploy Redis Cache')
param deployRedis bool = false

@description('Deploy Application Insights')
param deployAppInsights bool = true

// Configuration
@description('App Service SKU')
param appServiceSku string = 'B1'

@description('Database admin password')
@secure()
param databasePassword string = ''

@description('Container image (for Container Apps)')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

// ============================================================================
// Variables
// ============================================================================

var resourceGroupName = '${org}-${env}-${project}-rg-${region}'
var namePrefix = '${org}-${env}-${project}'
var tags = {
  org: org
  env: env
  project: project
  region: region
  managedBy: 'bicep'
}

// ============================================================================
// Resource Group
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ============================================================================
// Modules
// ============================================================================

// Application Insights (deploy first - other modules may reference it)
module appInsights 'modules/app-insights.bicep' = if (deployAppInsights) {
  scope: rg
  name: 'appInsights-${uniqueString(rg.id)}'
  params: {
    namePrefix: namePrefix
    location: location
    env: env
    tags: tags
  }
}

// Key Vault
module keyVault 'modules/key-vault.bicep' = if (deployKeyVault) {
  scope: rg
  name: 'keyVault-${uniqueString(rg.id)}'
  params: {
    namePrefix: namePrefix
    location: location
    env: env
    tags: tags
    accessPolicies: []
  }
}

// Storage Account
module storage 'modules/storage.bicep' = if (deployStorage) {
  scope: rg
  name: 'storage-${uniqueString(rg.id)}'
  params: {
    namePrefix: namePrefix
    location: location
    env: env
    tags: tags
    blobContainers: [
      'uploads'
      'exports'
    ]
  }
}

// PostgreSQL Database
module postgres 'modules/postgres.bicep' = if (deployDatabase && databasePassword != '') {
  scope: rg
  name: 'postgres-${uniqueString(rg.id)}'
  params: {
    namePrefix: namePrefix
    location: location
    env: env
    tags: tags
    adminPassword: databasePassword
    databaseName: project
  }
}

// Redis Cache
module redis 'modules/redis.bicep' = if (deployRedis) {
  scope: rg
  name: 'redis-${uniqueString(rg.id)}'
  params: {
    namePrefix: namePrefix
    location: location
    env: env
    tags: tags
  }
}

// App Service (traditional)
module appService 'modules/app-service.bicep' = if (deployApi && !useContainerApps) {
  scope: rg
  name: 'appService-${uniqueString(rg.id)}'
  params: {
    namePrefix: '${namePrefix}-api'
    location: location
    env: env
    sku: appServiceSku
    tags: tags
    appInsightsConnectionString: deployAppInsights ? appInsights.?outputs.?connectionString ?? '' : ''
    keyVaultUri: deployKeyVault ? keyVault.?outputs.?keyVaultUri ?? '' : ''
  }
}

// Container App (modern)
module containerApp 'modules/container-app.bicep' = if (deployApi && useContainerApps) {
  scope: rg
  name: 'containerApp-${uniqueString(rg.id)}'
  params: {
    namePrefix: '${namePrefix}-api'
    location: location
    env: env
    containerImage: containerImage
    tags: tags
    appInsightsConnectionString: deployAppInsights ? appInsights.?outputs.?connectionString ?? '' : ''
  }
}

// Web App Service (for frontend)
module webApp 'modules/app-service.bicep' = if (deployWeb) {
  scope: rg
  name: 'webApp-${uniqueString(rg.id)}'
  params: {
    namePrefix: '${namePrefix}-web'
    location: location
    env: env
    sku: appServiceSku
    tags: tags
    appInsightsConnectionString: deployAppInsights ? appInsights.?outputs.?connectionString ?? '' : ''
  }
}

// Grant API App access to Key Vault
module keyVaultAccess 'modules/key-vault-role-assignment.bicep' = if (deployKeyVault && deployApi) {
  scope: rg
  name: 'keyVaultAccess-${uniqueString(rg.id)}'
  params: {
    keyVaultName: keyVault.?outputs.?keyVaultName ?? ''
    principalId: useContainerApps ? (containerApp.?outputs.?principalId ?? '') : (appService.?outputs.?principalId ?? '')
  }
}

// ============================================================================
// Outputs
// ============================================================================

output resourceGroupName string = rg.name
output location string = location

// API outputs
output apiUrl string = deployApi ? (useContainerApps ? 'https://${containerApp.?outputs.?containerAppFqdn ?? ''}' : 'https://${appService.?outputs.?appServiceHostname ?? ''}') : ''

// Web outputs
output webUrl string = deployWeb ? 'https://${webApp.?outputs.?appServiceHostname ?? ''}' : ''

// Database outputs
output databaseServer string = deployDatabase ? postgres.?outputs.?serverFqdn ?? '' : ''

// Monitoring outputs
output appInsightsConnectionString string = deployAppInsights ? appInsights.?outputs.?connectionString ?? '' : ''

// Key Vault outputs
output keyVaultUri string = deployKeyVault ? keyVault.?outputs.?keyVaultUri ?? '' : ''

// Storage outputs
output storageEndpoint string = deployStorage ? storage.?outputs.?primaryEndpoint ?? '' : ''
