import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/api/graphql_client_factory.dart';
import 'package:sellhub/core/api/local_graphql_api.dart';
import 'package:sellhub/core/api/local_seed_guard.dart';
import 'package:sellhub/core/local_seed/sellhub_catalog_seed.dart';
import 'package:sellhub/core/pricing/smart_pricing.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart'
    as auth_model;
import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/cart/data/models/delivery_place_res.dart';
import 'package:sellhub/features/cart/data/models/buyer_risk_profile.dart';
import 'package:sellhub/features/cart/data/models/order_group_draft.dart';
import 'package:sellhub/features/cart/data/models/order_create_req.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';
import 'package:sellhub/features/cart/data/models/payment_gateway_response.dart';
import 'package:sellhub/features/cart/data/models/payment_method_res.dart';
import 'package:sellhub/features/cart/data/models/paymentgateway_req.dart';
import 'package:sellhub/features/cart/data/models/quick_order_draft.dart';
import 'package:sellhub/features/cart/data/models/reseller_order_line_draft.dart';
import 'package:sellhub/features/cart/data/models/reseller_quote.dart';
import 'package:sellhub/features/cart/data/models/share_asset_draft.dart';
import 'package:sellhub/features/cart/data/models/voucher_check_res.dart';
import 'package:sellhub/features/orders/data/models/order_event_model.dart';
import 'package:sellhub/features/product/data/models/customer_review_req.dart';
import 'package:sellhub/features/product/data/models/customer_review_res.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/model/payout_adjustment_entry.dart';
import 'package:sellhub/features/profile/data/model/payout_batch_entry.dart';
import 'package:sellhub/features/profile/data/model/payout_dispute_entry.dart';
import 'package:sellhub/features/profile/data/model/profile_res-Model.dart';
import 'package:sellhub/features/profile/data/model/reseller_response_model.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/profile/data/model/team_member_entry.dart';
import 'package:sellhub/features/profile/data/model/team_shared_list_entry.dart';
import 'package:sellhub/features/profile/data/model/team_selling_overview.dart';
import 'package:sellhub/features/profile/data/model/workflow_automation_overview.dart';
import 'package:sellhub/features/profile/data/model/workflow_buyer_segment.dart';
import 'package:sellhub/features/profile/data/model/workflow_pricing_template.dart';
import 'package:sellhub/features/profile/data/model/workflow_recent_pairing.dart';
import 'package:sellhub/features/profile/data/model/workflow_sell_again_suggestion.dart';
import 'package:sellhub/features/profile/data/model/workflow_supplier_bundle.dart';

class SellHubCommerceLocalStore {
  SellHubCommerceLocalStore({required LocalGraphQLApi api})
    : _client = createGraphQLClient(
        endpoint: 'https://example.invalid/graphql',
        link: LocalGraphQLLink(api: api),
      );

  final GraphQLClient _client;
  Future<void>? _seedFuture;

  static const String _seedKey = 'sellhub_commerce_seed';
  static const String _customersCollection = 'commerce_customers';
  static const String _ordersCollection = 'commerce_orders';
  static const String _orderEventsCollection = 'commerce_order_events';
  static const String _quotesCollection = 'commerce_quotes';
  static const String _paymentMethodsCollection = 'commerce_payment_methods';
  static const String _deliveryPlacesCollection = 'commerce_delivery_places';
  static const String _pricingMemoryCollection = 'commerce_pricing_memory';
  static const String _buyerMetaCollection = 'commerce_buyer_meta';
  static const String _payoutBatchesCollection = 'commerce_payout_batches';
  static const String _payoutAdjustmentsCollection =
      'commerce_payout_adjustments';
  static const String _payoutDisputesCollection = 'commerce_payout_disputes';
  static const String _quickOrderDraftsCollection =
      LocalGraphqlCollections.resellerQuickOrderDrafts;
  static const String _buyerRiskProfilesCollection =
      LocalGraphqlCollections.resellerBuyerRiskProfiles;
  static const String _orderGroupDraftsCollection =
      LocalGraphqlCollections.resellerOrderGroupDrafts;
  static const String _shareAssetDraftsCollection =
      LocalGraphqlCollections.resellerShareAssetDrafts;
  static const String _workflowPricingTemplatesCollection =
      'commerce_workflow_pricing_templates';
  static const String _workflowBundlesCollection =
      'commerce_workflow_supplier_bundles';
  static const String _workflowBuyerSegmentsCollection =
      'commerce_workflow_buyer_segments';
  static const String _teamConfigCollection = 'commerce_team_config';
  static const String _teamMembersCollection = 'commerce_team_members';
  static const String _teamSharedListsCollection = 'commerce_team_shared_lists';
  static const String _usersCollection = 'commerce_users';
  static const String _authMetaCollection = 'commerce_auth_meta';
  static const String _reviewsCollection = 'commerce_reviews';
  static const String _seedVersion = 'commerce_v8';

  static const int demoUserId = 10001;
  static const String demoPassword = '123456';
  static const int demoOtp = 1234;

  static final _listCollectionDocument = gql(r'''
    query ListCollection($collection: String!) {
      listCollection(collection: $collection) {
        id
        payload
      }
    }
  ''');

  static final _getEntityDocument = gql(r'''
    query GetEntity($collection: String!, $id: String!) {
      getEntity(collection: $collection, id: $id) {
        id
        payload
      }
    }
  ''');

