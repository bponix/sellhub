const String FETCHTOPBRAND = r'''
query ($siteId: [Int]!, $childId: Int, $isActive: Boolean, $isPrivate: Boolean, $search: String, $first: Int, $after: String) {
  storeBrands(
    siteId: $siteId
    isActive: $isActive
    isPrivate: $isPrivate
    search: $search
    first: $first
    after: $after
  ) {
    total
    edges {
      node {
        description
        hid
        id
        image(childId: $childId)
        isActive(childId: $childId)
        isPrivate
        priority
        siteId
        slug
        title
        translation
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
