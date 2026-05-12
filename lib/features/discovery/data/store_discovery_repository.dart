import 'package:geolocator/geolocator.dart';
import 'package:sellhub/core/local_seed/sellhub_catalog_local_store.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust.dart';
import 'package:sellhub/features/discovery/data/models/store_summary.dart';

class StoreDiscoveryRepository {
  StoreDiscoveryRepository(
    Object? client,
    this._trustStore,
    this._catalogStore,
  );

  final SupplierTrustLocalStore _trustStore;
  final SellHubCatalogLocalStore _catalogStore;

  Future<List<StoreSummary>> fetchStores({
    String? search,
    String queryType = 'latest',
    double? latitude,
    double? longitude,
    int first = 24,
    int offset = 0,
  }) async {
    final normalizedSearch = search?.trim().toLowerCase();
    final stores = await _catalogStore.loadSuppliers();
    final filtered = stores.where((store) {
      if (store.domain.trim().isEmpty) return false;
      if (normalizedSearch == null || normalizedSearch.isEmpty) return true;
      final haystacks = <String>[
        store.title,
        store.domain,
        store.address ?? '',
      ].map((value) => value.toLowerCase()).toList(growable: false);
      return haystacks.any((value) => value.contains(normalizedSearch));
    }).toList(growable: false);
    final withTrust = await _attachTrustProfiles(filtered);
    final sorted = _sortStoresByContext(
      withTrust,
      latitude: latitude,
      longitude: longitude,
      queryType: queryType,
    );
    return sorted.skip(offset).take(first).toList(growable: false);
  }

  Future<StoreSummary> resolveByDomain(String domain) async {
    final store = await _catalogStore.resolveSupplierByDomain(domain);
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

  Future<SupplierTrustProfile?> fetchSupplierTrustSummary(
    int siteId, {
    String domain = '',
    String title = '',
  }) async {
    return _trustStore.loadProfile(siteId: siteId, domain: domain, title: title);
  }

  Future<List<StoreSummary>> _attachTrustProfiles(List<StoreSummary> stores) async {
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
        .map((store) => store.copyWith(trustProfile: trustBySiteId[store.siteId]))
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
