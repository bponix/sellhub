import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/model/profile_res-Model.dart';
import 'package:sellhub/features/profile/data/model/reseller_response_model.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/profile/mutation/customer_address_mutations.dart';
import 'package:sellhub/features/profile/mutation/customer_favorite_mutations.dart';
import 'package:sellhub/features/profile/mutation/request_reseller.dart';
import 'package:sellhub/features/profile/mutation/user_password_update.dart';
import 'package:sellhub/features/profile/query/order_query.dart';
import 'package:sellhub/features/profile/query/profile_query.dart';
import 'package:sellhub/features/profile/query/reseller_query.dart';
import 'package:sellhub/features/profile/query/self_store_customer.dart';

class ProfileRepository {
  final GraphQLClient _client;
  ProfileRepository(this._client);

  // get profile data
  Future<ProfileResModel?>? fetchProfileDetails(int id) async {
    //print('user id is: ${id}');
    final QueryResult result = await _client
        .query(
          QueryOptions(
            document: gql(FETCHPROFILE),
            variables: {"id": id},
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        )
        .timeout(Duration(seconds: 10)); // it's good practice to add timeout

    if (result.hasException) {
      // print('has Eception');
      // // check network error
      // if (result.exception!.linkException is NetworkException) {
      //   print('Network Error: Please check your internet');
      // }
      throw Exception(result.exception.toString());
    }
    //log(result.data.toString());
    if (result.data != null) {
      final edges = result.data?['storeCustomer'];
      return ProfileResModel.fromJson(edges);
    } else {
      return null;
    }
  }

  // order history
  Future<List<OrderHistoryResModelProfile>> fetchOrderHistory(
    int siteId,
    int customerId,
  ) async {
    //print('user id is: ${customerId}');
    // print('Call Fetch Order History');
    // print(siteId);
    // print(customerId);
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHORDERHISTORY),
        variables: {
          "siteId": siteId,
          "customerId": customerId,
          "referId": null,
          "after": null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      // print('Has Exception');
      throw Exception(result.exception.toString());
    }
    // print('Data is >>>>');
    // print(result.data);
    if (result.data != null && result.data?['storeOrders']['edges'] != null) {
      final List edges = result.data?['storeOrders']['edges'];
      return edges
          .map((e) => OrderHistoryResModelProfile.fromJson(e['node']))
          .toList();
    } else {
      return [];
    }
  }

  // get reseller info
  Future<ResellerResModelProfile?> fetchResellerInformation(int id) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHRESELLERINFORMATION),
        variables: {"id": id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    if (result.data != null && result.data?['storeCustomer'] != null) {
      return ResellerResModelProfile.fromJson(result.data?['storeCustomer']);
    } else {
      return null;
    }
  }

  // request for reselling
  Future<bool> makeResellerRequest(
    int userId,
    int customerId,
    String title,
    String paymentTitle,
    String paymentNo,
  ) async {
    final QueryResult result = await _client.mutate(
      MutationOptions(
        document: gql(RESELLERREQUEST),
        variables: {
          "userId": userId,
          "customerId": customerId,
          "title": title,
          "customerType": [2],
          "paymentTitle": paymentTitle,
          "paymentNo": paymentNo,
          "note": [],
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      debugPrint(result.exception.toString());
      //throw Exception(result.exception.toString());
      return false;
    }
    if (result.data != null) {
      return true;
    } else {
      return false;
    }
  }

  // self store customer info fetch
  Future<SelfStoreCustomerRes?> fetchSelfStoreCustomer(
    int userId,
    int siteID,
  ) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHSELFSTORECUSTOMER),
        variables: {
          "userId": userId,
          "siteId": siteID,
          "isActive": true,
          "isReseller": false,
          "iswholesale": false,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    //print(result.data);
    if (result.data != null && result.data?['selfStoreCustomer'] != null) {
      return SelfStoreCustomerRes.fromJson(result.data?['selfStoreCustomer']);
    } else {
      return null;
    }
  }

  Future<bool> addFavorite({
    required int userId,
    required int customerId,
    required int productId,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(ADD_STORE_CUSTOMER_FAVORITE),
        variables: <String, dynamic>{
          'userId': userId,
          'customerId': customerId,
          'productId': productId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    return result.data?['selfStoreCustomerAddFavorite'] == true;
  }

  Future<bool> removeFavorite({
    required int userId,
    required int customerId,
    required int productId,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(REMOVE_STORE_CUSTOMER_FAVORITE),
        variables: <String, dynamic>{
          'userId': userId,
          'customerId': customerId,
          'productId': productId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    return result.data?['selfStoreCustomerRemoveFavorite'] == true;
  }

  Future<bool> addShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _addressMutation(
      document: ADD_STORE_CUSTOMER_SHIPPING_ADDRESS,
      customerId: customerId,
      address: address,
      resultKey: 'storeCustomerAddShippingAddress',
    );
  }

  Future<bool> removeShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _addressMutation(
      document: REMOVE_STORE_CUSTOMER_SHIPPING_ADDRESS,
      customerId: customerId,
      address: address,
      resultKey: 'storeCustomerRemoveShippingAddress',
    );
  }

  Future<bool> addBillingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _addressMutation(
      document: ADD_STORE_CUSTOMER_BILLING_ADDRESS,
      customerId: customerId,
      address: address,
      resultKey: 'storeCustomerAddBillingAddress',
    );
  }

  Future<bool> removeBillingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _addressMutation(
      document: REMOVE_STORE_CUSTOMER_BILLING_ADDRESS,
      customerId: customerId,
      address: address,
      resultKey: 'storeCustomerRemoveBillingAddress',
    );
  }

  Future<bool> _addressMutation({
    required String document,
    required int customerId,
    required StoreCustomerAddressModel address,
    required String resultKey,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(document),
        variables: <String, dynamic>{
          'customerId': customerId,
          'id': address.id,
          'address': address.address,
          'formattedAddress': address.formattedAddress,
          'latitude': address.latitude,
          'longitude': address.longitude,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    return result.data?[resultKey] == true;
  }

  // password change
  Future<bool> passwordChange(
    int id,
    String oldPassword,
    String newPassword,
  ) async {
    //  print(id);
    final QueryResult result = await _client.mutate(
      MutationOptions(
        document: gql(USER_PASSWORD_UPDATE),
        variables: {
          "id": id,
          "email": "hfccoyt314978@bponi.com",
          "new": newPassword,
          "old": oldPassword,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      // print(result.exception);
      // print('Has Exception');
      return false;
    }
    //  print(result.data);
    if (result.data != null && result.data?['userPasswordUpdate'] != null) {
      return true;
    } else {
      return false;
    }
  }
}
