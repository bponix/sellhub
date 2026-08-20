import 'package:geolocator/geolocator.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust.dart';
import 'package:sellhub/features/discovery/data/models/store_summary.dart';
import 'package:sellhub/features/discovery/query/fetch_sites.dart';

class StoreDiscoveryRepository {
  StoreDiscoveryRepository(this._client, this._trustStore);

  final GraphQLClient _client;
  final SupplierTrustLocalStore _trustStore;

  Future<List<StoreSummary>> fetchStores({
    String? search,
    String queryType = 'latest',
    double? latitude,
    double? longitude,
    int first = 24,
    int offset = 0,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(fetchSitesQuery),
        variables: <String, dynamic>{
          'siteType': 'store',
          'search': search?.trim().isEmpty == true ? null : search?.trim(),
          'queryType': queryType,
          'latitude': latitude,
          'longitude': longitude,
          'first': first,
          'offset': offset,
          'isActive': true,
          'isVerified': true,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final edges = result.data?['sites']?['edges'];
    final stores = edges is List
        ? edges
              .whereType<Map>()
              .map((edge) => edge['node'])
              .whereType<Map>()
              .map(
                (row) => StoreSummary.fromJson(Map<String, dynamic>.from(row)),
              )
              .where((store) => store.domain.trim().isNotEmpty)
              .toList(growable: false)
        : const <StoreSummary>[];
    final withTrust = await _attachTrustProfiles(stores);
    final sorted = _sortStoresByContext(
      withTrust,
      latitude: latitude,
      longitude: longitude,
      queryType: queryType,
    );
    return sorted.map(_anonymousStore).toList(growable: false);
  }

  Future<StoreSummary> resolveByDomain(String domain) async {
    final stores = await fetchStores(search: domain, first: 20, offset: 0);
    final store = stores.cast<StoreSummary?>().firstWhere(
      (candidate) => candidate?.domain.toLowerCase() == domain.toLowerCase(),
      orElse: () => null,
    );
    if (store == null) {
      throw Exception('Store not found.');
    }
    return store.copyWith(
      trustProfile: await fetchSupplierTrustSummary(
        store.siteId,
        domain: store.domain,
        title: store.title,
      ),
    );
  }

  StoreSummary _anonymousStore(StoreSummary store) => StoreSummary(
    siteId: store.siteId,
    domain: store.domain,
    title: 'Verified supply partner',
    logoUrl: null,
    coverImage: null,
    address: null,
    latitude: store.latitude,
    longitude: store.longitude,
    whiteLabelUrl: null,
    trustProfile: store.trustProfile,
  );

  Future<SupplierTrustProfile?> fetchSupplierTrustSummary(
    int siteId, {
    String domain = '',
    String title = '',
  }) async {
    return _trustStore.loadProfile(
      siteId: siteId,
      domain: domain,
      title: title,
    );
  }

  Future<List<StoreSummary>> _attachTrustProfiles(
    List<StoreSummary> stores,
  ) async {
    if (stores.isEmpty) return stores;
    final trustBySiteId = await _trustStore.loadProfiles(
      stores
          .map(
            (store) => SupplierTrustSeedInput(
              siteId: store.siteId,
              domain: store.domain,
              title: store.title,
            ),
          )
          .toList(growable: false),
    );
    return stores
        .map(
          (store) => store.copyWith(trustProfile: trustBySiteId[store.siteId]),
        )
        .toList(growable: false);
  }

  List<StoreSummary> _sortStoresByContext(
    List<StoreSummary> stores, {
    required String queryType,
    double? latitude,
    double? longitude,
  }) {
    final ranked = List<StoreSummary>.from(stores);
    ranked.sort((a, b) {
      final trustCompare = _trustScoreOf(b).compareTo(_trustScoreOf(a));
      if (queryType == 'nearest' && latitude != null && longitude != null) {
        final aDistance = _distanceOrMax(a, latitude, longitude);
        final bDistance = _distanceOrMax(b, latitude, longitude);
        final distanceCompare = aDistance.compareTo(bDistance);
        if (distanceCompare != 0) return distanceCompare;
      }
      if (trustCompare != 0) return trustCompare;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return ranked;
  }

  double _distanceOrMax(StoreSummary store, double latitude, double longitude) {
    final storeLatitude = store.latitude;
    final storeLongitude = store.longitude;
    if (storeLatitude == null || storeLongitude == null) {
      return double.maxFinite;
    }
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      storeLatitude,
      storeLongitude,
    );
  }

  double _trustScoreOf(StoreSummary store) {
    return store.trustProfile?.score ?? 0;
  }

  Future<Position?> resolveCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
      const Duration(seconds: 2),
      onTimeout: () => false,
    );
    if (!serviceEnabled) return null;

    final permission = await Geolocator.checkPermission().timeout(
      const Duration(seconds: 2),
      onTimeout: () => LocationPermission.denied,
    );
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      return null;
    }
  }
}
