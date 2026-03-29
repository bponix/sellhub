import 'package:flutter/material.dart';

import 'auth_screen.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.isResetPassword,
  });

  final bool isResetPassword;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      initialIdentifier: phoneNumber,
      startInForgotMode: isResetPassword,
    );
  }
}
