import 'package:flutter/material.dart';

/// Formats a time of day using the device's 12 or 24-hour setting.
String formatTime(BuildContext context, DateTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// Formats minutes after midnight as a time of day.
String formatMinutes(BuildContext context, int minutes) => formatTime(
      context,
      DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60),
    );
