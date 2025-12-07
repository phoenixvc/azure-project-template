// ============================================================================
// Redis Cache Module
// ============================================================================

@description('Name prefix for resources')
param namePrefix string

@description('Azure region')
param location string

@description('Environment')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('SKU name')
@allowed(['Basic', 'Standard', 'Premium'])
param skuName string = 'Basic'

@description('SKU family')
@allowed(['C', 'P'])
param skuFamily string = 'C'

@description('Cache capacity (0-6 for Basic/Standard, 1-5 for Premium)')
param capacity int = 0

@description('Tags')
param tags object = {}

var redisName = '${namePrefix}-redis'

resource redis 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisName
  location: location
  tags: tags
  properties: {
    sku: {
      name: env == 'prod' ? 'Standard' : skuName
      family: env == 'prod' ? 'C' : skuFamily
      capacity: env == 'prod' ? 1 : capacity
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
    publicNetworkAccess: 'Enabled'
  }
}

output redisId string = redis.id
output redisName string = redis.name
output redisHostName string = redis.properties.hostName
output redisPort int = redis.properties.sslPort
