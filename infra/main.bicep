// ============================================================================
// main.bicep
// AI Landing Zone - Main Deployment Template
// ============================================================================

targetScope = 'subscription'

// ============================================================================
// Parameters
// ============================================================================

@description('The location for all resources')
param location string = 'eastus'

@description('Environment name (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Base name for resource naming')
param baseName string = 'ai-landingzone'

// VNet Configuration
@description('VNet address prefix for the spoke network')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('Agent subnet address prefix')
param agentSubnetPrefix string = '10.1.1.0/24'

@description('Private Endpoint subnet address prefix')
param peSubnetPrefix string = '10.1.2.0/24'

@description('Application Gateway subnet address prefix')
param appGwSubnetPrefix string = '10.1.3.0/24'

@description('API Management subnet address prefix')
param apimSubnetPrefix string = '10.1.4.0/24'

@description('Container Apps Environment subnet address prefix')
param acaEnvSubnetPrefix string = '10.1.5.0/24'

@description('DevOps Agents subnet address prefix')
param devopsAgentsSubnetPrefix string = '10.1.6.0/24'

// Hub Configuration
@description('Hub subscription ID')
param hubSubscriptionId string

@description('Hub resource group name')
param hubResourceGroupName string

@description('Hub VNet name')
param hubVnetName string

// Routing Configuration
@description('Azure Firewall or NVA private IP address in hub')
param firewallPrivateIp string = '10.0.1.4'

@description('Enable default route to firewall')
param enableDefaultRoute bool = true

@description('Use remote gateways in hub (VPN/ExpressRoute)')
param useRemoteGateways bool = false

// Private DNS Zone Configuration
@description('Existing Private DNS Zone resource IDs from different subscriptions')
param privateDnsZoneIds object = {
  cognitiveServices: ''
  openai: ''
  aiServices: ''
  search: ''
  cosmosDb: ''
  keyVault: ''
  storageBlob: ''
  appConfig: ''
  containerApps: ''
  containerRegistry: ''
  machineLearning: ''
  notebooks: ''
}

// Observability Configuration
@description('Existing Log Analytics Workspace resource ID from different subscription')
param logAnalyticsWorkspaceResourceId string

// ============================================================================
// Deployment Toggles - Enable/Disable Individual Services
// ============================================================================

@description('Deployment toggles for all services')
param deployToggles object = {
  // Core AI Services
  aiFoundry: true
  openAiModels: false
  
  // Data Services  
  aiSearch: true
  cosmosDb: true
  keyVault: true
  storageAccount: true
  
  // Container Services
  containerAppsEnvironment: true
  containerApps: false
  
  // Observability
  applicationInsights: false
  
  // Networking & Security
  applicationGateway: false
  wafPolicy: false
  
  // DNS & Private Endpoints
  dnsVnetLinks: true
  privateEndpoints: true
}

// Model Configuration
@description('Array of OpenAI models to deploy')
param models array = [
  {
    name: 'gpt-4o'
    version: '2024-08-06'
    deploymentName: 'gpt-4o'
    capacity: 10
    sku: 'GlobalStandard'  // Pay-as-you-go pricing
  }
  {
    name: 'text-embedding-3-large'
    version: '1'
    deploymentName: 'text-embedding-3-large'
    capacity: 10
    sku: 'GlobalStandard'  // Pay-as-you-go pricing
  }
  {
    name: 'whisper'
    version: '001'
    deploymentName: 'whisper'
    capacity: 10
    sku: 'GlobalStandard'  // Pay-as-you-go pricing
  }
]

// Tags
@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  Project: baseName
  ManagedBy: 'Bicep'
  DeploymentDate: utcNow('yyyy-MM-dd')
}

// ============================================================================
// Variables
// ============================================================================

var hubVnetId = '/subscriptions/${hubSubscriptionId}/resourceGroups/${hubResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${hubVnetName}'
var spokeResourceGroupName = 'rg-${baseName}-${environment}'

// ============================================================================
// Resource Group
// ============================================================================

resource spokeResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: spokeResourceGroupName
  location: location
  tags: tags
}

// ============================================================================
// Networking Module - Spoke VNet
// ============================================================================

module networking 'modules/networking.bicep' = {
  name: 'deploy-networking-${environment}-${uniqueString(deployment().name)}'
  scope: spokeResourceGroup
  params: {
    location: location
    environment: environment
    tags: tags
    
    // VNet Configuration
    vnetAddressPrefix: vnetAddressPrefix
    hubVnetId: hubVnetId
    useRemoteGateways: useRemoteGateways
    
    // Subnet Prefixes
    agentSubnetPrefix: agentSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
    appGwSubnetPrefix: appGwSubnetPrefix
    apimSubnetPrefix: apimSubnetPrefix
    acaEnvSubnetPrefix: acaEnvSubnetPrefix
    devopsAgentsSubnetPrefix: devopsAgentsSubnetPrefix
    
    // Routing
    firewallPrivateIp: firewallPrivateIp
    enableDefaultRoute: enableDefaultRoute
  }
}

// ============================================================================
// Hub Peering Module
// ============================================================================

module hubPeering 'modules/hub-peering.bicep' = {
  name: 'deploy-hub-peering-${environment}-${uniqueString(deployment().name)}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    hubVnetName: hubVnetName
    spokeVnetId: networking.outputs.vnetId
    environment: environment
  }
}

