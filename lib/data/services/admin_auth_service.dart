import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminAuthService {
  static const _adminClaimKey = 'admin';

  static final ValueNotifier<bool> notifier = ValueNotifier<bool>(false);

  static bool _initialized = false;

  static bool get isAdmin => notifier.value;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    notifier.value = await _readAdminClaim(
      FirebaseAuth.instance.currentUser,
      forceRefresh: true,
    );

    FirebaseAuth.instance.idTokenChanges().listen((user) async {
      notifier.value = await _readAdminClaim(user);
    });
  }

  static Future<bool> refresh() async {
    final nextValue = await _readAdminClaim(
      FirebaseAuth.instance.currentUser,
      forceRefresh: true,
    );
    notifier.value = nextValue;
    return nextValue;
  }

  static Future<bool> _readAdminClaim(
    User? user, {
    bool forceRefresh = false,
  }) async {
    if (user == null) return false;

    try {
      final token = await user.getIdTokenResult(forceRefresh);
      return token.claims?[_adminClaimKey] == true;
    } catch (_) {
      return false;
    }
  }
}
