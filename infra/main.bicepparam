// ============================================================================
// main.bicepparam
// AI Landing Zone - Main Deployment Parameters
// ============================================================================

using './main.bicep'

// ============================================================================
// Basic Configuration
// ============================================================================

// Location for all resources
param location = 'uaenorth'

// Environment (dev, test, prod)
param environment = 'dev'

// Project name for resource naming
param baseName = 'ai-landingzone'

// ============================================================================
// Network Configuration - Spoke VNet
// ============================================================================

// VNet address prefix for the spoke network
param vnetAddressPrefix = '172.16.0.0/16'

// Agent subnet for AI/ML agents and compute resources
param agentSubnetPrefix = '172.16.1.0/24'

// Private Endpoint subnet for secure service connections
param peSubnetPrefix = '172.16.2.0/24'

// Application Gateway subnet for web application firewall and load balancing
param appGwSubnetPrefix = '172.16.3.0/24'

// API Management subnet for API gateway services
param apimSubnetPrefix = '172.16.4.0/24'

// Container Apps Environment subnet for serverless containers
param acaEnvSubnetPrefix = '172.16.5.0/24'

// DevOps Agents subnet for build and deployment agents
param devopsAgentsSubnetPrefix = '172.16.6.0/24'

// ============================================================================
// Hub Network Configuration
// ============================================================================

// Hub subscription ID where the hub VNet resides
param hubSubscriptionId = '6a53819a-8f7f-4191-a477-43ce91269baa' // Replace with actual hub subscription ID

// Hub resource group name containing the hub VNet
param hubResourceGroupName = 'rg-elayyans-connect-uksouth-01' // Replace with actual hub resource group name

// Hub VNet name for peering
param hubVnetName = 'vnet-elayyans-hub-uksouth-001' // Correct hub VNet name

// ============================================================================
// Routing and Security Configuration
// ============================================================================

// Azure Firewall or NVA private IP address in hub for routing
param firewallPrivateIp = '10.10.1.68' // Replace with actual firewall IP

// Enable default route to firewall (recommended for security)
param enableDefaultRoute = true

// Use remote gateways in hub for VPN/ExpressRoute connectivity
param useRemoteGateways = true // Set to true if hub has VPN Gateway or ExpressRoute Gateway

// ============================================================================
// Private DNS Zone Configuration
// ============================================================================

// Existing Private DNS Zone IDs from different subscriptions
param privateDnsZoneIds = {
  // AI/Cognitive Services DNS Zones
  cognitiveServices: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.cognitiveservices.azure.com'
  openai: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com'
  aiServices: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.services.ai.azure.com'

  // Data Services DNS Zones (for future use)
  search: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.search.windows.net'
  cosmosDb: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.documents.azure.com'
  keyVault: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
  storageBlob: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
  appConfig: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.azconfig.io'
  containerApps: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.uaenorth.azurecontainerapps.io'
  containerRegistry: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io'

  // Machine Learning DNS Zones (for AI Hub and Project access)
  machineLearning: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms'
  notebooks: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net'

  // Observability DNS Zones
  appInsights: '/subscriptions/6a53819a-8f7f-4191-a477-43ce91269baa/resourceGroups/rg-elayyans-connect-dns-uksouth-001/providers/Microsoft.Network/privateDnsZones/privatelink.monitor.azure.com'
}

// ============================================================================
// Observability Configuration
// ============================================================================

// Existing Log Analytics Workspace resource ID from different subscription
param logAnalyticsWorkspaceResourceId = '/subscriptions/b01b834b-ecec-45bd-8335-745510262a40/resourceGroups/rg-elayyans-mgmt-logging-001/providers/Microsoft.OperationalInsights/workspaces/alz-elayyans-log-analytics'

// ============================================================================
// Deployment Toggles - Control Which Services to Deploy
// ============================================================================

param deployToggles = {
  // Core AI Services
  aiFoundry: true
  openAiModels: false // Enabled to deploy the configured models

  // Data Services  
  aiSearch: true
  cosmosDb: true
  keyVault: true
  storageAccount: true

  // Container Services
  containerAppsEnvironment: false
  containerApps: false

  // Observability
  applicationInsights: false // Set to true when feature is registered

  // Networking & Security
  applicationGateway: false
  wafPolicy: false

  // DNS & Private Endpoints
  dnsVnetLinks: true
  privateEndpoints: true
}

// ============================================================================
// AI Model Configuration - Array-based with Pay-as-you-go Pricing
// ============================================================================

// Array of OpenAI models to deploy with pay-as-you-go pricing
param models = [
  {
    name: 'gpt-4o'
    version: '2024-08-06'
    deploymentName: 'gpt-4o'
    capacity: 1
    sku: 'GlobalStandard' // Pay-as-you-go pricing
  }
  {
    name: 'text-embedding-3-large'
    version: '1'
    deploymentName: 'text-embedding-3-large'
    capacity: 1
    sku: 'Standard' // Pay-as-you-go pricing
  }
  {
    name: 'whisper'
    version: '001'
    deploymentName: 'whisper'
    capacity: 1
    sku: 'Standard' // Pay-as-you-go pricing
  }
  // Note: Whisper model removed as it's not available in UAE North region
  // Whisper is only available in West Europe with Standard SKU (regional deployment)
  // For speech-to-text in UAE North, consider using Azure AI Speech Service instead
]

// ============================================================================
// Resource Tags
// ============================================================================

// Tags to apply to all resources
param tags = {
  Environment: 'dev'
  Project: 'ai-landingzone'
  ManagedBy: 'Bicep'
  DeploymentDate: '2025-10-05'
  Owner: 'Platform Team' // Replace with actual owner
  CostCenter: 'IT-AI-001' // Replace with actual cost center
  BusinessUnit: 'AI/ML Platform' // Replace with actual business unit
}
