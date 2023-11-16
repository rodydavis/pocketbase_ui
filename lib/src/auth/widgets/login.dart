import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../utils/open_url.dart';
import '../controller.dart';
import '../providers/base.dart';
import '../providers/email.dart';
import '../providers/oauth2.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    Key? key,
    required this.controller,
    required this.showForgotPassword,
    required this.showRegister,
    required this.showEmailVerify,
    required this.onLoginSuccess,
  }) : super(key: key);

  final AuthController controller;
  final VoidCallback showForgotPassword, showRegister, showEmailVerify;
  final VoidCallback onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  bool showPassword = false;
  static AuthMethodsList? methods;
  String? error;

  late final client = widget.controller.client;
  late final authService = widget.controller.authService;
  late final providers = widget.controller.providers;

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

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    if (oldWidget.controller != widget.controller) {
      init();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> init() async {
    await loadProviders();
  }

  Future<void> loadProviders() async {
    try {
      final methods = await authService.listAuthMethods();
      if (mounted) {
        setState(() {
          _LoginScreenState.methods = methods;
        });
      }
    } catch (e) {
      debugPrint('Error loading auth providers: $e');
      setError(e);
    }
  }

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

  Future<void> login(BuildContext context, AuthProvider provider) async {
    try {
      setError(null);
      debugPrint('Logging in with ${provider.name}');
      if (provider is EmailAuthProvider) {
        await provider.authenticate(username.text, password.text);
      } else if (provider is OAuth2AuthProvider) {
        await provider.authenticate(openUrl);
      }
      if (provider.isLoggedIn) widget.onLoginSuccess();
    } catch (e) {
      debugPrint('Error logging in with ${provider.name}: $e');
      setError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 20);
    if (_LoginScreenState.methods == null) {
      if (error != null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: error,
              child: Text(
                'Error loading authentication providers',
                textAlign: TextAlign.center,
                style: fonts.bodyMedium?.copyWith(color: colors.error),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: loadProviders,
              label: const Text('Retry'),
              icon: const Icon(Icons.refresh),
            ),
          ],
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    }
    final emailProvider = providers.whereType<EmailAuthProvider>().firstOrNull;
    final externalAuthProviders = providers.whereType<OAuth2AuthProvider>();
    final methods = _LoginScreenState.methods!;
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
                  'Sign In',
                  style: fonts.displaySmall,
                ),
              ),
            ],
          ),
          gap,
          if (emailProvider != null) ...[
            Builder(builder: (context) {
              final emailOk = methods.emailPassword;
              final usernameOk = methods.usernamePassword;
              final label = (switch ((emailOk, usernameOk)) {
                (true, true) => 'Username or Email',
                (true, false) => 'Email',
                (false, true) => 'Username',
                (false, false) => 'N/A',
              });
              return TextFormField(
                controller: username,
                decoration: InputDecoration(
                  labelText: label,
                ),
                validator: (val) {
                  if (val == null) return '$label required';
                  if (val.isEmpty) return '$label cannot be empty';
                  return null;
                },
              );
            }),
            TextFormField(
              controller: password,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  tooltip: '${showPassword ? 'Hide' : 'Show'} Password',
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    }
                  },
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null) return 'Password required';
                if (val.isEmpty) return 'Password cannot be empty';
                return null;
              },
            ),
          ],
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
                        if (emailProvider == null) return;
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          await login(context, emailProvider);
                        }
                      },
                      child: const Text('Login'),
                    ),
                    TextButton(
                      onPressed: widget.showForgotPassword,
                      child: const Text('Forgot your password?'),
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
                child: OutlinedButton(
                  onPressed: widget.showRegister,
                  child: const Text('Create a new account'),
                ),
              ),
            ],
          ),
          gap,
          for (final provider in externalAuthProviders) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => login(context, provider),
                    child: Text('Sign in with ${provider.label}'),
                  ),
                ),
              ],
            ),
            gap,
          ],
        ],
      ),
    );
  }
}
