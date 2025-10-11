# Azure AI Landing Zone - MOJAILZ

A comprehensive, enterprise-ready Azure AI Landing Zone built with Bicep that provides secure, private, and scalable infrastructure for AI workloads with granular deployment control.

## 🏗️ Architecture Overview

This solution deploys a complete AI Landing Zone with:

- **Networking**: Hub-spoke architecture with private connectivity and subnet delegation
- **AI Services**: Azure OpenAI with latest models (GPT-4o, Text-Embedding-3-Large, Whisper), Cognitive Services, AI Hub, and AI Projects
- **Data Services**: Azure AI Search, Cosmos DB, Key Vault, Storage Account
- **Container Platform**: Azure Container Apps Environment with workload profiles for serverless AI workloads
- **Observability**: Application Insights with centralized logging and monitoring (optional)
- **Security**: Private endpoints, network isolation, and cross-subscription DNS integration
- **Deployment Control**: Granular toggles for each service component and selective deployment scenarios

## 🎛️ Deployment Toggles

The solution includes comprehensive deployment toggles allowing you to selectively deploy services:

```bicep
param deployToggles = {
  // Core AI Services
  aiFoundry: true           // Azure AI Services, OpenAI, Hub, Project
  openAiModels: false       // OpenAI model deployments (requires quota)
  
  // Data Services  
  aiSearch: true            // Azure AI Search
  cosmosDb: true            // Cosmos DB with SQL API
  keyVault: true            // Key Vault with RBAC
  storageAccount: true      // Storage Account with blob containers
  
  // Container Services
  containerAppsEnvironment: true   // Container Apps Environment with workload profiles
  containerApps: false            // Individual Container Apps (future capability)
  
  // Observability
  applicationInsights: false      // Application Insights (requires feature registration)
  
  // Networking & Security
  applicationGateway: false       // Application Gateway v2
  wafPolicy: false               // Web Application Firewall Policy
  
  // DNS & Private Endpoints
  dnsVnetLinks: true             // DNS Virtual Network Links
  privateEndpoints: true        // Private Endpoints for all services
}
```

## 📋 Prerequisites

### 1. Required Tools

Install the following tools on your development machine:

#### Azure Developer CLI (azd)
```powershell
# Install Azure Developer CLI
winget install microsoft.azd
# OR
powershell -ex bypass -c "irm https://aka.ms/install-azd.ps1 | iex"
```

#### Azure CLI
```powershell
# Install Azure CLI
winget install microsoft.azurecli
# OR download from: https://aka.ms/installazurecliwindows
```

#### PowerShell 7+ (Recommended)
```powershell
# Install PowerShell 7
winget install microsoft.powershell
```

### 2. Azure Prerequisites

#### Required Subscriptions Access
- **AI Landing Zone Subscription**: Where AI services will be deployed
- **Hub Network Subscription**: Where hub VNet and DNS zones exist
- **Log Analytics Subscription**: Where centralized logging workspace exists

#### Required Permissions
- **Contributor** or **Owner** role on the AI Landing Zone subscription
- **Network Contributor** role on the hub network subscription
- **Reader** role on the Log Analytics workspace subscription

#### Required Azure Features
Register the following features in your AI Landing Zone subscription:

```powershell
# Login to Azure
az login

# Set the subscription context
az account set --subscription "YOUR-AI-LANDING-ZONE-SUBSCRIPTION-ID"

# Register required features for private endpoints
az feature register --namespace Microsoft.Network --name AllowPrivateEndpoints
az feature register --namespace Microsoft.CognitiveServices --name EnablePrivateEndpoints

# Register resource providers
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.MachineLearningServices
az provider register --namespace Microsoft.Search
az provider register --namespace Microsoft.DocumentDB
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.App

# Check feature registration status (can take 30-60 minutes)
az feature show --namespace Microsoft.Network --name AllowPrivateEndpoints
az feature show --namespace Microsoft.CognitiveServices --name EnablePrivateEndpoints

# Verify providers are registered
az provider show --namespace Microsoft.App --query "registrationState"
```

### 3. Existing Infrastructure Requirements

Before deploying, ensure you have:

