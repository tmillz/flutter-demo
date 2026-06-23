import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService {
  static const String _key = 'theme_mode';
  // Start as light — initialize() will correct this from storage before the
  // first frame, but starting as system causes a brief bad state window.
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier(
    ThemeMode.light,
  );

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> initialize() async {
    final String? stored = await _storage.read(key: _key);
    // Default to light — avoids the ambiguous system mode where cycling
    // from system→light appears to do nothing if the OS is already light.
    notifier.value = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    // Update the notifier synchronously first so the UI responds immediately.
    notifier.value = mode;

    // Persist asynchronously — errors are non-fatal (preference just won't
    // survive a restart, which is acceptable).
    try {
      if (mode == ThemeMode.system) {
        await _storage.delete(key: _key);
      } else if (mode == ThemeMode.light) {
        await _storage.write(key: _key, value: 'light');
      } else if (mode == ThemeMode.dark) {
        await _storage.write(key: _key, value: 'dark');
      }
    } catch (_) {
      // Storage unavailable (e.g. WebCrypto not ready) — UI is already updated.
    }
  }

  /// Toggle between light and dark.
  static void cycleMode() {
    setThemeMode(
      notifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
