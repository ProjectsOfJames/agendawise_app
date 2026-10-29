import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform/notification_service.dart';
import 'core/platform/platform_support.dart';
import 'core/theme/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isAndroidDevice) {
    await Alarm.init();
    await NotificationService.instance.init();
  }

  // Created here so the saved theme is applied before the first frame.
  final container = ProviderContainer();
  try {
    await container.read(themeModeProvider.notifier).restore();
  } on Object catch (error) {
    debugPrint('Could not restore the theme: $error');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AgendaWiseApp(),
    ),
  );
}
