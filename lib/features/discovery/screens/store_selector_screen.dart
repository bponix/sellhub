import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/local/recent_product.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/store/store_context_state.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/discovery/data/models/store_summary.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_cubit.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_state.dart';
import 'package:sellhub/features/discovery/presentation/cubit/store_discovery_cubit.dart';
import 'package:sellhub/features/discovery/presentation/cubit/store_discovery_state.dart';
import 'package:sellhub/features/discovery/presentation/store_activator.dart';

class StoreSelectorScreen extends StatefulWidget {
  const StoreSelectorScreen({super.key, this.returnTo, this.shellIndex});

  final String? returnTo;
  final int? shellIndex;

  @override
  State<StoreSelectorScreen> createState() => _StoreSelectorScreenState();
}

class _StoreSelectorScreenState extends State<StoreSelectorScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ActiveStore> _recentStores = const <ActiveStore>[];
  List<RecentProduct> _recentProducts = const <RecentProduct>[];

  @override
  void initState() {
    super.initState();
    final cubit = context.read<StoreDiscoveryCubit>();
    unawaited(_hydrateRecentStores());
    unawaited(cubit.loadFeatured());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(cubit.loadNearby());
    });
  }

  Future<void> _hydrateRecentStores() async {
    final stores = await LocalStorage.getRecentStores();
    final products = await LocalStorage.getRecentProducts();
    if (!mounted) return;
    setState(() {
      _recentStores = stores;
      _recentProducts = products;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Explore shops',
        icon: HugeIcons.strokeRoundedStore01,
        showBackButton: true,
      ),
      body: SafeArea(
        child: BlocBuilder<StoreContextCubit, StoreContextState>(
          builder: (context, storeContextState) {
            return BlocBuilder<StoreDiscoveryCubit, StoreDiscoveryState>(
              builder: (context, state) {
                final list = _controller.text.trim().isEmpty
                    ? state.featuredStores
                    : state.searchResults;
                final discoveryCubit = context.read<StoreDiscoveryCubit>();
                return BlocBuilder<FavouriteCubit, FavouriteState>(
                  builder: (context, favouriteState) {
                    final localPulse = _buildLocalPulse(
                      nearbyStores: state.nearbyStores,
                      favouriteState: favouriteState,
                    );
                    return RefreshIndicator(
                      onRefresh: () async {
                        await _hydrateRecentStores();
                        await discoveryCubit.loadFeatured();
                        await discoveryCubit.loadNearby();
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          if (_controller.text.trim().isEmpty &&
                              storeContextState.activeStore != null) ...[
                            _CurrentStoreCard(
                              store: storeContextState.activeStore!,
                              returnTo: widget.returnTo,
                              shellIndex: widget.shellIndex,
                            ),
                          ],
                          if (_controller.text.trim().isEmpty &&
                              _recentStores.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const _SectionTitle(
                              title: 'Recent stores',
                              subtitle: 'Tap to reopen',
                              icon: HugeIcons.strokeRoundedReload,
                            ),
                            const SizedBox(height: 10),
                            _RecentStoreRow(
                              stores: _recentStores,
                              onTap: _activateRecentStore,
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _controller,
                            onChanged: (value) {
                              setState(() {});
                              context.read<StoreDiscoveryCubit>().search(value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search shops',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(12),
                                child: AppHugeIcon(
                                  HugeIcons.strokeRoundedStore01,
                                  size: 20,
                                  color: AppColor.neutral2,
                                ),
                              ),
                              suffixIcon: _controller.text.isEmpty
                                  ? IconButton(
                                      onPressed: () =>
                                          AppRouter.goToStoreScanner(
                                            context,
                                            returnTo: widget.returnTo,
                                            shellIndex: widget.shellIndex,
                                          ),
                                      icon: const AppHugeIcon(
                                        HugeIcons.strokeRoundedQrCode,
                                        size: 20,
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() {});
                                        context
                                            .read<StoreDiscoveryCubit>()
                                            .search('');
                                      },
                                      icon: const AppHugeIcon(
                                        HugeIcons.strokeRoundedCancel01,
                                        size: 20,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_controller.text.trim().isEmpty) ...[
                            if (localPulse.nearbyRecentStores.isNotEmpty) ...[
                              const _SectionTitle(
                                title: 'Nearby again',
                                subtitle: 'Local stores you already opened',
                                icon: HugeIcons.strokeRoundedReload,
                              ),
                              const SizedBox(height: 10),
                              _RecentStoreRow(
                                stores: localPulse.nearbyRecentStores,
                                onTap: _activateRecentStore,
                              ),
                              const SizedBox(height: 18),
                            ],
                            const _SectionTitle(
                              title: 'Nearby stores',
                              subtitle: 'Closest verified stores',
                              icon: HugeIcons.strokeRoundedMapsLocation01,
                            ),
                            const SizedBox(height: 10),
                            _StoreList(
                              stores: state.nearbyStores,
                              loading: state.loadingNearby,
                              emptyLabel: 'No nearby stores found yet.',
                              onTap: _activate,
                              activityBySiteId: localPulse.activityBySiteId,
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle(
                              title: 'Explore shops',
                              subtitle: 'More stores',
                              icon: HugeIcons.strokeRoundedStore04,
                            ),
                          ] else ...[
                            const _SectionTitle(
                              title: 'Search results',
                              subtitle: 'Tap to open',
                              icon: HugeIcons.strokeRoundedSearch01,
                            ),
                          ],
                          const SizedBox(height: 10),
                          _StoreList(
                            stores: list,
                            loading: state.loadingFeatured || state.searching,
                            emptyLabel: _controller.text.trim().isEmpty
                                ? 'No stores available.'
                                : 'No stores matched that search.',
                            onTap: _activate,
                            activityBySiteId: localPulse.activityBySiteId,
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 16),
                            _InlineErrorCard(
                              message: state.error!.title,
                              onRetry: () async {
                                if (_controller.text.trim().isEmpty) {
                                  await discoveryCubit.loadFeatured();
                                  await discoveryCubit.loadNearby();
                                } else {
                                  discoveryCubit.search(
                                    _controller.text.trim(),
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _activate(StoreSummary store) async {
    if (!mounted) return;
    await StoreActivator.activate(
      context,
      store.toActiveStore(),
      returnTo: widget.returnTo,
      shellIndex: widget.shellIndex,
    );
    await _hydrateRecentStores();
  }

  Future<void> _activateRecentStore(ActiveStore store) async {
    if (!mounted) return;
    await StoreActivator.activate(
      context,
      store,
      returnTo: widget.returnTo,
      shellIndex: widget.shellIndex,
    );
    await _hydrateRecentStores();
  }

  _LocalPulseData _buildLocalPulse({
    required List<StoreSummary> nearbyStores,
    required FavouriteState favouriteState,
  }) {
    final nearbySiteIds = nearbyStores.map((item) => item.siteId).toSet();
    final nearbyRecentStores = _recentStores
        .where((item) => nearbySiteIds.contains(item.siteId))
        .toList(growable: false);
    final nearbyRecentProducts = _recentProducts
        .where((item) => nearbySiteIds.contains(item.siteId))
        .toList(growable: false);
    final nearbyFavouriteProducts = favouriteState.items
        .where((item) => nearbySiteIds.contains(item.siteId))
        .toList(growable: false);

    final activityBySiteId = <int, _StoreActivity>{};
    for (final store in nearbyStores) {
      final revisited = nearbyRecentStores.any(
        (item) => item.siteId == store.siteId,
      );
      final viewedProducts = nearbyRecentProducts
          .where((item) => item.siteId == store.siteId)
          .length;
      final favouriteCount = nearbyFavouriteProducts
          .where((item) => item.siteId == store.siteId)
          .length;
      activityBySiteId[store.siteId] = _StoreActivity(
        revisited: revisited,
        viewedProducts: viewedProducts,
        favouriteCount: favouriteCount,
      );
    }

    return _LocalPulseData(
      nearbyCount: nearbyStores.length,
      nearbyRecentStores: nearbyRecentStores,
      nearbyRecentProductCount: nearbyRecentProducts.length,
      nearbyFavouriteCount: nearbyFavouriteProducts.length,
      activityBySiteId: activityBySiteId,
    );
  }
}

class _LocalPulseData {
  const _LocalPulseData({
    required this.nearbyCount,
    required this.nearbyRecentStores,
    required this.nearbyRecentProductCount,
    required this.nearbyFavouriteCount,
    required this.activityBySiteId,
  });

  final int nearbyCount;
  final List<ActiveStore> nearbyRecentStores;
  final int nearbyRecentProductCount;
  final int nearbyFavouriteCount;
  final Map<int, _StoreActivity> activityBySiteId;

  String get densityLabel {
    if (nearbyCount >= 12) return 'High density';
    if (nearbyCount >= 6) return 'Growing cluster';
    if (nearbyCount >= 1) return 'Early local network';
    return 'No local cluster yet';
  }

  String get summaryCopy {
    if (nearbyCount <= 0) {
      return 'When more verified stores open nearby, this screen becomes a stronger local commerce map.';
    }
    return '$nearbyCount nearby verified stores, ${nearbyRecentStores.length} reopened shops, and $nearbyRecentProductCount viewed products already make this area easier to shop.';
  }
}

class _StoreActivity {
  const _StoreActivity({
    required this.revisited,
    required this.viewedProducts,
    required this.favouriteCount,
  });

  final bool revisited;
  final int viewedProducts;
  final int favouriteCount;
}

class _CurrentStoreCard extends StatelessWidget {
  const _CurrentStoreCard({
    required this.store,
    this.returnTo,
    this.shellIndex,
  });

  final ActiveStore store;
  final String? returnTo;
  final int? shellIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          _ActiveStoreAvatar(store: store, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current store',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (store.title?.trim().isNotEmpty ?? false)
                      ? store.title!.trim()
                      : store.domain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  store.domain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => AppRouter.goToStoreScanner(
              context,
              returnTo: returnTo,
              shellIndex: shellIndex,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppHugeIcon(HugeIcons.strokeRoundedQrCode, size: 16),
                SizedBox(width: 6),
                Text('Scan'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentStoreRow extends StatelessWidget {
  const _RecentStoreRow({required this.stores, required this.onTap});

  final List<ActiveStore> stores;
  final Future<void> Function(ActiveStore store) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final store = stores[index];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onTap(store),
            child: Container(
              width: 168,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColor.safe),
              ),
              child: Row(
                children: [
                  _ActiveStoreAvatar(store: store, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 68;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (store.title?.trim().isNotEmpty ?? false)
                                  ? store.title!.trim()
                                  : store.domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 13 : null,
                                    height: compact ? 1.15 : 1.2,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              store.domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColor.neutral2,
                                    fontSize: compact ? 11 : null,
                                    height: 1.15,
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.alertLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.alert.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const AppHugeIcon(
            HugeIcons.strokeRoundedAlertCircle,
            color: AppColor.alert,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColor.alert,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.icon = HugeIcons.strokeRoundedSquareArrowDataTransferHorizontal,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColor.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColor.neutral2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StoreList extends StatelessWidget {
  const _StoreList({
    required this.stores,
    required this.loading,
    required this.emptyLabel,
    required this.onTap,
    this.activityBySiteId = const <int, _StoreActivity>{},
  });

  final List<StoreSummary> stores;
  final bool loading;
  final String emptyLabel;
  final Future<void> Function(StoreSummary store) onTap;
  final Map<int, _StoreActivity> activityBySiteId;

  @override
  Widget build(BuildContext context) {
    if (loading && stores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (stores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColor.safe),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const AppHugeIcon(
                HugeIcons.strokeRoundedStore01,
                size: 18,
                color: AppColor.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                emptyLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: stores
          .map(
            (store) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => onTap(store),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: Row(
                    children: [
                      _StoreLogo(store: store),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              store.domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                const _MetaPill(
                                  label: 'Open store',
                                  color: AppColor.primary,
                                ),
                                if (activityBySiteId[store.siteId]?.revisited ??
                                    false)
                                  const _MetaPill(
                                    label: 'Visited before',
                                    color: AppColor.primary,
                                  ),
                                if ((activityBySiteId[store.siteId]
                                            ?.viewedProducts ??
                                        0) >
                                    0)
                                  _MetaPill(
                                    label:
                                        '${activityBySiteId[store.siteId]!.viewedProducts} viewed items',
                                    color: AppColor.neutral2,
                                  ),
                                if ((activityBySiteId[store.siteId]
                                            ?.favouriteCount ??
                                        0) >
                                    0)
                                  _MetaPill(
                                    label:
                                        '${activityBySiteId[store.siteId]!.favouriteCount} favourites',
                                    color: AppColor.neutral2,
                                  ),
                                if ((store.address?.trim().isNotEmpty ?? false))
                                  const _MetaPill(
                                    label: 'Address available',
                                    color: AppColor.neutral2,
                                  ),
                              ],
                            ),
                            if ((store.address?.trim().isNotEmpty ??
                                false)) ...[
                              const SizedBox(height: 6),
                              Text(
                                store.address!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColor.neutral2,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const AppHugeIcon(
                        HugeIcons.strokeRoundedArrowRight01,
                        size: 16,
                        color: AppColor.neutral2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StoreLogo extends StatelessWidget {
  const _StoreLogo({required this.store});

  final StoreSummary store;

  @override
  Widget build(BuildContext context) {
    final imageUrl = store.logoUrl?.trim().isNotEmpty == true
        ? store.logoUrl!.trim()
        : store.coverImage?.trim();
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? AppNetworkImage(
              imageUrl: imageUrl,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              backgroundColor: AppColor.safe1,
            )
          : _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final label = store.title.trim().isEmpty
        ? 'S'
        : store.title.trim()[0].toUpperCase();
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColor.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActiveStoreAvatar extends StatelessWidget {
  const _ActiveStoreAvatar({required this.store, required this.size});

  final ActiveStore store;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: (store.logoUrl?.trim().isNotEmpty ?? false)
          ? AppNetworkImage(
              imageUrl: store.logoUrl!.trim(),
              width: size,
              height: size,
              fit: BoxFit.cover,
              backgroundColor: AppColor.safe1,
            )
          : _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final title = (store.title?.trim().isNotEmpty ?? false)
        ? store.title!.trim()
        : store.domain;
    return Center(
      child: Text(
        title.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColor.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
