part of '../screens/sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    this.email,
  });

  final AuthController controller;
  final String? email;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  late final username = TextEditingController(text: widget.email);
  final password = TextEditingController();
  final showPassword = signal(false);
  final _currentError = signal<String?>(null);
  final loading = signal(false);

  late final AuthController controller = widget.controller;
  late final client = controller.client;
  late final authService = controller.authService;

  void setError(Object? error) {
    if (mounted) {
      setState(() {
        if (error is ClientException) {
          if (error.response.containsKey('message')) {
            _currentError.value = error.response['message'].toString();
          } else {
            _currentError.value = error.originalError.toString();
          }
        } else {
          _currentError.value = error?.toString();
        }
      });
    }
  }

  void setLoading(bool loading) {
    this.loading.value = loading;
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

  Future<void> save(
    BuildContext context,
    EmailAuthProvider? emailProvider,
  ) async {
    if (emailProvider == null) return;
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      await login(context, emailProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final fonts = Theme.of(context).textTheme;
      final colors = Theme.of(context).colorScheme;
      const gap = SizedBox(height: 20);
      final providers = AuthController.providers;
      final emailProvider =
          providers.whereType<EmailAuthProvider>().firstOrNull;
      final externalAuthProviders = providers.whereType<OAuth2AuthProvider>();
      final methods = controller.methods$.value!;
      final error = _currentError.watch(context);
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
                    widget.controller.emailCheck
                        ? 'Welcome Back!'
                        : 'Login to existing account',
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
              gap,
              TextFormField(
                controller: password,
                obscureText: !showPassword(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: '${showPassword() ? 'Hide' : 'Show'} Password',
                    onPressed: () {
                      showPassword.value = !showPassword();
                    },
                    icon: Icon(
                      showPassword() ? Icons.visibility_off : Icons.visibility,
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
            gap,
            if (error != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        error,
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
                        onPressed: loading()
                            ? () => setLoading(false)
                            : () => save(context, emailProvider),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Login'),
                            if (loading()) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
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
                              builder: (context) => ForgotPasswordScreen(
                                controller: widget.controller,
                              ),
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
    });
  }
}
