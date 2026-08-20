import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/product/screens/widget/product_list_vertical.dart';

import '../../../core/constants/app_color.dart';
import '../../../core/widget/app_huge_icon.dart';
import '../../../core/store/store_scope.dart';
import '../../cart/presentation/cubit/cart_cubit.dart';
import '../../cart/presentation/cubit/cart_state.dart';
import '../../cart/screens/cart_screen.dart';
import '../../product/screens/collection_link_screen.dart';
import '../../storefront/presentation/cubit/storefront_cubit.dart';
import '../../storefront/presentation/cubit/storefront_state.dart';

class FlashSaleProduct extends StatefulWidget {
  const FlashSaleProduct({super.key});

  @override
  State<FlashSaleProduct> createState() => _FlashSaleProductState();
}

class _FlashSaleProductState extends State<FlashSaleProduct> {
  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<StorefrontCubit>();
      final state = cubit.state;
      if (state.flashSale.isEmpty && !state.isLoading) {
        cubit.fetchFlashSale(StoreScope.activeSiteId(context), 16, 0);
      }
    });
  }

  void _onScroll() {
    if (_mainScrollController.position.extentAfter < 200) {
      final state = context.read<StorefrontCubit>().state;
      if (!state.isFetchingMore) {
        context.read<StorefrontCubit>().fetchFlashSale(
          StoreScope.activeSiteId(context),
          16,
          state.flashSaleOffset,
          isLoadMore: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StorefrontCubit, StorefrontState>(
      builder: (context, storefrontState) {
        return Scaffold(
          appBar: SellHubTopAppBar(
            title: 'Flash deals',
            icon: HugeIcons.strokeRoundedFire,
            showBackButton: true,
            actions: [
              IconButton(
                onPressed: () => _shareCollection(context),
                icon: const AppHugeIcon(
                  HugeIcons.strokeRoundedShare08,
                  size: 20,
                ),
              ),
              BlocBuilder<CartCubit, CartState>(
                builder: (context, cartProvider) {
                  return Badge(
                    offset: Offset(-3, 5),
                    backgroundColor: AppColor.primary,
                    isLabelVisible: cartProvider.items.isNotEmpty,
                    label: Text('${cartProvider.items.length}'),
                    child: IconButton(
                      onPressed: () {
                        // go to cart page
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CartScreen(isNewScreen: true),
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
              SizedBox(width: 10),
            ],
          ),
          body: CustomScrollView(
            controller: _mainScrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: _CollectionHero(
                    icon: HugeIcons.strokeRoundedFire,
                    title: 'Flash picks',
                    count: storefrontState.flashSale.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ProductListViewVerical(
                  products: storefrontState.flashSale,
                  emphasizeImage: true,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareCollection(BuildContext context) async {
    final store = context.read<StoreContextCubit>().state.activeStore;
    if (store == null) return;
    final text = SellHubShareLinkBuilder.buildCollectionShareText(
      store: store,
      collectionType: CollectionLinkScreen.flashSale,
      title: 'Flash deals',
    );
    await Share.share(text, subject: 'Flash deals');
  }
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({
    required this.icon,
    required this.title,
    required this.count,
  });

  final List<List<dynamic>> icon;
  final String title;
  final int count;

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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count items',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
