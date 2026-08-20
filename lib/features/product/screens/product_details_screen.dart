import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/config/text_style.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/product_viability/product_viability_widgets.dart';
import 'package:sellhub/core/store/store_industry.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_widgets.dart';
import 'package:sellhub/core/supply_intelligence/supply_intelligence_widgets.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
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
import 'package:sellhub/features/cart/screens/widget/reseller_price_sheet.dart';
import 'package:sellhub/features/product/data/models/customer_review_req.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/presentation/cubit/product_details_cubit.dart';
import 'package:sellhub/features/product/presentation/cubit/product_details_state.dart';
import 'package:sellhub/features/product/screens/widget/product details/detailt_upper_part.dart';
import 'package:sellhub/features/product/screens/widget/product details/image_part.dart';
import 'package:sellhub/features/product/screens/widget/product details/middle_part.dart';
import 'package:sellhub/features/product/screens/widget/product details/single_customer_review_card.dart';
import 'package:sellhub/features/product/screens/widget/product_list_vertical.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
        final showLocalBottomNav = _shouldShowLocalBottomNav();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: SellHubTopAppBar(
            title: product?.title ?? 'Product Details',
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
                              if (state.supplierTrust != null)
                                _sectionCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SupplyIntelligenceCommitCard(
                                        profile: state.supplierTrust!,
                                        product:
                                            state.baseProduct ??
                                            widget.baseProduct,
                                      ),
                                      const SizedBox(height: 12),
                                      SupplierTrustDecisionCard(
                                        profile: state.supplierTrust!,
                                      ),
                                      const SizedBox(height: 12),
                                      SupplierTrustMetricsCard(
                                        profile: state.supplierTrust!,
                                        title: 'Supplier trust breakdown',
                                        subtitle:
                                            'Use supplier quality, return pressure, delivery speed, and payout behavior before you push this product harder.',
                                      ),
                                    ],
                                  ),
                                ),
                              _sectionCard(
                                child: ProductViabilityDetailCard(
                                  product:
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
                                            Text(
                                              'Similar products',
                                              style: kTextStyle.itemHead,
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
                              if (_isOpenReviewForm)
                                _sectionCard(child: _buildReviewForm(state)),
                              _sectionCard(child: _buildReviewList(state)),
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
              ? SellerBottomNavBar(
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

  Widget _buildReviewForm(ProductDetailsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          title: 'Add review',
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
        Row(
          children: [
            Expanded(
              child: _buildSectionHeading(
                title: '${state.customerReviews.length} reviews',
                icon: HugeIcons.strokeRoundedMessageMultiple01,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isOpenReviewForm = !_isOpenReviewForm;
                  _ratingValue = 5;
                });
              },
              child: Text(_isOpenReviewForm ? 'Close' : 'Add'),
            ),
          ],
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
                    'No reviews yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.grey,
                    ),
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
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
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
    final viability = ProductViabilityEngine.build(common);
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
          final basePrice = product?.price?.toInt() ?? 0;
          final trustScore =
              (state.supplierTrust?.score ?? viability.trustScore).round();
          final minSellPrice = common.minResellPrice?.round() ?? basePrice;
          final maxSellPrice =
              common.maxResellPrice?.round() ??
              (minSellPrice > 0 ? minSellPrice : basePrice);
          final minMargin = (minSellPrice - basePrice).clamp(0, 1 << 30);
          final maxMargin = (maxSellPrice - basePrice).clamp(0, 1 << 30);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColor.safe.withValues(alpha: 0.9),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product?.price != null
                                ? 'Margin window ৳${convertToBengaliNumber(minMargin)}-${convertToBengaliNumber(maxMargin)}'
                                : 'Base unavailable',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColor.text,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isCart ? Colors.white : AppColor.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isCart ? 'In selling list' : 'Ready to sell',
                            style: TextStyle(
                              color: isCart ? AppColor.primary : AppColor.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SellerSignalChip(
                          icon: HugeIcons.strokeRoundedMoneyBag02,
                          label: 'Base ৳${convertToBengaliNumber(basePrice)}',
                        ),
                        _SellerSignalChip(
                          icon: HugeIcons.strokeRoundedShield01,
                          label: 'Trust $trustScore',
                        ),
                        _SellerSignalChip(
                          icon: HugeIcons.strokeRoundedShare08,
                          label: 'Share ${viability.shareabilityScore.round()}',
                        ),
                        _SellerSignalChip(
                          icon: HugeIcons.strokeRoundedAlert02,
                          label:
                              'Risk ${viabilityRiskLabel(viability.deliveryRisk)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set a buyer price, share the product context, then place the supplier order when the buyer confirms.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColor.safe),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: AppColor.text,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => _shareProduct(context, state),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compactLabel = constraints.maxWidth < 110;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppHugeIcon(
                                  HugeIcons.strokeRoundedShare08,
                                  size: 18,
                                  color: AppColor.primary,
                                ),
                                SizedBox(width: compactLabel ? 4 : 8),
                                Flexible(
                                  child: Text(
                                    compactLabel ? 'Share' : 'Share product',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: compactLabel ? 12.5 : 13.5,
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
                  const SizedBox(width: 10),
                  Expanded(
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
                            : () async {
                                if (isCart) {
                                  CustomToast.info('Already in selling list');
                                } else {
                                  final sellPrice =
                                      await showResellerPriceSheet(
                                        context,
                                        product: common,
                                      );
                                  if (sellPrice == null || !context.mounted) {
                                    return;
                                  }
                                  await context.read<CartCubit>().addToCart(
                                    common,
                                    sellPrice: sellPrice,
                                  );
                                  CustomToast.info('Added to selling list');
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
                                        ? (compactLabel
                                              ? 'Listed'
                                              : 'In selling list')
                                        : (compactLabel
                                              ? 'List'
                                              : 'Add to list'),
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
                  const SizedBox(width: 10),
                  Expanded(
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
                                      minSellPrice: product.minResellPrice
                                          ?.round(),
                                      maxSellPrice: product.maxResellPrice
                                          ?.round(),
                                      thumbnail:
                                          product.thumbnail ??
                                          product.images.firstOrNull?.image,
                                      title:
                                          product.translation ??
                                          product.title ??
                                          '',
                                      id: product.id ?? 0,
                                    ),
                                  ),
                                );
                              },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compactLabel = constraints.maxWidth < 116;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppHugeIcon(
                                  HugeIcons.strokeRoundedZap,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: compactLabel ? 4 : 8),
                                Flexible(
                                  child: Text(
                                    compactLabel ? 'Order' : 'Quick order',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: compactLabel ? 13 : 15,
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
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SellerSignalChip extends StatelessWidget {
  const _SellerSignalChip({required this.icon, required this.label});

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppHugeIcon(icon, size: 14, color: AppColor.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
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
