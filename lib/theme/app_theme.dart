import 'package:flutter/material.dart';

/// Design tokens — kept identical to the HTML prototype that was already
/// approved, so the real app looks/behaves the same.
class AppColors {
  static const bg = Color(0xFFEEF2F7);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF6F8FB);
  static const line = Color(0xFFE1E7EF);
  static const text = Color(0xFF182233);
  static const muted = Color(0xFF69758A);
  static const muted2 = Color(0xFF9AA5B4);
  static const blue = Color(0xFF3D6BFF);
  static const aqua = Color(0xFF17C3B2);
  static const red = Color(0xFFE5495F);
  static const amber = Color(0xFFE39B2D);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, aqua],
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Vazirmatn',
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text),
    ),
  );
}
