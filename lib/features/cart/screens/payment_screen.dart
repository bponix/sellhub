import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/pricing/smart_pricing.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/data/models/delivery_place_res.dart';
import 'package:sellhub/features/cart/data/models/order_create_req.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';
import 'package:sellhub/features/cart/data/models/payment_method_res.dart';
import 'package:sellhub/features/cart/data/models/paymentgateway_req.dart';
import 'package:sellhub/features/cart/data/models/reseller_order_line_draft.dart';
import 'package:sellhub/features/cart/data/models/reseller_quote.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_state.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_state.dart';
import 'package:sellhub/features/cart/screens/order_complete_welcome.dart';
import 'package:sellhub/features/cart/screens/multi_order_complete_screen.dart';
import 'package:sellhub/features/cart/screens/payment_gateway_webview_screen.dart';
import 'package:sellhub/features/cart/screens/quote_preview_screen.dart';
import 'package:sellhub/features/cart/screens/widget/selectableAreaPay.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/injection_container.dart' as di;

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.phone,
    required this.name,
    required this.address,
    required this.isCart,
    this.title,
    this.id,
    this.basePrice,
    this.minSellPrice,
    this.maxSellPrice,
    this.thumbnail,
  });

  final bool isCart;
  final String? title;
  final int? id;
  final int phone;
  final String name;
  final String address;
  final int? basePrice;
  final int? minSellPrice;
  final int? maxSellPrice;
  final String? thumbnail;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Map<String, TextEditingController> _sellPriceControllers =
      <String, TextEditingController>{};
  Map<int, ProductPricingMemory> _pricingMemories =
      const <int, ProductPricingMemory>{};
  bool _loadingPricingMemories = false;
  Future<BuyerBookProfile?>? _buyerConfidenceFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPricingMemories();
    });
    _buyerConfidenceFuture = _loadBuyerConfidence();
  }

  @override
  void dispose() {
    for (final controller in _sellPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPricingMemories() async {
    if (_loadingPricingMemories || !mounted) return;
    final cartCubit = context.read<CartCubit>();
    final checkoutCubit = context.read<CheckoutCubit>();
    final siteId = StoreScope.activeSiteId(context);
    final userId = await LocalStorage.getUserID();
    if (!mounted || userId == null || userId <= 0) return;
    final cartState = cartCubit.state;
    final productIds = _draftLines(
      cartState,
    ).map((line) => line.id).whereType<int>().toSet().toList(growable: false);
    if (productIds.isEmpty) return;
    setState(() {
      _loadingPricingMemories = true;
    });
    try {
      final memories = await checkoutCubit.fetchPricingMemories(
        userId: userId,
        siteId: siteId,
        productIds: productIds,
      );
      if (!mounted) return;
      setState(() {
        _pricingMemories = memories;
        _loadingPricingMemories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPricingMemories = false;
      });
    }
  }

  Future<BuyerBookProfile?> _loadBuyerConfidence() async {
    final siteId = StoreScope.activeSiteId(context);
    final userId = await LocalStorage.getUserID() ?? 0;
    if (userId <= 0 || widget.phone <= 0) return null;
    final buyers = await di.sl<ProfileRepository>().fetchBuyerBook(
      userId: userId,
      siteId: siteId,
    );
    final normalized = '${widget.phone}'.trim();
    for (final buyer in buyers) {
      final phone = buyer.phone.startsWith('88')
          ? buyer.phone.substring(2)
          : buyer.phone;
      if (phone == normalized ||
          buyer.phone == normalized ||
          buyer.phone == '88$normalized') {
        return buyer;
      }
    }
    return null;
  }

  int _normalizedMinSellPrice({
    required int basePrice,
    int? minSellPrice,
    int? maxSellPrice,
  }) {
    final floor = minSellPrice ?? basePrice;
    final ceil = maxSellPrice ?? floor;
    if (floor <= 0 && ceil > 0) return ceil;
    if (floor <= 0) return basePrice;
    return floor;
  }

  int _normalizedMaxSellPrice({
    required int basePrice,
    int? minSellPrice,
    int? maxSellPrice,
  }) {
    final floor = _normalizedMinSellPrice(
      basePrice: basePrice,
      minSellPrice: minSellPrice,
      maxSellPrice: maxSellPrice,
    );
    final ceiling = maxSellPrice ?? floor;
    if (ceiling < floor) return floor;
    return ceiling <= 0 ? floor : ceiling;
  }

  int _defaultSellPrice({
    required int basePrice,
    required int minSellPrice,
    required int maxSellPrice,
  }) {
    if (maxSellPrice >= minSellPrice && maxSellPrice > 0) {
      return maxSellPrice;
    }
    if (minSellPrice > 0) return minSellPrice;
    return basePrice;
  }

  List<ResellerOrderLineDraft> _draftLines(CartState cartState) {
    if (widget.isCart) {
      return cartState.items
          .map((item) {
            final basePrice = item.product.price?.toInt() ?? 0;
            final minSellPrice = _normalizedMinSellPrice(
              basePrice: basePrice,
              minSellPrice: item.product.minResellPrice?.round(),
              maxSellPrice: item.product.maxResellPrice?.round(),
            );
            final maxSellPrice = _normalizedMaxSellPrice(
              basePrice: basePrice,
              minSellPrice: item.product.minResellPrice?.round(),
              maxSellPrice: item.product.maxResellPrice?.round(),
            );
            return ResellerOrderLineDraft(
              id: item.product.id,
              title: (item.product.translation?.trim().isNotEmpty ?? false)
                  ? item.product.translation!.trim()
                  : (item.product.title ?? 'Product'),
              thumbnail: (item.product.thumbnail ?? '').trim().isNotEmpty
                  ? item.product.thumbnail!.trim()
                  : (item.product.images.firstOrNull?.image ?? '').trim(),
              quantity: item.quantity,
              basePrice: basePrice,
              sellPrice: item.sellPrice.clamp(minSellPrice, maxSellPrice),
              minSellPrice: minSellPrice,
              maxSellPrice: maxSellPrice,
              vat: item.product.vat?.round() ?? 0,
            );
          })
          .toList(growable: false);
    }

    final basePrice = widget.basePrice ?? 0;
    final minSellPrice = _normalizedMinSellPrice(
      basePrice: basePrice,
      minSellPrice: widget.minSellPrice,
      maxSellPrice: widget.maxSellPrice,
    );
    final maxSellPrice = _normalizedMaxSellPrice(
      basePrice: basePrice,
      minSellPrice: widget.minSellPrice,
      maxSellPrice: widget.maxSellPrice,
    );
    return <ResellerOrderLineDraft>[
      ResellerOrderLineDraft(
        id: widget.id,
        title: (widget.title ?? 'Product').trim(),
        thumbnail: (widget.thumbnail ?? '').trim(),
        quantity: 1,
        basePrice: basePrice,
        sellPrice: _defaultSellPrice(
          basePrice: basePrice,
          minSellPrice: minSellPrice,
          maxSellPrice: maxSellPrice,
        ),
        minSellPrice: minSellPrice,
        maxSellPrice: maxSellPrice,
        vat: 0,
      ),
    ];
  }

  String _lineKey(ResellerOrderLineDraft line) =>
      '${line.id ?? 0}:${line.title}:${line.quantity}';

  TextEditingController _controllerForLine(ResellerOrderLineDraft line) {
    final key = _lineKey(line);
    final existing = _sellPriceControllers[key];
    if (existing != null) return existing;
    final controller = TextEditingController(text: line.sellPrice.toString());
    _sellPriceControllers[key] = controller;
    return controller;
  }

  int _resolvedSellPrice(ResellerOrderLineDraft line) {
    final parsed = int.tryParse(_controllerForLine(line).text.trim());
    if (parsed == null) return line.sellPrice;
    return parsed.clamp(line.minSellPrice, line.maxSellPrice);
  }

  ProductPricingMemory? _memoryForLine(ResellerOrderLineDraft line) {
    final productId = line.id;
    if (productId == null) return null;
    return _pricingMemories[productId];
  }

  SmartPricingProfile _pricingProfileForLine(ResellerOrderLineDraft line) {
    return SmartPricingEngine.build(
      basePrice: line.basePrice,
      minSellPrice: line.minSellPrice,
      maxSellPrice: line.maxSellPrice,
      memory: _memoryForLine(line),
    );
  }

  void _applyPrice(ResellerOrderLineDraft line, int price) {
    final controller = _controllerForLine(line);
    controller.text = price.toString();
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    setState(() {});
  }

  List<ResellerOrderLineDraft>? _validatedLines(CartState cartState) {
    final lines = _draftLines(cartState);
    for (final line in lines) {
      final parsed = int.tryParse(_controllerForLine(line).text.trim());
      if (parsed == null) {
        CustomToast.error('Enter a valid buyer price for ${line.title}');
        return null;
      }
      if (parsed < line.minSellPrice || parsed > line.maxSellPrice) {
        CustomToast.error(
          '${line.title} must stay between ৳${line.minSellPrice} and ৳${line.maxSellPrice}',
        );
        return null;
      }
    }
    return lines
        .map((line) => line.copyWith(sellPrice: _resolvedSellPrice(line)))
        .toList(growable: false);
  }

  int _supplierCount(CartState cartState) {
    if (!widget.isCart) return 1;
    final siteIds = cartState.items
        .map((item) => item.product.siteId ?? 0)
        .where((siteId) => siteId > 0)
        .toSet();
    return siteIds.isEmpty ? 1 : siteIds.length;
  }

  _BuyerRiskSnapshot _buyerRiskSnapshot(BuyerBookProfile? buyer) {
    if (buyer == null) {
      return const _BuyerRiskSnapshot(
        title: 'New buyer',
        guidance: 'Share the quote and wait for a clear yes.',
        operationalLabel: 'Check phone, landmark, area, and COD.',
        facts: <String>['No prior order history'],
        actions: <String>[
          'Check receiver name and phone',
          'Check landmark and area',
          'Send quote first',
        ],
        risky: false,
      );
    }

    final blocked = buyer.isBlocked;
    final risky = blocked ||
        buyer.isRisky ||
        buyer.unpaidOrders > 0 ||
        buyer.returnCount > 0;
    final title = blocked
        ? 'Buyer blocked'
        : risky
        ? 'Buyer needs review'
        : buyer.isRepeatBuyer
        ? 'Buyer ready'
        : 'Buyer ready';
    final guidance = blocked
        ? 'Do not place supplier orders yet.'
        : risky
        ? 'Check buyer commitment before dispatch.'
        : 'Buyer is ready after quote confirmation.';
    final operationalLabel = blocked
        ? 'Hold and review first.'
        : buyer.unpaidOrders > 0
        ? 'Collect advance first.'
        : buyer.returnCount > 0
        ? 'Check address and receiver.'
        : 'Use the normal chat flow.';
    final facts = <String>[
      if (buyer.isRepeatBuyer) 'Repeat buyer',
      if (buyer.pendingOrders > 0) '${buyer.pendingOrders} pending',
      if (buyer.unpaidOrders > 0) '${buyer.unpaidOrders} unpaid',
      if (buyer.returnCount > 0) '${buyer.returnCount} returns',
      if ((buyer.deliveryZone.trim().isNotEmpty)) buyer.deliveryZone,
    ];
    final actions = <String>[
      if (blocked) 'Hold order',
      if (buyer.unpaidOrders > 0) 'Collect advance',
      if (buyer.pendingOrders > 1) 'Check open orders',
      if (buyer.returnCount > 0) 'Check landmark',
      if (!buyer.isRepeatBuyer) 'Send quote first',
    ];
    return _BuyerRiskSnapshot(
      title: title,
      guidance: guidance,
      operationalLabel: operationalLabel,
      facts: facts,
      actions: actions,
      risky: risky,
    );
  }

  _DeliveryLaneSnapshot _deliveryLaneSnapshot({
    required DeliveryPlaceRes area,
    PaymentMethodRes? gate,
  }) {
    final confidenceScore = area.confidenceScore ?? 0;
    final codLabel = (area.codSupportLabel ?? '').toLowerCase();
    final isCod = (gate?.title ?? '').toLowerCase().contains('cod');
    final blocked = isCod &&
        (confidenceScore > 0 && confidenceScore < 40 ||
            codLabel.contains('avoid') ||
            codLabel.contains('not'));
    final risky = blocked ||
        (confidenceScore > 0 && confidenceScore < 60) ||
        ((area.zoneLabel ?? '').toLowerCase().contains('risky')) ||
        ((area.confidenceLabel ?? '').toLowerCase().contains('watch'));
    return _DeliveryLaneSnapshot(
      title: blocked
          ? 'COD stop'
          : risky
          ? 'Check lane'
          : 'Lane ready',
      guidance: blocked
          ? 'Collect advance or change lane first.'
          : risky
          ? 'Check address and receiver before dispatch.'
          : 'Lane ready if buyer phone and address match.',
      operationalLabel: blocked
          ? 'Avoid COD on this lane.'
          : risky
          ? 'Call buyer and confirm landmark.'
          : 'Proceed after final buyer check.',
      facts: <String>[
        if ((area.zoneLabel ?? '').trim().isNotEmpty) area.zoneLabel!.trim(),
        if ((area.confidenceLabel ?? '').trim().isNotEmpty)
          area.confidenceLabel!.trim(),
        if ((area.deliveryEtaLabel ?? '').trim().isNotEmpty)
          area.deliveryEtaLabel!.trim(),
        if ((area.codSupportLabel ?? '').trim().isNotEmpty)
          area.codSupportLabel!.trim(),
      ],
      actions: <String>[
        if (blocked) 'Change lane or collect advance',
        if (risky && !blocked) 'Review lane now',
        if (!risky) 'Use current lane',
      ],
      risky: risky,
      blocked: blocked,
    );
  }

  List<_SupplierOrderGroup> _groupLinesBySupplier(
    CartState cartState,
    List<ResellerOrderLineDraft> lines,
  ) {
    if (!widget.isCart) {
      return <_SupplierOrderGroup>[
        _SupplierOrderGroup(
          siteId: StoreScope.activeSiteId(context),
          supplierLabel: 'Supplier order',
          lines: lines,
        ),
      ];
    }

    final grouped = <int, List<ResellerOrderLineDraft>>{};
    for (final line in lines) {
      final match = cartState.items.cast<dynamic>().firstWhere(
        (item) => item.product.id == line.id,
        orElse: () => null,
      );
      final siteId = match?.product.siteId ?? StoreScope.activeSiteId(context);
      grouped.putIfAbsent(siteId, () => <ResellerOrderLineDraft>[]).add(line);
    }
    return grouped.entries
        .map(
          (entry) => _SupplierOrderGroup(
            siteId: entry.key,
            supplierLabel:
                grouped.length == 1
                    ? 'Supplier order'
                    : 'Supplier ${entry.key}',
            lines: entry.value,
          ),
        )
        .toList(growable: false);
  }

  OrderCreateReq _buildOrderRequestForGroup({
    required _SupplierOrderGroup group,
    required int customerId,
    required int voucherDiscount,
    required DeliveryPlaceRes selectedArea,
    required PaymentMethodRes selectedGate,
    required int otp,
    required int? activeSourceId,
    required String activeDomain,
  }) {
    final groupProducts = group.lines
        .map(
          (line) => ProductOrderCreate(
            cost: 0,
            id: line.id,
            price: line.sellPrice,
            quantity: line.quantity,
            resellPrice: line.basePrice,
            thumbnail: line.thumbnail,
            title: line.title,
            variant: '',
            variantId: null,
            vat: line.vat,
          ),
        )
        .toList(growable: false);
    final orderSubtotal = group.lines.fold<int>(
      0,
      (sum, line) => sum + line.lineSellTotal,
    );
    final resellerBaseTotal = group.lines.fold<int>(
      0,
      (sum, line) => sum + line.lineBaseTotal,
    );
    final profitAmount = orderSubtotal - resellerBaseTotal;
    final finalSubtotal = max(0, orderSubtotal - voucherDiscount).toInt();
    final finalTotal =
        finalSubtotal + (selectedArea.chargeMerchantDefined ?? 0).toInt();

    return OrderCreateReq(
      userId: null,
      siteId: group.siteId,
      address: widget.address,
      affiliateCommission: 0,
      browser: null,
      cashbackBalance: 0,
      charge: 0,
      cost: 0,
      currency: 'BDT',
      customerAddress: widget.address,
      customerId: customerId > 0 ? customerId : null,
      customerName: widget.name,
      customerNote: '',
      customerPhone: widget.phone,
      deliveryTime: null,
      discount: voucherDiscount,
      discountName: voucherDiscount > 0 ? 'Voucher' : '',
      emiDuration: 0,
      emiInterest: 0,
      gatewayText: (selectedGate.title ?? '').trim(),
      grossAmount: orderSubtotal,
      image: null,
      isEmi: false,
      isRenew: false,
      latitude: 23.810332,
      logisticsCharge: (selectedArea.chargeMerchantDefined ?? 0).toInt(),
      logisticsExtraCharge: 0,
      logisticsId: selectedArea.id ?? 0,
      logisticsStoppageId: null,
      logisticsText: (selectedArea.title ?? '').trim(),
      longitude: 90.4125181,
      netAmount: finalSubtotal,
      otp: otp,
      paid: 0,
      parentSiteId: null,
      productId: groupProducts.isNotEmpty ? groupProducts.first.id : null,
      products: groupProducts,
      profit: profitAmount,
      referCode: '6',
      resellAmount: resellerBaseTotal,
      resellerAdvanceCollect: 0,
      resellerCommission: profitAmount,
      rewardPoints: 0,
      shopId: null,
      sourceId: activeSourceId,
      source: activeDomain,
      staffId: null,
      subscription: null,
      subscriptionFee: null,
      total: finalTotal,
      validTill: null,
      vat: 0,
      vatAmount: 0,
      weight: 0,
    );
  }

  Future<List<OrderCreateRes>> _createSupplierOrders({
    required CheckoutCubit checkoutCubit,
    required List<_SupplierOrderGroup> groups,
    required DeliveryPlaceRes selectedArea,
    required PaymentMethodRes selectedGate,
    required int voucherDiscount,
    required int otp,
    required int? userId,
    required int customerId,
    required int? activeSourceId,
    required String activeDomain,
  }) async {
    final orders = <OrderCreateRes>[];
    for (var index = 0; index < groups.length; index++) {
      final group = groups[index];
      final model = _buildOrderRequestForGroup(
        group: group,
        customerId: customerId,
        voucherDiscount: index == 0 ? voucherDiscount : 0,
        selectedArea: selectedArea,
        selectedGate: selectedGate,
        otp: otp + index,
        activeSourceId: activeSourceId,
        activeDomain: activeDomain,
      );
      final order = await checkoutCubit.makeOrder(
        model,
        isAuthenticated: userId != null && customerId > 0,
        userId: userId,
        customerId: customerId > 0 ? customerId : null,
      );
      orders.add(order);
    }
    return orders;
  }

  Future<void> _createQuotePreview(
    BuildContext context,
    CheckoutState checkoutState,
    CartState cartState,
  ) async {
    final lines = _validatedLines(cartState);
    if (lines == null || lines.isEmpty) return;
    final supplierGroups = _groupLinesBySupplier(cartState, lines);
    if (widget.name.trim().isEmpty ||
        widget.address.trim().isEmpty ||
        widget.phone <= 0) {
      CustomToast.error('Buyer details are incomplete');
      return;
    }
    if (checkoutState.deliveryPlace.isEmpty ||
        checkoutState.areaSelect < 0 ||
        checkoutState.areaSelect >= checkoutState.deliveryPlace.length) {
      CustomToast.error('Select a delivery area before creating a quote');
      return;
    }
    final checkoutCubit = context.read<CheckoutCubit>();
    final activeSiteId = StoreScope.activeSiteId(context);
    final userId = await LocalStorage.getUserID() ?? 0;
    if (userId <= 0) {
      CustomToast.error('Sign in to save and share quotes');
      return;
    }
    final selectedArea = checkoutState.deliveryPlace[checkoutState.areaSelect];
    final subtotal = lines.fold<int>(
      0,
      (sum, line) => sum + line.lineSellTotal,
    );
    final baseTotal = lines.fold<int>(
      0,
      (sum, line) => sum + line.lineBaseTotal,
    );
    final quote = await checkoutCubit.createQuote(
      ResellerQuote(
        id: 'QT${DateTime.now().millisecondsSinceEpoch}',
        siteId: activeSiteId,
        userId: userId,
        buyerName: widget.name.trim(),
        buyerPhone: widget.phone,
        buyerAddress: widget.address.trim(),
        deliveryLabel: supplierGroups.length > 1
            ? '${(selectedArea.title ?? '').trim()} • ${supplierGroups.length} supplier deliveries'
            : (selectedArea.title ?? '').trim(),
        deliveryEstimate: '3-7 days',
        deliveryCharge:
            (selectedArea.chargeMerchantDefined ?? 0).toInt() *
            supplierGroups.length,
        subtotal: subtotal,
        total:
            subtotal +
            ((selectedArea.chargeMerchantDefined ?? 0).toInt() *
                supplierGroups.length),
        baseTotal: baseTotal,
        profit: subtotal - baseTotal,
        createdAt: DateTime.now(),
        status: 'draft',
        lines: lines
            .map(
              (line) => ResellerQuoteLine(
                productId: line.id,
                title: line.title,
                thumbnail: line.thumbnail,
                quantity: line.quantity,
                basePrice: line.basePrice,
                sellPrice: line.sellPrice,
              ),
            )
            .toList(growable: false),
      ),
    );
    if (!context.mounted) return;
    final shouldConvert = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuotePreviewScreen(quote: quote)),
    );
    if (shouldConvert == true && context.mounted) {
      await _submitOrder(context, checkoutState, cartState, quoteId: quote.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Payment & Delivery',
        icon: HugeIcons.strokeRoundedWallet01,
        showBackButton: true,
      ),
      body: BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, checkoutState) {
          return BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final draftLines = _draftLines(cartState);
              final supplierCount = _supplierCount(cartState);
              final deliveryChargePerSupplier =
                  checkoutState.deliveryCharge.toInt();
              final totalDeliveryCharge =
                  deliveryChargePerSupplier * supplierCount;
              final payAmount = draftLines.fold<int>(
                0,
                (sum, line) => sum + (_resolvedSellPrice(line) * line.quantity),
              );
              final baseAmount = draftLines.fold<int>(
                0,
                (sum, line) => sum + (line.basePrice * line.quantity),
              );
              final voucherDiscount =
                  checkoutState.voucher?.discount.round() ?? 0;
              final discountedPayAmount = max(0, payAmount - voucherDiscount);
              final totalAmount = totalDeliveryCharge + discountedPayAmount;
              final profitAmount = payAmount - baseAmount;
              final selectedPaymentLabel =
                  checkoutState.paymentMethod.isNotEmpty &&
                      checkoutState.paySelect >= 0 &&
                      checkoutState.paySelect <
                          checkoutState.paymentMethod.length
                  ? (checkoutState.paymentMethod[checkoutState.paySelect].title ??
                        '')
                  : '';
              final supplierGroups = _groupLinesBySupplier(
                cartState,
                draftLines
                    .map(
                      (line) => line.copyWith(
                        sellPrice: _resolvedSellPrice(line),
                      ),
                    )
                    .toList(growable: false),
              );

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 120.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PaymentOverviewCard(
                            supplierCount: supplierCount,
                            payAmount: payAmount,
                            totalAmount: totalAmount,
                            profitAmount: profitAmount,
                            deliveryCharge: totalDeliveryCharge,
                          ),
                          const SizedBox(height: 18),
                          FutureBuilder<BuyerBookProfile?>(
                            future: _buyerConfidenceFuture,
                            builder: (context, snapshot) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _PaymentDecisionCard(
                                  snapshot: _buyerRiskSnapshot(snapshot.data),
                                ),
                              );
                            },
                          ),
                          _PaymentRouteCard(
                            buyerName: widget.name,
                            buyerPhone: widget.phone,
                            deliveryLabel: checkoutState.deliveryWay,
                            paymentLabel: selectedPaymentLabel,
                            voucherCode: checkoutState.voucherCode,
                            supplierCount: supplierCount,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColor.safe),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _PaymentSectionLead(
                                  icon: HugeIcons.strokeRoundedCoinsSwap,
                                  title: 'Buyer price',
                                ),
                                const SizedBox(height: 10),
                                ...draftLines.map((line) {
                                  final profile = _pricingProfileForLine(line);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ResellerPriceLineCard(
                                      line: line,
                                      controller: _controllerForLine(line),
                                      resolvedSellPrice: _resolvedSellPrice(
                                        line,
                                      ),
                                      pricingProfile: profile,
                                      onChanged: () => setState(() {}),
                                      onApplyPrice: (price) =>
                                          _applyPrice(line, price),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColor.safe),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _PaymentSectionLead(
                                  icon: HugeIcons.strokeRoundedMapsLocation01,
                                  title: 'Delivery area',
                                ),
                                const SizedBox(height: 10),
                                SelectableListAreaPay(
                                  itemCount: checkoutState.deliveryPlace.length,
                                  selectedIndex: checkoutState.areaSelect,
                                  isSelected: (index) =>
                                      checkoutState.areaSelect == index,
                                  onTap: (index) {
                                    final data =
                                        checkoutState.deliveryPlace[index];
                                    context.read<CheckoutCubit>().setAreaSelect(
                                      index,
                                    );
                                    context
                                        .read<CheckoutCubit>()
                                        .setDeliveryCharge(
                                          data.chargeMerchantDefined ?? 0.0,
                                        );
                                    context
                                        .read<CheckoutCubit>()
                                        .setDeliveryWay(data.title ?? '');
                                    context.read<CheckoutCubit>().setLogisticId(
                                      data.id ?? 0,
                                    );
                                  },
                                  titleBuilder: (index) {
                                    final data =
                                        checkoutState.deliveryPlace[index];
                                    return Text(
                                      data.title ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    );
                                  },
                                  subtitleBuilder: (index) {
                                    final data =
                                        checkoutState.deliveryPlace[index];
                                    return Text(
                                      'Delivery charge: ৳${convertToBengaliNumber(data.chargeMerchantDefined?.toInt() ?? 0)}',
                                      style: TextStyle(
                                        color: checkoutState.areaSelect == index
                                            ? AppColor.text
                                            : AppColor.neutral2,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                                if (checkoutState.deliveryPlace.isNotEmpty &&
                                    checkoutState.areaSelect >= 0 &&
                                    checkoutState.areaSelect <
                                        checkoutState.deliveryPlace.length) ...[
                                  const SizedBox(height: 12),
                                  Builder(
                                    builder: (context) {
                                      final selectedArea = checkoutState
                                          .deliveryPlace[checkoutState.areaSelect];
                                      final selectedGate =
                                          checkoutState.paymentMethod.isNotEmpty &&
                                              checkoutState.paySelect >= 0 &&
                                              checkoutState.paySelect <
                                                  checkoutState.paymentMethod.length
                                          ? checkoutState.paymentMethod[checkoutState.paySelect]
                                          : null;
                                      final deliverySnapshot =
                                          _deliveryLaneSnapshot(
                                            area: selectedArea,
                                            gate: selectedGate,
                                          );
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _DeliveryConfidenceCard(
                                            area: selectedArea,
                                          ),
                                          const SizedBox(height: 12),
                                          _PaymentDeliveryDecisionCard(
                                            snapshot: deliverySnapshot,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColor.safe),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _PaymentSectionLead(
                                  icon: HugeIcons.strokeRoundedWallet01,
                                  title: 'Payment method',
                                ),
                                const SizedBox(height: 10),
                                SelectableListAreaPay(
                                  itemCount: checkoutState.paymentMethod.length,
                                  selectedIndex: checkoutState.paySelect,
                                  isSelected: (index) =>
                                      checkoutState.paySelect == index,
                                  onTap: (index) {
                                    context.read<CheckoutCubit>().setPaySelect(
                                      index,
                                    );
                                    context
                                        .read<CheckoutCubit>()
                                        .setGatewayText(
                                          checkoutState
                                                  .paymentMethod[index]
                                                  .title ??
                                              '',
                                        );
                                  },
                                  titleBuilder: (index) {
                                    final data =
                                        checkoutState.paymentMethod[index];
                                    return Text(
                                      data.title ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    );
                                  },
                                  subtitleBuilder: (index) {
                                    return Text(
                                      'Payment amount: ৳${convertToBengaliNumber(totalAmount)}',
                                      style: TextStyle(
                                        color: checkoutState.paySelect == index
                                            ? AppColor.text
                                            : AppColor.neutral2,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                  trailingBuilder: (index) {
                                    final data =
                                        checkoutState.paymentMethod[index];
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: AppNetworkImage(
                                        imageUrl: data.logo,
                                        height: 38,
                                        width: 58,
                                        fit: BoxFit.contain,
                                        backgroundColor: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SupplierSplitPreviewCard(
                            groups: supplierGroups,
                            deliveryChargePerSupplier:
                                deliveryChargePerSupplier,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColor.safe),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _PaymentSectionLead(
                                  icon: HugeIcons.strokeRoundedInvoice03,
                                  title: 'Order summary',
                                ),
                                const SizedBox(height: 10),
                                Divider(
                                  color: AppColor.grey.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 10),
                                if (supplierCount > 1) ...[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: AppColor.safe1,
                                      border: Border.all(color: AppColor.safe),
                                    ),
                                    child: Text(
                                      'This selling list will split into $supplierCount supplier orders. Delivery charge applies per supplier.',
                                      style: const TextStyle(
                                        color: AppColor.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Subtotal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '৳${convertToBengaliNumber(discountedPayAmount)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Base supplier cost',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '৳${convertToBengaliNumber(baseAmount)}',
                                      style: const TextStyle(
                                        color: AppColor.neutral2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (voucherDiscount > 0) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Voucher discount',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '-৳${convertToBengaliNumber(voucherDiscount)}',
                                        style: const TextStyle(
                                          color: AppColor.green,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Gross margin',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '৳${convertToBengaliNumber(profitAmount)}',
                                      style: const TextStyle(
                                        color: AppColor.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Delivery charge',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      supplierCount > 1
                                          ? '৳${convertToBengaliNumber(totalDeliveryCharge)}'
                                          : '৳${convertToBengaliNumber(deliveryChargePerSupplier)}',
                                      style: const TextStyle(
                                        color: AppColor.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (supplierCount > 1) ...[
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '$supplierCount x ৳${convertToBengaliNumber(deliveryChargePerSupplier)}',
                                      style: TextStyle(
                                        color: AppColor.neutral2,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Delivery method',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: AppColor.grey,
                                      ),
                                    ),
                                    Text(
                                      checkoutState.deliveryWay.isEmpty
                                          ? 'Not selected'
                                          : checkoutState.deliveryWay,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: AppColor.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Divider(
                                  color: AppColor.grey.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '৳${convertToBengaliNumber(totalAmount)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                  color: AppColor.grey.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Estimated delivery:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: AppColor.grey,
                                      ),
                                    ),
                                    Text(
                                      '3-7 days',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: AppColor.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: AppColor.green.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Expected reseller margin ৳${convertToBengaliNumber(profitAmount)} before fees',
                                      style: const TextStyle(
                                        color: AppColor.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: AppColor.safe1,
                                  ),
                                  child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        supplierCount > 1
                                            ? 'Split order mode: each supplier gets its own order and delivery tracking.'
                                            : checkoutState.paymentMethod
                                                    .where(
                                                      (method) =>
                                                          (method.title ?? '')
                                                              .toLowerCase()
                                                              .contains('cash') ||
                                                          (method.title ?? '')
                                                              .toLowerCase()
                                                              .contains('cod'),
                                                    )
                                                    .isNotEmpty
                                            ? 'COD-friendly order. Confirm buyer phone and area before dispatch.'
                                            : 'Advance or gateway payment may be safer for this order.',
                                          style: const TextStyle(
                                            color: AppColor.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                    border: Border.all(color: AppColor.safe),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Payout rule',
                                        style: TextStyle(
                                          color: AppColor.text,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your profit shows after supplier fulfillment. Keep buyer confirmation and delivery follow-up tight to protect payout.',
                                        style: TextStyle(
                                          color: AppColor.grey,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _PaymentBottomBar(
                    totalAmount: totalAmount,
                    savingAmount: profitAmount,
                    loading: checkoutState.isLoading,
                    deliveryLabel: checkoutState.deliveryWay,
                    paymentLabel: selectedPaymentLabel,
                    supplierCount: supplierCount,
                    confirmLabel: supplierCount > 1
                        ? 'Create $supplierCount orders'
                        : 'Create order',
                    onCreateQuote: () =>
                        _createQuotePreview(context, checkoutState, cartState),
                    onConfirm: () =>
                        _submitOrder(context, checkoutState, cartState),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submitOrder(
    BuildContext context,
    CheckoutState checkoutState,
    CartState cartState, {
    String? quoteId,
  }) async {
    try {
      if (checkoutState.isLoading) {
        return;
      }
      final checkoutCubit = context.read<CheckoutCubit>();
      final navigator = Navigator.of(context);
      final cartCubit = context.read<CartCubit>();
      final activeSiteId = StoreScope.activeSiteId(context);
      final activeSourceId = StoreScope.activeSourceId(context);
      final activeDomain = StoreScope.activeDomain(context);
      final lines = _validatedLines(cartState);
      if (lines == null || lines.isEmpty) {
        return;
      }
      final supplierGroups = _groupLinesBySupplier(cartState, lines);

      final otp = Random().nextInt(900000) + 100000;
      final userId = await LocalStorage.getUserID();
      final customerId = checkoutState.customerId > 0
          ? checkoutState.customerId
          : ((await LocalStorage.getCustomerID()) ?? 0);
      final voucherDiscount = checkoutState.voucher?.discount.round() ?? 0;
      final orderSubtotal = lines.fold<int>(
        0,
        (sum, line) => sum + line.lineSellTotal,
      );
      final finalSubtotal = max(0, orderSubtotal - voucherDiscount).toInt();
      final finalTotal =
          finalSubtotal +
          (checkoutState.deliveryCharge.toInt() * supplierGroups.length);

      if (widget.name.trim().isEmpty ||
          widget.address.trim().isEmpty ||
          widget.phone <= 0) {
        CustomToast.error('Customer details are incomplete');
        return;
      }
      if (checkoutState.deliveryPlace.isEmpty) {
        CustomToast.error('Delivery areas are unavailable right now');
        return;
      }
      if (checkoutState.areaSelect < 0 ||
          checkoutState.areaSelect >= checkoutState.deliveryPlace.length) {
        CustomToast.error('Select a delivery area');
        return;
      }
      if (checkoutState.paymentMethod.isEmpty) {
        CustomToast.error('Payment methods are not available right now');
        return;
      }
      if (checkoutState.paySelect < 0 ||
          checkoutState.paySelect >= checkoutState.paymentMethod.length) {
        CustomToast.error('Select a payment method');
        return;
      }

      final selectedArea =
          checkoutState.deliveryPlace[checkoutState.areaSelect];
      final selectedGate = checkoutState.paymentMethod[checkoutState.paySelect];
      final deliverySnapshot = _deliveryLaneSnapshot(
        area: selectedArea,
        gate: selectedGate,
      );
      if (supplierGroups.length > 1 && voucherDiscount > 0) {
        CustomToast.error(
          'Voucher is not supported for mixed supplier orders yet.',
        );
        return;
      }
      if (deliverySnapshot.blocked) {
        CustomToast.error(
          'Selected delivery lane is too risky for COD. Collect advance or change the lane before confirming.',
        );
        return;
      }

      if ((selectedGate.title ?? '').toLowerCase().contains('bkash')) {
        if (!context.mounted) return;
        final result = await checkoutCubit.payWithBkash(
          context,
          finalTotal.toDouble(),
        );
        if (!context.mounted) return;
        if (!result.success) {
          CustomToast.error('Payment failed');
          return;
        }
        final orders = await _createSupplierOrders(
          checkoutCubit: checkoutCubit,
          groups: supplierGroups,
          selectedArea: selectedArea,
          selectedGate: selectedGate,
          voucherDiscount: voucherDiscount,
          otp: otp,
          userId: userId,
          customerId: customerId,
          activeSourceId: activeSourceId,
          activeDomain: activeDomain,
        );
        if ((quoteId ?? '').isNotEmpty) {
          await checkoutCubit.markQuoteConverted(
            quoteId: quoteId!,
            orderId: orders
                .map((order) => order.orderId ?? '')
                .where((value) => value.isNotEmpty)
                .join(', '),
          );
        }
        if (!context.mounted) return;
        CustomToast.info('Payment successful');
        if (widget.isCart) {
          await cartCubit.clearCart();
        }
        _openOrderCompletion(navigator, orders);
        return;
      }

      if ((selectedGate.title ?? '').toLowerCase().contains('cod')) {
        final orders = await _createSupplierOrders(
          checkoutCubit: checkoutCubit,
          groups: supplierGroups,
          selectedArea: selectedArea,
          selectedGate: selectedGate,
          voucherDiscount: voucherDiscount,
          otp: otp,
          userId: userId,
          customerId: customerId,
          activeSourceId: activeSourceId,
          activeDomain: activeDomain,
        );
        if ((quoteId ?? '').isNotEmpty) {
          await checkoutCubit.markQuoteConverted(
            quoteId: quoteId!,
            orderId: orders
                .map((order) => order.orderId ?? '')
                .where((value) => value.isNotEmpty)
                .join(', '),
          );
        }
        if (!context.mounted) return;
        if (widget.isCart) {
          await cartCubit.clearCart();
        }
        _openOrderCompletion(navigator, orders);
        return;
      }

      final paymentRequestSuccess = await checkoutCubit.paymentGatewayRequest(
        PaymentGatewayReq(
          siteId: activeSiteId,
          gatewayId: selectedGate.id,
          amount: finalTotal,
          cancelUrl: _normalizeGatewayUrl('$activeDomain/payment-cancel'),
          currency: 'BDT',
          customerName: widget.name,
          emiDuration: 0,
          emiInterest: 0,
          failUrl: _normalizeGatewayUrl('$activeDomain/payment-fail'),
          isCardTransaction: false,
          isCodPayment: false,
          isEmi: false,
          merchantId: customerId > 0 ? customerId : 0,
          payeeSource: _normalizeGatewayUrl(activeDomain),
          productInfo: lines.first.title,
          referenceId: 'order-${DateTime.now().millisecondsSinceEpoch}',
          showRefundButton: false,
          successUrl: _normalizeGatewayUrl('$activeDomain/payment-success'),
          transactionType: selectedGate.gatewayType ?? 1,
        ),
      );
      final gatewayPayload =
          (paymentRequestSuccess.displayValue ?? '').trim().isNotEmpty
          ? paymentRequestSuccess.displayValue!.trim()
          : (paymentRequestSuccess.callBack ?? '').trim();
      if (gatewayPayload.isEmpty) {
        CustomToast.error('Gateway checkout link is unavailable');
        return;
      }
      if (!context.mounted) return;
      final gatewayResult = await navigator.push<PaymentGatewayWebViewResult>(
        MaterialPageRoute(
          builder: (_) => PaymentGatewayWebViewScreen(
            title: selectedGate.title ?? 'Secure checkout',
            initialPayload: gatewayPayload,
            successUrl: _normalizeGatewayUrl(
              paymentRequestSuccess.successUrl ??
                  '$activeDomain/payment-success',
            ),
            failUrl: _normalizeGatewayUrl('$activeDomain/payment-fail'),
            cancelUrl: _normalizeGatewayUrl(
              paymentRequestSuccess.cancelUrl ?? '$activeDomain/payment-cancel',
            ),
          ),
        ),
      );
      if (!context.mounted) return;
      if (gatewayResult == PaymentGatewayWebViewResult.success) {
        final orders = await _createSupplierOrders(
          checkoutCubit: checkoutCubit,
          groups: supplierGroups,
          selectedArea: selectedArea,
          selectedGate: selectedGate,
          voucherDiscount: voucherDiscount,
          otp: otp,
          userId: userId,
          customerId: customerId,
          activeSourceId: activeSourceId,
          activeDomain: activeDomain,
        );
        if ((quoteId ?? '').isNotEmpty) {
          await checkoutCubit.markQuoteConverted(
            quoteId: quoteId!,
            orderId: orders
                .map((order) => order.orderId ?? '')
                .where((value) => value.isNotEmpty)
                .join(', '),
          );
        }
        if (!context.mounted) return;
        if (widget.isCart) {
          await cartCubit.clearCart();
        }
        _openOrderCompletion(navigator, orders);
        return;
      }
      if (gatewayResult == PaymentGatewayWebViewResult.cancelled) {
        CustomToast.info('Payment was cancelled');
        return;
      }
      CustomToast.error('Payment failed');
    } catch (error) {
      CustomToast.error('Could not create order: $error');
    }
  }

  void _openOrderCompletion(
    NavigatorState navigator,
    List<OrderCreateRes> orders,
  ) {
    if (orders.length == 1) {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => OrderCompleteWelcome(order: orders.first),
        ),
      );
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (context) => MultiOrderCompleteScreen(orders: orders),
      ),
    );
  }

  String _normalizeGatewayUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }
}

class _ResellerPriceLineCard extends StatelessWidget {
  const _ResellerPriceLineCard({
    required this.line,
    required this.controller,
    required this.resolvedSellPrice,
    required this.pricingProfile,
    required this.onChanged,
    required this.onApplyPrice,
  });

  final ResellerOrderLineDraft line;
  final TextEditingController controller;
  final int resolvedSellPrice;
  final SmartPricingProfile pricingProfile;
  final VoidCallback onChanged;
  final ValueChanged<int> onApplyPrice;

  @override
  Widget build(BuildContext context) {
    final margin = (resolvedSellPrice - line.basePrice) * line.quantity;
    final warning = pricingProfile.warningForPrice(resolvedSellPrice);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: line.thumbnail.isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: line.thumbnail,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        backgroundColor: Colors.white,
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const AppHugeIcon(
                          HugeIcons.strokeRoundedPackage,
                          size: 18,
                          color: AppColor.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColor.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Base ৳${convertToBengaliNumber(line.basePrice)} | Range ৳${convertToBengaliNumber(line.minSellPrice)} - ৳${convertToBengaliNumber(line.maxSellPrice)} | Qty ${line.quantity}',
                      style: const TextStyle(
                        color: AppColor.neutral2,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pricingProfile.options
                .map(
                  (option) => _PriceSuggestionChip(
                    label: option.label,
                    price: option.price,
                    marginPerItem: option.marginPerItem,
                    isActive: resolvedSellPrice == option.price,
                    onTap: () => onApplyPrice(option.price),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Buyer price per item',
                    prefixText: '৳ ',
                  ),
                  validator: (_) {
                    final parsed = int.tryParse(controller.text.trim());
                    if (parsed == null) {
                      return 'Enter price';
                    }
                    if (parsed < line.minSellPrice) {
                      return 'Min ৳${line.minSellPrice}';
                    }
                    if (parsed > line.maxSellPrice) {
                      return 'Max ৳${line.maxSellPrice}';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColor.safe),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Margin',
                      style: TextStyle(
                        color: AppColor.neutral2,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '৳${convertToBengaliNumber(margin)}',
                      style: const TextStyle(
                        color: AppColor.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _warningBackground(warning.level),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _warningColor(warning.level)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: _warningColor(warning.level),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warning.title,
                        style: TextStyle(
                          color: _warningTextColor(warning.level),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${warning.message} Best conversion band: ৳${convertToBengaliNumber(pricingProfile.realisticMinPrice)} - ৳${convertToBengaliNumber(pricingProfile.realisticMaxPrice)}.',
                        style: TextStyle(
                          color: _warningTextColor(warning.level),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSuggestionChip extends StatelessWidget {
  const _PriceSuggestionChip({
    required this.label,
    required this.price,
    required this.marginPerItem,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int price;
  final int marginPerItem;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColor.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColor.primary : AppColor.safe,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColor.primary : AppColor.text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '৳${convertToBengaliNumber(price)}',
              style: const TextStyle(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Margin ৳${convertToBengaliNumber(marginPerItem)}',
              style: const TextStyle(
                color: AppColor.neutral2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _warningColor(SmartPricingWarningLevel level) {
  switch (level) {
    case SmartPricingWarningLevel.good:
      return AppColor.green;
    case SmartPricingWarningLevel.notice:
      return AppColor.info;
    case SmartPricingWarningLevel.warning:
      return AppColor.warning;
    case SmartPricingWarningLevel.risk:
      return AppColor.alert;
  }
}

Color _warningBackground(SmartPricingWarningLevel level) {
  switch (level) {
    case SmartPricingWarningLevel.good:
      return AppColor.safe1;
    case SmartPricingWarningLevel.notice:
      return AppColor.infoLight;
    case SmartPricingWarningLevel.warning:
      return AppColor.warningLight;
    case SmartPricingWarningLevel.risk:
      return AppColor.alertLight;
  }
}

Color _warningTextColor(SmartPricingWarningLevel level) {
  switch (level) {
    case SmartPricingWarningLevel.good:
      return AppColor.green;
    case SmartPricingWarningLevel.notice:
      return AppColor.info;
    case SmartPricingWarningLevel.warning:
      return AppColor.warning;
    case SmartPricingWarningLevel.risk:
      return AppColor.alert;
  }
}

class _SupplierOrderGroup {
  const _SupplierOrderGroup({
    required this.siteId,
    required this.supplierLabel,
    required this.lines,
  });

  final int siteId;
  final String supplierLabel;
  final List<ResellerOrderLineDraft> lines;
}

class _DeliveryConfidenceCard extends StatelessWidget {
  const _DeliveryConfidenceCard({required this.area});

  final DeliveryPlaceRes area;

  @override
  Widget build(BuildContext context) {
    final confidenceScore = area.confidenceScore ?? 0;
    final risky = confidenceScore > 0 && confidenceScore < 60;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: risky ? AppColor.alertLight : AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: risky ? AppColor.alert : AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery lane',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            area.recommendedAction ??
                'Check landmark and phone before order.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DecisionFactPill(
                label: area.zoneLabel ?? 'Zone',
                risky: risky,
              ),
              _DecisionFactPill(
                label: area.confidenceLabel ?? 'Manual check',
                risky: risky,
              ),
              _DecisionFactPill(
                label: area.deliveryEtaLabel ?? 'Check ETA',
                risky: risky,
              ),
              _DecisionFactPill(
                label: area.codSupportLabel ?? 'Check COD',
                risky: risky,
              ),
            ],
          ),
          if ((area.riskNote ?? area.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              area.riskNote ?? area.note ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: risky ? AppColor.alert : AppColor.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentSectionLead extends StatelessWidget {
  const _PaymentSectionLead({required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.safe),
          ),
          child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColor.text,
          ),
        ),
      ],
    );
  }
}

class _PaymentBottomBar extends StatelessWidget {
  const _PaymentBottomBar({
    required this.totalAmount,
    required this.savingAmount,
    required this.loading,
    required this.deliveryLabel,
    required this.paymentLabel,
    required this.supplierCount,
    required this.confirmLabel,
    required this.onCreateQuote,
    required this.onConfirm,
  });

  final int totalAmount;
  final int savingAmount;
  final bool loading;
  final String deliveryLabel;
  final String paymentLabel;
  final int supplierCount;
  final String confirmLabel;
  final VoidCallback onCreateQuote;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColor.safe)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (deliveryLabel.trim().isNotEmpty)
                _PaymentInfoPill(label: 'Area', value: deliveryLabel.trim()),
              if (paymentLabel.trim().isNotEmpty)
                _PaymentInfoPill(label: 'Pay', value: paymentLabel.trim()),
              _PaymentInfoPill(
                label: 'Route',
                value: supplierCount > 1 ? 'Split' : 'Direct',
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buyer total',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${convertToBengaliNumber(totalAmount)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (savingAmount > 0)
                      Text(
                        'Margin ৳${convertToBengaliNumber(savingAmount)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColor.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 42.h,
                      child: OutlinedButton(
                        onPressed: loading ? null : onCreateQuote,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColor.safe),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: const Text(
                          'Quote',
                          style: TextStyle(
                            color: AppColor.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: loading ? null : onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                confirmLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentDecisionCard extends StatelessWidget {
  const _PaymentDecisionCard({required this.snapshot});

  final _BuyerRiskSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: snapshot.risky ? AppColor.alertLight : AppColor.safe1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: snapshot.risky ? AppColor.alert : AppColor.safe,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: snapshot.risky ? AppColor.alert : AppColor.safe,
              ),
            ),
            child: AppHugeIcon(
              snapshot.risky
                  ? HugeIcons.strokeRoundedAlertCircle
                  : HugeIcons.strokeRoundedMessagePreview01,
              size: 16,
              color: snapshot.risky ? AppColor.alert : AppColor.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.guidance,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: snapshot.risky ? AppColor.alert : AppColor.safe,
                    ),
                  ),
                  child: Text(
                    snapshot.operationalLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: snapshot.risky ? AppColor.alert : AppColor.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: snapshot.facts
                      .map(
                        (fact) => _DecisionFactPill(
                          label: fact,
                          risky: snapshot.risky,
                        ),
                      )
                      .toList(growable: false),
                ),
                if (snapshot.actions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.actions
                        .map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $action',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColor.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDeliveryDecisionCard extends StatelessWidget {
  const _PaymentDeliveryDecisionCard({required this.snapshot});

  final _DeliveryLaneSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: snapshot.risky ? AppColor.alertLight : AppColor.safe1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: snapshot.risky ? AppColor.alert : AppColor.safe,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppHugeIcon(
                snapshot.blocked
                    ? HugeIcons.strokeRoundedCancelCircle
                    : snapshot.risky
                    ? HugeIcons.strokeRoundedAlert02
                    : HugeIcons.strokeRoundedCheckmarkCircle02,
                size: 16,
                color: snapshot.risky ? AppColor.alert : AppColor.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  snapshot.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            snapshot.guidance,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: snapshot.risky ? AppColor.alert : AppColor.neutral2,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: snapshot.risky ? AppColor.alert : AppColor.safe,
              ),
            ),
            child: Text(
              snapshot.operationalLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: snapshot.risky ? AppColor.alert : AppColor.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (snapshot.facts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: snapshot.facts
                  .map(
                    (fact) => _DecisionFactPill(
                      label: fact,
                      risky: snapshot.risky,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (snapshot.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: snapshot.actions
                  .map(
                    (action) => _DecisionFactPill(
                      label: action,
                      risky: snapshot.risky,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentOverviewCard extends StatelessWidget {
  const _PaymentOverviewCard({
    required this.supplierCount,
    required this.payAmount,
    required this.totalAmount,
    required this.profitAmount,
    required this.deliveryCharge,
  });

  final int supplierCount;
  final int payAmount;
  final int totalAmount;
  final int profitAmount;
  final int deliveryCharge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm the math',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            supplierCount > 1
                ? 'Split by supplier'
                : 'Single supplier order',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PaymentInfoPill(
                label: 'Buyer total',
                value: '৳${convertToBengaliNumber(payAmount)}',
              ),
              _PaymentInfoPill(
                label: 'Delivery',
                value: '৳${convertToBengaliNumber(deliveryCharge)}',
              ),
              _PaymentInfoPill(
                label: 'Profit',
                value: '৳${convertToBengaliNumber(profitAmount)}',
              ),
              _PaymentInfoPill(
                label: 'Payable',
                value: '৳${convertToBengaliNumber(totalAmount)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoPill extends StatelessWidget {
  const _PaymentInfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionFactPill extends StatelessWidget {
  const _DecisionFactPill({required this.label, required this.risky});

  final String label;
  final bool risky;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: risky ? AppColor.alert : AppColor.safe),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: risky ? AppColor.alert : AppColor.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaymentRouteCard extends StatelessWidget {
  const _PaymentRouteCard({
    required this.buyerName,
    required this.buyerPhone,
    required this.deliveryLabel,
    required this.paymentLabel,
    required this.voucherCode,
    required this.supplierCount,
  });

  final String buyerName;
  final int buyerPhone;
  final String deliveryLabel;
  final String paymentLabel;
  final String voucherCode;
  final int supplierCount;

  @override
  Widget build(BuildContext context) {
    final normalizedBuyerName = buyerName.trim().isEmpty
        ? 'Buyer'
        : buyerName.trim();
    final facts = <String>[
      'Buyer: $normalizedBuyerName',
      if (buyerPhone > 0) 'Phone: 0$buyerPhone',
      if (deliveryLabel.trim().isNotEmpty) 'Area: ${deliveryLabel.trim()}',
      if (paymentLabel.trim().isNotEmpty) 'Payment: ${paymentLabel.trim()}',
      if (voucherCode.trim().isNotEmpty) 'Voucher: ${voucherCode.trim()}',
      supplierCount > 1 ? 'Split: $supplierCount supplier orders' : 'Route: Direct order',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order route',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: facts
                .map((fact) => _PaymentInfoPill(label: 'Order', value: fact))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SupplierSplitPreviewCard extends StatelessWidget {
  const _SupplierSplitPreviewCard({
    required this.groups,
    required this.deliveryChargePerSupplier,
  });

  final List<_SupplierOrderGroup> groups;
  final int deliveryChargePerSupplier;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PaymentSectionLead(
            icon: HugeIcons.strokeRoundedPackageProcess,
            title: 'Order split',
          ),
          const SizedBox(height: 10),
          Text(
            groups.length > 1
                ? 'This payment creates ${groups.length} supplier orders.'
                : 'This payment stays with one supplier.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...groups.map((group) {
            final buyerSubtotal = group.lines.fold<int>(
              0,
              (sum, line) => sum + line.lineSellTotal,
            );
            final supplierBase = group.lines.fold<int>(
              0,
              (sum, line) => sum + line.lineBaseTotal,
            );
            final itemCount = group.lines.fold<int>(
              0,
              (sum, line) => sum + line.quantity,
            );
            final itemSummary = group.lines
                .map((line) => '${line.title} x${line.quantity}')
                .take(3)
                .join(' • ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColor.safe),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.supplierLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PaymentInfoPill(
                          label: 'Items',
                          value: '$itemCount',
                        ),
                        _PaymentInfoPill(
                          label: 'Sell',
                          value: '৳${convertToBengaliNumber(buyerSubtotal)}',
                        ),
                        _PaymentInfoPill(
                          label: 'Base',
                          value: '৳${convertToBengaliNumber(supplierBase)}',
                        ),
                        _PaymentInfoPill(
                          label: 'Delivery',
                          value:
                              '৳${convertToBengaliNumber(deliveryChargePerSupplier)}',
                        ),
                      ],
                    ),
                    if (itemSummary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        itemSummary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColor.neutral2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BuyerRiskSnapshot {
  const _BuyerRiskSnapshot({
    required this.title,
    required this.guidance,
    required this.operationalLabel,
    required this.facts,
    required this.actions,
    required this.risky,
  });

  final String title;
  final String guidance;
  final String operationalLabel;
  final List<String> facts;
  final List<String> actions;
  final bool risky;
}

class _DeliveryLaneSnapshot {
  const _DeliveryLaneSnapshot({
    required this.title,
    required this.guidance,
    required this.operationalLabel,
    required this.facts,
    required this.actions,
    required this.risky,
    required this.blocked,
  });

  final String title;
  final String guidance;
  final String operationalLabel;
  final List<String> facts;
  final List<String> actions;
  final bool risky;
  final bool blocked;
}
