import 'package:flutter/material.dart';

import 'sign_in.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return BackButton(onPressed: () {
            SignInScreen.of(context).setScreen(AuthScreen.login);
          });
        }),
        title: const Text('Forgot Password Screen'),
      ),
    );
  }
}
