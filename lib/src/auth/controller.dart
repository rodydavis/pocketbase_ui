import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:signals/signals.dart';

import 'providers/base.dart';
import 'providers/email.dart';
import 'providers/oauth2.dart';

/// Auth error event callback
typedef AuthErrorCallback = FutureOr<void> Function(Object);

typedef User = (String, dynamic);

/// Auth controller to manage auth lifecycle
class AuthController extends ValueSignal<User?> {
  static List<AuthProvider> providers = [
    EmailAuthProvider(),
    AppleAuthProvider(),
    GoogleAuthProvider(),
  ];

  final PocketBase client;

  final AuthErrorCallback errorCallback;

  final String authCollectionIrOrName;

  StreamSubscription<AuthStoreEvent>? _authEventStream;

  final methods = ValueNotifier<AuthMethodsList?>(null);

  final healthy = signal(false);
  Timer? healthTimer;

  AuthController({
    required this.client,
    required this.errorCallback,
    this.authCollectionIrOrName = 'users',
    User? initialUser,
  }) : super(initialUser) {
    for (final provider in providers) {
      provider.client = client;
      provider.authService = authService;
    }
    _authEventStream = client.authStore.onChange.distinct().listen((event) {
      debugPrint('Auth event: $event');
      setAuth(event.token, event.model);
    });
    setAuth(client.authStore.token, client.authStore.model);
    checkHealth();
    healthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkHealth();
    });
  }

  void setAuth(String token, dynamic model) {
    debugPrint('set auth: $token $model');
    if (model is RecordModel) {
      value = (model.id, model);
    } else if (model is AdminModel) {
      value = (model.id, model);
    } else {
      value = null;
    }
  }

  void setHealthy(bool value) async {
    final wasHealthy = healthy.value;
    healthy.value = value;
    if (!wasHealthy && value) {
      await loadProviders();
      if (isSignedIn) {
        try {
          await authService.authRefresh();
        } catch (e) {
          this.value = null;
          debugPrint('error refresh auth: $e');
        }
      }
    }
  }

  Future<void> checkHealth() async {
    try {
      final result = await client.health.check();
      setHealthy(result.code == 200);
    } catch (e) {
      debugPrint('Error checking health: $e');
      setHealthy(false);
    }
  }

  @override
  void dispose() {
    healthTimer?.cancel();
    _authEventStream?.cancel();
    super.dispose();
  }

  late final authService = client.collection(authCollectionIrOrName);

  bool get isSignedIn =>
      client.authStore.isValid &&
      client.authStore.token.trim().isNotEmpty &&
      value != null;

  String get userId {
    if (value == null) return '';
    final (_, model) = value!;
    if (model is RecordModel) {
      return model.id;
    } else if (model is AdminModel) {
      return model.id;
    }
    return '';
  }

  Future<void> logout() async {
    client.authStore.clear();
    value = null;
  }

  Future<void> delete() async {
    final model = client.authStore.model;
    if (model is AdminModel) {
      // Cannot delete admin model
    } else if (model is RecordModel) {
      await authService.delete(model.id);
      await logout();
    }
  }

  Future<void> loadProviders() async {
    try {
      final methods = await authService.listAuthMethods();
      this.methods.value = methods;
    } catch (e) {
      debugPrint('Error loading auth providers: $e');
      await errorCallback(e);
    }
  }
}
