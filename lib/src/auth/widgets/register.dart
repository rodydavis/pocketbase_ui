import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../controller.dart';
import '../providers/email.dart';
import 'sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final email = TextEditingController();
  final displayName = TextEditingController();
  final password = TextEditingController();
  final passwordConfirm = TextEditingController();
  String? error;
  bool publicEmail = true;

  late final AuthController controller = widget.controller;
  late final client = controller.client;
  late final authService = controller.authService;

  void setError(Object? error) {
    if (mounted) {
      setState(() {
        if (error is ClientException) {
          this.error = error.response['message'];
        } else {
          this.error = error?.toString();
        }
      });
    }
  }

  Future<void> register(
    BuildContext context,
    EmailAuthProvider provider,
  ) async {
    try {
      final root = SignInScreen.of(context);
      setError(null);
      debugPrint('Registering in with ${provider.name}');
      await provider.register(
        email.text,
        password.text,
        username: username.text,
        name: displayName.text,
        emailVisibility: publicEmail,
      );
      if (provider.isLoggedIn) root.onLoginSuccess();
    } catch (e) {
      debugPrint('Error registering with ${provider.name}: $e');
      setError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 20);
    final providers = AuthController.providers;
    final emailProvider = providers.whereType<EmailAuthProvider>().firstOrNull;
    if (emailProvider == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Email registration is not available',
            textAlign: TextAlign.center,
            style: fonts.bodyMedium?.copyWith(color: colors.error),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: controller.loadProviders,
            label: const Text('Retry'),
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }
    final methods = controller.methods.value!;
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Register',
                  style: fonts.displaySmall,
                ),
              ),
            ],
          ),
          gap,
          TextFormField(
            controller: displayName,
            decoration: const InputDecoration(labelText: 'Display Name'),
            validator: (val) {
              if (val == null) return 'Display name required';
              if (val.isEmpty) return 'Display name cannot be empty';
              return null;
            },
          ),
          if (methods.usernamePassword)
            TextFormField(
              controller: username,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (val) {
                if (val == null) return 'Username required';
                if (val.isEmpty) return 'Username cannot be empty';
                return null;
              },
            ),
          if (methods.emailPassword) ...[
            TextFormField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (val) {
                if (val == null) return 'Email required';
                if (val.isEmpty) return 'Email cannot be empty';
                if (!val.contains('@')) return 'Invalid email address';
                return null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: publicEmail,
              onChanged: (val) {
                if (mounted) {
                  setState(() {
                    publicEmail = val;
                  });
                }
              },
              title: const Text('Public Email'),
              subtitle: const Text('Email visible to other users'),
            ),
          ],
          TextFormField(
            controller: password,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (val) {
              if (val == null) return 'Password required';
              if (val.isEmpty) return 'Password cannot be empty';
              return null;
            },
          ),
          TextFormField(
            controller: passwordConfirm,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
            validator: (val) {
              if (val == null) return 'Password required';
              if (val.isEmpty) return 'Password cannot be empty';
              if (password.text != val) return 'Passwords do not match';
              return null;
            },
          ),
          if (error != null) ...[
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: fonts.bodyMedium?.copyWith(color: colors.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
          gap,
          Row(
            children: [
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          await register(context, emailProvider);
                        }
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          gap,
          Row(
            children: [
              Expanded(
                child: Builder(builder: (context) {
                  return OutlinedButton(
                    onPressed: () {
                      SignInScreen.of(context).setScreen(AuthScreen.login);
                    },
                    child: const Text('Already have an account?'),
                  );
                }),
              ),
            ],
          ),
          gap,
        ],
      ),
    );
  }
}
