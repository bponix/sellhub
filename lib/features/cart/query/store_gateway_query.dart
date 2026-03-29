const String FETCHSTOREGATEWAY = r'''
query ($siteId: Int!, $first: Int, $after: String, $before: String, $last: Int) {
  storeGateways(
    siteId: $siteId
    first: $first
    after: $after
    before: $before
    last: $last
  ) {
    total
    edges {
      cursor
      node {
        discount
        fee
        gatewayType
        id
        isActive
        isDiscount
        isFreeLogistics
        isManual
        isSandbox
        note
        priority
        title
        logo
        updatedAt
      }
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
  }
}
 ''';
