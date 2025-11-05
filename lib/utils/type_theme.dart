import 'package:flutter/material.dart';
import 'type_colors.dart';

class TypeTheme {
  final Color primary;
  final Color secondary;

  const TypeTheme({required this.primary, required this.secondary});

  /// Soft vertical gradient for surfaces (cards, pages)
  LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary.withOpacity(0.12),
          secondary.withOpacity(0.05),
        ],
      );

  /// Subtle border / divider color
  Color get border => primary.withOpacity(0.20);

  /// High-contrast text color against tinted backgrounds
  Color get onTint =>
      (ThemeData.estimateBrightnessForColor(primary) == Brightness.dark)
          ? Colors.white
          : Colors.black87;
}

/// Build a TypeTheme from 1–2 types
TypeTheme typeThemeFrom(String type1, [String? type2]) {
  final c1 = typeColor(type1);
  final c2 = (type2 != null) ? typeColor(type2) : c1;
  return TypeTheme(primary: c1, secondary: c2);
}
