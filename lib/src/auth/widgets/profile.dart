import 'package:flutter/material.dart';

import '../controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Screen'),
        actions: [
          IconButton(
            onPressed: () => controller.logout(),
            icon: const Icon(Icons.exit_to_app),
          )
        ],
      ),
    );
  }
}
