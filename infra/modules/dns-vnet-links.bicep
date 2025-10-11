// ============================================================================
// dns-vnet-links.bicep
// Virtual Network Links for Private DNS Zones
// ============================================================================

@description('Location for the virtual network links')
param location string = 'global'

@description('Environment name (dev, test, prod)')
param environment string

@description('Spoke VNet resource ID to link to DNS zones')
param spokeVnetId string

@description('Private DNS zone resource IDs')
param privateDnsZoneIds object

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// Variables
// ============================================================================

var linkNamePrefix = 'link-ai-spoke-${environment}'

// ============================================================================
// Virtual Network Links - AI Services DNS Zones
// ============================================================================

// Cognitive Services DNS Zone Link
resource cognitiveServicesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.cognitiveServices)) {
  name: '${split(privateDnsZoneIds.cognitiveServices, '/')[8]}/${linkNamePrefix}-cogsvcs'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// OpenAI DNS Zone Link
resource openaiLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.openai)) {
  name: '${split(privateDnsZoneIds.openai, '/')[8]}/${linkNamePrefix}-openai'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// AI Services DNS Zone Link
resource aiServicesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.aiServices)) {
  name: '${split(privateDnsZoneIds.aiServices, '/')[8]}/${linkNamePrefix}-aiservices'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// ============================================================================
// Virtual Network Links - Data Services DNS Zones (for future use)
// ============================================================================

// Search DNS Zone Link
resource searchLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.search)) {
  name: '${split(privateDnsZoneIds.search, '/')[8]}/${linkNamePrefix}-search'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// Cosmos DB DNS Zone Link
resource cosmosDbLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.cosmosDb)) {
  name: '${split(privateDnsZoneIds.cosmosDb, '/')[8]}/${linkNamePrefix}-cosmos'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// Key Vault DNS Zone Link
resource keyVaultLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.keyVault)) {
  name: '${split(privateDnsZoneIds.keyVault, '/')[8]}/${linkNamePrefix}-kv'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// Storage Blob DNS Zone Link
resource storageBlobLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.storageBlob)) {
  name: '${split(privateDnsZoneIds.storageBlob, '/')[8]}/${linkNamePrefix}-blob'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// App Configuration DNS Zone Link
resource appConfigLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.appConfig)) {
  name: '${split(privateDnsZoneIds.appConfig, '/')[8]}/${linkNamePrefix}-appconfig'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// Container Apps DNS Zone Link
resource containerAppsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.containerApps)) {
  name: '${split(privateDnsZoneIds.containerApps, '/')[8]}/${linkNamePrefix}-aca'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// Container Registry DNS Zone Link
resource containerRegistryLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.containerRegistry)) {
  name: '${split(privateDnsZoneIds.containerRegistry, '/')[8]}/${linkNamePrefix}-acr'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// ============================================================================
// Virtual Network Links - Machine Learning DNS Zones
// ============================================================================

// Machine Learning API DNS Zone Link
resource machineLearningLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.machineLearning)) {
  name: '${split(privateDnsZoneIds.machineLearning, '/')[8]}/${linkNamePrefix}-ml'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// Machine Learning Notebooks DNS Zone Link
resource notebooksLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.notebooks)) {
  name: '${split(privateDnsZoneIds.notebooks, '/')[8]}/${linkNamePrefix}-notebooks'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// Application Insights DNS Zone Link
resource appInsightsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateDnsZoneIds.appInsights)) {
  name: '${split(privateDnsZoneIds.appInsights, '/')[8]}/${linkNamePrefix}-appinsights'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Created virtual network link names')
output virtualNetworkLinks object = {
  cognitiveServices: !empty(privateDnsZoneIds.cognitiveServices) ? cognitiveServicesLink.name : 'not-created'
  openai: !empty(privateDnsZoneIds.openai) ? openaiLink.name : 'not-created'
  aiServices: !empty(privateDnsZoneIds.aiServices) ? aiServicesLink.name : 'not-created'
  search: !empty(privateDnsZoneIds.search) ? searchLink.name : 'not-created'
  cosmosDb: !empty(privateDnsZoneIds.cosmosDb) ? cosmosDbLink.name : 'not-created'
  keyVault: !empty(privateDnsZoneIds.keyVault) ? keyVaultLink.name : 'not-created'
  storageBlob: !empty(privateDnsZoneIds.storageBlob) ? storageBlobLink.name : 'not-created'
  appConfig: !empty(privateDnsZoneIds.appConfig) ? appConfigLink.name : 'not-created'
  containerApps: !empty(privateDnsZoneIds.containerApps) ? containerAppsLink.name : 'not-created'
  containerRegistry: !empty(privateDnsZoneIds.containerRegistry) ? containerRegistryLink.name : 'not-created'
  machineLearning: !empty(privateDnsZoneIds.machineLearning) ? machineLearningLink.name : 'not-created'
  notebooks: !empty(privateDnsZoneIds.notebooks) ? notebooksLink.name : 'not-created'
  appInsights: !empty(privateDnsZoneIds.appInsights) ? appInsightsLink.name : 'not-created'
}
