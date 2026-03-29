const String FETCHSELFSTORECUSTOMER = r'''
query selfStoreCustomer($userId: Int!, $siteId: Int!, $isActive: Boolean, $isAffiliate: Boolean, $isReseller: Boolean, $isWholesale: Boolean, $customerType: Int, $customerTypes: [Int]) {
  selfStoreCustomer(
    userId: $userId
    siteId: $siteId
    isActive: $isActive
    isAffiliate: $isAffiliate
    isReseller: $isReseller
    isWholesale: $isWholesale
    customerType: $customerType
    customerTypes: $customerTypes
  ) {
    affiliatePaid
    affiliateProcessing
    affiliateTotal
    affiliatePayable
    address
    avatar
    billingAddress {
      address
      formattedAddress
      id
      latitude
      longitude
    }
    blockProducts
    createdAt
    currency
    customerType
    customerTypes
    cartProducts {
      id
      price
      quantity
      resellPrice
      title
      variant
      variantId
    }
    domain
    favorite
    formattedAddress
    id
    isActive
    isAffiliate
    isAffiliateCommission
    isAffiliateJoin
    isReseller
    isWholesale
    latitude
    longitude
    nid
    note
    ordersCancelled
    ordersConfirmed
    ordersDelivered
    ordersOnTheWay
    ordersPackaging
    ordersPending
    ordersPlaced
    ordersRejected
    ordersReturned
    ordersShipment
    ordersStation
    ordersTotal
    paymentNo
    paymentTitle
    pendingBalance
    pendingCashbackBalance
    pendingGiftCardBalance
    pendingProfit
    pendingPurchase
    pendingRewardPoints
    phone
    referCode
    referId
    resellPaid
    resellProcessing
    resellTotal
    resellPayable
    resellerCommissionPercentage
    tags
    shippingAddress {
      address
      formattedAddress
      id
      latitude
      longitude
    }
    siteId
    tags
    title
    totalBalance
    totalCashbackBalance
    totalGiftCardBalance
    totalPaid
    totalProfit
    totalPurchase
    totalReturnCharge
    totalRewardPoints
    updatedAt
    userId
  }
}
 ''';
