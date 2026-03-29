const String FETCHSITESLIDER = r'''
query ($siteId: [Int]!, $childId: Int, $isPrivate: Boolean, $first: Int, $after: String) {
  siteSliders(
    siteId: $siteId
    isPrivate: $isPrivate
    first: $first
    after: $after
  ) {
    edges {
      node {
        body
        cover(childId: $childId)
        id
        isActive(childId: $childId)
        isPrivate
        isPhone
        priority
        siteId
        title
        updatedAt
        url
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
