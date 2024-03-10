part of 'sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    this.automaticallyImplyLeading = true,
    this.actions = const [],
    this.children = const [],
  });

  final bool automaticallyImplyLeading;
  final AuthController controller;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final edited = signal(false);
  final loading = signal(false);
  final _currentError = signal<String?>(null);
  final _formKey = GlobalKey<FormState>();
  final displayName = TextEditingController();
  final username = TextEditingController();
  List<ExternalAuthModel> externalMethods = [];
  OAuth2AuthProvider? loadingProvider;
  late final _user = widget.controller.user$;

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

  void onAuthEvent() async {
    _currentError.value = null;
    final user = widget.controller.user$();
    if (user == null) return;
    loading.value = true;
    externalMethods = await widget //
        .controller
        .authService
        .listExternalAuths(user.id);
    final displayName = user.getStringValue('name');
    final username = user.getStringValue('username');
    if (displayName.isNotEmpty && this.displayName.text != displayName) {
      this.displayName.text = displayName;
    }
    if (username.isNotEmpty && this.username.text != username) {
      this.username.text = username;
    }
  }

  Future<void> link(BuildContext context, OAuth2AuthProvider provider) async {
    try {
      loading.value = true;
      setError(null);
      if (mounted) {
        setState(() {
          loadingProvider = provider;
        });
      }
      debugPrint('Oauth2 ${provider.name}');
      final linked = provider.isLinked(externalMethods);
      if (linked) {
        await provider.unlink();
      } else {
        await provider.authenticate(openUrl);
      }
    } catch (e) {
      debugPrint('Error oath2 with ${provider.name}: $e');
      setError(e);
    }
    if (mounted) {
      setState(() {
        loadingProvider = null;
      });
    }
    loading.value = false;
  }

  @override
  void dispose() {
    _user.dispose();
    super.dispose();
  }

  Future<void> save(BuildContext context) async {
    final user = _user.value;
    if (user == null) return;
    if (!edited()) return;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setError(null);
      loading.value = true;
      try {
        await widget.controller.authService.update(user.id, body: {
          if (username.text != user.getStringValue('username')) ...{
            'username': username.text.trim(),
          },
          if (displayName.text != user.getStringValue('name')) ...{
            'name': displayName.text.trim(),
          },
        });
        edited.value = false;
      } catch (e) {
        debugPrint('Error save info: $e');
        setError(e);
      }
      loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = AuthController.providers;
    final externalAuthProviders = providers.whereType<OAuth2AuthProvider>();
    final error = _currentError.watch(context);
    final user = _user.watch(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Screen'),
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        actions: user == null
            ? []
            : [
                ...widget.actions,
                TextButton(
                  onPressed: () => widget.controller.logout(),
                  child: const Text('Logout'),
                ),
              ],
      ),
      body: Watch.builder(builder: (context) {
        final user = _user.watch(context);
        if (user == null && loading()) {
          return const Center(child: CircularProgressIndicator());
        }
        if (user == null && !loading()) {
          return const Center(child: Text('User not found'));
        }
        final data = user!.toJson();
        final created = data['created'];
        final updated = data['updated'];
        final email = user.getStringValue('email');
        final verified = user.getBoolValue('verified', false);
        final emailVisibility = user.getBoolValue('emailVisibility', false);
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    child: Form(
                      key: _formKey,
                      onChanged: () => edited.value = true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!verified)
                            ListTile(
                              title: const Text('Email Not Verified'),
                              subtitle: const Text('Please verify your email'),
                              leading: Icon(
                                Icons.warning,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              trailing: OutlinedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) => VerifyEmailScreen(
                                            controller: widget.controller,
                                          )),
                                ),
                                child: const Text('Verify'),
                              ),
                            ),
                          if (emailVisibility && email.isNotEmpty)
                            ListTile(
                              title: const Text('Email'),
                              subtitle: Text(email),
                              leading: const Icon(Icons.email),
                              trailing: IconButton(
                                tooltip: 'Request email change',
                                icon: const Icon(Icons.edit),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) => ChangeEmailScreen(
                                            controller: widget.controller,
                                          )),
                                ),
                              ),
                            ),
                          ListTile(
                            title: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outlined),
                                border: OutlineInputBorder(),
                              ),
                              controller: username,
                              validator: (val) {
                                if (val == null) {
                                  return 'Username required';
                                }
                                if (val.isEmpty) {
                                  return 'Username cannot be empty';
                                }
                                return null;
                              },
                            ),
                          ),
                          ListTile(
                            title: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              controller: displayName,
                              validator: (val) {
                                if (val == null) {
                                  return 'Display name required';
                                }
                                if (val.isEmpty) {
                                  return 'Display name cannot be empty';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (edited())
                            ListTile(
                              title: FilledButton.tonal(
                                child: const Text('Save Info'),
                                onPressed: () => save(context),
                              ),
                            ),
                          ListTile(
                            title: OutlinedButton.icon(
                              label: const Text('Change Password'),
                              icon: const Icon(Icons.edit),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChangePasswordScreen(
                                    controller: widget.controller,
                                    model: user,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            title: OutlinedButton.icon(
                              label: const Text('Change Email'),
                              icon: const Icon(Icons.edit),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChangeEmailScreen(
                                    controller: widget.controller,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (externalAuthProviders.isNotEmpty)
                    Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final provider in externalAuthProviders) ...[
                            ListTile(
                              title: FilledButton.tonal(
                                onPressed: loadingProvider == provider
                                    ? null
                                    : () => link(context, provider),
                                child: Builder(builder: (context) {
                                  final action =
                                      provider.isLinked(externalMethods)
                                          ? 'Disconnect'
                                          : 'Connect';
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$action with ${provider.label}'),
                                      if (loadingProvider == provider) ...[
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
                                  );
                                }),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ...widget.children,
                  Card(
                    child: ExpansionTile(
                      title: const Text('Additional Info'),
                      leading: const Icon(Icons.info),
                      children: [
                        if (updated.isNotEmpty)
                          ListTile(
                            title: const Text('Last Modified'),
                            subtitle:
                                Text(timeago.format(DateTime.parse(updated))),
                            leading: const Icon(Icons.calendar_today),
                          ),
                        if (created.isNotEmpty)
                          ListTile(
                            title: const Text('Account Created'),
                            subtitle:
                                Text(timeago.format(DateTime.parse(created))),
                            leading: const Icon(Icons.calendar_today),
                          ),
                      ],
                    ),
                  ),
                  if (error != null && error.isNotEmpty) ...[
                    ListTile(
                      title: Text(
                        error,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
