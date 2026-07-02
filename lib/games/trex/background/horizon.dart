import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';

import '../obstacle/obstacle_manager.dart';
import '../trex_game.dart';
import 'cloud_manager.dart';

class Horizon extends PositionComponent with HasGameReference<TRexGame> {
  Horizon() : super();

  static final Vector2 lineSize = Vector2(1200, 24);
  final Queue<SpriteComponent> groundLayers = Queue();
  late final CloudManager cloudManager = CloudManager();
  late final ObstacleManager obstacleManager = ObstacleManager();

  late final _softSprite = Sprite(
    game.spriteImage,
    srcPosition: Vector2(2.0, 104.0),
    srcSize: lineSize,
  );

  late final _bumpySprite = Sprite(
    game.spriteImage,
    srcPosition: Vector2(game.spriteImage.width / 2, 104.0),
    srcSize: lineSize,
  );

  @override
  Future<void> onLoad() async {
    add(cloudManager);
    add(obstacleManager);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final increment = game.currentSpeed * dt;
    for (final line in groundLayers) {
      line.x -= increment;
    }

    if (groundLayers.isEmpty) {
      return;
    }

    final firstLine = groundLayers.first;
    if (firstLine.x <= -firstLine.width) {
      final lastLine = groundLayers.last;
      firstLine.x = lastLine.x + lastLine.width;
      groundLayers.remove(firstLine);
      groundLayers.add(firstLine);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final newLines = _generateLines();
    groundLayers.addAll(newLines);
    addAll(newLines);
    y = (size.y / 2) + 21.0;
  }

  void reset() {
    cloudManager.reset();
    obstacleManager.reset();

    var i = 0;
    for (final line in groundLayers) {
      line.x = i * lineSize.x;
      i++;
    }
  }

  List<SpriteComponent> _generateLines() {
    final number = 1 + (game.size.x / lineSize.x).ceil() - groundLayers.length;
    final hasLines = groundLayers.isNotEmpty;
    final lastX = hasLines ? groundLayers.last.x + groundLayers.last.width : 0;

    return List.generate(
      max(number, 0),
      (i) => SpriteComponent(
        sprite: (i + groundLayers.length).isEven ? _softSprite : _bumpySprite,
        size: lineSize,
      )..x = lastX + lineSize.x * i,
      growable: false,
    );
  }
}
