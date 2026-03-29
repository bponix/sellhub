import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sellhub/core/network/custom_hive_store.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GraphQLService {
  static final IOClient _httpClient = IOClient(
    HttpClient()..connectionTimeout = const Duration(seconds: 15),
  );

  static final HttpLink httpLink = HttpLink(
    AppConstants.kBaseUrl,
    defaultHeaders: {'X-Api-Key': AppConstants.kApiKey},
    httpClient: _httpClient,
  );

  static final ErrorLink errorLink = ErrorLink(
    onException: (request, forward, exception) {
      developer.log(
        'GraphQL transport error: ${exception.toString()}',
        name: 'store.graphql',
      );
      return forward(request);
    },
    onGraphQLError: (request, forward, response) {
      developer.log(
        'GraphQL response error: ${response.errors?.map((e) => e.message).join(', ')}',
        name: 'store.graphql',
      );
      return forward(request);
    },
  );

  static final AuthLink authLink = AuthLink(
    getToken: () async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.kAuthTokenKey);
      if (token != null && token.isNotEmpty) {
        return 'BPONI-AUTH $token';
      }
      return null;
    },
  );

  static final Link link = errorLink.concat(authLink.concat(httpLink));

  static Future<ValueNotifier<GraphQLClient>> initClient() async {
    final box = await Hive.openBox<Map<dynamic, dynamic>>('graphqlStore');
    return ValueNotifier(
      GraphQLClient(
        link: link,
        cache: GraphQLCache(store: CustomHiveStore(box)),
        defaultPolicies: DefaultPolicies(
          watchQuery: Policies(fetch: FetchPolicy.cacheAndNetwork),
          query: Policies(fetch: FetchPolicy.cacheFirst),
          mutate: Policies(fetch: FetchPolicy.networkOnly),
        ),
      ),
    );
  }
}
