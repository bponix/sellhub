import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/store/store_industry.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';

import '../../../../core/constants/app_color.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../cart/screens/checkout_screen.dart';
import '../../../cart/screens/widget/reseller_price_sheet.dart';
import '../../../favourite/presentation/cubit/favourite_cubit.dart';
import '../../../favourite/presentation/cubit/favourite_state.dart';
import '../../../storefront/presentation/cubit/storefront_cubit.dart';
import '../../data/models/product_res_common.dart';
import '../product_details_screen.dart';

class _RailCardPreset {
  const _RailCardPreset({
    required this.mediaHeight,
    required this.bodyHeight,
    required this.cardRadius,
    required this.innerPadding,
    required this.topPadding,
    required this.titleHeight,
    required this.titleFontSize,
    required this.titleLineHeight,
    required this.priceHeight,
    required this.priceFontSize,
    required this.infoHeight,
    required this.infoFontSize,
    required this.specHeight,
    required this.specFontSize,
    required this.actionHeight,
    required this.buttonFontSize,
    required this.verticalGap,
    required this.showSpecRow,
    required this.showInfoRow,
    required this.showComparePrice,
    required this.showActionLead,
    required this.tightChrome,
  });

  final double mediaHeight;
  final double bodyHeight;
  final double cardRadius;
  final double innerPadding;
  final double topPadding;
  final double titleHeight;
  final double titleFontSize;
  final double titleLineHeight;
  final double priceHeight;
  final double priceFontSize;
  final double infoHeight;
  final double infoFontSize;
  final double specHeight;
  final double specFontSize;
  final double actionHeight;
  final double buttonFontSize;
  final double verticalGap;
  final bool showSpecRow;
  final bool showInfoRow;
  final bool showComparePrice;
  final bool showActionLead;
  final bool tightChrome;
}

class ProductListViewHorizontal extends StatelessWidget {
  final ScrollController? scrollController;
  const ProductListViewHorizontal({
    super.key,
    required this.products,
    this.scrollController,
    this.visibleCountOverride,
    this.horizontalInset = 16,
  });

  final List<ProductResCommon> products;
  final int? visibleCountOverride;
  final double horizontalInset;

  String _displayTitle(ProductResCommon product) =>
      product.translation ?? product.title ?? 'Unknown title';

  bool _hasSavings(ProductResCommon product) =>
      (product.comparePrice ?? 0) > (product.price ?? 0);

  String _compactInfoLabel(ProductResCommon product) {
    if (_hasSavings(product)) {
      final save = ((product.comparePrice ?? 0) - (product.price ?? 0)).round();
      return 'Save ৳${convertToBengaliNumber(save)}';
    }
    return (product.quantity ?? 0) > 0 ? 'In stock' : 'Check stock';
  }

  String _decisionLabel(ProductViabilityProfile viability, bool compactRail) {
    final margin = viability.minMargin.round();
    if (compactRail) {
      return '৳${convertToBengaliNumber(margin)} • T${viability.trustScore.round()}';
    }
    return 'Margin ৳${convertToBengaliNumber(margin)} • Share ${viability.shareabilityScore.round()}';
  }

  String _heroTag(ProductViabilityProfile viability) {
    if (viability.deliveryRisk == ViabilityRiskLevel.high) {
      return 'Watch risk';
    }
    if (viability.shareabilityScore >= 72) {
      return 'Share-ready';
    }
    if (viability.minMargin >= 120) {
      return 'Margin pick';
    }
    return 'Seller check';
  }

  int _cartQuantity(CartState state, ProductResCommon product) {
    for (final item in state.items) {
      if (item.product.id == product.id) {
        return item.quantity;
      }
    }
    return 0;
  }

  Future<void> _handleAddToCart(
    BuildContext context,
    ProductResCommon product, {
    required bool alreadyInCart,
  }) async {
    if (alreadyInCart) {
      await context.read<CartCubit>().addToCart(product);
      return;
    }
    final sellPrice = await showResellerPriceSheet(context, product: product);
    if (sellPrice == null || !context.mounted) return;
    await context.read<CartCubit>().addToCart(product, sellPrice: sellPrice);
  }

