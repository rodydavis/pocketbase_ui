import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../controller.dart';
import '../screens/sign_in.dart';

class EmailCheck extends StatefulWidget {
  const EmailCheck({
    super.key,
    required this.controller,
    required this.onResult,
  });

  final AuthController controller;
  final ValueChanged<(String, AuthScreen)> onResult;

  @override
  State<EmailCheck> createState() => _EmailCheckState();
}

class _EmailCheckState extends State<EmailCheck> {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final loading = signal(false);

  Future<void> checkEmail(BuildContext context) async {
    loading.value = true;
    final messenger = ScaffoldMessenger.of(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final email = controller.text.trim();
      try {
        final model = await widget.controller.checkIfUserExistsForEmail(email);
        if (model != null) {
          widget.onResult((email, AuthScreen.login));
        } else {
          widget.onResult((email, AuthScreen.register));
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
    loading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
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
                onPressed: loading() ? null : () => checkEmail(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Continue'),
                    if (loading()) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
