import 'package:sellhub/features/auth/presentation/cubit/auth_state.dart';

extension AuthStateUIHelpers on AuthState {
  bool isInitialMode() =>
      status == AuthStatus.initial || status == AuthStatus.failure;

  bool isLoginMode(bool isForgot) => status == AuthStatus.login && !isForgot;

  bool isForgotMode(bool isForgot) => status == AuthStatus.login && isForgot;

  bool isRegisterMode() => status == AuthStatus.register;

  bool isOtpMode(bool isForgot) => status == AuthStatus.otpSent;

  bool isResetMode() => status == AuthStatus.otpVerifiedForReset;

  String getMainTitle(bool isCompany, bool isForgot) {
    if (isInitialMode()) return "Let's get you signed in";
    if (isForgotMode(isForgot)) return 'Reset your password';
    if (isLoginMode(isForgot)) return 'Welcome back';
    if (isRegisterMode()) return 'Create your account';
    if (isOtpMode(isForgot)) {
      return isForgot ? 'Verify to reset' : 'Verify your phone';
    }
    if (isResetMode()) return 'Choose a new password';
    return 'Welcome';
  }

  String getSubtitle(bool isForgot) {
    if (isInitialMode()) {
      return 'Enter your email or mobile number to get started.';
    }
    if (isForgotMode(isForgot)) {
      return "We'll send a 6-digit code to your verified contact.";
    }
    if (isLoginMode(isForgot)) {
      return 'Enter your password to pick up where you left off.';
    }
    if (isRegisterMode()) return 'Create a secure password to finish setup.';
    if (isOtpMode(isForgot)) return 'Enter the 6-digit code we just sent.';
    if (isResetMode()) return 'Set a new password for your account.';
    return 'Please enter your details.';
  }

  String getButtonText(bool isForgot) {
    if (isInitialMode()) return 'Continue';
    if (isForgotMode(isForgot)) return 'Send code';
    if (isLoginMode(isForgot)) return 'Sign in';
    if (isRegisterMode()) return 'Create account';
    if (isOtpMode(isForgot)) return isForgot ? 'Verify code' : 'Verify';
    if (isResetMode()) return 'Update password';
    return 'Continue';
  }
}
