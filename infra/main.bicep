targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the AKS cluster')
param aksClusterName string = ''

@description('Kubernetes namespace for docling deployment')
param kubernetesNamespace string = 'docling'

@description('Node count for AKS cluster')
param nodeCount int = 2

@description('VM size for AKS nodes')
param vmSize string = 'Standard_DS3_v2'

@description('Name of the storage account')
param storageAccountName string = ''

@description('Name of the Azure Container Registry')
param acrName string = ''

@description('File share quota in GB')
param fileShareQuota int = 100

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName, 'SecurityControl': 'Ignore' }

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// Storage Account for model persistence
module storage './modules/storage.bicep' = {
  name: 'storage-deployment'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : 'st${resourceToken}'
    location: location
    tags: tags
    fileShareName: 'models'
    fileShareQuota: fileShareQuota
  }
}

// AKS Cluster
module aks './modules/aks.bicep' = {
  name: 'aks-deployment'
  scope: rg
  params: {
    name: !empty(aksClusterName) ? aksClusterName : '${abbrs.containerServiceManagedClusters}${resourceToken}'
    location: location
    tags: tags
    nodeCount: nodeCount
    vmSize: vmSize
    kubernetesNamespace: kubernetesNamespace
  }
}

// Azure Container Registry
module acr './modules/acr.bicep' = {
  name: 'acr-deployment'
  scope: rg
  params: {
    name: !empty(acrName) ? acrName : 'acr${resourceToken}'
    location: location
    tags: tags
    sku: 'Basic'
    adminUserEnabled: true
  }
}

// Role assignment: AKS to pull from ACR
module aksAcrRoleAssignment './modules/aks-acr-role.bicep' = {
  name: 'aks-acr-role-assignment'
  scope: rg
  params: {
    aksKubeletIdentityObjectId: aks.outputs.clusterKubeletIdentityObjectId
    acrName: acr.outputs.acrName
  }
}

output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name
output AKS_CLUSTER_NAME string = aks.outputs.clusterName
output AKS_CLUSTER_FQDN string = aks.outputs.clusterFqdn
output KUBERNETES_NAMESPACE string = kubernetesNamespace
output STORAGE_ACCOUNT_NAME string = storage.outputs.storageAccountName
output STORAGE_ACCOUNT_KEY string = storage.outputs.storageAccountKey
output FILE_SHARE_NAME string = storage.outputs.fileShareName
output ACR_NAME string = acr.outputs.acrName
output ACR_LOGIN_SERVER string = acr.outputs.acrLoginServer
