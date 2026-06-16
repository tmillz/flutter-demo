

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/particle_component.dart';
import 'components/sparkle_component.dart';

class BackgroundGame extends FlameGame {
  bool isDark = false;
  final List<ParticleComponent> _particles = [];
  final List<SparkleComponent> _sparkles = [];

  static const int particleCount = 30;
  static const int sparkleCount = 20;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeBackground();
  }

  @override
  void render(Canvas canvas) {
    // Draw gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)]
          : [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    super.render(canvas);
  }

  void _initializeBackground() {
    // Add particles
    for (int i = 0; i < particleCount; i++) {
      final particle = ParticleComponent(isDark: isDark);
      add(particle);
      _particles.add(particle);
    }

    // Add sparkles
    for (int i = 0; i < sparkleCount; i++) {
      final sparkle = SparkleComponent(isDark: isDark);
      add(sparkle);
      _sparkles.add(sparkle);
    }
  }

  void updateTheme(bool dark) {
    if (isDark != dark) {
      isDark = dark;
      // Update existing components' isDark property
      for (final particle in _particles) {
        particle.isDark = dark;
      }
      for (final sparkle in _sparkles) {
        sparkle.isDark = dark;
      }
    }
  }
}