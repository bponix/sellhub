import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

typedef TokenProvider = FutureOr<String?> Function();
typedef GraphQLLogger = void Function(String message);

GraphQLClient createGraphQLClient({
  required String endpoint,
  TokenProvider? tokenProvider,
  GraphQLLogger? logger,
  Duration queryTimeout = const Duration(seconds: 30),
  Link? link,
}) {
  final resolvedLogger =
      logger ??
      (String message) {
        if (kDebugMode) {
          debugPrint(message);
        }
      };

  final resolvedLink =
      link ??
      (() {
        final httpLink = HttpLink(
          endpoint,
          defaultHeaders: const <String, String>{'X-API-KEY': 'app'},
        );
        final authLink = AuthLink(
          getToken: () async {
            final token = await tokenProvider?.call();
            if (token == null || token.isEmpty) {
              return null;
            }
            resolvedLogger('GraphQL auth header attached.');
            return 'Bearer $token';
          },
        );
        return authLink.concat(httpLink);
      })();

  return GraphQLClient(
    link: resolvedLink,
    cache: GraphQLCache(store: InMemoryStore()),
    queryRequestTimeout: queryTimeout,
  );
}
