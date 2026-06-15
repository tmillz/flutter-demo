import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/presentation/screens/home_screen.dart';
import 'package:flutter_application_1/presentation/screens/signin_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'firebase_options.dart';
import 'data/services/theme_service.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(title: 'Terrys World'),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SigninPage(title: 'Sign in'),
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Connect to local Firebase emulators when running in debug.
  if (kDebugMode) {
    try {
      // Add a small delay to ensure Firebase is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Connect to Auth emulator (only works if emulator is running)
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      // ignore: avoid_print
      print('✓ Connected Firebase Auth to emulator at 127.0.0.1:9099');
      
      // Connect to Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      // ignore: avoid_print
      print('✓ Connected Firestore to emulator at 127.0.0.1:8080');
    } catch (e) {
      // If emulator is not running, the app will use production Firebase
      // ignore: avoid_print
      print('⚠ Firebase emulator not available: $e');
      // Continue with production Firebase instead of crashing
    }
  }
  
  await ThemeService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.notifier,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          title: 'Demo',
          routerConfig: _router,
          themeMode: themeMode,
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.cyan,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ).copyWith(scaffoldBackgroundColor: Colors.white),
          darkTheme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueGrey,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ).copyWith(scaffoldBackgroundColor: const Color(0xFF121212)),
        );
      },
    );
  }
}
