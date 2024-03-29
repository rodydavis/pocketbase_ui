import 'package:pocketbase/pocketbase.dart';

import 'base.dart';

/// Email provider to login with username / email and password
class EmailAuthProvider extends AuthProvider {
  @override
  final String name = 'email';

  EmailAuthProvider();

  @override
  bool isSupported(AuthMethodsList value) {
    return value.emailPassword || value.usernamePassword;
  }

  Future<void> authenticate(
    final String username,
    final String password,
  ) async {
    await authService.authWithPassword(username, password);
  }

  Future<void> register(
    final String email,
    final String password, {
    String? username,
    String? name,
    bool emailVisibility = false,
  }) async {
    await authService.create(
      body: {
        'email': email,
        'emailVisibility': emailVisibility,
        'password': password,
        'passwordConfirm': password,
        if (username != null && username.isNotEmpty) 'username': username,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
    await authService.authWithPassword(email, password);
  }
}
