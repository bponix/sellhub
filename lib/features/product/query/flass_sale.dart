const String FETCHFLASHSALEQUERY = r'''
query ($siteId: [Int]!, $brandId: Int, $campaignId: Int, $categoryId: Int, $collectionId: Int, $isFeatured: Boolean, $isFlash: Boolean, $isNew: Boolean, $isPrivate: Boolean, $childId: Int, $childType: Int, $percentage: JSON, $isReseller: Boolean, $isBasePrice: Boolean, $queryType: String, $search: String, $subCategoryId: Int, $subSubCategoryId: Int, $shopId: Int, $stoppageId: Int, $productType: Int, $after: String, $first: Int, $offset: Int) {
  storeProducts(
    siteId: $siteId
    brandId: $brandId
    campaignId: $campaignId
    categoryId: $categoryId
    collectionId: $collectionId
    isActive: true
    isFeatured: $isFeatured
    isFlash: $isFlash
    isNew: $isNew
    isPrivate: $isPrivate
    queryType: $queryType
    search: $search
    subCategoryId: $subCategoryId
    subSubCategoryId: $subSubCategoryId
    shopId: $shopId
    stoppageId: $stoppageId
    productType: $productType
    after: $after
    first: $first
    offset: $offset
  ) {
    total
    edges {
      node {
        affiliateCommission(childId: $childId, childType: $childType)
        brands
        cashback(childId: $childId, childType: $childType)
        comparePrice(childId: $childId, childType: $childType)
        currency
        deliveryCharge(childId: $childId, childType: $childType)
        discount(childId: $childId, childType: $childType)
        isExclusive
        features {
          key
          value
        }
        flashPrice(
          childId: $childId
          childType: $childType
          percentage: $percentage
          isReseller: $isReseller
          isBasePrice: $isBasePrice
        )
        hid
        id
        images {
          id
          image
        }
        isActive(childId: $childId, childType: $childType)
        isContinueSelling(childId: $childId, childType: $childType)
        isFlash(childId: $childId, childType: $childType)
        isOneTime(childId: $childId, childType: $childType)
        isNegotiable(childId: $childId, childType: $childType)
        isVariant(childId: $childId, childType: $childType)
        maxOrder
        maxResellPrice
        minResellPrice
        minOrder
        price(
          childId: $childId
          childType: $childType
          percentage: $percentage
          isReseller: $isReseller
          isBasePrice: $isBasePrice
        )
        productType
        quantity(childId: $childId, childType: $childType)
        rating
        ratingTotal
        rewardPoints(childId: $childId, childType: $childType)
        siteId
        sku
        slug
        thumbnail
        title(childId: $childId, childType: $childType)
        translation(childId: $childId, childType: $childType)
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
        wholesalePrice(childId: $childId, percentage: $percentage)
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
