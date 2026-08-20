import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellhub/core/capabilities/store_surface_repository.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/store/store_context_state.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/injection_container.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    unawaited(_loadData());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final storefrontCubit = context.read<StorefrontCubit>();
    final profileCubit = context.read<ProfileCubit>();
    final categoriesCubit = context.read<CategoriesCubit>();
    final storeContextCubit = context.read<StoreContextCubit>();

    if (storeContextCubit.state.status == StoreContextStatus.initial) {
      await storeContextCubit.hydrate();
    }
    final storedActiveStore = storeContextCubit.state.activeStore;
    var activeStore =
        storedActiveStore ??
        ActiveStore(
          siteId: AppConstants.kDefaultSiteId,
          domain: AppConstants.kDefaultDomain,
          title: 'SellHub',
        );
    if (storedActiveStore == null) {
      await storeContextCubit.setActiveStore(activeStore);
    }

    try {
      final runtime = await sl<StoreSurfaceRepository>().fetchPublicRuntime(
        domain: activeStore.domain,
      );
      if (!runtime.ready) {
        await storeContextCubit.markUnavailable(
          store: activeStore,
          surface: null,
          title: runtime.siteTitle ?? 'SellHub supply is off',
          message: runtime.message,
        );
        if (!mounted) return;
        AppRouter.goToHome(context);
        return;
      }
      activeStore = activeStore.copyWith(market: runtime.market);
      final surface = await sl<StoreSurfaceRepository>().fetchSellHubSurface(
        activeStore.siteId,
      );
      final missing = surface.firstUnavailable(const <String>[
        'store.sellhub_supply',
        'store.base_price_visibility',
        'store.reseller_order_routing',
      ]);
      if (missing != null) {
        await storeContextCubit.markUnavailable(
          store: activeStore,
          surface: surface,
          title: 'SellHub supply is off',
          message:
              'This supplier has not enabled SellHub supply, base price visibility, and reseller order routing yet.',
        );
        if (!mounted) return;
        AppRouter.goToHome(context);
        return;
      }
      await storeContextCubit.setActiveStoreWithSurface(activeStore, surface);
    } catch (_) {
      await storeContextCubit.markUnavailable(
        store: activeStore,
        surface: null,
        title: 'Supplier is not ready for SellHub',
        message:
            'This supplier cannot be used for reseller selling right now. Ask the operator to enable SellHub supply.',
      );
      if (!mounted) return;
      AppRouter.goToHome(context);
      return;
    }

    await storefrontCubit.preload(
      domain: activeStore.domain,
      siteId: activeStore.siteId,
      first: AppConstants.kDefaultFirst,
      forceRefresh: true,
    );
    if (!mounted) {
      return;
    }
    if (await LocalStorage.isLogin()) {
      await profileCubit.fetchProfileDetails(
        await LocalStorage.getUserID() ?? 0,
      );
      if (!mounted) {
        return;
      }
    }
    categoriesCubit.fetchSubCategory(activeStore.siteId);
    categoriesCubit.fetchSubSubCategory(activeStore.siteId);

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }
    AppRouter.goToHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              const Spacer(),
              Center(child: _SplashLogo(fadeIn: _fadeIn)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Find products, set your buyer price, and sell across trusted suppliers from one reseller catalog.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColor.neutral2,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 5,
                    backgroundColor: AppColor.safe1,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text.rich(
                  TextSpan(
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.black.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(text: 'Powered by '),
                      TextSpan(
                        text: 'Bponi',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.fadeIn});

  final Animation<double> fadeIn;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeIn,
      child: SizedBox(
        width: 156,
        height: 156,
        child: Image.asset('assets/sellhub_logo.png', fit: BoxFit.contain),
      ),
    );
  }
}
