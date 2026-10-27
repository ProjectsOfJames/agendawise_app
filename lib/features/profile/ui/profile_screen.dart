import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/screen_header.dart';

/// Temporary profile: only the theme switch, to verify light and dark.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final isLight = ref.watch(themeModeProvider) != ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                label: 'Profile',
                trailing: CircleIconButton(
                  icon: Icons.close_rounded,
                  semanticLabel: 'Close',
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 24),
              const SectionLabel('Appearance'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLight
                            ? Icons.wb_sunny_outlined
                            : Icons.dark_mode_outlined,
                        color: c.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLight ? 'Light mode' : 'Dark mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: c.foreground,
                            ),
                          ),
                          Text(
                            isLight
                                ? 'Switch to dark theme'
                                : 'Switch to light theme',
                            style: TextStyle(
                              fontSize: 12,
                              color: c.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isLight,
                      onChanged: (v) => ref
                          .read(themeModeProvider.notifier)
                          .set(v ? ThemeMode.light : ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: PlaceholderNote('Full profile is built in later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
