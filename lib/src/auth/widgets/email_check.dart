
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../controller.dart';
import '../screens/sign_in.dart';

class EmailCheck extends StatefulWidget {
  const EmailCheck({super.key, required this.controller});

  final AuthController controller;

  @override
  State<EmailCheck> createState() => _EmailCheckState();
}

class _EmailCheckState extends State<EmailCheck> {
  final _currentScreen = signal<AuthScreen?>(null);
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<void> checkEmail(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final email = controller.text.trim();
      try {
        final model = await widget.controller.checkIfUserExistsForEmail(email);
        if (model != null) {
          _currentScreen.value = AuthScreen.login;
        } else {
          _currentScreen.value = AuthScreen.register;
        }
      } catch (e, t) {
        messenger.showSnackBar(SnackBar(
          content: Text('Error checking email "$email": $e'),
        ));
        widget.controller.client.storage.log.log(
          'Error checking email "$email"',
          error: e,
          stackTrace: t,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final screen = _currentScreen();
      if (screen == AuthScreen.login) {
        return LoginScreen(controller: widget.controller);
      }
      if (screen == AuthScreen.register) {
        return RegisterScreen(controller: widget.controller);
      }
      return Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sign In',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              title: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  label: Text('Email'),
                ),
                validator: (val) {
                  if (val == null) return 'Email required';
                  if (val.isEmpty) return 'Email cannot be empty';
                  if (!val.contains('@')) return 'Email much contain @';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: FilledButton(
                onPressed: () => checkEmail(context),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      );
    });
  }
}
