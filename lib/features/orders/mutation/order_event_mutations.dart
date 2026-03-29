const String createCustomerOrderEventMutation = r'''
mutation (
  $userId: Int!
  $siteId: Int!
  $orderId: Int!
  $eventType: Int!
  $note: String!
) {
  selfStoreOrderEventCreateByCustomer(
    userId: $userId
    siteId: $siteId
    orderId: $orderId
    eventType: $eventType
    note: $note
  ) {
    id
    createdAt
    eventType
    note
    isPublic
    address
    location
  }
}
''';
