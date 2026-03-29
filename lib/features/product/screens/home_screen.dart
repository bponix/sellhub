import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/local/recent_product.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/app_skeleton.dart';
import 'package:sellhub/core/widget/carousal_slider.dart';
import 'package:sellhub/core/widget/search_widget.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:sellhub/features/categories/screen/sub_category_products_screen.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_cubit.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_state.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/screens/widget/allPartHomePage.dart';
import 'package:sellhub/features/product/screens/widget/product_list_view_horizontal.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _pagePadding = 16;
  static const double _sectionGap = 18;
  static const double _blockGap = 12;
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _flashSaleController = ScrollController();
  final ScrollController _newArrivalController = ScrollController();
  List<RecentProduct> _recentProducts = const <RecentProduct>[];

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_onScroll);
    _hydrateRecentProducts();
  }

  void _onScroll() {
    if (_mainScrollController.position.extentAfter < 200) {
      final storefront = context.read<StorefrontCubit>().state;
      final siteId = storefront.siteDetails?.id;
      if (siteId == null) return;
      if (!storefront.isFetchingMore && storefront.hasMorePopular) {
        context.read<StorefrontCubit>().loadMoreData(
          siteId,
          AppConstants.kDefaultFirst,
          storefront.categoryIndex == 0
              ? null
              : storefront.allCategory[storefront.categoryIndex - 1].id,
          false,
          false,
        );
      }
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _flashSaleController.dispose();
    _newArrivalController.dispose();
    super.dispose();
  }

  Future<void> _hydrateRecentProducts() async {
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    final recent = await LocalStorage.getRecentProducts(
      siteId: activeStore?.siteId,
    );
    if (!mounted) return;
    setState(() {
      _recentProducts = recent.take(10).toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StorefrontCubit, StorefrontState>(
      builder: (context, storefrontState) {
        final siteId = storefrontState.siteDetails?.id;
        if (siteId != null &&
            storefrontState.allCategory.isNotEmpty &&
            storefrontState.homeCategoryProducts.isEmpty &&
            !storefrontState.homeCategoryLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<StorefrontCubit>().ensureHomeCategorySections(
              siteId,
              AppConstants.kDefaultFirst,
              maxSections: storefrontState.allCategory.length,
            );
          });
        }

        final hasVisibleContent =
            storefrontState.siteSlider.isNotEmpty ||
            storefrontState.allCategory.isNotEmpty ||
            storefrontState.products.isNotEmpty ||
            storefrontState.flashSale.isNotEmpty ||
            storefrontState.newArrival.isNotEmpty ||
            storefrontState.topBrand.isNotEmpty;

        return RefreshIndicator(
          onRefresh: _refreshStorefront,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _pagePadding,
                    12,
                    _pagePadding,
                    8,
                  ),
                  child: Column(
                    children: [
                      if (storefrontState.error != null &&
                          storefrontState.products.isEmpty &&
                          storefrontState.siteSlider.isEmpty)
                        _InlineHomeState(
                          icon: HugeIcons.strokeRoundedAlertCircle,
                          title: storefrontState.error!.title,
                          subtitle:
                              'Pull to refresh or switch to another store.',
                          actionLabel: 'Retry',
                          onAction: _refreshStorefront,
                        ),
                      if (storefrontState.isLoading && !hasVisibleContent)
                        const _HomeSkeleton(),
                    ],
                  ),
                ),
              ),
              if (!(storefrontState.isLoading && !hasVisibleContent))
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySearchHeaderDelegate(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _pagePadding,
                        0,
                        _pagePadding,
                        _blockGap,
                      ),
                      child: SearchWidget(
                        onTap: () => AppRouter.pushSearchScreen(context),
                      ),
                    ),
                  ),
                ),
              if (!(storefrontState.isLoading && !hasVisibleContent))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    _pagePadding,
                    4,
                    _pagePadding,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (storefrontState.siteSlider.isNotEmpty) ...[
                          CarousalSliderHomePage(
                            items: storefrontState.siteSlider,
                          ),
                          const SizedBox(height: _sectionGap),
                        ],
                        if (storefrontState.allCategory.isNotEmpty) ...[
                          _HomeSectionIntro(
                            icon: HugeIcons.strokeRoundedGridView,
                            title: 'Categories',
                            subtitle: 'Browse the store by collection',
                            badge:
                                '${storefrontState.allCategory.length} groups',
                          ),
                          const SizedBox(height: _blockGap),
                          _TwoRowCategoryRail(
                            categories: storefrontState.allCategory,
                            onTap: (category, title) =>
                                _openCategory(category, title),
                          ),
                          const SizedBox(height: _sectionGap),
                        ],
                        if (!storefrontState.isLoading && !hasVisibleContent)
                          _InlineHomeState(
                            icon: HugeIcons.strokeRoundedPackageSearch01,
                            title: 'This store has no catalog yet',
                            subtitle: '',
                            actionLabel: 'Explore shops',
                            onAction: () async {
                              AppRouter.goToStoreSelector(context);
                            },
                          )
                        else
                          AllPartHomePage(
                            flashSaleController: _flashSaleController,
                            newArrivalController: _newArrivalController,
                            storefrontState: storefrontState,
                          ),
                        if (_recentProducts.isNotEmpty) ...[
                          const SizedBox(height: _sectionGap),
                          _TrustRailSection(
                            icon: HugeIcons.strokeRoundedReload,
                            title: 'Recently viewed',
                            subtitle:
                                'Jump back into items you already checked',
                            products: _recentProducts
                                .map(_recentToProduct)
                                .where((item) => item.hid?.isNotEmpty == true)
                                .toList(growable: false),
                          ),
                        ],
                        BlocBuilder<FavouriteCubit, FavouriteState>(
                          builder: (context, favouritesState) {
                            if (favouritesState.items.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: [
                                const SizedBox(height: _sectionGap),
                                _TrustRailSection(
                                  icon: HugeIcons.strokeRoundedFavourite,
                                  title: 'Favourite picks',
                                  subtitle:
                                      'Saved products waiting for your next order',
                                  products: favouritesState.items
                                      .take(10)
                                      .toList(growable: false),
                                ),
                              ],
                            );
                          },
                        ),
                        if (_topRatedProducts(storefrontState).isNotEmpty) ...[
                          const SizedBox(height: _sectionGap),
                          _TrustRailSection(
                            icon: HugeIcons.strokeRoundedStar,
                            title: 'Top rated',
                            subtitle:
                                'Products with the strongest shopper signals',
                            products: _topRatedProducts(storefrontState),
                          ),
                        ],
                        if (storefrontState.isFetchingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshStorefront() async {
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    await context.read<StorefrontCubit>().preload(
      domain: activeStore?.domain ?? AppConstants.kDefaultDomain,
      siteId: activeStore?.siteId ?? AppConstants.kDefaultSiteId,
      first: AppConstants.kDefaultFirst,
      forceRefresh: true,
    );
    await _hydrateRecentProducts();
  }

  List<ProductResCommon> _topRatedProducts(StorefrontState storefrontState) {
    final allProducts = <ProductResCommon>[
      ...storefrontState.products,
      ...storefrontState.newArrival,
      ...storefrontState.flashSale,
    ];
    final deduped = <int?, ProductResCommon>{};
    for (final product in allProducts) {
      deduped[product.id] = product;
    }
    final rated = deduped.values
        .where((item) => (item.rating ?? 0) > 0)
        .toList(growable: false);
    rated.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return rated.take(10).toList(growable: false);
  }

  ProductResCommon _recentToProduct(RecentProduct item) {
    return ProductResCommon(
      brands: item.brand.isNotEmpty ? <String>[item.brand] : const <String>[],
      comparePrice: item.comparePrice,
      features: const <Feature>[],
      hid: item.hid,
      images: item.thumbnail.isNotEmpty
          ? <ProductImage>[ProductImage(id: null, image: item.thumbnail)]
          : const <ProductImage>[],
      price: item.price,
      siteId: item.siteId,
      thumbnail: item.thumbnail,
      title: item.title,
      translation: item.title,
      variants: const <Variant>[],
      wholesale: const <dynamic>[],
    );
  }

  void _openCategory(CategoriesRes data, String text) {
    final categoryId = data.id;
    if (categoryId == null) return;
    final categoriesCubit = context.read<CategoriesCubit>();
    categoriesCubit.setCategoryIndex(0, data);
    final siteId =
        data.siteId ??
        context.read<StoreContextCubit>().state.activeStore?.siteId ??
        AppConstants.kDefaultSiteId;
    categoriesCubit.fetchCategoriesAllProduct(
      siteId,
      AppConstants.kDefaultFirst,
      categoryId,
      0,
    );
    Navigator.of(context).push(
      _fadeRoute(
        SubCategoryProductsScreen(
          subCategoryId: -1,
          title: text,
          seeAll: true,
          categoryId: categoryId,
        ),
      ),
    );
  }

  PageRouteBuilder<void> _fadeRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _TrustRailSection extends StatelessWidget {
  const _TrustRailSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.products,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final List<ProductResCommon> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HomeSectionIntro(
          icon: icon,
          title: title,
          subtitle: subtitle,
          badge: '${products.length} picks',
        ),
        const SizedBox(height: 12),
        ProductListViewHorizontal(
          products: products,
          visibleCountOverride: 3,
          horizontalInset: 0,
        ),
      ],
    );
  }
}

