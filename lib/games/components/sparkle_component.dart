import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SparkleComponent extends PositionComponent {
  SparkleComponent({required this.isDark}) : super() {
    _randomizeSize();
    _randomizeSpeed();
  }

  bool isDark;
  final Random _random = Random();
  Vector2 _gameSize = Vector2.zero();

  double _opacity = 0.0;
  double _fadeDirection = 1.0;
  double _speedX = 0.0;
  double _speedY = 0.0;
  double _size = 2.0;

  void _randomizePosition() {
    position = Vector2(
      _random.nextDouble() * _gameSize.x,
      _random.nextDouble() * (_gameSize.y * 0.25),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _gameSize = size;
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    _randomizePosition();
  }

  void _randomizeSize() {
    _size = 3.0 + _random.nextDouble() * 5.0;
  }

  void _randomizeSpeed() {
    _speedX = (_random.nextDouble() - 0.5) * 10; // Slower movement
    _speedY = (_random.nextDouble() - 0.5) * 10; // Slower movement
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move sparkle
    position.x += _speedX * dt;
    position.y += _speedY * dt;

    // Fade in and out (slower for longer life)
    _opacity += _fadeDirection * dt * 0.3;
    if (_opacity >= 1.0) {
      _opacity = 1.0;
      _fadeDirection = -1.0;
    } else if (_opacity <= 0.0) {
      _opacity = 0.0;
      _fadeDirection = 1.0;
      _randomizePosition();
      _randomizeSpeed();
    }
  }

  @override
  void render(Canvas canvas) {
    final color = isDark
        ? const Color.fromARGB(
            172,
            255,
            160,
            59,
          ).withValues(alpha: _opacity * 0.7)
        : Colors.green.withValues(alpha: _opacity * 0.7);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(position.x, position.y), _size, paint);
  }
}
