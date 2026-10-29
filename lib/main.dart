import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/cloud/firebase_setup.dart';
import 'core/platform/notification_service.dart';
import 'core/platform/platform_support.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/account/data/account_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isAndroidDevice) {
    await Alarm.init();
    await NotificationService.instance.init();
    await FirebaseSetup.init();
  }

  // Created here so the saved theme is applied before the first frame.
  final container = ProviderContainer();
  try {
    await container.read(themeModeProvider.notifier).restore();
  } on Object catch (error) {
    debugPrint('Could not restore the theme: $error');
  }
  unawaited(container.read(accountServiceProvider).recordActive());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AgendaWiseApp(),
    ),
  );
}
