import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();

  /// Current theme mode for the app.
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Toggle between Light ↔ Dark (if on System, go to Dark first).
  static void toggle() {
    final m = themeMode.value;
    if (m == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
    } else if (m == ThemeMode.dark) {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.dark;
    }
  }
}
