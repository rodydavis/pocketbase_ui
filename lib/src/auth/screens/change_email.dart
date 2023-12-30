import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../controller.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  late final controller = widget.controller;
  final _error = signal<String?>(null);
  final _sent = signal(false);
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _token = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final sent = _sent.watch(context);
    final fonts = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Email'),
        actions: [
          if (sent)
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Reset',
              onPressed: () => _sent.value = false,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Watch.builder(
            builder: (context) {
              final error = _error.watch(context);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      if (sent) ...[
                        ListTile(
                          title: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Token from email',
                              prefixIcon: Icon(Icons.info_outline),
                              border: OutlineInputBorder(),
                            ),
                            controller: _token,
                            validator: (val) {
                              if (val == null) {
                                return 'Token required';
                              }
                              if (val.isEmpty) {
                                return 'Token cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ),
                        ListTile(
                          title: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Current Password',
                              border: OutlineInputBorder(),
                            ),
                            controller: _password,
                            validator: (val) {
                              if (val == null) {
                                return 'Password required';
                              }
                              if (val.isEmpty) {
                                return 'Password cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ),
                        FilledButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            if (_formKey.currentState!.validate()) {
                              try {
                                _formKey.currentState!.save();
                                await controller.authService.confirmEmailChange(
                                  _token.text.trim(),
                                  _password.text.trim(),
                                );
                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('Password reset!')),
                                );
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                _sent.value = false;
                                navigator.pop();
                              } catch (e) {
                                _error.value = e.toString();
                              }
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ] else ...[
                        ListTile(
                          title: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'New Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            controller: _email,
                            validator: (val) {
                              if (val == null) {
                                return 'Email required';
                              }
                              if (val.isEmpty) {
                                return 'Email cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ),
                        FilledButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (_formKey.currentState!.validate()) {
                              try {
                                _formKey.currentState!.save();
                                final email = _email.text.trim();
                                await controller.authService
                                    .requestEmailChange(email);
                                messenger.showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Email with token sent to $email')),
                                );
                                _sent.value = true;
                              } catch (e) {
                                _error.value = e.toString();
                              }
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ],
                      if (error != null)
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  error,
                                  textAlign: TextAlign.center,
                                  style: fonts.bodyMedium
                                      ?.copyWith(color: colors.error),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
