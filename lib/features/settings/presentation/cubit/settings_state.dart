import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.notificationOptIn = true,
    this.locationGranted = false,
    this.notificationGranted = false,
    this.notificationAvailable = false,
    this.loading = false,
  });

  final bool notificationOptIn;
  final bool locationGranted;
  final bool notificationGranted;
  final bool notificationAvailable;
  final bool loading;

  SettingsState copyWith({
    bool? notificationOptIn,
    bool? locationGranted,
    bool? notificationGranted,
    bool? notificationAvailable,
    bool? loading,
  }) {
    return SettingsState(
      notificationOptIn: notificationOptIn ?? this.notificationOptIn,
      locationGranted: locationGranted ?? this.locationGranted,
      notificationGranted: notificationGranted ?? this.notificationGranted,
      notificationAvailable:
          notificationAvailable ?? this.notificationAvailable,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [
    notificationOptIn,
    locationGranted,
    notificationGranted,
    notificationAvailable,
    loading,
  ];
}
