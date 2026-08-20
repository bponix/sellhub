import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sellhub/core/local_seed/sellhub_commerce_local_store.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/pricing/smart_pricing.dart';
import 'package:sellhub/core/store/store_registry.dart';
import 'package:sellhub/features/cart/data/models/delivery_place_res.dart';
import 'package:sellhub/features/cart/data/models/order_create_req.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';
import 'package:sellhub/features/cart/data/models/payment_gateway_response.dart';
import 'package:sellhub/features/cart/data/models/payment_method_res.dart';
import 'package:sellhub/features/cart/data/models/quick_order_draft.dart';
import 'package:sellhub/features/cart/data/models/order_group_draft.dart';
import 'package:sellhub/features/cart/data/models/voucher_check_res.dart';
import 'package:sellhub/features/cart/data/models/reseller_quote.dart';
import 'package:sellhub/features/orders/data/models/order_event_model.dart';
import 'package:sellhub/features/cart/mutation/order_create_customer_mutation.dart';
import 'package:sellhub/features/orders/mutation/order_event_mutations.dart';
import 'package:sellhub/features/cart/mutation/payment_gateway_mutation.dart';
import 'package:sellhub/features/cart/query/order_events_query.dart';
import 'package:sellhub/features/cart/query/voucher_query.dart';
import 'package:sellhub/features/cart/query/store_gateway_query.dart';
import 'package:sellhub/features/cart/query/logisticsmerchants_query.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/profile/query/self_store_customer.dart';
import 'package:sellhub/features/profile/mutation/customer_address_mutations.dart';

import 'models/paymentgateway_req.dart';

class CheckoutRepository {
  CheckoutRepository(GraphQLClient client, this._commerceStore)
    : _client = client;

  final GraphQLClient _client;
  final SellHubCommerceLocalStore _commerceStore;

  static final _orderEventsDocument = gql(FETCH_STORE_ORDER_EVENTS);
  static final _createOrderEventDocument = gql(
    createCustomerOrderEventMutation,
  );
  static final _paymentRequestDocument = gql(PAYMENT_REQUEST);
  static final _storeVoucherDocument = gql(STORE_VOUCHER_CHECK_BY_CODE);
  static final _selfStoreVoucherDocument = gql(
    SELF_STORE_VOUCHER_CHECK_BY_CODE,
  );
  static final _customerContextDocument = gql(FETCHSELFSTORECUSTOMER);
  static final _paymentMethodsDocument = gql(FETCHSTOREGATEWAY);
  static final _deliveryPlacesDocument = gql(FETCHLOGISTICSMERCHANTS);
  static final _buyerBookDocument = gql(r'''
    query SellHubCheckoutBuyerBook($data: ResellerBuyerBookListInput!) {
      resellerBuyerBook(data: $data) {
        id buyerKey buyerLabel areaName preferredProducts notes reliability
        blocked disputed lastOrderId lastOrderAt orderCount totalAmount
        followUpAt followUpStatus followUpCompletedAt followUpReminderCount
        createdAt updatedAt
      }
    }
  ''');
  static final _buyerRiskDecisionDocument = gql(r'''
    query SellHubBuyerRiskDecision(
      $siteId: Int!
      $userId: Int!
      $buyerKey: String!
      $orderTotal: Float
      $itemCount: Int
      $areaName: String
      $codRequested: Boolean
    ) {
      storeSellhubBuyerRiskDecision(
        siteId: $siteId
        userId: $userId
        buyerKey: $buyerKey
        orderTotal: $orderTotal
        itemCount: $itemCount
        areaName: $areaName
        codRequested: $codRequested
      ) {
        disposition riskScore buyerKnown repeatBuyer codAllowed
        recommendedAdvance maximumCodAmount orderCount averageOrderAmount
        reliability areaClusterSample areaClusterRiskRate reasons summary
        source evaluatedAt
      }
    }
  ''');

  static final _createQuoteDocument = gql(r'''
    mutation SellHubMobileCreateQuote(
      $userId: Int!
      $siteId: Int!
      $customerId: Int!
      $data: StoreQuoteCreate!
      $products: [StoreQuoteCartCreate!]!
    ) {
      selfStoreQuoteCreateByCustomer(
        userId: $userId
        siteId: $siteId
        customerId: $customerId
        data: $data
        products: $products
      ) {
        id siteId userId customerName customerPhone customerAddress
        deliveryTime logisticsCharge logisticsExtraCharge grossAmount
        total cost profit status createdAt currency idempotencyKey
        commerceContext {
          channel campaignId buyerKeyHash expiresAt
          baseAmount sellAmount expectedProfit
        }
        lines {
          productId productName image quantity price resellPrice
        }
      }
    }
  ''');

  static final _linkQuoteOrderDocument = gql(r'''
    mutation SellHubMobileLinkQuoteOrder(
      $userId: Int!
      $siteId: Int!
      $quoteId: Int!
      $orderId: Int!
    ) {
      selfStoreQuoteLinkExistingOrder(
        userId: $userId
        siteId: $siteId
        quoteId: $quoteId
        orderId: $orderId
      ) { quoteId orderId alreadyConverted status }
    }
  ''');

