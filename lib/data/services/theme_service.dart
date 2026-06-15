import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService {
  static const String _key = 'theme_mode';
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.system);

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> initialize() async {
    final String? stored = await _storage.read(key: _key);
    switch (stored) {
      case 'light':
        notifier.value = ThemeMode.light;
        break;
      case 'dark':
        notifier.value = ThemeMode.dark;
        break;
      default:
        notifier.value = ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    notifier.value = mode;
    if (mode == ThemeMode.system) {
      await _storage.delete(key: _key);
    } else if (mode == ThemeMode.light) {
      await _storage.write(key: _key, value: 'light');
    } else if (mode == ThemeMode.dark) {
      await _storage.write(key: _key, value: 'dark');
    }
  }

  /// Cycle modes: system -> light -> dark -> system
  static Future<void> cycleMode() async {
    final current = notifier.value;
    if (current == ThemeMode.system) {
      await setThemeMode(ThemeMode.light);
    } else if (current == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.system);
    }
  }
}
