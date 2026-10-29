import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import '../platform/platform_support.dart';

/// Whether Firebase started. The app works fully without it; online account
/// features are simply unavailable then.
class FirebaseSetup {
  FirebaseSetup._();

  static bool _ready = false;

  static bool get ready => _ready;

  static Future<void> init() async {
    if (!isAndroidDevice || _ready) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _ready = true;
    } on Object catch (error) {
      debugPrint('Firebase could not start: $error');
    }
  }
}

/// True when online accounts can be used.
final cloudAvailableProvider = Provider<bool>((ref) => FirebaseSetup.ready);
