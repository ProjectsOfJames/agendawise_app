import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/platform/alarm_reliability.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../account/application/account_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Settings pages opened from here return to the app; re-check them.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(reliabilityStatusProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _notAvailableYet(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is not available yet.')));
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(currentAccountProvider);
    final signedIn = account != null;
    final isLight = ref.watch(themeModeProvider) != ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ScreenHeader(
              label: 'Profile',
              trailing: CircleIconButton(
                icon: Icons.close_rounded,
                semanticLabel: 'Close',
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(height: 8),
            _Identity(account: account),
            const SizedBox(height: 20),
            if (account != null) ...[
              const SectionLabel('Account info'),
              const SizedBox(height: 10),
              _GroupCard(children: [
                _SettingRow(
                  icon: Icons.person_outline_rounded,
                  caption: 'Full name',
                  title: account.fullName,
                  showChevron: true,
                  onTap: () => _notAvailableYet('Editing your name'),
                ),
                _SettingRow(
                  icon: Icons.mail_outline_rounded,
                  caption: 'Email',
                  title: account.email,
                  showChevron: true,
                  onTap: () => _notAvailableYet('Editing your email'),
                ),
                _SettingRow(
                  icon: Icons.lock_outline_rounded,
                  caption: 'Password',
                  title: '••••••••',
                  showChevron: true,
                  onTap: () => _notAvailableYet('Changing your password'),
                ),
              ]),
            ] else ...[
              const SectionLabel('Account'),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => _notAvailableYet('Signing in'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                  child: const Text(
                    'Sign in or create account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const SectionLabel('Appearance'),
            const SizedBox(height: 10),
            _GroupCard(children: [
              _SettingRow(
                icon: isLight ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                title: isLight ? 'Light mode' : 'Dark mode',
                subtitle:
                    isLight ? 'Switch to dark theme' : 'Switch to light theme',
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .set(isLight ? ThemeMode.dark : ThemeMode.light),
                trailing: Switch(
                  value: isLight,
                  onChanged: (light) => ref
                      .read(themeModeProvider.notifier)
                      .set(light ? ThemeMode.light : ThemeMode.dark),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            const SectionLabel('Alarm reliability'),
            const SizedBox(height: 10),
            const _ReliabilityCard(),
            const SizedBox(height: 20),
            const SectionLabel('Data'),
            const SizedBox(height: 10),
            _GroupCard(children: [
              _SettingRow(
                icon: Icons.file_upload_outlined,
                iconTint: AppColors.of(context).success,
                title: 'Import data',
                subtitle: signedIn
                    ? 'Restore from a backup file'
                    : 'Sign in to restore a backup',
                enabled: signedIn,
                showChevron: true,
                onTap: () => _notAvailableYet('Importing data'),
              ),
              _SettingRow(
                icon: Icons.file_download_outlined,
                title: 'Export data',
                subtitle: signedIn
                    ? 'Save a backup of all your data'
                    : 'Sign in to save a backup',
                enabled: signedIn,
                showChevron: true,
                onTap: () => _notAvailableYet('Exporting data'),
              ),
            ]),
            const SizedBox(height: 24),
            Text(
              'Everything is stored on this device only.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.account});

  final User? account;

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = account;

    final avatar = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user == null ? c.muted : null,
        gradient: user == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.primary,
                  Color.lerp(c.primary, c.foreground, 0.2)!,
                ],
              ),
      ),
      alignment: Alignment.center,
      child: user == null
          ? Icon(Icons.person_outline_rounded, size: 44, color: c.mutedForeground)
          : Text(
              _initials(user.fullName),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: c.primaryForeground,
              ),
            ),
    );

    return Column(
      children: [
        Semantics(
          label: user == null ? 'No profile picture' : 'Profile picture',
          child: avatar,
        ),
        const SizedBox(height: 12),
        Text(
          user?.fullName ?? 'Not signed in',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: c.foreground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          user?.email ?? 'The app works fully without an account',
          style: TextStyle(fontSize: 13, color: c.mutedForeground),
        ),
      ],
    );
  }
}

class _ReliabilityCard extends ConsumerWidget {
  const _ReliabilityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final status = ref.watch(reliabilityStatusProvider);

    return status.when(
      loading: () => const _GroupCard(children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ]),
      error: (error, _) => _GroupCard(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Could not check: $error',
              style: TextStyle(color: c.destructive)),
        ),
      ]),
      data: (items) => _GroupCard(children: [
        for (final item in ReliabilityItem.values)
          _SettingRow(
            icon: items[item] ?? false
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            iconTint: items[item] ?? false ? c.success : c.priorityMedium,
            title: item.title,
            subtitle: item.description,
            trailing: items[item] ?? false
                ? null
                : TextButton(
                    onPressed: () async {
                      await ref.read(alarmReliabilityProvider).fix(item);
                      ref.invalidate(reliabilityStatusProvider);
                    },
                    child: const Text('Fix'),
                  ),
          ),
      ]),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 64, color: c.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.caption,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconTint,
    this.enabled = true,
    this.showChevron = false,
  });

  final IconData icon;
  final String title;

  /// Small upper-case label above the title.
  final String? caption;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconTint;
  final bool enabled;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tint = iconTint ?? c.primary;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: tint),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (caption != null)
                        Text(
                          caption!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: c.mutedForeground,
                          ),
                        ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.foreground,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style:
                              TextStyle(fontSize: 12, color: c.mutedForeground),
                        ),
                    ],
                  ),
                ),
                ?trailing,
                if (showChevron)
                  Icon(Icons.chevron_right_rounded, color: c.mutedForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
