import 'package:flutter/material.dart';

import 'auth_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    this.onAuthenticatedLocation,
  });

  final String? onAuthenticatedLocation;

  @override
  Widget build(BuildContext context) {
    return AuthScreen(onAuthenticatedLocation: onAuthenticatedLocation);
  }
}
