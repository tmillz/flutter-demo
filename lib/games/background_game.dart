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

  static const int particleEmitterCount = 20;
  static const int sparkleEmitterCount = 22;

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
        (_) =>
            _createEmitter(_AmbientEmitterKind.particle, initialScatter: true),
      ),
    );
    _emitters.addAll(
      List.generate(
        sparkleEmitterCount,
        (_) =>
            _createEmitter(_AmbientEmitterKind.sparkle, initialScatter: true),
      ),
    );
  }

  _AmbientEmitter _createEmitter(
    _AmbientEmitterKind kind, {
    bool initialScatter = false,
  }) {
    final emitter = _AmbientEmitter(
      kind: kind,
      isDark: isDark,
      position: _randomTopBandPosition(),
      seed: _random.nextInt(1 << 31),
      respawnPosition: _randomTopBandPosition,
      // Random phase so initial particles are spread across their lifecycles.
      initialPhase: initialScatter ? _random.nextDouble() : 0.0,
    );
    add(emitter);
    return emitter;
  }

  Vector2 _randomTopBandPosition() {
    return Vector2(
      _random.nextDouble() * size.x,
      -5.0 - _random.nextDouble() * 60.0,
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
    required this._respawnPosition,
    this.initialPhase = 0.0,
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
  final Vector2 Function() _respawnPosition;
  final double initialPhase;
  bool isDark;
  double _respawnDelay = 0.0;

  @override
  void onMount() {
    super.onMount();
    // Pre-advance the particle into a random point of its lifecycle so
    // all initial emitters are out of phase with each other from frame one.
    if (initialPhase > 0 && particle != null) {
      final approxLifespan = kind == _AmbientEmitterKind.particle ? 19.0 : 14.0;
      particle!.update(initialPhase * approxLifespan);
    }
  }

  @override
  void update(double dt) {
    // During a respawn delay the emitter is dormant; once the delay expires
    // spawn a fresh particle so it enters from the top rather than popping
    // in mid-screen.
    if (_respawnDelay > 0) {
      _respawnDelay -= dt;
      if (_respawnDelay <= 0) {
        position = _respawnPosition();
        particle = _buildParticle(kind: kind, isDark: isDark, random: _random);
      }
      return;
    }

    particle?.update(dt);
    if (particle?.shouldRemove ?? false) {
      if (kind == _AmbientEmitterKind.sparkle) {
        // Hide and wait a random delay so respawns are staggered — prevents
        // wave clustering without causing mid-screen pop-in.
        particle = null;
        _respawnDelay = _random.nextDouble() * 4.0;
      } else {
        position = _respawnPosition();
        particle = _buildParticle(kind: kind, isDark: isDark, random: _random);
      }
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
    final isParticle = kind == _AmbientEmitterKind.particle;

    final lifespan = isParticle
        ? 16.0 + random.nextDouble() * 6.0
        : 12.0 + random.nextDouble() * 4.0;
    final particleCount = isParticle ? 2 : 1;

    // Curated colour palettes per theme
    final List<Color> particleColors = isDark
        ? [
            const Color(0xFF4FC3F7), // sky blue
            const Color(0xFF7C4DFF), // violet
            const Color(0xFF00E5FF), // cyan
            const Color(0xFF64B5F6), // soft blue
          ]
        : [
            const Color(0xFFFF7043), // deep orange
            const Color(0xFFFFB300), // amber
            const Color(0xFFFF8A65), // soft coral
            const Color(0xFFFFA726), // warm orange
          ];

    final List<Color> sparkleColors = isDark
        ? [
            const Color(0xFFFFD54F), // amber
            const Color(0xFFFFF9C4), // pale yellow
            const Color(0xFFFFFFFF), // white
          ]
        : [
            const Color(0xFFFF8F00), // amber
            const Color(0xFFFFCA28), // gold
            const Color(0xFFF57F17), // deep yellow
          ];

    final colors = isParticle ? particleColors : sparkleColors;

    return Particle.generate(
      count: particleCount,
      lifespan: lifespan,
      generator: (index) {
        final baseColor = colors[random.nextInt(colors.length)];
        final radius = isParticle
            ? 3.0 + random.nextDouble() * 4.0
            : 5.0 + random.nextDouble() * 5.0;
        final baseAlpha = isParticle
            ? 0.35 + random.nextDouble() * 0.21
            : 0.45 + random.nextDouble() * 0.25;
        final glowSigma = isParticle
            ? 6.0 + random.nextDouble() * 4.0
            : 10.0 + random.nextDouble() * 6.0;
        final travel = isParticle
            ? Vector2(
                (random.nextDouble() - 0.5) * 120,
                1100 + random.nextDouble() * 400,
              )
            : Vector2(
                (random.nextDouble() - 0.5) * 60,
                900 + random.nextDouble() * 300,
              );
        // ~50% of particles bloom; only ~30% of sparkles bloom.
        final bool grows = isParticle && random.nextBool();
        final bool blooms = !isParticle && random.nextDouble() < 0.30;
        // Non-blooming sparkles stay as small fixed-size glints.
        final double fixedScale = 0.3 + random.nextDouble() * 0.3;
        // Each sparkle gets a unique sway: amplitude 18–40 px, 1.5–3 cycles.
        final double swayAmplitude = isParticle
            ? 0.0
            : 18.0 + random.nextDouble() * 22.0;
        final double swayFrequency = isParticle
            ? 0.0
            : 1.5 + random.nextDouble() * 1.5;

        return ComputedParticle(
          lifespan: lifespan,
          renderer: (canvas, particle) {
            final p = particle.progress;
            // Particles: ease-in 15%, ease-out last 25%.
            // Sparkles: very short fades so they stay fully opaque during bloom.
            final opacity = isParticle
                ? (p < 0.15
                      ? p / 0.15
                      : p > 0.75
                      ? ((1.0 - p) / 0.25).clamp(0.0, 1.0)
                      : 1.0)
                : (p < 0.08
                      ? p / 0.08
                      : p > 0.92
                      ? ((1.0 - p) / 0.08).clamp(0.0, 1.0)
                      : 1.0);
            final alpha = (baseAlpha * opacity).clamp(0.0, 1.0);
            // Particles grow linearly; blooming sparkles pulse 3×; the
            // rest stay as small glints.
            final scale = isParticle
                ? (grows ? (0.5 + p).clamp(0.5, 1.5) : 1.0)
                : blooms
                ? (0.1 + 2.9 * sin(p * pi)).clamp(0.0, 3.0)
                : fixedScale;
            final r = radius * scale;

            // Sparkles sway left/right like fluttering as they drift down.
            if (!isParticle) {
              canvas.save();
              canvas.translate(
                swayAmplitude * sin(p * 2 * pi * swayFrequency),
                0,
              );
            }

            if (isParticle) {
              // Outer soft glow
              canvas.drawCircle(
                Offset.zero,
                r * 2.8,
                Paint()
                  ..color = baseColor.withValues(alpha: alpha * 0.25)
                  ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma),
              );
              // Mid glow ring
              canvas.drawCircle(
                Offset.zero,
                r * 1.6,
                Paint()
                  ..color = baseColor.withValues(alpha: alpha * 0.5)
                  ..maskFilter = MaskFilter.blur(
                    BlurStyle.normal,
                    glowSigma * 0.4,
                  ),
              );
              // Bright solid core
              canvas.drawCircle(
                Offset.zero,
                r,
                Paint()..color = baseColor.withValues(alpha: alpha * 0.9),
              );
            } else {
              // Sparkle: large diffuse halo
              canvas.drawCircle(
                Offset.zero,
                r * 4.5,
                Paint()
                  ..color = baseColor.withValues(alpha: alpha * 0.18)
                  ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma),
              );
              // Inner glow
              canvas.drawCircle(
                Offset.zero,
                r * 2.0,
                Paint()
                  ..color = baseColor.withValues(alpha: alpha * 0.5)
                  ..maskFilter = MaskFilter.blur(
                    BlurStyle.normal,
                    glowSigma * 0.45,
                  ),
              );
              // Bright white hot core
              canvas.drawCircle(
                Offset.zero,
                r * 0.75,
                Paint()..color = Colors.white.withValues(alpha: alpha),
              );
            }

            if (!isParticle) canvas.restore();
          },
        ).moving(from: Vector2.zero(), to: travel);
      },
    );
  }
}
