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
          if (mode == ThemeMode.system) {
            return const Icon(Icons.brightness_auto);
          }
          if (mode == ThemeMode.light) {
            return const Icon(Icons.light_mode);
          }
          return const Icon(Icons.dark_mode);
        },
      ),
      onPressed: () => ThemeService.cycleMode(),
    );
  }
}
