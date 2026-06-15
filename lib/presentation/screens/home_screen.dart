import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/theme_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/post.dart';
import '../widgets/post_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
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
        const Text(
          'You have pushed the button this many times:',
          textAlign: TextAlign.center,
        ),
        Text(
          '$_counter',
          style: Theme.of(context).textTheme.headlineMedium,
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
          children: posts.map((post) {
            return PostCard(
              post: post,
              isAdmin: isAdmin,
            );
          }).toList(),
        );
      },
    );
  }
}

class _HomePageState extends State<HomePage> {
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
      // ignore: avoid_print
      print('Failed to fetch dad joke: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Text(widget.title),
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
                  final messenger = ScaffoldMessenger.of(c);
                  final router = GoRouter.of(c);
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  _CounterSection(key: _counterKey),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Posts Feed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _PostsFeed(isAdmin: _isAdmin),
                  const SizedBox(height: 24),
                  if (_dadJoke != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      _dadJoke!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _counterKey.currentState?._incrementCounter(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
