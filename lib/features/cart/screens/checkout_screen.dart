import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/utils/debouncer.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/store/store_registry.dart';
import 'package:sellhub/core/services/analytics_service.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sellhub/features/cart/data/models/cart_item_model.dart';
import 'package:sellhub/features/cart/data/models/delivery_place_res.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_state.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_state.dart';
import 'package:sellhub/features/cart/screens/payment_screen.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/injection_container.dart' as di;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.isCart,
    this.comparePrice,
    this.payPrice,
    this.savePrice,
    this.title,
    this.id,
    this.minSellPrice,
    this.maxSellPrice,
    this.thumbnail,
  });

  final bool isCart;
  final int? comparePrice;
  final int? payPrice;
  final int? savePrice;
  final String? title;
  final int? id;
  final int? minSellPrice;
  final int? maxSellPrice;
  final String? thumbnail;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _voucherController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  final _buyerRiskDebouncer = Debouncer(milliseconds: 450);
  Future<List<BuyerBookProfile>>? _buyerBookFuture;
  String? _lastBuyerRiskFingerprint;
  String? _pendingOperationalDraftKey;

  bool get _hasValidPhone =>
      StoreRegistry.currentStore?.market.isPhoneValid(_phoneController.text) ??
      false;

  @override
  void initState() {
    super.initState();
    final storefront = context.read<StorefrontCubit>().state;
    context.read<CheckoutCubit>().fetchPaymentMethod(
      StoreScope.siteIdFromState(storefront),
    );
    context.read<CheckoutCubit>().fetchDeliveryPlace(
      StoreScope.siteIdFromState(storefront),
    );
    _loadCustomerContext();
    _hydratePendingBuyer();
    _hydrateQuickOrderDraft();
    _buyerBookFuture = _loadBuyerBook();
    _phoneController.addListener(_onPhoneChanged);
    _phoneController.addListener(_onBuyerContextChanged);
    _nameController.addListener(_onBuyerContextChanged);
    _addressController.addListener(_onBuyerContextChanged);
  }

  Future<void> _loadCustomerContext() async {
    final userId = await LocalStorage.getUserID();
    if (userId == null || userId <= 0 || !mounted) return;
    await context.read<CheckoutCubit>().hydrateCustomerContext(
      userId: userId,
      siteId: StoreScope.activeSiteId(context),
    );
  }

  Future<void> _hydratePendingBuyer() async {
    final buyer = await LocalStorage.getPendingBuyer();
    if (!mounted || buyer == null) return;
    _applyBuyerProfile(buyer);
    await LocalStorage.clearPendingBuyer();
  }

  Future<void> _hydrateQuickOrderDraft() async {
    final userId = await LocalStorage.getUserID() ?? 0;
    if (!mounted || userId <= 0) return;
    final siteId = StoreScope.activeSiteId(context);
    final draft = await context.read<CheckoutCubit>().loadQuickOrderDraft(
      userId: userId,
      siteId: siteId,
    );
    if (!mounted || draft == null) return;
    final hasCurrentInput =
        _phoneController.text.trim().isNotEmpty ||
        _nameController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty;
    if (!hasCurrentInput) {
      _applyQuickOrderDraft(draft);
    }
  }

  Future<List<BuyerBookProfile>> _loadBuyerBook() async {
    final siteId = StoreScope.activeSiteId(context);
    final userId = await LocalStorage.getUserID() ?? 0;
    if (userId <= 0) return const <BuyerBookProfile>[];
    return di.sl<ProfileRepository>().fetchBuyerBook(
      userId: userId,
      siteId: siteId,
    );
  }

  void _applyBuyerProfile(BuyerBookProfile buyer) {
    _phoneController.text = buyer.phone.startsWith('88')
        ? buyer.phone.substring(2)
        : buyer.phone;
    _nameController.text = buyer.name;
    _addressController.text = buyer.primaryAddress;
    _scheduleBuyerRiskEvaluation();
  }

  void _applyQuickOrderDraft(Map<String, dynamic> draft) {
    final buyerPhone = (draft['buyerPhone'] as String? ?? '').trim();
    final normalizedPhone = buyerPhone.startsWith('88')
        ? buyerPhone.substring(2)
        : buyerPhone;
    if (normalizedPhone.isNotEmpty) {
      _phoneController.text = normalizedPhone;
    }
    _nameController.text = (draft['buyerName'] as String? ?? '').trim();
    _addressController.text = (draft['buyerAddress'] as String? ?? '').trim();
    final voucherCode = (draft['voucherCode'] as String? ?? '').trim();
    _voucherController.text = voucherCode;
    context.read<CheckoutCubit>().setQuickOrderDraft(draft);
    _restoreOperationalSelectionsFromDraft(
      draft,
      context.read<CheckoutCubit>().state,
    );
    _scheduleBuyerRiskEvaluation();
  }

  void _restoreOperationalSelectionsFromDraft(
    Map<String, dynamic> draft,
    CheckoutState checkoutState,
  ) {
    final checkoutCubit = context.read<CheckoutCubit>();
    final draftKey =
        (draft['id'] ?? draft['draftId'] ?? draft['updatedAt'] ?? 'draft')
            .toString();
    var appliedAny = false;

    final savedAddressId = (draft['selectedShippingAddressId'] as num?)
        ?.toInt();
    if (savedAddressId != null &&
        checkoutState.savedShippingAddresses.isNotEmpty) {
      final address = checkoutState.savedShippingAddresses
          .where((item) => item.id == savedAddressId)
          .firstOrNull;
      if (address != null) {
        checkoutCubit.selectShippingAddress(address);
        _addressController.text = address.address;
        appliedAny = true;
      }
    }

    final deliveryPlaceId = (draft['deliveryPlaceId'] as num?)?.toInt();
    final deliveryLabel = (draft['deliveryLabel'] as String? ?? '').trim();
    if (checkoutState.deliveryPlace.isNotEmpty) {
      final deliveryIndex = checkoutState.deliveryPlace.indexWhere((place) {
        final idMatch = deliveryPlaceId != null && place.id == deliveryPlaceId;
        final labelMatch =
            deliveryLabel.isNotEmpty &&
            (place.title ?? '').trim().toLowerCase() ==
                deliveryLabel.toLowerCase();
        return idMatch || labelMatch;
      });
      if (deliveryIndex >= 0) {
        final data = checkoutState.deliveryPlace[deliveryIndex];
        checkoutCubit.setAreaSelect(deliveryIndex);
        checkoutCubit.setDeliveryCharge(data.chargeMerchantDefined ?? 0.0);
        checkoutCubit.setDeliveryWay(data.title ?? '');
        checkoutCubit.setLogisticId(data.id ?? 0);
        appliedAny = true;
      }
    }

    final paymentMethodId = (draft['paymentMethodId'] as num?)?.toInt();
    final paymentLabel = (draft['paymentLabel'] as String? ?? '').trim();
    if (checkoutState.paymentMethod.isNotEmpty) {
      final paymentIndex = checkoutState.paymentMethod.indexWhere((method) {
        final idMatch = paymentMethodId != null && method.id == paymentMethodId;
        final titleMatch =
            paymentLabel.isNotEmpty &&
            (method.title ?? '').trim().toLowerCase() ==
                paymentLabel.toLowerCase();
        return idMatch || titleMatch;
      });
      if (paymentIndex >= 0) {
        final data = checkoutState.paymentMethod[paymentIndex];
        checkoutCubit.setPaySelect(paymentIndex);
        checkoutCubit.setGatewayText(data.title ?? '');
        appliedAny = true;
      }
    }

    final needsOperationalSync =
        (deliveryPlaceId != null || deliveryLabel.isNotEmpty) &&
            checkoutState.deliveryPlace.isEmpty ||
        (paymentMethodId != null || paymentLabel.isNotEmpty) &&
            checkoutState.paymentMethod.isEmpty ||
        (savedAddressId != null &&
            checkoutState.savedShippingAddresses.isEmpty);

    _pendingOperationalDraftKey = needsOperationalSync && !appliedAny
        ? draftKey
        : null;
  }

  void _maybeSyncPendingOperationalDraft(CheckoutState checkoutState) {
    final draft = checkoutState.quickOrderDraft;
    if (draft == null || _pendingOperationalDraftKey == null) return;
    final draftKey =
        (draft['id'] ?? draft['draftId'] ?? draft['updatedAt'] ?? 'draft')
            .toString();
    if (draftKey != _pendingOperationalDraftKey) return;
    if (checkoutState.deliveryPlace.isEmpty &&
        checkoutState.paymentMethod.isEmpty &&
        checkoutState.savedShippingAddresses.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _restoreOperationalSelectionsFromDraft(
        draft,
        context.read<CheckoutCubit>().state,
      );
    });
  }

  List<Map<String, dynamic>> _quickOrderLines(CartState cartState) {
    final activeSiteId = StoreScope.activeSiteId(context);
    if (widget.isCart) {
      return cartState.items
          .map(
            (item) => <String, dynamic>{
              'id': item.product.id,
              'title': ((item.product.translation ?? '').trim().isNotEmpty
                  ? item.product.translation!.trim()
                  : (item.product.title ?? 'Product')),
              'quantity': item.quantity,
              'basePrice': ((item.product.price ?? 0).toDouble()).round(),
              'sellPrice': item.sellPrice,
              'siteId': item.product.siteId ?? activeSiteId,
              'supplierName': 'Anonymous supply source',
              'thumbnail': item.product.thumbnail ?? '',
            },
          )
          .toList(growable: false);
    }
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': widget.id,
        'title': (widget.title ?? 'Product').trim(),
        'quantity': 1,
        'basePrice': widget.payPrice ?? 0,
        'sellPrice': widget.payPrice ?? 0,
        'siteId': activeSiteId,
        'supplierName': 'Anonymous supply source',
        'thumbnail': widget.thumbnail ?? '',
      },
    ];
  }

  Map<String, dynamic> _buildQuickOrderDraftPayload(
    CheckoutState checkoutState,
    CartState cartState,
  ) {
    final lines = _quickOrderLines(cartState);
    final subtotal = lines.fold<int>(
      0,
      (sum, line) =>
          sum +
          (((line['basePrice'] as num?)?.toInt() ?? 0) *
              ((line['quantity'] as num?)?.toInt() ?? 1)),
    );
    final total = lines.fold<int>(
      0,
      (sum, line) =>
          sum +
          (((line['sellPrice'] as num?)?.toInt() ?? 0) *
              ((line['quantity'] as num?)?.toInt() ?? 1)),
    );
    final existingDraft = checkoutState.quickOrderDraft;
    final siteId = StoreScope.activeSiteId(context);
    return <String, dynamic>{
      'id': existingDraft?['id'],
      'draftId': existingDraft?['draftId'],
      'title': widget.isCart
          ? 'Quick order draft'
          : (widget.title ?? 'Quick order'),
      'buyerName': _nameController.text.trim(),
      'buyerPhone': _phoneController.text.trim().startsWith('88')
          ? _phoneController.text.trim()
          : '88${_phoneController.text.trim()}',
      'buyerAddress': _addressController.text.trim(),
      'note': '',
      'status': 'draft',
      'deliveryLabel': checkoutState.deliveryWay.trim().isNotEmpty
          ? checkoutState.deliveryWay.trim()
          : 'Delivery pending',
      'deliveryPlaceId': checkoutState.logisticId > 0
          ? checkoutState.logisticId
          : null,
      'deliveryCharge': checkoutState.deliveryCharge.round(),
      'paymentMethodId':
          checkoutState.paymentMethod.isNotEmpty &&
              checkoutState.paySelect >= 0 &&
              checkoutState.paySelect < checkoutState.paymentMethod.length
          ? checkoutState.paymentMethod[checkoutState.paySelect].id
          : null,
      'paymentLabel': checkoutState.gateWayText.trim(),
      'selectedShippingAddressId': checkoutState.selectedShippingAddressId,
      'subtotal': subtotal,
      'total': total,
      'voucherCode': _voucherController.text.trim(),
      'siteId': siteId,
      'lineCount': lines.length,
      'supplierCount': lines
          .map((line) => line['siteId']?.toString() ?? '$siteId')
          .toSet()
          .length,
      'lines': lines,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _saveCurrentQuickOrderDraft(
    CheckoutState checkoutState,
    CartState cartState,
  ) async {
    final checkoutCubit = context.read<CheckoutCubit>();
    final siteId = StoreScope.activeSiteId(context);
    final userId = await LocalStorage.getUserID() ?? 0;
    if (userId <= 0) {
      CustomToast.error('Sign in to save quick-order draft');
      return;
    }
    final payload = _buildQuickOrderDraftPayload(checkoutState, cartState);
    await checkoutCubit.saveQuickOrderDraft(
      userId: userId,
      siteId: siteId,
      draft: payload,
    );
    if (!mounted) return;
    CustomToast.info('Quick-order draft saved');
  }

  Future<void> _restoreStoredQuickOrderDraft(
    CheckoutState checkoutState,
  ) async {
    final draft = checkoutState.quickOrderDraft;
    if (draft == null) return;
    _applyQuickOrderDraft(draft);
    CustomToast.info('Quick-order draft restored');
  }

  Future<void> _clearStoredQuickOrderDraft(CheckoutState checkoutState) async {
    final checkoutCubit = context.read<CheckoutCubit>();
    final siteId = StoreScope.activeSiteId(context);
    final draftId =
        (checkoutState.quickOrderDraft?['id'] ??
                checkoutState.quickOrderDraft?['draftId'])
            ?.toString();
    final userId = await LocalStorage.getUserID() ?? 0;
    if (userId <= 0) return;
    final deleted = await checkoutCubit.deleteQuickOrderDraft(
      userId: userId,
      siteId: siteId,
      draftId: draftId,
    );
    if (!mounted) return;
    if (deleted) {
      CustomToast.info('Stored quick-order draft cleared');
    }
  }

  List<_CheckoutSupplierPreview> _supplierPreview(CartState cartState) {
    if (!widget.isCart) {
      return <_CheckoutSupplierPreview>[
        _CheckoutSupplierPreview(
          label: 'Supply source order',
          itemCount: 1,
          supplierBase: widget.payPrice ?? 0,
          buyerTotal: widget.payPrice ?? 0,
          itemTitles: <String>[(widget.title ?? 'Product').trim()],
        ),
      ];
    }

    final grouped = <int, List<CartItem>>{};
    for (final item in cartState.items) {
      final siteId = item.product.siteId ?? 0;
      grouped.putIfAbsent(siteId, () => <CartItem>[]).add(item);
    }

    return grouped.entries
        .map((entry) {
          final items = entry.value;
          final supplierBase = items.fold<int>(
            0,
            (sum, item) =>
                sum +
                (((item.product.price ?? 0).toDouble()).round() *
                    item.quantity),
          );
          final buyerTotal = items.fold<int>(
            0,
            (sum, item) => sum + (item.sellPrice * item.quantity),
          );
          return _CheckoutSupplierPreview(
            label: grouped.length == 1
                ? 'Supply source order'
                : 'Anonymous supply source ${entry.key}',
            itemCount: items.fold<int>(0, (sum, item) => sum + item.quantity),
            supplierBase: supplierBase,
            buyerTotal: buyerTotal,
            itemTitles: items
                .map<String>(
                  (item) => ((item.product.translation ?? '').trim().isNotEmpty
                      ? item.product.translation!.trim()
                      : (item.product.title ?? 'Product')),
                )
                .take(3)
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.removeListener(_onBuyerContextChanged);
    _nameController.removeListener(_onBuyerContextChanged);
    _addressController.removeListener(_onBuyerContextChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _voucherController.dispose();
    _debouncer.dispose();
    _buyerRiskDebouncer.dispose();
    super.dispose();
  }

  void _onBuyerContextChanged() {
    _scheduleBuyerRiskEvaluation();
  }

  int _currentCheckoutItemCount(CartState cartState) {
    return widget.isCart ? cartState.totalItems : 1;
  }

  double _currentCheckoutOrderTotal(
    CartState cartState,
    CheckoutState checkoutState,
  ) {
    final base = widget.isCart
        ? cartState.totalAmount.toDouble()
        : (widget.payPrice ?? 0).toDouble();
    final voucherDiscount = checkoutState.voucher?.discount ?? 0;
    return (base - voucherDiscount + checkoutState.deliveryCharge).clamp(
      0,
      double.infinity,
    );
  }

  void _scheduleBuyerRiskEvaluation() {
    final checkoutCubit = context.read<CheckoutCubit>();
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length < 11) {
      _lastBuyerRiskFingerprint = null;
      checkoutCubit.clearBuyerRiskDecisionState();
      return;
    }

    final normalizedPhone = rawPhone.startsWith('88')
        ? rawPhone
        : '88$rawPhone';
    final buyerName = _nameController.text.trim();
    final buyerAddress = _addressController.text.trim();
    final cartState = context.read<CartCubit>().state;
    final checkoutState = checkoutCubit.state;
    final orderTotal = _currentCheckoutOrderTotal(cartState, checkoutState);
    final itemCount = _currentCheckoutItemCount(cartState);
    final supplierCount = widget.isCart
        ? cartState.items
              .map((item) => item.product.siteId ?? 0)
              .where((siteId) => siteId > 0)
              .toSet()
              .length
        : 1;
    final fingerprint = [
      normalizedPhone,
      buyerName,
      buyerAddress,
      orderTotal.round(),
      itemCount,
      supplierCount,
      checkoutState.deliveryWay,
      checkoutState.gateWayText,
    ].join('|');
    if (_lastBuyerRiskFingerprint == fingerprint &&
        checkoutState.buyerRiskDecisionStatus ==
            CheckoutResourceStatus.success) {
      return;
    }

    _buyerRiskDebouncer.run(() async {
      final userId = await LocalStorage.getUserID() ?? 0;
      if (!mounted || userId <= 0) return;
      _lastBuyerRiskFingerprint = fingerprint;
      try {
        await checkoutCubit.fetchBuyerRiskDecision(
          userId: userId,
          siteId: StoreScope.activeSiteId(context),
          buyerPhone: normalizedPhone,
          buyerName: buyerName,
          buyerAddress: buyerAddress,
          orderTotal: orderTotal,
          itemCount: itemCount,
          context: <String, dynamic>{
            'deliveryLane': checkoutState.deliveryWay,
            'paymentMethod': checkoutState.gateWayText,
            'supplierCount': supplierCount,
            'flow': 'quick_order_checkout',
          },
        );
      } catch (_) {}
    });
  }

  void _onPhoneChanged() {
    _debouncer.run(() async {
      final market = StoreRegistry.currentStore?.market;
      if (market == null || !market.isPhoneValid(_phoneController.text)) return;
      final fullPhone = market.normalizeInternationalPhone(
        _phoneController.text,
      );

      try {
        final user = await context.read<AuthCubit>().checkUser(fullPhone);
        if (!mounted || user == null) return;
        setState(() {
          _nameController.text = user.name;
          _addressController.text = user.address;
        });
        Fluttertoast.showToast(
          msg: 'User details found!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Start order',
        icon: HugeIcons.strokeRoundedShoppingBasket01,
        showBackButton: true,
      ),
      body: BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, checkoutState) {
          return BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final payAmount = widget.isCart
                  ? cartState.totalAmount.toInt()
                  : widget.payPrice ?? 0;
              final saveAmount = widget.isCart
                  ? (cartState.totalCompareAmount - cartState.totalAmount)
                        .toInt()
                  : widget.savePrice ?? 0;
              final voucherDiscount =
                  checkoutState.voucher?.discount.round() ?? 0;
              final payableAmount = (payAmount - voucherDiscount).clamp(
                0,
                1 << 31,
              );
              final itemCount = widget.isCart ? cartState.totalItems : 1;
              final supplierCount = widget.isCart
                  ? cartState.items
                        .map((item) => item.product.siteId ?? 0)
                        .where((siteId) => siteId > 0)
                        .toSet()
                        .length
                  : 1;
              final supplierPreview = _supplierPreview(cartState);
              final selectedDeliveryPlace =
                  checkoutState.deliveryPlace.isNotEmpty &&
                      checkoutState.areaSelect >= 0 &&
                      checkoutState.areaSelect <
                          checkoutState.deliveryPlace.length
                  ? checkoutState.deliveryPlace[checkoutState.areaSelect]
                  : null;
              _maybeSyncPendingOperationalDraft(checkoutState);

              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (checkoutState.error != null) ...[
                              _InlineStatusCard(
                                title: checkoutState.error!.title,
                                tone: _StatusTone.error,
                              ),
                              SizedBox(height: 12.h),
                            ],
                            _CheckoutSummaryCard(
                              itemCount: itemCount,
                              supplierCount: supplierCount,
                              payableAmount: payableAmount,
                              voucherDiscount: voucherDiscount,
                            ),
                            SizedBox(height: 12.h),
                            _CheckoutDraftCard(
                              hasBuyerDraft:
                                  _phoneController.text.trim().isNotEmpty ||
                                  _nameController.text.trim().isNotEmpty ||
                                  _addressController.text.trim().isNotEmpty,
                              hasStoredDraft:
                                  checkoutState.hasResumableQuickOrderDraft,
                              hasSavedBuyerAddress:
                                  checkoutState.selectedShippingAddressId !=
                                  null,
                              voucherCode: checkoutState.voucherCode,
                              supplierCount: supplierCount,
                              draftStatus: checkoutState.quickOrderDraftStatus,
                              onSaveDraft: () => _saveCurrentQuickOrderDraft(
                                checkoutState,
                                cartState,
                              ),
                              onRestoreDraft:
                                  checkoutState.hasResumableQuickOrderDraft
                                  ? () => _restoreStoredQuickOrderDraft(
                                      checkoutState,
                                    )
                                  : null,
                              onClearDraft:
                                  checkoutState.hasResumableQuickOrderDraft
                                  ? () => _clearStoredQuickOrderDraft(
                                      checkoutState,
                                    )
                                  : null,
                            ),
                            if (selectedDeliveryPlace != null) ...[
                              SizedBox(height: 12.h),
                              _CheckoutDeliveryConfidenceCard(
                                area: selectedDeliveryPlace,
                              ),
                            ],
                            SizedBox(height: 18.h),
                            _buildSectionTitle(
                              HugeIcons.strokeRoundedUserCircle,
                              'Buyer',
                            ),
                            SizedBox(height: 12.h),
                            const _CheckoutHintCard(
                              title: 'Chat order',
                              subtitle: 'WhatsApp or Facebook',
                            ),
                            SizedBox(height: 12.h),
                            _buildInputCard([
                              if (_buyerBookFuture != null)
                                FutureBuilder<List<BuyerBookProfile>>(
                                  future: _buyerBookFuture,
                                  builder: (context, snapshot) {
                                    final buyers =
                                        snapshot.data ??
                                        const <BuyerBookProfile>[];
                                    if (buyers.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Column(
                                      children: [
                                        _InfoStrip(
                                          icon:
                                              HugeIcons.strokeRoundedUserGroup,
                                          title: 'Saved buyers',
                                          subtitle: 'Tap to use',
                                        ),
                                        SizedBox(height: 12.h),
                                        SizedBox(
                                          height: 98,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: buyers.take(6).length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(width: 10.w),
                                            itemBuilder: (context, index) {
                                              final buyer = buyers[index];
                                              return _BuyerShortcutCard(
                                                buyer: buyer,
                                                onTap: () =>
                                                    _applyBuyerProfile(buyer),
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                      ],
                                    );
                                  },
                                ),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone',
                                hint: '017xxxxxxxx',
                                icon: HugeIcons.strokeRoundedSmartPhone01,
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 12.h),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Name',
                                hint: 'Buyer name',
                                icon: HugeIcons.strokeRoundedUser,
                              ),
                              SizedBox(height: 12.h),
                              _buildTextField(
                                controller: _addressController,
                                label: 'Address',
                                hint: 'House, area, district',
                                icon: HugeIcons.strokeRoundedMapsLocation01,
                                maxLines: 3,
                              ),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _phoneController,
                                builder: (context, _, __) {
                                  return FutureBuilder<List<BuyerBookProfile>>(
                                    future: _buyerBookFuture,
                                    builder: (context, snapshot) {
                                      final buyers =
                                          snapshot.data ??
                                          const <BuyerBookProfile>[];
                                      final normalized = _phoneController.text
                                          .trim();
                                      if (normalized.length < 5) {
                                        return const SizedBox.shrink();
                                      }
                                      final matched = buyers
                                          .where((buyer) {
                                            final phone =
                                                buyer.phone.startsWith('88')
                                                ? buyer.phone.substring(2)
                                                : buyer.phone;
                                            return phone.contains(normalized) ||
                                                buyer.name
                                                    .toLowerCase()
                                                    .contains(
                                                      _nameController.text
                                                          .trim()
                                                          .toLowerCase(),
                                                    );
                                          })
                                          .toList(growable: false);
                                      if (matched.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      final buyer = matched.first;
                                      return Padding(
                                        padding: EdgeInsets.only(top: 12.h),
                                        child: _BuyerLookupInsight(
                                          buyer: buyer,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _phoneController,
                                builder: (context, _, __) {
                                  final normalized = _phoneController.text
                                      .trim();
                                  if (normalized.length < 11) {
                                    return const SizedBox.shrink();
                                  }
                                  return FutureBuilder<List<BuyerBookProfile>>(
                                    future: _buyerBookFuture,
                                    builder: (context, snapshot) {
                                      final buyers =
                                          snapshot.data ??
                                          const <BuyerBookProfile>[];
                                      final exists = buyers.any((buyer) {
                                        final phone =
                                            buyer.phone.startsWith('88')
                                            ? buyer.phone.substring(2)
                                            : buyer.phone;
                                        return phone == normalized;
                                      });
                                      if (exists) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: EdgeInsets.only(top: 12.h),
                                        child: const _CheckoutHintCard(
                                          title: 'New buyer',
                                          subtitle: 'Check landmark and COD',
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              if (checkoutState.buyerRiskDecisionStatus !=
                                      CheckoutResourceStatus.initial ||
                                  _hasValidPhone) ...[
                                SizedBox(height: 12.h),
                                _BuyerRiskDecisionCard(
                                  status: checkoutState.buyerRiskDecisionStatus,
                                  decision: checkoutState.buyerRiskDecision,
                                ),
                              ],
                              if (checkoutState
                                  .savedShippingAddresses
                                  .isNotEmpty) ...[
                                SizedBox(height: 12.h),
                                _buildSavedAddressPicker(
                                  checkoutState.savedShippingAddresses,
                                  checkoutState.selectedShippingAddressId,
                                ),
                              ],
                              if (checkoutState.customerId > 0) ...[
                                SizedBox(height: 10.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final success = await context
                                          .read<CheckoutCubit>()
                                          .saveShippingAddress(
                                            customerId:
                                                checkoutState.customerId,
                                            address: _addressController.text
                                                .trim(),
                                          );
                                      if (!mounted) return;
                                      if (success) {
                                        CustomToast.info('Saved address');
                                      }
                                    },
                                    icon: const AppHugeIcon(
                                      HugeIcons.strokeRoundedBookmarkAdd01,
                                      size: 16,
                                      color: AppColor.primary,
                                      semanticLabel: 'Save address',
                                    ),
                                    label: const Text('Save address'),
                                  ),
                                ),
                              ],
                            ]),
                            SizedBox(height: 18.h),
                            _buildSectionTitle(
                              HugeIcons.strokeRoundedCoupon01,
                              'Voucher',
                            ),
                            SizedBox(height: 12.h),
                            _buildInputCard([
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _voucherController,
                                      label: 'Voucher',
                                      hint: 'Optional code',
                                      icon: HugeIcons.strokeRoundedCoupon01,
                                      required: false,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  SizedBox(
                                    height: 48.h,
                                    child: OutlinedButton(
                                      onPressed: () => _applyVoucher(
                                        checkoutState,
                                        cartState,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColor.safe,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Use code'),
                                    ),
                                  ),
                                ],
                              ),
                              if (checkoutState.voucher != null) ...[
                                SizedBox(height: 10.h),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColor.safe1,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColor.safe),
                                  ),
                                  child: Row(
                                    children: [
                                      const AppHugeIcon(
                                        HugeIcons.strokeRoundedCoupon01,
                                        size: 16,
                                        color: AppColor.green,
                                        backgroundColor: AppColor.safe1,
                                        borderColor: AppColor.safe,
                                        borderRadius: 12,
                                        padding: EdgeInsets.all(6),
                                        semanticLabel: 'Voucher ready',
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          checkoutState.voucher!.message,
                                          style: const TextStyle(
                                            color: AppColor.green,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _voucherController.clear();
                                          context
                                              .read<CheckoutCubit>()
                                              .clearVoucher();
                                        },
                                        child: const Text('Clear'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ]),
                            SizedBox(height: 18.h),
                            _buildSectionTitle(
                              HugeIcons.strokeRoundedInvoice03,
                              'Order summary',
                            ),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColor.safe),
                              ),
                              child: Column(
                                children: [
                                  if (supplierCount > 1) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12.w),
                                      margin: EdgeInsets.only(bottom: 14.h),
                                      decoration: BoxDecoration(
                                        color: AppColor.safe1,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColor.safe,
                                        ),
                                      ),
                                      child: Text(
                                        'Creates $supplierCount supplier orders.',
                                        style: TextStyle(
                                          color: AppColor.primary,
                                          fontSize: 12.5.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                  _CheckoutSupplierPreviewCard(
                                    suppliers: supplierPreview,
                                  ),
                                  SizedBox(height: 14.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _SummaryMetric(
                                          label: 'Items',
                                          value: '$itemCount',
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: _SummaryMetric(
                                          label: 'Base',
                                          value:
                                              '৳ ${convertToBengaliNumber(payAmount)}',
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: _SummaryMetric(
                                          label: 'Voucher',
                                          value: voucherDiscount > 0
                                              ? '-৳ ${convertToBengaliNumber(voucherDiscount)}'
                                              : '0',
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  _buildSummaryRow(
                                    'Base total',
                                    '৳ ${convertToBengaliNumber(payableAmount)}',
                                    isTotal: true,
                                  ),
                                  if (voucherDiscount > 0) ...[
                                    SizedBox(height: 12.h),
                                    _buildSummaryRow(
                                      'Voucher',
                                      '- ৳ ${convertToBengaliNumber(voucherDiscount)}',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _CheckoutBottomBar(
                      amount: payableAmount,
                      savings: saveAmount,
                      loading: checkoutState.isLoading,
                      onContinue: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        if (checkoutState.buyerRiskDecisionStatus ==
                            CheckoutResourceStatus.loading) {
                          CustomToast.info('Wait for buyer check');
                          return;
                        }
                        if (checkoutState.buyerRiskDisposition == 'blocked') {
                          CustomToast.error(
                            'Buyer blocked for COD. Collect advance first.',
                          );
                          return;
                        }
                        if (_hasValidPhone &&
                            checkoutState.buyerRiskDecisionStatus ==
                                CheckoutResourceStatus.initial) {
                          _scheduleBuyerRiskEvaluation();
                          CustomToast.info(
                            'Checking buyer. Review the result first.',
                          );
                          return;
                        }
                        if (checkoutState.buyerRiskDisposition == 'review') {
                          CustomToast.info(
                            'Buyer needs review. Check landmark and COD first.',
                          );
                        }
                        context.read<AnalyticsService>().logCheckoutStarted(
                          siteId: StoreScope.activeSiteId(context),
                          fromCart: widget.isCart,
                          totalItems: itemCount,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              phone:
                                  int.tryParse(_phoneController.text.trim()) ??
                                  0,
                              name: _nameController.text.trim(),
                              address: _addressController.text.trim(),
                              isCart: widget.isCart,
                              title: widget.title ?? '',
                              id: widget.id,
                              basePrice: widget.payPrice,
                              minSellPrice: widget.minSellPrice,
                              maxSellPrice: widget.maxSellPrice,
                              thumbnail: widget.thumbnail,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(List<List<dynamic>> icon, String title) {
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
          child: AppHugeIcon(icon, color: AppColor.primary, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required List<List<dynamic>> icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColor.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.safe),
            ),
            child: AppHugeIcon(icon, size: 16.sp, color: AppColor.primary),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFFBFBFB),
        labelStyle: TextStyle(
          color: AppColor.neutral2,
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: AppColor.neutral1, fontSize: 13.sp),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: maxLines > 1 ? 16.h : 14.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColor.safe),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppColor.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
      validator: required
          ? (value) =>
                value == null || value.isEmpty ? 'This field is required' : null
          : null,
    );
  }

  Widget _buildSummaryRow(
    String title,
    String amount, {
    bool isTotal = false,
    bool isOldPrice = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            color: isTotal ? Colors.black : Colors.grey.shade600,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColor.primary : Colors.black87,
            decoration: isOldPrice ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedAddressPicker(
    List<StoreCustomerAddressModel> addresses,
    int? selectedId,
  ) {
    if (_addressController.text.trim().isEmpty && addresses.isNotEmpty) {
      _addressController.text = addresses.first.address;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved buyer addresses',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Tap to fill',
          style: TextStyle(
            fontSize: 11.5.sp,
            color: AppColor.neutral2,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: addresses.map((address) {
            final selected = selectedId == address.id;
            return InkWell(
              onTap: () {
                context.read<CheckoutCubit>().selectShippingAddress(address);
                _addressController.text = address.address;
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 220.w,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? AppColor.safe1 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColor.primary : AppColor.safe,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected ? AppColor.primary : AppColor.safe1,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AppHugeIcon(
                        selected
                            ? HugeIcons.strokeRoundedCheckmarkCircle02
                            : HugeIcons.strokeRoundedMapsLocation01,
                        size: 15,
                        color: selected ? Colors.white : AppColor.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        address.address,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.text,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _applyVoucher(
    CheckoutState checkoutState,
    CartState cartState,
  ) async {
    final checkoutCubit = context.read<CheckoutCubit>();
    final siteId = StoreScope.activeSiteId(context);
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      CustomToast.error('Enter a voucher code');
      return;
    }
    final userId = await LocalStorage.getUserID();
    final products = widget.isCart
        ? cartState.items
              .map(
                (item) => <String, dynamic>{
                  'id': item.product.id,
                  'price': item.product.price,
                  'quantity': item.quantity,
                  'title': item.product.title,
                },
              )
              .toList()
        : <Map<String, dynamic>>[
            <String, dynamic>{
              'id': widget.id,
              'price': widget.payPrice,
              'quantity': 1,
              'title': widget.title,
            },
          ];
    final total = widget.isCart
        ? cartState.totalAmount.toDouble()
        : (widget.payPrice ?? 0).toDouble();
    final quantity = widget.isCart
        ? cartState.items.fold<double>(0, (sum, item) => sum + item.quantity)
        : 1.0;
    await checkoutCubit.applyVoucher(
      siteId: siteId,
      code: code,
      quantity: quantity,
      total: total,
      delivery: checkoutState.deliveryCharge,
      products: products,
      userId: userId,
    );
    if (!mounted) return;
    final message = checkoutCubit.state.voucher?.message;
    if (message?.isNotEmpty == true) {
      CustomToast.info(message!);
    }
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  const _CheckoutBottomBar({
    required this.amount,
    required this.savings,
    required this.loading,
    required this.onContinue,
  });

  final int amount;
  final int savings;
  final bool loading;
  final VoidCallback onContinue;

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order total',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '৳ ${convertToBengaliNumber(amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (savings > 0)
                  Text(
                    'Save ৳ ${convertToBengaliNumber(savings)}',
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
            child: SizedBox(
              height: 52.h,
              child: ElevatedButton(
                onPressed: loading ? null : onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDFF55A),
                  foregroundColor: AppColor.text,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColor.text,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Flexible(
                            child: Text(
                              'Go to payment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColor.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          AppHugeIcon(
                            HugeIcons.strokeRoundedArrowRight02,
                            size: 16,
                            color: AppColor.text,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StatusTone { error }

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({required this.title, required this.tone});

  final String title;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final isError = tone == _StatusTone.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? AppColor.alertLight : AppColor.safe1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isError ? AppColor.alert : AppColor.primary).withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHugeIcon(
            isError
                ? HugeIcons.strokeRoundedAlert02
                : HugeIcons.strokeRoundedInformationCircle,
            color: isError ? AppColor.alert : AppColor.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isError ? AppColor.alert : AppColor.primary,
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

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHugeIcon(icon, size: 18, color: AppColor.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyerShortcutCard extends StatelessWidget {
  const _BuyerShortcutCard({required this.buyer, required this.onTap});

  final BuyerBookProfile buyer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.safe),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              buyer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColor.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              buyer.phone,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${buyer.totalOrders} orders • ${buyer.sourceTag}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerLookupInsight extends StatelessWidget {
  const _BuyerLookupInsight({required this.buyer});

  final BuyerBookProfile buyer;

  @override
  Widget build(BuildContext context) {
    final riskScore =
        (buyer.isBlocked ? 90 : 0) +
        (buyer.isRisky ? 35 : 0) +
        (buyer.pendingOrders * 8) +
        (buyer.unpaidOrders * 18) +
        buyer.returnRate.round();
    final risky = riskScore >= 70 || buyer.isRisky || buyer.isBlocked;
    final operationalActions = <String>[
      if (buyer.isBlocked) 'Stop and review',
      if (buyer.unpaidOrders > 0) 'Collect advance',
      if (buyer.pendingOrders > 1) 'Check old orders',
      if (buyer.returnCount > 0) 'Check landmark',
      if (!buyer.isRepeatBuyer) 'Check name and area',
    ];
    final flags = <String>[
      if (buyer.pendingOrders > 0) '${buyer.pendingOrders} open',
      if (buyer.unpaidOrders > 0) '${buyer.unpaidOrders} unpaid',
      if (buyer.isRisky) 'Needs review',
      if (buyer.isBlocked) 'Stop',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: risky ? AppColor.alert : AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppHugeIcon(
                risky
                    ? HugeIcons.strokeRoundedAlertCircle
                    : HugeIcons.strokeRoundedUserCheck01,
                size: 16,
                color: risky ? AppColor.alert : AppColor.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  risky ? 'Buyer needs review' : 'Buyer ready',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Last order: ${buyer.lastOrderedAt == null ? 'Unknown' : buyer.lastOrderedAt!.toLocal().toString().split(' ').first} • Avg basket ৳${buyer.averageBasketSize.toStringAsFixed(0)} • ${buyer.sourceTag}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
          ),
          const SizedBox(height: 6),
          Text(
            riskScore >= 70
                ? 'Check phone, address, COD, and delivery first.'
                : buyer.isRepeatBuyer
                ? 'Repeat buyer. Reuse the last winning offer.'
                : 'New buyer. Check landmark and COD.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: risky ? AppColor.alert : AppColor.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (flags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              flags.join(' • '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: risky ? AppColor.alert : AppColor.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (operationalActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: operationalActions
                  .map((action) => _CheckoutTag(label: 'Next', value: action))
                  .toList(growable: false),
            ),
          ],
          if (buyer.note.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              buyer.note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (buyer.preferredProducts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Last successful: ${buyer.preferredProducts.take(2).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutHintCard extends StatelessWidget {
  const _CheckoutHintCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyerRiskDecisionCard extends StatelessWidget {
  const _BuyerRiskDecisionCard({required this.status, required this.decision});

  final CheckoutResourceStatus status;
  final Map<String, dynamic>? decision;

  @override
  Widget build(BuildContext context) {
    if (status == CheckoutResourceStatus.loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.safe1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColor.safe),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColor.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Checking buyer',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status == CheckoutResourceStatus.failure) {
      return const _CheckoutHintCard(
        title: 'Buyer check unavailable',
        subtitle: 'Check phone, address, and COD before payment',
      );
    }

    if (decision == null || status != CheckoutResourceStatus.success) {
      return const SizedBox.shrink();
    }

    final resolvedDecision = decision!;
    final disposition = (resolvedDecision['decision'] ?? 'review').toString();
    final summary =
        (resolvedDecision['summary'] as String?)?.trim().isNotEmpty == true
        ? (resolvedDecision['summary'] as String).trim()
        : 'Check buyer before payment.';
    final reasons =
        ((resolvedDecision['reasons'] as List?) ?? const <dynamic>[])
            .map((reason) => reason.toString())
            .where((reason) => reason.trim().isNotEmpty)
            .toList(growable: false);
    final toneColor = disposition == 'blocked'
        ? AppColor.alert
        : disposition == 'review'
        ? AppColor.primary
        : AppColor.safe;
    final toneFill = disposition == 'blocked'
        ? AppColor.alertLight
        : disposition == 'review'
        ? AppColor.safe1
        : AppColor.safe1;
    final title = disposition == 'blocked'
        ? 'Buyer blocked'
        : disposition == 'review'
        ? 'Buyer needs review'
        : 'Buyer ready';
    final badge = disposition == 'blocked'
        ? 'COD stop'
        : disposition == 'review'
        ? 'Check now'
        : 'Ready';
    final codGuidance = disposition == 'blocked'
        ? 'Hold COD. Collect advance first.'
        : disposition == 'review'
        ? 'Check COD and landmark first.'
        : 'COD ready if the address is right.';
    final actions = <String>[
      if (disposition == 'blocked') 'Collect advance first',
      if (disposition == 'review') 'Review buyer now',
      if (disposition == 'approved') 'Go to payment',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: toneFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: toneColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppHugeIcon(
                disposition == 'blocked'
                    ? HugeIcons.strokeRoundedAlertCircle
                    : disposition == 'review'
                    ? HugeIcons.strokeRoundedAlert02
                    : HugeIcons.strokeRoundedCheckmarkCircle02,
                size: 16,
                color: toneColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: toneColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: toneColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _CheckoutTag(label: 'COD', value: codGuidance),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reasons
                  .take(3)
                  .map(
                    (reason) => _CheckoutTag(
                      label: 'Why',
                      value: reason.replaceAll('_', ' '),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map((action) => _CheckoutTag(label: 'Next', value: action))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutSummaryCard extends StatelessWidget {
  const _CheckoutSummaryCard({
    required this.itemCount,
    required this.supplierCount,
    required this.payableAmount,
    required this.voucherDiscount,
  });

  final int itemCount;
  final int supplierCount;
  final int payableAmount;
  final int voucherDiscount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start order',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            supplierCount > 1
                ? 'Buyer first, then split'
                : 'Buyer first, then price and lane',
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
              _CheckoutTag(label: 'Items', value: '$itemCount'),
              _CheckoutTag(label: 'Supply sources', value: '$supplierCount'),
              _CheckoutTag(
                label: 'Base',
                value: '৳ ${convertToBengaliNumber(payableAmount)}',
              ),
              _CheckoutTag(
                label: 'Voucher',
                value: voucherDiscount > 0
                    ? '-৳ ${convertToBengaliNumber(voucherDiscount)}'
                    : 'None',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutDraftCard extends StatelessWidget {
  const _CheckoutDraftCard({
    required this.hasBuyerDraft,
    required this.hasStoredDraft,
    required this.hasSavedBuyerAddress,
    required this.voucherCode,
    required this.supplierCount,
    required this.draftStatus,
    required this.onSaveDraft,
    this.onRestoreDraft,
    this.onClearDraft,
  });

  final bool hasBuyerDraft;
  final bool hasStoredDraft;
  final bool hasSavedBuyerAddress;
  final String voucherCode;
  final int supplierCount;
  final CheckoutResourceStatus draftStatus;
  final Future<void> Function() onSaveDraft;
  final Future<void> Function()? onRestoreDraft;
  final Future<void> Function()? onClearDraft;

  @override
  Widget build(BuildContext context) {
    final facts = <String>[
      hasBuyerDraft ? 'Buyer ready' : 'Start with phone',
      if (hasStoredDraft) 'Saved draft',
      if (hasSavedBuyerAddress) 'Saved address',
      if (voucherCode.trim().isNotEmpty) 'Voucher ${voucherCode.trim()}',
      if (supplierCount > 1) '$supplierCount orders',
    ];
    final isBusy = draftStatus == CheckoutResourceStatus.loading;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasStoredDraft ? 'Resume order' : 'Save order',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasStoredDraft
                ? 'Use saved or replace it now.'
                : 'Save now, finish later.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: facts
                .map((fact) => _CheckoutTag(label: 'Draft', value: fact))
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: isBusy
                    ? null
                    : () async {
                        await onSaveDraft();
                      },
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(hasStoredDraft ? 'Update' : 'Save'),
              ),
              if (onRestoreDraft != null)
                OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () async {
                          await onRestoreDraft!();
                        },
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Resume'),
                ),
              if (onClearDraft != null)
                TextButton.icon(
                  onPressed: isBusy
                      ? null
                      : () async {
                          await onClearDraft!();
                        },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Clear'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutDeliveryConfidenceCard extends StatelessWidget {
  const _CheckoutDeliveryConfidenceCard({required this.area});

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
            area.recommendedAction ?? 'Check landmark and ETA before order',
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
              _CheckoutTag(
                label: area.zoneLabel ?? 'Zone',
                value: area.confidenceLabel ?? 'Confidence',
              ),
              _CheckoutTag(
                label: 'ETA',
                value: area.deliveryEtaLabel ?? 'Check ETA',
              ),
              _CheckoutTag(
                label: 'COD',
                value: area.codSupportLabel ?? 'Check COD',
              ),
              _CheckoutTag(
                label: 'Risk',
                value: area.riskNote ?? area.note ?? 'Check buyer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutSupplierPreviewCard extends StatelessWidget {
  const _CheckoutSupplierPreviewCard({required this.suppliers});

  final List<_CheckoutSupplierPreview> suppliers;

  @override
  Widget build(BuildContext context) {
    if (suppliers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order split',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColor.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This order will create ${suppliers.length} supplier orders.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColor.neutral2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...suppliers.map(
          (supplier) => Padding(
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
                    supplier.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColor.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CheckoutTag(
                        label: 'Items',
                        value: '${supplier.itemCount}',
                      ),
                      _CheckoutTag(
                        label: 'Base',
                        value:
                            '৳ ${convertToBengaliNumber(supplier.supplierBase)}',
                      ),
                      _CheckoutTag(
                        label: 'Sell',
                        value:
                            '৳ ${convertToBengaliNumber(supplier.buyerTotal)}',
                      ),
                    ],
                  ),
                  if (supplier.itemTitles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      supplier.itemTitles.join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutSupplierPreview {
  const _CheckoutSupplierPreview({
    required this.label,
    required this.itemCount,
    required this.supplierBase,
    required this.buyerTotal,
    required this.itemTitles,
  });

  final String label;
  final int itemCount;
  final int supplierBase;
  final int buyerTotal;
  final List<String> itemTitles;
}

class _CheckoutTag extends StatelessWidget {
  const _CheckoutTag({required this.label, required this.value});

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
