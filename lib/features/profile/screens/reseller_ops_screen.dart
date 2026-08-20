import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/data/checkout_repository.dart';
import 'package:sellhub/features/cart/data/models/order_group_draft.dart';
import 'package:sellhub/features/cart/data/models/quick_order_draft.dart';
import 'package:sellhub/features/cart/data/models/reseller_order_line_draft.dart';
import 'package:sellhub/features/orders/data/models/order_issue_report.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/payout_dispute_entry.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/data/model/team_member_entry.dart';
import 'package:sellhub/features/profile/data/model/team_selling_overview.dart';
import 'package:sellhub/features/profile/data/model/team_shared_list_entry.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/injection_container.dart' as di;

class ResellerOpsScreen extends StatefulWidget {
  const ResellerOpsScreen({super.key});

  @override
  State<ResellerOpsScreen> createState() => _ResellerOpsScreenState();
}

class _ResellerOpsScreenState extends State<ResellerOpsScreen> {
  Future<_OpsPayload>? _future;
  final _chatController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _sellPriceController = TextEditingController();
  String _paymentMode = 'COD';
  bool _savingQuickOrder = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _buyerNameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  Future<_OpsPayload> _load() async {
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    final siteId = activeStore?.siteId ?? 0;
    final userId = await LocalStorage.getUserID() ?? 0;
    if (userId <= 0 || siteId <= 0) {
      return _OpsPayload.empty();
    }
    final profileRepository = di.sl<ProfileRepository>();
    final checkoutRepository = di.sl<CheckoutRepository>();
    final customer = await profileRepository.fetchSelfStoreCustomer(
      userId,
      siteId,
    );
    final buyers = await profileRepository.fetchBuyerBook(
      userId: userId,
      siteId: siteId,
    );
    final disputes = await profileRepository.fetchPayoutDisputes(
      userId: userId,
      siteId: siteId,
    );
    final team = await profileRepository.fetchTeamSellingOverview(
      userId: userId,
      siteId: siteId,
    );
    final drafts = await checkoutRepository.fetchQuickOrderDrafts(
      userId: userId,
      siteId: siteId,
    );
    final orderGroups = await checkoutRepository.fetchSupplierOrderGroupDrafts(
      userId: userId,
      siteId: siteId,
    );
    final issues = await LocalStorage.getOrderIssueReports();
    final truthMode = await LocalStorage.getBackendTruthMode();
    final nextWeek = _buildRepeatNextWeek(buyers);
    final referralBuyers = buyers
        .where((item) => item.sourceTag.trim().toLowerCase() == 'referral')
        .toList(growable: false);
    final latestDraft = drafts.isEmpty ? null : drafts.first;
    final legPreview = latestDraft == null
        ? null
        : await checkoutRepository.previewSupplierSplit(
            userId: userId,
            siteId: siteId,
            lines: latestDraft.lines
                .map(
                  (line) => <String, dynamic>{
                    'id': line.id,
                    'productId': line.id,
                    'title': line.title,
                    'quantity': line.quantity,
                    'basePrice': line.basePrice,
                    'sellPrice': line.sellPrice,
                    'supplierId': siteId,
                    'supplierName': activeStore?.title ?? 'Current supplier',
                    'siteId': siteId,
                  },
                )
                .toList(growable: false),
            draft: latestDraft.toJson(),
            supplierHints: <Map<String, dynamic>>[
              <String, dynamic>{
                'supplierId': siteId,
                'supplierName': activeStore?.title ?? 'Current supplier',
              },
            ],
          );
    return _OpsPayload(
      userId: userId,
      siteId: siteId,
      customer: customer,
      buyers: buyers,
      payoutDisputes: disputes,
      orderIssueReports: issues
          .where((item) => item.siteId == siteId)
          .toList(growable: false),
      teamOverview: team,
      quickOrderDrafts: drafts,
      orderGroups: orderGroups,
      truthMode: truthMode,
      repeatNextWeek: nextWeek,
      referralBuyers: referralBuyers,
      supplierLegPreview: legPreview,
    );
  }

