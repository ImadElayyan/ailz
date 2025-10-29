// ============================================================================
// ai-foundry.bicep
// Azure AI Foundry Module for AI Landing Zone
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

@description('Agent subnet ID for AI services')
param agentSubnetId string

@description('Enable private DNS zones')
param enablePrivateDns bool = true

@description('Private DNS zone resource IDs')
param privateDnsZoneIds object = {
  cognitiveServices: ''
  openai: ''
  aiServices: ''
  machineLearning: ''
  notebooks: ''
}

@description('Deploy OpenAI models')
param deployModels bool = true

@description('Array of OpenAI models to deploy')
param models array = [
  {
    name: 'gpt-4o'
    version: '2024-08-06'
    deploymentName: 'gpt-4o'
    capacity: 10
    sku: 'GlobalStandard'
  }
]

// ============================================================================
// Variables
// ============================================================================

var aiHubName = 'aih-${baseName}-${environment}'
var aiProjectName = 'aip-${baseName}-${environment}'
var aiServicesName = 'ais-${baseName}-${environment}01'
var openAiName = 'oai-${baseName}-${environment}01'

// ============================================================================
// Azure AI Services (Multi-service account)
// ============================================================================

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiServicesName
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    apiProperties: {}
    customSubDomainName: aiServicesName
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: agentSubnetId
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: false
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// ============================================================================
// Azure OpenAI Service
// ============================================================================

resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    apiProperties: {}
    customSubDomainName: openAiName
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: agentSubnetId
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: false
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// ============================================================================
// Model Deployments - Loop through models array
// ============================================================================

resource modelDeployments 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [for (model, index) in models: if (deployModels) {
  parent: openAi
  name: model.deploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: model.name
      version: model.version
    }
    raiPolicyName: null
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
  sku: {
    name: model.sku
    capacity: model.capacity
  }
}]

// ============================================================================
// AI Hub (AI Studio Hub)
// ============================================================================

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: aiHubName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'AI Hub for ${baseName}'
    description: 'AI Hub for AI Landing Zone - ${environment}'
    
    // Network isolation
    publicNetworkAccess: 'Disabled'
    managedNetwork: {
      isolationMode: 'AllowInternetOutbound'
    }
  }
}

// ============================================================================
// AI Project 
// ============================================================================

resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: aiProjectName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'AI Project for ${baseName}'
    description: 'AI Project for AI Landing Zone - ${environment}'
    
    // Link to hub
    hubResourceId: aiHub.id
    
    // Network isolation is managed by the hub
    publicNetworkAccess: 'Disabled'
  }
}

// ============================================================================
// Private Endpoints (if enabled)
// ============================================================================

resource aiServicesPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateDns) {
  name: 'pe-${aiServicesName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'aiServices-connection'
        properties: {
          privateLinkServiceId: aiServices.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource openAiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateDns) {
  name: 'pe-${openAiName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'openai-connection'
        properties: {
          privateLinkServiceId: openAi.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

// Machine Learning Workspace Private Endpoints
resource aiHubPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateDns) {
  name: 'pe-${aiHubName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'aihub-connection'
        properties: {
          privateLinkServiceId: aiHub.id
          groupIds: [
            'amlworkspace'
          ]
        }
      }
    ]
  }
}

// ============================================================================
// Private DNS Zone Groups (if private DNS is enabled)
// ============================================================================

resource aiServicesDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateDns && !empty(privateDnsZoneIds.cognitiveServices)) {
  parent: aiServicesPrivateEndpoint
  name: 'aiservices-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-cognitiveservices-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.cognitiveServices
        }
      }
    ]
  }
}

resource openAiDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateDns && !empty(privateDnsZoneIds.openai)) {
  parent: openAiPrivateEndpoint
  name: 'openai-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-openai-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.openai
        }
      }
    ]
  }
}

resource aiHubDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateDns && !empty(privateDnsZoneIds.machineLearning)) {
  parent: aiHubPrivateEndpoint
  name: 'aihub-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-api-azureml-ms'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.machineLearning
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('AI Services resource ID')
output aiServicesId string = aiServices.id

@description('AI Services name')
output aiServicesName string = aiServices.name

@description('AI Services endpoint')
output aiServicesEndpoint string = aiServices.properties.endpoint

@description('OpenAI resource ID')
output openAiId string = openAi.id

@description('OpenAI name')
output openAiName string = openAi.name

@description('OpenAI endpoint')
output openAiEndpoint string = openAi.properties.endpoint

@description('AI Hub resource ID')
output aiHubId string = aiHub.id

@description('AI Hub name')
output aiHubName string = aiHub.name

@description('AI Project resource ID')
output aiProjectId string = aiProject.id

@description('AI Project name')
output aiProjectName string = aiProject.name

@description('Model deployment names and details')
output deployedModels array = models
