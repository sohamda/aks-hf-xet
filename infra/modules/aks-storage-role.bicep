@description('Object ID of the AKS kubelet identity')
param aksKubeletIdentityObjectId string

@description('Name of the storage account')
param storageAccountName string

// Reference existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// Storage File Data SMB Share Contributor role - required for Azure Files access via managed identity
// Role ID: 0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb
resource storageFileDataSmbShareContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aksKubeletIdentityObjectId, 'Storage-File-Data-SMB-Share-Contributor')
  scope: storageAccount
  properties: {
    principalId: aksKubeletIdentityObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb')
  }
}

// Storage Account Contributor role - required for CSI driver to access storage account metadata
// Role ID: 17d1049b-9a84-46fb-8f53-869881c3d3ab
resource storageAccountContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aksKubeletIdentityObjectId, 'Storage-Account-Contributor')
  scope: storageAccount
  properties: {
    principalId: aksKubeletIdentityObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '17d1049b-9a84-46fb-8f53-869881c3d3ab')
  }
}
