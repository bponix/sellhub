import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    await storeContextCubit.setActiveStore(store);
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
