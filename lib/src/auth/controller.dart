import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

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
      final m = event.model;
      if (m is RecordModel) {
        value = (m.id, m);
      } else if (m is AdminModel) {
        value = (m.id, m);
      } else {
        value = null;
      }
      notifyListeners();
    });
    refresh(); // Maybe call this on first event fired
  }

  @override
  void dispose() {
    _authEventStream?.cancel();
    super.dispose();
  }

  late final authService = client.collection(authCollectionIrOrName);

  bool get isSignedIn => client.authStore.isValid;

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
    // TODO
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
