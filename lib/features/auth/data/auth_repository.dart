import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';

class AuthRepository {
  final GraphQLClient _client;

  AuthRepository(this._client);

  Future<String> login(String id, String password) async {
    // print('login repository');
    // print(id);
    const String loginMutation = r'''
      mutation login($id: Int!, $password: String!, $parentId: Int) {
        login(id: $id, password: $password, parentId: $parentId) {
          message
          token
        }
      }
    ''';

    final QueryResult result = await _client.mutate(
      MutationOptions(
        document: gql(loginMutation),
        variables: {
          'id': int.parse(id),
          'password': password,
          'parentId': null,
        },
      ),
    );

    if (result.hasException) {
      //throw Exception(result.exception.toString());
      return "";
    }
    // print('Login data>>>>>>');
    // print(result.data);
    final data = result.data?['login'];
    if (data != null && data['token'] != null) {
      await LocalStorage.saveToken(data['token']);
      return data['token'];
    } else {
      throw Exception('Login failed');
    }
  }

  Future<User?> register(SignUpReq model) async {
    const String joinMutation = r'''
    mutation join($country: Int!, $currency: String!, $firstName: String!, $language: String!, $lastName: String!, $name: String!, $password: String!, $phone: Int!, $referedCode: String, $source: String, $username: String!, $sourceId: Int, $parentId: Int) {
  join(
    data: {country: $country, currency: $currency, firstName: $firstName, language: $language, lastName: $lastName, name: $name, password: $password, phone: $phone, referedCode: $referedCode, source: $source, sourceId: $sourceId, username: $username}
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

    final QueryResult result = await _client.mutate(
      MutationOptions(
        document: gql(joinMutation),
        variables: {
          "country": model.country,
          "currency": model.currency,
          "firstName": model.firstName,
          "language": model.language,
          "lastName": model.lastName,
          "name": model.name,
          "password": model.password,
          "phone": model.phone,
          "referedCode": model.referedCode,
          "source": model.source,
          "username": model.username,
          "sourceId": model.sourceId,
          "parentId": model.parentId,
        },
      ),
    );

    if (result.hasException) {
      debugPrint('has exception');
      //throw Exception(result.exception.toString());
      return null;
    }

    final userData = result.data?['join'];
    if (userData != null) {
      return User.fromJson(userData);
    } else {
      //throw Exception('Registration failed');
      return null;
    }
  }

  Future<User?> checkUser(String phone) async {
    const String userCheckQuery = r'''
      query ($data: String!, $parentId: Int) {
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

    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(userCheckQuery),
        variables: {"data": phone, "parentId": null},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      //throw Exception(result.exception.toString());
      return null;
    }

    if (result.data == null || result.data!['userCheck'] == null) {
      return null;
    }
    return User.fromJson(result.data!['userCheck']);
  }

  Future<User?> sendOtp(int userId, String source, int sourceId) async {
    const String userOtpUpdateMutation = r'''
    mutation userOtpUpdate($id: Int!, $source: String!, $sourceId: Int) {
  userOtpUpdate(id: $id, source: $source, sourceId: $sourceId) {
    address
    avatar
    country
    currency
    email
    firstName
    formattedAddress
    id
    isActive
    isStaff
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

    final QueryResult result = await _client.mutate(
      MutationOptions(
        document: gql(userOtpUpdateMutation),
        variables: {"id": userId, "source": source, "sourceId": sourceId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    if (result.data == null || result.data!['userOtpUpdate'] == null) {
      return null;
    }
    return User.fromJson(result.data!['userOtpUpdate']);
  }

  Future<User?> verifyOtp(int userId, int otp) async {
    const String userActiveUpdateMutation = r'''
     mutation userActiveUpdate($id: Int!, $otp: Int!) {
  userActiveUpdate(id: $id, otp: $otp) {
    address
    avatar
    country
    currency
    email
    firstName
    formattedAddress
    id
    isActive
    isStaff
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

    final QueryResult result = await _client.mutate(
      MutationOptions(
        document: gql(userActiveUpdateMutation),
        variables: {"id": userId, "otp": otp},
      ),
    );

    if (result.hasException) {
      debugPrint('Has Exception');
      return null;
      // throw Exception(result.exception.toString());
    }

    return User.fromJson(result.data!['userActiveUpdate']);
  }

  Future<User?> resetPassword(
    int userId,
    String phone,
    int otp,
    String newPassword,
  ) async {
    const String passwordUpdateMutation = r'''
     mutation userOtpPasswordUpdate($id: Int!, $email: String!, $otp: Int!, $new: String!, $parentId: Int) {
  userOtpPasswordUpdate(
    id: $id
    data: {email: $email, otp: $otp, new: $new}
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
    isActive
    isStaff
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

    final QueryResult result = await _client.mutate(
      MutationOptions(
        document: gql(passwordUpdateMutation),
        variables: {
          "id": userId,
          "email": phone, // phone number pass here
          "otp": otp,
          "new": newPassword,
          "parentId": null,
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    // return result.data?['userOtpPasswordUpdate'] != null;
    return User.fromJson(result.data!['userOtpPasswordUpdate']);
  }
}
