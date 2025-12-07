// ============================================================================
// Storage Account Module
// ============================================================================

@description('Name prefix for resources')
param namePrefix string

@description('Azure region')
param location string

@description('Environment')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Storage account SKU')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_ZRS', 'Standard_RAGRS'])
param sku string = 'Standard_LRS'

@description('Create blob containers')
param blobContainers array = []

@description('Tags')
param tags object = {}

var storageAccountName = '${replace(namePrefix, '-', '')}stor'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: env == 'prod' ? 'Standard_GRS' : sku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: env == 'prod' ? 30 : 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: env == 'prod' ? 30 : 7
    }
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for container in blobContainers: {
  parent: blobService
  name: container
  properties: {
    publicAccess: 'None'
  }
}]

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
