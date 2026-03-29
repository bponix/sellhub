import 'package:flutter/material.dart';

import 'auth_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(startInForgotMode: true);
  }
}
