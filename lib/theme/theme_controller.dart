import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();

  /// Current theme mode for the app.
  static const _kThemeModeKey = 'theme_mode';
  static const _kColorKey = 'theme_color';

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  static final ValueNotifier<Color> trainerColor = ValueNotifier(Colors.redAccent);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Mode
    final modeStr = prefs.getString(_kThemeModeKey);
    if (modeStr != null) {
      themeMode.value = ThemeMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => ThemeMode.system,
      );
    }

    // Load Color
    final colorVal = prefs.getInt(_kColorKey);
    if (colorVal != null) {
      trainerColor.value = Color(colorVal);
    }
  }

  static Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final m = themeMode.value;
    final next = (m == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    themeMode.value = next;
    await prefs.setString(_kThemeModeKey, next.name);
  }

  static Future<void> setTrainerColor(Color c) async {
    final prefs = await SharedPreferences.getInstance();
    trainerColor.value = c;
    await prefs.setInt(_kColorKey, c.value);
  }
}
