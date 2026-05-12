import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/utils/route_names.dart';
import 'package:sellhub/features/auth/screens/login_screen.dart';
import 'package:sellhub/features/auth/screens/register_screen.dart';
import 'package:sellhub/features/auth/screens/forgot_password_screen.dart';
import 'package:sellhub/features/main_screen.dart';
import 'package:sellhub/features/notifications/screens/notifications_screen.dart';
import 'package:sellhub/features/orders/screens/orders_screen.dart';
import 'package:sellhub/features/profile/screens/buyer_book_screen.dart';
import 'package:sellhub/features/profile/screens/payout_ledger_screen.dart';
import 'package:sellhub/features/profile/screens/profile_screen.dart';
import 'package:sellhub/features/profile/screens/quotes_screen.dart';
import 'package:sellhub/features/profile/screens/reseller_ops_screen.dart';
import 'package:sellhub/features/profile/screens/team_selling_screen.dart';
import 'package:sellhub/features/profile/screens/team_invite_screen.dart';
import 'package:sellhub/features/profile/screens/workflow_automation_screen.dart';
import 'package:sellhub/features/product/screens/collection_link_screen.dart';
import 'package:sellhub/features/saved/screens/saved_screen.dart';
import 'package:sellhub/features/search/screen/search_screen.dart';
import 'package:sellhub/features/settings/screens/settings_screen.dart';
import 'package:sellhub/features/selling_list/screens/selling_list_screen.dart';
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
      final uri = state.uri;
      final path = uri.path.toLowerCase();
      final isLoggedIn = await LocalStorage.isLogin();

      final isSplash = path == '/${RouteNames.splash}';
      final isAuthRoute =
          path == '/${RouteNames.login}' ||
          path == '/${RouteNames.register}' ||
          path == '/${RouteNames.forgotPassword}';
      final isProtectedRoute = _isProtectedRoute(path);

      if (isSplash) {
        return null;
      }

      if (!isLoggedIn && isProtectedRoute) {
        final returnTo = _normalizePostAuthReturnTo(uri.toString());
        if (returnTo == null) {
          return '/${RouteNames.login}';
        }
        return Uri(
          path: '/${RouteNames.login}',
          queryParameters: <String, String>{'returnTo': returnTo},
        ).toString();
      }

      if (isLoggedIn && isAuthRoute) {
        final returnTo = _normalizePostAuthReturnTo(
          uri.queryParameters['returnTo'],
        );
        return returnTo ?? '/${RouteNames.home}';
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
        builder: (context, state) => LoginScreen(
          onAuthenticatedLocation: _normalizePostAuthReturnTo(
            state.uri.queryParameters['returnTo'],
          ),
        ),
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
            builder: (context, state) => SearchScreen(
              initialMode: state.uri.queryParameters['mode'],
              initialQuery: state.uri.queryParameters['query'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/${RouteNames.sellingList}',
        name: RouteNames.sellingList,
        builder: (context, state) => const SellingListScreen(isNewScreen: true),
      ),
      GoRoute(
        path: '/${RouteNames.saved}',
        name: RouteNames.saved,
        builder: (context, state) => const SavedScreen(showAppBar: true),
      ),
      GoRoute(
        path: '/${RouteNames.profile}',
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(showAppBar: true),
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
        path: '/${RouteNames.buyerBook}',
        name: RouteNames.buyerBook,
        builder: (context, state) => const BuyerBookScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.payouts}',
        name: RouteNames.payouts,
        builder: (context, state) => const PayoutLedgerScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.teamSelling}',
        name: RouteNames.teamSelling,
        builder: (context, state) => const TeamSellingScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.teamInvite}',
        name: RouteNames.teamInvite,
        builder: (context, state) => TeamInviteScreen(
          teamId: state.uri.queryParameters['teamId']?.trim() ?? '',
          memberId: state.uri.queryParameters['memberId']?.trim() ?? '',
          ownerUserId:
              int.tryParse(state.uri.queryParameters['ownerUserId'] ?? '') ?? 0,
          siteId: int.tryParse(state.uri.queryParameters['siteId'] ?? '') ?? 0,
          teamName: state.uri.queryParameters['teamName']?.trim(),
          ownerName: state.uri.queryParameters['ownerName']?.trim(),
          overridePercent:
              double.tryParse(state.uri.queryParameters['override'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/${RouteNames.quotes}',
        name: RouteNames.quotes,
        builder: (context, state) => const QuotesScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.resellerOps}',
        name: RouteNames.resellerOps,
        builder: (context, state) => const ResellerOpsScreen(),
      ),
      GoRoute(
        path: '/${RouteNames.workflows}',
        name: RouteNames.workflows,
        builder: (context, state) => const WorkflowAutomationScreen(),
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
  static void goToSellingList(BuildContext context) =>
      context.go('/${RouteNames.sellingList}');
  static void goToSaved(BuildContext context) =>
      context.go('/${RouteNames.saved}');
  static void goToCart(BuildContext context) => goToSellingList(context);
  static void goToFavourites(BuildContext context) => goToSaved(context);
  static void goToProfile(BuildContext context) =>
      context.go('/${RouteNames.profile}');
  static void goToForgotPassword(BuildContext context) =>
      context.go('/${RouteNames.forgotPassword}');
  static void goToNotifications(BuildContext context) =>
      context.push('/${RouteNames.notifications}');
  static void goToOrders(BuildContext context) =>
      context.push('/${RouteNames.orders}');
  static void goToBuyerBook(BuildContext context) =>
      context.push('/${RouteNames.buyerBook}');
  static void goToPayouts(BuildContext context) =>
      context.push('/${RouteNames.payouts}');
  static void goToTeamSelling(BuildContext context) =>
      context.push('/${RouteNames.teamSelling}');
  static void goToQuotes(BuildContext context) =>
      context.push('/${RouteNames.quotes}');
  static void goToResellerOps(BuildContext context) =>
      context.push('/${RouteNames.resellerOps}');
  static void goToWorkflows(BuildContext context) =>
      context.push('/${RouteNames.workflows}');
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
  static Future<T?> pushToSellingList<T>(BuildContext context) =>
      context.push<T>('/${RouteNames.sellingList}');
  static Future<T?> pushToCart<T>(BuildContext context) =>
      pushToSellingList<T>(context);
  static Future<T?> pushToProfile<T>(BuildContext context) =>
      context.push<T>('/${RouteNames.profile}');
  static pushSearchScreen(
    BuildContext context, {
    String? mode,
    String? query,
  }) => context.pushNamed(
        RouteNames.search,
        queryParameters: <String, dynamic>{
          if ((mode ?? '').trim().isNotEmpty) 'mode': mode!.trim(),
          if ((query ?? '').trim().isNotEmpty) 'query': query!.trim(),
        },
      );

  static void goToStoreReturnTarget(
    BuildContext context, {
    String? returnTo,
    int? shellIndex,
  }) {
    final target =
        _normalizeDiscoveryReturnTo(returnTo) ?? '/${RouteNames.home}';
    if (target == '/${RouteNames.home}' && shellIndex != null) {
      final normalizedIndex = shellIndex.clamp(0, 4);
      context.read<StoreShellCubit>().setIndex(normalizedIndex);
    }
    context.go(target);
  }

  static String? _normalizeDiscoveryReturnTo(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    final path = uri.path.toLowerCase();
    const disallowedPaths = <String>{
      '/${RouteNames.splash}',
    };
    if (path.isEmpty || disallowedPaths.contains(path)) {
      return null;
    }
    return uri.toString();
  }

  static String? _normalizePostAuthReturnTo(String? raw) {
    final normalized = _normalizeDiscoveryReturnTo(raw);
    if (normalized == null) return null;
    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;
    final path = uri.path.toLowerCase();
    const disallowedAuthPaths = <String>{
      '/${RouteNames.login}',
      '/${RouteNames.register}',
      '/${RouteNames.forgotPassword}',
    };
    if (disallowedAuthPaths.contains(path)) {
      return null;
    }
    return normalized;
  }

  static bool _isProtectedRoute(String path) {
    const protectedPaths = <String>{
      '/${RouteNames.orders}',
      '/${RouteNames.buyerBook}',
      '/${RouteNames.payouts}',
      '/${RouteNames.teamSelling}',
      '/${RouteNames.teamInvite}',
      '/${RouteNames.quotes}',
      '/${RouteNames.resellerOps}',
      '/${RouteNames.workflows}',
      '/${RouteNames.settings}',
      '/${RouteNames.notifications}',
    };
    return protectedPaths.contains(path);
  }

}

/*
// Instead of:
context.go('/selling-list');

// Use:
AppRouter.goToSellingList(context);

// Or with named routes:
context.goNamed(RouteNames.sellingList);
 */
