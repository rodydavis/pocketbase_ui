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
  final String Function(String) emailCheckUrl;
  final String Function(String) externalAuthMethodsUrl;
  final Signal<RecordModel?> user$ = signal(null);

  late final ReadonlySignal<bool> isSignedIn$ = computed(() {
    if (!client.offlineAuthStore.isValid) return false;
    return user$() != null && user$()!.id.isNotEmpty;
  });

  late final ReadonlySignal<String?> userId$ = computed(() {
    if (!client.offlineAuthStore.isValid) return null;
    return user$()?.id;
  });

  final methods$ = signal<AuthMethodsList?>(null);

  final healthy = signal(false);
  Timer? healthTimer;
  final connects = <Connect>[];
  Duration healthCheckDelay = const Duration(seconds: 30);
  EffectCleanup? _cleanup;

  AuthController({
    required this.client,
    required this.errorCallback,
    this.authCollectionIrOrName = 'users',
    required this.emailCheckUrl,
    required this.externalAuthMethodsUrl,
  }) {
    connects.add(connect(user$, client.offlineAuthStore.modelEvents));
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
    _cleanup?.call();
    healthTimer?.cancel();
    for (final item in connects) {
      item.dispose();
    }
    connects.clear();
  }

  Future<void> logout() async {
    client.authStore.clear();
    user$.value = null;
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

  Future<RecordModel?> checkIfUserExistsForEmail(String email) async {
    final target = emailCheckUrl(email);
    final url = client.buildUrl(target);
    final res = await client.httpClientFactory().get(url);
    if (res.statusCode == 200) {
      return RecordModel.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<List<String>> getExternalAuthMethodsForEmail(String email) async {
    final target = externalAuthMethodsUrl(email);
    final url = client.buildUrl(target);
    final res = await client.httpClientFactory().get(url);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<String>();
    }
    return [];
  }
}
