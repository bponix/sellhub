const String FETCHLOGISTICSMERCHANTS = r'''
query ($userId: Int, $search: String, $isActive: Boolean, $after: String, $first: Int) {
  logisticsMerchants(
    userId: $userId
    search: $search
    isActive: $isActive
    after: $after
    first: $first
  ) {
    total
    edges {
      node {
        balance
        chargeBase
        chargeMerchantDefined
        discount
        id
        note
        isActive
        logisticsAddress
        logisticsTitle
        companyId
        company {
          domain
          id
          logo
          street
          phone
        }
        title
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
