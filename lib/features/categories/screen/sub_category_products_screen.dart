import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_state.dart';
import 'package:sellhub/features/cart/screens/cart_screen.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_state.dart';
import 'package:sellhub/features/product/screens/widget/product_list_vertical.dart';

class SubCategoryProductsScreen extends StatefulWidget {
  const SubCategoryProductsScreen({
    super.key,
    required this.subCategoryId,
    required this.title,
    required this.seeAll,
    required this.categoryId,
    this.brandId,
  });

  final int subCategoryId;
  final String title;
  final bool seeAll;
  final int categoryId;
  final int? brandId;

  @override
  State<SubCategoryProductsScreen> createState() =>
      _SubCategoryProductsScreenState();
}

class _SubCategoryProductsScreenState extends State<SubCategoryProductsScreen> {
  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshCatalog();
    });
  }

  void _onScroll() {
    if (_mainScrollController.position.extentAfter < 200) {
      final state = context.read<CategoriesCubit>().state;
      if (!state.isFetching) {
        context.read<CategoriesCubit>().loadMoreData(
          StoreScope.activeSiteId(context),
          widget.subCategoryId,
          16,
          widget.seeAll,
          widget.categoryId,
          widget.brandId,
        );
      }
    }
  }

  Future<void> _refreshCatalog() async {
    if (widget.brandId != null) {
      await context.read<CategoriesCubit>().fetchBrandProducts(
        StoreScope.activeSiteId(context),
        16,
        widget.brandId!,
        0,
      );
      return;
    }
    if (widget.seeAll) {
      await context.read<CategoriesCubit>().fetchCategoriesAllProduct(
        StoreScope.activeSiteId(context),
        16,
        widget.categoryId,
        0,
      );
      return;
    }
    await context.read<CategoriesCubit>().fetchSubCategoriesProduct(
      StoreScope.activeSiteId(context),
      16,
      widget.subCategoryId,
      0,
    );
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, categoriesState) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: SellHubTopAppBar(
            title: widget.title,
            icon: HugeIcons.strokeRoundedGridView,
            showBackButton: true,
            actions: [
              BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  return Badge(
                    offset: const Offset(-3, 5),
                    backgroundColor: AppColor.primary,
                    isLabelVisible: cartState.items.isNotEmpty,
                    label: Text('${cartState.items.length}'),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const CartScreen(isNewScreen: true),
                          ),
                        );
                      },
                      icon: const AppHugeIcon(
                        HugeIcons.strokeRoundedShoppingCart01,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  highlightColor: AppColor.grey.withValues(alpha: 0.5),
                  splashColor: AppColor.primary.withValues(alpha: 0.2),
                ),
                child: PopupMenuButton<String>(
                  tooltip: 'Filter',
                  onSelected: (value) {
                    context.read<CategoriesCubit>().queryTypeSet(
                      value,
                      widget.seeAll,
                      widget.seeAll ? widget.categoryId : widget.subCategoryId,
                      StoreScope.activeSiteId(context),
                      16,
                      brandId: widget.brandId,
                    );
                  },
                  itemBuilder: (context) {
                    return [
                      _filterItem(
                        title: 'Newest Products',
                        value: 'latest',
                        current: categoriesState.queryType,
                      ),
                      _filterItem(
                        title: 'Most Popular',
                        value: 'highest_sold',
                        current: categoriesState.queryType,
                      ),
                      _filterItem(
                        title: 'Highest Rating',
                        value: 'highest_rating',
                        current: categoriesState.queryType,
                      ),
                      _filterItem(
                        title: 'Lowest Price',
                        value: 'lowest_price',
                        current: categoriesState.queryType,
                      ),
                      _filterItem(
                        title: 'Highest Price',
                        value: 'highest_price',
                        current: categoriesState.queryType,
                      ),
                    ];
                  },
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshCatalog();
              },
              child: CustomScrollView(
                controller: _mainScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CatalogHero(
                        title: widget.title,
                        activeFilter: categoriesState.queryType,
                        catalogLabel: widget.brandId != null
                            ? 'Brand catalog'
                            : (widget.seeAll ? 'Whole category' : 'Subcategory'),
                      ),
                    ),
                  ),
                  if (categoriesState.isLoading &&
                      categoriesState.subCategoriesProduct.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (categoriesState.error != null &&
                      categoriesState.subCategoriesProduct.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CatalogStateCard(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        title: categoriesState.error!.title,
                      ),
                    )
                  else if (categoriesState.subCategoriesProduct.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CatalogStateCard(
                        icon: HugeIcons.strokeRoundedPackageSearch01,
                        title: 'No products found',
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _CatalogChip(
                              icon: HugeIcons.strokeRoundedGridView,
                              label: widget.brandId != null
                                  ? 'Brand catalog'
                                  : (widget.seeAll
                                        ? 'Whole category'
                                        : 'Subcategory'),
                            ),
                            _CatalogChip(
                              icon: HugeIcons.strokeRoundedFilterHorizontal,
                              label: _filterLabel(categoriesState.queryType),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ProductListViewVerical(
                        products: categoriesState.subCategoriesProduct,
                        emphasizeImage: true,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    if (categoriesState.isFetching)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    if (categoriesState.error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _CatalogStateCard(
                            icon: HugeIcons.strokeRoundedAlertCircle,
                            title: categoriesState.error!.title,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _filterItem({
    required String title,
    required String value,
    required String current,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          title,
          style: TextStyle(
            color: current == value ? AppColor.primary : AppColor.text,
            fontWeight: current == value ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _filterLabel(String queryType) {
    switch (queryType) {
      case 'highest_sold':
        return 'Popular';
      case 'highest_rating':
        return 'Top rated';
      case 'lowest_price':
        return 'Low price';
      case 'highest_price':
        return 'High price';
      case 'latest':
      default:
        return 'Newest';
    }
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero({
    required this.title,
    required this.activeFilter,
    required this.catalogLabel,
  });

  final String title;
  final String activeFilter;
  final String catalogLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColor.safe.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF6FADD),
                  Color(0xFFE8F2C9),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedGridView,
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
                  catalogLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColor.safe.withValues(alpha: 0.85)),
            ),
            child: Column(
              children: [
                Text(
                  'Sort',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _prettyFilter(activeFilter),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _prettyFilter(String filter) {
    switch (filter) {
      case 'highest_sold':
        return 'most popular';
      case 'highest_rating':
        return 'top rated';
      case 'lowest_price':
        return 'lowest price';
      case 'highest_price':
        return 'highest price';
      case 'latest':
      default:
        return 'new arrivals';
    }
  }
}

class _CatalogChip extends StatelessWidget {
  const _CatalogChip({
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
        color: const Color(0xFFFCFDF7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe.withValues(alpha: 0.85)),
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

class _CatalogStateCard extends StatelessWidget {
  const _CatalogStateCard({
    required this.icon,
    required this.title,
  });

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDF7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColor.safe.withValues(alpha: 0.8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppHugeIcon(icon, size: 36, color: AppColor.neutral2),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
