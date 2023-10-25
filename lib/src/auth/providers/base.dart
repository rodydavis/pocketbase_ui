import 'package:pocketbase/pocketbase.dart';

/// Base auth provider for auth clients in PocketBase console
abstract class AuthProvider {
  late PocketBase client;

  late RecordService authService;

  String get name;

  bool isSupported(AuthMethodsList value);

  String? get userId {
    final model = client.authStore.model;
    if (model is RecordModel) {
      return model.id;
    } else if (model is AdminModel) {
      return model.id;
    }
    return null;
  }

  bool get isAdmin {
    final model = client.authStore.model;
    if (model is AdminModel) {
      return true;
    }
    return false;
  }

  bool get isLoggedIn => userId != null;
}
