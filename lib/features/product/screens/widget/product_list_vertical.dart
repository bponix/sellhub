import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/store/store_industry.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';

import '../../../../core/constants/app_color.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../cart/screens/checkout_screen.dart';
import '../../../favourite/presentation/cubit/favourite_cubit.dart';
import '../../../favourite/presentation/cubit/favourite_state.dart';
import '../../../storefront/presentation/cubit/storefront_cubit.dart';
import '../../data/models/product_res_common.dart';
import '../product_details_screen.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.industry,
    this.emphasizeImage = false,
    this.denseMode = false,
  });

  final ProductResCommon product;
  final StoreIndustryKind industry;
  final bool emphasizeImage;
  final bool denseMode;

  String get _displayTitle =>
      product.translation ?? product.title ?? 'Unknown title';
  bool get _hasSavings => (product.comparePrice ?? 0) > (product.price ?? 0);
  int get _saveAmount => _hasSavings
      ? ((product.comparePrice ?? 0) - (product.price ?? 0)).round()
      : 0;
  int _cartQuantity(CartState state) {
    for (final item in state.items) {
      if (item.product.id == product.id) {
        return item.quantity;
      }
    }
    return 0;
  }

  String _compactInfoLabel() {
    if (_hasSavings) {
      return 'Save ৳${convertToBengaliNumber(_saveAmount)}';
    }
    return (product.quantity ?? 0) > 0 ? 'In stock' : 'Check stock';
  }

  Color get _availabilityColor =>
      (product.quantity ?? 0) > 0 ? const Color(0xFF2D7A46) : AppColor.neutral2;

  @override
  Widget build(BuildContext context) {
    final productId = product.id;
    final productHid = product.hid?.trim();
    final discount = product.discount;
    final imageUrl =
        product.thumbnail ??
        (product.images.isNotEmpty ? product.images.first.image : '');
    final visualCatalog = StoreIndustry.isVisualCatalog(industry);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactCard = denseMode || constraints.maxWidth < 170;
        final mediaHeight = constraints.maxWidth;
        return GestureDetector(
          onTap: productHid == null || productHid.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    ProductDetailsScreen.route(
                      hid: productHid,
                      product: product,
                    ),
                  );
                },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compactCard ? 16.r : 22.r),
              boxShadow: [
                BoxShadow(
                  color: compactCard
                      ? AppColor.safe.withValues(alpha: 0.28)
                      : AppColor.safe.withValues(alpha: 0.22),
                  blurRadius: compactCard ? 18 : 22,
                  offset: Offset(0, compactCard ? 8 : 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: mediaHeight,
                  child: Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          emphasizeImage ? 8 : 9,
                          emphasizeImage ? 8 : 9,
                          emphasizeImage ? 8 : 9,
                          compactCard ? 9 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.safe1,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, AppColor.safe1],
                          ),
                          borderRadius: BorderRadius.circular(
                            compactCard ? 16 : 20,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            compactCard ? 16 : 20,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(emphasizeImage ? 0 : 0),
                            child: AppNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              backgroundColor: AppColor.safe1,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: BlocBuilder<FavouriteCubit, FavouriteState>(
                          builder: (context, favourites) {
                            final isFav =
                                productId != null &&
                                favourites.favoriteIds.contains(productId);
                            return GestureDetector(
                              onTap: () => context
                                  .read<FavouriteCubit>()
                                  .toggleFavourite(product),
                              child: Container(
                                padding: EdgeInsets.all(compactCard ? 4 : 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: compactCard
                                      ? null
                                      : Border.all(color: AppColor.safe),
                                ),
                                child: AppHugeIcon(
                                  HugeIcons.strokeRoundedFavourite,
                                  size: 15,
                                  color: isFav ? Colors.red : AppColor.neutral2,
                                  secondaryColor: isFav
                                      ? Colors.red.withValues(alpha: 0.18)
                                      : null,
                                  semanticLabel: isFav
                                      ? 'Remove from favourites'
                                      : 'Add to favourites',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (product.brands.isNotEmpty)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 92),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColor.safe.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Text(
                              product.brands.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: const TextStyle(
                                color: AppColor.text,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if ((discount ?? 0) != 0)
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.text,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'OFF ${discount!.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compactCard ? 9 : 11,
                      compactCard ? 7 : 8,
                      compactCard ? 9 : 11,
                      compactCard ? 8 : 9,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final denseCompact = compactCard;
                        final mediumCompact = constraints.maxHeight < 128;
                        final ultraCompact = constraints.maxHeight < 112;
                        final roomyCard = constraints.maxHeight > 144;
                        final verticalGap = ultraCompact
                            ? 2.0
                            : denseCompact
                            ? 3.0
                            : 4.0;
                        final actionHeight = ultraCompact
                            ? 26.0
                            : denseCompact
                            ? 28.0
                            : 32.0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: ultraCompact
                                  ? 28
                                  : denseCompact
                                  ? 30
                                  : 32,
                              child: Text(
                                _displayTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: ultraCompact
                                      ? 10.4.sp
                                      : denseCompact
                                      ? 10.8.sp
                                      : 12.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColor.text,
                                  height: ultraCompact
                                      ? 1.1
                                      : denseCompact
                                      ? 1.15
                                      : 1.2,
                                ),
                              ),
                            ),
                            SizedBox(height: verticalGap),
                            SizedBox(
                              height: ultraCompact
                                  ? 17
                                  : denseCompact
                                  ? 17
                                  : 18,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '৳ ${convertToBengaliNumber(product.price?.toInt() ?? 0)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: ultraCompact
                                            ? 11.8.sp
                                            : denseCompact
                                            ? 12.sp
                                            : 14.sp,
                                        color: AppColor.text,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  if (_hasSavings && !denseCompact) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '৳ ${convertToBengaliNumber(product.comparePrice?.toInt() ?? 0)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: AppColor.neutral1,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: verticalGap),
                            SizedBox(
                              height: ultraCompact
                                  ? 14
                                  : denseCompact
                                  ? 16
                                  : 18,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: denseCompact
                                    ? Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: _availabilityColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              _compactInfoLabel(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColor.neutral2,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: ultraCompact
                                                        ? 9.2
                                                        : 10,
                                                    height: 1.0,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        child: Row(
                                          children: [
                                            if (_saveAmount > 0)
                                              _InfoChip(
                                                label:
                                                    'Save ৳${convertToBengaliNumber(_saveAmount)}',
                                              ),
                                            if (_saveAmount > 0)
                                              const SizedBox(width: 6),
                                            _InfoChip(
                                              label: (product.quantity ?? 0) > 0
                                                  ? 'In stock'
                                                  : 'Check stock',
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColor.safe1,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                _hasSavings
                                                    ? 'Quick buy'
                                                    : 'Ready',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: AppColor.primary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 9.2,
                                                      height: 1.0,
                                                    ),
                                              ),
                                            ),
                                            if (_saveAmount > 0) ...[
                                              const SizedBox(width: 6),
                                            ],
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            if (!mediumCompact && roomyCard) const Spacer(),
                            SizedBox(height: verticalGap),
                            BlocBuilder<CartCubit, CartState>(
                              builder: (context, cartState) {
                                final quantity = _cartQuantity(cartState);
                                final currentItem = quantity > 0
                                    ? cartState.items.firstWhere(
                                        (item) => item.product.id == product.id,
                                      )
                                    : null;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          final int cp =
                                              product.comparePrice?.toInt() ??
                                              0;
                                          final int p =
                                              product.price?.toInt() ?? 0;
                                          final save = cp > p ? (cp - p) : 0;
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CheckoutScreen(
                                                    isCart: false,
                                                    comparePrice: product
                                                        .comparePrice
                                                        ?.toInt(),
                                                    payPrice: product.price
                                                        ?.toInt(),
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
                                        child: Container(
                                          height: actionHeight,
                                          decoration: BoxDecoration(
                                            color: denseCompact
                                                ? AppColor.safe1
                                                : AppColor.text,
                                            borderRadius: BorderRadius.circular(
                                              denseCompact
                                                  ? 10.r
                                                  : compactCard
                                                  ? 10.r
                                                  : 12.r,
                                            ),
                                            border: Border.all(
                                              color: denseCompact
                                                  ? AppColor.safe.withValues(
                                                      alpha: 0.72,
                                                    )
                                                  : AppColor.text,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              visualCatalog
                                                  ? 'View product'
                                                  : denseCompact
                                                  ? 'Buy'
                                                  : 'Buy Now',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: denseCompact
                                                    ? 8.8
                                                    : compactCard
                                                    ? 9
                                                    : 10.2,
                                                color: denseCompact
                                                    ? AppColor.primary
                                                    : Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: denseCompact
                                          ? 6
                                          : compactCard
                                          ? 6
                                          : 8,
                                    ),
                                    quantity > 0 && currentItem != null
                                        ? Container(
                                            height: actionHeight,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: denseCompact
                                                  ? 4
                                                  : compactCard
                                                  ? 4
                                                  : 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    denseCompact
                                                        ? 12.r
                                                        : compactCard
                                                        ? 12.r
                                                        : 14.r,
                                                  ),
                                              border: denseCompact
                                                  ? null
                                                  : Border.all(
                                                      color: AppColor.safe,
                                                    ),
                                            ),
                                            child: Row(
                                              children: [
                                                InkWell(
                                                  onTap: () => context
                                                      .read<CartCubit>()
                                                      .updateQuantity(
                                                        currentItem,
                                                        quantity - 1,
                                                      ),
                                                  child: AppHugeIcon(
                                                    HugeIcons
                                                        .strokeRoundedMinusSign,
                                                    size: denseCompact
                                                        ? 13
                                                        : compactCard
                                                        ? 13
                                                        : 14,
                                                    color: AppColor.text,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: denseCompact
                                                        ? 6
                                                        : compactCard
                                                        ? 6
                                                        : 8,
                                                  ),
                                                  child: Text(
                                                    '$quantity',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () => context
                                                      .read<CartCubit>()
                                                      .addToCart(product),
                                                  child: AppHugeIcon(
                                                    HugeIcons
                                                        .strokeRoundedPlusSign,
                                                    size: denseCompact
                                                        ? 13
                                                        : compactCard
                                                        ? 13
                                                        : 14,
                                                    color: AppColor.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              context
                                                  .read<CartCubit>()
                                                  .addToCart(product);
                                            },
                                            child: Container(
                                              width: actionHeight,
                                              height: actionHeight,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDFF55A),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      denseCompact
                                                          ? 10.r
                                                          : compactCard
                                                          ? 10.r
                                                          : 12.r,
                                                    ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFFDFF55A,
                                                    ).withValues(alpha: 0.35),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: AppHugeIcon(
                                                  HugeIcons
                                                      .strokeRoundedPlusSign,
                                                  size: denseCompact
                                                      ? 14
                                                      : compactCard
                                                      ? 14
                                                      : 15,
                                                  color: AppColor.text,
                                                  semanticLabel: 'Add to cart',
                                                ),
                                              ),
                                            ),
                                          ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProductListViewVerical extends StatelessWidget {
  const ProductListViewVerical({
    super.key,
    required this.products,
    this.forceTwoColumns = false,
    this.emphasizeImage = false,
    this.denseMode = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  });

  final List<ProductResCommon> products;
  final bool forceTwoColumns;
  final bool emphasizeImage;
  final bool denseMode;
  final EdgeInsets padding;

  int _crossAxisCountForWidth(double width) {
    return width < 360 ? 2 : 3;
  }

  double _childAspectRatioFor({
    required double width,
    required bool visualCatalog,
  }) {
    final crossAxisCount = _crossAxisCountForWidth(width);
    if (crossAxisCount == 2) {
      if (denseMode) {
        return visualCatalog ? 0.63 : 0.61;
      }
      return visualCatalog ? 0.59 : 0.57;
    }
    if (denseMode) {
      return visualCatalog ? 0.49 : 0.47;
    }
    return visualCatalog ? 0.45 : 0.43;
  }

  @override
  Widget build(BuildContext context) {
    final industry = StoreIndustry.fromRaw(
      context.select<StorefrontCubit, Object?>(
        (cubit) => cubit.state.siteDetails?.industry,
      ),
    );
    final visualCatalog = StoreIndustry.isVisualCatalog(industry);
    return products.isNotEmpty
        ? LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = forceTwoColumns
                  ? 2
                  : _crossAxisCountForWidth(constraints.maxWidth);
              final childAspectRatio = forceTwoColumns
                  ? denseMode
                        ? (visualCatalog ? 0.63 : 0.61)
                        : (visualCatalog ? 0.59 : 0.57)
                  : _childAspectRatioFor(
                      width: constraints.maxWidth,
                      visualCatalog: visualCatalog,
                    );
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  padding.left.w,
                  padding.top.h,
                  padding.right.w,
                  padding.bottom.h,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 12.h,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: products[index],
                    industry: industry,
                    emphasizeImage: emphasizeImage,
                    denseMode: denseMode,
                  );
                },
              );
            },
          )
        : const _EmptyStateWidget(); // use separate widget for cleaning
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColor.neutral2,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          height: 1.0,
        ),
      ),
    );
  }
}

class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({super.key, required this.products});

  final List<ProductResCommon> products;

  int _crossAxisCountForWidth(double width) {
    return width < 360 ? 2 : 3;
  }

  double _childAspectRatioFor({
    required double width,
    required bool visualCatalog,
  }) {
    final crossAxisCount = _crossAxisCountForWidth(width);
    if (crossAxisCount == 2) {
      return visualCatalog ? 0.56 : 0.54;
    }
    return visualCatalog ? 0.42 : 0.4;
  }

  @override
  Widget build(BuildContext context) {
    final industry = StoreIndustry.fromRaw(
      context.select<StorefrontCubit, Object?>(
        (cubit) => cubit.state.siteDetails?.industry,
      ),
    );
    final visualCatalog = StoreIndustry.isVisualCatalog(industry);
    return products.isNotEmpty
        ? SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _crossAxisCountForWidth(
                  constraints.crossAxisExtent,
                );
                final childAspectRatio = _childAspectRatioFor(
                  width: constraints.crossAxisExtent,
                  visualCatalog: visualCatalog,
                );
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 12.h,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return ProductCard(
                      product: products[index],
                      industry: industry,
                    );
                  }, childCount: products.length),
                );
              },
            ),
          )
        : SliverToBoxAdapter(child: _EmptyStateWidget());
  }
}

// empty screen make clean
class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          AppHugeIcon(
            HugeIcons.strokeRoundedShoppingBag02,
            size: 80.r,
            color: AppColor.neutral1,
          ),
          const SizedBox(height: 12),
          const Text('No Item Found', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
