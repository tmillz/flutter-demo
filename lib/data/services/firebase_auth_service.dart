import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Signs in the user with Google and returns the [UserCredential].
  /// Returns null if the user cancels the sign-in flow.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web use FirebaseAuth popup sign-in which handles the OAuth flow.
        final provider = GoogleAuthProvider();
        return await FirebaseAuth.instance.signInWithPopup(provider);
      }

      // Mobile/native flow using google_sign_in package
      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: ['email'],
      );

      final GoogleSignInAuthentication auth = account.authentication;

      final googleSignInClientAuth = await account.authorizationClient
          .authorizationForScopes(['email']);

      final String? accessToken = googleSignInClientAuth?.accessToken;

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: accessToken,
      );

      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      // If the user cancelled or UI was unavailable, return null to indicate
      // a non-error cancellation. Otherwise rethrow so callers see the error.
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          return null;
        default:
          rethrow;
      }
    } catch (e) {
      // Propagate unexpected errors to the caller so UI can show details.
      rethrow;
    }
  }

  /// Signs out the current user from both Firebase Auth and Google Sign-In.
  /// Handles errors gracefully and doesn't crash even if sign-out encounters issues.
  static Future<void> signOut() async {
    debugPrint('Signing out user...');

    try {
      if (kDebugMode) {
        debugPrint('Current user before sign-out: ${_auth.currentUser}');
      }
      // Attempt to sign out from Firebase Auth with timeout
      await _auth.signOut().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠ Firebase Auth sign-out timed out');
          throw TimeoutException('signOut timed out');
        },
      );
      debugPrint('✓ Firebase Auth signed out');
    } catch (e) {
      // Log but don't crash - Firebase Auth sign-out may fail in certain conditions
      debugPrint('⚠ Firebase Auth sign-out error: $e');
    }

    // Only attempt Google Sign-In sign-out on mobile (not web)
    // Web uses the popup flow which doesn't require GoogleSignIn package
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
        debugPrint('✓ Google Sign-In signed out');
      } catch (e) {
        // Log but don't crash - Google Sign-In sign-out is secondary
        debugPrint('⚠ Google Sign-In sign-out error: $e');
      }
    }

    debugPrint('Sign-out complete');
  }
}
