import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/config/app_environment.dart';
import 'package:sellhub/core/config/id_encoder.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/product_viability/product_viability_widgets.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/utils/debouncer.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/search_widget.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/product/screens/product_details_screen.dart';
import 'package:sellhub/features/search/data/models/search_to_product_mapper.dart';
import 'package:sellhub/features/search/presentation/cubit/search_cubit.dart';
import 'package:sellhub/features/search/presentation/cubit/search_state.dart';
import 'package:sellhub/features/search/screen/search_button_click_result.dart';

enum _SearchDiscoveryMode {
  all,
  whatsapp,
  facebook,
  cod,
  lowRisk,
  goodMargin,
  repeat,
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.initialMode,
    this.initialQuery,
  });

  final String? initialMode;
  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _debouncer = Debouncer(milliseconds: 500);
  static const String _recentSearchKey = 'sellhub_recent_search_v1';
  List<String> _recentSearches = const <String>[];
  int? _lastSiteId;
  _SearchDiscoveryMode _discoveryMode = _SearchDiscoveryMode.all;

  @override
  void initState() {
    super.initState();
    _discoveryMode = _modeFromValue(widget.initialMode);
    final initialQuery = (widget.initialQuery ?? '').trim();
    if (initialQuery.isNotEmpty) {
      _controller.text = initialQuery;
    }
    _loadRecentSearches();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        if (initialQuery.isNotEmpty) {
          final activeSiteId =
              context.read<StoreContextCubit>().state.activeStore?.siteId ??
              AppConstants.kDefaultSiteId;
          context.read<SearchCubit>().search(
            initialQuery,
            siteId: activeSiteId,
          );
        }
      }
    });
    // Listen to controller changes to update the UI (specifically the Clear icon)
    _controller.addListener(() {
      setState(() {});
    });
  }

  _SearchDiscoveryMode _modeFromValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'whatsapp':
        return _SearchDiscoveryMode.whatsapp;
      case 'facebook':
        return _SearchDiscoveryMode.facebook;
      case 'cod':
        return _SearchDiscoveryMode.cod;
      case 'lowrisk':
      case 'low-risk':
        return _SearchDiscoveryMode.lowRisk;
      case 'goodmargin':
      case 'good-margin':
        return _SearchDiscoveryMode.goodMargin;
      case 'repeat':
        return _SearchDiscoveryMode.repeat;
      default:
        return _SearchDiscoveryMode.all;
    }
  }

  Future<void> _loadRecentSearches() async {
    final recent = await LocalStorage.getStringList(_recentSearchKey);
    if (!mounted) return;
    setState(() {
      _recentSearches = recent;
    });
  }

  Future<void> _pushRecentSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    final updated = <String>[
      normalized,
      ..._recentSearches.where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(8).toList(growable: false);
    await LocalStorage.saveStringList(_recentSearchKey, updated);
    if (!mounted) return;
    setState(() {
      _recentSearches = updated;
    });
  }

  // Always dispose to avoid memory leaks
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSiteId =
        context.read<StoreContextCubit>().state.activeStore?.siteId ??
        AppConstants.kDefaultSiteId;
    if (_lastSiteId != activeSiteId) {
      _lastSiteId = activeSiteId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SearchCubit>().ensureSite(activeSiteId);
        if (_controller.text.trim().isNotEmpty) {
          context.read<SearchCubit>().search(
            _controller.text.trim(),
            siteId: activeSiteId,
          );
        }
      });
    }
    final query = _controller.text.trim();
    final hasQuery = query.isNotEmpty;
    return Scaffold(
      appBar: SellHubTopAppBar(
        title: 'Find products to sell',
        icon: HugeIcons.strokeRoundedSearch01,
        showBackButton: true,
        actions: [
          if (_recentSearches.isNotEmpty)
            TextButton(
              onPressed: () async {
                await LocalStorage.saveStringList(_recentSearchKey, const []);
                if (!mounted) return;
                setState(() {
                  _recentSearches = const <String>[];
                });
              },
              child: const Text('Clear'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Hero(
              tag: SearchWidget.heroTag,
              child: Material(
                color: Colors.transparent,
                child: _HealthSearchFieldBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  query: query,
                  onChanged: (value) {
                    _debouncer.run(() {
                      if (mounted) {
                        context.read<SearchCubit>().search(
                          value,
                          siteId: activeSiteId,
                        );
                      }
                    });
                  },
                  onClear: () {
                    _controller.clear();
                    _debouncer.run(() {});
                    context.read<SearchCubit>().search(
                      '',
                      siteId: activeSiteId,
                    );
                    setState(() {});
                    _focusNode.requestFocus();
                  },
                  onSubmit: (value) {
                    context.read<SearchCubit>().search(
                      value,
                      siteId: activeSiteId,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            const SizedBox(height: 4),
            _SearchStartCard(mode: _discoveryMode),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SearchShortcutChip(
                      label: 'WhatsApp winners',
                      onTap: () => _runShortcutSearch(
                        query: 'bundle',
                        siteId: activeSiteId,
                        mode: _SearchDiscoveryMode.whatsapp,
                      ),
                    ),
                    _SearchShortcutChip(
                      label: 'Low-risk COD',
                      onTap: () => _runShortcutSearch(
                        query: 'home',
                        siteId: activeSiteId,
                        mode: _SearchDiscoveryMode.cod,
                      ),
                    ),
                    _SearchShortcutChip(
                      label: 'Repeat buyers',
                      onTap: () => _runShortcutSearch(
                        query: 'beauty',
                        siteId: activeSiteId,
                        mode: _SearchDiscoveryMode.repeat,
                      ),
                    ),
                    _SearchShortcutChip(
                      label: 'Facebook winners',
                      onTap: () => _runShortcutSearch(
                        query: 'fashion',
                        siteId: activeSiteId,
                        mode: _SearchDiscoveryMode.facebook,
                      ),
                    ),
                    _SearchShortcutChip(
                      label: 'Margin starters',
                      onTap: () => _runShortcutSearch(
                        query: 'gift',
                        siteId: activeSiteId,
                        mode: _SearchDiscoveryMode.goodMargin,
                      ),
                    ),
                    _SearchShortcutChip(
                      label: 'Low-return lanes',
                      onTap: () => _runShortcutSearch(
                        query: 'daily',
                        siteId: activeSiteId,
                        mode: _SearchDiscoveryMode.lowRisk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (hasQuery)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _pushRecentSearch(query);
                      context.read<SearchCubit>().searchProductsByButtonClick(
                        query,
                        activeSiteId,
                        AppConstants.kDefaultFirst,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SearchButtonClickResult(
                            query: query,
                            siteId: activeSiteId,
                          ),
                        ),
                      );
                    },
                    child: const Text('Full results'),
                  ),
                ),
              ),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_controller.text.isEmpty) {
                    if (_recentSearches.isEmpty) {
                      return _SearchEmptyState(
                        icon: HugeIcons.strokeRoundedSearch01,
                        title: 'Start with a reseller shortcut',
                        subtitle: _modeHintLabel,
                      );
                    }
                    return ListView(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent searches',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _recentSearches
                                  .map(
                                    (item) => ActionChip(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: AppColor.safe),
                                      avatar: const AppHugeIcon(
                                        HugeIcons.strokeRoundedSearch01,
                                        size: 14,
                                        color: AppColor.neutral2,
                                      ),
                                      label: Text(
                                        item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () {
                                        _controller.text = item;
                                        context.read<SearchCubit>().search(
                                          item,
                                          siteId: activeSiteId,
                                        );
                                        setState(() {});
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  if (state.error != null) {
                    return _SearchEmptyState(
                      icon: HugeIcons.strokeRoundedAlertCircle,
                      title: state.error!.title,
                      subtitle: 'Check your connection and try again.',
                    );
                  }
                  if (state.products.isEmpty) {
                    return const _SearchEmptyState(
                      icon: HugeIcons.strokeRoundedPackageSearch01,
                      title: 'No quick matches',
                      subtitle: 'Try a different keyword or use full search.',
                    );
                  }
                  final filteredProducts = _filterQuickMatches(state.products);
                  if (filteredProducts.isEmpty) {
                    return const _SearchEmptyState(
                      icon: HugeIcons.strokeRoundedFilterVertical,
                      title: 'No matches for this lens',
                      subtitle: 'Try another reseller focus like margin, repeat, or low risk.',
                    );
                  }
                  return ListView.separated(
                    itemCount: filteredProducts.length + 1,
                    separatorBuilder: (_, index) => SizedBox(
                      height: index == 0 ? 12 : 10,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${filteredProducts.length} matches',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.text,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            _SearchDiscoveryModeStrip(
                              current: _discoveryMode,
                              onChanged: (mode) {
                                setState(() {
                                  _discoveryMode = mode;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            _SearchContextHint(
                              label: _modeHintLabel,
                              icon: _modeHintIcon,
                            ),
                          ],
                        );
                      }
                      final item = filteredProducts[index - 1];
                      final mappedProduct = SearchToProductMapper.toProduct(item);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: InkWell(
                          onTap: () {
                            final hid = encodeId(item.id);
                            Navigator.of(context).push(
                              ProductDetailsScreen.route(
                                hid: hid,
                                product: mappedProduct,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColor.safe),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColor.safe1,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AppNetworkImage(
                                      imageUrl:
                                          '${AppEnvironment.mediaBaseUrl}${item.thumbnail}',
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      backgroundColor: AppColor.safe1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColor.text,
                                              height: 1.25,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '৳ ${convertToBengaliNumber(item.price.toInt())}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    color: AppColor.text,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _SearchCuePill(
                                            label: _productCueLabel(mappedProduct),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ProductViabilityCompactBlock(
                                        product: mappedProduct,
                                        maxLabels: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColor.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const AppHugeIcon(
                                    HugeIcons.strokeRoundedArrowRight02,
                                    size: 14,
                                    color: AppColor.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _runShortcutSearch({
    required String query,
    required int siteId,
    _SearchDiscoveryMode? mode,
  }) {
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    if (mode != null) {
      setState(() {
        _discoveryMode = mode;
      });
    }
    context.read<SearchCubit>().search(query, siteId: siteId);
  }

  List<dynamic> _filterQuickMatches(List<dynamic> items) {
    return items.where((item) {
      final product = SearchToProductMapper.toProduct(item);
      final viability = ProductViabilityEngine.build(product);
      switch (_discoveryMode) {
        case _SearchDiscoveryMode.all:
          return true;
        case _SearchDiscoveryMode.whatsapp:
          return !product.isOutOfStock &&
              _hasLabel(viability, 'Good margin') &&
              viability.shareabilityScore >= 68;
        case _SearchDiscoveryMode.facebook:
          return !product.isOutOfStock &&
              (_hasLabel(viability, 'High repeat potential') ||
                  viability.demandScore >= 72);
        case _SearchDiscoveryMode.cod:
          return !product.isOutOfStock &&
              (product.price ?? 0) <= 2500 &&
              _isLowRisk(viability);
        case _SearchDiscoveryMode.lowRisk:
          return !product.isOutOfStock && _isLowRisk(viability);
        case _SearchDiscoveryMode.goodMargin:
          return _hasLabel(viability, 'Good margin') ||
              viability.maxMargin >= 150;
        case _SearchDiscoveryMode.repeat:
          return _hasLabel(viability, 'High repeat potential') ||
              viability.shareabilityScore >= 74;
      }
    }).toList(growable: false);
  }

  String get _modeHintLabel {
    switch (_discoveryMode) {
      case _SearchDiscoveryMode.whatsapp:
        return 'Quick replies and faster close';
      case _SearchDiscoveryMode.facebook:
        return 'Post-friendly picks for comment leads';
      case _SearchDiscoveryMode.cod:
        return 'Safer price band for COD buyers';
      case _SearchDiscoveryMode.lowRisk:
        return 'Lower fulfilment pressure picks';
      case _SearchDiscoveryMode.goodMargin:
        return 'Stronger spread before buyer negotiation';
      case _SearchDiscoveryMode.repeat:
        return 'Items easier to sell again nearby';
      case _SearchDiscoveryMode.all:
        return 'Compact reseller matches across active suppliers';
    }
  }

  List<List<dynamic>> get _modeHintIcon {
    switch (_discoveryMode) {
      case _SearchDiscoveryMode.whatsapp:
        return HugeIcons.strokeRoundedWhatsapp;
      case _SearchDiscoveryMode.facebook:
        return HugeIcons.strokeRoundedFacebook02;
      case _SearchDiscoveryMode.cod:
        return HugeIcons.strokeRoundedDeliveryTruck01;
      case _SearchDiscoveryMode.lowRisk:
        return HugeIcons.strokeRoundedShield01;
      case _SearchDiscoveryMode.goodMargin:
        return HugeIcons.strokeRoundedWallet02;
      case _SearchDiscoveryMode.repeat:
        return HugeIcons.strokeRoundedReload;
      case _SearchDiscoveryMode.all:
        return HugeIcons.strokeRoundedSparkles;
    }
  }

  String _productCueLabel(product) {
    final viability = ProductViabilityEngine.build(product);
    switch (_discoveryMode) {
      case _SearchDiscoveryMode.whatsapp:
        return 'WhatsApp';
      case _SearchDiscoveryMode.facebook:
        return 'Facebook';
      case _SearchDiscoveryMode.cod:
        return 'COD';
      case _SearchDiscoveryMode.lowRisk:
        return 'Low risk';
      case _SearchDiscoveryMode.goodMargin:
        return viability.maxMargin >= 180 ? 'High margin' : 'Margin';
      case _SearchDiscoveryMode.repeat:
        return 'Repeat';
      case _SearchDiscoveryMode.all:
        if (_hasLabel(viability, 'High repeat potential')) {
          return 'Repeat';
        }
        if (_hasLabel(viability, 'Good margin')) {
          return 'Margin';
        }
        if (_isLowRisk(viability)) {
          return 'Low risk';
        }
        return 'Fast match';
    }
  }

  bool _hasLabel(ProductViabilityProfile viability, String label) {
    return viability.labels.contains(label);
  }

  bool _isLowRisk(ProductViabilityProfile viability) {
    return viability.deliveryRisk != ViabilityRiskLevel.high &&
        viability.returnSensitivity != ViabilityRiskLevel.high;
  }
}

class _SearchShortcutChip extends StatelessWidget {
  const _SearchShortcutChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColor.safe),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColor.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _SearchStartCard extends StatelessWidget {
  const _SearchStartCard({required this.mode});

  final _SearchDiscoveryMode mode;

  String get _title {
    switch (mode) {
      case _SearchDiscoveryMode.whatsapp:
        return 'WhatsApp selling mode';
      case _SearchDiscoveryMode.facebook:
        return 'Facebook selling mode';
      case _SearchDiscoveryMode.cod:
        return 'COD-safe search';
      case _SearchDiscoveryMode.lowRisk:
        return 'Lower-risk search';
      case _SearchDiscoveryMode.goodMargin:
        return 'Margin-first search';
      case _SearchDiscoveryMode.repeat:
        return 'Repeat-sell search';
      case _SearchDiscoveryMode.all:
        return 'Find products to sell';
    }
  }

  String get _subtitle {
    switch (mode) {
      case _SearchDiscoveryMode.whatsapp:
        return 'Pull fast-close products you can reply with in chat.';
      case _SearchDiscoveryMode.facebook:
        return 'Prioritize products that look strong in posts and captions.';
      case _SearchDiscoveryMode.cod:
        return 'Keep delivery promise and return risk easier to manage.';
      case _SearchDiscoveryMode.lowRisk:
        return 'Safer fulfilment is better when the buyer is uncertain.';
      case _SearchDiscoveryMode.goodMargin:
        return 'Start from profit, then narrow to what your buyers will accept.';
      case _SearchDiscoveryMode.repeat:
        return 'Look for products that neighbours can reorder later.';
      case _SearchDiscoveryMode.all:
        return 'Search the multivendor catalog with a clear reseller lens.';
    }
  }

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
            _title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColor.safe),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            AppHugeIcon(icon, size: 36, color: AppColor.neutral2),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColor.neutral2,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchDiscoveryModeStrip extends StatelessWidget {
  const _SearchDiscoveryModeStrip({
    required this.current,
    required this.onChanged,
  });

  final _SearchDiscoveryMode current;
  final ValueChanged<_SearchDiscoveryMode> onChanged;

  static const List<(_SearchDiscoveryMode, String, List<List<dynamic>>)> _items = <
      (_SearchDiscoveryMode, String, List<List<dynamic>>)>[
    (_SearchDiscoveryMode.all, 'All', HugeIcons.strokeRoundedSparkles),
    (_SearchDiscoveryMode.whatsapp, 'WhatsApp', HugeIcons.strokeRoundedWhatsapp),
    (_SearchDiscoveryMode.facebook, 'Facebook', HugeIcons.strokeRoundedFacebook02),
    (_SearchDiscoveryMode.cod, 'COD', HugeIcons.strokeRoundedDeliveryTruck01),
    (_SearchDiscoveryMode.lowRisk, 'Low risk', HugeIcons.strokeRoundedShield01),
    (_SearchDiscoveryMode.goodMargin, 'Margin', HugeIcons.strokeRoundedWallet02),
    (_SearchDiscoveryMode.repeat, 'Repeat', HugeIcons.strokeRoundedReload),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onChanged(item.$1),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: current == item.$1
                          ? AppColor.primarySoft
                          : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: current == item.$1
                            ? AppColor.primary
                            : AppColor.safe,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppHugeIcon(
                          item.$3,
                          size: 13,
                          color: current == item.$1
                              ? AppColor.primary
                              : AppColor.neutral2,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: current == item.$1
                                    ? AppColor.primary
                                    : AppColor.text,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SearchContextHint extends StatelessWidget {
  const _SearchContextHint({
    required this.label,
    required this.icon,
  });

  final String label;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          AppHugeIcon(icon, size: 14, color: AppColor.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchCuePill extends StatelessWidget {
  const _SearchCuePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _HealthSearchFieldBar extends StatelessWidget {
  const _HealthSearchFieldBar({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focusNode.hasFocus ? AppColor.primarySoft : AppColor.safe,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmit,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search product, category, keyword',
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 8, right: 6),
            child: AppHugeIcon(
              HugeIcons.strokeRoundedSearch01,
              size: 16,
              color: AppColor.primary,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const AppHugeIcon(
                      HugeIcons.strokeRoundedCancel01,
                      size: 14,
                      color: AppColor.neutral2,
                    ),
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}