// ============================================================================
// AI Foundry Module - Core AI Services
// ============================================================================

module aiFoundry 'modules/ai-foundry.bicep' = if (deployToggles.aiFoundry) {
  name: 'deploy-ai-foundry-${environment}-${uniqueString(deployment().name)}'
  scope: spokeResourceGroup
  params: {
    location: location
    environment: environment
    baseName: baseName
    tags: tags
    
    // Network configuration
    privateEndpointSubnetId: networking.outputs.subnetIds.peSubnetId
    agentSubnetId: networking.outputs.subnetIds.agentSubnetId

    // Private DNS configuration
    enablePrivateDns: deployToggles.privateEndpoints
    privateDnsZoneIds: {
      cognitiveServices: privateDnsZoneIds.cognitiveServices
      openai: privateDnsZoneIds.openai
      aiServices: privateDnsZoneIds.aiServices
      machineLearning: privateDnsZoneIds.machineLearning
      notebooks: privateDnsZoneIds.notebooks
    }
    
    // Model deployment configuration
    deployModels: deployToggles.openAiModels
    models: models
  }
}

// ============================================================================
// Data Services Module - Storage, Search, Cosmos DB, Key Vault
// ============================================================================

module dataServices 'modules/data-services.bicep' = if (deployToggles.aiSearch || deployToggles.cosmosDb || deployToggles.keyVault || deployToggles.storageAccount) {
  name: 'deploy-data-services-${environment}-${uniqueString(deployment().name)}'
  scope: spokeResourceGroup
  params: {
    location: location
    environment: environment
    baseName: baseName
    tags: tags
    
    // Network configuration
    privateEndpointSubnetId: networking.outputs.subnetIds.peSubnetId
    
    // Private DNS configuration
    enablePrivateDns: deployToggles.privateEndpoints
    privateDnsZoneIds: {
      search: privateDnsZoneIds.search
      cosmosDb: privateDnsZoneIds.cosmosDb
      keyVault: privateDnsZoneIds.keyVault
      storageBlob: privateDnsZoneIds.storageBlob
    }
  }
}

// ============================================================================
// Observability Module - Application Insights
// ============================================================================

module observability 'modules/observability.bicep' = if (deployToggles.applicationInsights) {
  name: 'deploy-observability-${environment}-${uniqueString(deployment().name)}'
  scope: spokeResourceGroup
  params: {
    location: location
    environment: environment
    baseName: baseName
    tags: tags
    
    // Existing Log Analytics Workspace
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    
    // Network configuration
    privateEndpointSubnetId: networking.outputs.subnetIds.peSubnetId
    
    // Private DNS configuration
    enablePrivateDns: true
    privateDnsZoneIds: {
      appInsights: privateDnsZoneIds.appInsights
    }
  }
}

// ============================================================================
// Container Apps Environment Module
// ============================================================================

module containerAppsEnvironment 'modules/container-apps-environment.bicep' = if (deployToggles.containerAppsEnvironment) {
  name: 'deploy-container-apps-env-${environment}-${uniqueString(deployment().name)}'
  scope: spokeResourceGroup
  params: {
    location: location
    environment: environment
    baseName: baseName
    tags: tags
    
    // Network configuration
    containerAppsSubnetId: networking.outputs.subnetIds.acaEnvSubnetId
    privateEndpointSubnetId: networking.outputs.subnetIds.peSubnetId
    
    // Log Analytics configuration
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    
    // Private DNS configuration
    enablePrivateDns: deployToggles.privateEndpoints
    privateDnsZoneIds: {
      containerApps: privateDnsZoneIds.containerApps
    }
  }
}

// ============================================================================
// DNS Virtual Network Links Module
// ============================================================================

module dnsVnetLinks 'modules/dns-vnet-links.bicep' = if (deployToggles.dnsVnetLinks) {
  name: 'deploy-dns-vnet-links-${environment}-${uniqueString(deployment().name)}'
  scope: resourceGroup(split(privateDnsZoneIds.cognitiveServices, '/')[2], split(privateDnsZoneIds.cognitiveServices, '/')[4])
  params: {
    location: 'global'
    environment: environment
    spokeVnetId: networking.outputs.vnetId
    privateDnsZoneIds: privateDnsZoneIds
    tags: tags
  }
}

// ============================================================================
// Outputs
// ============================================================================

output resourceGroupName string = spokeResourceGroup.name
output location string = location
output environment string = environment

// Networking Outputs
output vnetId string = networking.outputs.vnetId
output vnetName string = networking.outputs.vnetName
output vnetAddressSpace array = networking.outputs.vnetAddressSpace

output subnetIds object = networking.outputs.subnetIds
output subnetNames object = networking.outputs.subnetNames
output nsgIds object = networking.outputs.nsgIds
output routeTableIds object = networking.outputs.routeTableIds

// Peering Outputs
output spokePeeringName string = networking.outputs.peeringName
output spokePeeringState string = networking.outputs.peeringState
output hubPeeringName string = hubPeering.outputs.peeringName
output hubPeeringState string = hubPeering.outputs.peeringState

// Deployment Status
output deployedServices object = {
  networking: true
  aiFoundry: deployToggles.aiFoundry
  dataServices: (deployToggles.aiSearch || deployToggles.cosmosDb || deployToggles.keyVault || deployToggles.storageAccount)
  observability: deployToggles.applicationInsights
  dnsVnetLinks: deployToggles.dnsVnetLinks
}
