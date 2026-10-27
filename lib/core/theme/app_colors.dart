import 'package:flutter/material.dart';

/// Design tokens converted from Figma
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.muted,
    required this.mutedForeground,
    required this.destructive,
    required this.border,
    required this.inputBackground,
    required this.switchBackground,
    required this.navBg,
    required this.navBorder,
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
    required this.success,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color muted;
  final Color mutedForeground;
  final Color destructive;
  final Color border;
  final Color inputBackground;
  final Color switchBackground;
  final Color navBg;
  final Color navBorder;
  final Color priorityHigh;
  final Color priorityMedium;
  final Color priorityLow;
  final Color success;

  static const light = AppColors(
    background: Color(0xFFF5F7FF),
    foreground: Color(0xFF0C0C1D),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF06B6D4),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFEAF9FC),
    muted: Color(0xFFEEF1F8),
    mutedForeground: Color(0xFF6B7280),
    destructive: Color(0xFFF43F5E),
    border: Color(0x14000000),
    inputBackground: Color(0xFFEEF1F8),
    switchBackground: Color(0xFFCBD5E1),
    navBg: Color(0xF7F5F7FF),
    navBorder: Color(0x12000000),
    priorityHigh: Color(0xFFF43F5E),
    priorityMedium: Color(0xFFF97316),
    priorityLow: Color(0xFF009689),
    success: Color(0xFF34D399),
  );

  static const dark = AppColors(
    background: Color(0xFF0A0A12),
    foreground: Color(0xFFF0F0F8),
    card: Color(0xFF12121E),
    primary: Color(0xFF7C5CFC),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF1E1E2E),
    muted: Color(0xFF1A1A28),
    mutedForeground: Color(0xFF6B6B8A),
    destructive: Color(0xFFFF4D6D),
    border: Color(0x14FFFFFF),
    inputBackground: Color(0xFF1E1E2E),
    switchBackground: Color(0xFF3A3A5C),
    navBg: Color(0xF7080810),
    navBorder: Color(0x12FFFFFF),
    priorityHigh: Color(0xFFFF4D6D),
    priorityMedium: Color(0xFFF97316),
    priorityLow: Color(0xFF009689),
    success: Color(0xFF34D399),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith() => this;

  // Theme switches are instant, so no interpolation is needed.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      other is AppColors && t >= 0.5 ? other : this;
}
