import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/features/cart/data/models/delivery_place_res.dart';
import 'package:sellhub/features/cart/data/models/order_create_req.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';
import 'package:sellhub/features/cart/data/models/payment_gateway_response.dart';
import 'package:sellhub/features/cart/data/models/payment_method_res.dart';
import 'package:sellhub/features/cart/data/models/voucher_check_res.dart';
import 'package:sellhub/features/cart/mutation/order_create_customer_mutation.dart';
import 'package:sellhub/features/cart/mutation/order_create_mutation.dart';
import 'package:sellhub/features/cart/mutation/payment_gateway_mutation.dart';
import 'package:sellhub/features/cart/query/order_events_query.dart';
import 'package:sellhub/features/cart/query/logisticsmerchants_query.dart';
import 'package:sellhub/features/cart/query/store_gateway_query.dart';
import 'package:sellhub/features/cart/query/voucher_query.dart';
import 'package:sellhub/features/orders/data/models/order_event_model.dart';
import 'package:sellhub/features/orders/mutation/order_event_mutations.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/profile/mutation/customer_address_mutations.dart';
import 'package:sellhub/features/profile/query/self_store_customer.dart';

import 'models/paymentgateway_req.dart';

class CheckoutRepository {
  final GraphQLClient _client;
  CheckoutRepository(this._client);

  // Delivery Place
  Future<List<DeliveryPlaceRes>> fetchDeliveryPlace(int siteUserId) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHLOGISTICSMERCHANTS),
        variables: {
          "userId": siteUserId,
          "search": null,
          "isActive": true,
          "first": 2048,
          "after": null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    //     print('delivery place repository data: ');
    // print(result.data);
    if (result.data != null &&
        result.data?['logisticsMerchants']['edges'] != null) {
      final List edges = result.data?['logisticsMerchants']['edges'];
      return edges.map((e) => DeliveryPlaceRes.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

  // Payment Method
  Future<List<PaymentMethodRes>> fetchPaymentMethod(int siteId) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHSTOREGATEWAY),
        variables: {
          "siteId": siteId,
          "search": null,
          "first": 256,
          "after": null,
          "before": null,
          "last": null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    //print(result.data);

    if (result.data != null && result.data?['storeGateways']['edges'] != null) {
      final List edges = result.data?['storeGateways']['edges'];
      return edges.map((e) => PaymentMethodRes.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

  // third party Payment Method

  // Order Create
  Future<OrderCreateRes> makeOrder(
    OrderCreateReq model, {
    required bool isAuthenticated,
    int? userId,
    int? customerId,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(
          isAuthenticated
              ? ORDER_CREATE_BY_CUSTOMER_MUTATION
              : ORDERCREATEMUTATION,
        ),
        variables: <String, dynamic>{
          ...model.toJson(),
          if (isAuthenticated) 'userId': userId,
          if (isAuthenticated) 'customerId': customerId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return OrderCreateRes.fromJson(
      result.data?[isAuthenticated
          ? 'selfStoreOrderCreateByCustomer'
          : 'selfStoreOrderCreateByGuest'],
    );
  }

  //payment gateway
  Future<PaymentGatewayResponse> paymentGatewayRequest(
    PaymentGatewayReq model,
  ) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(PAYMENT_REQUEST),
        variables: model.toJson(),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    final data = result.data?['storeOrderPaymentRequest'];
    if (data is Map<String, dynamic>) {
      return PaymentGatewayResponse.fromJson(data);
    }
    if (data is Map) {
      return PaymentGatewayResponse.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Payment gateway response was empty');
  }

  Future<SelfStoreCustomerRes?> fetchCustomerContext({
    required int userId,
    required int siteId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHSELFSTORECUSTOMER),
        variables: <String, dynamic>{
          'userId': userId,
          'siteId': siteId,
          'isActive': true,
          'isAffiliate': false,
          'isReseller': false,
          'isWholesale': false,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['selfStoreCustomer'];
    if (data is Map<String, dynamic>) {
      return SelfStoreCustomerRes.fromJson(data);
    }
    if (data is Map) {
      return SelfStoreCustomerRes.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<VoucherCheckRes> checkVoucher({
    required int siteId,
    required String code,
    required double quantity,
    required double total,
    required double delivery,
    required List<Map<String, dynamic>> products,
    int? userId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(
          userId == null
              ? STORE_VOUCHER_CHECK_BY_CODE
              : SELF_STORE_VOUCHER_CHECK_BY_CODE,
        ),
        variables: <String, dynamic>{
          'siteId': siteId,
          if (userId != null) 'userId': userId,
          'code': code,
          'quantity': quantity,
          'total': total,
          'delivery': delivery,
          'products': products,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final key = userId == null
        ? 'storeVoucherCheckByCode'
        : 'selfStoreVoucherCheckByCode';
    final data = result.data?[key];
    if (data is Map<String, dynamic>) {
      return VoucherCheckRes.fromJson(data);
    }
    if (data is Map) {
      return VoucherCheckRes.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Voucher response was empty');
  }

  Future<List<OrderEventModel>> fetchOrderEvents({
    required int siteId,
    required int orderId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCH_STORE_ORDER_EVENTS),
        variables: <String, dynamic>{
          'siteId': siteId,
          'orderId': orderId,
          'isPublic': true,
          'first': 100,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final edges = result.data?['storeOrderEvents']?['edges'];
    if (edges is! List) return const <OrderEventModel>[];
    return edges
        .map((edge) => edge['node'])
        .whereType<Map>()
        .map(
          (node) => OrderEventModel.fromJson(Map<String, dynamic>.from(node)),
        )
        .toList();
  }

  Future<OrderEventModel> createCustomerOrderEvent({
    required int userId,
    required int siteId,
    required int orderId,
    required int eventType,
    required String note,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(createCustomerOrderEventMutation),
        variables: <String, dynamic>{
          'userId': userId,
          'siteId': siteId,
          'orderId': orderId,
          'eventType': eventType,
          'note': note,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['selfStoreOrderEventCreateByCustomer'];
    if (data is Map<String, dynamic>) {
      return OrderEventModel.fromJson(data);
    }
    if (data is Map) {
      return OrderEventModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Customer order event response was empty');
  }

  Future<bool> addShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(ADD_STORE_CUSTOMER_SHIPPING_ADDRESS),
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
    return result.data?['storeCustomerAddShippingAddress'] == true;
  }
}
