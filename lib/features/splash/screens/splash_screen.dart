import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/store/store_context_state.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';

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
    final activeStore = storeContextCubit.state.activeStore;
    if (activeStore == null) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      AppRouter.goToStoreSelector(context);
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
    final backgroundColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: const SizedBox(
                  width: 148,
                  height: 148,
                  child: _SplashLogo(),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text.rich(
                  TextSpan(
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(text: 'Powered by '),
                      TextSpan(
                        text: 'Bponi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/sellhub_logo.png', fit: BoxFit.contain);
  }
}
