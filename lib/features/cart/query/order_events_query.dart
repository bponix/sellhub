const String FETCH_STORE_ORDER_EVENTS = r'''
query (
  $siteId: Int!
  $orderId: Int
  $isPublic: Boolean
  $first: Int
  $after: String
) {
  storeOrderEvents(
    siteId: $siteId
    orderId: $orderId
    isPublic: $isPublic
    first: $first
    after: $after
  ) {
    edges {
      node {
        id
        createdAt
        eventType
        note
        isPublic
        address
        location
      }
    }
  }
}
''';
