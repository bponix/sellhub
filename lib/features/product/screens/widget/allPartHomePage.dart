import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/features/categories/screen/sub_category_products_screen.dart';
import 'package:sellhub/features/product/screens/new_arrival_product.dart';
import 'package:sellhub/features/product/screens/widget/product_list_vertical.dart';
import 'package:sellhub/features/product/screens/widget/product_list_view_horizontal.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_state.dart';

class AllPartHomePage extends StatelessWidget {
  const AllPartHomePage({
    super.key,
    required this.flashSaleController,
    required this.newArrivalController,
    required this.storefrontState,
    this.discoveryFocus = 'all',
  });

  final ScrollController flashSaleController;
  final ScrollController newArrivalController;
  final StorefrontState storefrontState;
  final String discoveryFocus;

  static const double _sectionGap = 20;
  static const double _blockGap = 12;

  @override
  Widget build(BuildContext context) {
    const visibleCount = 2;
    final allProducts = storefrontState.products;
    final whatsappProducts = applyProductViability(
      allProducts,
      filter: ProductViabilityFilter.goodMargin,
      sort: ProductViabilitySort.highestMargin,
    );
    final codProducts = applyProductViability(
      allProducts,
      filter: ProductViabilityFilter.beginnerFriendly,
      sort: ProductViabilitySort.lowestRisk,
    );
    final repeatProducts = applyProductViability(
      allProducts,
      filter: ProductViabilityFilter.highRepeatPotential,
      sort: ProductViabilitySort.highRepeatPotential,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allProducts.isNotEmpty) ...[
          _DiscoveryMomentumStrip(chips: _chipsForFocus()),
          const SizedBox(height: _sectionGap),
          const _ResellerTaskRail(),
          const SizedBox(height: _sectionGap),
          const _ResellerTaskRail(
            title: 'Student / housewife / social queue',
            subtitle:
                'Use the fastest BD-friendly moves for side-hustle sellers.',
            tasks: [
              _ResellerTaskItem(
                title: 'Student sprint',
                subtitle: 'Check quick COD replies between classes',
                icon: HugeIcons.strokeRoundedInvoice03,
                onTapRoute: _ResellerTaskRoute.orders,
              ),
              _ResellerTaskItem(
                title: 'Housewife repeat',
                subtitle: 'Warm buyer book for neighbour reorders',
                icon: HugeIcons.strokeRoundedUserGroup,
                onTapRoute: _ResellerTaskRoute.buyers,
              ),
              _ResellerTaskItem(
                title: 'Social repost',
                subtitle: 'Push saved winners back to Facebook and WhatsApp',
                icon: HugeIcons.strokeRoundedFavourite,
                onTapRoute: _ResellerTaskRoute.saved,
              ),
              _ResellerTaskItem(
                title: 'Cash-out check',
                subtitle: 'Track payout before the next buying cycle',
                icon: HugeIcons.strokeRoundedWallet02,
                onTapRoute: _ResellerTaskRoute.payouts,
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
        ],
        if (_showWhatsAppRail && whatsappProducts.isNotEmpty) ...[
          _SectionLead(
            title: discoveryFocus == 'whatsapp'
                ? 'WhatsApp quick sell'
                : 'WhatsApp-ready picks',
          ),
          const SizedBox(height: _blockGap),
          ProductListViewHorizontal(
            products: whatsappProducts.take(12).toList(growable: false),
            scrollController: flashSaleController,
            visibleCountOverride: visibleCount,
            horizontalInset: 0,
          ),
          const SizedBox(height: _sectionGap),
        ],
        if (_showCodRail && codProducts.isNotEmpty) ...[
          _SectionLead(
            title: discoveryFocus == 'cod'
                ? 'COD-friendly picks'
                : 'Lower-risk COD picks',
          ),
          const SizedBox(height: _blockGap),
          ProductListViewHorizontal(
            products: codProducts.take(12).toList(growable: false),
            scrollController: flashSaleController,
            visibleCountOverride: visibleCount,
            horizontalInset: 0,
          ),
          const SizedBox(height: _sectionGap),
        ],
        if (storefrontState.flashSale.isNotEmpty) ...[
          _SectionLead(title: _fastMoverTitle),
          const SizedBox(height: _blockGap),
          ProductListViewHorizontal(
            products: storefrontState.flashSale
                .take(12)
                .toList(growable: false),
            scrollController: flashSaleController,
            visibleCountOverride: visibleCount,
            horizontalInset: 0,
          ),
          const SizedBox(height: _sectionGap),
        ],
        if (storefrontState.products.isNotEmpty) ...[
          _SectionLead(title: _easySellTitle),
          const SizedBox(height: _blockGap),
          ProductListViewHorizontal(
            products: storefrontState.products.take(12).toList(growable: false),
            scrollController: flashSaleController,
            visibleCountOverride: visibleCount,
            horizontalInset: 0,
          ),
          const SizedBox(height: _sectionGap),
        ],
        if (storefrontState.newArrival.isNotEmpty) ...[
          _SectionLead(
            title: 'New supplier drops',
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
          const SizedBox(height: _sectionGap),
        ],
        if (_showRepeatRail && repeatProducts.isNotEmpty) ...[
          _SectionLead(
            title: discoveryFocus == 'repeat'
                ? 'Repeat buyer picks'
                : 'Easy to repost',
          ),
          const SizedBox(height: _blockGap),
          ProductListViewHorizontal(
            products: repeatProducts.take(12).toList(growable: false),
            visibleCountOverride: visibleCount,
            horizontalInset: 0,
          ),
          const SizedBox(height: _sectionGap),
        ],
        ..._buildCategorySections(context, visibleCount),
        if (storefrontState.products.isNotEmpty) ...[
          const _SectionLead(title: 'All products'),
          const SizedBox(height: _blockGap),
          ProductListViewVerical(
            products: storefrontState.products,
            emphasizeImage: true,
            denseMode: true,
            padding: EdgeInsets.zero,
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
              _SectionLead(
                title: title,
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

  List<_DiscoveryChipData> _chipsForFocus() {
    const base = <String, _DiscoveryChipData>{
      'all': _DiscoveryChipData(title: 'All', subtitle: 'Compact browse'),
      'whatsapp': _DiscoveryChipData(
        title: 'WhatsApp',
        subtitle: 'Quick replies',
      ),
      'facebook': _DiscoveryChipData(title: 'Facebook', subtitle: 'Post-ready'),
      'cod': _DiscoveryChipData(title: 'COD', subtitle: 'Low promise risk'),
      'lowRisk': _DiscoveryChipData(
        title: 'Low risk',
        subtitle: 'Safer fulfilment',
      ),
      'goodMargin': _DiscoveryChipData(
        title: 'Margin',
        subtitle: 'Better spread',
      ),
      'repeat': _DiscoveryChipData(
        title: 'Repeat',
        subtitle: 'Neighbour demand',
      ),
    };
    final ordered = {
      discoveryFocus,
      'whatsapp',
      'facebook',
      'cod',
      'goodMargin',
      'repeat',
    };
    return ordered
        .map((key) => base[key] ?? base['all']!)
        .take(4)
        .toList(growable: false);
  }

  bool get _showWhatsAppRail =>
      discoveryFocus == 'all' ||
      discoveryFocus == 'whatsapp' ||
      discoveryFocus == 'facebook' ||
      discoveryFocus == 'goodMargin';

  bool get _showCodRail =>
      discoveryFocus == 'all' ||
      discoveryFocus == 'cod' ||
      discoveryFocus == 'lowRisk';

  bool get _showRepeatRail =>
      discoveryFocus == 'all' ||
      discoveryFocus == 'repeat' ||
      discoveryFocus == 'facebook';

  String get _fastMoverTitle {
    switch (discoveryFocus) {
      case 'facebook':
        return 'Facebook fast movers';
      case 'goodMargin':
        return 'Fast margin movers';
      case 'whatsapp':
        return 'Chat-close fast movers';
      default:
        return 'Fast movers';
    }
  }

  String get _easySellTitle {
    switch (discoveryFocus) {
      case 'facebook':
        return 'Facebook winners';
      case 'cod':
        return 'COD-friendly picks';
      case 'lowRisk':
        return 'Lower-risk picks';
      case 'goodMargin':
        return 'Good margin picks';
      case 'repeat':
        return 'Neighbour-demand picks';
      default:
        return 'Easy to sell';
    }
  }
}

enum _ResellerTaskRoute { sellingList, orders, buyers, payouts, saved }

class _ResellerTaskRail extends StatelessWidget {
  const _ResellerTaskRail({
    this.title = 'Reseller quick queue',
    this.subtitle = 'Start with the work that closes buyers fastest today.',
    this.tasks = const [
      _ResellerTaskItem(
        title: 'Launch quick order',
        subtitle: 'Open sell list and send quote fast',
        icon: HugeIcons.strokeRoundedShoppingBag01,
        onTapRoute: _ResellerTaskRoute.sellingList,
      ),
      _ResellerTaskItem(
        title: 'Order queue',
        subtitle: 'Review placed and pending orders',
        icon: HugeIcons.strokeRoundedInvoice03,
        onTapRoute: _ResellerTaskRoute.orders,
      ),
      _ResellerTaskItem(
        title: 'Buyer book',
        subtitle: 'Follow up with repeat and warm leads',
        icon: HugeIcons.strokeRoundedUserGroup,
        onTapRoute: _ResellerTaskRoute.buyers,
      ),
    ],
  });

  final String title;
  final String subtitle;
  final List<_ResellerTaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColor.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColor.neutral2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tasks
                .map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _ResellerTaskCard(task: task),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _ResellerTaskItem {
  const _ResellerTaskItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTapRoute,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final _ResellerTaskRoute onTapRoute;
}

class _ResellerTaskCard extends StatelessWidget {
  const _ResellerTaskCard({required this.task});

  final _ResellerTaskItem task;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openTask(context, task.onTapRoute),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.safe),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppHugeIcon(task.icon, size: 18, color: AppColor.primary),
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTask(BuildContext context, _ResellerTaskRoute route) {
    switch (route) {
      case _ResellerTaskRoute.sellingList:
        AppRouter.goToSellingList(context);
        return;
      case _ResellerTaskRoute.orders:
        AppRouter.goToOrders(context);
        return;
      case _ResellerTaskRoute.buyers:
        AppRouter.goToBuyerBook(context);
        return;
      case _ResellerTaskRoute.payouts:
        AppRouter.goToPayouts(context);
        return;
      case _ResellerTaskRoute.saved:
        AppRouter.goToSaved(context);
        return;
    }
  }
}

class _DiscoveryMomentumStrip extends StatelessWidget {
  const _DiscoveryMomentumStrip({required this.chips});

  final List<_DiscoveryChipData> chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chip.title,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColor.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chip.subtitle,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _DiscoveryChipData {
  const _DiscoveryChipData({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _SectionLead extends StatelessWidget {
  const _SectionLead({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('See all')),
      ],
    );
  }
}
