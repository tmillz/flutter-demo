import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_demo/presentation/screens/home_screen.dart';
import 'package:flutter_demo/presentation/screens/signin_screen.dart';
import 'package:flutter_demo/presentation/screens/new_post_screen.dart';
import 'package:flutter_demo/presentation/screens/ping_game_screen.dart';
import 'package:flutter_demo/presentation/screens/trex_game_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'firebase_options.dart';
import 'data/services/theme_service.dart';
import 'package:flame/game.dart';
import 'games/background_game.dart';
import 'src/register_web_plugins_stub.dart'
    if (dart.library.html) 'src/register_web_plugins_web.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(title: 'tmillz'),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SigninScreen(title: 'Sign in'),
    ),
    GoRoute(
      path: '/new-post',
      builder: (context, state) => const NewPostScreen(),
    ),
    GoRoute(path: '/ping', builder: (context, state) => const PingGameScreen()),
    GoRoute(path: '/trex', builder: (context, state) => const TrexGameScreen()),
  ],
  redirect: (context, state) {
    final adminEmail = 'terrymil1981@gmail.com';
    final user = FirebaseAuth.instance.currentUser;

    // Protect /new-post route - only admin can access
    if (state.matchedLocation == '/new-post') {
      if (user == null || user.email != adminEmail) {
        return '/';
      }
    }

    return null;
  },
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Register the iframe WebView platform on Flutter web before any
  // YoutubePlayerController is created (fixes WebViewPlatform.instance assertion).
  registerWebPlugins();
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
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BackgroundGame? _backgroundGame;
  late final Widget _backgroundWidget;

  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    ThemeService.notifier.addListener(_onThemeChanged);
    _backgroundGame = BackgroundGame();
    _backgroundWidget = GameWidget(game: _backgroundGame!);
  }

  @override
  void dispose() {
    ThemeService.notifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  // No longer needs MediaQuery — we only use light/dark, never system.
  bool _isDarkMode(ThemeMode themeMode) => themeMode == ThemeMode.dark;

  void _onThemeChanged() {
    _backgroundGame?.updateTheme(_isDarkMode(ThemeService.notifier.value));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backgroundGame?.updateTheme(_isDarkMode(ThemeService.notifier.value));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.notifier,
      builder: (context, themeMode, child) {
        // MaterialApp must be the root — never nest it inside a Stack.
        // Inject the background via builder so it gets proper MediaQuery/Theme
        // context and never causes RenderBox layout errors.
        return MaterialApp.router(
          title: 'tmillz',
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
          builder: (context, child) {
            return Stack(
              textDirection: TextDirection.ltr,
              children: [
                // Flame background — excluded from focus and hit-testing so it
                // never steals browser focus or swallows button taps.
                Positioned.fill(
                  child: ExcludeFocus(
                    child: IgnorePointer(child: _backgroundWidget),
                  ),
                ),
                ?child,
              ],
            );
          },
        );
      },
    );
  }
}
