import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/config/app_environment.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/features/settings/presentation/cubit/settings_state.dart';

class SettingsCubit extends SafeCubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  static const String _notificationsKey = 'sellhub_notifications_opt_in_v1';

  Future<void> hydrate() async {
    final optInRaw = await LocalStorage.getString(_notificationsKey);
    final notificationPermission = await _requestNotificationPermission(
      provisional: true,
    );
    final locationPermission = await Geolocator.checkPermission();
    emit(
      state.copyWith(
        notificationOptIn: optInRaw != 'false',
        notificationAvailable: _notificationsAvailable,
        notificationGranted:
            notificationPermission?.authorizationStatus !=
            AuthorizationStatus.denied,
        locationGranted: locationPermission == LocationPermission.always ||
            locationPermission == LocationPermission.whileInUse,
      ),
    );
  }

  Future<void> setNotificationOptIn(bool value) async {
    await LocalStorage.saveString(_notificationsKey, value ? 'true' : 'false');
    emit(state.copyWith(notificationOptIn: value));
  }

  Future<void> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    emit(
      state.copyWith(
        locationGranted: permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse,
      ),
    );
  }

  Future<void> requestNotificationPermission() async {
    final permission = await _requestNotificationPermission();
    emit(
      state.copyWith(
        notificationAvailable: _notificationsAvailable,
        notificationGranted:
            permission?.authorizationStatus != AuthorizationStatus.denied,
      ),
    );
  }

  bool get _notificationsAvailable =>
      AppEnvironment.firebaseEnabled && Firebase.apps.isNotEmpty;

  Future<NotificationSettings?> _requestNotificationPermission({
    bool provisional = false,
  }) async {
    if (!_notificationsAvailable) {
      return null;
    }
    return FirebaseMessaging.instance.requestPermission(
      provisional: provisional,
    );
  }
}
