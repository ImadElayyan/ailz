// ============================================================================
// Hub VNet Peering to AI Landing Zone Spoke
// Deploy this in the Hub VNet resource group
// ============================================================================

@description('The name of the existing hub VNet')
param hubVnetName string

@description('The resource ID of the spoke VNet')
param spokeVnetId string

@description('Environment name (dev, test, prod)')
param environment string = 'dev'

// ============================================================================
// VNet Peering: Hub to Spoke
// ============================================================================

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: hubVnetName
}

resource peeringHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: hubVnet
  name: 'peer-hub-to-ai-spoke-${environment}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true // Set to true if hub has VPN/ExpressRoute gateway
    useRemoteGateways: false
  }
}

// ============================================================================
// Outputs
// ============================================================================

output peeringName string = peeringHubToSpoke.name
output peeringState string = peeringHubToSpoke.properties.peeringState
