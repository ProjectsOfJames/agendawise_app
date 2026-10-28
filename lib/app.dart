import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/platform/clock_format_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

class AgendaWiseApp extends ConsumerWidget {
  const AgendaWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final use24Hour = ref.watch(use24HourFormatProvider);

    return MaterialApp.router(
      title: 'AgendaWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
      // Applies the live device clock setting to every time shown in the app.
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (use24Hour == null) return content;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24Hour),
          child: content,
        );
      },
    );
  }
}
