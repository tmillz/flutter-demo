import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/services/theme_service.dart';
import '../../games/ping_game.dart';

class PingGameScreen extends StatefulWidget {
  const PingGameScreen({super.key});

  @override
  State<PingGameScreen> createState() => _PingGameScreenState();
}

class _PingGameScreenState extends State<PingGameScreen> {
  late final PingGame _game;

  bool get _isDark => ThemeService.notifier.value == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _game = PingGame(isDark: _isDark);
    ThemeService.notifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() => _game.updateTheme(_isDark);

  @override
  void dispose() {
    ThemeService.notifier.removeListener(_onThemeChanged);
    _game.score.dispose();
    _game.isGameOver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Game canvas — GestureDetector drives paddle movement via touch
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) =>
                _game.movePaddleTo(details.localPosition.dx),
            child: GameWidget(game: _game),
          ),

          // Back button — SafeArea + 80 px height mirrors the home AppBar leading position
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: SizedBox(
                height: 80,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            ),
          ),

          // Live score (top-center)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ValueListenableBuilder<int>(
                  valueListenable: _game.score,
                  builder: (context, score, _) {
                    return Text(
                      '$score',
                      style: GoogleFonts.orbitron(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.9),
                        shadows: [
                          Shadow(
                            color: isDark
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.7)
                                : const Color(
                                    0xFFFF6D00,
                                  ).withValues(alpha: 0.65),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Game-over overlay
          ValueListenableBuilder<bool>(
            valueListenable: _game.isGameOver,
            builder: (context, gameOver, _) {
              if (!gameOver) return const SizedBox.shrink();
              return _GameOverOverlay(
                score: _game.score,
                onRestart: _game.restart,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.score, required this.onRestart});

  final ValueNotifier<int> score;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Colors.black.withValues(alpha: 0.65)
          : Colors.white.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GAME OVER',
              style: GoogleFonts.orbitron(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<int>(
              valueListenable: score,
              builder: (context, s, _) => Text(
                'Score: $s',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  color: isDark ? scheme.primary : const Color(0xFFE65100),
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? scheme.primary
                    : const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onRestart,
              child: Text(
                'PLAY AGAIN',
                style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(
                'QUIT',
                style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
