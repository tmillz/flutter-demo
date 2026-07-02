import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class PingGame extends FlameGame {
  PingGame({this.isDark = false});

  bool isDark;

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<bool> isGameOver = ValueNotifier(false);

  late _BallComponent _ball;
  late _PaddleComponent _paddle;

  static const double _paddleWidth = 110.0;
  static const double _paddleHeight = 14.0;
  static const double _paddleBottomOffset = 80.0;
  static const double _ballRadius = 10.0;
  static const double _initialBallSpeed = 320.0;
  static const double _maxBallSpeed = 700.0;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _addComponents();
  }

  void _addComponents() {
    _paddle = _PaddleComponent(
      position: Vector2(
        (size.x - _paddleWidth) / 2,
        size.y - _paddleBottomOffset,
      ),
      size: Vector2(_paddleWidth, _paddleHeight),
    );

    final angle = _randomStartAngle();
    _ball = _BallComponent(
      position: Vector2(size.x / 2, size.y * 0.45),
      velocity: Vector2(
        cos(angle) * _initialBallSpeed,
        sin(angle) * _initialBallSpeed,
      ),
    );

    addAll([_paddle, _ball]);
  }

  double _randomStartAngle() {
    // Shoot upward with a random left/right angle (±40° from straight up)
    return -pi / 2 + (Random().nextDouble() - 0.5) * (2 * pi / 4.5);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver.value) return;

    _checkPaddleCollision();
    _checkGameOver();
  }

  void _checkPaddleCollision() {
    // Only check when ball is moving downward
    if (_ball.velocity.y <= 0) return;

    final ballLeft = _ball.position.x - _ballRadius;
    final ballRight = _ball.position.x + _ballRadius;
    final ballBottom = _ball.position.y + _ballRadius;
    final ballTop = _ball.position.y - _ballRadius;

    final paddleLeft = _paddle.position.x;
    final paddleRight = _paddle.position.x + _paddle.size.x;
    final paddleTop = _paddle.position.y;
    final paddleBottom = _paddle.position.y + _paddle.size.y;

    final overlaps =
        ballBottom >= paddleTop &&
        ballTop <= paddleBottom &&
        ballRight >= paddleLeft &&
        ballLeft <= paddleRight;

    if (!overlaps) return;

    // Bounce the ball upward
    _ball.velocity.y = -_ball.velocity.y.abs();

    // Deflect angle based on where the ball hits the paddle (edge hits = steeper angle)
    final hitFraction = (_ball.position.x - paddleLeft) / _paddle.size.x;
    final deflect = (hitFraction - 0.5) * 480;
    _ball.velocity.x = deflect;

    // Gradually increase speed up to the cap
    final newSpeed = (_ball.velocity.length * 1.05).clamp(0.0, _maxBallSpeed);
    _ball.velocity.normalize();
    _ball.velocity.scale(newSpeed);

    score.value++;
  }

  void _checkGameOver() {
    if (_ball.position.y - _ballRadius > size.y) {
      isGameOver.value = true;
      pauseEngine();
    }
  }

  /// Called by the Flutter widget layer to move the paddle to follow a touch.
  void movePaddleTo(double screenX) {
    if (isGameOver.value) return;
    final newX = screenX - _paddle.size.x / 2;
    _paddle.position.x = newX.clamp(0.0, size.x - _paddle.size.x);
  }

  /// Reset state and resume the game.
  void restart() {
    score.value = 0;
    isGameOver.value = false;

    _ball.position = Vector2(size.x / 2, size.y * 0.45);
    final angle = _randomStartAngle();
    _ball.velocity = Vector2(
      cos(angle) * _initialBallSpeed,
      sin(angle) * _initialBallSpeed,
    );

    _paddle.position = Vector2(
      (size.x - _paddleWidth) / 2,
      size.y - _paddleBottomOffset,
    );

    resumeEngine();
  }

  /// Mirrors the pattern in BackgroundGame — called by the Flutter layer when
  /// the app's light/dark theme changes.
  void updateTheme(bool dark) {
    isDark = dark;
  }

  @override
  void render(Canvas canvas) {
    // Background mirrors the app's BackgroundGame light/dark palette
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f3460), Color(0xFF1a1a2e)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFffffff), Color(0xFFe8e8e8), Color(0xFFffcc80)],
            stops: [0.0, 0.5, 1.0],
          );
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Horizontal dashed midfield line for visual reference
    final dashPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..strokeWidth = 2;
    const dashLen = 12.0;
    const dashGap = 8.0;
    double x = 0;
    while (x < size.x) {
      canvas.drawLine(
        Offset(x, size.y / 2),
        Offset(x + dashLen, size.y / 2),
        dashPaint,
      );
      x += dashLen + dashGap;
    }

    super.render(canvas);
  }
}

