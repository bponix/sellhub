import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/repeat_sell_reminder.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/injection_container.dart' as di;

class BuyerBookScreen extends StatefulWidget {
  const BuyerBookScreen({super.key});

  @override
  State<BuyerBookScreen> createState() => _BuyerBookScreenState();
}

class _BuyerBookScreenState extends State<BuyerBookScreen> {
  late Future<List<BuyerBookProfile>> _future;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDistrict;
  _BuyerSegment _segment = _BuyerSegment.all;
  List<RepeatSellReminder> _repeatSellReminders = const <RepeatSellReminder>[];

  @override
  void initState() {
    super.initState();
    _future = _loadBuyerBook();
    _loadRepeatSellReminders();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _refresh() async {
    setState(() {
      _future = _loadBuyerBook();
    });
    await _future;
    await _loadRepeatSellReminders();
  }

  Future<void> _loadRepeatSellReminders() async {
    final reminders = await LocalStorage.getRepeatSellReminders();
    if (!mounted) return;
    reminders.sort(
      (a, b) => (a.scheduledFor ?? DateTime(2100)).compareTo(
        b.scheduledFor ?? DateTime(2100),
      ),
    );
    setState(() {
      _repeatSellReminders = reminders;
    });
  }

  List<BuyerBookProfile> _filteredBuyers(List<BuyerBookProfile> buyers) {
    final filteredBySegment = buyers
        .where((buyer) {
          switch (_segment) {
            case _BuyerSegment.all:
              return true;
            case _BuyerSegment.repeat:
              return buyer.isRepeatBuyer;
            case _BuyerSegment.referral:
              return buyer.sourceTag.trim().toLowerCase() == 'referral';
            case _BuyerSegment.risky:
              return buyer.isRisky;
            case _BuyerSegment.pending:
              return buyer.hasPendingBuyerRisk;
            case _BuyerSegment.blocked:
              return buyer.isBlocked;
          }
        })
        .toList(growable: false);
    final matched = _searchQuery.isEmpty
        ? filteredBySegment
        : filteredBySegment
              .where((buyer) {
                final haystack = <String>[
                  buyer.name,
                  buyer.phone,
                  buyer.primaryAddress,
                  buyer.note,
                  buyer.sourceTag,
                  buyer.district,
                  buyer.deliveryZone,
                  ...buyer.preferredProducts,
                ].join(' ').toLowerCase();
                return haystack.contains(_searchQuery);
              })
              .toList(growable: false);
    final districtFiltered = _selectedDistrict == null
        ? matched
        : matched
              .where(
                (buyer) =>
                    buyer.district.trim().toLowerCase() ==
                    _selectedDistrict!.trim().toLowerCase(),
              )
              .toList(growable: false);
    final sorted = List<BuyerBookProfile>.from(districtFiltered);
    sorted.sort((a, b) => _buyerAssetScore(b).compareTo(_buyerAssetScore(a)));
    return sorted;
  }

  double _buyerAssetScore(BuyerBookProfile buyer) {
    final recencyBoost = buyer.lastOrderedAt == null
        ? 0
        : 30 -
              DateTime.now()
                  .difference(buyer.lastOrderedAt!)
                  .inDays
                  .clamp(0, 30);
    return (buyer.totalDelivered * 12) +
        (buyer.totalOrders * 8) +
        (buyer.averageBasketSize / 40) +
        (buyer.preferredProducts.length * 6) +
        (buyer.addresses.length * 3) +
        recencyBoost -
        (buyer.returnRate * 0.8) -
        (buyer.unpaidOrders * 14) -
        (buyer.isRisky ? 16 : 0) -
        (buyer.isBlocked ? 30 : 0);
  }

  List<_RepeatSellPrompt> _buildRepeatSellPrompts(
    List<BuyerBookProfile> buyers,
  ) {
    final prompts = buyers
        .where(
          (buyer) =>
              !buyer.isBlocked &&
              !buyer.isRisky &&
              buyer.preferredProducts.isNotEmpty,
        )
        .map(
          (buyer) => _RepeatSellPrompt(
            buyerName: buyer.name,
            buyerPhone: buyer.phone,
            productTitle: buyer.preferredProducts.first,
            reason: buyer.isRepeatBuyer
                ? 'Repeat buyer with purchase history'
                : 'Recent buyer with a reusable winning product',
            lastOrderLabel: _lastOrderLabel(buyer.lastOrderedAt),
            district: buyer.district,
            averageBasketSize: buyer.averageBasketSize,
          ),
        )
        .toList(growable: false);
    prompts.sort((a, b) => b.averageBasketSize.compareTo(a.averageBasketSize));
    return prompts.take(4).toList(growable: false);
  }

  List<_NeighborhoodCluster> _buildNeighborhoodClusters(
    List<BuyerBookProfile> buyers,
  ) {
    final grouped = <String, List<BuyerBookProfile>>{};
    for (final buyer in buyers) {
      final district = buyer.district.trim().isEmpty
          ? 'Unknown district'
          : buyer.district.trim();
      grouped.putIfAbsent(district, () => <BuyerBookProfile>[]).add(buyer);
    }
    final clusters =
        grouped.entries
            .map((entry) {
              final districtBuyers = entry.value;
              final repeatCount = districtBuyers
                  .where((item) => item.isRepeatBuyer)
                  .length;
              final riskyCount = districtBuyers
                  .where((item) => item.isRisky)
                  .length;
              final bestProductFrequency = <String, int>{};
              for (final buyer in districtBuyers) {
                for (final product in buyer.preferredProducts) {
                  bestProductFrequency[product] =
                      (bestProductFrequency[product] ?? 0) + 1;
                }
              }
              String topProduct = 'Build local history';
              if (bestProductFrequency.isNotEmpty) {
                final sorted = bestProductFrequency.entries.toList(
                  growable: false,
                )..sort((a, b) => b.value.compareTo(a.value));
                topProduct = sorted.first.key;
              }
              return _NeighborhoodCluster(
                district: entry.key,
                buyerCount: districtBuyers.length,
                repeatCount: repeatCount,
                riskyCount: riskyCount,
                topProduct: topProduct,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.buyerCount.compareTo(a.buyerCount));
    return clusters.take(4).toList(growable: false);
  }

  List<_ReferralPrompt> _buildReferralPrompts(List<BuyerBookProfile> buyers) {
    final prompts = buyers
        .where(
          (buyer) =>
              buyer.sourceTag.trim().toLowerCase() == 'referral' &&
              !buyer.isBlocked,
        )
        .map(
          (buyer) => _ReferralPrompt(
            buyerName: buyer.name,
            buyerPhone: buyer.phone,
            district: buyer.district,
            leadProduct: buyer.preferredProducts.isNotEmpty
                ? buyer.preferredProducts.first
                : 'Pick product',
            totalOrders: buyer.totalOrders,
            averageBasketSize: buyer.averageBasketSize,
          ),
        )
        .toList(growable: false);
    prompts.sort((a, b) => b.averageBasketSize.compareTo(a.averageBasketSize));
    return prompts.take(4).toList(growable: false);
  }

  Future<void> _scheduleReminder(
    BuyerBookProfile buyer, {
    required int daysFromNow,
  }) async {
    final productTitle = buyer.preferredProducts.isNotEmpty
        ? buyer.preferredProducts.first
        : 'Pick product';
    final reminder = RepeatSellReminder(
      id: '${buyer.id}-${daysFromNow}d',
      buyerId: buyer.id,
      buyerName: buyer.name,
      buyerPhone: buyer.phone,
      productTitle: productTitle,
      district: buyer.district,
      note: 'Reopen from Buyer Book and start order in checkout.',
      scheduledFor: DateTime.now().add(Duration(days: daysFromNow)),
      createdAt: DateTime.now(),
      status: 'open',
    );
    await LocalStorage.upsertRepeatSellReminder(reminder);
    if (!mounted) return;
    CustomToast.info('Repeat reminder saved for ${buyer.name}');
    await _loadRepeatSellReminders();
  }

  Future<void> _removeReminder(String id) async {
    await LocalStorage.deleteRepeatSellReminder(id);
    if (!mounted) return;
    CustomToast.info('Reminder removed');
    await _loadRepeatSellReminders();
  }

  Future<void> _editBuyer(BuyerBookProfile buyer) async {
    final noteController = TextEditingController(text: buyer.note);
    String sourceTag = buyer.sourceTag;
    bool isRisky = buyer.isRisky;
    bool isBlocked = buyer.isBlocked;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buyer record',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColor.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Buyer note',
                      hintText:
                          'Prefers evening delivery, calls before dispatch',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: sourceTag,
                    items: const [
                      DropdownMenuItem(
                        value: 'WhatsApp',
                        child: Text('WhatsApp'),
                      ),
                      DropdownMenuItem(
                        value: 'Facebook',
                        child: Text('Facebook'),
                      ),
                      DropdownMenuItem(value: 'Repeat', child: Text('Repeat')),
                      DropdownMenuItem(
                        value: 'Referral',
                        child: Text('Referral'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() {
                        sourceTag = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Source tag'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isRisky,
                    onChanged: (value) {
                      setSheetState(() {
                        isRisky = value;
                      });
                    },
                    title: const Text('Mark as risky buyer'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isBlocked,
                    onChanged: (value) {
                      setSheetState(() {
                        isBlocked = value;
                      });
                    },
                    title: const Text('Blocklist buyer'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Save buyer record'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (saved != true) return;
    final userId = await LocalStorage.getUserID() ?? 0;
    if (!mounted || userId <= 0) return;
    final siteId = StoreScope.activeSiteId(context);
    final success = await di.sl<ProfileRepository>().saveBuyerProfileMeta(
      buyerId: buyer.id,
      buyerName: buyer.name,
      buyerPhone: buyer.phone,
      userId: userId,
      siteId: siteId,
      note: noteController.text,
      sourceTag: sourceTag,
      isRisky: isRisky,
      isBlocked: isBlocked,
    );
    noteController.dispose();
    if (!mounted) return;
    if (!success) {
      CustomToast.info('Saved offline. Reopen this buyer to sync with Store.');
      return;
    }
    CustomToast.info('Buyer record updated');
    await _refresh();
  }

  Future<void> _useForNextOrder(BuyerBookProfile buyer) async {
    await LocalStorage.savePendingBuyer(buyer);
    if (!mounted) return;
    CustomToast.info('Buyer reopened in selling flow');
    AppRouter.goToSellingList(context);
  }

  void _openRepeatSearch(String productTitle) {
    final query = productTitle.trim();
    if (_isBuyerBookPlaceholderProduct(query)) return;
    AppRouter.pushSearchScreen(context, mode: 'repeat', query: query);
  }

  void _openReferralSearch(String productTitle) {
    final query = productTitle.trim();
    if (_isBuyerBookPlaceholderProduct(query)) return;
    AppRouter.pushSearchScreen(context, mode: 'facebook', query: query);
  }

  void _openNeighborhoodSearch(String productTitle) {
    final query = productTitle.trim();
    if (query.isEmpty || query.toLowerCase() == 'build local history') return;
    AppRouter.pushSearchScreen(context, mode: 'repeat', query: query);
  }

  Future<void> _resetBuyerMeta(BuyerBookProfile buyer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Reset buyer record'),
          content: Text(
            'Remove the saved note, source tag, and risk flags for ${buyer.name}? Order history will remain.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final userId = await LocalStorage.getUserID() ?? 0;
    if (!mounted || userId <= 0) return;
    final success = await di.sl<ProfileRepository>().resetBuyerProfileMeta(
      buyer: buyer,
      userId: userId,
      siteId: StoreScope.activeSiteId(context),
    );
    if (!mounted) return;
    CustomToast.info(success ? 'Buyer record reset' : 'Reset saved offline');
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Buyer Book',
        icon: HugeIcons.strokeRoundedUserGroup,
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<BuyerBookProfile>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _BuyerBookEmptyState(
                    icon: HugeIcons.strokeRoundedAlert02,
                    title: 'Unable to load buyers',
                    subtitle: 'Pull to refresh and try again.',
                  ),
                ],
              );
            }
            final buyers = snapshot.data ?? const <BuyerBookProfile>[];
            final filteredBuyers = _filteredBuyers(buyers);
            final repeatBuyers = buyers
                .where((buyer) => buyer.isRepeatBuyer)
                .length;
            final riskyBuyers = buyers.where((buyer) => buyer.isRisky).length;
            final pendingCashBuyers = buyers
                .where((buyer) => buyer.unpaidOrders > 0)
                .length;
            final referralBuyers = buyers
                .where(
                  (buyer) => buyer.sourceTag.trim().toLowerCase() == 'referral',
                )
                .length;
            final readyToResell = buyers
                .where(
                  (buyer) =>
                      buyer.isRepeatBuyer || buyer.preferredProducts.isNotEmpty,
                )
                .length;
            final blockedBuyers = buyers
                .where((buyer) => buyer.isBlocked)
                .length;
            final repeatSellPrompts = _buildRepeatSellPrompts(buyers);
            final neighborhoodClusters = _buildNeighborhoodClusters(buyers);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _BuyerBookOverviewCard(
                  totalBuyers: buyers.length,
                  repeatBuyers: repeatBuyers,
                  referralBuyers: referralBuyers,
                  riskyBuyers: riskyBuyers,
                  pendingCashBuyers: pendingCashBuyers,
                  readyToResell: readyToResell,
                  blockedBuyers: blockedBuyers,
                ),
                if (referralBuyers > 0) ...[
                  const SizedBox(height: 14),
                  _ReferralLoopCard(
                    prompts: _buildReferralPrompts(buyers),
                    onUseBuyer: (buyerPhone) async {
                      final match = buyers.firstWhere(
                        (buyer) => buyer.phone == buyerPhone,
                        orElse: () => buyers.first,
                      );
                      await _useForNextOrder(match);
                    },
                    onFindProduct: _openReferralSearch,
                    onFocusReferral: () =>
                        setState(() => _segment = _BuyerSegment.referral),
                  ),
                ],
                if (repeatSellPrompts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _RepeatSellPromptCard(
                    prompts: repeatSellPrompts,
                    onUseBuyer: (buyerPhone) async {
                      final match = buyers.firstWhere(
                        (buyer) => buyer.phone == buyerPhone,
                        orElse: () => buyers.first,
                      );
                      await _useForNextOrder(match);
                    },
                    onFindProduct: _openRepeatSearch,
                  ),
                ],
                if (_repeatSellReminders.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ReminderQueueCard(
                    reminders: _repeatSellReminders,
                    onFindProduct: _openRepeatSearch,
                    onUseBuyer: (buyerPhone) async {
                      final match = buyers.firstWhere(
                        (buyer) => buyer.phone == buyerPhone,
                        orElse: () => buyers.first,
                      );
                      await _useForNextOrder(match);
                    },
                    onDismiss: _removeReminder,
                  ),
                ],
                if (neighborhoodClusters.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _NeighborhoodClusterCard(
                    clusters: neighborhoodClusters,
                    selectedDistrict: _selectedDistrict,
                    onFindProduct: _openNeighborhoodSearch,
                    onSelectDistrict: (district) {
                      setState(() {
                        _selectedDistrict = _selectedDistrict == district
                            ? null
                            : district;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Phone-based lookup',
                    hintText: 'Search by phone, name, zone, source, or product',
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedDistrict != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                        ),
                        label: Text('Area: $_selectedDistrict'),
                        onPressed: () {},
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.close, size: 16),
                        label: const Text('Clear'),
                        onPressed: () =>
                            setState(() => _selectedDistrict = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _BuyerSegmentChip(
                        label: 'All',
                        active: _segment == _BuyerSegment.all,
                        onTap: () =>
                            setState(() => _segment = _BuyerSegment.all),
                      ),
                      _BuyerSegmentChip(
                        label: 'Repeat',
                        active: _segment == _BuyerSegment.repeat,
                        onTap: () =>
                            setState(() => _segment = _BuyerSegment.repeat),
                      ),
                      _BuyerSegmentChip(
                        label: 'Referral',
                        active: _segment == _BuyerSegment.referral,
                        onTap: () =>
                            setState(() => _segment = _BuyerSegment.referral),
                      ),
                      _BuyerSegmentChip(
                        label: 'Pending',
                        active: _segment == _BuyerSegment.pending,
                        onTap: () =>
                            setState(() => _segment = _BuyerSegment.pending),
                      ),
                      _BuyerSegmentChip(
                        label: 'Risky',
                        active: _segment == _BuyerSegment.risky,
                        onTap: () =>
                            setState(() => _segment = _BuyerSegment.risky),
                      ),
                      _BuyerSegmentChip(
                        label: 'Blocked',
                        active: _segment == _BuyerSegment.blocked,
                        onTap: () =>
                            setState(() => _segment = _BuyerSegment.blocked),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Buyer records',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 12),
                if (filteredBuyers.isEmpty)
                  const _BuyerBookEmptyState(
                    icon: HugeIcons.strokeRoundedUserSearch01,
                    title: 'No matching buyers',
                    subtitle:
                        'Try a phone number, district, or product name to find a saved buyer.',
                  )
                else
                  ...filteredBuyers.map(
                    (buyer) => _BuyerCard(
                      buyer: buyer,
                      onEdit: () => _editBuyer(buyer),
                      onReset: () => _resetBuyerMeta(buyer),
                      onFindProduct: buyer.preferredProducts.isEmpty
                          ? null
                          : () => _openRepeatSearch(
                              buyer.preferredProducts.first,
                            ),
                      onUseForNextOrder: () => _useForNextOrder(buyer),
                      onRemindTomorrow: () =>
                          _scheduleReminder(buyer, daysFromNow: 1),
                      onRemindInThreeDays: () =>
                          _scheduleReminder(buyer, daysFromNow: 3),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

bool _isBuyerBookPlaceholderProduct(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ||
      normalized == 'follow-up product' ||
      normalized == 'repeat-sell follow-up' ||
      normalized == 'pick product';
}

class _BuyerCard extends StatelessWidget {
  const _BuyerCard({
    required this.buyer,
    required this.onEdit,
    required this.onReset,
    required this.onFindProduct,
    required this.onUseForNextOrder,
    required this.onRemindTomorrow,
    required this.onRemindInThreeDays,
  });

  final BuyerBookProfile buyer;
  final VoidCallback onEdit;
  final VoidCallback onReset;
  final VoidCallback? onFindProduct;
  final Future<void> Function() onUseForNextOrder;
  final Future<void> Function() onRemindTomorrow;
  final Future<void> Function() onRemindInThreeDays;

  String _profileTruthLabel() {
    final updatedAt = buyer.profileMetaUpdatedAt;
    if (updatedAt == null) return 'Order history only';
    final days = DateTime.now().difference(updatedAt).inDays;
    if (days <= 0) return 'Reviewed today';
    if (days <= 7) return 'Reviewed this week';
    return 'Needs review';
  }

  String _buyerRiskLabel() {
    if (buyer.isBlocked) return 'Buyer blocked';
    if (buyer.isRisky || buyer.hasPendingBuyerRisk) return 'Buyer needs review';
    return 'Buyer approved';
  }

  _TagTone _buyerRiskTone() {
    if (buyer.isBlocked) return _TagTone.alert;
    if (buyer.isRisky || buyer.hasPendingBuyerRisk) return _TagTone.warning;
    return _TagTone.good;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const AppHugeIcon(
                  HugeIcons.strokeRoundedUser,
                  size: 18,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyer.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColor.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      buyer.phone.isEmpty ? 'No phone' : buyer.phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _BuyerStatusPill(buyer: buyer),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(label: buyer.sourceTag),
              _TagPill(
                label: buyer.hasProfileMeta
                    ? _profileTruthLabel()
                    : 'Order history only',
                tone: buyer.hasProfileMeta ? _TagTone.good : _TagTone.neutral,
              ),
              _TagPill(label: _buyerRiskLabel(), tone: _buyerRiskTone()),
              if (buyer.hasPendingBuyerRisk)
                const _TagPill(
                  label: 'Pending / unpaid',
                  tone: _TagTone.warning,
                ),
              if (buyer.isRepeatBuyer)
                const _TagPill(label: 'Repeat buyer', tone: _TagTone.good),
              if (buyer.deliveryZone.isNotEmpty)
                _TagPill(label: buyer.deliveryZone),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                label: 'Last order',
                value: _lastOrderLabel(buyer.lastOrderedAt),
              ),
              _SummaryPill(label: 'Record', value: _profileTruthLabel()),
              _SummaryPill(
                label: 'Pending cash',
                value: buyer.unpaidOrders > 0
                    ? '${buyer.unpaidOrders}'
                    : 'Clear',
              ),
              _SummaryPill(label: 'Risk', value: _buyerRiskLabel()),
              _SummaryPill(
                label: 'Sell again',
                value: buyer.preferredProducts.isNotEmpty
                    ? buyer.preferredProducts.first
                    : buyer.isRepeatBuyer
                    ? 'Ready'
                    : 'Build history',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Primary address', value: buyer.primaryAddress),
          _InfoRow(label: 'District', value: buyer.district),
          if (buyer.note.trim().isNotEmpty)
            _InfoRow(label: 'Note', value: buyer.note.trim()),
          if (buyer.preferredProducts.isNotEmpty)
            _InfoRow(
              label: 'Preferred products',
              value: buyer.preferredProducts.join(', '),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(label: 'Orders', value: '${buyer.totalOrders}'),
              _SummaryPill(
                label: 'Delivered',
                value: '${buyer.totalDelivered}',
              ),
              _SummaryPill(
                label: 'Return rate',
                value: '${buyer.returnRate.toStringAsFixed(0)}%',
              ),
              _SummaryPill(
                label: 'Avg basket',
                value: _currency(buyer.averageBasketSize),
              ),
              _SummaryPill(
                label: 'Addresses',
                value: '${buyer.addresses.length}',
              ),
              _SummaryPill(
                label: 'Top products',
                value: '${buyer.preferredProducts.length}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text(
              'Buyer record',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${_profileTruthLabel()} • Last ordered ${formatDateTime(buyer.lastOrderedAt)}',
              style: const TextStyle(
                color: AppColor.neutral2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              const SizedBox(height: 8),
              if (buyer.addresses.isNotEmpty) ...[
                Text(
                  'Saved addresses',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: buyer.addresses
                      .map(
                        (address) => _AddressChip(
                          label: address,
                          isPrimary: address == buyer.primaryAddress,
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 10),
              ],
              if (buyer.preferredProducts.isNotEmpty)
                _InfoRow(
                  label: 'Last successful products',
                  value: buyer.preferredProducts.take(3).join(', '),
                ),
              _InfoRow(
                label: 'Total sales',
                value: _currency(buyer.totalSales),
              ),
              _InfoRow(
                label: 'Pending orders',
                value: '${buyer.pendingOrders}',
              ),
              _InfoRow(label: 'Unpaid orders', value: '${buyer.unpaidOrders}'),
              if ((buyer.lastOrderId ?? '').isNotEmpty)
                _InfoRow(label: 'Last order', value: buyer.lastOrderId!),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedUserEdit01,
                    size: 16,
                  ),
                  label: const Text('Edit local record'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onFindProduct != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFindProduct,
                    icon: const AppHugeIcon(
                      HugeIcons.strokeRoundedSearch01,
                      size: 16,
                    ),
                    label: const Text('Find product'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await onUseForNextOrder();
                    if (!context.mounted) return;
                    CustomToast.info(
                      buyer.preferredProducts.isEmpty
                          ? 'Buyer ready. Open a product to start order.'
                          : 'Buyer ready. Start with ${buyer.preferredProducts.first}.',
                    );
                  },
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedReload,
                    size: 16,
                  ),
                  label: const Text('Start reorder'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onUseForNextOrder,
              icon: const AppHugeIcon(
                HugeIcons.strokeRoundedUserCheck01,
                size: 16,
                color: Colors.white,
              ),
              label: const Text('Start order'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemindTomorrow,
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedNotification03,
                    size: 16,
                  ),
                  label: const Text('Remind tomorrow'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemindInThreeDays,
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedCalendar03,
                    size: 16,
                  ),
                  label: const Text('Remind +3d'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const AppHugeIcon(
                HugeIcons.strokeRoundedDelete02,
                size: 16,
              ),
              label: const Text('Reset local record'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyerBookOverviewCard extends StatelessWidget {
  const _BuyerBookOverviewCard({
    required this.totalBuyers,
    required this.repeatBuyers,
    required this.referralBuyers,
    required this.riskyBuyers,
    required this.pendingCashBuyers,
    required this.readyToResell,
    required this.blockedBuyers,
  });

  final int totalBuyers;
  final int repeatBuyers;
  final int referralBuyers;
  final int riskyBuyers;
  final int pendingCashBuyers;
  final int readyToResell;
  final int blockedBuyers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buyer record snapshot',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start from repeat buyers, then clear risky COD and unpaid buyer records early.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(label: 'Buyers', value: '$totalBuyers'),
              _SummaryPill(label: 'Repeat', value: '$repeatBuyers'),
              _SummaryPill(label: 'Referral', value: '$referralBuyers'),
              _SummaryPill(label: 'At risk', value: '$riskyBuyers'),
              _SummaryPill(label: 'Pending cash', value: '$pendingCashBuyers'),
              _SummaryPill(label: 'Ready again', value: '$readyToResell'),
              _SummaryPill(label: 'Blocked', value: '$blockedBuyers'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepeatSellPrompt {
  const _RepeatSellPrompt({
    required this.buyerName,
    required this.buyerPhone,
    required this.productTitle,
    required this.reason,
    required this.lastOrderLabel,
    required this.district,
    required this.averageBasketSize,
  });

  final String buyerName;
  final String buyerPhone;
  final String productTitle;
  final String reason;
  final String lastOrderLabel;
  final String district;
  final double averageBasketSize;
}

class _ReferralPrompt {
  const _ReferralPrompt({
    required this.buyerName,
    required this.buyerPhone,
    required this.district,
    required this.leadProduct,
    required this.totalOrders,
    required this.averageBasketSize,
  });

  final String buyerName;
  final String buyerPhone;
  final String district;
  final String leadProduct;
  final int totalOrders;
  final double averageBasketSize;
}

class _ReferralLoopCard extends StatelessWidget {
  const _ReferralLoopCard({
    required this.prompts,
    required this.onUseBuyer,
    required this.onFindProduct,
    required this.onFocusReferral,
  });

  final List<_ReferralPrompt> prompts;
  final Future<void> Function(String buyerPhone) onUseBuyer;
  final void Function(String productTitle) onFindProduct;
  final VoidCallback onFocusReferral;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Referral loop',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onFocusReferral,
                child: const Text('Focus'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...prompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.safe),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isBuyerBookPlaceholderProduct(prompt.leadProduct)
                                ? prompt.buyerName
                                : '${prompt.buyerName} • ${prompt.leadProduct}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColor.text,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if (!_isBuyerBookPlaceholderProduct(prompt.leadProduct))
                          TextButton(
                            onPressed: () => onFindProduct(prompt.leadProduct),
                            child: const Text('Find product'),
                          ),
                        TextButton(
                          onPressed: () async => onUseBuyer(prompt.buyerPhone),
                          child: const Text('Start order'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SummaryPill(label: 'District', value: prompt.district),
                        _SummaryPill(
                          label: 'Orders',
                          value: '${prompt.totalOrders}',
                        ),
                        _SummaryPill(
                          label: 'Avg basket',
                          value: _currency(prompt.averageBasketSize),
                        ),
                      ],
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

class _RepeatSellPromptCard extends StatelessWidget {
  const _RepeatSellPromptCard({
    required this.prompts,
    required this.onUseBuyer,
    required this.onFindProduct,
  });

  final List<_RepeatSellPrompt> prompts;
  final Future<void> Function(String buyerPhone) onUseBuyer;
  final void Function(String productTitle) onFindProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat-sell prompts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start here when you want the fastest follow-up sale from Buyer Book.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...prompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.safe),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${prompt.buyerName} • ${prompt.productTitle}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColor.text,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => onFindProduct(prompt.productTitle),
                          child: const Text('Find product'),
                        ),
                        TextButton(
                          onPressed: () async => onUseBuyer(prompt.buyerPhone),
                          child: const Text('Start order'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt.reason,
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
                        _SummaryPill(
                          label: 'Last order',
                          value: prompt.lastOrderLabel,
                        ),
                        _SummaryPill(label: 'District', value: prompt.district),
                        _SummaryPill(
                          label: 'Avg basket',
                          value: _currency(prompt.averageBasketSize),
                        ),
                      ],
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

class _NeighborhoodCluster {
  const _NeighborhoodCluster({
    required this.district,
    required this.buyerCount,
    required this.repeatCount,
    required this.riskyCount,
    required this.topProduct,
  });

  final String district;
  final int buyerCount;
  final int repeatCount;
  final int riskyCount;
  final String topProduct;
}

class _NeighborhoodClusterCard extends StatelessWidget {
  const _NeighborhoodClusterCard({
    required this.clusters,
    required this.selectedDistrict,
    required this.onFindProduct,
    required this.onSelectDistrict,
  });

  final List<_NeighborhoodCluster> clusters;
  final String? selectedDistrict;
  final void Function(String productTitle) onFindProduct;
  final ValueChanged<String> onSelectDistrict;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Neighborhood selling clusters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 12),
          ...clusters.map(
            (cluster) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onSelectDistrict(cluster.district),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedDistrict == cluster.district
                        ? AppColor.primarySoft
                        : AppColor.safe1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cluster.district,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColor.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (cluster.topProduct.trim().isNotEmpty &&
                          cluster.topProduct.trim().toLowerCase() !=
                              'build local history') ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => onFindProduct(cluster.topProduct),
                            child: const Text('Find top product'),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SummaryPill(
                            label: 'Buyers',
                            value: '${cluster.buyerCount}',
                          ),
                          _SummaryPill(
                            label: 'Repeat',
                            value: '${cluster.repeatCount}',
                          ),
                          _SummaryPill(
                            label: 'Risky',
                            value: '${cluster.riskyCount}',
                          ),
                          _SummaryPill(
                            label: 'Top product',
                            value: cluster.topProduct,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderQueueCard extends StatelessWidget {
  const _ReminderQueueCard({
    required this.reminders,
    required this.onFindProduct,
    required this.onUseBuyer,
    required this.onDismiss,
  });

  final List<RepeatSellReminder> reminders;
  final void Function(String productTitle) onFindProduct;
  final Future<void> Function(String buyerPhone) onUseBuyer;
  final Future<void> Function(String id) onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat reminder queue',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'These are your next buyer follow-ups. Reopen the buyer, then share or start order.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...reminders
              .take(4)
              .map(
                (reminder) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: reminder.isDue
                          ? AppColor.primarySoft
                          : AppColor.safe1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColor.safe),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isBuyerBookPlaceholderProduct(
                                      reminder.productTitle,
                                    )
                                    ? reminder.buyerName
                                    : '${reminder.buyerName} • ${reminder.productTitle}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColor.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            if (!_isBuyerBookPlaceholderProduct(
                              reminder.productTitle,
                            ))
                              TextButton(
                                onPressed: () =>
                                    onFindProduct(reminder.productTitle),
                                child: const Text('Find product'),
                              ),
                            TextButton(
                              onPressed: () async =>
                                  onUseBuyer(reminder.buyerPhone),
                              child: const Text('Start order'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SummaryPill(
                              label: 'When',
                              value: reminder.scheduledFor == null
                                  ? 'Open'
                                  : formatDateTime(reminder.scheduledFor),
                            ),
                            _SummaryPill(
                              label: 'District',
                              value: reminder.district,
                            ),
                            _SummaryPill(
                              label: 'Status',
                              value: reminder.isDue ? 'Due now' : 'Planned',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async => onDismiss(reminder.id),
                          icon: const AppHugeIcon(
                            HugeIcons.strokeRoundedDelete02,
                            size: 16,
                          ),
                          label: const Text('Dismiss reminder'),
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

String _lastOrderLabel(DateTime? lastOrderedAt) {
  if (lastOrderedAt == null) return 'No orders';
  final days = DateTime.now().difference(lastOrderedAt).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return '1 day ago';
  if (days < 30) return '$days days ago';
  return formatDateTime(lastOrderedAt);
}

class _BuyerStatusPill extends StatelessWidget {
  const _BuyerStatusPill({required this.buyer});

  final BuyerBookProfile buyer;

  @override
  Widget build(BuildContext context) {
    final color = buyer.isBlocked
        ? AppColor.alert
        : buyer.isRisky
        ? AppColor.warning
        : AppColor.primary;
    final background = buyer.isBlocked
        ? AppColor.alertLight
        : buyer.isRisky
        ? AppColor.warningLight
        : AppColor.safe1;
    final label = buyer.isBlocked
        ? 'Blocked'
        : buyer.isRisky
        ? 'Watch buyer'
        : 'Stable';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum _TagTone { neutral, good, warning, alert }

enum _BuyerSegment { all, repeat, referral, pending, risky, blocked }

class _BuyerSegmentChip extends StatelessWidget {
  const _BuyerSegmentChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColor.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? AppColor.primary : AppColor.safe,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? AppColor.primary : AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, this.tone = _TagTone.neutral});

  final String label;
  final _TagTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _TagTone.neutral => AppColor.primary,
      _TagTone.good => AppColor.green,
      _TagTone.warning => AppColor.warning,
      _TagTone.alert => AppColor.alert,
    };
    final background = switch (tone) {
      _TagTone.neutral => AppColor.safe1,
      _TagTone.good => AppColor.safe1,
      _TagTone.warning => AppColor.warningLight,
      _TagTone.alert => AppColor.alertLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColor.neutral2,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColor.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _AddressChip extends StatelessWidget {
  const _AddressChip({required this.label, required this.isPrimary});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? AppColor.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPrimary ? AppColor.primary : AppColor.safe),
      ),
      child: Text(
        isPrimary ? 'Primary: $label' : label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isPrimary ? AppColor.primary : AppColor.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BuyerBookEmptyState extends StatelessWidget {
  const _BuyerBookEmptyState({
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        children: [
          AppHugeIcon(icon, size: 28, color: AppColor.primary),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColor.neutral2),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColor.neutral2),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: const TextStyle(
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

String _currency(double amount) => '৳${amount.toStringAsFixed(0)}';