  static final _createQuoteShareDocument = gql(r'''
    mutation SellHubMobileCreateQuoteShare($userId: Int!, $siteId: Int!, $quoteId: Int!) {
      selfStoreQuoteShareCreate(userId: $userId, siteId: $siteId, quoteId: $quoteId) {
        code expiresAt status
      }
    }
  ''');

  static final _resellerIdentityDocument = gql(r'''
    query SellHubCheckoutResellerIdentity($data: ResellerByUserInput!) {
      resellerByUser(data: $data) { id code }
    }
  ''');

  static final _attributeOrderDocument = gql(r'''
    mutation SellHubCheckoutAttributeOrder($data: ResellerAttributionUpsertInput!) {
      resellerAttributionUpsert(data: $data) {
        siteId orderId resellerId attributionType resellerCode
      }
    }
  ''');

  Future<List<DeliveryPlaceRes>> fetchDeliveryPlace(int siteUserId) async {
    final result = await _client.query(
      QueryOptions(
        document: _deliveryPlacesDocument,
        variables: <String, dynamic>{
          'userId': siteUserId > 0 ? siteUserId : null,
          'isActive': true,
          'first': 100,
          'after': null,
          'search': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final edges = result.data?['logisticsMerchants']?['edges'];
    if (edges is! List) return const <DeliveryPlaceRes>[];
    return edges
        .whereType<Map>()
        .map((edge) => edge['node'])
        .whereType<Map>()
        .map((row) => DeliveryPlaceRes.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<PaymentMethodRes>> fetchPaymentMethod(int siteId) async {
    final result = await _client.query(
      QueryOptions(
        document: _paymentMethodsDocument,
        variables: <String, dynamic>{
          'siteId': siteId,
          'first': 100,
          'after': null,
          'before': null,
          'last': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final edges = result.data?['storeGateways']?['edges'];
    if (edges is! List) return const <PaymentMethodRes>[];
    return edges
        .whereType<Map>()
        .map((edge) => edge['node'])
        .whereType<Map>()
        .map((row) => PaymentMethodRes.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<Map<int, ProductPricingMemory>> fetchPricingMemories({
    required int userId,
    required int siteId,
    required List<int> productIds,
  }) async => const <int, ProductPricingMemory>{};

  Future<OrderCreateRes> makeOrder(
    OrderCreateReq model, {
    required bool isAuthenticated,
    int? userId,
    int? customerId,
  }) async {
    final actorUserId = userId ?? (model.userId as int?);
    final actorCustomerId = customerId ?? model.customerId;
    final siteId = model.siteId ?? 0;
    if (!isAuthenticated ||
        actorUserId == null ||
        actorUserId <= 0 ||
        actorCustomerId == null ||
        actorCustomerId <= 0 ||
        siteId <= 0) {
      throw StateError('Sign in as a reseller before creating an order.');
    }
    final variables = Map<String, dynamic>.from(model.toJson())
      ..['userId'] = actorUserId
      ..['siteId'] = siteId
      ..['customerId'] = actorCustomerId
      ..['products'] = model.products
          .map(
            (product) => <String, dynamic>{
              'cost': product.cost?.toDouble(),
              'id': product.id,
              'price': product.price?.toDouble() ?? 0.0,
              'quantity': product.quantity?.toDouble() ?? 1.0,
              'resellPrice': product.resellPrice?.toDouble() ?? 0.0,
              'thumbnail': product.thumbnail,
              'title': product.title,
              'variant': product.variant,
              'variantId': product.variantId,
              'vat': product.vat?.toDouble() ?? 0.0,
            },
          )
          .toList(growable: false)
      ..['affiliateCommission'] = (model.affiliateCommission ?? 0).toDouble()
      ..['cashbackBalance'] = (model.cashbackBalance ?? 0).toDouble()
      ..['charge'] = (model.charge ?? 0).toDouble()
      ..['cost'] = (model.cost ?? 0).toDouble()
      ..['discount'] = (model.discount ?? 0).toDouble()
      ..['emiInterest'] = (model.emiInterest ?? 0).toDouble()
      ..['grossAmount'] = (model.grossAmount ?? 0).toDouble()
      ..['logisticsCharge'] = (model.logisticsCharge ?? 0).toDouble()
      ..['logisticsExtraCharge'] = (model.logisticsExtraCharge ?? 0).toDouble()
      ..['netAmount'] = (model.netAmount ?? 0).toDouble()
      ..['paid'] = (model.paid ?? 0).toDouble()
      ..['profit'] = (model.profit ?? 0).toDouble()
      ..['resellAmount'] = (model.resellAmount ?? 0).toDouble()
      ..['resellerAdvanceCollect'] = (model.resellerAdvanceCollect ?? 0)
          .toDouble()
      ..['resellerCommission'] = (model.resellerCommission ?? 0).toDouble()
      ..['rewardPoints'] = (model.rewardPoints ?? 0).toDouble()
      ..['subscriptionFee'] = (model.subscriptionFee as num?)?.toDouble()
      ..['total'] = (model.total ?? 0).toDouble()
      ..['vat'] = (model.vat ?? 0).toDouble()
      ..['vatAmount'] = (model.vatAmount ?? 0).toDouble()
      ..['weight'] = (model.weight ?? 0).toDouble();
    final result = await _client.mutate(
      MutationOptions(
        document: gql(ORDER_CREATE_BY_CUSTOMER_MUTATION),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      final errors = result.exception?.graphqlErrors ?? const [];
      throw StateError(
        errors.isEmpty ? 'Store order creation failed.' : errors.first.message,
      );
    }
    final payload = result.data?['selfStoreOrderCreateByCustomer'];
    if (payload is! Map) throw StateError('Store returned no order.');
    final order = OrderCreateRes.fromJson(Map<String, dynamic>.from(payload));
    final orderId = order.id ?? 0;
    if (orderId <= 0) {
      throw StateError('Store returned an invalid order identity.');
    }
    final resellerResult = await _client.query(
      QueryOptions(
        document: _resellerIdentityDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{'siteId': siteId, 'userId': actorUserId},
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    final reseller = resellerResult.data?['resellerByUser'];
    final resellerId = reseller is Map ? '${reseller['id'] ?? ''}'.trim() : '';
    if (resellerResult.hasException || resellerId.isEmpty) {
      throw StateError(
        'Store order exists but reseller attribution is unavailable. Retry to reconcile.',
      );
    }
    final attributionResult = await _client.mutate(
      MutationOptions(
        document: _attributeOrderDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'orderId': orderId,
            'resellerId': resellerId,
            'attributionType': 'sellhub_mobile',
            'resellerCode': '${reseller['code'] ?? ''}'.trim(),
          },
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (attributionResult.hasException ||
        attributionResult.data?['resellerAttributionUpsert'] == null) {
      throw StateError(
        'Store order exists but reseller attribution failed. Retry to reconcile.',
      );
    }
    return order;
  }

  Future<ResellerQuote> createQuote(
    ResellerQuote quote, {
    required int customerId,
  }) async {
    if (customerId <= 0) {
      return _commerceStore.createQuote(quote.copyWith(status: 'offline'));
    }
    final operationKey = 'sellhub-mobile:${quote.siteId}:${quote.id}';
    final result = await _client.mutate(
      MutationOptions(
        document: _createQuoteDocument,
        fetchPolicy: FetchPolicy.networkOnly,
        variables: <String, dynamic>{
          'userId': quote.userId,
          'siteId': quote.siteId,
          'customerId': customerId,
          'data': <String, dynamic>{
            'affiliateCommission': 0.0,
            'cashbackBalance': 0.0,
            'campaignId': null,
            'charge': quote.deliveryCharge.toDouble(),
            'channel': 'sellhub_mobile',
            'cost': quote.baseTotal.toDouble(),
            'currency':
                StoreRegistry.currentStore?.market.currencyCode ?? 'BDT',
            'customerAddress': quote.buyerAddress,
            'customerName': quote.buyerName,
            'customerNote': 'SellHub reseller quote',
            'customerPhone': quote.buyerPhone,
            'deliveryTime': quote.deliveryEstimate,
            'discount': 0.0,
            'discountName': null,
            'emiDuration': 0,
            'emiInterest': 0.0,
            'gatewayText': 'cash_on_delivery',
            'grossAmount': quote.subtotal.toDouble(),
            'idempotencyKey': operationKey,
            'isEmi': false,
            'latitude': 0.0,
            'logisticsCharge': quote.deliveryCharge.toDouble(),
            'logisticsExtraCharge': 0.0,
            'logisticsId': 0,
            'logisticsText': quote.deliveryLabel,
            'longitude': 0.0,
            'netAmount': quote.total.toDouble(),
            'paid': 0.0,
            'profit': quote.profit.toDouble(),
            'referCode': '',
            'resellAmount': quote.total.toDouble(),
            'resellerAdvanceCollect': 0.0,
            'resellerCommission': quote.profit.toDouble(),
            'rewardPoints': 0.0,
            'source': 'sellhub_mobile',
            'total': quote.total.toDouble(),
            'userId': quote.userId,
          },
          'products': quote.lines
              .where((line) => line.productId != null && line.productId! > 0)
              .map(
                (line) => <String, dynamic>{
                  'currency':
                      StoreRegistry.currentStore?.market.currencyCode ?? 'BDT',
                  'id': line.productId,
                  'image': line.thumbnail,
                  'price': line.basePrice.toDouble(),
                  'quantity': line.quantity.toDouble(),
                  'resellPrice': line.sellPrice.toDouble(),
                  'shopId': null,
                  'sku': '',
                  'title': line.title,
                  'unit': 1.0,
                  'unitType': 1,
                  'variant': null,
                },
              )
              .toList(growable: false),
        },
      ),
    );
    if (result.hasException) {
      return _commerceStore.createQuote(quote.copyWith(status: 'offline'));
    }
    final payload = result.data?['selfStoreQuoteCreateByCustomer'];
    if (payload is! Map) {
      return _commerceStore.createQuote(quote.copyWith(status: 'offline'));
    }
    var remote = _quoteFromStore(Map<String, dynamic>.from(payload), quote);
    final remoteQuoteId = int.tryParse('${payload['id'] ?? ''}');
    if (remoteQuoteId != null) {
      final shareResult = await _client.mutate(
        MutationOptions(
          document: _createQuoteShareDocument,
          fetchPolicy: FetchPolicy.networkOnly,
          variables: <String, dynamic>{
            'userId': quote.userId,
            'siteId': quote.siteId,
            'quoteId': remoteQuoteId,
          },
        ),
      );
      final share = shareResult.data?['selfStoreQuoteShareCreate'];
      if (!shareResult.hasException && share is Map) {
        final code = '${share['code'] ?? ''}';
        if (code.isNotEmpty) {
          remote = remote.copyWith(shareCode: code, sharePath: '/quote/$code/');
        }
      }
    }
    return _commerceStore.upsertQuote(remote);
  }

  static ResellerQuote _quoteFromStore(
    Map<String, dynamic> row,
    ResellerQuote fallback,
  ) {
    final lines = ((row['lines'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (line) => ResellerQuoteLine(
            productId: (line['productId'] as num?)?.toInt(),
            title: '${line['productName'] ?? ''}',
            thumbnail: '${line['image'] ?? ''}',
            quantity: (line['quantity'] as num?)?.toInt() ?? 1,
            basePrice: (line['price'] as num?)?.toInt() ?? 0,
            sellPrice: (line['resellPrice'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);
    return ResellerQuote(
      id: '${row['id'] ?? fallback.id}',
      siteId: (row['siteId'] as num?)?.toInt() ?? fallback.siteId,
      userId: (row['userId'] as num?)?.toInt() ?? fallback.userId,
      buyerName: '${row['customerName'] ?? fallback.buyerName}',
      buyerPhone:
          (row['customerPhone'] as num?)?.toInt() ?? fallback.buyerPhone,
      buyerAddress: '${row['customerAddress'] ?? fallback.buyerAddress}',
      deliveryLabel: fallback.deliveryLabel,
      deliveryEstimate: '${row['deliveryTime'] ?? fallback.deliveryEstimate}',
      deliveryCharge:
          (row['logisticsCharge'] as num?)?.toInt() ?? fallback.deliveryCharge,
      subtotal: (row['grossAmount'] as num?)?.toInt() ?? fallback.subtotal,
      total: (row['total'] as num?)?.toInt() ?? fallback.total,
      baseTotal: (row['cost'] as num?)?.toInt() ?? fallback.baseTotal,
      profit: (row['profit'] as num?)?.toInt() ?? fallback.profit,
      createdAt:
          DateTime.tryParse('${row['createdAt'] ?? ''}') ?? fallback.createdAt,
      status: ((row['status'] as num?)?.toInt() ?? 1) == 2
          ? 'converted'
          : 'draft',
      lines: lines.isEmpty ? fallback.lines : lines,
    );
  }

  Future<ResellerQuote> upsertQuote(ResellerQuote quote) {
    if (int.tryParse(quote.id) != null || quote.status != 'offline') {
      throw StateError('Only offline quote drafts can be updated locally.');
    }
    return _commerceStore.upsertQuote(quote);
  }

  Future<void> markQuoteConverted({
    required String quoteId,
    required String orderId,
    required int userId,
    required int siteId,
  }) async {
    final numericQuoteId = int.tryParse(quoteId);
    final numericOrderId = int.tryParse(orderId);
    if (numericQuoteId == null || numericOrderId == null) {
      throw StateError('Store quote or order identity is invalid.');
    }
    final result = await _client.mutate(
      MutationOptions(
        document: _linkQuoteOrderDocument,
        variables: <String, dynamic>{
          'userId': userId,
          'siteId': siteId,
          'quoteId': numericQuoteId,
          'orderId': numericOrderId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException ||
        result.data?['selfStoreQuoteLinkExistingOrder'] == null) {
      final errors = result.exception?.graphqlErrors ?? const [];
      throw StateError(
        errors.isEmpty
            ? 'Quote conversion proof could not be saved.'
            : errors.first.message,
      );
    }
    await _commerceStore.markQuoteConverted(quoteId: quoteId, orderId: orderId);
  }

  Future<bool> deleteQuote(String quoteId) {
    if (int.tryParse(quoteId) != null) {
      throw StateError('Store quotes cannot be deleted from local drafts.');
    }
    return _commerceStore.deleteQuote(quoteId);
  }

  Future<PaymentGatewayResponse> paymentGatewayRequest(
    PaymentGatewayReq model,
  ) async {
    final variables = Map<String, dynamic>.from(model.toJson())
      ..['amount'] = (model.amount ?? 0).toDouble()
      ..['emiInterest'] = (model.emiInterest ?? 0).toDouble();
    final result = await _client.mutate(
      MutationOptions(
        document: _paymentRequestDocument,
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['storeOrderPaymentRequest'];
    if (row is! Map) throw StateError('Store returned no payment request.');
    return PaymentGatewayResponse.fromJson(Map<String, dynamic>.from(row));
  }

  Future<SelfStoreCustomerRes?> fetchCustomerContext({
    required int userId,
    required int siteId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _customerContextDocument,
        variables: <String, dynamic>{
          'userId': userId,
          'siteId': siteId,
          'isActive': true,
          'isReseller': null,
          'isWholesale': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['selfStoreCustomer'];
    return row is Map
        ? SelfStoreCustomerRes.fromJson(Map<String, dynamic>.from(row))
        : null;
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
    final authenticated = userId != null && userId > 0;
    final variables = <String, dynamic>{
      'siteId': siteId,
      'code': code.trim(),
      'quantity': quantity,
      'total': total,
      'delivery': delivery,
      'products': products,
      if (authenticated) 'userId': userId,
    };
    final result = await _client.query(
      QueryOptions(
        document: authenticated
            ? _selfStoreVoucherDocument
            : _storeVoucherDocument,
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row =
        result.data?[authenticated
            ? 'selfStoreVoucherCheckByCode'
            : 'storeVoucherCheckByCode'];
    if (row is! Map) {
      throw StateError('Store returned no voucher decision.');
    }
    return VoucherCheckRes.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<OrderEventModel>> fetchOrderEvents({
    required int siteId,
    required int orderId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _orderEventsDocument,
        variables: <String, dynamic>{
          'siteId': siteId,
          'orderId': orderId,
          'isPublic': true,
          'first': 100,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final edges = result.data?['storeOrderEvents']?['edges'];
    if (edges is! List) return const <OrderEventModel>[];
    return edges
        .whereType<Map>()
        .map((edge) => edge['node'])
        .whereType<Map>()
        .map((row) => OrderEventModel.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
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
        document: _createOrderEventDocument,
        variables: <String, dynamic>{
          'userId': userId,
          'siteId': siteId,
          'orderId': orderId,
          'eventType': eventType,
          'note': note.trim(),
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['selfStoreOrderEventCreateByCustomer'];
    if (row is! Map) throw StateError('Store returned no order event.');
    return OrderEventModel.fromJson(Map<String, dynamic>.from(row));
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
    if (result.hasException) throw result.exception!;
    return result.data?['storeCustomerAddShippingAddress'] == true;
  }

  Future<Map<String, dynamic>?> fetchQuickOrderDraft({
    required int userId,
    required int siteId,
    String? draftId,
  }) async {
    final dynamic store = _commerceStore;
    try {
      final dynamic result = await store.fetchQuickOrderDraft(
        userId: userId,
        siteId: siteId,
        draftId: draftId,
      );
      return _normalizeMap(result);
    } on NoSuchMethodError {
      try {
        final dynamic result = await store.loadQuickOrderDraft(
          userId: userId,
          siteId: siteId,
          draftId: draftId,
        );
        return _normalizeMap(result);
      } on NoSuchMethodError {
        return null;
      }
    }
  }

  Future<Map<String, dynamic>> saveQuickOrderDraft({
    required int userId,
    required int siteId,
    required Map<String, dynamic> draft,
  }) async {
    final payload = <String, dynamic>{
      ...draft,
      'id':
          (draft['id'] ??
                  draft['draftId'] ??
                  _quickOrderDraftId(userId: userId, siteId: siteId))
              .toString(),
      'draftId':
          (draft['draftId'] ??
                  draft['id'] ??
                  _quickOrderDraftId(userId: userId, siteId: siteId))
              .toString(),
      'userId': userId,
      'siteId': siteId,
      'updatedAt':
          (draft['updatedAt'] as String?) ?? DateTime.now().toIso8601String(),
      'storage': (draft['storage'] as String?) ?? 'local-first',
    };
    final dynamic store = _commerceStore;
    try {
      final dynamic result = await store.saveQuickOrderDraft(payload);
      return _normalizeMap(result) ?? payload;
    } on NoSuchMethodError {
      try {
        final dynamic result = await store.upsertQuickOrderDraft(payload);
        return _normalizeMap(result) ?? payload;
      } on NoSuchMethodError {
        return payload;
      }
    }
  }

  Future<bool> deleteQuickOrderDraft({
    required int userId,
    required int siteId,
    String? draftId,
  }) async {
    final dynamic store = _commerceStore;
    try {
      final dynamic result = await store.deleteQuickOrderDraft(
        userId: userId,
        siteId: siteId,
        draftId: draftId,
      );
      return result == true;
    } on NoSuchMethodError {
      try {
        final dynamic result = await store.clearQuickOrderDraft(
          userId: userId,
          siteId: siteId,
          draftId: draftId,
        );
        return result == true;
      } on NoSuchMethodError {
        return true;
      }
    }
  }

  Future<List<QuickOrderDraft>> fetchQuickOrderDrafts({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchResellerQuickOrderDrafts(
      userId: userId,
      siteId: siteId,
    );
  }

  Future<List<OrderGroupDraft>> fetchSupplierOrderGroupDrafts({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchResellerSupplierOrderGroupDrafts(
      userId: userId,
      siteId: siteId,
    );
  }

  Future<Map<String, dynamic>> fetchBuyerRiskDecision({
    required int userId,
    required int siteId,
    required String buyerPhone,
    String? buyerName,
    String? buyerAddress,
    double? orderTotal,
    int? itemCount,
    Map<String, dynamic>? context,
  }) async {
    final normalizedPhone = buyerPhone.trim();
    final normalizedName = (buyerName ?? '').trim();
    final buyerKey = _privacySafeBuyerKey(siteId, normalizedPhone);
    try {
      final result = await _client.query(
        QueryOptions(
          document: _buyerRiskDecisionDocument,
          variables: <String, dynamic>{
            'siteId': siteId,
            'userId': userId,
            'buyerKey': buyerKey,
            'orderTotal': orderTotal,
            'itemCount': itemCount,
            'areaName': context?['deliveryLane']?.toString(),
            'codRequested': true,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) throw result.exception!;
      final raw = result.data?['storeSellhubBuyerRiskDecision'];
      if (raw is Map) {
        final decision = Map<String, dynamic>.from(raw);
        final disposition = '${decision['disposition'] ?? 'review'}';
        return <String, dynamic>{
          ...decision,
          'decision': disposition == 'advance_required'
              ? 'blocked'
              : disposition,
          'requiresManualReview': disposition != 'approved',
          'buyerPhone': '',
          'buyerName': normalizedName,
          'buyerAddress': buyerAddress ?? '',
          'orderTotal': orderTotal ?? 0,
          'itemCount': itemCount ?? 0,
          'context': context ?? const <String, dynamic>{},
        };
      }
    } catch (_) {
      // Store remains authority online; local evaluation is explicit offline fallback.
    }
    final dynamic store = _commerceStore;
    try {
      final dynamic result = await store.fetchBuyerRiskDecision(
        userId: userId,
        siteId: siteId,
        buyerPhone: normalizedPhone,
        buyerName: normalizedName,
        buyerAddress: buyerAddress,
        orderTotal: orderTotal,
        itemCount: itemCount,
        context: context,
      );
      final map = _normalizeMap(result);
      if (map != null) return map;
    } on NoSuchMethodError {
      try {
        final dynamic result = await store.evaluateBuyerRisk(
          userId: userId,
          siteId: siteId,
          buyerPhone: normalizedPhone,
          buyerName: normalizedName,
          buyerAddress: buyerAddress,
          orderTotal: orderTotal,
          itemCount: itemCount,
          context: context,
        );
        final map = _normalizeMap(result);
        if (map != null) return map;
      } on NoSuchMethodError {
        // Fall through to local computation.
      }
    }

    final buyer = await _findBuyer(
      userId: userId,
      siteId: siteId,
      buyerPhone: normalizedPhone,
      buyerName: normalizedName,
    );
    return _buildBuyerRiskDecision(
      buyer: buyer,
      buyerPhone: normalizedPhone,
      buyerName: normalizedName,
      buyerAddress: buyerAddress,
      orderTotal: orderTotal,
      itemCount: itemCount,
      context: context,
    );
  }

  Future<Map<String, dynamic>> previewSupplierSplit({
    required int userId,
    required int siteId,
    required List<Map<String, dynamic>> lines,
    Map<String, dynamic>? draft,
    List<Map<String, dynamic>> supplierHints = const <Map<String, dynamic>>[],
  }) async {
    final dynamic store = _commerceStore;
    try {
      final dynamic result = await store.previewSupplierSplit(
        userId: userId,
        siteId: siteId,
        lines: lines,
        draft: draft,
        supplierHints: supplierHints,
      );
      final map = _normalizeMap(result);
      if (map != null) return map;
    } on NoSuchMethodError {
      try {
        final dynamic result = await store.fetchSupplierSplitPreview(
          userId: userId,
          siteId: siteId,
          lines: lines,
          draft: draft,
          supplierHints: supplierHints,
        );
        final map = _normalizeMap(result);
        if (map != null) return map;
      } on NoSuchMethodError {
        // Fall through to local computation.
      }
    }
    return _buildSupplierSplitPreview(
      userId: userId,
      siteId: siteId,
      lines: lines,
      draft: draft,
      supplierHints: supplierHints,
    );
  }

  Future<BuyerBookProfile?> _findBuyer({
    required int userId,
    required int siteId,
    required String buyerPhone,
    required String buyerName,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _buyerBookDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'includeBlocked': true,
            'limit': 200,
            'offset': 0,
          },
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final rows = result.data?['resellerBuyerBook'];
    if (rows is! List) throw StateError('Store returned no buyer risk data.');
    final candidateKeys = <String>{};
    final normalizedPhone = buyerPhone.replaceAll(RegExp(r'\s+'), '').trim();
    if (normalizedPhone.isNotEmpty && normalizedPhone != '0') {
      candidateKeys.add(_privacySafeBuyerKey(siteId, normalizedPhone));
    }
    if (buyerName.trim().isNotEmpty) {
      candidateKeys.add(
        _privacySafeBuyerKey(siteId, 'name:${buyerName.trim().toLowerCase()}'),
      );
    }
    final row = rows.whereType<Map>().cast<Map>().firstWhere(
      (item) => candidateKeys.contains('${item['buyerKey'] ?? ''}'),
      orElse: () => const <String, dynamic>{},
    );
    if (row.isEmpty) return null;
    final reliability = '${row['reliability'] ?? 'unknown'}'.toLowerCase();
    final orderCount = (row['orderCount'] as num?)?.toInt() ?? 0;
    final totalAmount = (row['totalAmount'] as num?)?.toDouble() ?? 0;
    return BuyerBookProfile(
      id: '${row['buyerKey'] ?? row['id'] ?? ''}',
      name: '${row['buyerLabel'] ?? buyerName}',
      phone: '',
      addresses: const <String>[],
      primaryAddress: '${row['areaName'] ?? ''}',
      note: '${row['notes'] ?? ''}',
      sourceTag: 'Store buyer book',
      isRisky: reliability == 'caution' || reliability == 'disputed',
      isBlocked: row['blocked'] == true || reliability == 'blocked',
      totalOrders: orderCount,
      totalDelivered: 0,
      returnCount: reliability == 'disputed' ? 1 : 0,
      pendingOrders: 0,
      unpaidOrders: 0,
      totalSales: totalAmount,
      averageBasketSize: orderCount > 0 ? totalAmount / orderCount : 0,
      lastOrderedAt: DateTime.tryParse('${row['lastOrderAt'] ?? ''}'),
      profileMetaUpdatedAt: DateTime.tryParse('${row['updatedAt'] ?? ''}'),
      preferredProducts: ((row['preferredProducts'] as List?) ?? const [])
          .map((item) => '$item')
          .toList(growable: false),
      district: '${row['areaName'] ?? ''}',
      deliveryZone: '',
      lastOrderId: row['lastOrderId']?.toString(),
      followUpAt: DateTime.tryParse('${row['followUpAt'] ?? ''}'),
      followUpStatus: '${row['followUpStatus'] ?? 'none'}',
      followUpCompletedAt: DateTime.tryParse(
        '${row['followUpCompletedAt'] ?? ''}',
      ),
      followUpReminderCount:
          (row['followUpReminderCount'] as num?)?.toInt() ?? 0,
      storeBuyerBookId: '${row['id'] ?? ''}',
    );
  }

  static String _privacySafeBuyerKey(int siteId, String value) => sha256
      .convert(utf8.encode('$siteId:${value.trim().toLowerCase()}'))
      .toString();

  Map<String, dynamic> _buildBuyerRiskDecision({
    required BuyerBookProfile? buyer,
    required String buyerPhone,
    required String buyerName,
    String? buyerAddress,
    double? orderTotal,
    int? itemCount,
    Map<String, dynamic>? context,
  }) {
    final reasons = <String>[
      if (buyer?.isBlocked == true) 'Buyer is blocked',
      if (buyer?.isRisky == true) 'Buyer is marked risky',
      if ((buyer?.pendingOrders ?? 0) > 0)
        '${buyer!.pendingOrders} pending orders',
      if ((buyer?.unpaidOrders ?? 0) > 0)
        '${buyer!.unpaidOrders} unpaid orders',
      if ((buyer?.returnCount ?? 0) > 0)
        '${buyer!.returnCount} returned orders',
      if ((orderTotal ?? 0) >= 5000) 'High-value order needs reconfirmation',
      if ((itemCount ?? 0) >= 6) 'Large basket order',
      if ((buyerAddress ?? '').trim().isEmpty && buyer == null)
        'Missing saved delivery address',
    ];
    final riskScore =
        (buyer?.isBlocked == true ? 90 : 0) +
        (buyer?.isRisky == true ? 35 : 0) +
        ((buyer?.pendingOrders ?? 0) * 8) +
        ((buyer?.unpaidOrders ?? 0) * 18) +
        (buyer?.returnRate.round() ?? 0) +
        ((orderTotal ?? 0) >= 5000 ? 10 : 0) +
        ((itemCount ?? 0) >= 6 ? 5 : 0);
    final decision = riskScore >= 90
        ? 'blocked'
        : riskScore >= 45
        ? 'review'
        : 'approved';
    final summary = decision == 'blocked'
        ? 'Manual approval required before supplier order.'
        : decision == 'review'
        ? 'Reconfirm phone, landmark, and COD intent before confirming.'
        : 'Buyer risk is manageable for the current quick-order flow.';
    return <String, dynamic>{
      'decision': decision,
      'riskScore': riskScore,
      'summary': summary,
      'reasons': reasons,
      'requiresManualReview': decision != 'approved',
      'buyer': buyer?.toJson(),
      'buyerPhone': buyerPhone,
      'buyerName': buyerName,
      'buyerAddress': buyerAddress ?? buyer?.primaryAddress ?? '',
      'orderTotal': orderTotal ?? 0,
      'itemCount': itemCount ?? 0,
      'context': context ?? const <String, dynamic>{},
      'evaluatedAt': DateTime.now().toIso8601String(),
      'source': 'local-first',
    };
  }

  Map<String, dynamic> _buildSupplierSplitPreview({
    required int userId,
    required int siteId,
    required List<Map<String, dynamic>> lines,
    Map<String, dynamic>? draft,
    List<Map<String, dynamic>> supplierHints = const <Map<String, dynamic>>[],
  }) {
    final bySupplier = <String, List<Map<String, dynamic>>>{};
    final supplierNames = <String, String>{};
    for (final hint in supplierHints) {
      final key = _supplierKeyFromLine(hint, fallbackSiteId: siteId);
      supplierNames[key] =
          (hint['supplierName'] ?? hint['name'] ?? hint['title'] ?? 'Supplier')
              .toString();
    }
    for (final line in lines) {
      final key = _supplierKeyFromLine(line, fallbackSiteId: siteId);
      bySupplier.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(line);
      supplierNames[key] =
          (line['supplierName'] ??
                  line['siteName'] ??
                  supplierNames[key] ??
                  'Supplier')
              .toString();
    }

    final suppliers =
        bySupplier.entries
            .map((entry) {
              final supplierLines = entry.value;
              final quantity = supplierLines.fold<int>(
                0,
                (sum, item) => sum + _toInt(item['quantity'], fallback: 1),
              );
              final baseAmount = supplierLines.fold<double>(
                0,
                (sum, item) =>
                    sum +
                    (_toDouble(item['basePrice']) *
                        _toInt(item['quantity'], fallback: 1)),
              );
              final sellAmount = supplierLines.fold<double>(
                0,
                (sum, item) =>
                    sum +
                    (_toDouble(item['sellPrice'] ?? item['price']) *
                        _toInt(item['quantity'], fallback: 1)),
              );
              return <String, dynamic>{
                'supplierKey': entry.key,
                'supplierName': supplierNames[entry.key] ?? 'Supplier',
                'siteId': _extractSiteId(entry.key, fallback: siteId),
                'lineCount': supplierLines.length,
                'quantity': quantity,
                'baseAmount': baseAmount,
                'sellAmount': sellAmount,
                'profit': sellAmount - baseAmount,
                'lines': supplierLines,
              };
            })
            .toList(growable: false)
          ..sort(
            (a, b) => _toDouble(
              b['sellAmount'],
            ).compareTo(_toDouble(a['sellAmount'])),
          );

    final totalQuantity = suppliers.fold<int>(
      0,
      (sum, item) => sum + _toInt(item['quantity']),
    );
    final totalBaseAmount = suppliers.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['baseAmount']),
    );
    final totalSellAmount = suppliers.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['sellAmount']),
    );
    return <String, dynamic>{
      'userId': userId,
      'siteId': siteId,
      'draftId': draft?['id'] ?? draft?['draftId'],
      'supplierCount': suppliers.length,
      'lineCount': lines.length,
      'totalQuantity': totalQuantity,
      'totalBaseAmount': totalBaseAmount,
      'totalSellAmount': totalSellAmount,
      'totalProfit': totalSellAmount - totalBaseAmount,
      'suppliers': suppliers,
      'generatedAt': DateTime.now().toIso8601String(),
      'source': 'local-first',
    };
  }

  Map<String, dynamic>? _normalizeMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, dynamic item) => MapEntry('$key', item),
      );
    }
    return null;
  }

  String _quickOrderDraftId({required int userId, required int siteId}) {
    return 'quick-order-$userId-$siteId';
  }

  String _supplierKeyFromLine(
    Map<String, dynamic> line, {
    required int fallbackSiteId,
  }) {
    final supplierId =
        line['supplierId'] ??
        line['siteId'] ??
        line['storeId'] ??
        fallbackSiteId;
    return '${line['supplierKey'] ?? line['supplierCode'] ?? supplierId}';
  }

  int _extractSiteId(String key, {required int fallback}) {
    final parsed = int.tryParse(key);
    return parsed ?? fallback;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }
}
