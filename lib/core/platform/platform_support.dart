import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// True when running on a real Android device or emulator. False in widget
/// and unit tests, where the host operating system is reported instead, so
/// native plugins are not called there.
bool get isAndroidDevice => !kIsWeb && Platform.isAndroid;
