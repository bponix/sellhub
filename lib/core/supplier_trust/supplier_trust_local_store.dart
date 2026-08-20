import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/api/graphql_client_factory.dart';
import 'package:sellhub/core/api/local_graphql_api.dart';
import 'package:sellhub/core/api/local_seed_guard.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_seed.dart';

class SupplierTrustLocalStore {
  SupplierTrustLocalStore({required LocalGraphQLApi api})
    : _client = createGraphQLClient(
        endpoint: 'https://example.invalid/graphql',
        link: LocalGraphQLLink(api: api),
      );

  final GraphQLClient _client;

  static const String _seedKey = 'supplier_trust_seed';
  static const String _collection =
      LocalGraphqlCollections.supplierTrustProfiles;
  Future<void>? _seedFuture;

  static final String _seedVersion = 'supplier_trust_v1';

  static final _listCollectionDocument = gql(r'''
    query ListCollection($collection: String!) {
      listCollection(collection: $collection) {
        id
        payload
        updatedAt
      }
    }
  ''');

  static final _upsertEntityDocument = gql(r'''
    mutation UpsertEntity(
      $collection: String!
      $id: String!
      $payload: String!
      $updatedAt: String!
    ) {
      upsertEntity(
        collection: $collection
        id: $id
        payload: $payload
        updatedAt: $updatedAt
      ) {
        id
      }
    }
  ''');

  Future<void> ensureSeeded(Iterable<SupplierTrustSeedInput> stores) {
    final existing = _seedFuture;
    if (existing != null) {
      return existing;
    }
    final future = _ensureSeededInternal(stores).whenComplete(() {
      _seedFuture = null;
    });
    _seedFuture = future;
    return future;
  }

  Future<SupplierTrustProfile?> loadProfile({
    required int siteId,
    String domain = '',
    String title = '',
  }) async {
    await ensureSeeded(<SupplierTrustSeedInput>[
      SupplierTrustSeedInput(siteId: siteId, domain: domain, title: title),
    ]);
    final profiles = await loadProfiles(<SupplierTrustSeedInput>[
      SupplierTrustSeedInput(siteId: siteId, domain: domain, title: title),
    ]);
    return profiles[siteId];
  }

  Future<Map<int, SupplierTrustProfile>> loadProfiles(
    Iterable<SupplierTrustSeedInput> stores,
  ) async {
    await ensureSeeded(stores);
    final result = await _client.query(
      QueryOptions(
        document: _listCollectionDocument,
        variables: const <String, dynamic>{'collection': _collection},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    _throwIfFailed(result);
    final rawItems =
        result.data?['listCollection'] as List<dynamic>? ?? const <dynamic>[];
    final expectedIds = stores.map((item) => item.siteId).toSet();
    final profiles = <int, SupplierTrustProfile>{};
    for (final item in rawItems.whereType<Map<String, dynamic>>()) {
      final id = int.tryParse(item['id'] as String? ?? '');
      if (id == null || !expectedIds.contains(id)) continue;
      final payload = Map<String, dynamic>.from(
        jsonDecode(item['payload'] as String? ?? '{}') as Map,
      );
      payload['updatedAt'] ??= item['updatedAt'] as String?;
      profiles[id] = SupplierTrustProfile.fromJson(payload);
    }
    return profiles;
  }

  Future<void> _ensureSeededInternal(
    Iterable<SupplierTrustSeedInput> stores,
  ) async {
    final seedInputs = <SupplierTrustSeedInput>[];
    for (final item in stores) {
      if (item.siteId <= 0) continue;
      if (seedInputs.any((existing) => existing.siteId == item.siteId)) {
        continue;
      }
      seedInputs.add(item);
    }
    if (seedInputs.isEmpty) return;

    final version = await loadLocalSeedVersion(_client, seedKey: _seedKey);
    final shouldWriteVersion = version != _seedVersion;

    final existingProfiles = await loadProfilesWithoutSeeding(seedInputs);
    for (final input in seedInputs) {
      if (existingProfiles.containsKey(input.siteId)) {
        continue;
      }
      final profile = SupplierTrustSeedFactory.build(input);
      await _upsertProfile(input.siteId, profile);
    }

    if (shouldWriteVersion) {
      await saveLocalSeedVersion(
        _client,
        seedKey: _seedKey,
        version: _seedVersion,
      );
    }
  }

  Future<Map<int, SupplierTrustProfile>> loadProfilesWithoutSeeding(
    Iterable<SupplierTrustSeedInput> stores,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: _listCollectionDocument,
        variables: const <String, dynamic>{'collection': _collection},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    _throwIfFailed(result);
    final rawItems =
        result.data?['listCollection'] as List<dynamic>? ?? const <dynamic>[];
    final expectedIds = stores.map((item) => item.siteId).toSet();
    final profiles = <int, SupplierTrustProfile>{};
    for (final item in rawItems.whereType<Map<String, dynamic>>()) {
      final id = int.tryParse(item['id'] as String? ?? '');
      if (id == null || !expectedIds.contains(id)) continue;
      final payload = Map<String, dynamic>.from(
        jsonDecode(item['payload'] as String? ?? '{}') as Map,
      );
      payload['updatedAt'] ??= item['updatedAt'] as String?;
      profiles[id] = SupplierTrustProfile.fromJson(payload);
    }
    return profiles;
  }

  Future<void> _upsertProfile(int siteId, SupplierTrustProfile profile) async {
    final result = await _client.mutate(
      MutationOptions(
        document: _upsertEntityDocument,
        variables: <String, dynamic>{
          'collection': _collection,
          'id': siteId.toString(),
          'payload': jsonEncode(profile.toJson()),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    _throwIfFailed(result);
  }

  void _throwIfFailed(QueryResult result) {
    if (result.hasException) {
      throw result.exception!;
    }
  }
}
