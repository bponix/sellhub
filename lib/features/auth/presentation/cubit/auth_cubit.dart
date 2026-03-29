import 'dart:async';

import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/core/notifications/push_notification_service.dart';
import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:sellhub/features/auth/domain/repositories/session_repository.dart';
import 'package:sellhub/features/auth/domain/usecases/check_user.dart';
import 'package:sellhub/features/auth/domain/usecases/login_user.dart';
import 'package:sellhub/features/auth/domain/usecases/logout_user.dart';
import 'package:sellhub/features/auth/domain/usecases/register_user.dart';
import 'package:sellhub/features/auth/domain/usecases/reset_password.dart';
import 'package:sellhub/features/auth/domain/usecases/send_otp.dart';
import 'package:sellhub/features/auth/domain/usecases/verify_otp.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends SafeCubit<AuthState> {
  AuthCubit({
    required CheckUser checkUser,
    required LoginUser loginUser,
    required RegisterUser registerUser,
    required SendOtp sendOtp,
    required VerifyOtp verifyOtp,
    required ResetPassword resetPassword,
    required LogoutUser logoutUser,
    required SessionRepository sessionRepository,
  }) : _checkUser = checkUser,
       _loginUser = loginUser,
       _registerUser = registerUser,
       _sendOtp = sendOtp,
       _verifyOtp = verifyOtp,
       _resetPassword = resetPassword,
       _logoutUser = logoutUser,
       _sessionRepository = sessionRepository,
       super(const AuthState());

  final CheckUser _checkUser;
  final LoginUser _loginUser;
  final RegisterUser _registerUser;
  final SendOtp _sendOtp;
  final VerifyOtp _verifyOtp;
  final ResetPassword _resetPassword;
  final LogoutUser _logoutUser;
  final SessionRepository _sessionRepository;
  Timer? _resendTimer;
  String? _lastIdentifier;
  String? _lastOtpSource;
  int? _lastOtpSourceId;

  String _normalizeIdentifier(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('@')) {
      return trimmed.toLowerCase();
    }
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('88')) {
      return digits;
    }
    return '88$digits';
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    emit(state.copyWith(resendSeconds: 60));
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendSeconds - 1;
      if (next <= 0) {
        timer.cancel();
        emit(state.copyWith(resendSeconds: 0));
        return;
      }
      emit(state.copyWith(resendSeconds: next));
    });
  }

  Future<User?> checkUser(String identifier) async {
    final normalized = _normalizeIdentifier(identifier);
    _lastIdentifier = normalized;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await _checkUser(normalized);
      emit(
        state.copyWith(
          isLoading: false,
          user: user,
          userId: user?.id,
          status: user == null ? AuthStatus.register : AuthStatus.login,
          clearError: true,
        ),
      );
      return user;
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          status: AuthStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to verify user.',
          ),
        ),
      );
      return null;
    }
  }

  Future<bool> login(String identifier, String password) async {
    final normalized = _normalizeIdentifier(identifier);
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = state.user ?? await _checkUser(normalized);
      if (user == null) {
        throw const AppFailure(title: 'User not found');
      }
      final token = await _loginUser(
        userId: user.id.toString(),
        password: password,
      );
      if (token.isEmpty) {
        throw const AppFailure(title: 'Invalid credentials');
      }
      await _sessionRepository.saveSession(user: user, token: token);
      await PushNotificationService.syncSubscriptions();
      emit(
        state.copyWith(
          isLoading: false,
          user: user,
          userId: user.id,
          status: AuthStatus.authenticated,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          status: AuthStatus.failure,
          error: error is AppFailure
              ? error
              : AppFailure.fromObject(
                  error,
                  fallbackTitle: 'Unable to sign in.',
                ),
        ),
      );
      return false;
    }
  }

  Future<bool> register(SignUpReq model) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await _registerUser(model);
      if (user == null) {
        throw const AppFailure(title: 'Registration failed');
      }
      final response = await _sendOtp(
        userId: user.id,
        source: model.source ?? 'bponi_store_app',
        sourceId: model.sourceId ?? 82616,
      );
      if (response == null || response.phone.isEmpty) {
        throw const AppFailure(title: 'OTP send failed');
      }
      _lastIdentifier = model.username;
      _lastOtpSource = model.source ?? 'bponi_store_app';
      _lastOtpSourceId = model.sourceId ?? 82616;
      _startResendCountdown();
      emit(
        state.copyWith(
          isLoading: false,
          user: user,
          userId: user.id,
          status: AuthStatus.otpSent,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          status: AuthStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to create account.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> sendOtp(String source, int sourceId, String identifier) async {
    final normalized = _normalizeIdentifier(identifier);
    _lastIdentifier = normalized;
    _lastOtpSource = source;
    _lastOtpSourceId = sourceId;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = state.user ?? await _checkUser(normalized);
      if (user == null) {
        throw const AppFailure(title: 'User not found');
      }
      final response = await _sendOtp(
        userId: user.id,
        source: source,
        sourceId: sourceId,
      );
      final success = response != null && response.phone.isNotEmpty;
      if (!success) {
        throw const AppFailure(title: 'OTP send failed');
      }
      _startResendCountdown();
      emit(
        state.copyWith(
          isLoading: false,
          user: user,
          userId: user.id,
          status: AuthStatus.otpSent,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          status: AuthStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to send OTP.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> resendOtp() async {
    final identifier = _lastIdentifier;
    final source = _lastOtpSource;
    final sourceId = _lastOtpSourceId;
    if (identifier == null || source == null || sourceId == null) {
      emit(
        state.copyWith(
          error: const AppFailure(title: 'Unable to resend code right now.'),
        ),
      );
      return false;
    }
    return sendOtp(source, sourceId, identifier);
  }

  Future<bool> verifyOtp(
    int otp,
    String identifier, {
    bool isResetFlow = false,
  }) async {
    final normalized = _normalizeIdentifier(identifier);
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = state.user ?? await _checkUser(normalized);
      if (user == null) {
        throw const AppFailure(title: 'User not found');
      }
      final response = await _verifyOtp(userId: user.id, otp: otp);
      final success = response != null && response.phone.isNotEmpty;
      if (!success) {
        throw const AppFailure(title: 'Invalid OTP');
      }
      emit(
        state.copyWith(
          isLoading: false,
          user: response,
          userId: response.id,
          status: isResetFlow
              ? AuthStatus.otpVerifiedForReset
              : AuthStatus.verificationSuccess,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          status: AuthStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to verify OTP.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> resetPassword(
    String identifier,
    int otp,
    String newPassword,
  ) async {
    final normalized = _normalizeIdentifier(identifier);
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = state.user ?? await _checkUser(normalized);
      if (user == null) {
        throw const AppFailure(title: 'User not found');
      }
      final response = await _resetPassword(
        userId: user.id,
        phone: normalized,
        otp: otp,
        newPassword: newPassword,
      );
      final success = response != null && response.phone.isNotEmpty;
      if (!success) {
        throw const AppFailure(title: 'Password reset failed');
      }
      emit(
        state.copyWith(
          isLoading: false,
          user: response,
          userId: response.id,
          status: AuthStatus.passwordReset,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          status: AuthStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to reset password.',
          ),
        ),
      );
      return false;
    }
  }

  void resetFlow() {
    _resendTimer?.cancel();
    emit(
      const AuthState(
        status: AuthStatus.initial,
        isLoading: false,
        resendSeconds: 0,
      ),
    );
  }

  Future<void> logout() async {
    await _logoutUser();
    await PushNotificationService.unsubscribeAll();
    emit(const AuthState());
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }
}
