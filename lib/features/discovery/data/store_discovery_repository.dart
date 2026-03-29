import 'package:geolocator/geolocator.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/features/discovery/data/models/store_summary.dart';
import 'package:sellhub/features/discovery/query/fetch_sites.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/query/site_information.dart';

class StoreDiscoveryRepository {
  StoreDiscoveryRepository(this._client);

  final GraphQLClient _client;

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

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final edges = result.data?['sites']?['edges'] as List<dynamic>? ?? <dynamic>[];
    return edges
        .map((dynamic edge) => StoreSummary.fromJson(edge['node'] as Map<String, dynamic>))
        .where((StoreSummary site) => site.domain.trim().isNotEmpty)
        .toList();
  }

  Future<StoreSummary> resolveByDomain(String domain) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHSITEINFORMATION),
        variables: <String, dynamic>{'domain': domain.trim()},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    final raw = result.data?['site'];
    if (raw == null) {
      throw Exception('Store not found.');
    }
    final site = SiteInformationRes.fromJson(Map<String, dynamic>.from(raw));
    final siteId = site.id;
    final siteDomain = site.domain?.trim();
    if (siteId == null || siteDomain == null || siteDomain.isEmpty) {
      throw Exception('Store configuration is incomplete.');
    }
    return StoreSummary(
      siteId: siteId,
      domain: siteDomain,
      title: (site.title?.trim().isNotEmpty ?? false) ? site.title!.trim() : siteDomain,
      logoUrl: site.phoneLogo,
      coverImage: site.coverImage,
      address: site.address,
      latitude: site.latitude,
      longitude: site.longitude,
      whiteLabelUrl: site.whiteLabelUrl,
    );
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
