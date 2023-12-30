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
class AuthController extends ValueNotifier<User?> {
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
    _authEventStream = client.authStore.onChange.listen((event) {
      debugPrint('Auth event: $event');
      setAuth(event.token, event.model);
    });
    checkHealth();
    healthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkHealth();
    });
  }

  void setAuth(String token, dynamic model) {
    if (model is RecordModel) {
      value = (model.id, model);
    } else if (model is AdminModel) {
      value = (model.id, model);
    } else {
      value = null;
    }
    notifyListeners();
  }

  void setHealthy(bool value) async {
    final wasHealthy = healthy.previousValue;
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

  Future<void> execute(final Future<void> Function() callback) async {
    try {
      await callback();
    } catch (e) {
      await errorCallback(e);
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!isSignedIn) return;
    return execute(() => authService.authRefresh());
  }

  Future<void> logout() => execute(() async => client.authStore.clear());

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
