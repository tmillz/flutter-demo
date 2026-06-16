import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SparkleComponent extends PositionComponent {
  SparkleComponent({
    required this.isDark,
  }) : super() {
    _randomizeSize();
    _randomizeSpeed();
  }

  bool isDark;
  final Random _random = Random();
  
  double _opacity = 0.0;
  double _fadeDirection = 1.0;
  double _speedX = 0.0;
  double _speedY = 0.0;
  double _size = 2.0;

  void _randomizePosition() {
    position = Vector2(
      _random.nextDouble() * size.x,
      _random.nextDouble() * size.y,
    );
  }

  void _randomizeSize() {
    _size = 3.0 + _random.nextDouble() * 5.0;
  }

  void _randomizeSpeed() {
    _speedX = (_random.nextDouble() - 0.5) * 20;
    _speedY = (_random.nextDouble() - 0.5) * 20;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move sparkle
    position.x += _speedX * dt;
    position.y += _speedY * dt;
    
    // Fade in and out
    _opacity += _fadeDirection * dt * 0.5;
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
        ? Colors.yellow.withOpacity(_opacity * 0.7)
        : Colors.green.withOpacity(_opacity * 0.7);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(position.x, position.y), _size, paint);
  }

  @override
  void onMount() {
    super.onMount();
    _randomizePosition();
  }
}
