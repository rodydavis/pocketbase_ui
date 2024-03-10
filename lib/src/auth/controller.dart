import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sqlite_storage_pocketbase/sqlite_storage_pocketbase.dart';
import 'package:signals/signals.dart';

import 'providers/base.dart';
import 'providers/email.dart';
import 'providers/oauth2.dart';

/// Auth error event callback
typedef AuthErrorCallback = FutureOr<void> Function(Object);

// typedef User = (String, dynamic);

/// Auth controller to manage auth lifecycle
class AuthController {
  static List<AuthProvider> providers = [
    EmailAuthProvider(),
    AppleAuthProvider(),
    GoogleAuthProvider(),
  ];

  final OfflinePocketBase client;
  final AuthErrorCallback errorCallback;
  final String authCollectionIrOrName;
  late final authService = client.collection(authCollectionIrOrName);
  final Signal<String?> auth$ = signal(null);
  final String Function(String)? emailCheckUrl;

  late final ReadonlySignal<RecordModel?> user$ = computed(() {
    auth$.value;
    final model = client.offlineAuthStore.model;
    if (model is RecordModel) return model;
    return null;
  });

  late final ReadonlySignal<bool> isSignedIn$ = computed(() {
    auth$.value;
    final model = client.offlineAuthStore.model;
    return model != null && client.offlineAuthStore.isValid;
  });

  late final ReadonlySignal<String?> userId$ = computed(() {
    auth$.value;
    final model = client.offlineAuthStore.model;
    if (model is RecordModel) return model.id;
    return '';
  });

  final methods$ = signal<AuthMethodsList?>(null);

  final healthy = signal(false);
  Timer? healthTimer;
  final connects = <Connect>[];
  Duration healthCheckDelay = const Duration(seconds: 30);

  AuthController({
    required this.client,
    required this.errorCallback,
    this.authCollectionIrOrName = 'users',
    this.emailCheckUrl,
  }) {
    connects.add(connect(auth$, client.offlineAuthStore.authEvents));
    for (final provider in providers) {
      provider.client = client;
      provider.authService = authService;
    }
    checkHealth();
    healthTimer = Timer.periodic(healthCheckDelay, (_) {
      checkHealth();
    });
  }

  void setHealthy(bool value) async {
    final wasHealthy = healthy.value;
    healthy.value = value;
    if (!wasHealthy && value) {
      await loadProviders();
      if (isSignedIn$()) {
        try {
          await authService.authRefresh();
        } catch (e, t) {
          await logout();
          debugPrint('error refresh auth: $e, $t');
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

  void dispose() {
    healthTimer?.cancel();
    for (final item in connects) {
      item.dispose();
    }
  }

  Future<void> logout() async {
    client.authStore.clear();
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
      methods$.value = methods;
    } catch (e) {
      debugPrint('Error loading auth providers: $e');
      await errorCallback(e);
    }
  }

  bool get emailCheck => emailCheckUrl != null;

  Future<RecordModel?> checkIfUserExistsForEmail(String email) async {
    final target = emailCheckUrl?.call(email);
    if (target == null) return null;
    final url = client.buildUrl(target);
    final res = await client.httpClientFactory().get(url);
    if (res.statusCode == 200) {
      return RecordModel.fromJson(jsonDecode(res.body));
    }
    return null;
  }
}
