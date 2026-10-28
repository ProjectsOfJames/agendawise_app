import 'dart:convert';

/// Stable positive 31-bit id for a record id, as native alarm and
/// notification ids must be integers. [salt] keeps alarm and reminder ids
/// apart. Uses FNV-1a so the value is the same on every run.
int nativeIdFor(String id, {String salt = 'alarm'}) {
  var hash = 0x811C9DC5;
  for (final unit in '$salt:$id'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final value = hash & 0x7FFFFFFF;
  return value == 0 ? 1 : value;
}

/// Data carried with a scheduled native alarm, so a ring can be matched to
/// its stored alarm and the snooze count survives the app being closed.
class RingPayload {
  const RingPayload({required this.alarmId, this.snoozesUsed = 0});

  final String alarmId;
  final int snoozesUsed;

  String encode() => jsonEncode({'alarmId': alarmId, 'snoozes': snoozesUsed});

  /// Returns null for missing or unreadable payloads.
  static RingPayload? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic>) return null;
      final alarmId = data['alarmId'];
      if (alarmId is! String || alarmId.isEmpty) return null;
      final snoozes = data['snoozes'];
      return RingPayload(
        alarmId: alarmId,
        snoozesUsed: snoozes is int && snoozes > 0 ? snoozes : 0,
      );
    } on FormatException {
      return null;
    }
  }
}