#### Hub Virtual Network
- Existing hub VNet with Azure Firewall or NVA
- Hub-spoke peering capabilities
- Note the hub VNet resource details

#### Private DNS Zones
Required private DNS zones in your DNS subscription:
- `privatelink.cognitiveservices.azure.com` - For Azure AI Services
- `privatelink.openai.azure.com` - For Azure OpenAI
- `privatelink.services.ai.azure.com` - For AI Foundry services
- `privatelink.api.azureml.ms` - For Azure Machine Learning Hub/Project
- `privatelink.notebooks.azure.net` - For ML Notebooks (optional)
- `privatelink.search.windows.net` - For Azure AI Search
- `privatelink.documents.azure.com` - For Cosmos DB
- `privatelink.vaultcore.azure.net` - For Key Vault
- `privatelink.blob.core.windows.net` - For Storage Account (blob)
- `privatelink.monitor.azure.com` - For Application Insights (optional)
- `privatelink.[region].azurecontainerapps.io` - For Container Apps (e.g., `privatelink.uaenorth.azurecontainerapps.io`)

#### Log Analytics Workspace
- Existing Log Analytics workspace for centralized logging
- Note the workspace resource ID

## 🔧 Configuration

### 1. Clone the Repository

```powershell
git clone <repository-url>
cd "Landing Zone/MOJAILZ"
```

### 2. Update Parameters File

Edit `infra/main.bicepparam` and update the following values:

#### Basic Configuration
```bicep
// Update these basic settings
param location = 'uaenorth'  // Your preferred Azure region
param environment = 'dev'    // Environment: dev, test, prod
param baseName = 'ai-landingzone'  // Your project name
```

#### Network Configuration
```bicep
// Update these network settings
param vnetAddressPrefix = '172.16.0.0/16'  // Your spoke VNet CIDR
param hubSubscriptionId = 'YOUR-HUB-SUBSCRIPTION-ID'
param hubResourceGroupName = 'YOUR-HUB-RESOURCE-GROUP'
param hubVnetName = 'YOUR-HUB-VNET-NAME'
param firewallPrivateIp = 'YOUR-FIREWALL-IP'  // e.g., '10.10.1.68'
```

#### Private DNS Zone IDs
Update all DNS zone resource IDs with your actual values:
```bicep
param privateDnsZoneIds = {
  cognitiveServices: '/subscriptions/YOUR-DNS-SUB/resourceGroups/YOUR-DNS-RG/providers/Microsoft.Network/privateDnsZones/privatelink.cognitiveservices.azure.com'
  openai: '/subscriptions/YOUR-DNS-SUB/resourceGroups/YOUR-DNS-RG/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com'
  // ... update all other DNS zones
}
```

#### Log Analytics Workspace
```bicep
param logAnalyticsWorkspaceResourceId = '/subscriptions/YOUR-LAW-SUB/resourceGroups/YOUR-LAW-RG/providers/Microsoft.OperationalInsights/workspaces/YOUR-LAW-NAME'
```

#### Resource Tags
```bicep
param tags = {
  Environment: 'dev'
  Project: 'ai-landingzone'
  Owner: 'YOUR-TEAM-NAME'
  CostCenter: 'YOUR-COST-CENTER'
  BusinessUnit: 'YOUR-BUSINESS-UNIT'
}
```

### 3. AI Model Configuration

Configure OpenAI model deployments based on your quota availability:
```bicep
// Set to false initially to avoid quota issues, enable after quota verification
param deployToggles = {
  openAiModels: false       // Start with false, enable after confirming quota
  // ... other toggles
}

// Available models in the deployment (when enabled)
// - gpt-4o (latest GPT-4 model, requires premium quota, 10K TPM)
// - text-embedding-3-large (enhanced embeddings, 10K TPM)  
// - whisper (speech-to-text, 10K TPM)
```

**Note**: These are premium models that require quota approval. GPT-4o provides the most advanced language capabilities, Text-Embedding-3-Large offers superior vector search performance, and Whisper enables speech-to-text processing.
param deployModels = false

// Configure models when ready
param gptModel = {
  name: 'gpt-35-turbo'  // Use available model
  version: '0613'
  deploymentName: 'gpt-35-turbo'
  capacity: 10
}
```

## 🚀 Deployment

### 1. Login and Set Context

```powershell
# Login to Azure
az login

