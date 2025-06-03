param frontDoorName string
param storageAccountName string
param privateLinkLocation string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource frontDoor 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: frontDoorName
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoor
  name: 'static-endpoint'
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoor
  name: 'originGroup1'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'privateBlob'
  properties: {
    hostName: '${storageAccountName}.blob.${environment().suffixes.storage}'
    originHostHeader: '${storageAccountName}.blob.${environment().suffixes.storage}'
    httpPort: 80
    httpsPort: 443
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {
      groupId: 'blob'
      privateLink: {
        id: storageAccount.id
      }
      privateLinkLocation: privateLinkLocation
      requestMessage: 'The request is from storage account ${storageAccountName}'
    }
  }
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: frontDoorEndpoint
  name: 'default-route'
  properties: {
    originGroup: {
      id: originGroup.id
    }
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'MatchRequest'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
    linkToDefaultDomain: 'Enabled'
    cacheConfiguration: {
      compressionSettings: {
        isCompressionEnabled: true
        contentTypesToCompress: ['application/javascript', 'text/css', 'text/html', 'text/plain']
      }
      queryStringCachingBehavior: 'IgnoreQueryString'
    }
  }
}

output url string = 'https://${frontDoorEndpoint.name}.azurefd.net/'
output endpoint_url string = frontDoorEndpoint.properties.hostName
