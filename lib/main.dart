import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'firebase_options.dart';
import 'app_router.dart';
import 'data/services/admin_auth_service.dart';
import 'data/services/theme_service.dart';
import 'presentation/theme/app_typography.dart';
import 'src/register_web_plugins_stub.dart'
    if (dart.library.html) 'src/register_web_plugins_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Register the iframe WebView platform on Flutter web before any
  // YoutubePlayerController is created (fixes WebViewPlatform.instance assertion).
  registerWebPlugins();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Connect to local Firebase emulators when running in debug or CI screenshot mode.
  if (kDebugMode || const bool.fromEnvironment('USE_EMULATORS')) {
    try {
      // Add a small delay to ensure Firebase is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));

      // Connect to Auth emulator (only works if emulator is running)
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      debugPrint('✓ Connected Firebase Auth to emulator at 127.0.0.1:9099');

      // Connect to Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      debugPrint('✓ Connected Firestore to emulator at 127.0.0.1:8080');

      // Connect to Storage emulator
      FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);
      debugPrint('✓ Connected Firebase Storage to emulator at 127.0.0.1:9199');
    } catch (e) {
      // If emulator is not running, the app will use production Firebase
      debugPrint('⚠ Firebase emulator not available: $e');
      // Continue with production Firebase instead of crashing
    }
  }

  await ThemeService.initialize();
  await AdminAuthService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.notifier,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          title: 'tmillz',
          routerConfig: appRouter,
          themeMode: themeMode,
          theme:
              ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.cyan,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              ).copyWith(
                textTheme: AppTypography.textTheme(
                  ThemeData.from(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.cyan,
                      brightness: Brightness.light,
                    ),
                    useMaterial3: true,
                  ).textTheme,
                ),
              ),
          darkTheme:
              ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blueGrey,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ).copyWith(
                textTheme: AppTypography.textTheme(
                  ThemeData.from(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.blueGrey,
                      brightness: Brightness.dark,
                    ),
                    useMaterial3: true,
                  ).textTheme,
                ),
              ),
        );
      },
    );
  }
}
