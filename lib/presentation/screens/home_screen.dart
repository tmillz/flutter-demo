import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_typography.dart';
import '../../data/services/admin_auth_service.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/post.dart';
import '../widgets/post_card.dart';
import '../widgets/footer_widget.dart';
import '../widgets/app_brand_title.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _PostsFeed extends StatefulWidget {
  final bool isAdmin;
  final double cardHorizontalInset;
  final double pageHorizontalPadding;

  const _PostsFeed({
    required this.isAdmin,
    required this.cardHorizontalInset,
    required this.pageHorizontalPadding,
  });

  @override
  State<_PostsFeed> createState() => _PostsFeedState();
}

class _PostsFeedState extends State<_PostsFeed> {
  late final Stream<List<Post>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = FirestoreService.getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <Post>[];

        Widget wrapContent(Widget child) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.pageHorizontalPadding,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: child,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: wrapContent(
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: wrapContent(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: AppTypography.statusText(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: wrapContent(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No posts yet',
                  style: AppTypography.statusText(size: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        const preItems = 0;
        return SliverList.builder(
          itemCount: posts.length + preItems,
          itemBuilder: (context, index) {
            final postIndex = index - preItems;
            return wrapContent(
              PostCard(post: posts[postIndex], isAdmin: widget.isAdmin),
            );
          },
        );
      },
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  User? _firebaseUser;
  StreamSubscription<User?>? _authSubscription;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _postsAnchorKey = GlobalKey();
  bool get _isAdmin => AdminAuthService.isAdmin;

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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToPosts() async {
    final targetContext = _postsAnchorKey.currentContext;
    if (targetContext == null || !_scrollController.hasClients) return;

    final targetRender = targetContext.findRenderObject();
    if (targetRender is! RenderBox) return;

    final globalY = targetRender.localToGlobal(Offset.zero).dy;
    final targetOffset = _scrollController.offset + globalY - 90;
    final clampedOffset = targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrowScreen = MediaQuery.sizeOf(context).width < 600;
    final pageHorizontalPadding = isNarrowScreen ? 6.0 : 12.0;
    final cardHorizontalInset = isNarrowScreen ? 8.0 : 16.0;

    return Scaffold(
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 80,
        title: const AppBrandTitle(),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          const ThemeToggleButton(),
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
                    context.go('/signin');
                    return;
                  }
                  try {
                    await FirebaseAuthService.signOut();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Signed out')),
                    );
                    router.go('/');
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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _HeroSection(onScrollDown: _scrollToPosts)),
          SliverToBoxAdapter(child: SizedBox(key: _postsAnchorKey)),
          _PostsFeed(
            isAdmin: _isAdmin,
            cardHorizontalInset: cardHorizontalInset,
            pageHorizontalPadding: pageHorizontalPadding,
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: pageHorizontalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [SizedBox(height: 80), FooterWidget()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onPressed: () => context.push('/new-post'),
              tooltip: 'New post',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onScrollDown;

  const _HeroSection({required this.onScrollDown});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.sizeOf(context);
    final isNarrow = screenSize.width < 600;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final heroImage = isNarrow
        ? 'assets/images/hero-strong-mobile.jpg'
        : 'assets/images/hero-strong.jpg';
    final heroHeight = (screenSize.height - safeBottom).clamp(620.0, 980.0);
    final imageHeight = isNarrow
        ? (heroHeight * 0.34).clamp(180.0, 250.0)
        : (heroHeight * 0.5).clamp(280.0, 430.0);

    const services = [
      'Software & Platform Engineering',
      'Drone Photography & Videography',
      'Electronics Repair',
    ];

    final heroContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            isNarrow ? 10 : 24,
            16,
            isNarrow ? 14 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: isNarrow ? 1 : 2),
              Column(
                children: [
                  Text(
                    'Turning Complex Technical Problems into Practical Solutions',
                    textAlign: TextAlign.center,
                    style: AppTypography.heroHeadline(isNarrow: isNarrow),
                  ),
                  SizedBox(height: isNarrow ? 12 : 18),
                  Text(
                    'Software engineering, platform infrastructure, aerial imaging, and electronics repair backed by hands-on operational experience.',
                    textAlign: TextAlign.center,
                    style: AppTypography.heroBody(
                      isNarrow: isNarrow,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
              Spacer(flex: isNarrow ? 1 : 2),
              Column(
                children: [
                  Text(
                    'FEATURED SERVICES',
                    textAlign: TextAlign.center,
                    style: AppTypography.sectionLabel(scheme.primary),
                  ),
                  SizedBox(height: isNarrow ? 10 : 14),
                  ...services.map(
                    (s) => Padding(
                      padding: EdgeInsets.only(bottom: isNarrow ? 8 : 10),
                      child: Text(
                        s,
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionItem(),
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(flex: isNarrow ? 2 : 3),
              Column(
                children: [
                  Text(
                    'Projects',
                    style: AppTypography.helperLabel(
                      scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ScrollDownButton(onTap: onScrollDown),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      height: heroHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: imageHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  heroImage,
                  fit: BoxFit.cover,
                  cacheWidth: isNarrow ? 960 : 1920,
                  filterQuality: FilterQuality.low,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: heroContent),
        ],
      ),
    );
  }
}

class _ScrollDownButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScrollDownButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surface,
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: scheme.primary,
            size: 26,
          ),
        ),
      ),
    );
  }
}
