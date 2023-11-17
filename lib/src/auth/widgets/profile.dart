import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../utils/open_url.dart';
import '../controller.dart';
import '../providers/oauth2.dart';
import 'change_email.dart';
import 'change_password.dart';
import 'verify_email.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool edited = false;
  bool loading = false;
  String? error;
  final _formKey = GlobalKey<FormState>();
  final displayName = TextEditingController();
  final username = TextEditingController();
  String email = '';
  bool emailVisibility = false;
  bool verified = false;
  bool userFound = false;
  String dateCreated = '', dateModified = '';
  List<ExternalAuthModel> externalMethods = [];
  bool isAdmin = false;
  OAuth2AuthProvider? loadingProvider;

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        this.loading = loading;
      });
    }
  }

  void setError(Object? error) {
    if (mounted) {
      setState(() {
        if (error is ClientException) {
          this.error = error.originalError.toString();
        } else {
          this.error = error?.toString();
        }
      });
    }
  }

  void setEdited(bool edited) {
    if (mounted) {
      setState(() {
        this.edited = edited;
      });
    }
  }

  void onAuthEvent() async {
    isAdmin = false;
    error = null;
    if (widget.controller.value == null) {
      if (mounted) {
        setState(() {
          userFound = false;
        });
      }
      return;
    }
    final (_, user) = widget.controller.value!;
    if (user is AdminModel) {
      if (mounted) {
        setState(() {
          isAdmin = true;
        });
      }
    } else if (user is RecordModel) {
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
      final data = user.toJson();
      final created = data['created'];
      final updated = data['updated'];
      final email = user.getStringValue('email');
      final verified = user.getBoolValue('verified', false);
      final emailVisibility = user.getBoolValue('emailVisibility', false);
      if (mounted) {
        setState(() {
          this.email = email;
          this.emailVisibility = emailVisibility;
          this.verified = verified;
          dateCreated = created;
          dateModified = updated;
          userFound = true;
        });
      }
    }
  }

  Future<void> link(BuildContext context, OAuth2AuthProvider provider) async {
    try {
      setLoading(true);
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
    setLoading(false);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(onAuthEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onAuthEvent();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(onAuthEvent);
    super.dispose();
  }

  Future<void> save(BuildContext context) async {}

  @override
  Widget build(BuildContext context) {
    final providers = AuthController.providers;
    final externalAuthProviders = providers.whereType<OAuth2AuthProvider>();
    return ValueListenableBuilder(
      valueListenable: widget.controller,
      builder: (context, event, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile Screen'),
            actions: [
              TextButton(
                onPressed: () => widget.controller.logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
          body: Builder(builder: (context) {
            // TODO: Delete / logout
            if (!userFound && loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!userFound && !loading) {
              return const Center(child: Text('User not found'));
            }
            if (isAdmin) {
              return const Center(child: Text('Admin user'));
            }
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
                          onChanged: () => setEdited(true),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!verified)
                                ListTile(
                                  title: const Text('Email Not Verified'),
                                  subtitle:
                                      const Text('Please verify your email'),
                                  leading: Icon(
                                    Icons.warning,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  trailing: OutlinedButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const VerifyEmailScreen()),
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
                                          builder: (context) =>
                                              const ChangeEmailScreen()),
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
                              ListTile(
                                title: OutlinedButton.icon(
                                  label: const Text('Change Password'),
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ChangePasswordScreen()),
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
                                          Text(
                                              '$action with ${provider.label}'),
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
                      Card(
                        child: ExpansionTile(
                          title: const Text('Additional Info'),
                          leading: const Icon(Icons.info),
                          children: [
                            if (dateModified.isNotEmpty)
                              ListTile(
                                title: const Text('Last Modified'),
                                subtitle: Text(timeago
                                    .format(DateTime.parse(dateModified))),
                                leading: const Icon(Icons.calendar_today),
                              ),
                            if (dateCreated.isNotEmpty)
                              ListTile(
                                title: const Text('Account Created'),
                                subtitle: Text(timeago
                                    .format(DateTime.parse(dateCreated))),
                                leading: const Icon(Icons.calendar_today),
                              ),
                          ],
                        ),
                      ),
                      if (error != null && error!.isNotEmpty) ...[
                        ListTile(
                          title: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
      },
    );
  }
}
