import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/config/text_style.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/local/recent_product.dart';
import 'package:sellhub/core/store/store_industry.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/route_names.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/product_share_sheet.dart';
import 'package:sellhub/core/widget/app_skeleton.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/auth/screens/login_screen.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_state.dart';
import 'package:sellhub/features/cart/screens/checkout_screen.dart';
import 'package:sellhub/features/product/data/models/customer_review_req.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/presentation/cubit/product_details_cubit.dart';
import 'package:sellhub/features/product/presentation/cubit/product_details_state.dart';
import 'package:sellhub/features/product/screens/widget/product details/customer_review_line.dart';
import 'package:sellhub/features/product/screens/widget/product details/detailt_upper_part.dart';
import 'package:sellhub/features/product/screens/widget/product details/image_part.dart';
import 'package:sellhub/features/product/screens/widget/product details/middle_part.dart';
import 'package:sellhub/features/product/screens/widget/product details/single_customer_review_card.dart';
import 'package:sellhub/features/product/screens/widget/product_list_view_horizontal.dart';
import 'package:sellhub/features/product/screens/widget/product_list_vertical.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_cubit.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';
import 'package:sellhub/features/main_screen.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/injection_container.dart' as di;

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.hid,
    required this.productResCommon,
  });

  final String hid;
  final ProductResCommon productResCommon;

  static Route<void> route({
    required String hid,
    required ProductResCommon product,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => ProductDetailsScreen(hid: hid, productResCommon: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ProductDetailsCubit>()
        ..hydrate(
          hid: hid,
          baseProduct: productResCommon,
          siteId: StoreScope.activeSiteId(context),
        ),
      child: _ProductDetailsView(baseProduct: productResCommon, hid: hid),
    );
  }
}

class _ProductDetailsView extends StatefulWidget {
  const _ProductDetailsView({required this.baseProduct, required this.hid});

  final ProductResCommon baseProduct;
  final String hid;

  @override
  State<_ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<_ProductDetailsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _feedbackController = TextEditingController();
  bool _isOpenReviewForm = false;
  double _ratingValue = 5;
  List<RecentProduct> _recentProducts = const <RecentProduct>[];