  List<BuyerBookProfile> _buildRepeatNextWeek(List<BuyerBookProfile> buyers) {
    final now = DateTime.now();
    final candidates =
        buyers
            .where((buyer) {
              if (!buyer.isRepeatBuyer || buyer.isBlocked) return false;
              final lastOrderedAt = buyer.lastOrderedAt;
              if (lastOrderedAt == null) return false;
              final days = now.difference(lastOrderedAt).inDays;
              return days >= 7 && days <= 45;
            })
            .toList(growable: false)
          ..sort((a, b) {
            final scoreA =
                (a.totalDelivered * 4) + (a.totalOrders * 3) - a.returnCount;
            final scoreB =
                (b.totalDelivered * 4) + (b.totalOrders * 3) - b.returnCount;
            return scoreB.compareTo(scoreA);
          });
    return candidates.take(6).toList(growable: false);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  void _parseChat() {
    final raw = _chatController.text.trim();
    if (raw.isEmpty) return;
    final lines = raw
        .split(RegExp(r'[\n\r]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final phoneMatch = RegExp(r'(\+?88)?01[3-9]\d{8}').firstMatch(raw);
    final quantityMatch = RegExp(
      r'(\d+)\s*(pcs|piece|pieces|x)\b',
      caseSensitive: false,
    ).firstMatch(raw);
    final priceMatch = RegExp(
      r'(?:৳|tk|bdt)\s*([0-9]{2,6})',
      caseSensitive: false,
    ).firstMatch(raw);
    final addressLine = lines.firstWhere(
      (item) =>
          item.toLowerCase().contains('address') ||
          item.toLowerCase().contains('area'),
      orElse: () => '',
    );
    final buyerLine = lines.firstWhere(
      (item) =>
          !RegExp(r'(\+?88)?01[3-9]\d{8}').hasMatch(item) &&
          !item.toLowerCase().contains('address') &&
          !item.toLowerCase().contains('area') &&
          !item.toLowerCase().contains('price') &&
          !item.toLowerCase().contains('tk') &&
          !item.toLowerCase().contains('৳'),
      orElse: () => '',
    );
    final productLine = lines.firstWhere(
      (item) =>
          item.toLowerCase().contains('product') ||
          item.toLowerCase().contains('item'),
      orElse: () => lines.length > 1 ? lines[1] : lines.first,
    );

    setState(() {
      if (_phoneController.text.trim().isEmpty && phoneMatch != null) {
        _phoneController.text = phoneMatch.group(0)!.replaceAll('+88', '');
      }
      if (_buyerNameController.text.trim().isEmpty && buyerLine.isNotEmpty) {
        _buyerNameController.text = buyerLine
            .replaceFirst(
              RegExp(r'^(name|buyer)\s*:?\s*', caseSensitive: false),
              '',
            )
            .trim();
      }
      if (_addressController.text.trim().isEmpty && addressLine.isNotEmpty) {
        _addressController.text = addressLine
            .replaceFirst(
              RegExp(r'^(address|area)\s*:?\s*', caseSensitive: false),
              '',
            )
            .trim();
      }
      if (_areaController.text.trim().isEmpty && addressLine.isNotEmpty) {
        _areaController.text = addressLine
            .replaceFirst(
              RegExp(r'^(address|area)\s*:?\s*', caseSensitive: false),
              '',
            )
            .split(',')
            .first
            .trim();
      }
      if (_productController.text.trim().isEmpty && productLine.isNotEmpty) {
        _productController.text = productLine
            .replaceFirst(
              RegExp(r'^(product|item)\s*:?\s*', caseSensitive: false),
              '',
            )
            .trim();
      }
      if (_quantityController.text.trim().isEmpty ||
          _quantityController.text.trim() == '1') {
        _quantityController.text =
            quantityMatch?.group(1) ?? _quantityController.text;
      }
      if (_sellPriceController.text.trim().isEmpty && priceMatch != null) {
        _sellPriceController.text = priceMatch.group(1) ?? '';
      }
      if (raw.toLowerCase().contains('advance')) {
        _paymentMode = 'Advance';
      } else if (raw.toLowerCase().contains('cod')) {
        _paymentMode = 'COD';
      }
    });
  }

  Future<void> _saveQuickOrder(
    _OpsPayload payload, {
    bool openFlow = false,
  }) async {
    if (_savingQuickOrder) return;
    final buyerName = _buyerNameController.text.trim();
    final phone = _phoneController.text.trim();
    final productTitle = _productController.text.trim();
    final address = _addressController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final sellPrice = int.tryParse(_sellPriceController.text.trim()) ?? 0;
    if (buyerName.isEmpty ||
        phone.isEmpty ||
        productTitle.isEmpty ||
        sellPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buyer, phone, product, and sell price are required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _savingQuickOrder = true;
    });
    try {
      final supplierName =
          context.read<StoreContextCubit>().state.activeStore?.title ??
          'Current supplier';
      final checkoutRepository = di.sl<CheckoutRepository>();
      final draftId =
          'chat-${payload.siteId}-${DateTime.now().millisecondsSinceEpoch}';
      final line = ResellerOrderLineDraft(
        id: null,
        title: productTitle,
        thumbnail: '',
        quantity: quantity,
        basePrice: (sellPrice * 0.75).round(),
        sellPrice: sellPrice,
        minSellPrice: (sellPrice * 0.9).round(),
        maxSellPrice: (sellPrice * 1.1).round(),
        vat: 0,
      );
      final total = line.lineSellTotal;
      final draft = await checkoutRepository.saveQuickOrderDraft(
        userId: payload.userId,
        siteId: payload.siteId,
        draft: <String, dynamic>{
          'id': draftId,
          'draftId': draftId,
          'title': '$productTitle quick order',
          'buyerName': buyerName,
          'buyerPhone': phone,
          'buyerAddress': address,
          'note':
              'Area: ${_areaController.text.trim()}\nPayment: $_paymentMode\nChat source: ${_chatController.text.trim()}',
          'status': 'confirmed-draft',
          'deliveryLabel': _areaController.text.trim().isEmpty
              ? 'Delivery area'
              : _areaController.text.trim(),
          'deliveryCharge': 0,
          'subtotal': total,
          'total': total,
          'lines': <Map<String, dynamic>>[line.toJson()],
        },
      );
      await checkoutRepository.previewSupplierSplit(
        userId: payload.userId,
        siteId: payload.siteId,
        lines: <Map<String, dynamic>>[
          <String, dynamic>{
            ...line.toJson(),
            'supplierId': payload.siteId,
            'supplierName': supplierName,
            'siteId': payload.siteId,
          },
        ],
        draft: draft,
      );
      await LocalStorage.savePendingBuyer(
        BuyerBookProfile(
          id: 'chat-$phone',
          name: buyerName,
          phone: phone,
          addresses: <String>[if (address.isNotEmpty) address],
          primaryAddress: address,
          note: _chatController.text.trim(),
          sourceTag: 'Chat',
          isRisky: false,
          isBlocked: false,
          totalOrders: 0,
          totalDelivered: 0,
          returnCount: 0,
          pendingOrders: 1,
          unpaidOrders: _paymentMode == 'Advance' ? 1 : 0,
          totalSales: 0,
          averageBasketSize: total.toDouble(),
          lastOrderedAt: DateTime.now(),
          profileMetaUpdatedAt: DateTime.now(),
          preferredProducts: <String>[productTitle],
          district: _areaController.text.trim(),
          deliveryZone: _areaController.text.trim(),
          lastOrderId: null,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            openFlow
                ? 'Chat order saved. Buyer is ready in the sell flow.'
                : 'Quick-order draft saved.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refresh();
      if (!mounted) return;
      if (openFlow) {
        AppRouter.goToCart(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingQuickOrder = false;
        });
      }
    }
  }

  Future<void> _setTruthMode(String mode) async {
    await LocalStorage.saveBackendTruthMode(mode);
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _shareReferralLoop(_OpsPayload payload) async {
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    final referCode = payload.customer?.referCode?.trim();
    if (activeStore == null || referCode == null || referCode.isEmpty) return;
    await Share.share(
      SellHubShareLinkBuilder.buildReferralShareText(
        store: activeStore,
        referCode: referCode,
        rewardLabel:
            '${payload.referralBuyers.length} referral buyers already in your loop',
      ),
      subject: 'SellHub referral loop',
    );
  }

  Future<void> _useBuyer(BuyerBookProfile buyer) async {
    await LocalStorage.savePendingBuyer(buyer);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${buyer.name} is ready in checkout.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Reseller ops',
        subtitle:
            'Chat intake, truth mode, legs, disputes, repeat, team, and referrals',
        icon: HugeIcons.strokeRoundedDashboardSquare03,
        showBackButton: true,
      ),
      body: FutureBuilder<_OpsPayload>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final payload = snapshot.data ?? _OpsPayload.empty();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TruthModeCard(
                  mode: payload.truthMode,
                  onChanged: _setTruthMode,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: HugeIcons.strokeRoundedMessage02,
                  title: 'Chat-to-order mode',
                  subtitle:
                      'Paste a chat, parse it, and turn it into a buyer-ready draft.',
                  child: Column(
                    children: [
                      TextField(
                        controller: _chatController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Chat text',
                          hintText:
                              'Paste the buyer message with name, phone, area, product, quantity, and price.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _parseChat,
                              child: const Text('Parse chat'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _savingQuickOrder
                                  ? null
                                  : () => _saveQuickOrder(
                                      payload,
                                      openFlow: true,
                                    ),
                              child: Text(
                                _savingQuickOrder
                                    ? 'Saving...'
                                    : 'Save and open flow',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: HugeIcons.strokeRoundedShoppingBasket01,
                  title: 'True quick-order lane',
                  subtitle:
                      'Capture a sale draft with the minimum reseller fields.',
                  child: Column(
                    children: [
                      _TwoFieldRow(
                        left: TextField(
                          controller: _buyerNameController,
                          decoration: const InputDecoration(labelText: 'Buyer'),
                        ),
                        right: TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone'),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TwoFieldRow(
                        left: TextField(
                          controller: _areaController,
                          decoration: const InputDecoration(labelText: 'Area'),
                        ),
                        right: DropdownButtonFormField<String>(
                          initialValue: _paymentMode,
                          items: const <String>['COD', 'Advance']
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _paymentMode = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Payment',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                      const SizedBox(height: 10),
                      _TwoFieldRow(
                        left: TextField(
                          controller: _productController,
                          decoration: const InputDecoration(
                            labelText: 'Product',
                          ),
                        ),
                        right: TextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(labelText: 'Qty'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _sellPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Sell price',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _savingQuickOrder
                              ? null
                              : () => _saveQuickOrder(payload),
                          child: const Text('Save draft'),
                        ),
                      ),
                      if (payload.quickOrderDrafts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...payload.quickOrderDrafts
                            .take(3)
                            .map(
                              (draft) => _ActionListCard(
                                title: draft.buyerName,
                                subtitle:
                                    '${draft.lines.isEmpty ? draft.title : draft.lines.first.title} • Qty ${draft.lines.fold<int>(0, (sum, item) => sum + item.quantity)} • ${formatDateTime(draft.updatedAt)}',
                                actionLabel: 'Open flow',
                                onAction: () async {
                                  final requiresAdvance = draft.note
                                      .toLowerCase()
                                      .contains('payment: advance');
                                  await LocalStorage.savePendingBuyer(
                                    BuyerBookProfile(
                                      id: draft.id,
                                      name: draft.buyerName,
                                      phone: draft.buyerPhone,
                                      addresses: <String>[
                                        if (draft.buyerAddress
                                            .trim()
                                            .isNotEmpty)
                                          draft.buyerAddress.trim(),
                                      ],
                                      primaryAddress: draft.buyerAddress,
                                      note: draft.note,
                                      sourceTag: 'Quick order',
                                      isRisky: false,
                                      isBlocked: false,
                                      totalOrders: 0,
                                      totalDelivered: 0,
                                      returnCount: 0,
                                      pendingOrders: 1,
                                      unpaidOrders: requiresAdvance ? 1 : 0,
                                      totalSales: draft.total.toDouble(),
                                      averageBasketSize: draft.total.toDouble(),
                                      lastOrderedAt: draft.updatedAt,
                                      profileMetaUpdatedAt: draft.updatedAt,
                                      preferredProducts: draft.lines
                                          .map((item) => item.title.trim())
                                          .where((item) => item.isNotEmpty)
                                          .toList(growable: false),
                                      district: draft.deliveryLabel,
                                      deliveryZone: draft.deliveryLabel,
                                      lastOrderId: null,
                                    ),
                                  );
                                  if (!context.mounted) return;
                                  AppRouter.goToCart(context);
                                },
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: HugeIcons.strokeRoundedPackageProcess,
                  title: 'Supplier leg ledger',
                  subtitle: 'Read supplier lanes before final order placement.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (payload.supplierLegPreview != null) ...[
                        _KpiRow(
                          items: <({String label, String value})>[
                            (
                              label: 'Lanes',
                              value:
                                  '${payload.supplierLegPreview!['supplierCount'] ?? 0}',
                            ),
                            (
                              label: 'Sell',
                              value:
                                  '৳${((payload.supplierLegPreview!['totalSellAmount'] as num?) ?? 0).toStringAsFixed(0)}',
                            ),
                            (
                              label: 'Profit',
                              value:
                                  '৳${((payload.supplierLegPreview!['totalProfit'] as num?) ?? 0).toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...((payload.supplierLegPreview!['suppliers']
                                    as List<dynamic>? ??
                                const <dynamic>[])
                            .whereType<Map>()
                            .map(
                              (item) => _MiniLedgerCard(
                                title: '${item['supplierName'] ?? 'Supplier'}',
                                subtitle:
                                    '${item['lineCount'] ?? 0} items • Qty ${item['quantity'] ?? 0}',
                                trailing:
                                    '৳${((item['sellAmount'] as num?) ?? 0).toStringAsFixed(0)}',
                              ),
                            )),
                      ],
                      if (payload.orderGroups.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...payload.orderGroups
                            .take(3)
                            .map(
                              (group) => _MiniLedgerCard(
                                title: group.title,
                                subtitle:
                                    '${group.targetOrderCount} supplier legs • ${group.channel}',
                                trailing: '৳${group.projectedRevenue}',
                              ),
                            ),
                      ],
                      if (payload.supplierLegPreview == null &&
                          payload.orderGroups.isEmpty)
                        const _EmptyHint(
                          text:
                              'Save a quick-order draft first to generate supplier lanes here.',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: HugeIcons.strokeRoundedReload,
                  title: 'Repeat-next-week engine',
                  subtitle: 'Surface likely repeat buyers before they go cold.',
                  child: payload.repeatNextWeek.isEmpty
                      ? const _EmptyHint(
                          text:
                              'Repeat buyers will appear here once the buyer loop builds more delivered history.',
                        )
                      : Column(
                          children: payload.repeatNextWeek
                              .map(
                                (buyer) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ActionListCard(
                                    title: buyer.name,
                                    subtitle:
                                        '${buyer.preferredProducts.isEmpty ? 'Repeat buyer' : buyer.preferredProducts.first} • Last order ${formatDateTime(buyer.lastOrderedAt)}',
                                    actionLabel: 'Start order',
                                    onAction: () async {
                                      await _useBuyer(buyer);
                                      if (!context.mounted) return;
                                      AppRouter.goToCart(context);
                                    },
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: HugeIcons.strokeRoundedAlert02,
                  title: 'Unified dispute inbox',
                  subtitle: 'See payout and order problems in one place.',
                  child: _DisputeInbox(
                    payoutDisputes: payload.payoutDisputes,
                    orderIssueReports: payload.orderIssueReports,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: HugeIcons.strokeRoundedUserMultiple02,
                  title: 'Team network operations',
                  subtitle:
                      'Track invite conversion, team output, and shared distribution.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KpiRow(
                        items: <({String label, String value})>[
                          (
                            label: 'Active',
                            value: '${payload.teamOverview.activeMembers}',
                          ),
                          (
                            label: 'Invites',
                            value: '${payload.teamOverview.pendingInvites}',
                          ),
                          (
                            label: 'Lists',
                            value: '${payload.teamOverview.sharedListCount}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _MiniLedgerCard(
                        title: payload.teamOverview.teamName,
                        subtitle:
                            'Volume ৳${payload.teamOverview.teamOrderVolume.toStringAsFixed(0)} • Override ৳${payload.teamOverview.overrideEarned.toStringAsFixed(0)}',
                        trailing:
                            '${payload.teamOverview.distributedProductCount} products',
                      ),
                      if (payload.teamOverview.members.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...payload.teamOverview.members
                            .take(3)
                            .map(
                              (member) => _MiniLedgerCard(
                                title: member.name,
                                subtitle:
                                    '${member.status} • ${member.topProduct.isEmpty ? 'No top product yet' : member.topProduct}',
                                trailing:
                                    '৳${member.orderVolume.toStringAsFixed(0)}',
                              ),
                            ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () => AppRouter.goToTeamSelling(context),
                          child: const Text('Open team'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: HugeIcons.strokeRoundedShare08,
                  title: 'Referral reward loop',
                  subtitle: 'Track referral buyers and share your loop again.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KpiRow(
                        items: <({String label, String value})>[
                          (
                            label: 'Code',
                            value:
                                payload.customer?.referCode
                                        ?.trim()
                                        .isNotEmpty ==
                                    true
                                ? payload.customer!.referCode!.trim()
                                : 'Not set',
                          ),
                          (
                            label: 'Referral buyers',
                            value: '${payload.referralBuyers.length}',
                          ),
                          (
                            label: 'Referral sales',
                            value:
                                '৳${payload.referralBuyers.fold<double>(0, (sum, item) => sum + item.totalSales).toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (payload.referralBuyers.isNotEmpty)
                        ...payload.referralBuyers
                            .take(3)
                            .map(
                              (buyer) => _MiniLedgerCard(
                                title: buyer.name,
                                subtitle:
                                    '${buyer.totalOrders} orders • ${buyer.district}',
                                trailing:
                                    '৳${buyer.totalSales.toStringAsFixed(0)}',
                              ),
                            ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => _shareReferralLoop(payload),
                          child: const Text('Share referral code'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OpsPayload {
  const _OpsPayload({
    required this.userId,
    required this.siteId,
    required this.customer,
    required this.buyers,
    required this.payoutDisputes,
    required this.orderIssueReports,
    required this.teamOverview,
    required this.quickOrderDrafts,
    required this.orderGroups,
    required this.truthMode,
    required this.repeatNextWeek,
    required this.referralBuyers,
    required this.supplierLegPreview,
  });

  final int userId;
  final int siteId;
  final SelfStoreCustomerRes? customer;
  final List<BuyerBookProfile> buyers;
  final List<PayoutDisputeEntry> payoutDisputes;
  final List<OrderIssueReport> orderIssueReports;
  final TeamSellingOverview teamOverview;
  final List<QuickOrderDraft> quickOrderDrafts;
  final List<OrderGroupDraft> orderGroups;
  final String truthMode;
  final List<BuyerBookProfile> repeatNextWeek;
  final List<BuyerBookProfile> referralBuyers;
  final Map<String, dynamic>? supplierLegPreview;

  factory _OpsPayload.empty() {
    return const _OpsPayload(
      userId: 0,
      siteId: 0,
      customer: null,
      buyers: <BuyerBookProfile>[],
      payoutDisputes: <PayoutDisputeEntry>[],
      orderIssueReports: <OrderIssueReport>[],
      teamOverview: TeamSellingOverview(
        teamId: '',
        ownerUserId: 0,
        siteId: 0,
        teamName: 'SellHub Team',
        ownerName: '',
        overridePercent: 0,
        transparentPayoutRule: '',
        activeMembers: 0,
        pendingInvites: 0,
        teamOrderVolume: 0,
        overrideEarned: 0,
        sharedListCount: 0,
        distributedProductCount: 0,
        members: <TeamMemberEntry>[],
        sharedLists: <TeamSharedListEntry>[],
      ),
      quickOrderDrafts: <QuickOrderDraft>[],
      orderGroups: <OrderGroupDraft>[],
      truthMode: 'local',
      repeatNextWeek: <BuyerBookProfile>[],
      referralBuyers: <BuyerBookProfile>[],
      supplierLegPreview: null,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TruthModeCard extends StatelessWidget {
  const _TruthModeCard({required this.mode, required this.onChanged});

  final String mode;
  final Future<void> Function(String mode) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppHugeIcon(
                HugeIcons.strokeRoundedDatabaseSync01,
                size: 18,
                color: AppColor.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Backend truth mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _TruthPill(label: mode == 'backend' ? 'Backend' : 'Local MVP'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mode == 'backend'
                ? 'Use backend-first operator expectations when live truth is available.'
                : 'Local-first mode is active. Treat payout, team, and dispute surfaces as local records.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'local', label: Text('Local MVP')),
              ButtonSegment<String>(value: 'backend', label: Text('Backend')),
            ],
            selected: <String>{mode == 'backend' ? 'backend' : 'local'},
            onSelectionChanged: (value) {
              final selected = value.first;
              onChanged(selected);
            },
          ),
        ],
      ),
    );
  }
}

class _TruthPill extends StatelessWidget {
  const _TruthPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColor.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TwoFieldRow extends StatelessWidget {
  const _TwoFieldRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.items});

  final List<({String label, String value})> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: item == items.last ? 0 : 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MiniLedgerCard extends StatelessWidget {
  const _MiniLedgerCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Expanded(
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
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionListCard extends StatelessWidget {
  const _ActionListCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Expanded(
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
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _DisputeInbox extends StatelessWidget {
  const _DisputeInbox({
    required this.payoutDisputes,
    required this.orderIssueReports,
  });

  final List<PayoutDisputeEntry> payoutDisputes;
  final List<OrderIssueReport> orderIssueReports;

  @override
  Widget build(BuildContext context) {
    final items =
        <
            ({
              String title,
              String subtitle,
              String badge,
              DateTime updatedAt,
              VoidCallback onTap,
            })
          >[
            ...payoutDisputes.map(
              (item) => (
                title: 'Payout ${item.orderId}',
                subtitle: '${item.reason} • ${formatDateTime(item.updatedAt)}',
                badge: item.status,
                updatedAt: item.updatedAt ?? item.createdAt ?? DateTime.now(),
                onTap: () => AppRouter.goToPayouts(context),
              ),
            ),
            ...orderIssueReports.map(
              (item) => (
                title: 'Order ${item.orderId}',
                subtitle:
                    '${item.issueType} • ${formatDateTime(item.updatedAt)}',
                badge: item.status,
                updatedAt: item.updatedAt,
                onTap: () => AppRouter.goToOrders(context),
              ),
            ),
          ]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (items.isEmpty) {
      return const _EmptyHint(
        text: 'Open issue briefs and payout mismatches will appear here.',
      );
    }
    return Column(
      children: items
          .take(6)
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: Row(
                    children: [
                      const AppHugeIcon(
                        HugeIcons.strokeRoundedAlert02,
                        size: 16,
                        color: AppColor.alert,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColor.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColor.neutral2,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _TruthPill(label: item.badge),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColor.neutral2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
