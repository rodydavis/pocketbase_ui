import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, event, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile Screen'),
            actions: [
              TextButton(
                onPressed: () => controller.logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
          body: Builder(builder: (context) {
            if (event == null) {
              return const Center(
                child: Text('No user found'),
              );
            }
            final (_, user) = event;
            if (user is AdminModel) {}
            if (user is RecordModel) {
              final data = user.toJson();
              final displayName = user.getStringValue('name');
              final username = user.getStringValue('username');
              final emailVisibility =
                  user.getBoolValue('emailVisibility', false);
              final email = user.getStringValue('email');
              final verified = user.getBoolValue('verified', false);
              final created = data['created'];
              final updated = data['updated'];
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Card(
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
                                onPressed: () {},
                                child: const Text('Verify'),
                              ),
                            ),
                          if (emailVisibility && email.isNotEmpty)
                            ListTile(
                              title: const Text('Email'),
                              subtitle: Text(email),
                              leading: const Icon(Icons.email),
                              trailing: const Icon(Icons.edit),
                            ),
                          if (username.isNotEmpty)
                            ListTile(
                              title: const Text('Username'),
                              subtitle: Text(username),
                              leading: const Icon(Icons.person_outlined),
                              trailing: const Icon(Icons.edit),
                            ),
                          if (displayName.isNotEmpty)
                            ListTile(
                              title: const Text('Display Name'),
                              subtitle: Text(displayName),
                              leading: const Icon(Icons.person),
                              trailing: const Icon(Icons.edit),
                            ),
                          if (created.isNotEmpty)
                            ListTile(
                              title: const Text('Date Created'),
                              subtitle: Text(created),
                              leading: const Icon(Icons.calendar_today),
                            ),
                          if (updated.isNotEmpty)
                            ListTile(
                              title: const Text('Last Updated'),
                              subtitle: Text(updated),
                              leading: const Icon(Icons.calendar_today),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return const Center(
              child: Text('Error loading user info'),
            );
          }),
        );
      },
    );
  }
}
