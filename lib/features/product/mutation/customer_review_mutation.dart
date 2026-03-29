const String SUBMIT_REVIEW_MUTATION = r'''
mutation selfStoreProductReviewCreate($userId: Int!, $productId: Int!, $description: String!, $rating: Int!, $feedbackType: String!, $status: String!, $siteId: Int!, $image: String, $feedbacker: String) {
  selfStoreProductReviewCreate(
    userId: $userId
    data: {description: $description, productId: $productId, feedbackType: $feedbackType, rating: $rating, status: $status, siteId: $siteId, image: $image, feedbacker: $feedbacker}
  ) {
    id
  }
}
 ''';

const String FETCH_CUSTOMER_REVIEW = r'''
query ($productId: Int, $after: String, $first: Int) {
  storeProductReviews(productId: $productId, first: $first, after: $after) {
    total
    edges {
      node {
        createdAt
        description
        id
        rating
        userId
        user {
          id
          name
          avatar
        }
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
