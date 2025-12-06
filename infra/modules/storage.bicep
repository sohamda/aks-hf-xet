@description('Name of the storage account')
param name string

@description('Location for the storage account')
param location string = resourceGroup().location

@description('Tags for the resources')
param tags object = {}

@description('Name of the file share for model storage')
param fileShareName string = 'models'

@description('File share quota in GB')
param fileShareQuota int = 100

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true  // CSI driver uses managed identity to retrieve storage key
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }

  // Nested file service
  resource fileService 'fileServices' = {
    name: 'default'
    
    // Nested file share
    resource share 'shares' = {
      name: fileShareName
      properties: {
        shareQuota: fileShareQuota
        enabledProtocols: 'SMB'
      }
    }
  }
}

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output fileShareName string = fileShareName