class _TwoRowCategoryRail extends StatelessWidget {
  const _TwoRowCategoryRail({required this.categories, required this.onTap});

  final List<CategoriesRes> categories;
  final void Function(CategoriesRes category, String title) onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    final categoryChunks = <List<CategoriesRes>>[];
    for (var index = 0; index < categories.length; index += 10) {
      final end = index + 10 < categories.length
          ? index + 10
          : categories.length;
      categoryChunks.add(categories.sublist(index, end));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categoryChunks
            .map((chunk) {
              final firstRow = chunk.take(5).toList(growable: false);
              final secondRow = chunk.skip(5).toList(growable: false);
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: firstRow
                            .map(
                              (category) => _HomeCategoryTile(
                                category: category,
                                onTap: onTap,
                              ),
                            )
                            .toList(growable: false),
                      ),
                      if (secondRow.isNotEmpty) const SizedBox(height: 10),
                      if (secondRow.isNotEmpty)
                        Row(
                          children: secondRow
                              .map(
                                (category) => _HomeCategoryTile(
                                  category: category,
                                  onTap: onTap,
                                ),
                              )
                              .toList(growable: false),
                        ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _HomeCategoryTile extends StatelessWidget {
  const _HomeCategoryTile({required this.category, required this.onTap});

  final CategoriesRes category;
  final void Function(CategoriesRes category, String title) onTap;

  @override
  Widget build(BuildContext context) {
    final title = (category.translation?.trim().isNotEmpty ?? false)
        ? category.translation!.trim()
        : (category.title ?? '--').trim();
    final imageUrl = category.cover ?? category.image ?? '';
    final initial = title.isNotEmpty
        ? String.fromCharCode(title.runes.first).toUpperCase()
        : '';

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => onTap(category, title),
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColor.safe),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AppNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          backgroundColor: AppColor.safe1,
                        ),
                      )
                    : _CategoryFallback(initial: initial),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickySearchHeaderDelegate({required this.child});

  static const double _extent = 72;

  final Widget child;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: overlapsContent ? AppColor.safe : Colors.transparent,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _InlineHomeState extends StatelessWidget {
  const _InlineHomeState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHugeIcon(icon, color: AppColor.alert, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => onAction!.call(),
                    child: Text(actionLabel!),
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

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.safe1,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColor.neutral2,
        ),
      ),
    );
  }
}

class _HomeSectionIntro extends StatelessWidget {
  const _HomeSectionIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColor.safe),
          ),
          child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColor.safe),
            ),
            child: Text(
              badge!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppSkeleton(
          height: 58,
          radius: 18,
          margin: EdgeInsets.only(bottom: 14),
        ),
        AppSkeleton(
          height: 180,
          radius: 22,
          margin: EdgeInsets.only(bottom: 18),
        ),
        Row(
          children: [
            Expanded(child: AppSkeleton(height: 100, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: AppSkeleton(height: 100, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: AppSkeleton(height: 100, radius: 18)),
          ],
        ),
        SizedBox(height: 18),
        AppSkeleton(height: 22, width: 150, radius: 999),
      ],
    );
  }
}
