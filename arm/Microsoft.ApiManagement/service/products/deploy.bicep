@description('Required. The name of the of the API Management service.')
param apiManagementServiceName string

@description('Optional. Whether subscription approval is required. If false, new subscriptions will be approved automatically enabling developers to call the products APIs immediately after subscribing. If true, administrators must manually approve the subscription before the developer can any of the products APIs. Can be present only if subscriptionRequired property is present and has a value of false.')
param approvalRequired bool = false

@description('Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered')
param cuaId string = ''

@description('Optional. Product description. May include HTML formatting tags.')
param productDescription string = ''

@description('Optional. Array of Product APIs.')
param apis array = []

@description('Optional. Array of Product Groups.')
param groups array = []

@description('Required. Product Name.')
param name string

@description('Optional. whether product is published or not. Published products are discoverable by users of developer portal. Non published products are visible only to administrators. Default state of Product is notPublished. - notPublished or published')
param state string = 'published'

@description('Optional. Whether a product subscription is required for accessing APIs included in this product. If true, the product is referred to as "protected" and a valid subscription key is required for a request to an API included in the product to succeed. If false, the product is referred to as "open" and requests to an API included in the product can be made without a subscription key. If property is omitted when creating a new product it\'s value is assumed to be true.')
param subscriptionRequired bool = false

@description('Optional. Whether the number of subscriptions a user can have to this product at the same time. Set to null or omit to allow unlimited per user subscriptions. Can be present only if subscriptionRequired property is present and has a value of false.')
param subscriptionsLimit int = 1

@description('Optional. Product terms of use. Developers trying to subscribe to the product will be presented and required to accept these terms before they can complete the subscription process.')
param terms string = ''

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource service 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementServiceName
}

resource product 'Microsoft.ApiManagement/service/products@2021-08-01' = {
  name: name
  parent: service
  properties: {
    description: productDescription
    displayName: name
    terms: terms
    subscriptionRequired: subscriptionRequired
    approvalRequired: subscriptionRequired ? approvalRequired : null
    subscriptionsLimit: subscriptionRequired ? subscriptionsLimit : null
    state: state
  }
}

module api 'apis/deploy.bicep' = [for (api, index) in apis: {
  name: '${deployment().name}-Api-${index}'
  params: {
    apiManagementServiceName: apiManagementServiceName
    name: api.name
    productName: name
  }
}]

module group 'groups/deploy.bicep' = [for (group, index) in groups: {
  name: '${deployment().name}-Group-${index}'
  params: {
    apiManagementServiceName: apiManagementServiceName
    name: group.name
    productName: name
  }
}]

@description('The resource ID of the API management service product')
output productResourceId string = product.id

@description('The name of the API management service product')
output productName string = product.name

@description('The resource group the API management service product was deployed into')
output productResourceGroup string = resourceGroup().name

@description('The Resources IDs of the API management service product APIs')
output productApisResourceIds array = [for productApi in apis: resourceId('Microsoft.ApiManagement/service/products/apis', apiManagementServiceName, name, productApi.name)]

@description('The Resources IDs of the API management service product groups')
output productGroupsResourceIds array = [for productGroup in groups: resourceId('Microsoft.ApiManagement/service/products/groups', apiManagementServiceName, name, productGroup.name)]
