const String ADD_STORE_CUSTOMER_FAVORITE = r'''
mutation ($userId: Int!, $customerId: Int!, $productId: Int!) {
  selfStoreCustomerAddFavorite(
    userId: $userId
    customerId: $customerId
    productId: $productId
  )
}
''';

const String REMOVE_STORE_CUSTOMER_FAVORITE = r'''
mutation ($userId: Int!, $customerId: Int!, $productId: Int!) {
  selfStoreCustomerRemoveFavorite(
    userId: $userId
    customerId: $customerId
    productId: $productId
  )
}
''';
