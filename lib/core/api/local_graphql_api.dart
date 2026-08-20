import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/database/local_entity_database.dart';

class LocalGraphqlCollections {
  LocalGraphqlCollections._();

  static const String supplierTrustProfiles = 'supplier_trust_profiles';
  static const String bootstrapMeta = 'bootstrap_meta';
  static const String resellerQuickOrderDrafts = 'reseller_quick_order_drafts';
  static const String resellerBuyerRiskProfiles =
      'reseller_buyer_risk_profiles';
  static const String resellerOrderGroupDrafts = 'reseller_order_group_drafts';
  static const String resellerShareAssetDrafts = 'reseller_share_asset_drafts';
}

class LocalGraphqlOperations {
  LocalGraphqlOperations._();

  static const String listCollection = 'ListCollection';
  static const String getEntity = 'GetEntity';
  static const String replaceCollection = 'ReplaceCollection';
  static const String upsertEntity = 'UpsertEntity';
  static const String deleteEntity = 'DeleteEntity';
}

class LocalGraphQLApi {
  LocalGraphQLApi({required LocalEntityDatabase database})
    : _database = database;

  final LocalEntityDatabase _database;

  Future<Map<String, dynamic>> execute({
    required String operationName,
    required Map<String, dynamic> variables,
  }) async {
    switch (operationName) {
      case LocalGraphqlOperations.listCollection:
        final collection = variables['collection'] as String? ?? '';
        final records = await _database.listCollection(collection);
        return <String, dynamic>{
          '__typename': 'Query',
          'listCollection': records
              .map((item) => item.toGraphqlJson())
              .toList(growable: false),
        };
      case LocalGraphqlOperations.getEntity:
        final collection = variables['collection'] as String? ?? '';
        final id = variables['id'] as String? ?? '';
        final record = await _database.getEntity(
          collection: collection,
          id: id,
        );
        return <String, dynamic>{
          '__typename': 'Query',
          'getEntity': record?.toGraphqlJson(),
        };
      case LocalGraphqlOperations.replaceCollection:
        final collection = variables['collection'] as String? ?? '';
        final rawEntities =
            (variables['entities'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .toList(growable: false);
        final records = rawEntities
            .map(
              (item) => LocalEntityRecord(
                id: item['id'] as String? ?? '',
                payload: item['payload'] as String? ?? '{}',
                updatedAt: item['updatedAt'] as String? ?? '',
              ),
            )
            .toList(growable: false);
        final count = await _database.replaceCollection(
          collection: collection,
          records: records,
        );
        return <String, dynamic>{
          '__typename': 'Mutation',
          'replaceCollection': <String, dynamic>{
            '__typename': 'LocalCollectionMutationResult',
            'collection': collection,
            'count': count,
          },
        };
      case LocalGraphqlOperations.upsertEntity:
        final collection = variables['collection'] as String? ?? '';
        final id = variables['id'] as String? ?? '';
        final payload = variables['payload'] as String? ?? '{}';
        final updatedAt = variables['updatedAt'] as String? ?? '';
        final record = await _database.upsertEntity(
          collection: collection,
          id: id,
          payload: payload,
          updatedAt: updatedAt,
        );
        return <String, dynamic>{
          '__typename': 'Mutation',
          'upsertEntity': record.toGraphqlJson(),
        };
      case LocalGraphqlOperations.deleteEntity:
        final collection = variables['collection'] as String? ?? '';
        final id = variables['id'] as String? ?? '';
        final deleted = await _database.deleteEntity(
          collection: collection,
          id: id,
        );
        return <String, dynamic>{
          '__typename': 'Mutation',
          'deleteEntity': <String, dynamic>{
            '__typename': 'LocalEntityDeleteResult',
            'id': id,
            'deleted': deleted,
          },
        };
    }
    throw UnsupportedError(
      'Unsupported local GraphQL operation: $operationName',
    );
  }
}

class LocalGraphQLLink extends Link {
  LocalGraphQLLink({required LocalGraphQLApi api}) : _api = api;

  final LocalGraphQLApi _api;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final operationName =
        request.operation.operationName ?? _inferOperationName(request);
    if (operationName == null || operationName.isEmpty) {
      yield Response(
        response: const <String, dynamic>{},
        errors: const <GraphQLError>[
          GraphQLError(
            message: 'Operation name is required for local GraphQL.',
          ),
        ],
      );
      return;
    }

    try {
      final data = await _api.execute(
        operationName: operationName,
        variables: Map<String, dynamic>.from(request.variables),
      );
      yield Response(response: const <String, dynamic>{}, data: data);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'LocalGraphQLLink failed: $operationName error=$error\n$stackTrace',
        );
      }
      yield Response(
        response: const <String, dynamic>{},
        errors: <GraphQLError>[GraphQLError(message: error.toString())],
      );
    }
  }

  String? _inferOperationName(Request request) {
    for (final definition in request.operation.document.definitions) {
      if (definition is OperationDefinitionNode) {
        return definition.name?.value;
      }
    }
    return null;
  }
}

Map<String, dynamic> encodeLocalEntityList<T>({
  required List<T> items,
  required Map<String, dynamic> Function(T item) toJson,
  required String Function(T item) idOf,
  required String Function(T item) updatedAtOf,
}) {
  return <String, dynamic>{
    'entities': items
        .map(
          (item) => <String, dynamic>{
            'id': idOf(item),
            'payload': jsonEncode(toJson(item)),
            'updatedAt': updatedAtOf(item),
          },
        )
        .toList(growable: false),
  };
}
