import 'package:flutter/material.dart';

import '../../data/services/theme_service.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Toggle theme',
      icon: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.notifier,
        builder: (context, mode, child) {
          return Icon(
            mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
          );
        },
      ),
      onPressed: () => ThemeService.cycleMode(),
    );
  }
}