  static final _replaceCollectionDocument = gql(r'''
    mutation ReplaceCollection(
      $collection: String!
      $entities: [LocalEntityInput!]!
    ) {
      replaceCollection(collection: $collection, entities: $entities) {
        count
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

  static final _deleteEntityDocument = gql(r'''
    mutation DeleteEntity($collection: String!, $id: String!) {
      deleteEntity(collection: $collection, id: $id) {
        id
        deleted
      }
    }
  ''');

  Future<void> ensureSeeded() {
    final existing = _seedFuture;
    if (existing != null) return existing;
    final future = _ensureSeededInternal().whenComplete(() {
      _seedFuture = null;
    });
    _seedFuture = future;
    return future;
  }

  Future<auth_model.User?> checkUser(String phoneOrUsername) async {
    await ensureSeeded();
    final normalized = phoneOrUsername.trim();
    final users = await _loadCollection(_usersCollection);
    for (final user in users) {
      final phone = (user['phone'] ?? '').toString();
      final username = (user['username'] ?? '').toString();
      if (phone == normalized || username == normalized) {
        return auth_model.User.fromJson(user);
      }
    }
    return null;
  }

  Future<String> login(String id, String password) async {
    await ensureSeeded();
    final auth = await _loadEntity(_authMetaCollection, id);
    if (auth == null) return '';
    if ((auth['password'] ?? '').toString() != password) return '';
    return 'local-token-$id';
  }

  Future<auth_model.User?> register(SignUpReq model) async {
    await ensureSeeded();
    final users = await _loadCollection(_usersCollection);
    final maxId = users
        .map((item) => (item['id'] as num?)?.toInt() ?? 0)
        .fold<int>(
          demoUserId,
          (value, element) => element > value ? element : value,
        );
    final userId = maxId + 1;
    final normalizedPhone = '88${model.phone ?? userId}';
    final userJson = <String, dynamic>{
      'id': userId,
      'name': model.name ?? 'New Seller',
      'username': model.username ?? normalizedPhone,
      'phone': normalizedPhone,
      'email': '${model.username ?? 'seller$userId'}@sellhub.local',
      'address': 'Dhaka, Bangladesh',
      'avatar': null,
      'country': model.country ?? 50,
      'currency': model.currency ?? 'BDT',
      'firstName': model.firstName ?? 'Seller',
      'formattedAddress': 'Dhaka, Bangladesh',
      'isStaff': false,
      'isActive': true,
      'latitude': 23.8103,
      'longitude': 90.4125,
      'referCode': 'SH$userId',
      'referedCode': model.referedCode,
    };
    await _upsertEntity(_usersCollection, '$userId', userJson);
    await _upsertEntity(_authMetaCollection, '$userId', <String, dynamic>{
      'id': userId,
      'password': model.password ?? demoPassword,
      'otp': demoOtp,
    });
    for (final supplier in SellHubCatalogSeed.suppliers) {
      final siteId = (supplier['id'] as num).toInt();
      final customerJson = _seedCustomer(
        id: userId * 10 + siteId,
        userId: userId,
        siteId: siteId,
        title: model.name ?? 'New Seller',
        phone: int.tryParse(normalizedPhone) ?? 8801700000000,
      );
      await _upsertEntity(
        _customersCollection,
        _customerKey(siteId, userId),
        customerJson,
      );
    }
    return auth_model.User.fromJson(userJson);
  }

  Future<auth_model.User?> sendOtp(
    int userId,
    String source,
    int sourceId,
  ) async {
    await ensureSeeded();
    final user = await _loadEntity(_usersCollection, '$userId');
    if (user == null) return null;
    await _upsertEntity(_authMetaCollection, '$userId', <String, dynamic>{
      'id': userId,
      'password':
          ((await _loadEntity(_authMetaCollection, '$userId'))?['password'] ??
          demoPassword),
      'otp': demoOtp,
      'source': source,
      'sourceId': sourceId,
    });
    return auth_model.User.fromJson(user);
  }

  Future<auth_model.User?> verifyOtp(int userId, int otp) async {
    await ensureSeeded();
    final auth = await _loadEntity(_authMetaCollection, '$userId');
    if (auth == null) return null;
    if ((auth['otp'] as num?)?.toInt() != otp) return null;
    final user = await _loadEntity(_usersCollection, '$userId');
    return user == null ? null : auth_model.User.fromJson(user);
  }

  Future<auth_model.User?> resetPassword(
    int userId,
    String phone,
    int otp,
    String newPassword,
  ) async {
    final user = await verifyOtp(userId, otp);
    if (user == null) return null;
    await _upsertEntity(_authMetaCollection, '$userId', <String, dynamic>{
      'id': userId,
      'password': newPassword,
      'otp': demoOtp,
      'phone': phone,
    });
    return user;
  }

  Future<ProfileResModel?> fetchProfileDetails(int customerId) async {
    await ensureSeeded();
    final customer = await _loadCustomerById(customerId);
    if (customer == null) return null;
    return ProfileResModel.fromJson(_customerToProfileJson(customer));
  }

  Future<List<OrderHistoryResModelProfile>> fetchOrderHistory(
    int siteId,
    int customerId,
  ) async {
    await ensureSeeded();
    final orders = await _loadCollection(_ordersCollection);
    return orders
        .where(
          (item) =>
              (item['siteId'] as num?)?.toInt() == siteId &&
              (item['customerId'] as num?)?.toInt() == customerId,
        )
        .toList(growable: false)
        .reversed
        .map((item) => OrderHistoryResModelProfile.fromJson(item))
        .toList(growable: false);
  }

  Future<ResellerResModelProfile?> fetchResellerInformation(
    int customerId,
  ) async {
    await ensureSeeded();
    final customer = await _loadCustomerById(customerId);
    if (customer == null) return null;
    return ResellerResModelProfile.fromJson(_customerToResellerJson(customer));
  }

  Future<bool> makeResellerRequest({
    required int userId,
    required int customerId,
    required String title,
    required String paymentTitle,
    required String paymentNo,
  }) async {
    final customer = await _loadCustomerById(customerId);
    if (customer == null) return false;
    customer['isReseller'] = true;
    customer['title'] = title;
    customer['paymentTitle'] = paymentTitle;
    customer['paymentNo'] = paymentNo;
    customer['userId'] = userId;
    await _upsertEntity(
      _customersCollection,
      _customerKey(
        (customer['siteId'] as num?)?.toInt() ?? 0,
        (customer['userId'] as num?)?.toInt() ?? userId,
      ),
      customer,
    );
    return true;
  }

  Future<SelfStoreCustomerRes?> fetchSelfStoreCustomer(
    int userId,
    int siteId,
  ) async {
    await ensureSeeded();
    final customer = await _loadEntity(
      _customersCollection,
      _customerKey(siteId, userId),
    );
    if (customer == null) return null;
    return SelfStoreCustomerRes.fromJson(_customerToSelfJson(customer));
  }

  Future<bool> addFavorite({
    required int userId,
    required int customerId,
    required int productId,
  }) {
    return _mutateCustomer(
      customerId: customerId,
      userId: userId,
      mutate: (customer) {
        final favorites =
            (customer['favorite'] as List<dynamic>? ?? <dynamic>[])
                .map((item) => (item as num).toInt())
                .toSet();
        favorites.add(productId);
        customer['favorite'] = favorites.toList(growable: false);
      },
    );
  }

  Future<bool> removeFavorite({
    required int userId,
    required int customerId,
    required int productId,
  }) {
    return _mutateCustomer(
      customerId: customerId,
      userId: userId,
      mutate: (customer) {
        final favorites =
            (customer['favorite'] as List<dynamic>? ?? <dynamic>[])
                .map((item) => (item as num).toInt())
                .where((item) => item != productId)
                .toList(growable: false);
        customer['favorite'] = favorites;
      },
    );
  }

  Future<bool> addShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _updateAddressBook(
      customerId: customerId,
      address: address,
      key: 'shippingAddress',
      add: true,
    );
  }

  Future<bool> removeShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _updateAddressBook(
      customerId: customerId,
      address: address,
      key: 'shippingAddress',
      add: false,
    );
  }

  Future<bool> addBillingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _updateAddressBook(
      customerId: customerId,
      address: address,
      key: 'billingAddress',
      add: true,
    );
  }

  Future<bool> removeBillingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _updateAddressBook(
      customerId: customerId,
      address: address,
      key: 'billingAddress',
      add: false,
    );
  }

  Future<bool> passwordChange(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final auth = await _loadEntity(_authMetaCollection, '$userId');
    if (auth == null) return false;
    if ((auth['password'] ?? '').toString() != oldPassword) return false;
    auth['password'] = newPassword;
    await _upsertEntity(_authMetaCollection, '$userId', auth);
    return true;
  }

  Future<List<DeliveryPlaceRes>> fetchDeliveryPlace(int siteUserId) async {
    await ensureSeeded();
    final places = await _loadCollection(_deliveryPlacesCollection);
    return places
        .map((item) => DeliveryPlaceRes.fromJson(item))
        .toList(growable: false);
  }

  Future<List<PaymentMethodRes>> fetchPaymentMethod(int siteId) async {
    await ensureSeeded();
    final methods = await _loadCollection(_paymentMethodsCollection);
    final filtered = siteId <= 0
        ? methods
        : methods.where((item) => (item['siteId'] as num?)?.toInt() == siteId);
    return filtered
        .map((item) {
          final copy = Map<String, dynamic>.from(item)..remove('siteId');
          return PaymentMethodRes.fromJson(copy);
        })
        .toList(growable: false);
  }

  Future<Map<int, ProductPricingMemory>> fetchPricingMemories({
    required int userId,
    required int siteId,
    required List<int> productIds,
  }) async {
    await ensureSeeded();
    final requested = productIds.where((item) => item > 0).toSet();
    if (requested.isEmpty) return const <int, ProductPricingMemory>{};
    final memories = await _loadCollection(_pricingMemoryCollection);
    final result = <int, ProductPricingMemory>{};
    for (final item in memories) {
      final productId = (item['productId'] as num?)?.toInt() ?? 0;
      if (!requested.contains(productId)) continue;
      if ((item['userId'] as num?)?.toInt() != userId) continue;
      if (siteId > 0 && (item['siteId'] as num?)?.toInt() != siteId) continue;
      result[productId] = ProductPricingMemory.fromJson(item);
    }
    return result;
  }

  Future<List<BuyerBookProfile>> fetchBuyerBook({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final orders = await _loadCollection(_ordersCollection);
    final buyerMeta = await _loadCollection(_buyerMetaCollection);
    final relevantOrders = orders
        .where(
          (item) =>
              (item['siteId'] as num?)?.toInt() == siteId &&
              (item['userId'] as num?)?.toInt() == userId,
        )
        .toList(growable: false);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final order in relevantOrders) {
      final key = _buyerIdentityKey(
        phone: '${order['customerPhone'] ?? ''}',
        name: (order['customerName'] as String?) ?? '',
      );
      grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(order);
    }

    final buyers =
        grouped.entries
            .map((entry) {
              final items = entry.value.toList(growable: false)
                ..sort(
                  (a, b) =>
                      (DateTime.tryParse((b['updatedAt'] as String?) ?? '') ??
                              DateTime(2000))
                          .compareTo(
                            DateTime.tryParse(
                                  (a['updatedAt'] as String?) ?? '',
                                ) ??
                                DateTime(2000),
                          ),
                );
              final latest = items.first;
              final meta =
                  buyerMeta.cast<Map<String, dynamic>?>().firstWhere(
                    (item) => item?['id'] == entry.key,
                    orElse: () => null,
                  ) ??
                  const <String, dynamic>{};
              final addresses = items
                  .map(
                    (item) =>
                        ((item['customerAddress'] as String?) ?? '').trim(),
                  )
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .toList(growable: false);
              final totalOrders = items.length;
              final totalSales = items.fold<double>(
                0,
                (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0),
              );
              final address = addresses.isNotEmpty
                  ? addresses.first
                  : 'No saved address';
              return BuyerBookProfile(
                id: entry.key,
                name:
                    ((latest['customerName'] as String?)?.trim().isNotEmpty ??
                        false)
                    ? (latest['customerName'] as String).trim()
                    : 'Unnamed buyer',
                phone: '${latest['customerPhone'] ?? ''}'.trim(),
                addresses: addresses,
                primaryAddress: address,
                note:
                    (meta['note'] as String?) ??
                    ((latest['customerNote'] as String?) ?? ''),
                sourceTag:
                    (meta['sourceTag'] as String?) ?? _inferSourceTag(items),
                isRisky:
                    meta['isRisky'] == true ||
                    items.where(_isReturnedOrder).isNotEmpty,
                isBlocked: meta['isBlocked'] == true,
                totalOrders: totalOrders,
                totalDelivered: items.where(_isDeliveredOrder).length,
                returnCount: items.where(_isReturnedOrder).length,
                pendingOrders: items
                    .where((item) => !_isDeliveredOrder(item))
                    .length,
                unpaidOrders: items
                    .where((item) => item['isSettle'] != true)
                    .length,
                totalSales: totalSales,
                averageBasketSize: totalOrders == 0
                    ? 0
                    : totalSales / totalOrders,
                lastOrderedAt: DateTime.tryParse(
                  (latest['updatedAt'] as String?) ?? '',
                ),
                profileMetaUpdatedAt: DateTime.tryParse(
                  (meta['updatedAt'] as String?) ?? '',
                ),
                preferredProducts: _collectPreferredProducts(items),
                district: _extractDistrict(address),
                deliveryZone: ((latest['logisticsText'] as String?) ?? '')
                    .trim(),
                lastOrderId: latest['orderId'] as String?,
              );
            })
            .toList(growable: false)
          ..sort(
            (a, b) => (b.lastOrderedAt ?? DateTime(2000)).compareTo(
              a.lastOrderedAt ?? DateTime(2000),
            ),
          );

    return buyers;
  }

  Future<List<PayoutBatchEntry>> fetchPayoutBatches({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final batches = await _loadCollection(_payoutBatchesCollection);
    return batches
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(PayoutBatchEntry.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
          a.createdAt ?? DateTime(2000),
        ),
      );
  }

  Future<PayoutBatchEntry> upsertPayoutBatch(PayoutBatchEntry entry) async {
    await ensureSeeded();
    await _upsertEntity(_payoutBatchesCollection, entry.id, entry.toJson());
    return entry;
  }

  Future<bool> deletePayoutBatch(String id) async {
    await ensureSeeded();
    return _deleteEntity(_payoutBatchesCollection, id);
  }

  Future<List<PayoutAdjustmentEntry>> fetchPayoutAdjustments({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final adjustments = await _loadCollection(_payoutAdjustmentsCollection);
    return adjustments
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(PayoutAdjustmentEntry.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
          a.createdAt ?? DateTime(2000),
        ),
      );
  }

  Future<PayoutAdjustmentEntry> upsertPayoutAdjustment(
    PayoutAdjustmentEntry entry,
  ) async {
    await ensureSeeded();
    await _upsertEntity(_payoutAdjustmentsCollection, entry.id, entry.toJson());
    return entry;
  }

  Future<bool> deletePayoutAdjustment(String id) async {
    await ensureSeeded();
    return _deleteEntity(_payoutAdjustmentsCollection, id);
  }

  Future<List<PayoutDisputeEntry>> fetchPayoutDisputes({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final disputes = await _loadCollection(_payoutDisputesCollection);
    return disputes
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(PayoutDisputeEntry.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<PayoutDisputeEntry> upsertPayoutDispute(
    PayoutDisputeEntry entry,
  ) async {
    await ensureSeeded();
    await _upsertEntity(_payoutDisputesCollection, entry.id, entry.toJson());
    return entry;
  }

  Future<bool> deletePayoutDispute(String id) async {
    await ensureSeeded();
    return _deleteEntity(_payoutDisputesCollection, id);
  }

  Future<PayoutDisputeEntry> reportPayoutDispute({
    required int userId,
    required int siteId,
    required String orderId,
    String? batchId,
    required String reason,
    required String note,
  }) async {
    await ensureSeeded();
    final disputes = await _loadCollection(_payoutDisputesCollection);
    final nextId =
        disputes
            .map((item) => int.tryParse('${item['id'] ?? 0}') ?? 0)
            .fold<int>(
              70000,
              (value, element) => element > value ? element : value,
            ) +
        1;
    final now = DateTime.now();
    final dispute = PayoutDisputeEntry(
      id: '$nextId',
      userId: userId,
      siteId: siteId,
      orderId: orderId,
      batchId: batchId,
      status: 'open',
      reason: reason,
      note: note.trim().isEmpty
          ? 'Seller reported a payout mismatch from the payout ledger.'
          : note.trim(),
      createdAt: now,
      updatedAt: now,
    );
    return upsertPayoutDispute(dispute);
  }

  Future<List<WorkflowPricingTemplate>> fetchWorkflowPricingTemplates({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_workflowPricingTemplatesCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(WorkflowPricingTemplate.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<WorkflowPricingTemplate> upsertWorkflowPricingTemplate(
    WorkflowPricingTemplate template,
  ) async {
    await ensureSeeded();
    await _upsertEntity(
      _workflowPricingTemplatesCollection,
      template.id,
      template.toJson(),
    );
    return template;
  }

  Future<bool> deleteWorkflowPricingTemplate(String id) async {
    await ensureSeeded();
    return _deleteEntity(_workflowPricingTemplatesCollection, id);
  }

  Future<List<WorkflowSupplierBundle>> fetchWorkflowSupplierBundles({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_workflowBundlesCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(WorkflowSupplierBundle.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<WorkflowSupplierBundle> upsertWorkflowSupplierBundle(
    WorkflowSupplierBundle bundle,
  ) async {
    await ensureSeeded();
    await _upsertEntity(_workflowBundlesCollection, bundle.id, bundle.toJson());
    return bundle;
  }

  Future<bool> deleteWorkflowSupplierBundle(String id) async {
    await ensureSeeded();
    return _deleteEntity(_workflowBundlesCollection, id);
  }

  Future<List<WorkflowBuyerSegment>> fetchWorkflowBuyerSegments({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_workflowBuyerSegmentsCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(WorkflowBuyerSegment.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<WorkflowBuyerSegment> upsertWorkflowBuyerSegment(
    WorkflowBuyerSegment segment,
  ) async {
    await ensureSeeded();
    await _upsertEntity(
      _workflowBuyerSegmentsCollection,
      segment.id,
      segment.toJson(),
    );
    return segment;
  }

  Future<bool> deleteWorkflowBuyerSegment(String id) async {
    await ensureSeeded();
    return _deleteEntity(_workflowBuyerSegmentsCollection, id);
  }

  Future<WorkflowAutomationOverview> fetchWorkflowAutomationOverview({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final templates = await fetchWorkflowPricingTemplates(
      userId: userId,
      siteId: siteId,
    );
    final bundles = await fetchWorkflowSupplierBundles(
      userId: userId,
      siteId: siteId,
    );
    final savedSegments = await fetchWorkflowBuyerSegments(
      userId: userId,
      siteId: siteId,
    );
    final buyers = await fetchBuyerBook(userId: userId, siteId: siteId);
    final orders =
        (await _loadCollection(_ordersCollection))
            .where(
              (item) =>
                  (item['siteId'] as num?)?.toInt() == siteId &&
                  (item['userId'] as num?)?.toInt() == userId,
            )
            .toList(growable: false)
          ..sort(
            (a, b) =>
                (DateTime.tryParse((b['updatedAt'] as String?) ?? '') ??
                        DateTime(2000))
                    .compareTo(
                      DateTime.tryParse((a['updatedAt'] as String?) ?? '') ??
                          DateTime(2000),
                    ),
          );

    final recentPairings = <WorkflowRecentPairing>[];
    for (final order in orders.take(8)) {
      final lines = (order['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      if (lines.isEmpty) continue;
      final firstLine = lines.first;
      recentPairings.add(
        WorkflowRecentPairing(
          buyerId: _buyerIdentityKey(
            phone: '${order['customerPhone'] ?? ''}',
            name: (order['customerName'] as String?) ?? '',
          ),
          buyerName: (order['customerName'] as String?) ?? 'Buyer',
          buyerPhone: '${order['customerPhone'] ?? ''}',
          buyerAddress: (order['customerAddress'] as String?) ?? '',
          productTitle: (firstLine['title'] as String?) ?? 'Product',
          sellPrice:
              (firstLine['price'] as num?)?.toDouble() ??
              (order['total'] as num?)?.toDouble() ??
              0,
          orderId: (order['orderId'] as String?) ?? 'Order',
          updatedAt: DateTime.tryParse((order['updatedAt'] as String?) ?? ''),
        ),
      );
    }

    final deliveredOrders = orders
        .where(_isDeliveredOrder)
        .toList(growable: false);
    final sellAgainFrequency = <String, int>{};
    final sellAgainSuggestionMap = <String, WorkflowSellAgainSuggestion>{};
    for (final order in deliveredOrders) {
      final lines = (order['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      for (final line in lines) {
        final title = (line['title'] as String?)?.trim() ?? '';
        if (title.isEmpty) continue;
        sellAgainFrequency[title] = (sellAgainFrequency[title] ?? 0) + 1;
        sellAgainSuggestionMap[title] = WorkflowSellAgainSuggestion(
          productTitle: title,
          lastBuyerName: (order['customerName'] as String?) ?? 'Buyer',
          lastBuyerPhone: '${order['customerPhone'] ?? ''}',
          lastBuyerAddress: (order['customerAddress'] as String?) ?? '',
          lastSellPrice:
              (line['price'] as num?)?.toDouble() ??
              (order['total'] as num?)?.toDouble() ??
              0,
          repeatCount: sellAgainFrequency[title] ?? 1,
          lastOrderedAt: DateTime.tryParse(
            (order['updatedAt'] as String?) ?? '',
          ),
          reason: (sellAgainFrequency[title] ?? 1) >= 2
              ? 'Delivered more than once. Good candidate to sell again.'
              : 'Recently delivered. Easy follow-up product for repeat selling.',
        );
      }
    }
    final sellAgainSuggestions = sellAgainSuggestionMap.values.toList(
      growable: false,
    )..sort((a, b) => b.repeatCount.compareTo(a.repeatCount));

    final derivedSegments = <WorkflowBuyerSegment>[
      WorkflowBuyerSegment(
        id: 'auto-repeat-$siteId',
        userId: userId,
        siteId: siteId,
        name: 'Repeat buyers',
        description: 'Buyers with two or more orders. Best for quick reorder.',
        buyerCount: buyers.where((item) => item.isRepeatBuyer).length,
        updatedAt: DateTime.now(),
      ),
      WorkflowBuyerSegment(
        id: 'auto-high-value-$siteId',
        userId: userId,
        siteId: siteId,
        name: 'High value buyers',
        description: 'Average basket over ৳1000. Good for premium offers.',
        buyerCount: buyers
            .where((item) => item.averageBasketSize >= 1000)
            .length,
        updatedAt: DateTime.now(),
      ),
      WorkflowBuyerSegment(
        id: 'auto-risky-$siteId',
        userId: userId,
        siteId: siteId,
        name: 'Risky follow-up',
        description: 'Pending, unpaid, or risky buyers needing manual care.',
        buyerCount: buyers
            .where((item) => item.isRisky || item.hasPendingBuyerRisk)
            .length,
        updatedAt: DateTime.now(),
      ),
    ];

    return WorkflowAutomationOverview(
      pricingTemplates: templates,
      supplierBundles: bundles,
      buyerSegments: <WorkflowBuyerSegment>[
        ...savedSegments,
        ...derivedSegments,
      ],
      recentPairings: recentPairings,
      sellAgainSuggestions: sellAgainSuggestions
          .take(6)
          .toList(growable: false),
    );
  }

  Future<TeamSellingOverview> fetchTeamSellingOverview({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final config =
        await _loadEntity(_teamConfigCollection, _teamConfigKey(userId, siteId)) ??
        <String, dynamic>{
          'id': _teamConfigKey(userId, siteId),
          'teamId': 'team-$siteId-$userId',
          'ownerUserId': userId,
          'siteId': siteId,
          'teamName': 'SellHub Team',
          'ownerName': 'Team owner',
          'overridePercent': 4,
          'transparentPayoutRule':
              'Override applies only to direct team sales. No multi-level payouts.',
        };
    final members = (await _loadCollection(_teamMembersCollection))
        .where(
          (item) =>
              (item['ownerUserId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId &&
              (item['teamId'] as String?) == config['teamId'],
        )
        .map(TeamMemberEntry.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.lastActiveAt ?? DateTime(2000)).compareTo(
          a.lastActiveAt ?? DateTime(2000),
        ),
      );
    final sharedLists = (await _loadCollection(_teamSharedListsCollection))
        .where(
          (item) =>
              (item['ownerUserId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId &&
              (item['teamId'] as String?) == config['teamId'],
        )
        .map(TeamSharedListEntry.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );

    final activeMembers = members.where((item) => item.isActive).length;
    final pendingInvites = members.where((item) => item.isPending).length;
    final teamOrderVolume = members.fold<double>(
      0,
      (sum, item) => sum + item.orderVolume,
    );
    final overrideEarned = members.fold<double>(
      0,
      (sum, item) => sum + item.overrideGenerated,
    );
    final distributedProductCount = sharedLists
        .expand((item) => item.productTitles)
        .toSet()
        .length;

    return TeamSellingOverview(
      teamId: (config['teamId'] as String?) ?? 'team-$siteId-$userId',
      ownerUserId: userId,
      siteId: siteId,
      teamName: (config['teamName'] as String?) ?? 'SellHub Team',
      ownerName: (config['ownerName'] as String?) ?? 'Team owner',
      overridePercent: (config['overridePercent'] as num?)?.toDouble() ?? 0,
      transparentPayoutRule:
          (config['transparentPayoutRule'] as String?) ??
          'Override applies only to direct team sales. No hidden chain payouts.',
      activeMembers: activeMembers,
      pendingInvites: pendingInvites,
      teamOrderVolume: teamOrderVolume,
      overrideEarned: overrideEarned,
      sharedListCount: sharedLists.length,
      distributedProductCount: distributedProductCount,
      members: members,
      sharedLists: sharedLists,
    );
  }

  Future<void> upsertTeamConfig({
    required int userId,
    required int siteId,
    required String teamId,
    required String teamName,
    required String ownerName,
    required double overridePercent,
  }) async {
    await ensureSeeded();
    await _upsertEntity(
      _teamConfigCollection,
      _teamConfigKey(userId, siteId),
      <String, dynamic>{
        'id': _teamConfigKey(userId, siteId),
        'teamId': teamId,
        'ownerUserId': userId,
        'siteId': siteId,
        'teamName': teamName,
        'ownerName': ownerName,
        'overridePercent': overridePercent,
        'transparentPayoutRule':
            'Override applies only to direct team sales. No multi-level payouts.',
      },
    );
  }

  Future<TeamMemberEntry> upsertTeamMember(TeamMemberEntry member) async {
    await ensureSeeded();
    await _upsertEntity(_teamMembersCollection, member.id, member.toJson());
    return member;
  }

  Future<TeamMemberEntry?> fetchTeamMember(String id) async {
    await ensureSeeded();
    final entity = await _loadEntity(_teamMembersCollection, id);
    return entity == null ? null : TeamMemberEntry.fromJson(entity);
  }

  Future<TeamMemberEntry> acceptTeamInvite({
    required String memberId,
    required String teamId,
    required int ownerUserId,
    required int siteId,
    String? sellerName,
    String? sellerPhone,
  }) async {
    await ensureSeeded();
    final entity = await _loadEntity(_teamMembersCollection, memberId);
    final now = DateTime.now();
    final member = TeamMemberEntry(
      id: memberId,
      teamId: teamId,
      ownerUserId: ownerUserId,
      siteId: siteId,
      name: sellerName?.trim().isNotEmpty == true
          ? sellerName!.trim()
          : (entity?['name'] as String?) ?? 'Seller',
      phone: sellerPhone?.trim().isNotEmpty == true
          ? sellerPhone!.trim()
          : (entity?['phone'] as String?) ?? '',
      status: 'active',
      role: (entity?['role'] as String?) ?? 'team_seller',
      orderVolume: (entity?['orderVolume'] as num?)?.toDouble() ?? 0,
      overrideGenerated:
          (entity?['overrideGenerated'] as num?)?.toDouble() ?? 0,
      topProduct: (entity?['topProduct'] as String?) ?? '',
      joinedAt:
          DateTime.tryParse((entity?['joinedAt'] as String?) ?? '') ?? now,
      lastActiveAt: now,
    );
    await _upsertEntity(_teamMembersCollection, member.id, member.toJson());
    return member;
  }

  Future<bool> deleteTeamMember(String id) async {
    await ensureSeeded();
    return _deleteEntity(_teamMembersCollection, id);
  }

  Future<TeamSharedListEntry> upsertTeamSharedList(
    TeamSharedListEntry entry,
  ) async {
    await ensureSeeded();
    await _upsertEntity(_teamSharedListsCollection, entry.id, entry.toJson());
    return entry;
  }

  Future<bool> deleteTeamSharedList(String id) async {
    await ensureSeeded();
    return _deleteEntity(_teamSharedListsCollection, id);
  }

  Future<Map<String, dynamic>?> fetchQuickOrderDraft({
    required int userId,
    required int siteId,
    String? draftId,
  }) async {
    if ((draftId?.trim().isNotEmpty ?? false)) {
      final draft = await fetchResellerQuickOrderDraft(draftId!.trim());
      if (draft != null && draft.userId == userId && draft.siteId == siteId) {
        return draft.toJson();
      }
    }
    final drafts = await fetchResellerQuickOrderDrafts(
      userId: userId,
      siteId: siteId,
    );
    return drafts.isEmpty ? null : drafts.first.toJson();
  }

  Future<Map<String, dynamic>> saveQuickOrderDraft(
    Map<String, dynamic> payload,
  ) async {
    final draft = QuickOrderDraft.fromJson(payload);
    final saved = await upsertResellerQuickOrderDraft(draft);
    return saved.toJson();
  }

  Future<bool> deleteQuickOrderDraft({
    required int userId,
    required int siteId,
    String? draftId,
  }) async {
    if ((draftId?.trim().isNotEmpty ?? false)) {
      return deleteResellerQuickOrderDraft(draftId!.trim());
    }
    final drafts = await fetchResellerQuickOrderDrafts(
      userId: userId,
      siteId: siteId,
    );
    if (drafts.isEmpty) return true;
    return deleteResellerQuickOrderDraft(drafts.first.id);
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
    await ensureSeeded();
    final buyers = await fetchBuyerBook(userId: userId, siteId: siteId);
    BuyerBookProfile? matchedBuyer;
    for (final buyer in buyers) {
      if (buyerPhone.trim().isNotEmpty &&
          _normalizeIdentity(buyer.phone) == _normalizeIdentity(buyerPhone)) {
        matchedBuyer = buyer;
        break;
      }
    }
    if (matchedBuyer == null && (buyerName?.trim().isNotEmpty ?? false)) {
      for (final buyer in buyers) {
        if (_normalizeIdentity(buyer.name) ==
            _normalizeIdentity(buyerName!.trim())) {
          matchedBuyer = buyer;
          break;
        }
      }
    }

    final storedProfile = await fetchResellerBuyerRiskProfile(
      buyerId: matchedBuyer?.id ??
          _buyerIdentityKey(phone: buyerPhone, name: buyerName ?? ''),
      userId: userId,
      siteId: siteId,
    );
    final profile = storedProfile ??
        (matchedBuyer == null
            ? BuyerRiskProfile(
                id: _buyerIdentityKey(phone: buyerPhone, name: buyerName ?? ''),
                userId: userId,
                siteId: siteId,
                buyerName: (buyerName?.trim().isNotEmpty ?? false)
                    ? buyerName!.trim()
                    : 'Buyer',
                buyerPhone: buyerPhone.trim(),
                riskLevel: (orderTotal ?? 0) >= 5000 ? 'medium' : 'low',
                riskScore: (orderTotal ?? 0) >= 5000 ? 20 : 0,
                blocked: false,
                note: '',
                reasonCodes: <String>[
                  if ((buyerAddress ?? '').trim().isEmpty) 'missing_address',
                  if ((orderTotal ?? 0) >= 5000) 'high_value_order',
                  if ((itemCount ?? 0) >= 6) 'large_basket',
                ],
                recommendedAction: (orderTotal ?? 0) >= 5000
                    ? 'Reconfirm buyer phone and address before placing supplier order.'
                    : 'Buyer can proceed through the normal reseller order flow.',
                totalOrders: 0,
                deliveredOrders: 0,
                returnCount: 0,
                pendingOrders: 0,
                unpaidOrders: 0,
                lastOrderId: null,
                updatedAt: DateTime.now(),
              )
            : _deriveBuyerRiskProfile(matchedBuyer, userId, siteId));

    final escalatedScore =
        profile.riskScore +
        ((orderTotal ?? 0) >= 5000 ? 10 : 0) +
        ((itemCount ?? 0) >= 6 ? 5 : 0);
    final decision = profile.blocked || escalatedScore >= 90
        ? 'blocked'
        : escalatedScore >= 45
        ? 'review'
        : 'approved';
    final reasons = {
      ...profile.reasonCodes,
      if ((orderTotal ?? 0) >= 5000) 'high_value_order',
      if ((itemCount ?? 0) >= 6) 'large_basket',
    }.toList(growable: false);

    final updatedProfile = BuyerRiskProfile(
      id: profile.id,
      userId: profile.userId,
      siteId: profile.siteId,
      buyerName: profile.buyerName,
      buyerPhone: profile.buyerPhone,
      riskLevel: decision == 'approved'
          ? 'low'
          : decision == 'review'
          ? 'medium'
          : 'high',
      riskScore: escalatedScore,
      blocked: decision == 'blocked',
      note: profile.note,
      reasonCodes: reasons,
      recommendedAction: decision == 'blocked'
          ? 'Hold the order, collect advance, and verify buyer intent before dispatch.'
          : decision == 'review'
          ? 'Call the buyer, confirm landmark, and check COD intent before supplier confirmation.'
          : profile.recommendedAction,
      totalOrders: profile.totalOrders,
      deliveredOrders: profile.deliveredOrders,
      returnCount: profile.returnCount,
      pendingOrders: profile.pendingOrders,
      unpaidOrders: profile.unpaidOrders,
      lastOrderId: profile.lastOrderId,
      updatedAt: DateTime.now(),
    );
    await upsertResellerBuyerRiskProfile(updatedProfile);
    return <String, dynamic>{
      'decision': decision,
      'riskScore': escalatedScore,
      'summary': updatedProfile.recommendedAction,
      'reasons': reasons,
      'requiresManualReview': decision != 'approved',
      'buyer': matchedBuyer?.toJson(),
      'buyerPhone': buyerPhone.trim(),
      'buyerName': (buyerName ?? '').trim(),
      'buyerAddress': buyerAddress ?? matchedBuyer?.primaryAddress ?? '',
      'orderTotal': orderTotal ?? 0,
      'itemCount': itemCount ?? 0,
      'context': context ?? const <String, dynamic>{},
      'evaluatedAt': DateTime.now().toIso8601String(),
      'source': 'local-store',
      'profile': updatedProfile.toJson(),
    };
  }

  Future<Map<String, dynamic>> previewSupplierSplit({
    required int userId,
    required int siteId,
    required List<Map<String, dynamic>> lines,
    Map<String, dynamic>? draft,
    List<Map<String, dynamic>> supplierHints = const <Map<String, dynamic>>[],
  }) async {
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
      supplierNames[key] = (line['supplierName'] ??
              line['siteName'] ??
              supplierNames[key] ??
              'Supplier')
          .toString();
    }
    final suppliers = bySupplier.entries.map((entry) {
      final supplierLines = entry.value;
      final quantity = supplierLines.fold<int>(
        0,
        (sum, item) => sum + _toInt(item['quantity'], fallback: 1),
      );
      final baseAmount = supplierLines.fold<double>(
        0,
        (sum, item) =>
            sum +
            (_toDouble(item['basePrice'] ?? item['resellPrice']) *
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
    }).toList(growable: false);

    final totalSellAmount = suppliers.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['sellAmount']),
    );
    final totalBaseAmount = suppliers.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['baseAmount']),
    );
    final groupDraft = await upsertResellerSupplierOrderGroupDraft(
      OrderGroupDraft(
        id: ((draft?['groupId'] ?? draft?['id']) as Object?)?.toString().trim().isNotEmpty ==
                true
            ? ((draft?['groupId'] ?? draft?['id']) as Object).toString()
            : 'group-$siteId-$userId',
        userId: userId,
        siteId: siteId,
        title: (draft?['title'] as String?) ?? 'Supplier split draft',
        status: (draft?['status'] as String?) ?? 'draft',
        channel: (draft?['channel'] as String?) ?? 'quick-order',
        buyerIds: <String>[
          if ((draft?['buyerPhone'] as String?)?.trim().isNotEmpty ?? false)
            _buyerIdentityKey(
              phone: draft!['buyerPhone'] as String,
              name: (draft['buyerName'] as String?) ?? '',
            ),
        ],
        quickOrderDraftIds: <String>[
          if ((draft?['id'] as String?)?.trim().isNotEmpty ?? false)
            draft!['id'] as String,
        ],
        tags: suppliers.map((item) => '${item['supplierName']}').toList(
          growable: false,
        ),
        note:
            'Local supplier grouping preview for ${suppliers.length} supplier lanes.',
        targetOrderCount: suppliers.length,
        projectedRevenue: totalSellAmount.round(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return <String, dynamic>{
      'userId': userId,
      'siteId': siteId,
      'draftId': draft?['id'] ?? draft?['draftId'],
      'groupId': groupDraft.id,
      'supplierCount': suppliers.length,
      'lineCount': lines.length,
      'totalQuantity': suppliers.fold<int>(
        0,
        (sum, item) => sum + _toInt(item['quantity']),
      ),
      'totalBaseAmount': totalBaseAmount,
      'totalSellAmount': totalSellAmount,
      'totalProfit': totalSellAmount - totalBaseAmount,
      'suppliers': suppliers,
      'generatedAt': DateTime.now().toIso8601String(),
      'source': 'local-store',
    };
  }

  Future<List<QuickOrderDraft>> fetchResellerQuickOrderDrafts({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_quickOrderDraftsCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(QuickOrderDraft.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<QuickOrderDraft?> fetchResellerQuickOrderDraft(String id) async {
    await ensureSeeded();
    final entity = await _loadEntity(_quickOrderDraftsCollection, id);
    return entity == null ? null : QuickOrderDraft.fromJson(entity);
  }

  Future<QuickOrderDraft> upsertResellerQuickOrderDraft(
    QuickOrderDraft draft,
  ) async {
    await ensureSeeded();
    final now = DateTime.now();
    final payload = draft.toJson();
    if ((payload['createdAt'] as String?)?.isEmpty ?? true) {
      payload['createdAt'] = now.toIso8601String();
    }
    payload['updatedAt'] = now.toIso8601String();
    await _upsertEntity(_quickOrderDraftsCollection, draft.id, payload);
    return QuickOrderDraft.fromJson(payload);
  }

  Future<bool> deleteResellerQuickOrderDraft(String id) async {
    await ensureSeeded();
    return _deleteEntity(_quickOrderDraftsCollection, id);
  }

  Future<List<BuyerRiskProfile>> fetchResellerBuyerRiskProfiles({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final storedRows = await _loadCollection(_buyerRiskProfilesCollection);
    final profiles = <String, BuyerRiskProfile>{};
    for (final row in storedRows) {
      if ((row['userId'] as num?)?.toInt() != userId) continue;
      if ((row['siteId'] as num?)?.toInt() != siteId) continue;
      final profile = BuyerRiskProfile.fromJson(row);
      profiles[profile.id] = profile;
    }
    final buyers = await fetchBuyerBook(userId: userId, siteId: siteId);
    for (final buyer in buyers) {
      profiles.putIfAbsent(buyer.id, () => _deriveBuyerRiskProfile(buyer, userId, siteId));
    }
    final items = profiles.values.toList(growable: false)
      ..sort((a, b) {
        final scoreCompare = b.riskScore.compareTo(a.riskScore);
        if (scoreCompare != 0) return scoreCompare;
        return (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        );
      });
    return items;
  }

  Future<BuyerRiskProfile?> fetchResellerBuyerRiskProfile({
    required String buyerId,
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final entity = await _loadEntity(_buyerRiskProfilesCollection, buyerId);
    if (entity != null) return BuyerRiskProfile.fromJson(entity);
    final buyers = await fetchBuyerBook(userId: userId, siteId: siteId);
    for (final buyer in buyers) {
      if (buyer.id == buyerId) {
        return _deriveBuyerRiskProfile(buyer, userId, siteId);
      }
    }
    return null;
  }

  Future<BuyerRiskProfile> upsertResellerBuyerRiskProfile(
    BuyerRiskProfile profile,
  ) async {
    await ensureSeeded();
    final payload = profile.toJson()
      ..['updatedAt'] = DateTime.now().toIso8601String();
    await _upsertEntity(_buyerRiskProfilesCollection, profile.id, payload);
    return BuyerRiskProfile.fromJson(payload);
  }

  Future<bool> deleteResellerBuyerRiskProfile(String buyerId) async {
    await ensureSeeded();
    return _deleteEntity(_buyerRiskProfilesCollection, buyerId);
  }

  Future<List<OrderGroupDraft>> fetchResellerSupplierOrderGroupDrafts({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_orderGroupDraftsCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(OrderGroupDraft.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<OrderGroupDraft?> fetchResellerSupplierOrderGroupDraft(
    String id,
  ) async {
    await ensureSeeded();
    final entity = await _loadEntity(_orderGroupDraftsCollection, id);
    return entity == null ? null : OrderGroupDraft.fromJson(entity);
  }

  Future<OrderGroupDraft> upsertResellerSupplierOrderGroupDraft(
    OrderGroupDraft draft,
  ) async {
    await ensureSeeded();
    final now = DateTime.now();
    final payload = draft.toJson();
    if ((payload['createdAt'] as String?)?.isEmpty ?? true) {
      payload['createdAt'] = now.toIso8601String();
    }
    payload['updatedAt'] = now.toIso8601String();
    await _upsertEntity(_orderGroupDraftsCollection, draft.id, payload);
    return OrderGroupDraft.fromJson(payload);
  }

  Future<bool> deleteResellerSupplierOrderGroupDraft(String id) async {
    await ensureSeeded();
    return _deleteEntity(_orderGroupDraftsCollection, id);
  }

  Future<List<ShareAssetDraft>> fetchResellerShareAssetDrafts({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_shareAssetDraftsCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(ShareAssetDraft.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<ShareAssetDraft?> fetchResellerShareAssetDraft(String id) async {
    await ensureSeeded();
    final entity = await _loadEntity(_shareAssetDraftsCollection, id);
    return entity == null ? null : ShareAssetDraft.fromJson(entity);
  }

  Future<ShareAssetDraft> upsertResellerShareAssetDraft(
    ShareAssetDraft draft,
  ) async {
    await ensureSeeded();
    final payload = draft.toJson()
      ..['updatedAt'] = DateTime.now().toIso8601String();
    await _upsertEntity(_shareAssetDraftsCollection, draft.id, payload);
    return ShareAssetDraft.fromJson(payload);
  }

  Future<bool> deleteResellerShareAssetDraft(String id) async {
    await ensureSeeded();
    return _deleteEntity(_shareAssetDraftsCollection, id);
  }

  Future<ResellerQuote> createQuote(ResellerQuote quote) async {
    await ensureSeeded();
    await _upsertEntity(_quotesCollection, quote.id, quote.toJson());
    return quote;
  }

  Future<ResellerQuote> upsertQuote(ResellerQuote quote) {
    return createQuote(quote);
  }

  Future<List<ResellerQuote>> fetchQuotes({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_quotesCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(ResellerQuote.fromJson)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markQuoteConverted({
    required String quoteId,
    required String orderId,
  }) async {
    await ensureSeeded();
    final existing = await _loadEntity(_quotesCollection, quoteId);
    if (existing == null) return;
    final updated = ResellerQuote.fromJson(
      existing,
    ).copyWith(status: 'converted', orderId: orderId);
    await _upsertEntity(_quotesCollection, quoteId, updated.toJson());
  }

  Future<bool> deleteQuote(String quoteId) async {
    await ensureSeeded();
    return _deleteEntity(_quotesCollection, quoteId);
  }

  Future<bool> saveBuyerProfileMeta({
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required int userId,
    required int siteId,
    required String note,
    required String sourceTag,
    required bool isRisky,
    required bool isBlocked,
  }) async {
    await ensureSeeded();
    await _upsertEntity(_buyerMetaCollection, buyerId, <String, dynamic>{
      'id': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'userId': userId,
      'siteId': siteId,
      'note': note.trim(),
      'sourceTag': sourceTag.trim().isEmpty ? 'Repeat' : sourceTag.trim(),
      'isRisky': isRisky,
      'isBlocked': isBlocked,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  Future<bool> deleteBuyerProfileMeta(String buyerId) async {
    await ensureSeeded();
    return _deleteEntity(_buyerMetaCollection, buyerId);
  }

  Future<OrderCreateRes> makeOrder(
    OrderCreateReq model, {
    required bool isAuthenticated,
    int? userId,
    int? customerId,
  }) async {
    await ensureSeeded();
    final resolvedUserId = userId ?? (model.userId as int?) ?? demoUserId;
    final resolvedCustomerId =
        customerId ??
        model.customerId ??
        ((await fetchSelfStoreCustomer(
              resolvedUserId,
              model.siteId ?? 0,
            ))?.id ??
            0);
    final existingOrders = await _loadCollection(_ordersCollection);
    final nextId =
        existingOrders
            .map((item) => (item['id'] as num?)?.toInt() ?? 0)
            .fold<int>(
              9000,
              (value, element) => element > value ? element : value,
            ) +
        1;
    final now = DateTime.now();
    final orderId = 'SH${now.millisecondsSinceEpoch}';
    final orderJson = <String, dynamic>{
      'id': nextId,
      'siteId': model.siteId,
      'customerId': resolvedCustomerId,
      'userId': resolvedUserId,
      'address': model.address,
      'affiliateCommission': model.affiliateCommission ?? 0,
      'affiliateIsPaid': false,
      'cashbackBalance': model.cashbackBalance ?? 0,
      'charge': model.charge ?? 0,
      'childHid': null,
      'childId': null,
      'cost': model.cost ?? 0,
      'createdAt': now.toIso8601String(),
      'currency': model.currency ?? 'BDT',
      'customerAddress': model.customerAddress ?? '',
      'customerName': model.customerName ?? 'Buyer',
      'customerNote': model.customerNote ?? '',
      'customerPhone': model.customerPhone ?? 0,
      'deliveryTime': model.deliveryTime,
      'discount': (model.discount ?? 0).toDouble(),
      'discountName': model.discountName,
      'emiDuration': model.emiDuration ?? 0,
      'emiInterest': model.emiInterest ?? 0,
      'gatewayText': model.gatewayText ?? 'Cash on Delivery',
      'grossAmount': model.grossAmount ?? model.total ?? 0,
      'image': model.image,
      'isChargePaid': false,
      'isEmi': model.isEmi ?? false,
      'isPaid': false,
      'isSettle': false,
      'isTransferred': false,
      'latitude': model.latitude,
      'logisticsCharge': (model.logisticsCharge ?? 0).toDouble(),
      'logisticsCityId': null,
      'logisticsExtraCharge': (model.logisticsExtraCharge ?? 0).toDouble(),
      'logisticsId': model.logisticsId ?? 1,
      'logisticsIsConfirmed': true,
      'logisticsIsPaid': false,
      'logisticsStoppageId': model.logisticsStoppageId,
      'logisticsText': model.logisticsText ?? 'SteadFast',
      'logisticsUrl': null,
      'logisticsZoneId': null,
      'longitude': model.longitude,
      'netAmount': model.netAmount ?? model.total ?? 0,
      'orderId': orderId,
      'paid': model.paid ?? 0,
      'paymentId': null,
      'paymentResellerId': null,
      'profit': model.profit ?? 0,
      'resellAmount': model.resellAmount ?? model.total ?? 0,
      'resellerAdvanceCollect': model.resellerAdvanceCollect ?? 0,
      'resellerCommission': model.resellerCommission ?? model.profit ?? 0,
      'resellerId': resolvedCustomerId,
      'resellerIsPaid': false,
      'rewardPoints': model.rewardPoints ?? 0,
      'status': 1,
      'statusCompleted': <int>[1],
      'total': model.total ?? 0,
      'trackingId': 'TRK$nextId',
      'updatedAt': now.toIso8601String(),
      'vat': model.vat ?? 0,
      'vatAmount': model.vatAmount ?? 0,
      'buyerContacted': false,
      'supportIssue': false,
      'customer': <String, dynamic>{
        'id': resolvedCustomerId,
        'name': model.customerName ?? 'Buyer',
      },
      'events': <Map<String, dynamic>>[
        _eventJson(
          id: nextId * 10,
          orderId: nextId,
          eventType: 1,
          note: 'Order placed in local MVP mode',
          address: model.customerAddress ?? '',
          createdAt: now,
        ),
      ],
      'lines': model.products
          .map(
            (product) => <String, dynamic>{
              'id': product.id ?? 0,
              'cost': product.cost ?? 0,
              'price': product.price ?? 0,
              'quantity': product.quantity ?? 1,
              'resellPrice': product.resellPrice ?? product.cost ?? 0,
              'thumbnail': product.thumbnail,
              'title': product.title,
              'variant': product.variant,
              'variantId': product.variantId,
              'vat': product.vat ?? 0,
            },
          )
          .toList(growable: false),
    };
    await _upsertEntity(_ordersCollection, '$nextId', orderJson);
    for (final product in model.products) {
      final productId = product.id;
      final price = product.price;
      if (productId == null || productId <= 0 || price == null || price <= 0) {
        continue;
      }
      await _recordPricingMemoryObservation(
        userId: resolvedUserId,
        siteId: model.siteId ?? 0,
        productId: productId,
        successfulPrice: price,
      );
    }
    await _upsertEntity(
      _orderEventsCollection,
      '${nextId * 10}',
      _eventJson(
        id: nextId * 10,
        orderId: nextId,
        eventType: 1,
        note: 'Order placed in local MVP mode',
        address: model.customerAddress ?? '',
        createdAt: now,
      ),
    );
    final customer = await _loadCustomerById(resolvedCustomerId);
    if (customer != null) {
      customer['ordersPlaced'] =
          ((customer['ordersPlaced'] as num?)?.toInt() ?? 0) + 1;
      customer['ordersPending'] =
          ((customer['ordersPending'] as num?)?.toInt() ?? 0) + 1;
      customer['ordersTotal'] =
          ((customer['ordersTotal'] as num?)?.toInt() ?? 0) + 1;
      customer['resellTotal'] =
          ((customer['resellTotal'] as num?)?.toInt() ?? 0) +
          (model.resellAmount ?? model.total ?? 0);
      customer['resellPayable'] =
          ((customer['resellPayable'] as num?)?.toInt() ?? 0) +
          (model.profit ?? 0);
      customer['pendingProfit'] =
          ((customer['pendingProfit'] as num?)?.toInt() ?? 0) +
          (model.profit ?? 0);
      await _upsertEntity(
        _customersCollection,
        _customerKey(
          (customer['siteId'] as num?)?.toInt() ?? 0,
          (customer['userId'] as num?)?.toInt() ?? resolvedUserId,
        ),
        customer,
      );
    }
    return OrderCreateRes.fromJson(orderJson);
  }

  Future<PaymentGatewayResponse> paymentGatewayRequest(
    PaymentGatewayReq model,
  ) async {
    await ensureSeeded();
    return PaymentGatewayResponse.fromJson(<String, dynamic>{
      'amount': model.amount,
      'callBack': 'sellhub://payment/callback',
      'cancelUrl': 'sellhub://payment/cancel',
      'currency': 'BDT',
      'customerName': model.customerName ?? 'SellHub Buyer',
      'displayValue': 'Sandbox payment request',
      'failUrl': 0,
      'id': DateTime.now().millisecondsSinceEpoch,
      'isCaptured': false,
      'isPaid': false,
      'merchantId': 1,
      'productInfo': model.productInfo ?? 'SellHub Order',
      'referenceId': model.referenceId ?? 'local-payment',
      'showRefundButton': false,
      'status': 1,
      'successUrl': 'sellhub://payment/success',
      'transactionType': 1,
      'transactionId': 'TX-${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  Future<SelfStoreCustomerRes?> fetchCustomerContext({
    required int userId,
    required int siteId,
  }) {
    return fetchSelfStoreCustomer(userId, siteId);
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
    await ensureSeeded();
    final normalized = code.trim().toUpperCase();
    if (normalized == 'SELLHUB10') {
      return VoucherCheckRes(
        discount: (total * 0.10).clamp(0, 250),
        message: '10% reseller launch discount applied',
      );
    }
    if (normalized == 'FREESHIP') {
      return VoucherCheckRes(
        discount: delivery,
        message: 'Delivery charge waived for this order',
      );
    }
    return const VoucherCheckRes(
      discount: 0,
      message: 'Voucher not available in local MVP seed',
    );
  }

  Future<List<OrderEventModel>> fetchOrderEvents({
    required int siteId,
    required int orderId,
  }) async {
    await ensureSeeded();
    final events = await _loadCollection(_orderEventsCollection);
    return events
        .where(
          (item) =>
              (item['siteId'] as num?)?.toInt() == siteId &&
              (item['orderId'] as num?)?.toInt() == orderId,
        )
        .toList(growable: false)
        .reversed
        .map((item) => OrderEventModel.fromJson(item))
        .toList(growable: false);
  }

  Future<OrderEventModel> createCustomerOrderEvent({
    required int userId,
    required int siteId,
    required int orderId,
    required int eventType,
    required String note,
  }) async {
    await ensureSeeded();
    final events = await _loadCollection(_orderEventsCollection);
    final nextId =
        events
            .map((item) => (item['id'] as num?)?.toInt() ?? 0)
            .fold<int>(
              40000,
              (value, element) => element > value ? element : value,
            ) +
        1;
    final event = _eventJson(
      id: nextId,
      orderId: orderId,
      siteId: siteId,
      eventType: eventType,
      note: note,
      address: 'Customer follow-up from local SellHub',
      createdAt: DateTime.now(),
    );
    event['userId'] = userId;
    await _upsertEntity(_orderEventsCollection, '$nextId', event);
    final orders = await _loadCollection(_ordersCollection);
    for (final order in orders) {
      if ((order['id'] as num?)?.toInt() != orderId) continue;
      if (eventType == 11 || eventType == 12) {
        order['supportIssue'] = true;
      }
      if (eventType == 13) {
        order['buyerContacted'] = true;
      }
      order['updatedAt'] = DateTime.now().toIso8601String();
      await _upsertEntity(_ordersCollection, '$orderId', order);
      break;
    }
    return OrderEventModel.fromJson(event);
  }

  Future<bool> deleteLatestCustomerOrderEvent({
    required int siteId,
    required int orderId,
    required int eventType,
  }) async {
    await ensureSeeded();
    final events = await _loadCollection(_orderEventsCollection);
    final matching =
        events
            .where(
              (item) =>
                  (item['siteId'] as num?)?.toInt() == siteId &&
                  (item['orderId'] as num?)?.toInt() == orderId &&
                  (item['eventType'] as num?)?.toInt() == eventType,
            )
            .toList(growable: false)
          ..sort(
            (a, b) =>
                (DateTime.tryParse((b['createdAt'] as String?) ?? '') ??
                        DateTime(2000))
                    .compareTo(
                      DateTime.tryParse((a['createdAt'] as String?) ?? '') ??
                          DateTime(2000),
                    ),
          );
    if (matching.isEmpty) return false;
    final target = matching.first;
    final deleted = await _deleteEntity(
      _orderEventsCollection,
      '${target['id'] ?? ''}',
    );
    if (!deleted) return false;

    final remaining = (await _loadCollection(_orderEventsCollection))
        .where(
          (item) =>
              (item['siteId'] as num?)?.toInt() == siteId &&
              (item['orderId'] as num?)?.toInt() == orderId,
        )
        .toList(growable: false);

    final hasSupportIssue = remaining.any(
      (item) =>
          ((item['eventType'] as num?)?.toInt() ?? 0) == 11 ||
          ((item['eventType'] as num?)?.toInt() ?? 0) == 12,
    );
    final hasBuyerContacted = remaining.any(
      (item) => ((item['eventType'] as num?)?.toInt() ?? 0) == 13,
    );
    final orders = await _loadCollection(_ordersCollection);
    for (final order in orders) {
      if ((order['id'] as num?)?.toInt() != orderId) continue;
      order['supportIssue'] = hasSupportIssue;
      order['buyerContacted'] = hasBuyerContacted;
      order['updatedAt'] = DateTime.now().toIso8601String();
      await _upsertEntity(_ordersCollection, '$orderId', order);
      break;
    }
    return true;
  }

  Future<List<CustomerReviewResModel>> fetchCustomerReviews(
    int productId,
    int first,
  ) async {
    await ensureSeeded();
    final reviews = await _loadCollection(_reviewsCollection);
    return reviews
        .where((item) => (item['productId'] as num?)?.toInt() == productId)
        .toList(growable: false)
        .reversed
        .take(first)
        .map((item) => CustomerReviewResModel.fromJson(item))
        .toList(growable: false);
  }

  Future<bool> makeCustomerReview(SubmitReviewReq model) async {
    await ensureSeeded();
    final reviews = await _loadCollection(_reviewsCollection);
    final nextId =
        reviews
            .map((item) => (item['id'] as num?)?.toInt() ?? 0)
            .fold<int>(
              60000,
              (value, element) => element > value ? element : value,
            ) +
        1;
    final user = await _loadEntity(
      _usersCollection,
      '${model.userId ?? demoUserId}',
    );
    final review = <String, dynamic>{
      'id': nextId,
      'productId': model.productId ?? 0,
      'siteId': model.siteId ?? 0,
      'userId': model.userId ?? demoUserId,
      'rating': model.rating ?? 5,
      'description': model.description ?? '',
      'createdAt': DateTime.now().toIso8601String(),
      'user': <String, dynamic>{
        'id': (user?['id'] as num?)?.toInt() ?? demoUserId,
        'name':
            (user?['name'] as String?) ??
            (model.feedbacker ?? 'SellHub Seller'),
        'avatar': user?['avatar'],
      },
    };
    await _upsertEntity(_reviewsCollection, '$nextId', review);
    return true;
  }

  Future<void> _ensureSeededInternal() async {
    final version = await loadLocalSeedVersion(_client, seedKey: _seedKey);
    if (version == _seedVersion) return;

    await _replaceCollection(_usersCollection, <Map<String, dynamic>>[
      <String, dynamic>{
        'id': demoUserId,
        'name': 'Demo Seller',
        'username': '8801700000000',
        'phone': '8801700000000',
        'email': 'demo@sellhub.local',
        'address': 'Dhaka, Bangladesh',
        'avatar': null,
        'country': 50,
        'currency': 'BDT',
        'firstName': 'Demo',
        'formattedAddress': 'Dhaka, Bangladesh',
        'isStaff': false,
        'isActive': true,
        'latitude': 23.8103,
        'longitude': 90.4125,
        'referCode': 'SELLDEMO',
        'referedCode': null,
      },
    ]);
    await _replaceCollection(_authMetaCollection, <Map<String, dynamic>>[
      <String, dynamic>{
        'id': demoUserId,
        'password': demoPassword,
        'otp': demoOtp,
      },
    ]);
    await _replaceCollection(
      _customersCollection,
      SellHubCatalogSeed.suppliers
          .map(
            (supplier) => _seedCustomer(
              id: demoUserId * 10 + (supplier['id'] as num).toInt(),
              userId: demoUserId,
              siteId: (supplier['id'] as num).toInt(),
              title: 'Demo Seller',
              phone: 8801700000000,
            ),
          )
          .toList(growable: false),
    );
    await _replaceCollection(
      _paymentMethodsCollection,
      SellHubCatalogSeed.suppliers
          .expand(
            (supplier) => <Map<String, dynamic>>[
              _paymentMethod(
                id: (supplier['id'] as num).toInt() * 10 + 1,
                siteId: (supplier['id'] as num).toInt(),
                title: 'Cash on Delivery',
                note: 'Most trusted for first-time buyers',
                logo: '',
              ),
              _paymentMethod(
                id: (supplier['id'] as num).toInt() * 10 + 2,
                siteId: (supplier['id'] as num).toInt(),
                title: 'bKash',
                note: 'Collect advance if needed',
                logo: '',
                gatewayType: 2,
              ),
            ],
          )
          .toList(growable: false),
    );
    await _replaceCollection(_deliveryPlacesCollection, <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'balance': 0,
        'chargeBase': 80,
        'chargeMerchantDefined': 80,
        'codSupportLabel': 'COD friendly',
        'confidenceLabel': 'High confidence',
        'confidenceScore': 88,
        'deliveryEtaLabel': '1-2 days in Dhaka',
        'discount': 0,
        'note': 'Reliable nationwide COD',
        'isActive': true,
        'logisticsAddress': 'Dhaka Hub',
        'logisticsTitle': 'SteadFast Courier',
        'riskNote': 'Low return pressure for metro orders with confirmed phone.',
        'recommendedAction':
            'Good default lane for Dhaka COD buyers and first-time sellers.',
        'companyId': 1,
        'company': <String, dynamic>{
          'domain': 'steadfast.local',
          'id': 1,
          'logo': '',
          'street': 'Dhaka',
          'phone': 8809600000000,
        },
        'title': 'SteadFast Courier',
        'updatedAt': DateTime.now().toIso8601String(),
        'zoneLabel': 'Dhaka metro',
      },
      <String, dynamic>{
        'id': 2,
        'balance': 0,
        'chargeBase': 120,
        'chargeMerchantDefined': 120,
        'codSupportLabel': 'COD available',
        'confidenceLabel': 'Medium confidence',
        'confidenceScore': 68,
        'deliveryEtaLabel': '2-4 days outside Dhaka',
        'discount': 0,
        'note': 'Suitable for district orders with clear landmark confirmation',
        'isActive': true,
        'logisticsAddress': 'District lane',
        'logisticsTitle': 'SteadFast Courier',
        'riskNote': 'Call confirmation is recommended before supplier dispatch.',
        'recommendedAction':
            'Use after phone confirmation and address landmark check.',
        'companyId': 1,
        'company': <String, dynamic>{
          'domain': 'steadfast.local',
          'id': 1,
          'logo': '',
          'street': 'Dhaka',
          'phone': 8809600000000,
        },
        'title': 'District COD',
        'updatedAt': DateTime.now().toIso8601String(),
        'zoneLabel': 'Outside Dhaka',
      },
      <String, dynamic>{
        'id': 3,
        'balance': 0,
        'chargeBase': 140,
        'chargeMerchantDefined': 140,
        'codSupportLabel': 'Review before COD',
        'confidenceLabel': 'Watch risk',
        'confidenceScore': 46,
        'deliveryEtaLabel': '3-5 days in mixed zones',
        'discount': 0,
        'note': 'Use this lane only after reconfirming risky addresses or large COD baskets.',
        'isActive': true,
        'logisticsAddress': 'Mixed zone lane',
        'logisticsTitle': 'SteadFast Courier',
        'riskNote':
            'Higher return risk for weak landmarks, new buyers, or large baskets.',
        'recommendedAction':
            'Collect partial advance or verify landmark and alternate phone before ordering.',
        'companyId': 1,
        'company': <String, dynamic>{
          'domain': 'steadfast.local',
          'id': 1,
          'logo': '',
          'street': 'Dhaka',
          'phone': 8809600000000,
        },
        'title': 'Risk-check lane',
        'updatedAt': DateTime.now().toIso8601String(),
        'zoneLabel': 'Mixed / risky zone',
      },
    ]);
    await _replaceCollection(_pricingMemoryCollection, <Map<String, dynamic>>[
      _pricingMemory(
        productId: 7001,
        siteId: 1001,
        lastSuccessfulPrice: 790,
        mostCommonSuccessfulPrice: 780,
        successfulOrderCount: 6,
        frequency: const <int, int>{760: 1, 780: 4, 790: 1},
      ),
      _pricingMemory(
        productId: 7002,
        siteId: 1001,
        lastSuccessfulPrice: 960,
        mostCommonSuccessfulPrice: 920,
        successfulOrderCount: 4,
        frequency: const <int, int>{890: 1, 920: 2, 960: 1},
      ),
      _pricingMemory(
        productId: 7101,
        siteId: 1002,
        lastSuccessfulPrice: 1450,
        mostCommonSuccessfulPrice: 1420,
        successfulOrderCount: 5,
        frequency: const <int, int>{1390: 1, 1420: 3, 1450: 1},
      ),
      _pricingMemory(
        productId: 7202,
        siteId: 1003,
        lastSuccessfulPrice: 1280,
        mostCommonSuccessfulPrice: 1240,
        successfulOrderCount: 3,
        frequency: const <int, int>{1210: 1, 1240: 1, 1280: 1},
      ),
    ]);
    await _replaceCollection(_buyerMetaCollection, <Map<String, dynamic>>[
      <String, dynamic>{
        'id': _buyerIdentityKey(phone: '8801711111111', name: 'Ayesha Rahman'),
        'buyerName': 'Ayesha Rahman',
        'buyerPhone': '8801711111111',
        'userId': demoUserId,
        'siteId': 1001,
        'note': 'Prefers evening delivery and quick WhatsApp confirmation.',
        'sourceTag': 'WhatsApp',
        'isRisky': false,
        'isBlocked': false,
      },
      <String, dynamic>{
        'id': _buyerIdentityKey(phone: '8801811111111', name: 'Tanvir Hasan'),
        'buyerName': 'Tanvir Hasan',
        'buyerPhone': '8801811111111',
        'userId': demoUserId,
        'siteId': 1002,
        'note': 'Referral buyer. Confirm office-hour delivery before dispatch.',
        'sourceTag': 'Referral',
        'isRisky': false,
        'isBlocked': false,
      },
    ]);
    await _replaceCollection(
      _workflowPricingTemplatesCollection,
      <Map<String, dynamic>>[
        WorkflowPricingTemplate(
          id: 'pricing-1001-whatsapp',
          userId: demoUserId,
          siteId: 1001,
          name: 'WhatsApp quick sell',
          channel: 'WhatsApp',
          markupAmount: 120,
          markupPercent: 18,
          note: 'Fast reply pricing for message-first buyers.',
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ).toJson(),
        WorkflowPricingTemplate(
          id: 'pricing-1001-premium',
          userId: demoUserId,
          siteId: 1001,
          name: 'Premium buyer',
          channel: 'Premium',
          markupAmount: 220,
          markupPercent: 28,
          note: 'Higher margin template for repeat and higher-trust buyers.',
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ).toJson(),
      ],
    );
    await _replaceCollection(_workflowBundlesCollection, <Map<String, dynamic>>[
      WorkflowSupplierBundle(
        id: 'bundle-1001-top-picks',
        userId: demoUserId,
        siteId: 1001,
        supplierName: 'Style Bazaar',
        name: 'Top fashion starters',
        productTitles: const <String>[
          'Classic Cotton Panjabi',
          'Premium Cotton Saree',
          'Easy gift combo',
        ],
        note: 'Use this bundle when selling to festival and family buyers.',
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ).toJson(),
    ]);
    await _replaceCollection(
      _workflowBuyerSegmentsCollection,
      <Map<String, dynamic>>[
        WorkflowBuyerSegment(
          id: 'segment-1001-office-buyers',
          userId: demoUserId,
          siteId: 1001,
          name: 'Office-hour buyers',
          description: 'Buyers who want delivery confirmed before dispatch.',
          buyerCount: 3,
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ).toJson(),
      ],
    );
    await _replaceCollection(_teamConfigCollection, <Map<String, dynamic>>[
      <String, dynamic>{
        'id': _teamConfigKey(demoUserId, 1001),
        'teamId': 'team-1001-$demoUserId',
        'ownerUserId': demoUserId,
        'siteId': 1001,
        'teamName': 'Dhaka Fast Sellers',
        'ownerName': 'Demo Seller',
        'overridePercent': 4,
        'transparentPayoutRule':
            'Override applies only to direct team sales. No multi-level payouts.',
      },
    ]);
    await _replaceCollection(_teamMembersCollection, <Map<String, dynamic>>[
      TeamMemberEntry(
        id: 'member-1001-1',
        teamId: 'team-1001-$demoUserId',
        ownerUserId: demoUserId,
        siteId: 1001,
        name: 'Nusrat Jahan',
        phone: '8801710001001',
        status: 'active',
        role: 'team_seller',
        orderVolume: 18640,
        overrideGenerated: 746,
        topProduct: 'Classic Cotton Panjabi',
        joinedAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 6)),
      ).toJson(),
      TeamMemberEntry(
        id: 'member-1001-2',
        teamId: 'team-1001-$demoUserId',
        ownerUserId: demoUserId,
        siteId: 1001,
        name: 'Shafiq Ahmed',
        phone: '8801810001001',
        status: 'active',
        role: 'team_seller',
        orderVolume: 12450,
        overrideGenerated: 498,
        topProduct: 'Premium Cotton Saree',
        joinedAt: DateTime.now().subtract(const Duration(days: 18)),
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 12)),
      ).toJson(),
      TeamMemberEntry(
        id: 'member-1001-3',
        teamId: 'team-1001-$demoUserId',
        ownerUserId: demoUserId,
        siteId: 1001,
        name: 'Raihan',
        phone: '8801910001001',
        status: 'pending',
        role: 'team_seller',
        orderVolume: 0,
        overrideGenerated: 0,
        topProduct: '',
        joinedAt: DateTime.now().subtract(const Duration(days: 2)),
        lastActiveAt: DateTime.now().subtract(const Duration(days: 2)),
      ).toJson(),
    ]);
    await _replaceCollection(_teamSharedListsCollection, <Map<String, dynamic>>[
      TeamSharedListEntry(
        id: 'team-list-1001-1',
        teamId: 'team-1001-$demoUserId',
        ownerUserId: demoUserId,
        siteId: 1001,
        title: 'Eid starters',
        supplierName: 'Style Bazaar',
        productTitles: const <String>[
          'Classic Cotton Panjabi',
          'Premium Cotton Saree',
          'Easy gift combo',
        ],
        sharedWithMemberIds: const <String>['member-1001-1', 'member-1001-2'],
        note: 'Push these first in WhatsApp and Facebook this week.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ).toJson(),
    ]);
    await _replaceCollection(_payoutBatchesCollection, <Map<String, dynamic>>[
      PayoutBatchEntry(
        id: 'PB-1001-001',
        userId: demoUserId,
        siteId: 1001,
        customerId: demoUserId * 10 + 1001,
        status: 'paid',
        channel: 'bKash • 01700000000',
        referenceId: 'BKSH-893744',
        orderIds: const <String>['SH9105'],
        totalAmount: 190,
        deductionTotal: 0,
        netAmount: 190,
        note: 'Released in the weekly settled payout batch.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        estimatedSettlementDate: DateTime.now().subtract(
          const Duration(days: 5),
        ),
        releasedAt: DateTime.now().subtract(const Duration(days: 5)),
        paidAt: DateTime.now().subtract(const Duration(days: 4)),
      ).toJson(),
      PayoutBatchEntry(
        id: 'PB-1001-002',
        userId: demoUserId,
        siteId: 1001,
        customerId: demoUserId * 10 + 1001,
        status: 'released',
        channel: 'bKash • 01700000000',
        referenceId: 'BKSH-894211',
        orderIds: const <String>['SH9104'],
        totalAmount: 220,
        deductionTotal: 20,
        netAmount: 200,
        note: 'Released to wallet. Waiting for provider confirmation.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        estimatedSettlementDate: DateTime.now().subtract(
          const Duration(days: 1),
        ),
        releasedAt: DateTime.now().subtract(const Duration(days: 1)),
        paidAt: null,
      ).toJson(),
    ]);
    await _replaceCollection(
      _payoutAdjustmentsCollection,
      <Map<String, dynamic>>[
        PayoutAdjustmentEntry(
          id: 'ADJ-1001-001',
          userId: demoUserId,
          siteId: 1001,
          orderId: 'SH9106',
          type: 'return_adjustment',
          label: 'Return adjustment',
          amount: 130,
          note: 'Buyer refused delivery. Margin reversed after return.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ).toJson(),
        PayoutAdjustmentEntry(
          id: 'ADJ-1001-002',
          userId: demoUserId,
          siteId: 1001,
          orderId: 'SH9104',
          type: 'payout_fee',
          label: 'Payout fee',
          amount: 20,
          note: 'Mobile wallet cash-out fee applied to released batch.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ).toJson(),
      ],
    );
    await _replaceCollection(_payoutDisputesCollection, <Map<String, dynamic>>[
      PayoutDisputeEntry(
        id: '71001',
        userId: demoUserId,
        siteId: 1001,
        orderId: 'SH9104',
        batchId: 'PB-1001-002',
        status: 'reviewing',
        reason: 'Net amount lower than expected',
        note: 'Seller asked support to confirm the wallet cash-out fee.',
        createdAt: DateTime.now().subtract(const Duration(hours: 20)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ).toJson(),
    ]);
    await _replaceCollection(_quickOrderDraftsCollection, <Map<String, dynamic>>[
      _seedQuickOrderDraft(
        id: 'rqod-1001-1',
        siteId: 1001,
        title: 'Mirpur COD follow-up',
        buyerName: 'Ayesha Rahman',
        buyerPhone: '8801711111111',
        buyerAddress: 'Mirpur 10, Dhaka',
        note: 'Keep price tight and confirm evening delivery before dispatch.',
        deliveryLabel: 'SteadFast Courier',
        deliveryCharge: 80,
        lines: const <ResellerOrderLineDraft>[
          ResellerOrderLineDraft(
            id: 7001,
            title: 'Classic Cotton Panjabi',
            thumbnail: '',
            quantity: 1,
            basePrice: 610,
            sellPrice: 790,
            minSellPrice: 760,
            maxSellPrice: 860,
            vat: 0,
          ),
        ],
      ).toJson(),
      _seedQuickOrderDraft(
        id: 'rqod-1002-1',
        siteId: 1002,
        title: 'Referral kitchen closer',
        buyerName: 'Tanvir Hasan',
        buyerPhone: '8801811111111',
        buyerAddress: 'Agrabad, Chattogram',
        note: 'Referral lead. Push same-day confirmation and COD trust line.',
        deliveryLabel: 'SteadFast Courier',
        deliveryCharge: 120,
        lines: const <ResellerOrderLineDraft>[
          ResellerOrderLineDraft(
            id: 7101,
            title: 'Smart Blender Pro',
            thumbnail: '',
            quantity: 1,
            basePrice: 1180,
            sellPrice: 1450,
            minSellPrice: 1390,
            maxSellPrice: 1550,
            vat: 0,
          ),
        ],
      ).toJson(),
    ]);
    await _replaceCollection(
      _buyerRiskProfilesCollection,
      <Map<String, dynamic>>[
        _seedBuyerRiskProfile(
          buyerId: _buyerIdentityKey(
            phone: '8801711111111',
            name: 'Ayesha Rahman',
          ),
          siteId: 1001,
          buyerName: 'Ayesha Rahman',
          buyerPhone: '8801711111111',
          riskLevel: 'low',
          riskScore: 24,
          reasonCodes: const <String>['repeat_buyer', 'confirmed_contact'],
          recommendedAction: 'Safe to offer COD. Keep evening delivery promise.',
          totalOrders: 1,
          deliveredOrders: 0,
          returnCount: 0,
          pendingOrders: 1,
          unpaidOrders: 1,
          lastOrderId: 'SH9101',
          note: 'Responsive on WhatsApp and easy to re-engage.',
        ).toJson(),
        _seedBuyerRiskProfile(
          buyerId: _buyerIdentityKey(
            phone: '8801311111111',
            name: 'Rafiq Uddin',
          ),
          siteId: 1001,
          buyerName: 'Rafiq Uddin',
          buyerPhone: '8801311111111',
          riskLevel: 'high',
          riskScore: 82,
          reasonCodes: const <String>['returned_order', 'address_mismatch'],
          recommendedAction:
              'Require call confirmation and partial advance before dispatch.',
          totalOrders: 1,
          deliveredOrders: 0,
          returnCount: 1,
          pendingOrders: 0,
          unpaidOrders: 1,
          lastOrderId: 'SH9106',
          note: 'Past return came from address mismatch and low response.',
        ).toJson(),
      ],
    );
    await _replaceCollection(
      _orderGroupDraftsCollection,
      <Map<String, dynamic>>[
        _seedOrderGroupDraft(
          id: 'sogd-1001-1',
          siteId: 1001,
          title: 'Dhaka metro cotton run',
          channel: 'WhatsApp',
          buyerIds: const <String>[
            'phone:8801711111111',
            'phone:8801911111111',
          ],
          quickOrderDraftIds: const <String>['rqod-1001-1'],
          tags: const <String>['cod', 'dhaka', 'cotton'],
          note: 'Batch this with metro buyers for faster supplier follow-up.',
          targetOrderCount: 3,
          projectedRevenue: 2370,
        ).toJson(),
      ],
    );
    await _replaceCollection(_shareAssetDraftsCollection, <Map<String, dynamic>>[
      _seedShareAssetDraft(
        id: 'rsad-1001-1',
        siteId: 1001,
        title: 'Panjabi Eid post',
        channel: 'Facebook',
        assetType: 'image',
        assetUrl: 'https://local.sellhub/assets/panjabi-eid-post.png',
        thumbnailUrl: 'https://local.sellhub/assets/panjabi-eid-thumb.png',
        caption:
            'Premium cotton panjabi, COD available, fast Dhaka delivery.',
        callToAction: 'Inbox to confirm size and delivery slot.',
        targetBuyerIds: const <String>['phone:8801711111111'],
        productTitles: const <String>['Classic Cotton Panjabi'],
        tags: const <String>['eid', 'facebook', 'cod'],
      ).toJson(),
    ]);
    await _replaceCollection(_quotesCollection, const <Map<String, dynamic>>[]);
    await _replaceCollection(_ordersCollection, <Map<String, dynamic>>[
      _seedOrder(
        id: 9101,
        siteId: 1001,
        customerId: demoUserId * 10 + 1001,
        customerName: 'Ayesha Rahman',
        customerPhone: 8801711111111,
        customerAddress: 'Mirpur 10, Dhaka',
        total: 790,
        cost: 610,
        profit: 180,
        resellAmount: 790,
        isSettle: false,
        status: 2,
        customerNote: 'Prefers evening delivery',
        logisticsText: 'Dhaka Metro',
        lines: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 7001,
            'title': 'Classic Cotton Panjabi',
            'price': 790,
            'resellPrice': 610,
            'quantity': 1,
          },
        ],
      ),
      _seedOrder(
        id: 9103,
        siteId: 1001,
        customerId: demoUserId * 10 + 1001,
        customerName: 'Sadia Khan',
        customerPhone: 8801911111111,
        customerAddress: 'Bashundhara, Dhaka',
        total: 920,
        cost: 720,
        profit: 200,
        resellAmount: 920,
        isSettle: false,
        status: 10,
        customerNote: 'Facebook lead, verified by call',
        logisticsText: 'Dhaka Metro',
        lines: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 7002,
            'title': 'Premium Cotton Saree',
            'price': 920,
            'resellPrice': 720,
            'quantity': 1,
          },
        ],
      ),
      _seedOrder(
        id: 9104,
        siteId: 1001,
        customerId: demoUserId * 10 + 1001,
        customerName: 'Nafisa Ahmed',
        customerPhone: 8801611111111,
        customerAddress: 'Uttara Sector 11, Dhaka',
        total: 1080,
        cost: 860,
        profit: 220,
        resellAmount: 1080,
        isSettle: true,
        status: 10,
        customerNote: 'COD buyer, prefers evening delivery',
        logisticsText: 'Dhaka Metro',
        lines: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 7001,
            'title': 'Classic Cotton Panjabi',
            'price': 1080,
            'resellPrice': 860,
            'quantity': 1,
          },
        ],
      ),
      _seedOrder(
        id: 9105,
        siteId: 1001,
        customerId: demoUserId * 10 + 1001,
        customerName: 'Hasibul Islam',
        customerPhone: 8801511111111,
        customerAddress: 'Jatrabari, Dhaka',
        total: 990,
        cost: 800,
        profit: 190,
        resellAmount: 990,
        isSettle: true,
        status: 10,
        customerNote: 'Repeat buyer',
        logisticsText: 'Dhaka Metro',
        lines: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 7002,
            'title': 'Premium Cotton Saree',
            'price': 990,
            'resellPrice': 800,
            'quantity': 1,
          },
        ],
      ),
      _seedOrder(
        id: 9106,
        siteId: 1001,
        customerId: demoUserId * 10 + 1001,
        customerName: 'Rafiq Uddin',
        customerPhone: 8801311111111,
        customerAddress: 'Keraniganj, Dhaka',
        total: 760,
        cost: 630,
        profit: 130,
        resellAmount: 760,
        isSettle: false,
        status: 8,
        customerNote: 'Return due to address mismatch',
        logisticsText: 'Outside core zone',
        lines: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 7001,
            'title': 'Classic Cotton Panjabi',
            'price': 760,
            'resellPrice': 630,
            'quantity': 1,
          },
        ],
      ),
      _seedOrder(
        id: 9102,
        siteId: 1002,
        customerId: demoUserId * 10 + 1002,
        customerName: 'Tanvir Hasan',
        customerPhone: 8801811111111,
        customerAddress: 'Agrabad, Chattogram',
        total: 1450,
        cost: 1180,
        profit: 270,
        resellAmount: 1450,
        isSettle: true,
        status: 4,
        customerNote: 'Referral buyer',
        logisticsText: 'Chattogram City',
        lines: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 7101,
            'title': 'Smart Blender Pro',
            'price': 1450,
            'resellPrice': 1180,
            'quantity': 1,
          },
        ],
      ),
    ]);
    await _replaceCollection(_orderEventsCollection, <Map<String, dynamic>>[
      _eventJson(
        id: 50101,
        orderId: 9101,
        siteId: 1001,
        eventType: 1,
        note: 'Buyer confirmed order on WhatsApp',
        address: 'Mirpur 10, Dhaka',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      _eventJson(
        id: 50102,
        orderId: 9101,
        siteId: 1001,
        eventType: 2,
        note: 'Supplier packed order',
        address: 'Mirpur 10, Dhaka',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      _eventJson(
        id: 50103,
        orderId: 9102,
        siteId: 1002,
        eventType: 4,
        note: 'Order delivered successfully',
        address: 'Agrabad, Chattogram',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);
    await _replaceCollection(_reviewsCollection, <Map<String, dynamic>>[
      _seedReview(
        id: 60101,
        productId: 7001,
        siteId: 1001,
        userId: demoUserId,
        name: 'Nusrat Jahan',
        rating: 5,
        description:
            'Easy to sell on Facebook. Buyers liked the fabric quality and sizing.',
        daysAgo: 6,
      ),
      _seedReview(
        id: 60102,
        productId: 7101,
        siteId: 1002,
        userId: demoUserId,
        name: 'Mehedi Hasan',
        rating: 4,
        description:
            'Good margin and low complaint rate. Delivery took one extra day once.',
        daysAgo: 9,
      ),
      _seedReview(
        id: 60103,
        productId: 7202,
        siteId: 1003,
        userId: demoUserId,
        name: 'Farzana Akter',
        rating: 5,
        description:
            'Repeat buyers came back for this serum. Caption plus trust card works well.',
        daysAgo: 3,
      ),
    ]);
    await saveLocalSeedVersion(
      _client,
      seedKey: _seedKey,
      version: _seedVersion,
    );
  }

  Future<bool> _updateAddressBook({
    required int customerId,
    required StoreCustomerAddressModel address,
    required String key,
    required bool add,
  }) async {
    final customer = await _loadCustomerById(customerId);
    if (customer == null) return false;
    final items = (customer[key] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: true);
    items.removeWhere((item) => (item['id'] as num?)?.toInt() == address.id);
    if (add) {
      items.add(address.toInputJson());
    }
    customer[key] = items;
    await _upsertEntity(
      _customersCollection,
      _customerKey(
        (customer['siteId'] as num?)?.toInt() ?? 0,
        (customer['userId'] as num?)?.toInt() ?? 0,
      ),
      customer,
    );
    return true;
  }

  Future<bool> _mutateCustomer({
    required int customerId,
    required int userId,
    required void Function(Map<String, dynamic> customer) mutate,
  }) async {
    final customer = await _loadCustomerById(customerId);
    if (customer == null) return false;
    mutate(customer);
    await _upsertEntity(
      _customersCollection,
      _customerKey(
        (customer['siteId'] as num?)?.toInt() ?? 0,
        (customer['userId'] as num?)?.toInt() ?? userId,
      ),
      customer,
    );
    return true;
  }

  Future<Map<String, dynamic>?> _loadCustomerById(int customerId) async {
    final customers = await _loadCollection(_customersCollection);
    for (final customer in customers) {
      if ((customer['id'] as num?)?.toInt() == customerId) return customer;
    }
    return null;
  }

  String _customerKey(int siteId, int userId) => '$siteId-$userId';

  String _pricingMemoryKey(int siteId, int userId, int productId) =>
      '$siteId-$userId-$productId';

  String _buyerIdentityKey({required String phone, required String name}) {
    final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '').trim();
    if (normalizedPhone.isNotEmpty && normalizedPhone != '0') {
      return 'phone:$normalizedPhone';
    }
    return 'name:${name.trim().toLowerCase()}';
  }

  Future<void> _recordPricingMemoryObservation({
    required int userId,
    required int siteId,
    required int productId,
    required int successfulPrice,
  }) async {
    final existing = await _loadEntity(
      _pricingMemoryCollection,
      _pricingMemoryKey(siteId, userId, productId),
    );
    final current = existing == null
        ? ProductPricingMemory(
            productId: productId,
            siteId: siteId,
            userId: userId,
            lastSuccessfulPrice: successfulPrice,
            mostCommonSuccessfulPrice: successfulPrice,
            successfulOrderCount: 0,
            priceFrequency: const <int, int>{},
          )
        : ProductPricingMemory.fromJson(existing);
    final frequency = Map<int, int>.from(current.priceFrequency);
    frequency[successfulPrice] = (frequency[successfulPrice] ?? 0) + 1;
    final mostCommonSuccessfulPrice = frequency.entries.toList(growable: false)
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return b.key.compareTo(a.key);
      });
    final updated = ProductPricingMemory(
      productId: productId,
      siteId: siteId,
      userId: userId,
      lastSuccessfulPrice: successfulPrice,
      mostCommonSuccessfulPrice: mostCommonSuccessfulPrice.first.key,
      successfulOrderCount: current.successfulOrderCount + 1,
      priceFrequency: frequency,
    );
    await _upsertEntity(
      _pricingMemoryCollection,
      _pricingMemoryKey(siteId, userId, productId),
      updated.toJson(),
    );
  }

  bool _isDeliveredOrder(Map<String, dynamic> order) {
    final status = (order['status'] as num?)?.toInt() ?? 0;
    return status >= 4 || status == 10;
  }

  bool _isReturnedOrder(Map<String, dynamic> order) {
    final status = (order['status'] as num?)?.toInt() ?? 0;
    return status == 8;
  }

  String _inferSourceTag(List<Map<String, dynamic>> orders) {
    final notes = orders
        .map((item) => ((item['customerNote'] as String?) ?? '').toLowerCase())
        .join(' ');
    if (notes.contains('facebook')) return 'Facebook';
    if (notes.contains('referral')) return 'Referral';
    if (notes.contains('whatsapp')) return 'WhatsApp';
    return orders.length >= 2 ? 'Repeat' : 'WhatsApp';
  }

  List<String> _collectPreferredProducts(List<Map<String, dynamic>> orders) {
    final productFrequency = <String, int>{};
    for (final order in orders) {
      final lines = (order['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item));
      for (final line in lines) {
        final title = (line['title'] as String?)?.trim() ?? '';
        if (title.isEmpty) continue;
        productFrequency[title] = (productFrequency[title] ?? 0) + 1;
      }
    }
    final sorted = productFrequency.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((item) => item.key).toList(growable: false);
  }

  String _extractDistrict(String address) {
    final parts = address
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'Unknown district';
    return parts.length >= 2 ? parts.last : parts.first;
  }

  String _normalizeIdentity(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  String _supplierKeyFromLine(
    Map<String, dynamic> line, {
    required int fallbackSiteId,
  }) {
    final supplierId =
        line['supplierId'] ?? line['siteId'] ?? line['storeId'] ?? fallbackSiteId;
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

  BuyerRiskProfile _deriveBuyerRiskProfile(
    BuyerBookProfile buyer,
    int userId,
    int siteId,
  ) {
    final score =
        (buyer.returnCount * 45) +
        (buyer.unpaidOrders * 15) +
        (buyer.pendingOrders * 10) +
        (buyer.isBlocked ? 30 : 0) +
        (buyer.isRisky ? 15 : 0);
    final boundedScore = score.clamp(0, 100).toInt();
    final riskLevel = boundedScore >= 75
        ? 'high'
        : boundedScore >= 40
        ? 'medium'
        : 'low';
    final reasonCodes = <String>[
      if (buyer.returnCount > 0) 'returned_order',
      if (buyer.unpaidOrders > 0) 'unpaid_order',
      if (buyer.pendingOrders > 0) 'pending_fulfillment',
      if (buyer.isBlocked) 'blocked_buyer',
      if (buyer.totalOrders >= 2 && buyer.returnCount == 0) 'repeat_buyer',
    ];
    final recommendedAction = boundedScore >= 75
        ? 'Require call confirmation and partial advance before dispatch.'
        : boundedScore >= 40
        ? 'Confirm address and delivery slot before placing supplier order.'
        : 'Safe to handle as standard COD with regular follow-up.';
    return BuyerRiskProfile(
      id: buyer.id,
      userId: userId,
      siteId: siteId,
      buyerName: buyer.name,
      buyerPhone: buyer.phone,
      riskLevel: riskLevel,
      riskScore: boundedScore,
      blocked: buyer.isBlocked,
      note: buyer.note,
      reasonCodes: reasonCodes,
      recommendedAction: recommendedAction,
      totalOrders: buyer.totalOrders,
      deliveredOrders: buyer.totalDelivered,
      returnCount: buyer.returnCount,
      pendingOrders: buyer.pendingOrders,
      unpaidOrders: buyer.unpaidOrders,
      lastOrderId: buyer.lastOrderId,
      updatedAt: buyer.lastOrderedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _customerToSelfJson(Map<String, dynamic> customer) {
    return <String, dynamic>{
      ...customer,
      'billingAddress': customer['billingAddress'] ?? <dynamic>[],
      'shippingAddress': customer['shippingAddress'] ?? <dynamic>[],
    };
  }

  Map<String, dynamic> _customerToProfileJson(Map<String, dynamic> customer) {
    return <String, dynamic>{
      ...customer,
      'blockProducts': const <dynamic>[],
      'cartProducts': const <dynamic>[],
      'note': null,
      'billingAddress': customer['billingAddress'] ?? <dynamic>[],
      'shippingAddress': customer['shippingAddress'] ?? <dynamic>[],
    };
  }

  Map<String, dynamic> _customerToResellerJson(Map<String, dynamic> customer) {
    return <String, dynamic>{
      ..._customerToProfileJson(customer),
      'affiliatePaid': (customer['affiliatePaid'] as num?)?.toInt() ?? 0,
      'affiliateProcessing':
          (customer['affiliateProcessing'] as num?)?.toInt() ?? 0,
      'affiliateTotal': (customer['affiliateTotal'] as num?)?.toInt() ?? 0,
      'affiliatePayable': (customer['affiliatePayable'] as num?)?.toInt() ?? 0,
    };
  }

  Map<String, dynamic> _pricingMemory({
    required int productId,
    required int siteId,
    required int lastSuccessfulPrice,
    required int mostCommonSuccessfulPrice,
    required int successfulOrderCount,
    required Map<int, int> frequency,
  }) {
    return ProductPricingMemory(
      productId: productId,
      siteId: siteId,
      userId: demoUserId,
      lastSuccessfulPrice: lastSuccessfulPrice,
      mostCommonSuccessfulPrice: mostCommonSuccessfulPrice,
      successfulOrderCount: successfulOrderCount,
      priceFrequency: frequency,
    ).toJson();
  }

  Future<List<Map<String, dynamic>>> _loadCollection(String collection) async {
    final result = await _client.query(
      QueryOptions(
        document: _listCollectionDocument,
        variables: <String, dynamic>{'collection': collection},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) throw result.exception!;
    return (result.data?['listCollection'] as List<dynamic>? ??
            const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => Map<String, dynamic>.from(
            jsonDecode(item['payload'] as String? ?? '{}') as Map,
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> _loadEntity(
    String collection,
    String id,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: _getEntityDocument,
        variables: <String, dynamic>{'collection': collection, 'id': id},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) throw result.exception!;
    final entity = result.data?['getEntity'];
    if (entity is! Map<String, dynamic>) return null;
    return Map<String, dynamic>.from(
      jsonDecode(entity['payload'] as String? ?? '{}') as Map,
    );
  }

  Future<void> _replaceCollection(
    String collection,
    List<Map<String, dynamic>> items,
  ) async {
    final result = await _client.mutate(
      MutationOptions(
        document: _replaceCollectionDocument,
        variables: <String, dynamic>{
          'collection': collection,
          ...encodeLocalEntityList<Map<String, dynamic>>(
            items: items,
            toJson: (item) => item,
            idOf: (item) => (item['id'] ?? item['orderId'] ?? '').toString(),
            updatedAtOf: (_) => DateTime.now().toIso8601String(),
          ),
        },
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) throw result.exception!;
  }

  Future<void> _upsertEntity(
    String collection,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final result = await _client.mutate(
      MutationOptions(
        document: _upsertEntityDocument,
        variables: <String, dynamic>{
          'collection': collection,
          'id': id,
          'payload': jsonEncode(payload),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) throw result.exception!;
  }

  Future<bool> _deleteEntity(String collection, String id) async {
    final result = await _client.mutate(
      MutationOptions(
        document: _deleteEntityDocument,
        variables: <String, dynamic>{'collection': collection, 'id': id},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) throw result.exception!;
    return result.data?['deleteEntity']?['deleted'] == true;
  }

  String _teamConfigKey(int userId, int siteId) => 'team-config-$siteId-$userId';

  static Map<String, dynamic> _seedCustomer({
    required int id,
    required int userId,
    required int siteId,
    required String title,
    required int phone,
  }) {
    final supplier = SellHubCatalogSeed.suppliers.firstWhere(
      (item) => (item['id'] as num).toInt() == siteId,
    );
    return <String, dynamic>{
      'address': supplier['address'],
      'affiliatePaid': 0,
      'affiliatePayable': 0,
      'affiliateProcessing': 0,
      'affiliateTotal': 0,
      'avatar': supplier['phoneLogo'],
      'billingAddress': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': siteId * 100 + 1,
          'address': supplier['address'],
          'formattedAddress': supplier['address'],
          'latitude': 23.8103,
          'longitude': 90.4125,
        },
      ],
      'cartCount': 0,
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'createdById': userId,
      'currency': 'BDT',
      'customerType': 2,
      'customerTypes': <int>[2],
      'domain': supplier['domain'],
      'favorite': <int>[
        if (siteId == 1001) 7002 else if (siteId == 1002) 7101 else 7201,
      ],
      'formattedAddress': supplier['address'],
      'hid': 'cust$id',
      'id': id,
      'isActive': true,
      'isAffiliate': false,
      'isAffiliateCommission': false,
      'isAffiliateJoin': false,
      'isReseller': true,
      'isWholesale': false,
      'latitude': 23.8103,
      'longitude': 90.4125,
      'nid': null,
      'ordersCancelled': 0,
      'ordersConfirmed': 1,
      'ordersDelivered': 1,
      'ordersOnTheWay': 0,
      'ordersPackaging': 0,
      'ordersPending': 1,
      'ordersPlaced': 2,
      'ordersRejected': 0,
      'ordersReturned': 0,
      'ordersShipment': 0,
      'ordersStation': 0,
      'ordersTotal': 2,
      'paymentNo': '01700000000',
      'paymentTitle': 'bKash',
      'pendingBalance': 0,
      'pendingCashbackBalance': 0,
      'pendingGiftCardBalance': 0,
      'pendingProfit': 180,
      'pendingPurchase': 0,
      'pendingRewardPoints': 0,
      'phone': phone,
      'referId': null,
      'referCode': 'SELL$userId',
      'resellerCommissionPercentage': 12,
      'resellPaid': 270,
      'resellPayable': 180,
      'resellProcessing': 0,
      'resellTotal': 1450,
      'shippingAddress': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': siteId * 100 + 2,
          'address': 'Repeat buyer zone, ${supplier['address']}',
          'formattedAddress': 'Repeat buyer zone, ${supplier['address']}',
          'latitude': 23.8103,
          'longitude': 90.4125,
        },
      ],
      'siteId': siteId,
      'tags': 'local-seed,reseller',
      'title': title,
      'totalBalance': 0,
      'totalCashbackBalance': 0,
      'totalGiftCardBalance': 0,
      'totalPaid': 270,
      'totalProfit': 450,
      'totalPurchase': 0,
      'totalReturnCharge': 0,
      'totalRewardPoints': 0,
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedById': userId,
      'userId': userId,
    };
  }

  static Map<String, dynamic> _paymentMethod({
    required int id,
    required int siteId,
    required String title,
    required String note,
    required String logo,
    int gatewayType = 1,
  }) {
    return <String, dynamic>{
      'siteId': siteId,
      'discount': 0,
      'fee': 0,
      'gatewayType': gatewayType,
      'id': id,
      'isActive': true,
      'isDiscount': false,
      'isFreeLogistics': false,
      'isManual': gatewayType == 1,
      'isSandbox': true,
      'note': note,
      'priority': id,
      'title': title,
      'logo': logo,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static QuickOrderDraft _seedQuickOrderDraft({
    required String id,
    required int siteId,
    required String title,
    required String buyerName,
    required String buyerPhone,
    required String buyerAddress,
    required String note,
    required String deliveryLabel,
    required int deliveryCharge,
    required List<ResellerOrderLineDraft> lines,
  }) {
    final subtotal = lines.fold<int>(0, (sum, item) => sum + item.lineSellTotal);
    final now = DateTime.now().subtract(const Duration(hours: 6));
    return QuickOrderDraft(
      id: id,
      userId: demoUserId,
      siteId: siteId,
      title: title,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerAddress: buyerAddress,
      note: note,
      status: 'draft',
      deliveryLabel: deliveryLabel,
      deliveryCharge: deliveryCharge,
      subtotal: subtotal,
      total: subtotal + deliveryCharge,
      lines: lines,
      createdAt: now,
      updatedAt: now,
    );
  }

  static BuyerRiskProfile _seedBuyerRiskProfile({
    required String buyerId,
    required int siteId,
    required String buyerName,
    required String buyerPhone,
    required String riskLevel,
    required int riskScore,
    required List<String> reasonCodes,
    required String recommendedAction,
    required int totalOrders,
    required int deliveredOrders,
    required int returnCount,
    required int pendingOrders,
    required int unpaidOrders,
    required String lastOrderId,
    required String note,
  }) {
    return BuyerRiskProfile(
      id: buyerId,
      userId: demoUserId,
      siteId: siteId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      riskLevel: riskLevel,
      riskScore: riskScore,
      blocked: riskLevel == 'high',
      note: note,
      reasonCodes: reasonCodes,
      recommendedAction: recommendedAction,
      totalOrders: totalOrders,
      deliveredOrders: deliveredOrders,
      returnCount: returnCount,
      pendingOrders: pendingOrders,
      unpaidOrders: unpaidOrders,
      lastOrderId: lastOrderId,
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
    );
  }

  static OrderGroupDraft _seedOrderGroupDraft({
    required String id,
    required int siteId,
    required String title,
    required String channel,
    required List<String> buyerIds,
    required List<String> quickOrderDraftIds,
    required List<String> tags,
    required String note,
    required int targetOrderCount,
    required int projectedRevenue,
  }) {
    final now = DateTime.now().subtract(const Duration(hours: 4));
    return OrderGroupDraft(
      id: id,
      userId: demoUserId,
      siteId: siteId,
      title: title,
      status: 'draft',
      channel: channel,
      buyerIds: buyerIds,
      quickOrderDraftIds: quickOrderDraftIds,
      tags: tags,
      note: note,
      targetOrderCount: targetOrderCount,
      projectedRevenue: projectedRevenue,
      createdAt: now,
      updatedAt: now,
    );
  }

  static ShareAssetDraft _seedShareAssetDraft({
    required String id,
    required int siteId,
    required String title,
    required String channel,
    required String assetType,
    required String assetUrl,
    required String thumbnailUrl,
    required String caption,
    required String callToAction,
    required List<String> targetBuyerIds,
    required List<String> productTitles,
    required List<String> tags,
  }) {
    return ShareAssetDraft(
      id: id,
      userId: demoUserId,
      siteId: siteId,
      title: title,
      channel: channel,
      assetType: assetType,
      assetUrl: assetUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      callToAction: callToAction,
      targetBuyerIds: targetBuyerIds,
      productTitles: productTitles,
      tags: tags,
      status: 'draft',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  static Map<String, dynamic> _seedOrder({
    required int id,
    required int siteId,
    required int customerId,
    required String customerName,
    required int customerPhone,
    required String customerAddress,
    required int total,
    required int cost,
    required int profit,
    required int resellAmount,
    required bool isSettle,
    required int status,
    String customerNote = '',
    String logisticsText = '',
    List<Map<String, dynamic>> lines = const <Map<String, dynamic>>[],
  }) {
    return <String, dynamic>{
      'id': id,
      'siteId': siteId,
      'userId': demoUserId,
      'customerId': customerId,
      'currency': 'BDT',
      'customerAddress': customerAddress,
      'customerName': customerName,
      'customerNote': customerNote,
      'customerPhone': customerPhone,
      'buyerContacted': false,
      'orderId': 'SH$id',
      'paid': isSettle ? profit : 0,
      'profit': profit.toDouble(),
      'resellAmount': resellAmount.toDouble(),
      'status': status,
      'total': total.toDouble(),
      'cost': cost,
      'isSettle': isSettle,
      'logisticsText': logisticsText,
      'supportIssue': false,
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'updatedAt': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'events': const <dynamic>[],
      'lines': lines,
    };
  }

  static Map<String, dynamic> _eventJson({
    required int id,
    required int orderId,
    int siteId = 0,
    required int eventType,
    required String note,
    required String address,
    required DateTime createdAt,
  }) {
    return <String, dynamic>{
      'id': id,
      'orderId': orderId,
      'siteId': siteId,
      'createdAt': createdAt.toIso8601String(),
      'eventType': eventType,
      'note': note,
      'isPublic': true,
      'address': address,
      'location': address,
    };
  }

  static Map<String, dynamic> _seedReview({
    required int id,
    required int productId,
    required int siteId,
    required int userId,
    required String name,
    required int rating,
    required String description,
    required int daysAgo,
  }) {
    return <String, dynamic>{
      'id': id,
      'productId': productId,
      'siteId': siteId,
      'userId': userId,
      'rating': rating,
      'description': description,
      'createdAt': DateTime.now()
          .subtract(Duration(days: daysAgo))
          .toIso8601String(),
      'user': <String, dynamic>{'id': userId, 'name': name, 'avatar': null},
    };
  }
}
