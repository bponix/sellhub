const String FETCHORDERHISTORY = r'''
query ($siteId: Int!, $search: String, $customerId: Int, $shopId: Int, $status: Int, $affiliateIsPaid: Boolean, $resellerIsPaid: Boolean, $referId: Int, $from: DateTime, $to: DateTime, $after: String, $first: Int) {
  storeOrders(
    siteId: $siteId
    search: $search
    customerId: $customerId
    shopId: $shopId
    status: $status
    affiliateIsPaid: $affiliateIsPaid
    resellerIsPaid: $resellerIsPaid
    referId: $referId
    from: $from
    to: $to
    first: $first
    after: $after
  ) {
    total
    edges {
      node {
        createdAt
        currency
        customerAddress
        customerName
        customerNote
        customerPhone
        id
        isSettle
        orderId
        paid
        profit
        resellAmount
        status
        total
        updatedAt
      }
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      endCursor
    }
  }
}
 ''';
