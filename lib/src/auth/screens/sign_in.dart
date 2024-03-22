import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:signals/signals_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../utils/open_url.dart';
import '../controller.dart';
import '../providers/base.dart';
import '../providers/email.dart';
import '../providers/oauth2.dart';
import '../widgets/email_check.dart';
import 'change_email.dart';
import 'change_password.dart';
import 'forgot_password.dart';
import 'verify_email.dart';

part '../widgets/login.dart';
part '../widgets/register.dart';
part 'profile.dart';

final _currentScreen = signal(AuthScreen.login);

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

  static SignInScreenState of(BuildContext context) {
    return context.findAncestorStateOfType<SignInScreenState>()!;
  }

  @override
  State<SignInScreen> createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  late final AuthController controller = widget.controller;
  final _currentError = signal<String?>(null);
  final showCheck = signal(true);
  String? email;

  void setError(Object? error) {
    if (error is ClientException) {
      if (error.response.containsKey('message')) {
        _currentError.value = error.response['message'].toString();
      } else {
        _currentError.value = error.originalError.toString();
      }
    } else {
      _currentError.value = error?.toString();
    }
  }

  void onLoginSuccess() => widget.onLoginSuccess();

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final healthy = controller.healthy.watch(context);
    if (!healthy) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Server is down. Please try again later.\n(trying again in 30 seconds)',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _AuthBackgroundBuilder(
        background: widget.background,
        form: Watch.builder(
          builder: (context) {
            final methods = controller.methods$();
            if (methods == null) {
              final err = _currentError.watch(context);
              if (err != null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: err,
                      child: Text(
                        'Error loading authentication providers',
                        textAlign: TextAlign.center,
                        style: fonts.bodyMedium?.copyWith(color: colors.error),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: controller.loadProviders,
                      label: const Text('Retry'),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                );
              } else {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading authentication providers...'),
                    ],
                  ),
                );
              }
            }
            return SingleChildScrollView(
              child: EmailCheck(
                controller: controller,
                onResult: (val) {
                  _currentScreen.set(val.$2);
                  email = val.$1;
                  showCheck.value = false;
                },
              ),
            );
          },
        ),
      ),
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

enum AuthScreen {
  login,
  register,
}
