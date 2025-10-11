// ============================================================================
// container-apps-environment.bicep
// Container Apps Environment Module for AI Landing Zone
// ============================================================================

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, test, prod)')
param environment string

@description('Base name for resource naming')
param baseName string

@description('Tags to apply to all resources')
param tags object = {}

@description('Container Apps Environment subnet ID')
param containerAppsSubnetId string

@description('Existing Log Analytics Workspace resource ID')
param logAnalyticsWorkspaceResourceId string

@description('Private endpoint subnet ID')
param privateEndpointSubnetId string

@description('Enable private DNS zones')
param enablePrivateDns bool = true

@description('Private DNS zone resource IDs')
param privateDnsZoneIds object = {
  containerApps: ''
}

// ============================================================================
// Variables
// ============================================================================

var containerAppsEnvName = 'cae-${baseName}-${environment}'

// Parse the existing Log Analytics workspace resource ID
var lawIdSegments = split(logAnalyticsWorkspaceResourceId, '/')
var lawSubscriptionId = length(lawIdSegments) >= 3 ? lawIdSegments[2] : ''
var lawResourceGroupName = length(lawIdSegments) >= 5 ? lawIdSegments[4] : ''
var lawName = length(lawIdSegments) >= 1 ? last(lawIdSegments) : ''

// ============================================================================
// Reference to Existing Log Analytics Workspace
// ============================================================================

resource existingLogAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: lawName
  scope: resourceGroup(lawSubscriptionId, lawResourceGroupName)
}

// ============================================================================
// Container Apps Environment
// ============================================================================

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppsEnvName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: existingLogAnalytics.properties.customerId
        sharedKey: existingLogAnalytics.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
    vnetConfiguration: {
      infrastructureSubnetId: containerAppsSubnetId
      internal: true
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
      {
        name: 'Dedicated-D4'
        workloadProfileType: 'D4'
        minimumCount: 0
        maximumCount: 10
      }
      {
        name: 'Dedicated-E4'
        workloadProfileType: 'E4'
        minimumCount: 0
        maximumCount: 5
      }
    ]
  }
}

// ============================================================================
// Private Endpoint for Container Apps Environment (if enabled)
// ============================================================================

resource containerAppsPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateDns) {
  name: 'pe-${containerAppsEnvName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'containerapps-connection'
        properties: {
          privateLinkServiceId: containerAppsEnvironment.id
          groupIds: [
            'managedEnvironments'
          ]
        }
      }
    ]
  }
}

// ============================================================================
// Private DNS Zone Group (if private DNS is enabled)
// ============================================================================

resource containerAppsDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateDns && !empty(privateDnsZoneIds.containerApps)) {
  parent: containerAppsPrivateEndpoint
  name: 'containerapps-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-containerapps-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.containerApps
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Container Apps Environment resource ID')
output containerAppsEnvironmentId string = containerAppsEnvironment.id

@description('Container Apps Environment name')
output containerAppsEnvironmentName string = containerAppsEnvironment.name

@description('Container Apps Environment default domain')
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain

@description('Container Apps Environment static IP')
output staticIp string = containerAppsEnvironment.properties.staticIp

@description('Log Analytics Workspace Customer ID')
output logAnalyticsCustomerId string = existingLogAnalytics.properties.customerId

@description('Container Apps Environment FQDN')
output environmentFqdn string = 'https://${containerAppsEnvironment.properties.defaultDomain}'
