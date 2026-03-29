import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/features/product/screens/new_arrival_product.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';
import 'package:sellhub/features/product/screens/widget/product_list_vertical.dart';
import 'package:sellhub/features/product/screens/widget/product_list_view_horizontal.dart';
import 'package:sellhub/features/categories/screen/sub_category_products_screen.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_state.dart';

class AllPartHomePage extends StatelessWidget {
  const AllPartHomePage({
    super.key,
    required this.flashSaleController,
    required this.newArrivalController,
    required this.storefrontState,
  });

  final ScrollController flashSaleController;
  final ScrollController newArrivalController;
  final StorefrontState storefrontState;

  static const double _sectionGap = 20;
  static const double _blockGap = 12;

  @override
  Widget build(BuildContext context) {
    const visibleCount = 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PromoPercentRail(),
        const SizedBox(height: _sectionGap),
        if (storefrontState.topBrand.isNotEmpty) ...[
          _SectionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLead(
                  icon: HugeIcons.strokeRoundedAward01,
                  title: 'Brands',
                  badge: storefrontState.topBrand.length.toString(),
                ),
                const SizedBox(height: _blockGap),
                _TwoRowBrandRail(brands: storefrontState.topBrand),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
        ],
        if (storefrontState.newArrival.isNotEmpty) ...[
          _SectionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLead(
                  icon: HugeIcons.strokeRoundedSparkles,
                  title: 'New',
                  badge: storefrontState.newArrival.length.toString(),
                  onTap: () {
                    context.read<StorefrontCubit>().fetchNewArrival(
                      StoreScope.siteIdFromState(storefrontState),
                      16,
                      0,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NewArrivalProductScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: _blockGap),
                ProductListViewHorizontal(
                  products: storefrontState.newArrival,
                  scrollController: newArrivalController,
                  visibleCountOverride: visibleCount,
                  horizontalInset: 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
        ],
        if (storefrontState.products.isNotEmpty) ...[
          _SectionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLead(
                  icon: HugeIcons.strokeRoundedFire,
                  title: 'Trending',
                  badge: storefrontState.products.length.toString(),
                ),
                const SizedBox(height: _blockGap),
                ProductListViewHorizontal(
                  products: storefrontState.products
                      .take(12)
                      .toList(growable: false),
                  scrollController: flashSaleController,
                  visibleCountOverride: visibleCount,
                  horizontalInset: 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
        ],
        ..._buildCategorySections(context, visibleCount),
        if (storefrontState.products.isNotEmpty) ...[
          _SectionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLead(
                  icon: HugeIcons.strokeRoundedShoppingBag01,
                  title: 'More to explore',
                  badge: storefrontState.products.length.toString(),
                ),
                const SizedBox(height: _blockGap),
                ProductListViewVerical(
                  products: storefrontState.products,
                  emphasizeImage: true,
                  denseMode: true,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
        ],
      ],
    );
  }

  List<Widget> _buildCategorySections(BuildContext context, int visibleCount) {
    final sections = storefrontState.allCategory
        .where((category) => category.id != null)
        .map((category) {
          final categoryId = category.id!;
          final products = storefrontState.homeCategoryProducts[categoryId];
          if (products == null || products.length <= 3) {
            return null;
          }
          final title = (category.translation?.trim().isNotEmpty ?? false)
              ? category.translation!.trim()
              : (category.title ?? 'Category');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLead(
                      icon: HugeIcons.strokeRoundedShoppingBag02,
                      title: title,
                      badge: products.length.toString(),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SubCategoryProductsScreen(
                              subCategoryId: -1,
                              title: title,
                              seeAll: true,
                              categoryId: categoryId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: _blockGap),
                    ProductListViewHorizontal(
                      products: products.take(12).toList(growable: false),
                      visibleCountOverride: visibleCount,
                      horizontalInset: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _sectionGap),
            ],
          );
        })
        .whereType<Widget>()
        .toList(growable: false);

    if (sections.isEmpty && storefrontState.homeCategoryLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ];
    }

    return sections;
  }
}

class _PromoPercentRail extends StatelessWidget {
  const _PromoPercentRail();

  static const List<int> _percents = <int>[20, 25, 30, 40, 50, 60];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _percents
            .map(
              (value) {
                final tint = switch (value) {
                  20 => const Color(0xFFF4FAE2),
                  25 => const Color(0xFFFFF3E7),
                  30 => const Color(0xFFEAF7F5),
                  40 => const Color(0xFFF8F1FF),
                  50 => const Color(0xFFFFF1F1),
                  _ => const Color(0xFFEEF7FF),
                };
                return Container(
                width: 118,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColor.safe),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Offer',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColor.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const AppHugeIcon(
                        HugeIcons.strokeRoundedDiscountTag01,
                        size: 16,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$value%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColor.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Save more',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Today picks',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
              },
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _TwoRowBrandRail extends StatelessWidget {
  const _TwoRowBrandRail({required this.brands});

  final List<TopBrandRes> brands;

  @override
  Widget build(BuildContext context) {
    final brandChunks = <List<TopBrandRes>>[];
    for (var index = 0; index < brands.length; index += 10) {
      final end = index + 10 < brands.length ? index + 10 : brands.length;
      brandChunks.add(brands.sublist(index, end));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: brandChunks.map((chunk) {
          final firstRow = chunk.take(5).toList(growable: false);
          final secondRow = chunk.skip(5).toList(growable: false);
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColor.safe),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: firstRow
                        .map((brand) => _BrandTile(brand: brand))
                        .toList(growable: false),
                  ),
                  if (secondRow.isNotEmpty) const SizedBox(height: 10),
                  if (secondRow.isNotEmpty)
                    Row(
                      children: secondRow
                          .map((brand) => _BrandTile(brand: brand))
                          .toList(growable: false),
                    ),
                ],
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.brand});

  final TopBrandRes brand;

  @override
  Widget build(BuildContext context) {
    final brandId = brand.id;
    final title = (brand.translation?.trim().isNotEmpty ?? false)
        ? brand.translation!.trim()
        : (brand.title ?? 'Brand');
    return InkWell(
      onTap: brandId == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubCategoryProductsScreen(
                    subCategoryId: -1,
                    title: title,
                    seeAll: false,
                    categoryId: -1,
                    brandId: brandId,
                  ),
                ),
              );
            },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 74,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColor.safe),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppNetworkImage(
                  imageUrl: brand.image,
                  fit: BoxFit.cover,
                  backgroundColor: AppColor.safe1,
                  icon: HugeIcons.strokeRoundedStore03,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColor.safe),
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
    );
  }
}

class _SectionLead extends StatelessWidget {
  const _SectionLead({
    required this.icon,
    required this.title,
    this.badge,
    this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColor.safe),
          ),
          child: AppHugeIcon(icon, size: 16, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColor.text,
                ),
              ),
            ],
          ),
        ),
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const SizedBox(width: 6),
        ],
        if (onTap != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColor.safe),
              ),
              child: const AppHugeIcon(
                HugeIcons.strokeRoundedArrowRight02,
                size: 16,
                color: AppColor.primary,
              ),
            ),
          ),
      ],
    );
  }
}
