import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class BackgroundGame extends FlameGame {
  bool isDark = false;
  final Random _random = Random();
  final List<_AmbientEmitter> _emitters = [];

  bool _initialized = false;

  static const int particleEmitterCount = 10;
  static const int sparkleEmitterCount = 6;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _ensureEmitters();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    if (!_initialized) {
      _ensureEmitters();
    } else {
      _scatterEmitters();
    }
  }

  @override
  void render(Canvas canvas) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
            ]
          : [
              const Color(0xFFffffff),
              const Color(0xFFe8e8e8),
              const Color(0xFFffcc80),
            ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    super.render(canvas);
  }

  void _ensureEmitters() {
    if (_initialized || size.x <= 0 || size.y <= 0) {
      return;
    }

    _initialized = true;
    _emitters.addAll(
      List.generate(
        particleEmitterCount,
        (_) => _createEmitter(_AmbientEmitterKind.particle),
      ),
    );
    _emitters.addAll(
      List.generate(
        sparkleEmitterCount,
        (_) => _createEmitter(_AmbientEmitterKind.sparkle),
      ),
    );
  }

  _AmbientEmitter _createEmitter(_AmbientEmitterKind kind) {
    final emitter = _AmbientEmitter(
      kind: kind,
      isDark: isDark,
      position: _randomTopBandPosition(),
      seed: _random.nextInt(1 << 31),
    );
    add(emitter);
    return emitter;
  }

  Vector2 _randomTopBandPosition() {
    return Vector2(
      _random.nextDouble() * size.x,
      -350.0 - _random.nextDouble() * 250.0, // 350–600px above screen top
    );
  }

  void _scatterEmitters() {
    for (final emitter in _emitters) {
      emitter.position = _randomTopBandPosition();
    }
  }

  void updateTheme(bool dark) {
    if (isDark == dark) {
      return;
    }

    isDark = dark;
    for (final emitter in _emitters) {
      emitter.updateTheme(dark);
    }
  }
}

enum _AmbientEmitterKind { particle, sparkle }

class _AmbientEmitter extends ParticleSystemComponent {
  _AmbientEmitter({
    required this.kind,
    required this.isDark,
    required int seed,
    required super.position,
  }) : _random = Random(seed),
       super(
         particle: _buildParticle(
           kind: kind,
           isDark: isDark,
           random: Random(seed),
         ),
       );

  final _AmbientEmitterKind kind;
  final Random _random;
  bool isDark;

  @override
  void update(double dt) {
    particle?.update(dt);
    if (particle?.shouldRemove ?? false) {
      particle = _buildParticle(kind: kind, isDark: isDark, random: _random);
    }
  }

  void updateTheme(bool dark) {
    if (isDark == dark) {
      return;
    }

    isDark = dark;
    particle = _buildParticle(kind: kind, isDark: isDark, random: _random);
  }

  static Particle _buildParticle({
    required _AmbientEmitterKind kind,
    required bool isDark,
    required Random random,
  }) {
    final lifespan = kind == _AmbientEmitterKind.particle
        ? 10.0 + random.nextDouble() * 4.0
        : 7.0 + random.nextDouble() * 3.0;
    final particleCount = kind == _AmbientEmitterKind.particle ? 4 : 3;
    final baseColor = kind == _AmbientEmitterKind.particle
        ? (isDark ? Colors.purple : Colors.orange)
        : (isDark ? const Color.fromARGB(200, 255, 160, 59) : Colors.green);

    return Particle.generate(
      count: particleCount,
      lifespan: lifespan,
      generator: (index) {
        final radius = kind == _AmbientEmitterKind.particle
            ? 3.5 + random.nextDouble() * 3.5
            : 2.0 + random.nextDouble() * 2.5;
        final alpha = kind == _AmbientEmitterKind.particle
            ? 0.35 + random.nextDouble() * 0.25
            : 0.25 + random.nextDouble() * 0.3;
        final travel = kind == _AmbientEmitterKind.particle
            ? Vector2(
                (random.nextDouble() - 0.5) * 120,
                1100 + random.nextDouble() * 400, // 1100–1500px down
              )
            : Vector2(
                (random.nextDouble() - 0.5) * 60,
                900 + random.nextDouble() * 300, // 900–1200px down
              );

        return CircleParticle(
          paint: Paint()..color = baseColor.withValues(alpha: alpha),
          radius: radius,
          lifespan: lifespan,
        ).moving(from: Vector2.zero(), to: travel);
      },
    );
  }
}
