const String STORE_VOUCHER_CHECK_BY_CODE = r'''
query (
  $siteId: Int!
  $code: String!
  $quantity: Float!
  $total: Float!
  $delivery: Float!
  $products: JSON!
) {
  storeVoucherCheckByCode(
    siteId: $siteId
    code: $code
    quantity: $quantity
    total: $total
    delivery: $delivery
    products: $products
  ) {
    discount
    message
  }
}
''';

const String SELF_STORE_VOUCHER_CHECK_BY_CODE = r'''
query (
  $siteId: Int!
  $userId: Int!
  $code: String!
  $quantity: Float!
  $total: Float!
  $delivery: Float!
  $products: JSON!
) {
  selfStoreVoucherCheckByCode(
    siteId: $siteId
    userId: $userId
    code: $code
    quantity: $quantity
    total: $total
    delivery: $delivery
    products: $products
  ) {
    discount
    message
  }
}
''';
