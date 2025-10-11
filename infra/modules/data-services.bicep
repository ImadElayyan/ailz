// ============================================================================
// data-services.bicep
// Data Services Module for AI Landing Zone
// ============================================================================

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, test, prod)')
param environment string

@description('Base name for resource naming')
param baseName string

@description('Tags to apply to all resources')
param tags object = {}

@description('Private endpoint subnet ID')
param privateEndpointSubnetId string

@description('Enable private DNS zones')
param enablePrivateDns bool = true

@description('Private DNS zone resource IDs')
param privateDnsZoneIds object = {
  search: ''
  cosmosDb: ''
  keyVault: ''
  storageBlob: ''
}

// ============================================================================
// Variables
// ============================================================================

var searchServiceName = 'srch-${baseName}-${environment}'
var cosmosDbName = 'cosmos-${baseName}-${environment}'
var keyVaultName = 'kv-${baseName}-${environment}'
// Storage account names: 3-24 chars, lowercase, no hyphens
// Format: 'st' (2) + unique (13) + env (3) = 18 chars total
var storageAccountName = 'st${uniqueString(resourceGroup().id, baseName)}${substring(environment, 0, 3)}'

// ============================================================================
// Azure AI Search
// ============================================================================

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchServiceName
  location: location
  tags: tags
  sku: {
    name: 'standard'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'disabled'
    networkRuleSet: {
      ipRules: []
    }
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    disableLocalAuth: false
    authOptions: {
      apiKeyOnly: {}
    }
    semanticSearch: 'standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// ============================================================================
// Cosmos DB Account
// ============================================================================

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' = {
  name: cosmosDbName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    isVirtualNetworkFilterEnabled: true
    virtualNetworkRules: []
    disableKeyBasedMetadataWriteAccess: false
    enableFreeTier: false
    enableAnalyticalStorage: false
    analyticalStorageConfiguration: {
      schemaType: 'WellDefined'
    }
    databaseAccountOfferType: 'Standard'
    defaultIdentity: 'FirstPartyIdentity'
    networkAclBypass: 'None'
    disableLocalAuth: false
    enablePartitionMerge: false
    enableBurstCapacity: false
    minimalTlsVersion: 'Tls12'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: []
    ipRules: []
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
        backupStorageRedundancy: 'Geo'
      }
    }
    networkAclBypassResourceIds: []
    publicNetworkAccess: 'Disabled'
  }
}

// Cosmos DB Database
resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-12-01-preview' = {
  parent: cosmosDbAccount
  name: 'ai-landing-zone-db'
  properties: {
    resource: {
      id: 'ai-landing-zone-db'
    }
  }
}

// Cosmos DB Container for AI workloads
resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-12-01-preview' = {
  parent: cosmosDbDatabase
  name: 'ai-workloads'
  properties: {
    resource: {
      id: 'ai-workloads'
      partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      defaultTtl: -1
    }
  }
}

// ============================================================================
// Key Vault
// ============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    accessPolicies: []
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'Disabled'
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
  }
}

// ============================================================================
// Storage Account
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

// Storage Account - Blob Service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    isVersioningEnabled: false
  }
}

// Storage Container for AI data
resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'ai-data'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

// ============================================================================
// Private Endpoints (if enabled)
// ============================================================================

resource searchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateDns) {
  name: 'pe-${searchServiceName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'search-connection'
        properties: {
          privateLinkServiceId: searchService.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource cosmosPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateDns) {
  name: 'pe-${cosmosDbName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'cosmos-connection'
        properties: {
          privateLinkServiceId: cosmosDbAccount.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateDns) {
  name: 'pe-${keyVaultName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'keyvault-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateDns) {
  name: 'pe-${storageAccountName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-blob-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// ============================================================================
// Private DNS Zone Groups (if private DNS is enabled)
// ============================================================================

resource searchDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateDns && !empty(privateDnsZoneIds.search)) {
  parent: searchPrivateEndpoint
  name: 'search-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-search-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.search
        }
      }
    ]
  }
}

resource cosmosDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateDns && !empty(privateDnsZoneIds.cosmosDb)) {
  parent: cosmosPrivateEndpoint
  name: 'cosmos-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-documents-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.cosmosDb
        }
      }
    ]
  }
}

resource keyVaultDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateDns && !empty(privateDnsZoneIds.keyVault)) {
  parent: keyVaultPrivateEndpoint
  name: 'keyvault-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.keyVault
        }
      }
    ]
  }
}

resource storageDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateDns && !empty(privateDnsZoneIds.storageBlob)) {
  parent: storagePrivateEndpoint
  name: 'storage-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.storageBlob
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('AI Search service resource ID')
output searchServiceId string = searchService.id

@description('AI Search service name')
output searchServiceName string = searchService.name

@description('AI Search service endpoint')
output searchServiceEndpoint string = 'https://${searchService.name}.search.windows.net'

@description('Cosmos DB account resource ID')
output cosmosDbAccountId string = cosmosDbAccount.id

@description('Cosmos DB account name')
output cosmosDbAccountName string = cosmosDbAccount.name

@description('Cosmos DB endpoint')
output cosmosDbAccountEndpoint string = cosmosDbAccount.properties.documentEndpoint

@description('Cosmos DB database name')
output cosmosDbDatabaseName string = cosmosDbDatabase.name

@description('Cosmos DB container name')
output cosmosDbContainerName string = cosmosDbContainer.name

@description('Key Vault resource ID')
output keyVaultId string = keyVault.id

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Storage account resource ID')
output storageAccountId string = storageAccount.id

@description('Storage account name')
output storageAccountName string = storageAccount.name

@description('Storage account primary blob endpoint')
output storageBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Storage container name')
output storageContainerName string = storageContainer.name
