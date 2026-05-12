import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sellhub/core/config/app_environment.dart';
import 'package:sellhub/core/navigation/deep_link_service.dart';
import 'package:sellhub/core/config/app_providers.dart';
import 'package:sellhub/core/config/app_text.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/network/graphql_service.dart';
import 'package:sellhub/core/network/connectivity_cubit.dart';
import 'package:sellhub/core/notifications/local_notification_service.dart';
import 'package:sellhub/core/notifications/notification_center_cubit.dart';
import 'package:sellhub/core/notifications/push_notification_service.dart';
import 'package:sellhub/core/services/analytics_service.dart';
import 'package:sellhub/core/services/crash_reporting_service.dart';
import 'package:sellhub/core/services/remote_config_service.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/store/store_context_state.dart';
import 'package:sellhub/core/theme/app_theme.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/route_names.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widgets/app_update_gate.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:sellhub/features/cart/data/models/cart_item_model.dart';
import 'package:sellhub/features/main_screen.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_state.dart';
import 'package:sellhub/injection_container.dart' as di;
import 'package:hugeicons/hugeicons.dart';

class AppStartupState {
  AppStartupState._();

  static final ValueNotifier<Set<String>> degradedServices =
      ValueNotifier<Set<String>>(<String>{});

  static final ValueNotifier<Map<String, int>> initStepLatencyMs =
      ValueNotifier<Map<String, int>>(<String, int>{});

  static void markDegraded(String service) {
    degradedServices.value = Set<String>.from(degradedServices.value)
      ..add(service);
  }

  static void markStepLatency(String step, int latencyMs) {
    initStepLatencyMs.value = Map<String, int>.from(initStepLatencyMs.value)
      ..[step] = latencyMs;
  }
}

Future<void> _runInitStep(String name, Future<void> Function() action) async {
  final watch = Stopwatch()..start();
  try {
    await action();
  } catch (error, stackTrace) {
    developer.log(
      'Startup step failed: $name, error=$error',
      stackTrace: stackTrace,
      name: 'store.main',
    );
    AppStartupState.markDegraded(name);
  } finally {
    if (watch.isRunning) watch.stop();
    AppStartupState.markStepLatency(name, watch.elapsedMilliseconds);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorage.init();

  Hive
    ..registerAdapter(UserAdapter())
    ..registerAdapter(CartItemAdapter())
    ..registerAdapter(ProductResCommonAdapter())
    ..registerAdapter(FeatureAdapter())
    ..registerAdapter(ProductImageAdapter())
    ..registerAdapter(VariantAdapter());

  final clientNotifier = await GraphQLService.initClient();
  var firebaseAvailable = false;
  if (AppEnvironment.firebaseEnabled) {
    await _runInitStep('firebase', () async {
      firebaseAvailable = true;
    });
  } else {
    AppStartupState.markDegraded('firebase');
  }

  await di.initDependencies(
    clientNotifier: clientNotifier,
    firebaseAvailable: firebaseAvailable,
  );
  final notificationCenterCubit = di.sl<NotificationCenterCubit>();
  final connectivityCubit = di.sl<ConnectivityCubit>();
  final storeContextCubit = di.sl<StoreContextCubit>();
  final crashReporting = di.sl<CrashReportingService>();
  final remoteConfig = di.sl<RemoteConfigService>();
  final analytics = di.sl<AnalyticsService>();

  crashReporting.registerGlobalHandlers();

  await _runInitStep('active_store', () => storeContextCubit.hydrate());
  await _runInitStep('connectivity', () => connectivityCubit.initialize());
  await _runInitStep('remote_config', () => remoteConfig.initialize());
  await _runInitStep(
    'notification_center',
    () => notificationCenterCubit.hydrate(),
  );
  await _runInitStep(
    'local_notifications',
    () => LocalNotificationService.instance.initialize(),
  );
  if (firebaseAvailable) {
    await _runInitStep(
      'push_notifications',
      () => PushNotificationService.initialize(
        notificationCenterCubit: notificationCenterCubit,
      ),
    );
    await _runInitStep(
      'push_sync',
      () => PushNotificationService.syncSubscriptions(),
    );
  } else {
    AppStartupState.markDegraded('push_notifications');
    AppStartupState.markDegraded('push_sync');
  }
  await _runInitStep('deep_links', () => DeepLinkService.initialize());
  await _runInitStep('analytics', () => analytics.logAppOpen());

  runApp(MyApp(clientNotifier: clientNotifier));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.clientNotifier});

  final ValueNotifier<GraphQLClient> clientNotifier;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final payload = await LocalNotificationService.instance
          .consumePendingPayload();
      await PushNotificationService.handleLocalNotificationPayload(payload);
      await DeepLinkService.consumePendingLink();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      clientNotifier: widget.clientNotifier,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) =>
            BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
              builder: (context, notificationState) {
                return BlocBuilder<ConnectivityCubit, ConnectivityState>(
                  builder: (context, connectivityState) {
                    return MaterialApp.router(
                      title: notificationState.unreadCount > 0
                          ? '${AppText.appName} (${notificationState.unreadCount})'
                          : AppText.appName,
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.light(),
                      routerConfig: AppRouter.router,
                      builder: (context, child) {
                        return BlocBuilder<
                          StoreContextCubit,
                          StoreContextState
                        >(
                          builder: (context, storeContextState) {
                            return BlocBuilder<
                              StoreShellCubit,
                              StoreShellState
                            >(
                              builder: (context, shellState) {
                                final showPersistentNav =
                                    _shouldShowPersistentStoreNav(
                                      storeContextState: storeContextState,
                                    );
                                return AppUpdateGate(
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          bottom: showPersistentNav ? 86 : 0,
                                        ),
                                        child: child ?? const SizedBox.shrink(),
                                      ),
                                      if (showPersistentNav)
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: SellerBottomNavBar(
                                            currentIndex:
                                                shellState.currentIndex,
                                          ),
                                        ),
                                      if (connectivityState.status ==
                                          ConnectivityStatus.offline)
                                        const _OfflineBanner(),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
      ),
    );
  }
}

bool _shouldShowPersistentStoreNav({
  required StoreContextState storeContextState,
}) {
  final path = AppRouter.router.routeInformationProvider.value.uri.path
      .toLowerCase();
  const hiddenRoutes = <String>{'/${RouteNames.splash}', '/${RouteNames.home}'};

  return !hiddenRoutes.contains(path);
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF15211D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppHugeIcon(
                  HugeIcons.strokeRoundedCloud,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Offline. Some data may be stale.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
