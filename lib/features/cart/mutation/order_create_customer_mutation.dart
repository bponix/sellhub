const String ORDER_CREATE_BY_CUSTOMER_MUTATION = r'''
mutation selfStoreOrderCreateByCustomer(
  $userId: Int!
  $siteId: Int!
  $customerId: Int!
  $address: String!
  $affiliateCommission: Float!
  $browser: String
  $cashbackBalance: Float!
  $charge: Float!
  $cost: Float!
  $currency: String!
  $customerAddress: String!
  $customerName: String!
  $customerNote: String
  $customerPhone: Int!
  $deliveryTime: String
  $discount: Float!
  $discountName: String
  $emiDuration: Int!
  $emiInterest: Float!
  $gatewayText: String!
  $grossAmount: Float!
  $image: Upload
  $isEmi: Boolean!
  $isRenew: Boolean
  $latitude: Float!
  $logisticsCharge: Float!
  $logisticsExtraCharge: Float!
  $logisticsId: Int!
  $logisticsStoppageId: Int
  $logisticsText: String!
  $logisticsUrl: String
  $longitude: Float!
  $netAmount: Float!
  $otp: Int!
  $paid: Float!
  $parentSiteId: Int
  $productId: Int
  $profit: Float!
  $referCode: String!
  $resellAmount: Float!
  $resellerAdvanceCollect: Float!
  $resellerCommission: Float!
  $resellerId: Int
  $rewardPoints: Float!
  $shopId: Int
  $source: String!
  $sourceId: Int
  $staffId: Int
  $subscription: String
  $subscriptionFee: Float
  $total: Float!
  $validTill: DateTime
  $vat: Float!
  $vatAmount: Float!
  $weight: Float!
  $products: [StoreOrderCartCreate!]
) {
  selfStoreOrderCreateByCustomer(
    userId: $userId
    siteId: $siteId
    customerId: $customerId
    data: {
      address: $address
      affiliateCommission: $affiliateCommission
      browser: $browser
      cashbackBalance: $cashbackBalance
      charge: $charge
      cost: $cost
      currency: $currency
      customerAddress: $customerAddress
      customerId: $customerId
      customerName: $customerName
      customerNote: $customerNote
      customerPhone: $customerPhone
      deliveryTime: $deliveryTime
      discount: $discount
      discountName: $discountName
      emiDuration: $emiDuration
      emiInterest: $emiInterest
      gatewayText: $gatewayText
      grossAmount: $grossAmount
      image: $image
      isEmi: $isEmi
      isRenew: $isRenew
      latitude: $latitude
      logisticsCharge: $logisticsCharge
      logisticsExtraCharge: $logisticsExtraCharge
      logisticsId: $logisticsId
      logisticsStoppageId: $logisticsStoppageId
      logisticsText: $logisticsText
      logisticsUrl: $logisticsUrl
      longitude: $longitude
      netAmount: $netAmount
      otp: $otp
      paid: $paid
      parentSiteId: $parentSiteId
      productId: $productId
      profit: $profit
      referCode: $referCode
      resellAmount: $resellAmount
      resellerAdvanceCollect: $resellerAdvanceCollect
      resellerCommission: $resellerCommission
      resellerId: $resellerId
      rewardPoints: $rewardPoints
      shopId: $shopId
      source: $source
      sourceId: $sourceId
      staffId: $staffId
      subscription: $subscription
      subscriptionFee: $subscriptionFee
      total: $total
      validTill: $validTill
      vat: $vat
      vatAmount: $vatAmount
      weight: $weight
    }
    products: $products
  ) {
    address
    customerAddress
    customerId
    customerName
    customerNote
    customerPhone
    currency
    gatewayText
    id
    isPaid
    logisticsCharge
    logisticsId
    logisticsText
    orderId
    paid
    source
    sourceId
    status
    total
    updatedAt
  }
}
''';