// ---------------------------------------------------------------------------
// Internal components — not exported
// ---------------------------------------------------------------------------

class _BallComponent extends PositionComponent {
  static const double radius = 10.0;

  Vector2 velocity;

  _BallComponent({required Vector2 position, required this.velocity})
    : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    position += velocity * dt;

    final game = findGame()! as PingGame;

    // Left wall
    if (position.x - radius <= 0) {
      position.x = radius;
      velocity.x = velocity.x.abs();
    }
    // Right wall
    if (position.x + radius >= game.size.x) {
      position.x = game.size.x - radius;
      velocity.x = -velocity.x.abs();
    }
    // Top wall
    if (position.y - radius <= 0) {
      position.y = radius;
      velocity.y = velocity.y.abs();
    }
  }

  @override
  void render(Canvas canvas) {
    final isDark = (findGame()! as PingGame).isDark;
    final ballColor = isDark ? Colors.white : const Color(0xFFBF360C);
    final glowColor = isDark ? Colors.cyanAccent : Colors.deepOrange;

    // Tail drawn first so ball renders on top
    _drawTail(canvas, glowColor: glowColor);

    // Halo glow around ball
    canvas.drawCircle(
      Offset.zero,
      radius * 2.0,
      Paint()
        ..color = glowColor.withValues(alpha: isDark ? 0.18 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Solid ball
    canvas.drawCircle(Offset.zero, radius, Paint()..color = ballColor);
  }

  /// Draws a triangle tail behind the ball whose length grows with speed.
  void _drawTail(Canvas canvas, {required Color glowColor}) {
    final speed = velocity.length;
    if (speed < 1) return;

    const maxTailLength = 65.0;
    final tailLength = (speed / PingGame._maxBallSpeed) * maxTailLength;
    if (tailLength < 4) return;

    final inv = 1.0 / speed;
    // Unit vector pointing backward (opposite to velocity)
    final tDx = -velocity.x * inv;
    final tDy = -velocity.y * inv;
    // Perpendicular unit vector (for triangle base width)
    final pDx = -velocity.y * inv;
    final pDy = velocity.x * inv;

    final baseWidth = radius * 0.9;
    final tip = Offset(tDx * tailLength, tDy * tailLength);
    final b1 = Offset(pDx * baseWidth, pDy * baseWidth);
    final b2 = Offset(-pDx * baseWidth, -pDy * baseWidth);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..close();

    // Soft outer glow pass
    canvas.drawPath(
      path,
      Paint()
        ..color = glowColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Sharp core with linear gradient: transparent at tip → opaque at ball
    final shader = ui.Gradient.linear(tip, Offset.zero, [
      glowColor.withValues(alpha: 0.0),
      glowColor.withValues(alpha: 0.7),
    ]);
    canvas.drawPath(path, Paint()..shader = shader);
  }
}

class _PaddleComponent extends PositionComponent {
  _PaddleComponent({required super.position, required super.size});

  @override
  void render(Canvas canvas) {
    final isDark = (findGame()! as PingGame).isDark;
    final paddleColor = isDark ? Colors.white : const Color(0xFFE65100);
    final glowColor = isDark
        ? Colors.cyanAccent.withValues(alpha: 0.35)
        : Colors.orange.withValues(alpha: 0.55);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(7));

    // Glow behind the paddle
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Paddle fill
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = paddleColor
        ..style = PaintingStyle.fill,
    );
  }
}
