const String FETCH_STORE_PRODUCT_BY_ID = r'''
query ($id: Int!) {
  storeProduct(id: $id) {
    affiliateCommission
    brands
    cashback
    comparePrice
    currency
    deliveryCharge
    discount
    isExclusive
    features {
      key
      value
    }
    flashPrice
    hid
    id
    images {
      id
      image
    }
    isActive
    isContinueSelling
    isFlash
    isOneTime
    isNegotiable
    isVariant
    maxOrder
    maxResellPrice
    minResellPrice
    minOrder
    price
    productType
    quantity
    rating
    ratingTotal
    rewardPoints
    siteId
    sku
    slug
    thumbnail
    title
    translation
    unit
    unitType
    variants {
      comparePrice
      cost
      currency
      id
      imageIndex
      price
      priority
      quantity
      title
      variant {
        key
        value
      }
      weight
      wholesalePrice
    }
    vat
    weight
    wholesale {
      id
      maxOrder
      minOrder
      price
    }
    wholesalePrice
  }
}
''';
