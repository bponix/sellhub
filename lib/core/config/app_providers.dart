import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/network/connectivity_cubit.dart';
import 'package:sellhub/core/notifications/notification_center_cubit.dart';
import 'package:sellhub/core/services/analytics_service.dart';
import 'package:sellhub/core/services/crash_reporting_service.dart';
import 'package:sellhub/core/services/remote_config_service.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/features/auth/data/auth_repository.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sellhub/features/cart/data/checkout_repository.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_cubit.dart';
import 'package:sellhub/features/categories/data/categories_repositopry.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_cubit.dart';
import 'package:sellhub/features/orders/data/orders_repository.dart';
import 'package:sellhub/features/product/data/product_repository.dart';
import 'package:sellhub/features/discovery/presentation/cubit/store_discovery_cubit.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sellhub/features/search/data/search_repository.dart';
import 'package:sellhub/features/search/presentation/cubit/search_cubit.dart';
import 'package:sellhub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/injection_container.dart' as di;

class AppProviders extends StatelessWidget {
  const AppProviders({
    super.key,
    required this.child,
    required this.clientNotifier,
  });

  final Widget child;
  final ValueNotifier<GraphQLClient> clientNotifier;

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: clientNotifier,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: di.sl<AuthCubit>()),
          BlocProvider.value(value: di.sl<StorefrontCubit>()),
          BlocProvider.value(value: di.sl<StoreShellCubit>()),
          BlocProvider.value(value: di.sl<CategoriesCubit>()),
          BlocProvider.value(value: di.sl<StoreContextCubit>()),
          BlocProvider.value(value: di.sl<StoreDiscoveryCubit>()),
          BlocProvider.value(value: di.sl<SearchCubit>()),
          BlocProvider.value(value: di.sl<ProfileCubit>()),
          BlocProvider.value(value: di.sl<FavouriteCubit>()..init()),
          BlocProvider.value(value: di.sl<CartCubit>()..init()),
          BlocProvider.value(value: di.sl<CheckoutCubit>()),
          BlocProvider.value(value: di.sl<NotificationCenterCubit>()),
          BlocProvider.value(value: di.sl<ConnectivityCubit>()),
          BlocProvider.value(value: di.sl<SettingsCubit>()),
        ],
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthRepository>.value(value: di.sl<AuthRepository>()),
            RepositoryProvider<ProductRepository>.value(
              value: di.sl<ProductRepository>(),
            ),
            RepositoryProvider<CategoryRepository>.value(
              value: di.sl<CategoryRepository>(),
            ),
            RepositoryProvider<CheckoutRepository>.value(
              value: di.sl<CheckoutRepository>(),
            ),
            RepositoryProvider<ProfileRepository>.value(
              value: di.sl<ProfileRepository>(),
            ),
            RepositoryProvider<OrdersRepository>.value(
              value: di.sl<OrdersRepository>(),
            ),
            RepositoryProvider<SearchRepository>.value(
              value: di.sl<SearchRepository>(),
            ),
            RepositoryProvider<AnalyticsService>.value(
              value: di.sl<AnalyticsService>(),
            ),
            RepositoryProvider<CrashReportingService>.value(
              value: di.sl<CrashReportingService>(),
            ),
            RepositoryProvider<RemoteConfigService>.value(
              value: di.sl<RemoteConfigService>(),
            ),
          ],
          child: child,
        ),
      ),
    );
  }
}
