import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';

import 'local_graphql_api.dart';

final _getEntityDocument = gql(r'''
  query GetEntity($collection: String!, $id: String!) {
    getEntity(collection: $collection, id: $id) {
      id
      payload
    }
  }
''');

final _upsertEntityDocument = gql(r'''
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

Future<String?> loadLocalSeedVersion(
  GraphQLClient client, {
  required String seedKey,
}) async {
  final result = await client.query(
    QueryOptions(
      document: _getEntityDocument,
      variables: <String, dynamic>{
        'collection': LocalGraphqlCollections.bootstrapMeta,
        'id': seedKey,
      },
      fetchPolicy: FetchPolicy.noCache,
    ),
  );
  if (result.hasException) {
    throw result.exception!;
  }
  final raw = result.data?['getEntity'] as Map<String, dynamic>?;
  if (raw == null) {
    return null;
  }
  final payload = Map<String, dynamic>.from(
    jsonDecode(raw['payload'] as String? ?? '{}') as Map,
  );
  return payload['version'] as String?;
}

Future<void> saveLocalSeedVersion(
  GraphQLClient client, {
  required String seedKey,
  required String version,
}) async {
  final result = await client.mutate(
    MutationOptions(
      document: _upsertEntityDocument,
      variables: <String, dynamic>{
        'collection': LocalGraphqlCollections.bootstrapMeta,
        'id': seedKey,
        'payload': jsonEncode(<String, dynamic>{'version': version}),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      fetchPolicy: FetchPolicy.noCache,
    ),
  );
  if (result.hasException) {
    throw result.exception!;
  }
}
