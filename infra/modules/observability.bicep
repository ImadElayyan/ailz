// ============================================================================
// observability.bicep
// Observability Module for AI Landing Zone
// ============================================================================

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, test, prod)')
param environment string

@description('Base name for resource naming')
param baseName string

@description('Tags to apply to all resources')
param tags object = {}

@description('Existing Log Analytics Workspace resource ID from different subscription')
param logAnalyticsWorkspaceResourceId string

@description('Private endpoint subnet ID')
param privateEndpointSubnetId string

@description('Enable private DNS zones')
param enablePrivateDns bool = true

@description('Private DNS zone resource IDs')
param privateDnsZoneIds object = {
  appInsights: ''
}

// ============================================================================
// Variables
// ============================================================================

var appInsightsName = 'appi-${baseName}-${environment}'

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
// Application Insights
// ============================================================================

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'CustomDeployment'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalyticsWorkspaceResourceId
    IngestionMode: 'LogAnalytics'
    // Disable public access for enterprise security
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
    DisableIpMasking: false
  }
}

// ============================================================================
// Private Endpoint for Application Insights (if enabled)
// ============================================================================

resource appInsightsPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateDns) {
  name: 'pe-${appInsightsName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'appinsights-connection'
        properties: {
          privateLinkServiceId: applicationInsights.id
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
  }
}

// ============================================================================
// Private DNS Zone Group (if private DNS is enabled)
// ============================================================================

resource appInsightsDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateDns && !empty(privateDnsZoneIds.appInsights)) {
  parent: appInsightsPrivateEndpoint
  name: 'appinsights-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-monitor-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.appInsights
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Application Insights resource ID')
output applicationInsightsId string = applicationInsights.id

@description('Application Insights name')
output applicationInsightsName string = applicationInsights.name

@description('Application Insights Instrumentation Key')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('Application Insights Connection String')
output connectionString string = applicationInsights.properties.ConnectionString

@description('Application Insights Application ID')
output applicationId string = applicationInsights.properties.AppId

@description('Referenced Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = existingLogAnalytics.id

@description('Referenced Log Analytics Workspace Name')
output logAnalyticsWorkspaceName string = existingLogAnalytics.name
