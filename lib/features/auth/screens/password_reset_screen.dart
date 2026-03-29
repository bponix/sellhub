import 'package:flutter/material.dart';

import 'auth_screen.dart';

class PasswordResetScreen extends StatelessWidget {
  const PasswordResetScreen({
    super.key,
    required this.otp,
    required this.phone,
  });

  final int otp;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return AuthScreen(initialIdentifier: phone, startInForgotMode: true);
  }
}
