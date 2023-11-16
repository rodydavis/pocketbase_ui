import 'package:flutter/material.dart';

import '../controller.dart';
import 'email_verification.dart';
import 'forgot_password.dart';
import 'login.dart';
import 'register.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    Key? key,
    required this.controller,
    required this.onLoginSuccess,
    this.background,
  }) : super(key: key);

  final AuthController controller;
  final Widget? background;
  final VoidCallback onLoginSuccess;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  var screen = _AuthScreen.login;

  void setScreen(_AuthScreen value) {
    if (mounted) {
      setState(() {
        screen = value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void reassemble() {
    super.reassemble();
    init();
  }

  Future<void> init() async {
    // TODO
  }

  @override
  Widget build(BuildContext context) {
    return _AuthBackgroundBuilder(
      form: (switch (screen) {
        _AuthScreen.login => LoginScreen(
            key: const ValueKey('auth:login'),
            controller: widget.controller,
            showForgotPassword: () => setScreen(_AuthScreen.forgot),
            showEmailVerify: () => setScreen(_AuthScreen.verify),
            showRegister: () => setScreen(_AuthScreen.register),
            onLoginSuccess: widget.onLoginSuccess,
          ),
        _AuthScreen.forgot => ForgotPasswordScreen(
            key: const ValueKey('auth:forgot'),
            controller: widget.controller,
            showLogin: () => setScreen(_AuthScreen.login),
          ),
        _AuthScreen.register => RegisterScreen(
            key: const ValueKey('auth:register'),
            controller: widget.controller,
            showLogin: () => setScreen(_AuthScreen.login),
            onLoginSuccess: widget.onLoginSuccess,
          ),
        _AuthScreen.verify => EmailVerificationScreen(
            key: const ValueKey('auth:verify'),
            controller: widget.controller,
            showLogin: () => setScreen(_AuthScreen.login),
          ),
      }),
      background: widget.background,
    );
  }
}

class _AuthBackgroundBuilder extends StatelessWidget {
  const _AuthBackgroundBuilder({
    required this.form,
    required this.background,
  });

  final Widget form;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final Widget child = Builder(
      builder: (context) {
        if (size.height < 500) {
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: form,
                ),
              ),
            ),
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: form,
            ),
          ),
        );
      },
    );
    if (size.width > 900 && background != null) {
      return Material(
        child: Row(
          children: [
            SizedBox(
              width: 500,
              height: double.infinity,
              child: child,
            ),
            Expanded(
              child: SizedBox.expand(
                child: background!,
              ),
            ),
          ],
        ),
      );
    }
    return Material(child: child);
  }
}

enum _AuthScreen {
  login,
  register,
  forgot,
  verify,
}
