import 'package:sellhub/core/local_seed/sellhub_commerce_local_store.dart';
import 'package:sellhub/core/pricing/smart_pricing.dart';
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
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';

import 'models/paymentgateway_req.dart';

class CheckoutRepository {
  CheckoutRepository(Object? client, this._commerceStore);

  final SellHubCommerceLocalStore _commerceStore;

  Future<List<DeliveryPlaceRes>> fetchDeliveryPlace(int siteUserId) {
    return _commerceStore.fetchDeliveryPlace(siteUserId);
  }

  Future<List<PaymentMethodRes>> fetchPaymentMethod(int siteId) {
    return _commerceStore.fetchPaymentMethod(siteId);
  }

  Future<Map<int, ProductPricingMemory>> fetchPricingMemories({
    required int userId,
    required int siteId,
    required List<int> productIds,
  }) {
    return _commerceStore.fetchPricingMemories(
      userId: userId,
      siteId: siteId,
      productIds: productIds,
    );
  }

  Future<OrderCreateRes> makeOrder(
    OrderCreateReq model, {
    required bool isAuthenticated,
    int? userId,
    int? customerId,
  }) {
    return _commerceStore.makeOrder(
      model,
      isAuthenticated: isAuthenticated,
      userId: userId,
      customerId: customerId,
    );
  }

  Future<ResellerQuote> createQuote(ResellerQuote quote) {
    return _commerceStore.createQuote(quote);
  }

  Future<ResellerQuote> upsertQuote(ResellerQuote quote) {
    return _commerceStore.upsertQuote(quote);
  }

  Future<void> markQuoteConverted({
    required String quoteId,
    required String orderId,
  }) {
    return _commerceStore.markQuoteConverted(
      quoteId: quoteId,
      orderId: orderId,
    );
  }

  Future<bool> deleteQuote(String quoteId) {
    return _commerceStore.deleteQuote(quoteId);
  }

  Future<PaymentGatewayResponse> paymentGatewayRequest(
    PaymentGatewayReq model,
  ) {
    return _commerceStore.paymentGatewayRequest(model);
  }

  Future<SelfStoreCustomerRes?> fetchCustomerContext({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchCustomerContext(userId: userId, siteId: siteId);
  }

  Future<VoucherCheckRes> checkVoucher({
    required int siteId,
    required String code,
    required double quantity,
    required double total,
    required double delivery,
    required List<Map<String, dynamic>> products,
    int? userId,
  }) {
    return _commerceStore.checkVoucher(
      siteId: siteId,
      code: code,
      quantity: quantity,
      total: total,
      delivery: delivery,
      products: products,
      userId: userId,
    );
  }

  Future<List<OrderEventModel>> fetchOrderEvents({
    required int siteId,
    required int orderId,
  }) {
    return _commerceStore.fetchOrderEvents(siteId: siteId, orderId: orderId);
  }

  Future<OrderEventModel> createCustomerOrderEvent({
    required int userId,
    required int siteId,
    required int orderId,
    required int eventType,
    required String note,
  }) {
    return _commerceStore.createCustomerOrderEvent(
      userId: userId,
      siteId: siteId,
      orderId: orderId,
      eventType: eventType,
      note: note,
    );
  }

  Future<bool> deleteLatestCustomerOrderEvent({
    required int siteId,
    required int orderId,
    required int eventType,
  }) {
    return _commerceStore.deleteLatestCustomerOrderEvent(
      siteId: siteId,
      orderId: orderId,
      eventType: eventType,
    );
  }

  Future<bool> addShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _commerceStore.addShippingAddress(
      customerId: customerId,
      address: address,
    );
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
      'id': (draft['id'] ?? draft['draftId'] ?? _quickOrderDraftId(
        userId: userId,
        siteId: siteId,
      ))
          .toString(),
      'draftId': (draft['draftId'] ?? draft['id'] ?? _quickOrderDraftId(
        userId: userId,
        siteId: siteId,
      ))
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
    final buyers = await _commerceStore.fetchBuyerBook(userId: userId, siteId: siteId);
    for (final buyer in buyers) {
      if (_normalizeIdentity(buyer.phone) == _normalizeIdentity(buyerPhone) &&
          buyer.phone.trim().isNotEmpty) {
        return buyer;
      }
    }
    if (buyerName.isEmpty) return null;
    for (final buyer in buyers) {
      if (_normalizeIdentity(buyer.name) == _normalizeIdentity(buyerName)) {
        return buyer;
      }
    }
    return null;
  }

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
      if ((buyer?.returnCount ?? 0) > 0) '${buyer!.returnCount} returned orders',
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
    }).toList(growable: false)
      ..sort(
        (a, b) => _toDouble(b['sellAmount']).compareTo(_toDouble(a['sellAmount'])),
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

  String _quickOrderDraftId({
    required int userId,
    required int siteId,
  }) {
    return 'quick-order-$userId-$siteId';
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
}
