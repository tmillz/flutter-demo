import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../widgets/google_signin_button.dart';
import '../widgets/footer_widget.dart';
import '../widgets/app_brand_title.dart';
import '../widgets/theme_toggle_button.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key, required this.title});

  final String title;

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  User? _firebaseUser;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _firebaseUser = FirebaseAuth.instance.currentUser;
    _authSubscription = FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {
          _firebaseUser = user;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80,
        title: const AppBrandTitle(
          title: 'Sign In',
          subtitle: 'create or continue',
        ),
        actions: [const ThemeToggleButton()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Sign in or create an account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_firebaseUser != null) ...[
                  const SizedBox(height: 12),
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: _firebaseUser!.photoURL != null
                        ? NetworkImage(_firebaseUser!.photoURL!)
                        : null,
                    child: _firebaseUser!.photoURL == null
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _firebaseUser!.displayName ??
                        _firebaseUser!.email ??
                        'Signed in',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 16),

                // Simple cross-platform Google sign-in button.
                GoogleSignInButton(
                  onSignedIn: () {
                    if (!mounted) return;
                    GoRouter.of(context).go('/');
                  },
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (mounted) context.pop();
                  },
                  child: const Text('Back'),
                ),
                const SizedBox(height: 80),
                const FooterWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
