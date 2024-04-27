targetScope = 'resourceGroup'

@minLength(2)
param project string
param location string
param hostname string = ''

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: toLower('st${project}${location}')
  location: location
  tags: {'project-name': project, 'service-ame': 'storage'}
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}

  resource blobService 'blobServices@2022-09-01' = {
    name: 'default'
    resource staticContainer 'containers@2022-09-01' = {
      name: 'static'
    }
    resource uploadsContainer 'containers@2022-09-01' = {
      name: 'uploads'
    }
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-${project}-${location}'
  location: location
  tags: {'project-name': project, 'service-name': 'app-service-plan'}
  sku: {
    name: 'B1'
  }
  properties: {
    reserved: true
  }
  kind: 'linux'
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-${project}-${location}'
  location: location
  tags: {'project-name': project, 'service-name' : 'app'}
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'
      ftpsState: 'Disabled'
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }

  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      PROJECT_DOMAIN: hostname
      PROJECT_NAME: project
      ENABLE_ORYX_BUILD: 'true'
      STORAGE_CONNECTION_STRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
      SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
    }
  }

  resource logs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: {
        fileSystem: {
          level: 'Verbose'
        }
      }
      detailedErrorMessages: {
        enabled: true
      }
      failedRequestsTracing: {
        enabled: true
      }
      httpLogs: {
        fileSystem: {
          enabled: true
          retentionInDays: 1
          retentionInMb: 35
        }
      }
    }
  }

  resource customDomain 'hostnameBindings' = if (hostname != '' && !contains(hostname, 'example.com')) {
    name: hostname
    properties: {
      sslState: 'SniEnabled'
      thumbprint: appServiceCertificate.properties.thumbprint
    }
  }
}

resource appServiceCertificate 'Microsoft.Web/certificates@2022-09-01' = {
name: '${hostname}-${webApp.name}'
location: location
properties: {
  serverFarmId: appServicePlan.id
  canonicalName: hostname
}
}

output storageConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
