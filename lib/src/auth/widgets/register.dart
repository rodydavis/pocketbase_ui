part of '../screens/sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.controller,
    this.email,
  });

  final AuthController controller;
  final String? email;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  late final email = TextEditingController(text: widget.email);
  final username = TextEditingController();
  final displayName = TextEditingController();
  final password = TextEditingController();
  final passwordConfirm = TextEditingController();
  final _currentError = signal<String?>(null);
  final publicEmail = signal(true);
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

  Future<void> register(
    BuildContext context,
    EmailAuthProvider provider,
  ) async {
    try {
      final root = SignInScreen.of(context);
      setError(null);
      setLoading(true);
      debugPrint('Registering in with ${provider.name}');
      await provider.register(
        email.text,
        password.text,
        username: username.text,
        name: displayName.text,
        emailVisibility: publicEmail(),
      );
      if (provider.isLoggedIn) root.onLoginSuccess();
    } catch (e) {
      debugPrint('Error registering with ${provider.name}: $e');
      setError(e);
    }
    setLoading(false);
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
      final error = _currentError.watch(context);
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
      final methods = controller.methods$()!;
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
                    'Create a new account',
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
            gap,
            if (methods.usernamePassword)
              TextFormField(
                controller: username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (val) {
                  if (val == null) return 'Username required';
                  if (val.isEmpty) {
                    if (email.text.isNotEmpty && methods.emailPassword) {
                      return null;
                    }
                    return 'Username cannot be empty';
                  }
                  return null;
                },
              ),
            if (methods.emailPassword) ...[
              gap,
              TextFormField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) {
                  if (val == null) return 'Email required';
                  if (val.isEmpty) {
                    if (username.text.isNotEmpty && methods.usernamePassword) {
                      return null;
                    }
                    return 'Email cannot be empty';
                  }
                  if (!val.contains('@')) return 'Invalid email address';
                  return null;
                },
              ),
              gap,
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: publicEmail(),
                onChanged: (val) {
                  publicEmail.value = val;
                },
                title: const Text('Public Email'),
                subtitle: const Text('Email visible to other users'),
              ),
            ],
            gap,
            TextFormField(
              controller: password,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (val) {
                if (val == null) return 'Password required';
                if (val.isEmpty) return 'Password cannot be empty';
                return null;
              },
            ),
            gap,
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
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  await register(context, emailProvider);
                                }
                              },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Register'),
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
                        _currentScreen.set(AuthScreen.login);
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
    });
  }
}
