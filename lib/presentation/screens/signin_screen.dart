import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/theme_service.dart';
import '../widgets/google_signin_button.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key, required this.title});

  final String title;

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Builder(
              builder: (c) {
                final mode = ThemeService.notifier.value;
                if (mode == ThemeMode.system) {
                  return const Icon(Icons.brightness_auto);
                }
                if (mode == ThemeMode.light) {
                  return const Icon(Icons.light_mode);
                }
                return const Icon(Icons.dark_mode);
              },
            ),
            onPressed: () => ThemeService.cycleMode(),
          ),
        ],
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

                // const SizedBox(height: 12),
                // TextField(
                //   decoration: const InputDecoration(labelText: 'Username'),
                // ),
                // const SizedBox(height: 12),
                // const PasswordTextField(),

                const SizedBox(height: 16),

                // Simple cross-platform Google sign-in button.
                GoogleSignInButton(
                  webClientId:
                      '48988735153-jtqjqe6ra09s4adkq3cusob9m3htvuv3.apps.googleusercontent.com',
                  onSignedIn: () {
                    if (!mounted) return;
                    GoRouter.of(context).go('/');
                  },
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () {
                    if (mounted) context.pop();
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordTextField extends StatefulWidget {
  const PasswordTextField({super.key});

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }
}
