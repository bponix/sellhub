const String FETCHCATEGORIES = r'''
query ($siteId: [Int]!, $childId: Int, $isActive: Boolean, $isPrivate: Boolean, $search: String, $after: String, $first: Int) {
  storeCategories(
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
        createdAt
        external
        id
        hid
        image(childId: $childId)
        cover
        isActive(childId: $childId)
        isExternal
        isParent
        isPrivate
        priority
        siteId
        slug
        title
        total
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