  String? _firstBrandLabel(List<dynamic> brands) {
    if (brands.isEmpty) return null;
    final raw = brands.first;
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty || value == 'null') {
      return null;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _trackRecentView(widget.baseProduct);
    _hydrateRecentProducts();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      context.read<ProductDetailsCubit>().loadMoreRelated(
        StoreScope.activeSiteId(context),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _trackRecentView(ProductResCommon product) {
    final hid = product.hid?.trim() ?? '';
    final title = (product.translation?.trim().isNotEmpty ?? false)
        ? product.translation!.trim()
        : (product.title ?? '').trim();
    if (hid.isEmpty || title.isEmpty) {
      return Future<void>.value();
    }
    return LocalStorage.pushRecentProduct(
      RecentProduct(
        hid: hid,
        siteId: product.siteId ?? StoreScope.activeSiteId(context),
        title: title,
        thumbnail: (product.thumbnail ?? '').trim().isNotEmpty
            ? product.thumbnail!.trim()
            : product.images.isNotEmpty
            ? (product.images.first.image ?? '').trim()
            : '',
        price: product.price ?? 0,
        comparePrice: product.comparePrice ?? 0,
        brand: product.brands.isNotEmpty ? product.brands.first.trim() : '',
      ),
    ).then((_) => _hydrateRecentProducts());
  }

  Future<void> _hydrateRecentProducts() async {
    final recent = await LocalStorage.getRecentProducts(
      siteId: StoreScope.activeSiteId(context),
    );
    if (!mounted) return;
    setState(() {
      _recentProducts = recent
          .where((item) => item.hid != widget.hid)
          .take(8)
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
      builder: (context, state) {
        final product = state.product;
        final cubit = context.read<ProductDetailsCubit>();
        final industry = StoreIndustry.fromRaw(
          context.select<StorefrontCubit, Object?>(
            (c) => c.state.siteDetails?.industry,
          ),
        );
        final visualCatalog = StoreIndustry.isVisualCatalog(industry);
        final validImages = (product?.images ?? [])
            .where((item) => cubit.isValidImage(item.image))
            .toList();
        final brandLabel = _firstBrandLabel(product?.brands ?? const []);
        final showLocalBottomNav = _shouldShowLocalBottomNav();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: SellHubTopAppBar(
            title: product?.title ?? 'Product Details',
            subtitle: brandLabel ?? 'Product details',
            icon: HugeIcons.strokeRoundedPackageSearch01,
            showBackButton: true,
            actions: <Widget>[
              _ProductShareAction(onTap: () => _shareProduct(context, state)),
              const SizedBox(width: 8),
            ],
          ),
          body: state.loading && product == null
              ? const _ProductDetailsSkeleton()
              : state.error != null && product == null
              ? _ProductDetailsStateView(
                  icon: HugeIcons.strokeRoundedAlertCircle,
                  title: state.error!.title,
                  subtitle: 'Go back and try opening the product again.',
                  actionLabel: 'Retry',
                  onAction: () => _refreshProduct(context),
                )
              : product == null
              ? const _ProductDetailsStateView(
                  icon: HugeIcons.strokeRoundedPackageSearch01,
                  title: 'Product unavailable',
                  subtitle: 'This product could not be loaded right now.',
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _refreshProduct(context),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          child: Column(
                            children: [
                              if (state.error != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    0,
                                  ),
                                  child: _ProductDetailsStateView(
                                    icon: HugeIcons.strokeRoundedAlertCircle,
                                    title: state.error!.title,
                                    subtitle:
                                        'Some product sections could not be refreshed. Pull down to retry.',
                                    compact: true,
                                  ),
                                ),
                              _sectionCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    LargeImageProductDetails(
                                      visualCatalog: visualCatalog,
                                      validImages: validImages,
                                      product: product,
                                      state: state,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: smallImageListHorizontal(
                                        validImages: validImages,
                                        product: product,
                                        state: state,
                                        onImageSelected: cubit.setImageIndex,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _sectionCard(
                                child: titlePriceColor(
                                  product: product,
                                  textTheme: Theme.of(context).textTheme,
                                ),
                              ),
                              _sectionCard(
                                child: _buildHeroHighlights(
                                  product: product,
                                  common:
                                      state.baseProduct ?? widget.baseProduct,
                                ),
                              ),
                              _sectionCard(
                                child: ProductDetailsMiddlePart(
                                  product: product,
                                  productResCommon:
                                      state.baseProduct ?? widget.baseProduct,
                                ),
                              ),
                              _sectionCard(
                                child: _buildShoppingSignals(
                                  product: product,
                                  common:
                                      state.baseProduct ?? widget.baseProduct,
                                ),
                              ),
                              _sectionCard(
                                child: _buildTrustSnapshot(
                                  context,
                                  state,
                                  common:
                                      state.baseProduct ?? widget.baseProduct,
                                ),
                              ),
                              _sectionCard(child: _buildReviewSummary(state)),
                              if (_isOpenReviewForm)
                                _sectionCard(child: _buildReviewForm(state)),
                              _sectionCard(child: _buildReviewList(state)),
                              if (_recentProducts.isNotEmpty)
                                _sectionCard(child: _buildRecentViewsSection()),
                              if (state.relatedProducts.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColor.text
                                                        .withValues(
                                                          alpha: 0.03,
                                                        ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: const AppHugeIcon(
                                                HugeIcons.strokeRoundedSparkles,
                                                color: AppColor.primary,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Keep browsing',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color:
                                                            AppColor.neutral2,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Related Products',
                                                  style: kTextStyle.itemHead,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ProductListViewVerical(
                                        products: state.relatedProducts,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              if (state.relatedLoading ||
                                  state.isFetchingMoreRelated)
                                const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildBottomAction(
                      context,
                      state,
                      includeBottomSafeArea: !showLocalBottomNav,
                    ),
                  ],
                ),
          bottomNavigationBar: showLocalBottomNav
              ? StoreBottomNavBar(
                  currentIndex: context
                      .watch<StoreShellCubit>()
                      .state
                      .currentIndex,
                )
              : null,
        );
      },
    );
  }

  Future<void> _shareProduct(
    BuildContext context,
    ProductDetailsState state,
  ) async {
    final product = state.baseProduct ?? widget.baseProduct;
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    if (activeStore == null) {
      CustomToast.error('Store link is unavailable right now.');
      return;
    }
    await ProductShareSheet.show(
      context: context,
      store: activeStore,
      product: product,
    );
  }

  Widget _buildTrustSnapshot(
    BuildContext context,
    ProductDetailsState state, {
    required ProductResCommon common,
  }) {
    final reviewCount = state.customerReviews.length;
    final isFavourite = context.select<FavouriteCubit, bool>(
      (cubit) => cubit.state.favoriteIds.contains(common.id ?? 0),
    );
    final boughtCount = state.product?.sold ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InlineSectionLead(
          icon: HugeIcons.strokeRoundedFavourite,
          eyebrow: 'Trust signals',
          title: 'Shoppers are already using this product',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TrustMetric(
                icon: HugeIcons.strokeRoundedStar,
                label: 'Reviews',
                value: reviewCount > 0 ? '$reviewCount' : 'New',
                hint: reviewCount > 0
                    ? '${state.averageRating.toStringAsFixed(1)} avg'
                    : 'Be first to rate',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrustMetric(
                icon: HugeIcons.strokeRoundedFavourite,
                label: 'Saved',
                value: isFavourite ? 'Yes' : 'Tap',
                hint: isFavourite ? 'In your favourites' : 'Save for later',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrustMetric(
                icon: HugeIcons.strokeRoundedShoppingBag01,
                label: 'Demand',
                value: boughtCount > 0 ? '$boughtCount' : 'Fresh',
                hint: boughtCount > 0 ? 'Units sold' : 'New listing',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentViewsSection() {
    final recentProducts = _recentProducts
        .map(_recentToProduct)
        .where((item) => item.hid?.isNotEmpty == true)
        .toList(growable: false);
    if (recentProducts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InlineSectionLead(
          icon: HugeIcons.strokeRoundedReload,
          eyebrow: 'Quick return',
          title: 'Recently viewed',
        ),
        const SizedBox(height: 12),
        ProductListViewHorizontal(
          products: recentProducts,
          visibleCountOverride: 3,
          horizontalInset: 0,
        ),
      ],
    );
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

  bool _shouldShowLocalBottomNav() {
    final path = AppRouter.router.routeInformationProvider.value.uri.path
        .toLowerCase();
    return path == '/${RouteNames.home}';
  }

  Future<void> _refreshProduct(BuildContext context) {
    return context.read<ProductDetailsCubit>().hydrate(
      hid: widget.hid,
      baseProduct: widget.baseProduct,
      siteId: StoreScope.activeSiteId(context),
    );
  }

  Widget _buildReviewSummary(ProductDetailsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          eyebrow: 'Customer feedback',
          title: 'Customer Reviews',
          icon: HugeIcons.strokeRoundedComment01,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              state.averageRating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => AppHugeIcon(
                      HugeIcons.strokeRoundedStar,
                      color: index < state.averageRating.round()
                          ? AppColor.primary
                          : Colors.grey,
                      secondaryColor: index < state.averageRating.round()
                          ? AppColor.primary.withValues(alpha: 0.18)
                          : null,
                      size: 18,
                    ),
                  ),
                ),
                Text(
                  '${state.customerReviews.length} ratings',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(5, (index) {
          final star = 5 - index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: CustomerReviewLineDraw(
              number: '$star',
              percent: state.ratingPercent(star),
              isEnable: state.ratingBreakdown[star]! > 0,
            ),
          );
        }),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.withValues(alpha: 0.2)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isOpenReviewForm = !_isOpenReviewForm;
              _ratingValue = 5;
            });
          },
          child: Container(
            height: 42,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.safe1.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _isOpenReviewForm
                    ? 'Close Review Form'
                    : 'Write a Customer Review',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColor.text,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingSignals({
    required dynamic product,
    required ProductResCommon common,
  }) {
    final discount = (product.discount ?? common.discount ?? 0).toDouble();
    final comparePrice = (product.comparePrice ?? common.comparePrice ?? 0)
        .toDouble();
    final price = (product.price ?? common.price ?? 0).toDouble();
    final deliveryTime = product.deliveryTime as int?;
    final rewardPoints = (product.rewardPoints ?? common.rewardPoints ?? 0)
        .toDouble();
    final cashback = (product.cashback ?? common.cashback ?? 0).toDouble();
    final brand = common.brands.isNotEmpty
        ? common.brands.first
        : 'Trusted brand';
    final savings = comparePrice > price ? (comparePrice - price) : 0;
    final promises = <({List<List<dynamic>> icon, String label})>[
      (
        icon: HugeIcons.strokeRoundedShield01,
        label: deliveryTime != null && deliveryTime > 0
            ? '$deliveryTime day delivery'
            : 'Store delivery',
      ),
      (icon: HugeIcons.strokeRoundedAward01, label: brand),
      (
        icon: HugeIcons.strokeRoundedDiscountTag01,
        label: savings > 0
            ? 'Save ${savings.toStringAsFixed(0)}'
            : '${discount.toStringAsFixed(0)}% offer',
      ),
      (
        icon: HugeIcons.strokeRoundedGift,
        label: rewardPoints > 0
            ? '${rewardPoints.toStringAsFixed(0)} pts'
            : cashback > 0
            ? 'Cashback ${cashback.toStringAsFixed(0)}'
            : 'Store perks',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          eyebrow: 'Shopping signals',
          title: 'Why shoppers choose this',
          icon: HugeIcons.strokeRoundedSparkles,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SignalTile(
                icon: HugeIcons.strokeRoundedDiscountTag01,
                label: savings > 0 ? 'Save' : 'Offer',
                value: savings > 0
                    ? 'BDT ${savings.toStringAsFixed(0)}'
                    : '${discount.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SignalTile(
                icon: HugeIcons.strokeRoundedDeliveryTruck02,
                label: 'Delivery',
                value: deliveryTime != null && deliveryTime > 0
                    ? '$deliveryTime day'
                    : 'Active',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: promises
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.safe1.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppHugeIcon(item.icon, size: 14, color: AppColor.primary),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColor.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        if (common.brands.isNotEmpty || rewardPoints > 0 || cashback > 0) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColor.text.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (common.brands.isNotEmpty)
                  Expanded(
                    child: _MiniStat(
                      icon: HugeIcons.strokeRoundedAward01,
                      title: common.brands.first,
                    ),
                  ),
                if (common.brands.isNotEmpty &&
                    (rewardPoints > 0 || cashback > 0))
                  const SizedBox(width: 10),
                if (rewardPoints > 0 || cashback > 0)
                  Expanded(
                    child: _MiniStat(
                      icon: rewardPoints > 0
                          ? HugeIcons.strokeRoundedGift
                          : HugeIcons.strokeRoundedMoneyBag02,
                      title: rewardPoints > 0
                          ? '${rewardPoints.toStringAsFixed(0)} reward pts'
                          : 'Cashback ${cashback.toStringAsFixed(0)}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroHighlights({
    required dynamic product,
    required ProductResCommon common,
  }) {
    final comparePrice = (product.comparePrice ?? common.comparePrice ?? 0)
        .toDouble();
    final price = (product.price ?? common.price ?? 0).toDouble();
    final savings = comparePrice > price ? comparePrice - price : 0;
    final rewardPoints = (product.rewardPoints ?? common.rewardPoints ?? 0)
        .toDouble();
    final cashback = (product.cashback ?? common.cashback ?? 0).toDouble();
    final hasStock = (product?.quantity ?? common.quantity ?? 0) > 0;
    final brand = common.brands.isNotEmpty ? common.brands.first.trim() : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          eyebrow: 'Quick take',
          title: 'At a glance',
          icon: HugeIcons.strokeRoundedSparkles,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroBadge(
              icon: hasStock
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : HugeIcons.strokeRoundedAlert02,
              label: hasStock ? 'Ready to order' : 'Limited stock',
              emphasis: hasStock,
            ),
            if (savings > 0)
              _HeroBadge(
                icon: HugeIcons.strokeRoundedDiscountTag01,
                label: 'Save BDT ${savings.toStringAsFixed(0)}',
              ),
            if (brand.isNotEmpty)
              _HeroBadge(icon: HugeIcons.strokeRoundedAward01, label: brand),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SignalTile(
                icon: HugeIcons.strokeRoundedDeliveryTruck02,
                label: 'Order flow',
                value: hasStock ? 'Fast checkout' : 'Check with store',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SignalTile(
                icon: rewardPoints > 0
                    ? HugeIcons.strokeRoundedGift
                    : HugeIcons.strokeRoundedMoneyBag02,
                label: rewardPoints > 0 ? 'Rewards' : 'Store value',
                value: rewardPoints > 0
                    ? '${rewardPoints.toStringAsFixed(0)} pts'
                    : cashback > 0
                    ? 'Cashback ${cashback.toStringAsFixed(0)}'
                    : 'Member perks',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewForm(ProductDetailsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          eyebrow: 'Leave feedback',
          title: 'Add Your Review',
          icon: HugeIcons.strokeRoundedEdit02,
        ),
        const SizedBox(height: 10),
        const Text(
          'YOUR RATING',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            RatingBar.builder(
              itemSize: 25,
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, _) => const AppHugeIcon(
                HugeIcons.strokeRoundedStar,
                color: Colors.amber,
                secondaryColor: Color(0x33FFC107),
              ),
              onRatingUpdate: (rating) => setState(() => _ratingValue = rating),
            ),
            const SizedBox(width: 20),
            Text(
              _ratingValue == 5
                  ? 'Excellent'
                  : _ratingValue == 4
                  ? 'Good'
                  : _ratingValue == 3
                  ? 'Average'
                  : _ratingValue == 2
                  ? 'Poor'
                  : 'Terrible',
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'YOUR FEEDBACK',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          controller: _feedbackController,
          decoration: InputDecoration(
            hintText: 'What did you like or dislike?',
            filled: true,
            fillColor: AppColor.safe1.withValues(alpha: 0.75),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColor.primary.withValues(alpha: 0.24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: () => _submitReview(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.text,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Review',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitReview(ProductDetailsState state) async {
    if (_feedbackController.text.trim().isEmpty) {
      CustomToast.error('Please write a comment');
      return;
    }
    final navigator = Navigator.of(context);
    final productDetailsCubit = context.read<ProductDetailsCubit>();
    final profile = context.read<ProfileCubit>().state.profile;
    final siteId = StoreScope.activeSiteId(context);
    if (!await LocalStorage.isLogin()) {
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }
    final model = SubmitReviewReq(
      userId: await LocalStorage.getUserID(),
      siteId: siteId,
      productId: state.product?.id ?? 0,
      description: _feedbackController.text.trim(),
      rating: _ratingValue.toInt(),
      feedbackType: 'review',
      status: 'approved',
      image: null,
      feedbacker: profile?.title,
    );
    final result = await productDetailsCubit.submitReview(model);
    if (!mounted) return;
    if (result) {
      CustomToast.info('Successfully added review');
      setState(() {
        _feedbackController.clear();
        _isOpenReviewForm = false;
      });
    } else {
      CustomToast.error('Failed to add review');
    }
  }

  Widget _buildReviewList(ProductDetailsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          eyebrow: 'What buyers say',
          title: 'Top Reviews (${state.customerReviews.length})',
          icon: HugeIcons.strokeRoundedMessageMultiple01,
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.grey.withValues(alpha: 0.7), thickness: 0.6),
        const SizedBox(height: 10),
        if (state.customerReviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  AppHugeIcon(
                    HugeIcons.strokeRoundedComment01,
                    size: 40,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No Reviews Yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Be the first to review this product!',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: state.customerReviews.length,
            itemBuilder: (context, index) =>
                SingleCustomerReviewCard(review: state.customerReviews[index]),
          ),
      ],
    );
  }

  Widget _sectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColor.text.withValues(alpha: 0.025),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: padding == EdgeInsets.zero
              ? child
              : Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeading({
    required String eyebrow,
    required String title,
    required List<List<dynamic>> icon,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColor.text.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildBottomAction(
    BuildContext context,
    ProductDetailsState state, {
    required bool includeBottomSafeArea,
  }) {
    final product = state.product;
    final common = state.baseProduct ?? widget.baseProduct;
    final comparePrice =
        product?.comparePrice?.toDouble() ??
        common.comparePrice?.toDouble() ??
        0;
    final price = product?.price?.toDouble() ?? common.price?.toDouble() ?? 0;
    final savings = comparePrice > price ? comparePrice - price : 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        10.h,
        16.w,
        (includeBottomSafeArea ? MediaQuery.of(context).padding.bottom + 8 : 10)
            .h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColor.text.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          final isCart = cartState.items.any(
            (item) => item.product.id == product?.id,
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColor.neutral2,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product?.price != null
                              ? 'BDT ${product!.price!.toStringAsFixed(0)}'
                              : 'Unavailable',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColor.text,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (savings > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Save BDT ${savings.toStringAsFixed(0)} on this order',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColor.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isCart ? AppColor.safe1 : AppColor.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCart ? 'In cart' : 'Instant checkout',
                      style: TextStyle(
                        color: isCart ? AppColor.primary : AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isCart ? AppColor.safe : AppColor.primary,
                          ),
                          backgroundColor: isCart
                              ? AppColor.safe1
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: AppColor.text,
                        ),
                        onPressed: product == null
                            ? null
                            : () {
                                if (isCart) {
                                  CustomToast.info('Already in cart');
                                } else {
                                  context.read<CartCubit>().addToCart(common);
                                  CustomToast.info('Added to cart');
                                }
                              },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compactLabel = constraints.maxWidth < 108;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppHugeIcon(
                                  isCart
                                      ? HugeIcons.strokeRoundedCheckmarkCircle02
                                      : HugeIcons
                                            .strokeRoundedShoppingCartAdd01,
                                  size: 18,
                                ),
                                SizedBox(width: compactLabel ? 6 : 8),
                                Flexible(
                                  child: Text(
                                    isCart
                                        ? (compactLabel ? 'Added' : 'Added')
                                        : (compactLabel
                                              ? 'Cart'
                                              : 'Add to cart'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: compactLabel ? 13 : 14,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: product == null
                            ? null
                            : () {
                                final cp = product.comparePrice?.toInt() ?? 0;
                                final p = product.price?.toInt() ?? 0;
                                final save = cp > p ? (cp - p) : 0;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      isCart: false,
                                      comparePrice: product.comparePrice
                                          ?.toInt(),
                                      payPrice: product.price?.toInt(),
                                      savePrice: save,
                                      title:
                                          product.translation ??
                                          product.title ??
                                          '',
                                      id: product.id ?? 0,
                                    ),
                                  ),
                                );
                              },
                        child: const Text(
                          'Buy now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.safe1.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHugeIcon(icon, size: 18, color: AppColor.primary),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    this.emphasis = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasis ? AppColor.safe1.withValues(alpha: 0.75) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColor.text.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppHugeIcon(
            icon,
            size: 14,
            color: emphasis ? AppColor.primary : AppColor.neutral2,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductShareAction extends StatelessWidget {
  const _ProductShareAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColor.safe),
        ),
        alignment: Alignment.center,
        child: const AppHugeIcon(
          HugeIcons.strokeRoundedShare08,
          size: 16,
          color: AppColor.primary,
        ),
      ),
    );
  }
}

class _InlineSectionLead extends StatelessWidget {
  const _InlineSectionLead({
    required this.icon,
    required this.eyebrow,
    required this.title,
  });

  final List<List<dynamic>> icon;
  final String eyebrow;
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustMetric extends StatelessWidget {
  const _TrustMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHugeIcon(icon, size: 16, color: AppColor.primary),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

class _ProductDetailsSkeleton extends StatelessWidget {
  const _ProductDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: const [
          AppSkeletonCard(
            padding: EdgeInsets.all(14),
            child: Column(
              children: [
                AppSkeleton(height: 280, radius: 16),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: AppSkeleton(height: 64, radius: 12)),
                    SizedBox(width: 8),
                    Expanded(child: AppSkeleton(height: 64, radius: 12)),
                    SizedBox(width: 8),
                    Expanded(child: AppSkeleton(height: 64, radius: 12)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          AppSkeletonCard(child: AppSkeleton(height: 90, radius: 14)),
          SizedBox(height: 10),
          AppSkeletonCard(child: AppSkeleton(height: 120, radius: 14)),
          SizedBox(height: 10),
          AppSkeletonCard(child: AppSkeleton(height: 110, radius: 14)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AppHugeIcon(icon, size: 16, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductDetailsStateView extends StatelessWidget {
  const _ProductDetailsStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: compact ? const EdgeInsets.all(16) : const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppHugeIcon(
              icon,
              size: compact ? 24 : 44,
              color: AppColor.neutral2,
            ),
            SizedBox(height: compact ? 8 : 14),
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