  _RailCardPreset _presetFor({
    required bool compactRail,
    required bool visualCatalog,
  }) {
    if (compactRail) {
      return const _RailCardPreset(
        mediaHeight: 108,
        bodyHeight: 114,
        cardRadius: 16,
        innerPadding: 5,
        topPadding: 5,
        titleHeight: 20,
        titleFontSize: 9.8,
        titleLineHeight: 1.08,
        priceHeight: 14,
        priceFontSize: 10.8,
        infoHeight: 12,
        infoFontSize: 8.2,
        specHeight: 0,
        specFontSize: 0,
        actionHeight: 24,
        buttonFontSize: 8.2,
        verticalGap: 1,
        showSpecRow: false,
        showInfoRow: true,
        showComparePrice: false,
        showActionLead: false,
        tightChrome: true,
      );
    }

    return _RailCardPreset(
        mediaHeight: 146,
      bodyHeight: visualCatalog ? 114 : 114,
      cardRadius: 22,
      innerPadding: 12,
      topPadding: 10,
      titleHeight: 22,
      titleFontSize: 11.6,
      titleLineHeight: 1.18,
      priceHeight: 12,
      priceFontSize: 12.5,
      infoHeight: 0,
      infoFontSize: 9.6,
      specHeight: 0,
      specFontSize: 0,
      actionHeight: 24,
      buttonFontSize: 10.2,
      verticalGap: 4,
      showSpecRow: false,
      showInfoRow: false,
      showComparePrice: !visualCatalog,
      showActionLead: !visualCatalog,
      tightChrome: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final industry = StoreIndustry.fromRaw(
      context.select<StorefrontCubit, Object?>(
        (cubit) => cubit.state.siteDetails?.industry,
      ),
    );
    final visualCatalog = StoreIndustry.isVisualCatalog(industry);
    final viewportWidth =
        MediaQuery.sizeOf(context).width - (horizontalInset * 2);
    final visibleCount = (visibleCountOverride ?? (visualCatalog ? 2 : 3))
        .toDouble();
    final compactRail = visibleCount >= 3;
    final preset = _presetFor(
      compactRail: compactRail,
      visualCatalog: visualCatalog,
    );
    final tightRail = preset.tightChrome;
    final totalSpacing = visualCatalog ? 12.0 : 14.0;
    final cardWidth = (viewportWidth - totalSpacing) / visibleCount;
    final cardHeight = preset.mediaHeight + preset.bodyHeight;
    return products.isEmpty
        ? Center(child: Text('No Product Found'))
        : SizedBox(
            height: cardHeight,
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 6),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final productId = product.id;
                final productHid = product.hid?.trim();
                final viability = ProductViabilityEngine.build(product);
                final imageUrl =
                    product.thumbnail ??
                    (product.images.isNotEmpty
                        ? product.images.first.image
                        : '');
                return InkWell(
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
                  child: Container(
                    padding: EdgeInsets.only(
                      right: index == products.length - 1 ? 0 : 10,
                    ),
                    width: cardWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(preset.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: compactRail
                                ? AppColor.safe.withValues(alpha: 0.28)
                                : AppColor.safe.withValues(alpha: 0.22),
                            blurRadius: compactRail ? 18 : 22,
                            offset: Offset(0, compactRail ? 8 : 10),
                          ),
                        ],
                        border: tightRail
                            ? null
                            : Border.all(
                                color: AppColor.safe.withValues(alpha: 0.7),
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: preset.mediaHeight,
                            child: Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.fromLTRB(
                                    tightRail ? 0 : 8,
                                    tightRail ? 0 : 8,
                                    tightRail ? 0 : 8,
                                    tightRail ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.safe1,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.white, AppColor.safe1],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      tightRail ? 16 : 20,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      tightRail ? 16 : 20,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.zero,
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
                                  child:
                                      BlocBuilder<
                                        FavouriteCubit,
                                        FavouriteState
                                      >(
                                        builder: (context, favourites) {
                                          final isFav =
                                              productId != null &&
                                              favourites.favoriteIds.contains(
                                                productId,
                                              );
                                          return GestureDetector(
                                            onTap: () => context
                                                .read<FavouriteCubit>()
                                                .toggleFavourite(product),
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                compactRail ? 4 : 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: tightRail
                                                    ? null
                                                    : Border.all(
                                                        color: AppColor.safe,
                                                      ),
                                              ),
                                              child: AppHugeIcon(
                                                HugeIcons
                                                    .strokeRoundedFavourite,
                                                size: compactRail ? 14 : 15,
                                                color: isFav
                                                    ? Colors.red
                                                    : AppColor.neutral2,
                                                secondaryColor: isFav
                                                    ? Colors.red.withValues(
                                                        alpha: 0.18,
                                                      )
                                                    : null,
                                                semanticLabel: isFav
                                                    ? 'Remove from saved products'
                                                    : 'Add to saved products',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                ),
                                if (product.brands.isNotEmpty)
                                  Positioned(
                                    left: compactRail ? 6 : 8,
                                    top: compactRail ? 6 : 8,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth: tightRail ? 88 : 100,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: tightRail ? 7 : 9,
                                        vertical: tightRail ? 3.5 : 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.96,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: AppColor.safe.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        product.brands.first,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        style: TextStyle(
                                          color: AppColor.text,
                                          fontSize: tightRail ? 8.8 : 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  left: compactRail ? 6 : 8,
                                  bottom: compactRail ? 6 : 8,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: tightRail ? 82 : 108,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: tightRail ? 6 : 8,
                                      vertical: tightRail ? 3.5 : 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.96,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: viability.deliveryRisk ==
                                                ViabilityRiskLevel.high
                                            ? const Color(0xFFF1C9B8)
                                            : AppColor.safe.withValues(
                                                alpha: 0.75,
                                              ),
                                      ),
                                    ),
                                    child: Text(
                                      _heroTag(viability),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: viability.deliveryRisk ==
                                                ViabilityRiskLevel.high
                                            ? const Color(0xFFA85A2A)
                                            : AppColor.text,
                                        fontSize: tightRail ? 7.8 : 8.8,
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
                                preset.innerPadding,
                                preset.topPadding,
                                preset.innerPadding,
                                preset.innerPadding,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: preset.titleHeight,
                                        child: Text(
                                          _displayTitle(product),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: preset.titleFontSize.sp,
                                            fontWeight: FontWeight.w800,
                                            color: AppColor.text,
                                            height: preset.titleLineHeight,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: preset.verticalGap),
                                      SizedBox(
                                        height: preset.priceHeight,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '৳ ${convertToBengaliNumber(product.price?.toInt() ?? 0)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: preset.priceFontSize.sp,
                                                  color: AppColor.text,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            if (_hasSavings(product) &&
                                                preset.showComparePrice) ...[
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  '৳ ${convertToBengaliNumber(product.comparePrice?.toInt() ?? 0)}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 9.sp,
                                                    color: AppColor.neutral1,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (compactRail) ...[
                                        SizedBox(height: preset.verticalGap),
                                        SizedBox(
                                          height: 12,
                                          child: Text(
                                            _compactInfoLabel(product),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: preset.infoFontSize.sp,
                                              color: AppColor.neutral2,
                                              fontWeight: FontWeight.w700,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: preset.verticalGap),
                                      SizedBox(
                                        height: compactRail ? 12 : 14,
                                        child: Text(
                                          _decisionLabel(
                                            viability,
                                            compactRail,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize:
                                                (compactRail ? 7.9 : 8.8).sp,
                                            color: AppColor.primary,
                                            fontWeight: FontWeight.w800,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: preset.verticalGap),
                                      BlocBuilder<CartCubit, CartState>(
                                        builder: (context, cartState) {
                                          final quantity = _cartQuantity(
                                            cartState,
                                            product,
                                          );
                                          final currentItem = quantity > 0
                                              ? cartState.items.firstWhere(
                                                  (item) =>
                                                      item.product.id ==
                                                      product.id,
                                                )
                                              : null;
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: preset.actionHeight,
                                                  child: TextButton(
                                                    onPressed: () {
                                                      final int cp =
                                                          product.comparePrice
                                                              ?.toInt() ??
                                                          0;
                                                      final int p =
                                                          product.price
                                                              ?.toInt() ??
                                                          0;
                                                      final save = cp > p
                                                          ? (cp - p)
                                                          : 0;
                                                      Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CheckoutScreen(
                                                                isCart: false,
                                                                comparePrice: product
                                                                    .comparePrice
                                                                    ?.toInt(),
                                                                payPrice: product
                                                                    .price
                                                                    ?.toInt(),
                                                                savePrice: save,
                                                                minSellPrice: product
                                                                    .minResellPrice
                                                                    ?.round(),
                                                                maxSellPrice: product
                                                                    .maxResellPrice
                                                                    ?.round(),
                                                                thumbnail:
                                                                    product.thumbnail ??
                                                                    product.images.firstOrNull?.image,
                                                                title:
                                                                    product
                                                                        .translation ??
                                                                    product
                                                                        .title ??
                                                                    '',
                                                                id:
                                                                    product
                                                                        .id ??
                                                                    0,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    style: TextButton.styleFrom(
                                                      backgroundColor:
                                                          compactRail
                                                          ? AppColor.safe1
                                                          : AppColor.text,
                                                      foregroundColor:
                                                          compactRail
                                                          ? AppColor.primary
                                                          : Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                compactRail
                                                                ? 6
                                                                : 12,
                                                            vertical: 0,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              compactRail
                                                                  ? 9
                                                                  : 12,
                                                            ),
                                                        side: BorderSide(
                                                          color: compactRail
                                                              ? AppColor.safe
                                                                    .withValues(
                                                                      alpha:
                                                                          0.72,
                                                                    )
                                                              : AppColor.text,
                                                        ),
                                                      ),
                                                      minimumSize: const Size(
                                                        0,
                                                        0,
                                                      ),
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: Text(
                                                      visualCatalog
                                                          ? 'Open'
                                                          : compactRail
                                                          ? 'Order'
                                                          : 'Quick order',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: preset
                                                            .buttonFontSize,
                                                        color: compactRail
                                                            ? AppColor.primary
                                                            : Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 0.1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: compactRail ? 6 : 8,
                                              ),
                                              quantity > 0 &&
                                                      currentItem != null
                                                  ? Container(
                                                      height:
                                                          preset.actionHeight,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                compactRail
                                                                ? 3
                                                                : 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              compactRail
                                                                  ? 9
                                                                  : 12,
                                                            ),
                                                        border: tightRail
                                                            ? null
                                                            : Border.all(
                                                                color: AppColor
                                                                    .safe,
                                                              ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          InkWell(
                                                            onTap: () => context
                                                                .read<
                                                                  CartCubit
                                                                >()
                                                                .updateQuantity(
                                                                  currentItem,
                                                                  quantity - 1,
                                                                ),
                                                            child: AppHugeIcon(
                                                              HugeIcons
                                                                  .strokeRoundedMinusSign,
                                                              size: compactRail
                                                                  ? 12
                                                                  : 13,
                                                              color:
                                                                  AppColor.text,
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      compactRail
                                                                      ? 6
                                                                      : 8,
                                                                ),
                                                            child: Text(
                                                              '$quantity',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            ),
                                                          ),
                                                          InkWell(
                                                            onTap: () =>
                                                                _handleAddToCart(
                                                                  context,
                                                                  product,
                                                                  alreadyInCart:
                                                                      true,
                                                                ),
                                                            child: AppHugeIcon(
                                                              HugeIcons
                                                                  .strokeRoundedPlusSign,
                                                              size: compactRail
                                                                  ? 12
                                                                  : 13,
                                                              color: AppColor
                                                                  .primary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : Container(
                                                      width:
                                                          preset.actionHeight,
                                                      height:
                                                          preset.actionHeight,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFDFF55A,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              compactRail
                                                                  ? 9
                                                                  : 11,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color:
                                                                const Color(
                                                                  0xFFDFF55A,
                                                                ).withValues(
                                                                  alpha: 0.35,
                                                                ),
                                                            blurRadius: 10,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  4,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: GestureDetector(
                                                        onTap: () =>
                                                            _handleAddToCart(
                                                              context,
                                                              product,
                                                              alreadyInCart:
                                                                  false,
                                                            ),
                                                        child: Center(
                                                          child: AppHugeIcon(
                                                            HugeIcons
                                                                .strokeRoundedPlusSign,
                                                            size: compactRail
                                                                ? 13
                                                                : 15,
                                                            color:
                                                                AppColor.text,
                                                            semanticLabel:
                                                                'Add to selling list',
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
                  ),
                );
              },
            ),
          );
  }
}
