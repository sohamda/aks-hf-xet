@description('Name of the AKS cluster')
param name string

@description('Location for the AKS cluster')
param location string = resourceGroup().location

@description('Tags for the resources')
param tags object = {}

@description('Number of nodes in the default node pool')
param nodeCount int = 2

@description('VM size for nodes')
param vmSize string = 'Standard_DS3_v2'

@description('Kubernetes namespace for docling deployment')
param kubernetesNamespace string = 'docling'

@description('Kubernetes version - use empty string to let Azure select the default version')
param kubernetesVersion string = ''

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-01-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: '${name}-dns'
    // Only set kubernetesVersion if explicitly provided, otherwise use Azure default
    kubernetesVersion: !empty(kubernetesVersion) ? kubernetesVersion : null
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: nodeCount
        vmSize: vmSize
        osType: 'Linux'
        mode: 'System'
        osDiskSizeGB: 128
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }
    // Enable OIDC issuer and workload identity for managed identity authentication
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
  }
}

output clusterName string = aksCluster.name
output clusterFqdn string = aksCluster.properties.fqdn
output clusterIdentityPrincipalId string = aksCluster.identity.principalId
output clusterKubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId
output clusterKubeletIdentityClientId string = aksCluster.properties.identityProfile.kubeletidentity.clientId
