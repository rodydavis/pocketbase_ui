import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:signals/signals_flutter.dart';

import '../controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.controller,
    required this.model,
  });

  final AuthController controller;
  final RecordModel model;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final controller = widget.controller;
  final _error = signal<String?>(null);
  final _formKey = GlobalKey<FormState>();
  final _password1 = TextEditingController();
  final _password2 = TextEditingController();
  final _password3 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
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
                      ListTile(
                        title: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Old Password',
                            border: OutlineInputBorder(),
                          ),
                          controller: _password1,
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
                      ListTile(
                        title: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'New Password',
                            border: OutlineInputBorder(),
                          ),
                          controller: _password2,
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
                      ListTile(
                        title: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Password Confirm',
                            border: OutlineInputBorder(),
                          ),
                          controller: _password3,
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
                              await controller.authService
                                  .update(widget.model.id, body: {
                                'oldPassword': _password1.text.trim(),
                                'password': _password2.text.trim(),
                                'passwordConfirm': _password3.text.trim(),
                              });
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Password changed!')),
                              );
                              await controller.authService.authRefresh();
                              await Future.delayed(const Duration(seconds: 1));
                              navigator.pop();
                            } catch (e) {
                              _error.value = e.toString();
                            }
                          }
                        },
                        child: const Text('Submit'),
                      ),
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
