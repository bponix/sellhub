const String FETCHSUBSUBCATEGORY = r'''
query ($siteId: [Int]!, $categoryId: Int, $subCategoryId: Int, $isActive: Boolean, $isPrivate: Boolean, $first: Int, $after: String) {
  storeSubSubCategories(
    siteId: $siteId
    categoryId: $categoryId
    subCategoryId: $subCategoryId
    isActive: $isActive
    isPrivate: $isPrivate
    first: $first
    after: $after
  ) {
    total
    edges {
      node {
        categoryId
        id
        hid
        image
        isActive
        isPrivate
        priority
        slug
        subCategoryId
        title
        translation
        siteId
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