# Set the target subscription
az account set --subscription "YOUR-AI-LANDING-ZONE-SUBSCRIPTION-ID"

# Verify login and subscription
az account show
```

### 2. Initialize Azure Developer CLI

```powershell
# Navigate to the project directory
cd "c:\Work\Source\Landing Zone\MOJAILZ"

# Initialize azd (first time only)
azd auth login
azd init
```

### 3. Deploy the Infrastructure

#### Option A: Using Azure Developer CLI (Recommended)
```powershell
# Deploy all infrastructure with azd
azd provision

# View deployment progress
azd show
```

#### Option B: Using Azure CLI
```powershell
# Deploy with Azure CLI
az deployment sub create \
  --name "ai-landingzone-deployment" \
  --location "uaenorth" \
  --template-file "infra/main.bicep" \
  --parameters "infra/main.bicepparam"
```

#### Option C: Incremental Deployment with Toggles
```powershell
# Deploy only core services first
az deployment sub create \
  --name "ai-landingzone-core" \
  --location "uaenorth" \
  --template-file "infra/main.bicep" \
  --parameters "infra/main.bicepparam" \
  --parameters deployToggles='{"aiFoundry":true,"aiSearch":true,"keyVault":true,"storageAccount":true,"cosmosDb":false,"containerAppsEnvironment":false,"openAiModels":false,"applicationInsights":false}'

# Then deploy additional services as needed
```

### 4. Validate Deployment

```powershell
# Check deployment status
az deployment sub show --name "ai-landingzone-deployment"

# List created resources
az resource list --resource-group "rg-ai-landingzone-dev" --output table

# Check specific service endpoints
az cognitiveservices account show --name "ais-ai-landingzone-dev" --resource-group "rg-ai-landingzone-dev" --query "properties.endpoint"
az search service show --name "srch-ai-landingzone-dev" --resource-group "rg-ai-landingzone-dev" --query "hostName"
```

## 📊 Post-Deployment Steps

### 1. Verify Private Connectivity

1. **Test DNS Resolution**: From a VM in the spoke VNet, verify private DNS resolution:
   ```powershell
   # Test OpenAI endpoint
   nslookup oai-ai-landingzone-dev.openai.azure.com
   
   # Test AI Services endpoint  
   nslookup ais-ai-landingzone-dev.cognitiveservices.azure.com
   
   # Test AI Search endpoint
   nslookup srch-ai-landingzone-dev.search.windows.net
   
   # Test Container Apps Environment
   nslookup cae-ai-landingzone-dev.uaenorth.azurecontainerapps.io
   ```

2. **Access Azure AI Studio**: Navigate to https://ai.azure.com and verify access to your AI Hub and Project

3. **Test Container Apps Environment**: Verify the environment is ready for workload deployment

### 2. Enable OpenAI Models (Optional)

Once you have quota approval:
```bicep
# Update main.bicepparam
param deployToggles = {
  // ... other settings
  openAiModels: true    // Enable model deployments
}
```

Then redeploy to add the models:
```powershell
azd provision
```

**Available Models**:
- `gpt-4o`: Latest GPT-4 model with enhanced capabilities (10K TPM, requires premium quota)
- `text-embedding-3-large`: Advanced embeddings for superior vector search (10K TPM)
- `whisper`: Speech-to-text processing for audio content (10K TPM)

### 3. Configure Application Access

1. **Set up RBAC**: Assign appropriate roles to users/applications:
   ```powershell
   # Assign AI Developer role to users
   az role assignment create \
     --role "Cognitive Services OpenAI User" \
     --assignee "user@domain.com" \
     --scope "/subscriptions/YOUR-SUB-ID/resourceGroups/rg-ai-landingzone-dev"
   ```

2. **Configure Container Apps**: Deploy your applications to the Container Apps Environment

3. **Test Data Services**: Verify access to Search, Cosmos DB, and Storage from your applications

## 🔍 Troubleshooting

### Common Issues

#### 1. Feature Registration Pending
```powershell
# Check feature status
az feature show --namespace Microsoft.Network --name AllowPrivateEndpoints

