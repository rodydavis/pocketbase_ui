import 'package:flutter/material.dart';

import 'sign_in.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return BackButton(onPressed: () {
            SignInScreen.of(context).setScreen(AuthScreen.login);
          });
        }),
        title: const Text('Email Verify Screen'),
      ),
    );
  }
}
