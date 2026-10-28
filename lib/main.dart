import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform/notification_service.dart';
import 'core/platform/platform_support.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isAndroidDevice) {
    await Alarm.init();
    await NotificationService.instance.init();
  }
  runApp(const ProviderScope(child: AgendaWiseApp()));
}
