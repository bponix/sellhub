import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
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
  ProductViabilityFilter _viabilityFilter = ProductViabilityFilter.all;
  ProductViabilitySort _viabilitySort = ProductViabilitySort.featured;
  String _sellerLens = 'all';

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

  void _applySellerLens(String lens) {
    setState(() {
      _sellerLens = lens;
      switch (lens) {
        case 'student':
          _viabilityFilter = ProductViabilityFilter.beginnerFriendly;
          _viabilitySort = ProductViabilitySort.lowestRisk;
          break;
        case 'repeat':
          _viabilityFilter = ProductViabilityFilter.highRepeatPotential;
          _viabilitySort = ProductViabilitySort.highRepeatPotential;
          break;
        case 'margin':
          _viabilityFilter = ProductViabilityFilter.goodMargin;
          _viabilitySort = ProductViabilitySort.highestMargin;
          break;
        case 'cod':
          _viabilityFilter = ProductViabilityFilter.beginnerFriendly;
          _viabilitySort = ProductViabilitySort.lowestRisk;
          break;
        case 'fast':
          _viabilityFilter = ProductViabilityFilter.fastMover;
          _viabilitySort = ProductViabilitySort.featured;
          break;
        default:
          _viabilityFilter = ProductViabilityFilter.all;
          _viabilitySort = ProductViabilitySort.featured;
      }
    });
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
              IconButton(
                tooltip: 'Viability',
                onPressed: _openViabilitySheet,
                icon: const AppHugeIcon(
                  HugeIcons.strokeRoundedAiIdea,
                  size: 20,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CatalogIntentCard(
                              lens: _sellerLens,
                              onSelectLens: _applySellerLens,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
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
                                _CatalogChip(
                                  icon: HugeIcons.strokeRoundedAiIdea,
                                  label: _viabilityFilterLabel(_viabilityFilter),
                                ),
                                _CatalogChip(
                                  icon: HugeIcons
                                      .strokeRoundedArrowDataTransferHorizontal,
                                  label: _viabilitySortLabel(_viabilitySort),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ProductListViewVerical(
                        products: applyProductViability(
                          categoriesState.subCategoriesProduct,
                          filter: _viabilityFilter,
                          sort: _viabilitySort,
                        ),
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

  Future<void> _openViabilitySheet() async {
    final selected = await showModalBottomSheet<_ViabilitySelection>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => _ViabilityPickerSheet(
        filter: _viabilityFilter,
        sort: _viabilitySort,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _viabilityFilter = selected.filter;
      _viabilitySort = selected.sort;
    });
  }

  String _viabilityFilterLabel(ProductViabilityFilter filter) {
    switch (filter) {
      case ProductViabilityFilter.all:
        return 'All products';
      case ProductViabilityFilter.fastMover:
        return 'Fast mover';
      case ProductViabilityFilter.goodMargin:
        return 'Good margin';
      case ProductViabilityFilter.beginnerFriendly:
        return 'Beginner friendly';
      case ProductViabilityFilter.highRepeatPotential:
        return 'High repeat';
      case ProductViabilityFilter.riskyDeliveryZone:
        return 'Risky delivery';
      case ProductViabilityFilter.lowTrustSupplier:
        return 'Low trust';
    }
  }

  String _viabilitySortLabel(ProductViabilitySort sort) {
    switch (sort) {
      case ProductViabilitySort.featured:
        return 'Featured';
      case ProductViabilitySort.strongestDemand:
        return 'Strongest demand';
      case ProductViabilitySort.highestMargin:
        return 'Highest margin';
      case ProductViabilitySort.lowestRisk:
        return 'Lowest risk';
      case ProductViabilitySort.beginnerFriendly:
        return 'Best for beginners';
      case ProductViabilitySort.highRepeatPotential:
        return 'Repeat potential';
    }
  }
}

class _ViabilitySelection {
  const _ViabilitySelection({required this.filter, required this.sort});

  final ProductViabilityFilter filter;
  final ProductViabilitySort sort;
}

class _ViabilityPickerSheet extends StatefulWidget {
  const _ViabilityPickerSheet({required this.filter, required this.sort});

  final ProductViabilityFilter filter;
  final ProductViabilitySort sort;

  @override
  State<_ViabilityPickerSheet> createState() => _ViabilityPickerSheetState();
}

class _ViabilityPickerSheetState extends State<_ViabilityPickerSheet> {
  late ProductViabilityFilter _filter = widget.filter;
  late ProductViabilitySort _sort = widget.sort;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product viability',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductViabilityFilter.values
                  .map(
                    (filter) => ChoiceChip(
                      label: Text(filter.name),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductViabilitySort>(
              initialValue: _sort,
              items: ProductViabilitySort.values
                  .map(
                    (sort) => DropdownMenuItem(
                      value: sort,
                      child: Text(sort.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _sort = value);
              },
              decoration: const InputDecoration(labelText: 'Sort by'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(_ViabilitySelection(filter: _filter, sort: _sort)),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
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

class _CatalogIntentCard extends StatelessWidget {
  const _CatalogIntentCard({
    required this.lens,
    required this.onSelectLens,
  });

  final String lens;
  final ValueChanged<String> onSelectLens;

  String get _summary {
    switch (lens) {
      case 'student':
        return 'Beginner-safe picks for students, part-time sellers, and first COD orders.';
      case 'repeat':
        return 'Focus on products that are easier to sell again to neighborhood and repeat buyers.';
      case 'margin':
        return 'Push higher-margin products when you already trust the buyer and supplier lane.';
      case 'cod':
        return 'Safer COD picks for Bangladesh delivery and first-time buyer confirmation.';
      case 'fast':
        return 'Use fast movers when you need faster response from Facebook and WhatsApp audiences.';
      default:
        return 'Choose a Bangladesh reseller lens before reviewing supplier products.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bangladesh seller lens',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CatalogActionChip(
                  label: 'All',
                  selected: lens == 'all',
                  onTap: () => onSelectLens('all'),
                ),
                _CatalogActionChip(
                  label: 'Student budget',
                  selected: lens == 'student',
                  onTap: () => onSelectLens('student'),
                ),
                _CatalogActionChip(
                  label: 'Repeat buyers',
                  selected: lens == 'repeat',
                  onTap: () => onSelectLens('repeat'),
                ),
                _CatalogActionChip(
                  label: 'Good margin',
                  selected: lens == 'margin',
                  onTap: () => onSelectLens('margin'),
                ),
                _CatalogActionChip(
                  label: 'COD safer',
                  selected: lens == 'cod',
                  onTap: () => onSelectLens('cod'),
                ),
                _CatalogActionChip(
                  label: 'Fast movers',
                  selected: lens == 'fast',
                  onTap: () => onSelectLens('fast'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

class _CatalogActionChip extends StatelessWidget {
  const _CatalogActionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
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
            color: selected ? AppColor.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColor.primary : AppColor.safe,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColor.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
