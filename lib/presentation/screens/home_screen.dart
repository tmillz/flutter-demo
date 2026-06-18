import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/theme_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/post.dart';
import '../widgets/post_card.dart';
import '../widgets/footer_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _CounterSection extends StatefulWidget {
  const _CounterSection({super.key});

  @override
  State<_CounterSection> createState() => _CounterSectionState();
}

class _CounterSectionState extends State<_CounterSection> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'You have pushed the button $_counter times!',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PostsFeed extends StatelessWidget {
  final bool isAdmin;

  const _PostsFeed({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: FirestoreService.getPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const Center(
            child: Text('No posts yet'),
          );
        }

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Posts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            ...posts.map((post) {
              return PostCard(
                post: post,
                isAdmin: isAdmin,
              );
            }),
          ],
        );
      },
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  User? _firebaseUser;
  StreamSubscription<User?>? _authSubscription;
  String? _dadJoke;
  final String _adminEmail = 'terrymil1981@gmail.com';
  final GlobalKey<_CounterSectionState> _counterKey = GlobalKey<_CounterSectionState>();

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == _adminEmail;
  }

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
    _fetchDadJoke();
  }

  Future<void> _fetchDadJoke() async {
    try {
      final response = await http.get(
        Uri.parse('https://icanhazdadjoke.com/'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _dadJoke = data['joke'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch dad joke: $e');
    }
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tmillz',
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                //fontStyle: FontStyle.italic,
                fontSize: 36,
              ),
            ),
            Text(
              'ideas in motion',
              style: GoogleFonts.inter(
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Builder(
              builder: (context) {
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
          Builder(
            builder: (context) {
              final signedIn = _firebaseUser != null;
              return IconButton(
                tooltip: signedIn ? 'Sign out' : 'Sign in with Google',
                icon: signedIn
                    ? const Icon(Icons.logout)
                    : const Icon(Icons.account_circle),
                onPressed: () async {
                  // Capture context-dependent objects before any async gap so
                  // we never touch a BuildContext after awaiting.
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  if (!signedIn) {
                    router.push('/signin');
                    return;
                  }
                  try {
                    await FirebaseAuthService.signOut();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Signed out')),
                    );
                    router.push('/signin');
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Sign-in failed: $e')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  _CounterSection(key: _counterKey),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          Text(
                            'About:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This website is for sharing ideas and design with Flutter',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                  if (_dadJoke != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dad joke of the day:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  '😂',
                                  style: TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _dadJoke!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Powered by icanhazdadjokes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _PostsFeed(isAdmin: _isAdmin),
                  const SizedBox(height: 24),
                  const SizedBox(height: 80),
                  const FooterWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onPressed: () {
          if (_isAdmin) {
            context.push('/new-post');
          } else {
            _counterKey.currentState?._incrementCounter();
          }
        },
        tooltip: 'add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
