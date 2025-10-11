// ============================================================================
// Module: networking.bicep
// AI Landing Zone - Virtual Network Infrastructure Module
// ============================================================================

// Parameters - Location and Environment
@description('The location for all resources')
param location string

@description('Environment name (dev, test, prod)')
param environment string

@description('Tags to apply to all resources')
param tags object = {}

// Parameters - VNet Configuration
@description('VNet address prefix')
param vnetAddressPrefix string

@description('Custom VNet name (optional - if empty, uses default naming pattern)')
param vnetName string = ''

@description('Hub VNet Resource ID for peering')
param hubVnetId string

@description('Use remote gateways in hub')
param useRemoteGateways bool = false

// Parameters - Subnet Address Prefixes
@description('Agent subnet address prefix')
param agentSubnetPrefix string

@description('Private Endpoint subnet address prefix')
param peSubnetPrefix string

@description('Application Gateway subnet address prefix')
param appGwSubnetPrefix string

@description('API Management subnet address prefix')
param apimSubnetPrefix string

@description('Container Apps Environment subnet address prefix')
param acaEnvSubnetPrefix string

@description('DevOps Agents subnet address prefix')
param devopsAgentsSubnetPrefix string

// Parameters - Routing
@description('Firewall/NVA IP address for default routing')
param firewallPrivateIp string

@description('Enable default route to firewall')
param enableDefaultRoute bool = true

// ============================================================================
// Network Security Groups
// ============================================================================

// NSG for Agent Subnet
resource nsgAgent 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-agent-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          description: 'Allow HTTPS from VNet'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

// NSG for Private Endpoint Subnet
resource nsgPe 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-pe-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowVNetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          description: 'Allow all VNet traffic'
        }
      }
    ]
  }
}

// NSG for Application Gateway Subnet
resource nsgAppGw 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-appgw-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowGatewayManager'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          description: 'Allow Gateway Manager'
        }
      }
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          description: 'Allow Azure Load Balancer'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          description: 'Allow HTTPS from Internet'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          priority: 130
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          description: 'Allow HTTP from Internet'
        }
      }
    ]
  }
}

// NSG for API Management Subnet
resource nsgApim 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-apim-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowAPIMManagement'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          description: 'APIM Management Endpoint'
        }
      }
      {
        name: 'AllowHTTPSInbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          description: 'Allow HTTPS'
        }
      }
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '6390'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          description: 'Azure Infrastructure Load Balancer'
        }
      }
    ]
  }
}

// NSG for Container Apps Environment Subnet
resource nsgAcaEnv 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-acaenv-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          description: 'Allow HTTPS from VNet'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          description: 'Allow HTTP from VNet'
        }
      }
    ]
  }
}

// NSG for DevOps Agents Subnet
resource nsgDevOps 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-devops-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          description: 'Allow HTTPS to Internet'
        }
      }
      {
        name: 'AllowVNetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          description: 'Allow VNet traffic'
        }
      }
    ]
  }
}

// ============================================================================
// Route Table (Shared)
// ============================================================================

resource routeTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-shared-${environment}'
  location: location
  tags: tags
  properties: {
    routes: enableDefaultRoute ? [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ] : []
    disableBgpRoutePropagation: false
  }
}

// ============================================================================
// Virtual Network
// ============================================================================

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: !empty(vnetName) ? vnetName : 'vnet-ai-spoke-${environment}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'agent-subnet'
        properties: {
          addressPrefix: agentSubnetPrefix
          networkSecurityGroup: {
            id: nsgAgent.id
          }
          routeTable: {
            id: routeTable.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.CognitiveServices'
              locations: [
                location
              ]
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'pe-subnet'
        properties: {
          addressPrefix: peSubnetPrefix
          networkSecurityGroup: {
            id: nsgPe.id
          }
          routeTable: {
            id: routeTable.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'appgw-subnet'
        properties: {
          addressPrefix: appGwSubnetPrefix
          networkSecurityGroup: {
            id: nsgAppGw.id
          }
          routeTable: {
            id: routeTable.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'apim-subnet'
        properties: {
          addressPrefix: apimSubnetPrefix
          networkSecurityGroup: {
            id: nsgApim.id
          }
          routeTable: {
            id: routeTable.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'aca-env-subnet'
        properties: {
          addressPrefix: acaEnvSubnetPrefix
          networkSecurityGroup: {
            id: nsgAcaEnv.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'devops-agents-subnet'
        properties: {
          addressPrefix: devopsAgentsSubnetPrefix
          networkSecurityGroup: {
            id: nsgDevOps.id
          }
          routeTable: {
            id: routeTable.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// ============================================================================
// VNet Peering: Spoke to Hub
// ============================================================================

resource peeringSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: vnet
  name: 'peer-spoke-to-hub-${environment}'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: useRemoteGateways
  }
}

// ============================================================================
// Outputs
// ============================================================================

output vnetId string = vnet.id
output vnetName string = vnet.name
output vnetAddressSpace array = vnet.properties.addressSpace.addressPrefixes

output subnetIds object = {
  agentSubnetId: vnet.properties.subnets[0].id
  peSubnetId: vnet.properties.subnets[1].id
  appgwSubnetId: vnet.properties.subnets[2].id
  apimSubnetId: vnet.properties.subnets[3].id
  acaEnvSubnetId: vnet.properties.subnets[4].id
  devopsAgentsSubnetId: vnet.properties.subnets[5].id
}

output subnetNames object = {
  agentSubnetName: vnet.properties.subnets[0].name
  peSubnetName: vnet.properties.subnets[1].name
  appgwSubnetName: vnet.properties.subnets[2].name
  apimSubnetName: vnet.properties.subnets[3].name
  acaEnvSubnetName: vnet.properties.subnets[4].name
  devopsAgentsSubnetName: vnet.properties.subnets[5].name
}

output nsgIds object = {
  agentNsgId: nsgAgent.id
  peNsgId: nsgPe.id
  appgwNsgId: nsgAppGw.id
  apimNsgId: nsgApim.id
  acaEnvNsgId: nsgAcaEnv.id
  devopsNsgId: nsgDevOps.id
}

output routeTableIds object = {
  sharedRouteTableId: routeTable.id
}

output peeringName string = peeringSpokeToHub.name
output peeringState string = peeringSpokeToHub.properties.peeringState
