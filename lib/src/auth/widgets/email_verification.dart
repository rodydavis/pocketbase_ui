import 'package:flutter/material.dart';

import '../controller.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({
    super.key,
    required this.controller,
    required this.showLogin,
  });

  final AuthController controller;
  final VoidCallback showLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: showLogin),
        title: const Text('Email Verify Screen'),
      ),
    );
  }
}
