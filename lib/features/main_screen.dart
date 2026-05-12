import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/navigation/deep_link_service.dart';
import 'package:sellhub/core/navigation/pending_product_deep_link.dart';
import 'package:sellhub/core/config/app_text.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_drawer.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/categories/screen/category_screen.dart';
import 'package:sellhub/features/product/screens/home_screen.dart';
import 'package:sellhub/features/profile/screens/profile_screen.dart';
import 'package:sellhub/features/saved/presentation/cubit/saved_cubit.dart';
import 'package:sellhub/features/saved/presentation/cubit/saved_state.dart';
import 'package:sellhub/features/saved/screens/saved_screen.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_state.dart';
import 'package:sellhub/features/selling_list/presentation/cubit/selling_list_cubit.dart';
import 'package:sellhub/features/selling_list/presentation/cubit/selling_list_state.dart';
import 'package:sellhub/features/selling_list/screens/selling_list_screen.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_state.dart';

import 'storefront/presentation/cubit/storefront_cubit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    CategoryScreen(),
    SavedScreen(),
    SellingListScreen(),
    ProfileScreen(),
  ];

  bool _handledPendingProductLink = false;
  bool _handledPendingDeepLink = false;

  _TabAppBarData _tabAppBarDataForIndex(int index) {
    switch (index) {
      case 1:
        return const _TabAppBarData(
          title: 'Categories',
          subtitle: 'Browse supplier catalog fast',
          icon: HugeIcons.strokeRoundedGridView,
        );
      case 2:
        return const _TabAppBarData(
          title: 'Saved',
          subtitle: 'Products you want to reuse',
          icon: HugeIcons.strokeRoundedFavourite,
        );
      case 3:
        return const _TabAppBarData(
          title: 'Selling list',
          subtitle: 'Price, quote, and place the order',
          icon: HugeIcons.strokeRoundedShoppingCart01,
        );
      case 4:
        return const _TabAppBarData(
          title: 'Profile',
          subtitle: 'Buyer book, payouts, and team',
          icon: HugeIcons.strokeRoundedUser,
        );
      default:
        return const _TabAppBarData(
          title: AppText.appName,
          subtitle: 'Find products and sell fast',
          icon: HugeIcons.strokeRoundedShoppingBag03,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingDeepLink();
      _consumePendingProductLink();
    });
  }

  Future<void> _consumePendingDeepLink() async {
    if (!mounted || _handledPendingDeepLink) return;
    _handledPendingDeepLink = true;
    final handled = await DeepLinkService.consumePendingLink();
    if (!handled) {
      _handledPendingDeepLink = false;
    }
  }

  Future<void> _consumePendingProductLink() async {
    if (!mounted || _handledPendingProductLink) return;
    _handledPendingProductLink = true;
    final opened = await PendingProductDeepLinkHandler.consumeAndOpen(context);
    if (!opened) {
      _handledPendingProductLink = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreShellCubit, StoreShellState>(
      builder: (context, shellState) {
        final appBarData = _tabAppBarDataForIndex(shellState.currentIndex);
        return BlocBuilder<StorefrontCubit, StorefrontState>(
          builder: (context, storefrontState) {
            return Scaffold(
              appBar: SellHubTopAppBar(
                title: appBarData.title,
                subtitle: appBarData.subtitle,
                showSubtitle: true,
                icon: appBarData.icon,
              ),
              endDrawer: AppDrawerFull(
                onOpenCategories: () =>
                    context.read<StoreShellCubit>().setIndex(1),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: shellState.currentIndex,
                      children: _screens,
                    ),
                  ),
                  if (storefrontState.status == StorefrontStatus.failure &&
                      storefrontState.siteDetails == null)
                    _StorefrontBootstrapError(
                      onRetry: () {
                        final activeStore = context
                            .read<StoreContextCubit>()
                            .state
                            .activeStore;
                        context.read<StorefrontCubit>().preload(
                          domain:
                              activeStore?.domain ??
                              AppConstants.kDefaultDomain,
                          siteId:
                              activeStore?.siteId ??
                              AppConstants.kDefaultSiteId,
                          first: AppConstants.kDefaultFirst,
                          forceRefresh: true,
                        );
                      },
                    ),
                ],
              ),
              bottomNavigationBar: SellerBottomNavBar(
                currentIndex: shellState.currentIndex,
              ),
            );
          },
        );
      },
    );
  }
}

class _TabAppBarData {
  const _TabAppBarData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
}

class _StorefrontBootstrapError extends StatelessWidget {
  const _StorefrontBootstrapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4F4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.safe),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColor.safe),
                ),
                child: const AppHugeIcon(
                  HugeIcons.strokeRoundedWifiError02,
                  size: 18,
                  color: AppColor.alert,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catalog refresh failed',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColor.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Showing saved data until refresh works again.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class SellerBottomNavBar extends StatelessWidget {
  const SellerBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  static const List<_BottomNavItemData> _items = [
    _BottomNavItemData(
      icon: HugeIcons.strokeRoundedHome01,
      semanticLabel: 'Home',
    ),
    _BottomNavItemData(
      icon: HugeIcons.strokeRoundedGridView,
      semanticLabel: 'Categories',
    ),
    _BottomNavItemData(
      icon: HugeIcons.strokeRoundedFavourite,
      semanticLabel: 'Saved',
      useFavouriteBadge: true,
    ),
    _BottomNavItemData(
      icon: HugeIcons.strokeRoundedShoppingCart01,
      semanticLabel: 'Selling list',
      useCartBadge: true,
    ),
    _BottomNavItemData(
      icon: HugeIcons.strokeRoundedUser,
      semanticLabel: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.safe.withValues(alpha: 0.95)),
            boxShadow: [
              BoxShadow(
                color: AppColor.text.withValues(alpha: 0.02),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                return Expanded(
                  child: _BottomNavItem(
                    data: item,
                    selected: currentIndex == index,
                    onTap: () {
                      context.read<StoreShellCubit>().setIndex(index);
                      AppRouter.goToHome(context);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  const _BottomNavItemData({
    required this.icon,
    required this.semanticLabel,
    this.useFavouriteBadge = false,
    this.useCartBadge = false,
  });

  final List<List<dynamic>> icon;
  final String semanticLabel;
  final bool useFavouriteBadge;
  final bool useCartBadge;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellingListCubit, SellingListState>(
      buildWhen: (_, __) => data.useCartBadge,
      builder: (context, cartState) {
        return BlocBuilder<SavedCubit, SavedState>(
          buildWhen: (_, __) => data.useFavouriteBadge,
          builder: (context, favouriteState) {
            final badgeCount = data.useCartBadge
                ? cartState.items.length
                : data.useFavouriteBadge
                ? favouriteState.items.length
                : 0;
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColor.safe1 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColor.primarySoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: AppHugeIcon(
                            data.icon,
                            size: 18,
                            color: selected
                                ? AppColor.primary
                                : AppColor.neutral2,
                            semanticLabel: data.semanticLabel,
                          ),
                        ),
                        if (badgeCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.primary,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                badgeCount > 99 ? '99+' : '$badgeCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
