const String fetchSitesQuery = r'''
query FetchSites(
  $siteType: String
  $search: String
  $queryType: String
  $latitude: Float
  $longitude: Float
  $first: Int
  $offset: Int
  $isActive: Boolean
  $isVerified: Boolean
) {
  sites(
    siteType: $siteType
    search: $search
    queryType: $queryType
    latitude: $latitude
    longitude: $longitude
    first: $first
    offset: $offset
    isActive: $isActive
    isVerified: $isVerified
  ) {
    edges {
      node {
        id
        domain
        title
        phoneLogo
        coverImage
        address
        latitude
        longitude
        whiteLabelUrl
      }
    }
  }
}
''';