# Wait for registration to complete (can take 30-60 minutes)
```

#### 2. DNS Resolution Issues
- Verify VNet links exist in private DNS zones
- Check NSG rules allow DNS traffic
- Validate DNS forwarders in hub

#### 3. OpenAI Model Quota Issues
- Request quota increase in Azure portal
- Use alternative models (gpt-35-turbo instead of gpt-4)
- Deploy models later after quota approval

#### 4. Private Endpoint Connection Issues
- Verify subnet delegation and service endpoints configuration
- Check NSG rules allow private endpoint traffic (port 443)
- Validate DNS zone configuration and VNet links
- Ensure private endpoint subnet has sufficient IP addresses

#### 5. Container Apps Environment Issues
- Verify subnet delegation for Microsoft.App/environments
- Check workload profiles are properly configured
- Validate Log Analytics workspace connectivity

### Useful Commands

```powershell
# Check deployment logs with verbose output
azd provision --debug

# View resource group contents with details
az resource list --resource-group "rg-ai-landingzone-dev" --output table

# Test network connectivity to specific services
az network vnet check-ip-address \
  --resource-group "rg-ai-landingzone-dev" \
  --name "vnet-ai-spoke-dev" \
  --ip-address "172.16.1.4"

# Check DNS zones and VNet links
az network private-dns zone list --resource-group "YOUR-DNS-RG" --output table
az network private-dns link vnet list --zone-name "privatelink.openai.azure.com" --resource-group "YOUR-DNS-RG"

# Verify Container Apps Environment status
az containerapp env show --name "cae-ai-landingzone-dev" --resource-group "rg-ai-landingzone-dev"

# Check private endpoint status
az network private-endpoint list --resource-group "rg-ai-landingzone-dev" --output table
```

## 📁 Project Structure

```
MOJAILZ/
├── infra/
│   ├── main.bicep                 # Main deployment template
│   ├── main.bicepparam            # Parameters file
│   └── modules/
│       ├── networking.bicep       # VNet, subnets, NSGs
│       ├── ai-foundry.bicep       # AI services
│       ├── data-services.bicep    # Storage, Search, Cosmos
│       ├── observability.bicep    # App Insights
│       └── dns-vnet-links.bicep   # DNS integration
├── azure.yaml                     # Azure Developer CLI config
└── README.md                      # This file
```

## 🏷️ Deployed Resources

After successful deployment, you'll have:

### Networking
- **Virtual Network**: Hub-spoke architecture with 6 specialized subnets
- **Network Security Groups**: Subnet-level security with AI service rules
- **Route Tables**: Traffic routing through central firewall
- **Hub-Spoke Peering**: Integration with existing hub infrastructure
- **Private Endpoints**: Secure connectivity for all AI and data services

### AI Services
- **Azure OpenAI**: Account configured for model deployments (quota dependent)
- **Azure AI Services**: Unified cognitive services hub
- **AI Hub Workspace**: MLOps platform for model management
- **AI Project Workspace**: Development environment for AI solutions

### Data Services
- **Azure AI Search**: Vector and semantic search capabilities (Standard tier)
- **Cosmos DB**: Document database with AI vectorization support
- **Key Vault**: Centralized secrets management with RBAC
- **Storage Account**: Blob storage for AI artifacts and data

### Container Platform
- **Container Apps Environment**: Serverless platform with workload profiles
  - D4 Consumption profile for variable workloads
  - D4 General Purpose profile for consistent workloads
  - Internal load balancer with VNet integration
  - Auto-scaling capabilities

### Observability (Optional)
- **Application Insights**: Connected to existing Log Analytics workspace
- **Centralized Logging**: Unified monitoring across all services

### Security & Compliance
- **Network Isolation**: All services private endpoint enabled
- **Cross-Subscription DNS**: Integration with existing private DNS zones
- **RBAC**: Role-based access control across all services
- **Enterprise Security**: Zero-trust network architecture
- Zero public access points

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Azure documentation
3. Open an issue in the repository
4. Contact your platform team

---

**Note**: This AI Landing Zone follows Azure Well-Architected Framework principles and enterprise security best practices. Ensure you understand the security implications and have proper governance in place before deploying to production.
