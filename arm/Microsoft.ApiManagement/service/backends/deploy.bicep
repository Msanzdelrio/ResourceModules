@description('Required. The name of the of the API Management service.')
param apiManagementServiceName string

@description('Required. Backend Name.')
param name string

@description('Optional. Backend Credentials Contract Properties.')
param credentials object = {}

@description('Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered')
param cuaId string = ''

@description('Optional. Backend Description.')
param backendDescription string = ''

@description('Optional. Backend communication protocol. - http or soap')
param protocol string = 'http'

@description('Optional. Backend Proxy Contract Properties')
param proxy object = {}

@description('Optional. Management Uri of the Resource in External System. This URL can be the Arm Resource ID of Logic Apps, Function Apps or API Apps.')
param resourceId string = ''

@description('Optional. Backend Service Fabric Cluster Properties.')
param serviceFabricCluster object = {}

@description('Optional. Backend Title.')
param title string = ''

@description('Optional. Backend TLS Properties')
param tls object = {
  validateCertificateChain: false
  validateCertificateName: false
}

@description('Required. Runtime URL of the Backend.')
param url string

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource service 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementServiceName
}

resource backend 'Microsoft.ApiManagement/service/backends@2021-08-01' = {
  name: name
  parent: service
  properties: {
    title: !empty(title) ? title : null
    description: !empty(backendDescription) ? backendDescription : null
    resourceId: !empty(resourceId) ? resourceId : null
    properties: {
      serviceFabricCluster: !empty(serviceFabricCluster) ? serviceFabricCluster : null
    }
    credentials: !empty(credentials) ? credentials : null
    proxy: !empty(proxy) ? proxy : null
    tls: !empty(tls) ? tls : null
    url: url
    protocol: protocol
  }
}

@description('The resource ID of the API management service backend')
output backendResourceId string = backend.id

@description('The name of the API management service backend')
output backendName string = backend.name

@description('The resource group the API management service backend was deployed into')
output backendResourceGroup string = resourceGroup().name
