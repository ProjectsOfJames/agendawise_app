import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_repository.dart';

/// Light or dark theme, saved in app_settings so it survives restarts.
///
/// The saved choice is read once before the first frame (see [restore]) to
/// avoid a flash of the wrong theme; later changes are written straight away.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref
        .read(settingsRepositoryProvider)
        .setString(SettingsKeys.themeMode, _encode(mode));
  }

  /// Applies the saved choice without writing it back.
  Future<void> restore() async {
    final saved =
        await ref.read(settingsRepositoryProvider).getString(SettingsKeys.themeMode);
    state = _decode(saved);
  }

  static String _encode(ThemeMode mode) =>
      mode == ThemeMode.dark ? 'dark' : 'light';

  static ThemeMode _decode(String? value) =>
      value == 'dark' ? ThemeMode.dark : ThemeMode.light;
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
