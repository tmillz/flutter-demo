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
    _game = TRexGame(
      onBack: () {
        if (mounted) context.canPop() ? context.pop() : context.go('/');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GameWidget(game: _game),
    );
  }
}
