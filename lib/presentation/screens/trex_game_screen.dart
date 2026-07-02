import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../games/trex/trex_game.dart';

class TrexGameScreen extends StatefulWidget {
  const TrexGameScreen({super.key});

  @override
  State<TrexGameScreen> createState() => _TrexGameScreenState();
}

class _TrexGameScreenState extends State<TrexGameScreen> {
  late final TRexGame _game;

  @override
  void initState() {
    super.initState();
    _game = TRexGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(24),
            child: ClipRect(
              child: GameWidget(game: _game),
            ),
          ),
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
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
