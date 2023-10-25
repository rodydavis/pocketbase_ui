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
}
