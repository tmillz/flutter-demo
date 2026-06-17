import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ParticleComponent extends PositionComponent {
  ParticleComponent({
    required this.isDark,
  }) : super() {
    _randomizeVelocity();
  }

  bool isDark;
  final Random _random = Random();
  
  double _velocityX = 0.0;
  double _velocityY = 0.0;
  double _life = 0.0;
  double _maxLife = 0.0;

  void _randomizePosition() {
    position = Vector2(
      size.x + _random.nextDouble() * 100, // Start from right side
      _random.nextDouble() * size.y * 0.3, // Top 30% of screen
    );
  }

  void _randomizeVelocity() {
    _velocityX = (_random.nextDouble() - 0.5) * 50; // Slower movement
    _velocityY = (_random.nextDouble() - 0.5) * 50; // Slower movement
    _maxLife = 4.0 + _random.nextDouble() * 4.0; // Live longer (4-8 seconds)
    _life = _maxLife;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move particle
    position.x += _velocityX * dt;
    position.y += _velocityY * dt;
    
    // Decrease life
    _life -= dt;
    
    // Reset when life ends
    if (_life <= 0) {
      _randomizePosition();
      _randomizeVelocity();
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = (_life / _maxLife).clamp(0.0, 1.0);
    final color = isDark
        ? Colors.purple.withValues(alpha: opacity * 0.6)
        : Colors.orange.withValues(alpha: opacity * 0.6);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(position.x, position.y), 6.0, paint);
  }

  @override
  void onMount() {
    super.onMount();
    _randomizePosition();
  }
}
