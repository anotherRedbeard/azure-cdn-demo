targetScope = 'subscription'

@description('The location for the resources.')
param location string 

@description('The name of the resource group.')
//test
param resourceGroupName string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module storage './storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    storageAccountName: 'cdnstatic${uniqueString(rg.id)}'
  }
}

module frontDoor './frontdoor.bicep' = {
  name: 'frontdoor'
  scope: rg
  params: {
    frontDoorName: 'cdn-${uniqueString(rg.id)}'
    storageAccountName: storage.outputs.storageAccountName
    privateLinkLocation: location
  }
}

output AZURE_RESOURCE_GROUP string = rg.name
output STORAGE_ACCOUNT_NAME string = storage.outputs.storageAccountName
output STATIC_ASSETS_CONTAINER_NAME string = storage.outputs.staticAssetsContainerName
output CDN_ENDPOINT string = frontDoor.outputs.url
output FRONT_DOOR_ENDPOINT_URL string = frontDoor.outputs.endpoint_url
