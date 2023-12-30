part of '../screens/sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  bool showPassword = false;
  String? error;
  bool loading = false;

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

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        this.loading = loading;
      });
    }
  }

  Future<void> login(BuildContext context, AuthProvider provider) async {
    try {
      final root = SignInScreen.of(context);
      setLoading(true);
      setError(null);
      debugPrint('Logging in with ${provider.name}');
      if (provider is EmailAuthProvider) {
        await provider.authenticate(username.text, password.text);
      } else if (provider is OAuth2AuthProvider) {
        await provider.authenticate(openUrl);
      }
      if (provider.isLoggedIn) root.onLoginSuccess();
    } catch (e) {
      debugPrint('Error logging in with ${provider.name}: $e');
      setError(e);
    }
    setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 20);
    final providers = AuthController.providers;
    final emailProvider = providers.whereType<EmailAuthProvider>().firstOrNull;
    final externalAuthProviders = providers.whereType<OAuth2AuthProvider>();
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
              obscureText: !showPassword,
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
                      onPressed: loading
                          ? null
                          : () async {
                              if (emailProvider == null) return;
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                await login(context, emailProvider);
                              }
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Login'),
                          if (loading) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Builder(builder: (context) {
                      return TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                            fullscreenDialog: true,
                          ));
                        },
                        child: const Text('Forgot your password?'),
                      );
                    }),
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
                      _currentScreen.set(AuthScreen.register);
                    },
                    child: const Text('Create a new account'),
                  );
                }),
              ),
            ],
          ),
          gap,
          for (final provider in externalAuthProviders) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: FilledButton.tonal(
                onPressed: () => login(context, provider),
                child: Text('Sign in with ${provider.label}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
