import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellhub/core/capabilities/store_surface_capabilities.dart';
import 'package:sellhub/core/capabilities/store_surface_repository.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_cubit.dart';
import 'package:sellhub/features/search/presentation/cubit/search_cubit.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/injection_container.dart';

class StoreActivator {
  const StoreActivator._();

  static Future<void> activate(
    BuildContext context,
    ActiveStore store, {
    String? returnTo,
    int? shellIndex,
  }) async {
    final storeContextCubit = context.read<StoreContextCubit>();
    final storefrontCubit = context.read<StorefrontCubit>();
    final categoriesCubit = context.read<CategoriesCubit>();
    final searchCubit = context.read<SearchCubit>();
    final cartCubit = context.read<CartCubit>();
    final favouriteCubit = context.read<FavouriteCubit>();
    final shellCubit = context.read<StoreShellCubit>();
    StoreSurfaceCapabilitySet? surface;
    var activatedStore = store;

    try {
      final runtime = await sl<StoreSurfaceRepository>().fetchPublicRuntime(
        domain: store.domain,
        route: returnTo ?? '/',
      );
      if (!runtime.ready) {
        await storeContextCubit.markUnavailable(
          store: store,
          surface: null,
          title: runtime.siteTitle ?? 'SellHub supply is off',
          message: runtime.message,
        );
        if (context.mounted) {
          AppRouter.goToStoreReturnTarget(
            context,
            returnTo: returnTo,
            shellIndex: shellIndex,
          );
        }
        return;
      }
      activatedStore = store.copyWith(market: runtime.market);
      surface = await sl<StoreSurfaceRepository>().fetchSellHubSurface(
        store.siteId,
      );
    } catch (_) {
      await storeContextCubit.markUnavailable(
        store: store,
        surface: null,
        title: 'Supplier is not ready for SellHub',
        message:
            'This supplier cannot be used for reseller selling right now. Ask the operator to enable SellHub supply.',
      );
      if (context.mounted) {
        AppRouter.goToStoreReturnTarget(
          context,
          returnTo: returnTo,
          shellIndex: shellIndex,
        );
      }
      return;
    }

    final missing = surface.firstUnavailable(const <String>[
      'store.sellhub_supply',
      'store.base_price_visibility',
      'store.reseller_order_routing',
    ]);
    if (missing != null) {
      await storeContextCubit.markUnavailable(
        store: store,
        surface: surface,
        title: 'SellHub supply is off',
        message:
            'This supplier has not enabled SellHub supply, base price visibility, and reseller order routing yet.',
      );
      if (context.mounted) {
        AppRouter.goToStoreReturnTarget(
          context,
          returnTo: returnTo,
          shellIndex: shellIndex,
        );
      }
      return;
    }

    await storeContextCubit.setActiveStoreWithSurface(activatedStore, surface);
    storefrontCubit.clear();
    categoriesCubit.reset();
    searchCubit.reset();
    await cartCubit.clearCart();
    await favouriteCubit.clear();
    shellCubit.setIndex(shellIndex?.clamp(0, 4) ?? 0);

    await storefrontCubit.preload(
      domain: store.domain,
      siteId: store.siteId,
      first: AppConstants.kDefaultFirst,
      forceRefresh: true,
    );
    await categoriesCubit.fetchSubCategory(store.siteId);
    await categoriesCubit.fetchSubSubCategory(store.siteId);
    await favouriteCubit.syncFromSession();

    if (context.mounted) {
      AppRouter.goToStoreReturnTarget(
        context,
        returnTo: returnTo,
        shellIndex: shellIndex,
      );
    }
  }
}
