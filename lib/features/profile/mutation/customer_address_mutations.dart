const String ADD_STORE_CUSTOMER_BILLING_ADDRESS = r'''
mutation (
  $customerId: Int!
  $id: Int!
  $address: String!
  $formattedAddress: String!
  $latitude: Float!
  $longitude: Float!
) {
  storeCustomerAddBillingAddress(
    customerId: $customerId
    data: {
      id: $id
      address: $address
      formattedAddress: $formattedAddress
      latitude: $latitude
      longitude: $longitude
    }
  )
}
''';

const String REMOVE_STORE_CUSTOMER_BILLING_ADDRESS = r'''
mutation (
  $customerId: Int!
  $id: Int!
  $address: String!
  $formattedAddress: String!
  $latitude: Float!
  $longitude: Float!
) {
  storeCustomerRemoveBillingAddress(
    customerId: $customerId
    data: {
      id: $id
      address: $address
      formattedAddress: $formattedAddress
      latitude: $latitude
      longitude: $longitude
    }
  )
}
''';

const String ADD_STORE_CUSTOMER_SHIPPING_ADDRESS = r'''
mutation (
  $customerId: Int!
  $id: Int!
  $address: String!
  $formattedAddress: String!
  $latitude: Float!
  $longitude: Float!
) {
  storeCustomerAddShippingAddress(
    customerId: $customerId
    data: {
      id: $id
      address: $address
      formattedAddress: $formattedAddress
      latitude: $latitude
      longitude: $longitude
    }
  )
}
''';

const String REMOVE_STORE_CUSTOMER_SHIPPING_ADDRESS = r'''
mutation (
  $customerId: Int!
  $id: Int!
  $address: String!
  $formattedAddress: String!
  $latitude: Float!
  $longitude: Float!
) {
  storeCustomerRemoveShippingAddress(
    customerId: $customerId
    data: {
      id: $id
      address: $address
      formattedAddress: $formattedAddress
      latitude: $latitude
      longitude: $longitude
    }
  )
}
''';
