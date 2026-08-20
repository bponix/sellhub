import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/capabilities/store_surface_capabilities.dart';
import 'package:sellhub/core/capabilities/store_public_runtime.dart';

const String storePublicRuntimeQuery = r'''
query StorePublicRuntime($domain: String!, $route: String, $appKey: String, $surface: String) {
  storePublicRuntime(domain: $domain, route: $route, appKey: $appKey, surface: $surface) {
    siteTitle
    ready
    code
    message
    action
    retryable
    market {
      countryCode
      currencyCode
      defaultLanguage
      languageCodes
      timezone
      phoneCountryCode
      phoneNationalPrefix
      phoneMinDigits
      phoneMaxDigits
      taxEnabled
      taxLabel
      defaultTaxRate
      pricesIncludeTax
      logisticsZoneModel
      localLaneLabel
      remoteLaneLabel
      cashOnDeliveryEnabled
      payoutMethods
      defaultPayoutMethod
      source
      appOverrideApplied
    }
  }
}
''';

const String mobileStoreSurfaceQuery = r'''
query MobileStoreSurface($siteId: Int!, $surface: String!) {
  siteSurface(siteId: $siteId, appType: "store", surface: $surface) {
    siteId
    appType
    surfaceKey
    capabilities {
      key
      state
      reason
      source
    }
    warnings {
      code
      message
      severity
    }
  }
}
''';

class StoreSurfaceRepository {
  StoreSurfaceRepository(this._client);

  final GraphQLClient _client;

  Future<StorePublicRuntime> fetchPublicRuntime({
    required String domain,
    String route = '/',
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(storePublicRuntimeQuery),
        variables: <String, dynamic>{
          'domain': domain,
          'route': route,
          'appKey': 'store.sellhub_supply_app',
          'surface': 'sellhub',
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw Exception(result.exception.toString());
    final raw = result.data?['storePublicRuntime'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('SellHub runtime state is unavailable.');
    }
    return StorePublicRuntime.fromJson(raw);
  }

  Future<StoreSurfaceCapabilitySet> fetchSellHubSurface(int siteId) {
    return _fetch(siteId: siteId, surface: 'sellhub');
  }

  Future<StoreSurfaceCapabilitySet> _fetch({
    required int siteId,
    required String surface,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(mobileStoreSurfaceQuery),
        variables: <String, dynamic>{'siteId': siteId, 'surface': surface},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final raw = result.data?['siteSurface'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('SellHub channel state is unavailable.');
    }

    return StoreSurfaceCapabilitySet.fromJson(raw);
  }
}
