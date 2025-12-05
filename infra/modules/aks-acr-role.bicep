@description('Object ID of the AKS kubelet identity')
param aksKubeletIdentityObjectId string

@description('Name of the ACR')
param acrName string

// Reference existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// AcrPull role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Assign AcrPull role to AKS kubelet identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, aksKubeletIdentityObjectId, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    principalId: aksKubeletIdentityObjectId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}
