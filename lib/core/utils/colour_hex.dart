import 'package:flutter/painting.dart';

/// Converts between [Color] and the #RRGGBB text stored in the database.
abstract final class ColourHex {
  static String encode(Color colour) {
    final rgb = colour.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Color decode(String hex, {Color fallback = const Color(0xFF6B7280)}) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value == null ? fallback : Color(0xFF000000 | value);
  }
}
