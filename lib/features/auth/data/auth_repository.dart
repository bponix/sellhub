import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/store_registry.dart';
import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final GraphQLClient _client;

  static const String _loginMutation = r'''
mutation Login($id: Int!, $password: String!, $parentId: Int) {
  login(id: $id, password: $password, parentId: $parentId) {
    message
    token
  }
}
''';

  static const String _userCheckQuery = r'''
query UserCheck($data: String!, $parentId: Int) {
  userCheck(data: $data, parentId: $parentId) {
    address
    avatar
    country
    currency
    email
    firstName
    formattedAddress
    id
    isStaff
    isActive
    latitude
    longitude
    name
    phone
    referCode
    referedCode
    username
  }
}
''';

  static const String _joinMutation = r'''
mutation Join(
  $country: Int!
  $currency: String!
  $email: String
  $firstName: String!
  $language: String!
  $lastName: String!
  $name: String!
  $password: String!
  $phone: Int
  $referedCode: String
  $source: String
  $username: String!
  $sourceId: Int
  $parentId: Int
  $isActive: Boolean
) {
  join(
    data: {
      country: $country
      currency: $currency
      email: $email
      firstName: $firstName
      language: $language
      lastName: $lastName
      name: $name
      password: $password
      phone: $phone
      referedCode: $referedCode
      source: $source
      sourceId: $sourceId
      username: $username
      isActive: $isActive
    }
    sourceId: $sourceId
    parentId: $parentId
  ) {
    address
    avatar
    country
    currency
    email
    firstName
    formattedAddress
    id
    isStaff
    isActive
    latitude
    longitude
    name
    phone
    referCode
    referedCode
    username
  }
}
''';

  static const String _sendOtpMutation = r'''
mutation SellHubSendOtp($id: Int!, $source: String!, $sourceId: Int) {
  userOtpUpdate(id: $id, source: $source, sourceId: $sourceId) {
    address avatar country currency email firstName formattedAddress id
    isStaff isActive latitude longitude name phone referCode referedCode username
  }
}
''';

  static const String _verifyOtpMutation = r'''
mutation SellHubVerifyOtp($id: Int!, $otp: Int!) {
  userActiveUpdate(id: $id, otp: $otp) {
    address avatar country currency email firstName formattedAddress id
    isStaff isActive latitude longitude name phone referCode referedCode username
  }
}
''';

  static const String _resetPasswordMutation = r'''
mutation SellHubResetPassword(
  $id: Int!
  $email: String!
  $otp: Int!
  $new: String!
  $parentId: Int
) {
  userOtpPasswordUpdate(
    id: $id
    data: {email: $email, otp: $otp, new: $new}
    parentId: $parentId
  ) {
    address avatar country currency email firstName formattedAddress id
    isStaff isActive latitude longitude name phone referCode referedCode username
  }
}
''';

  Future<String> login(String id, String password) async {
    final userId = int.tryParse(id);
    if (userId == null || userId <= 0) {
      throw ArgumentError.value(id, 'id', 'A valid user id is required.');
    }
    final result = await _client.mutate<Map<String, dynamic>>(
      MutationOptions<Map<String, dynamic>>(
        document: gql(_loginMutation),
        variables: <String, dynamic>{
          'id': userId,
          'password': password,
          'parentId': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final token = '${result.data?['login']?['token'] ?? ''}'.trim();
    if (token.isEmpty) {
      throw StateError('Authentication returned no session token.');
    }
    await LocalStorage.saveToken(token);
    await LocalStorage.setLogin(true);
    await LocalStorage.saveUserID(userId);
    return token;
  }

  Future<User?> register(SignUpReq model) async {
    final user = await _registerRemote(model);
    if (user != null) await LocalStorage.saveUserID(user.id);
    return user;
  }

  Future<User?> checkUser(String phone) async {
    final user = await _checkUserRemote(phone);
    if (user != null) await LocalStorage.saveUserID(user.id);
    return user;
  }

  Future<User?> sendOtp(int userId, String source, int sourceId) => _mutateUser(
    document: _sendOtpMutation,
    resultKey: 'userOtpUpdate',
    variables: <String, dynamic>{
      'id': userId,
      'source': source,
      'sourceId': sourceId,
    },
  );

  Future<User?> verifyOtp(int userId, int otp) => _mutateUser(
    document: _verifyOtpMutation,
    resultKey: 'userActiveUpdate',
    variables: <String, dynamic>{'id': userId, 'otp': otp},
  );

  Future<User?> resetPassword(
    int userId,
    String phone,
    int otp,
    String newPassword,
  ) => _mutateUser(
    document: _resetPasswordMutation,
    resultKey: 'userOtpPasswordUpdate',
    variables: <String, dynamic>{
      'id': userId,
      'email': phone,
      'otp': otp,
      'new': newPassword,
      'parentId': null,
    },
  );

  Future<User?> _checkUserRemote(String identifier) async {
    if (identifier.trim().isEmpty) {
      return null;
    }
    final result = await _client.query<Map<String, dynamic>>(
      QueryOptions<Map<String, dynamic>>(
        document: gql(_userCheckQuery),
        variables: <String, dynamic>{
          'data': identifier.trim(),
          'parentId': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final data = result.data?['userCheck'];
    if (data is Map<String, dynamic>) {
      return User.fromJson(data);
    }
    if (data is Map) {
      return User.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  Future<User?> _registerRemote(SignUpReq model) async {
    final result = await _client.mutate<Map<String, dynamic>>(
      MutationOptions<Map<String, dynamic>>(
        document: gql(_joinMutation),
        variables: <String, dynamic>{
          'country': model.country ?? 50,
          'currency':
              model.currency ??
              StoreRegistry.currentStore?.market.currencyCode ??
              'BDT',
          'email': model.username?.contains('@') == true
              ? model.username
              : null,
          'firstName': model.firstName ?? 'User',
          'language': model.language ?? 'en',
          'lastName': model.lastName ?? 'Guest',
          'name': model.name ?? model.username ?? 'SellHub Reseller',
          'password': model.password ?? '',
          'phone': model.phone,
          'referedCode': model.referedCode,
          'source': model.source,
          'username': model.username ?? model.phone?.toString() ?? '',
          'sourceId': model.sourceId,
          'parentId': model.parentId,
          'isActive': true,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final data = result.data?['join'];
    if (data is Map<String, dynamic>) {
      return User.fromJson(data);
    }
    if (data is Map) {
      return User.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  Future<User?> _mutateUser({
    required String document,
    required String resultKey,
    required Map<String, dynamic> variables,
  }) async {
    final result = await _client.mutate<Map<String, dynamic>>(
      MutationOptions<Map<String, dynamic>>(
        document: gql(document),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final data = result.data?[resultKey];
    if (data is Map<String, dynamic>) return User.fromJson(data);
    if (data is Map) {
      return User.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }
}
