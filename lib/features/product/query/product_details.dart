const String FETCHPRODUCTDETAILS = r'''
query ($hid: String!, $childId: Int, $childType: Int, $percentage: JSON, $isReseller: Boolean, $isBasePrice: Boolean) {
  storeProductByHid(hid: $hid) {
    affiliateCommission(childId: $childId, childType: $childType)
    affiliateCommissionPercentage(childId: $childId, childType: $childType)
    authors
    barcode
    brands
    campaigns
    cashback(childId: $childId, childType: $childType)
    categories
    childProducts {
      flashPrice
      cost
      price
      quantity
      siteId
      siteType
      sold
    }
    collections
    comparePrice(childId: $childId, childType: $childType)
    cost(childId: $childId, childType: $childType, isReseller: $isReseller)
    createdAt
    currency
    deliveryCharge(childId: $childId, childType: $childType)
    deliveryTime(childId: $childId, childType: $childType)
    description(childId: $childId, childType: $childType)
    discount(childId: $childId, childType: $childType)
    emiDuration(childId: $childId, childType: $childType)
    emiInterest(childId: $childId, childType: $childType)
    emiPrice(childId: $childId, childType: $childType)
    extraImages {
      id
      image
    }
    faq {
      id
      key
      value
    }
    features {
      id
      key
      value
    }
    file
    fileType
    flashPrice(
      childId: $childId
      childType: $childType
      percentage: $percentage
      isReseller: $isReseller
      isBasePrice: $isBasePrice
    )
    html
    id
    hid
    image
    images {
      id
      image
    }
    isActive
    isCod
    isContinueSelling
    isEmi
    isExclusive
    isFeatured
    isFlash
    isNegotiable
    isNew
    isOneTime
    isPrivate
    isResell
    isTrack
    isVariant
    isWarranty
    keyword
    maxOrder
    maxResellPrice
    minResellPrice
    metaDescription(childId: $childId, childType: $childType)
    metaTitle(childId: $childId, childType: $childType)
    minOrder
    note {
      genre
      id
      image
      isFree
      title
      url
    }
    parentId
    price(
      childId: $childId
      childType: $childType
      percentage: $percentage
      isReseller: $isReseller
      isBasePrice: $isBasePrice
    )
    priority
    productType
    quantity(childId: $childId, childType: $childType)
    requirements {
      id
      key
      value
    }
    rewardPoints(childId: $childId, childType: $childType)
    salePrice(childId: $childId, childType: $childType)
    siteId
    sku
    slug
    sold(childId: $childId, childType: $childType)
    source
    stoppages
    subCategories
    subSubCategories
    tags
    thumbnail
    title(childId: $childId, childType: $childType)
    translation(childId: $childId, childType: $childType)
    unit
    unitType
    updatedAt
    validFor(childId: $childId, childType: $childType)
    vat(childId: $childId, childType: $childType)
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
    vouchers
    warranty
    weight
    wholesale {
      id
      maxOrder
      minOrder
      price
    }
    wholesalePrice(childId: $childId, percentage: $percentage)
    wholesalePricePercentage(childId: $childId, percentage: $percentage)
  }
}
 ''';
