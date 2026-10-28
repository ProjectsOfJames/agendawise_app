import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/alarm_display.dart';
import '../../../core/platform/platform_support.dart';
import '../../settings/data/settings_repository.dart';

/// Share of the alarm volume kept while a challenge is on screen.
const challengeVolumeShare = 0.3;

/// Idle time after which the alarm returns to full volume.
const challengeIdleLimit = Duration(seconds: 30);

const _savedLevelKey = 'alarm_volume_before_challenge';

/// Lowers the alarm volume during a challenge and puts it back afterwards.
/// The original level is stored so it can be restored at the next start-up
/// if the app is closed mid-challenge.
class ChallengeVolume {
  ChallengeVolume(this._settings, [this._display = const AlarmDisplay()]);

  final SettingsRepository _settings;
  final AlarmDisplay _display;

  int? _fullLevel;

  bool get _enabled => isAndroidDevice;

  Future<void> start() async {
    if (!_enabled) return;
    final saved = int.tryParse(await _settings.getString(_savedLevelKey) ?? '');
    final level = saved ?? await _display.alarmVolumeLevel();
    if (level == null) return;
    _fullLevel = level;
    await _settings.setString(_savedLevelKey, '$level');
    await quiet();
  }

  Future<void> quiet() async {
    final full = _fullLevel;
    if (!_enabled || full == null || full == 0) return;
    final reduced = (full * challengeVolumeShare).round().clamp(1, full);
    await _display.setAlarmVolumeLevel(reduced);
  }

  Future<void> full() async {
    final full = _fullLevel;
    if (!_enabled || full == null) return;
    await _display.setAlarmVolumeLevel(full);
  }

  /// Restores the original level and forgets it.
  Future<void> finish() async {
    await full();
    _fullLevel = null;
    if (_enabled) await _settings.remove(_savedLevelKey);
  }

  /// Restores a level left behind by a challenge that never finished.
  Future<void> restoreLeftover() async {
    if (!_enabled) return;
    final saved = int.tryParse(await _settings.getString(_savedLevelKey) ?? '');
    if (saved == null) return;
    await _display.setAlarmVolumeLevel(saved);
    await _settings.remove(_savedLevelKey);
  }
}

final challengeVolumeProvider = Provider<ChallengeVolume>(
  (ref) => ChallengeVolume(ref.watch(settingsRepositoryProvider)),
);
