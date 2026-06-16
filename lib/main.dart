import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_demo/presentation/screens/home_screen.dart';
import 'package:flutter_demo/presentation/screens/signin_screen.dart';
import 'package:flutter_demo/presentation/screens/new_post_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'firebase_options.dart';
import 'data/services/theme_service.dart';
import 'package:flame/game.dart';
import 'games/background_game.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(title: 'tmillz Ideas in motion'),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SigninScreen(title: 'Sign in'),
    ),
    GoRoute(
      path: '/new-post',
      builder: (context, state) => const NewPostScreen(),
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
      debugPrint('✓ Connected Firebase Auth to emulator at 127.0.0.1:9099');
      
      // Connect to Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      debugPrint('✓ Connected Firestore to emulator at 127.0.0.1:8080');
    } catch (e) {
      // If emulator is not running, the app will use production Firebase
      debugPrint('⚠ Firebase emulator not available: $e');
      // Continue with production Firebase instead of crashing
    }
  }
  
  await ThemeService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BackgroundGame? _backgroundGame;

  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    ThemeService.notifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.notifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  bool _isDarkMode(ThemeMode themeMode) {
    return themeMode == ThemeMode.dark ||
           (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
  }

  void _onThemeChanged() {
    final themeMode = ThemeService.notifier.value;
    _backgroundGame?.updateTheme(_isDarkMode(themeMode));
  }

  BackgroundGame _createBackgroundGame() {
    final game = BackgroundGame();
    _backgroundGame = game;
    // Set initial theme
    final themeMode = ThemeService.notifier.value;
    game.updateTheme(_isDarkMode(themeMode));
    return game;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update theme when dependencies change (more reliable than initState)
    final themeMode = ThemeService.notifier.value;
    _backgroundGame?.updateTheme(_isDarkMode(themeMode));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.notifier,
      builder: (context, themeMode, child) {
        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            // Flame game background
            Positioned.fill(
              child: GameWidget.controlled(
                gameFactory: _createBackgroundGame,
              ),
            ),
            // App content
            MaterialApp.router(
              title: 'Demo',
              routerConfig: _router,
              themeMode: themeMode,
              theme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.cyan,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              ).copyWith(scaffoldBackgroundColor: Colors.transparent),
              darkTheme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blueGrey,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ).copyWith(scaffoldBackgroundColor: Colors.transparent),
            ),
          ],
        );
      },
    );
  }
}
