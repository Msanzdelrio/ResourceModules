@description('Optional. Determines whether tracing can be enabled.')
param allowTracing bool = true

@description('Required. The name of the of the API Management service.')
param apiManagementServiceName string

@description('Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered')
param cuaId string = ''

@description('Optional. User (user ID path) for whom subscription is being created in form /users/{userId}')
param ownerId string = ''

@description('Optional. Primary subscription key. If not specified during request key will be generated automatically.')
param primaryKey string = ''

@description('Optional. Scope type to choose between a product, "allAPIs" or a specific API. Scope like "/products/{productId}" or "/apis" or "/apis/{apiId}".')
param scope string = '/apis'

@description('Optional. Secondary subscription key. If not specified during request key will be generated automatically.')
param secondaryKey string = ''

@description('Optional. Initial subscription state. If no value is specified, subscription is created with Submitted state. Possible states are "*" active "?" the subscription is active, "*" suspended "?" the subscription is blocked, and the subscriber cannot call any APIs of the product, * submitted ? the subscription request has been made by the developer, but has not yet been approved or rejected, * rejected ? the subscription request has been denied by an administrator, * cancelled ? the subscription has been cancelled by the developer or administrator, * expired ? the subscription reached its expiration date and was deactivated. - suspended, active, expired, submitted, rejected, cancelled')
param state string = ''

@description('Required. Subscription name.')
param name string

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource service 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementServiceName
}

resource subscription 'Microsoft.ApiManagement/service/subscriptions@2021-08-01' = {
  name: name
  parent: service
  properties: {
    scope: scope
    displayName: name
    ownerId: !empty(ownerId) ? ownerId : null
    primaryKey: !empty(primaryKey) ? primaryKey : null
    secondaryKey: !empty(secondaryKey) ? secondaryKey : null
    state: !empty(state) ? state : null
    allowTracing: allowTracing
  }
}

@description('The resource ID of the API management service subscription')
output subscriptionResourceId string = subscription.id

@description('The name of the API management service subscription')
output subscriptionName string = subscription.name

@description('The resource group the API management service subscription was deployed into')
output subscriptionResourceGroup string = resourceGroup().name
