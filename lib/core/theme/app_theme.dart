import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppRadius {
  static const double card = 16;
  static const double pill = 999;
}

abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.primaryForeground,
      secondary: c.secondary,
      onSecondary: c.foreground,
      error: c.destructive,
      onError: c.primaryForeground,
      surface: c.card,
      onSurface: c.foreground,
      outline: c.border,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      dividerColor: c.border,
      extensions: [c],
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.primaryForeground),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primary
              : c.switchBackground,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.foreground,
        contentTextStyle: TextStyle(color: c.background),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
