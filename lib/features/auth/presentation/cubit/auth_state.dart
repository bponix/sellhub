import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  login,
  register,
  otpSent,
  verificationSuccess,
  otpVerifiedForReset,
  passwordReset,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.userId,
    this.resendSeconds = 0,
    this.isLoading = false,
    this.error,
  });

  final AuthStatus status;
  final User? user;
  final int? userId;
  final int resendSeconds;
  final bool isLoading;
  final AppFailure? error;
  String? get errorMessage => error?.title;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    int? userId,
    int? resendSeconds,
    bool? isLoading,
    AppFailure? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      userId: userId ?? this.userId,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    userId,
    resendSeconds,
    isLoading,
    error,
  ];
}
