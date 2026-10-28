import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/id_generator.dart';
import '../domain/alarm_rules.dart';

/// Prefix of a sound_ref that points at a file copied from the device.
const deviceSoundPrefix = 'file:';

/// Bundled tones and sound files chosen from the device.
class AlarmSoundStore {
  AlarmSoundStore(this._ids);

  final IdGenerator _ids;

  static String assetPathForTone(String toneRef) => 'assets/sounds/$toneRef.wav';

  static bool isDeviceSound(String soundRef) =>
      soundRef.startsWith(deviceSoundPrefix);

  /// Name shown on the form for [soundRef].
  static String displayName(String soundRef) {
    final tone = alarmTones[soundRef];
    if (tone != null) return tone;
    if (!isDeviceSound(soundRef)) return 'Default tone';
    final file = soundRef.substring(deviceSoundPrefix.length);
    final name = file.split(RegExp(r'[\\/]')).last;
    // Stored copies are named "<short id>_<original name>".
    final underscore = name.indexOf('_');
    return underscore > 0 ? name.substring(underscore + 1) : name;
  }

  /// Audio path for the alarm player. A device sound that no longer exists
  /// falls back to the first bundled tone.
  static String audioPathFor(String soundRef) {
    if (isDeviceSound(soundRef)) {
      final path = soundRef.substring(deviceSoundPrefix.length);
      if (File(path).existsSync()) return path;
      return assetPathForTone(alarmTones.keys.first);
    }
    final tone =
        alarmTones.containsKey(soundRef) ? soundRef : alarmTones.keys.first;
    return assetPathForTone(tone);
  }

  /// Lets the user choose an audio file and copies it into app storage, so
  /// it still plays if the original is moved. Returns the new sound_ref, or
  /// null if nothing was chosen.
  Future<String?> pickDeviceSound() async {
    final picked = await FilePicker.pickFile(type: FileType.audio);
    if (picked == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final sounds = Directory('${directory.path}${Platform.pathSeparator}sounds');
    await sounds.create(recursive: true);
    final safeName = picked.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final target = '${sounds.path}${Platform.pathSeparator}'
        '${_ids.next().substring(0, 8)}_$safeName';
    final source = picked.path;
    if (source != null) {
      await File(source).copy(target);
    } else {
      // Content URIs have no file path; copy the bytes instead.
      await File(target).writeAsBytes(await picked.readAsBytes());
    }
    return '$deviceSoundPrefix$target';
  }
}

final alarmSoundStoreProvider = Provider<AlarmSoundStore>(
  (ref) => AlarmSoundStore(ref.watch(idGeneratorProvider)),
);
