import 'package:agendawise/core/utils/colour_hex.dart';
import 'package:agendawise/core/utils/date_labels.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColourHex', () {
    test('encodes and decodes #RRGGBB', () {
      expect(ColourHex.encode(const Color(0xFF06B6D4)), '#06B6D4');
      expect(ColourHex.decode('#06B6D4'), const Color(0xFF06B6D4));
    });

    test('invalid text falls back', () {
      expect(ColourHex.decode('nope', fallback: const Color(0xFF000000)),
          const Color(0xFF000000));
    });
  });

  group('date labels', () {
    final now = DateTime(2026, 11, 2, 14); // Monday

    test('relative day names', () {
      expect(dayLabel(DateTime(2026, 11, 2, 9), now), 'Today');
      expect(dayLabel(DateTime(2026, 11, 3), now), 'Tomorrow');
      expect(dayLabel(DateTime(2026, 11, 1), now), 'Yesterday');
      expect(dayLabel(DateTime(2026, 11, 6), now), 'Fri 6 Nov');
      expect(dayLabel(DateTime(2027, 1, 4), now), 'Mon 4 Jan 2027');
    });

    test('due label includes time unless all-day', () {
      expect(dueLabel(DateTime(2026, 11, 3, 9, 5), allDay: false, now: now),
          'Tomorrow · 09:05');
      expect(dueLabel(DateTime(2026, 11, 3), allDay: true, now: now),
          'Tomorrow');
    });
  });
}
