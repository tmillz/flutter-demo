import 'package:flutter/material.dart';

import '../../data/services/firebase_auth_service.dart';

class GoogleSignInButton extends StatelessWidget {
    final String? webClientId;
    final VoidCallback? onSignedIn;

    const GoogleSignInButton({super.key, this.webClientId, this.onSignedIn});

    @override
    Widget build(BuildContext context) {
        return ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
            onPressed: () async {
                final cred = await FirebaseAuthService.signInWithGoogle();
                if (cred != null) onSignedIn?.call();
            },
        );
    }
}
