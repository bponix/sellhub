const String fetchSupplierTrustSummariesQuery = r'''
query FetchSupplierTrustSummaries($siteIds: [Int!]!, $days: Int) {
  storeSupplierTrustSummaries(siteIds: $siteIds, days: $days) {
    siteId
    score
    isVerified
    trustBand
    fulfillmentSuccessRate
    averageDeliveryDays
    returnRate
    shippedOrders30d
    paysResellersOnTime
    topCategories
    minimumIssueRate
    minimumIssueRateLabel
    note
  }
}
''';

const String fetchSupplierTrustSummaryQuery = r'''
query FetchSupplierTrustSummary($siteId: Int!, $days: Int) {
  storeSupplierTrustSummary(siteId: $siteId, days: $days) {
    siteId
    score
    isVerified
    trustBand
    fulfillmentSuccessRate
    averageDeliveryDays
    returnRate
    shippedOrders30d
    paysResellersOnTime
    topCategories
    minimumIssueRate
    minimumIssueRateLabel
    note
  }
}
''';
