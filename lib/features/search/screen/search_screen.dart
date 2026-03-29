import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/config/app_environment.dart';
import 'package:sellhub/core/config/id_encoder.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
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

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    // Listen to controller changes to update the UI (specifically the Clear icon)
    _controller.addListener(() {
      setState(() {});
    });
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
        title: 'Search',
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
            _SearchContextHero(
              hasQuery: hasQuery,
              query: query,
              recentCount: _recentSearches.length,
            ),
            if (hasQuery)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _ContextChip(
                            icon: HugeIcons.strokeRoundedStore01,
                            label: 'Current store',
                          ),
                          _ContextChip(
                            icon: HugeIcons.strokeRoundedSearchArea,
                            label: 'Live match',
                          ),
                        ],
                      ),
                    ),
                    TextButton(
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
                      child: const Text('Search'),
                    ),
                  ],
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
                      return const _SearchEmptyState(
                        icon: HugeIcons.strokeRoundedSearch01,
                        title: 'Type something to search',
                        subtitle:
                            'Search products across the current store catalog.',
                      );
                    }
                    return ListView(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ContextChip(
                                icon: HugeIcons.strokeRoundedStore01,
                                label: 'Current store',
                              ),
                              _ContextChip(
                                icon: HugeIcons.strokeRoundedStars,
                                label: 'Recent picks',
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent searches',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColor.neutral2,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pick up where you left off',
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
                  return ListView.separated(
                    itemCount: state.products.length + 1,
                    separatorBuilder: (_, index) => SizedBox(
                      height: index == 0 ? 12 : 10,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
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
                              child: const AppHugeIcon(
                                HugeIcons.strokeRoundedSearch01,
                                size: 18,
                                color: AppColor.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick results',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColor.neutral2,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${state.products.length} instant matches',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColor.text,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      final item = state.products[index - 1];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: InkWell(
                          onTap: () {
                            final product = SearchToProductMapper.toProduct(item);
                            final hid = encodeId(item.id);
                            Navigator.of(context).push(
                              ProductDetailsScreen.route(
                                hid: hid,
                                product: product,
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
                                          Text(
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
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColor.safe1,
                                              borderRadius: BorderRadius.circular(
                                                999,
                                              ),
                                            ),
                                            child: Text(
                                              'Quick match',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColor.primary,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                        ],
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

class _SearchContextHero extends StatelessWidget {
  const _SearchContextHero({
    required this.hasQuery,
    required this.query,
    required this.recentCount,
  });

  final bool hasQuery;
  final String query;
  final int recentCount;

  @override
  Widget build(BuildContext context) {
    final title = hasQuery ? query : 'Search the catalog';
    final subtitle = hasQuery
        ? 'Live results across products, brands, and categories'
        : 'Fast lookup with recent searches and instant matches';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.safe),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedSearchVisual,
              size: 20,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasQuery ? 'Searching now' : 'Discover faster',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.safe),
            ),
            child: Column(
              children: [
                Text(
                  '$recentCount',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Recent',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
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

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.icon,
    required this.label,
  });

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppHugeIcon(icon, size: 14, color: AppColor.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
          hintText: 'Search store, brand, category, product',
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
