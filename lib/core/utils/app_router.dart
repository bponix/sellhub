import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/utils/route_names.dart';
import 'package:sellhub/features/auth/screens/login_screen.dart';
import 'package:sellhub/features/auth/screens/register_screen.dart';
import 'package:sellhub/features/auth/screens/forgot_password_screen.dart';
import 'package:sellhub/features/cart/screens/cart_screen.dart';
import 'package:sellhub/features/discovery/screens/store_qr_scanner_screen.dart';
import 'package:sellhub/features/discovery/screens/store_selector_screen.dart';
import 'package:sellhub/features/favourite/screens/favourite_screen.dart';
import 'package:sellhub/features/main_screen.dart';
import 'package:sellhub/features/notifications/screens/notifications_screen.dart';
import 'package:sellhub/features/orders/screens/orders_screen.dart';
import 'package:sellhub/features/profile/screens/profile_screen.dart';
import 'package:sellhub/features/product/screens/collection_link_screen.dart';
import 'package:sellhub/features/search/screen/search_screen.dart';
import 'package:sellhub/features/settings/screens/settings_screen.dart';
import 'package:sellhub/features/splash/screens/splash_screen.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';
import 'package:sellhub/core/navigation/unsupported_link_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get navigatorKey => rootNavigatorKey;

  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/${RouteNames.splash}',
    redirect: (context, state) async {
      final path = state.uri.path.toLowerCase();
      final activeStore = await LocalStorage.getActiveStore();
      final isLoggedIn = await LocalStorage.isLogin();

      final isSplash = path == '/${RouteNames.splash}';
      final isAuthRoute =
          path == '/${RouteNames.login}' ||
          path == '/${RouteNames.register}' ||
          path == '/${RouteNames.forgotPassword}';
      final isStoreDiscoveryRoute =
          path == '/${RouteNames.storeSelector}' ||
          path == '/${RouteNames.storeScanner}';

      if (isSplash) {
        return null;
      }

      if (activeStore == null && !isStoreDiscoveryRoute && !isAuthRoute) {
        return '/${RouteNames.storeSelector}';
      }

      if (isLoggedIn && isAuthRoute) {
        return activeStore == null
            ? '/${RouteNames.storeSelector}'
            : '/${RouteNames.home}';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/${RouteNames.splash}',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.login}',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.register}',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.forgotPassword}',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.home}',
        name: RouteNames.home,
        builder: (context, state) => const MainScreen(),
        routes: [
          GoRoute(
            path: RouteNames.search,
            name: RouteNames.search,
            builder: (context, state) => const SearchScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/${RouteNames.storeSelector}',
        name: RouteNames.storeSelector,
        builder: (context, state) => StoreSelectorScreen(
          returnTo: state.uri.queryParameters['returnTo'],
          shellIndex: int.tryParse(state.uri.queryParameters['shellIndex'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/${RouteNames.storeScanner}',
        name: RouteNames.storeScanner,
        builder: (context, state) => StoreQrScannerScreen(
          returnTo: state.uri.queryParameters['returnTo'],
          shellIndex: int.tryParse(state.uri.queryParameters['shellIndex'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/${RouteNames.cart}',
        name: RouteNames.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.favourite}',
        name: RouteNames.favourite,
        builder: (context, state) => const FavouriteScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.profile}',
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.notifications}',
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.orders}',
        name: RouteNames.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.settings}',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.collection}',
        name: RouteNames.collection,
        builder: (context, state) => CollectionLinkScreen(
          collectionType:
              state.uri.queryParameters['collectionType']?.trim() ?? '',
          title: state.uri.queryParameters['collectionTitle']?.trim(),
        ),
      ),
      GoRoute(
        path: '/${RouteNames.unsupportedLink}',
        name: RouteNames.unsupportedLink,
        builder: (context, state) => const UnsupportedLinkScreen(),
      ),
    ],
  );

  // Helper methods for navigation
  static void goToSplash(BuildContext context) =>
      context.go('/${RouteNames.splash}');
  static void goToLogin(BuildContext context) =>
      context.go('/${RouteNames.login}');
  static void goToRegister(BuildContext context) =>
      context.go('/${RouteNames.register}');
  static void goToHome(BuildContext context) =>
      context.go('/${RouteNames.home}');
  static void goToStoreSelector(
    BuildContext context, {
    String? returnTo,
    int? shellIndex,
  }) => context.go(
    _buildDiscoveryLocation(
      '/${RouteNames.storeSelector}',
      returnTo: returnTo ?? _currentReturnLocation(),
      shellIndex: shellIndex ?? _readShellIndex(context),
    ),
  );
  static void goToStoreScanner(
    BuildContext context, {
    String? returnTo,
    int? shellIndex,
  }) => context.push(
    _buildDiscoveryLocation(
      '/${RouteNames.storeScanner}',
      returnTo: returnTo ?? _currentReturnLocation(),
      shellIndex: shellIndex ?? _readShellIndex(context),
    ),
  );
  static void goToCart(BuildContext context) =>
      context.go('/${RouteNames.cart}');
  static void goToFavourites(BuildContext context) =>
      context.go('/${RouteNames.favourite}');
  static void goToProfile(BuildContext context) =>
      context.go('/${RouteNames.profile}');
  static void goToForgotPassword(BuildContext context) =>
      context.go('/${RouteNames.forgotPassword}');
  static void goToNotifications(BuildContext context) =>
      context.push('/${RouteNames.notifications}');
  static void goToOrders(BuildContext context) =>
      context.push('/${RouteNames.orders}');
  static void goToSettings(BuildContext context) =>
      context.push('/${RouteNames.settings}');

  static void go(String location) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    context.go(location);
  }

  static void goNamed(
    String routeName, {
    Map<String, dynamic>? queryParameters,
  }) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    context.goNamed(
      routeName,
      queryParameters: queryParameters ?? const <String, dynamic>{},
    );
  }

  // Push methods (if you need push instead of go)
  static Future<T?> pushToCart<T>(BuildContext context) =>
      context.push<T>('/${RouteNames.cart}');
  static Future<T?> pushToProfile<T>(BuildContext context) =>
      context.push<T>('/${RouteNames.profile}');
  static pushSearchScreen(BuildContext context) =>
      context.pushNamed(RouteNames.search);

  static void goToStoreReturnTarget(
    BuildContext context, {
    String? returnTo,
    int? shellIndex,
  }) {
    final target = _normalizeDiscoveryReturnTo(returnTo) ?? '/${RouteNames.home}';
    if (target == '/${RouteNames.home}' && shellIndex != null) {
      final normalizedIndex = shellIndex.clamp(0, 4);
      context.read<StoreShellCubit>().setIndex(normalizedIndex);
    }
    context.go(target);
  }

  static String _buildDiscoveryLocation(
    String path, {
    String? returnTo,
    int? shellIndex,
  }) {
    final normalizedReturnTo = _normalizeDiscoveryReturnTo(returnTo);
    final queryParameters = <String, String>{};
    if (normalizedReturnTo != null) {
      queryParameters['returnTo'] = normalizedReturnTo;
    }
    if (shellIndex != null) {
      queryParameters['shellIndex'] = shellIndex.clamp(0, 4).toString();
    }
    return Uri(path: path, queryParameters: queryParameters.isEmpty ? null : queryParameters)
        .toString();
  }

  static String? _currentReturnLocation() =>
      _normalizeDiscoveryReturnTo(
        router.routeInformationProvider.value.uri.toString(),
      );

  static String? _normalizeDiscoveryReturnTo(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    final path = uri.path.toLowerCase();
    const disallowedPaths = <String>{
      '/${RouteNames.splash}',
      '/${RouteNames.storeSelector}',
      '/${RouteNames.storeScanner}',
    };
    if (path.isEmpty || disallowedPaths.contains(path)) {
      return null;
    }
    return uri.toString();
  }

  static int? _readShellIndex(BuildContext context) {
    try {
      return context.read<StoreShellCubit>().state.currentIndex;
    } catch (_) {
      return null;
    }
  }
}

/*
// Instead of:
context.go('/cart');

// Use:
AppRouter.goToCart(context);

// Or with named routes:
context.goNamed(RouteNames.cart);
 */
