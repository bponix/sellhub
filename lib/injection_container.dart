import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sellhub/core/network/connectivity_cubit.dart';
import 'package:sellhub/core/notifications/notification_center_cubit.dart';
import 'package:sellhub/core/services/analytics_service.dart';
import 'package:sellhub/core/services/crash_reporting_service.dart';
import 'package:sellhub/core/services/remote_config_service.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/features/auth/data/auth_repository.dart';
import 'package:sellhub/features/auth/data/auth_repository_adapter.dart';
import 'package:sellhub/features/auth/data/local_session_repository.dart';
import 'package:sellhub/features/auth/domain/repositories/auth_repository_contract.dart';
import 'package:sellhub/features/auth/domain/repositories/session_repository.dart';
import 'package:sellhub/features/auth/domain/usecases/check_user.dart';
import 'package:sellhub/features/auth/domain/usecases/login_user.dart';
import 'package:sellhub/features/auth/domain/usecases/logout_user.dart';
import 'package:sellhub/features/auth/domain/usecases/register_user.dart';
import 'package:sellhub/features/auth/domain/usecases/reset_password.dart';
import 'package:sellhub/features/auth/domain/usecases/send_otp.dart';
import 'package:sellhub/features/auth/domain/usecases/verify_otp.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sellhub/features/cart/data/checkout_repository.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_cubit.dart';
import 'package:sellhub/features/categories/data/categories_repositopry.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_cubit.dart';
import 'package:sellhub/features/product/data/product_repository.dart';
import 'package:sellhub/features/discovery/data/store_discovery_repository.dart';
import 'package:sellhub/features/discovery/presentation/cubit/store_discovery_cubit.dart';
import 'package:sellhub/features/orders/data/orders_repository.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sellhub/features/product/presentation/cubit/product_details_cubit.dart';
import 'package:sellhub/features/search/data/search_repository.dart';
import 'package:sellhub/features/search/presentation/cubit/search_cubit.dart';
import 'package:sellhub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';
import 'package:sellhub/features/storefront/data/storefront_repository_impl.dart';
import 'package:sellhub/features/storefront/domain/repositories/storefront_repository.dart';
import 'package:sellhub/features/storefront/domain/usecases/preload_storefront.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies({
  required ValueNotifier<GraphQLClient> clientNotifier,
  required bool firebaseAvailable,
}) async {
  if (sl.isRegistered<ValueNotifier<GraphQLClient>>()) {
    await sl.reset();
  }

  sl.registerLazySingleton<ValueNotifier<GraphQLClient>>(() => clientNotifier);
  sl.registerLazySingleton<GraphQLClient>(() => clientNotifier.value);
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(
    () =>
        AnalyticsService(firebaseAvailable ? FirebaseAnalytics.instance : null),
  );
  sl.registerLazySingleton(
    () => CrashReportingService(
      firebaseAvailable ? FirebaseCrashlytics.instance : null,
    ),
  );
  sl.registerLazySingleton(
    () => RemoteConfigService(
      firebaseAvailable ? FirebaseRemoteConfig.instance : null,
    ),
  );

  sl.registerLazySingleton(() => AuthRepository(sl()));
  sl.registerLazySingleton<AuthRepositoryContract>(
    () => AuthRepositoryAdapter(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SessionRepository>(() => LocalSessionRepository());
  sl.registerLazySingleton(() => ProductRepository(sl()));
  sl.registerLazySingleton<StorefrontRepository>(
    () => StorefrontRepositoryImpl(sl<ProductRepository>()),
  );
  sl.registerLazySingleton(() => CategoryRepository(sl()));
  sl.registerLazySingleton(() => StoreDiscoveryRepository(sl()));
  sl.registerLazySingleton(() => CheckoutRepository(sl()));
  sl.registerLazySingleton(() => ProfileRepository(sl()));
  sl.registerLazySingleton(() => OrdersRepository(sl(), sl()));
  sl.registerLazySingleton(() => SearchRepository(sl()));

  sl.registerLazySingleton(() => CheckUser(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => SendOtp(sl()));
  sl.registerLazySingleton(() => VerifyOtp(sl()));
  sl.registerLazySingleton(() => ResetPassword(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => PreloadStorefront(sl()));

  sl.registerLazySingleton(
    () => AuthCubit(
      checkUser: sl(),
      loginUser: sl(),
      registerUser: sl(),
      sendOtp: sl(),
      verifyOtp: sl(),
      resetPassword: sl(),
      logoutUser: sl(),
      sessionRepository: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => StorefrontCubit(repository: sl(), preloadStorefront: sl()),
  );
  sl.registerLazySingleton(() => StoreShellCubit());
  sl.registerLazySingleton(() => CategoriesCubit(sl()));
  sl.registerLazySingleton(() => StoreContextCubit());
  sl.registerLazySingleton(() => StoreDiscoveryCubit(sl()));
  sl.registerLazySingleton(() => SearchCubit(sl()));
  sl.registerLazySingleton(() => ProfileCubit(sl()));
  sl.registerLazySingleton(() => FavouriteCubit(sl(), sl()));
  sl.registerFactory(() => OrdersCubit(sl()));
  sl.registerFactory(() => ProductDetailsCubit(sl()));
  sl.registerLazySingleton(() => CartCubit());
  sl.registerLazySingleton(() => CheckoutCubit(sl()));
  sl.registerLazySingleton(() => NotificationCenterCubit());
  sl.registerLazySingleton(() => ConnectivityCubit(sl()));
  sl.registerLazySingleton(() => SettingsCubit());
}
