import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/home_screen.dart';
import 'presentation/screens/signin_screen.dart';
import 'presentation/screens/new_post_screen.dart';
import 'presentation/screens/ping_game_screen.dart';
import 'presentation/screens/trex_game_screen.dart';

const _adminEmail = 'YOUR_EMAIL';

final appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: Center(child: Text('No route for ${state.uri.path}')),
  ),
  redirect: (context, state) {
    if (state.uri.path == '/new-post') {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email != _adminEmail) return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(title: 'tmillz'),
    ),
    GoRoute(
      path: '/signin',
      name: 'signin',
      builder: (context, state) => const SigninScreen(title: 'Sign in'),
    ),
    GoRoute(
      path: '/new-post',
      name: 'new-post',
      builder: (context, state) => const NewPostScreen(),
    ),
    GoRoute(
      path: '/ping',
      name: 'ping',
      builder: (context, state) => const PingGameScreen(),
    ),
    GoRoute(
      path: '/trex',
      name: 'trex',
      builder: (context, state) => const TrexGameScreen(),
    ),
  ],
);
