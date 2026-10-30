import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/alarm_reliability.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../account/application/account_providers.dart';
import '../../account/data/account_service.dart';
import '../../account/data/avatar_store.dart';
import '../../account/domain/account.dart';
import '../../account/ui/account_widgets.dart';
import '../../admin/ui/admin_card.dart';
import '../../backup/application/backup_service.dart';
import '../../backup/domain/backup_format.dart';

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

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _backupBusy = false;

  Future<void> _exportData() async {
    setState(() => _backupBusy = true);
    try {
      final saved = await ref.read(backupServiceProvider).export();
      if (saved && mounted) _show('Backup saved.');
    } on BackupException catch (e) {
      if (mounted) _show(e.message);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importData() async {
    final service = ref.read(backupServiceProvider);
    final PickedBackup? picked;
    try {
      picked = await service.pick();
    } on BackupException catch (e) {
      if (mounted) _show(e.message);
      return;
    }
    if (picked == null || !mounted) return;
    final chosen = picked;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ImportConfirmDialog(picked: chosen),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _backupBusy = true);
    try {
      await service.restore(chosen.contents);
      if (mounted) _show('Your data has been restored.');
    } on BackupException catch (e) {
      if (mounted) _show(e.message);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _changePicture(Account account) async {
    try {
      final path = await ref
          .read(avatarStoreProvider)
          .pick(uid: account.uid, replacing: account.imagePath);
      if (path == null) return;
      await ref.read(accountServiceProvider).setProfilePicture(path);
    } on Object catch (error) {
      if (mounted) _show('Could not use that picture: $error');
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'Your tasks, events and alarms stay on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountServiceProvider).signOut();
    if (mounted) _show('Signed out.');
  }

  Future<void> _deleteAccount() async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (deleted == true && mounted) _show('Your account has been deleted.');
  }

  Future<void> _setUsage(bool value) async {
    try {
      await ref.read(accountServiceProvider).setUsageOptIn(value);
      ref.invalidate(usageOptInProvider);
    } on AccountException catch (e) {
      if (mounted) _show(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
            _Identity(
              account: account,
              onChangePicture:
                  account == null ? null : () => _changePicture(account),
            ),
            const SizedBox(height: 20),
            if (account != null) ...[
              const SectionLabel('Account info'),
              const SizedBox(height: 10),
              _GroupCard(children: [
                _SettingRow(
                  icon: Icons.person_outline_rounded,
                  caption: 'Full name',
                  title: account.displayName,
                  showChevron: true,
                  onTap: () => context.push(AppRoutes.editName),
                ),
                _SettingRow(
                  icon: Icons.mail_outline_rounded,
                  caption: 'Email',
                  title: account.email,
                  showChevron: true,
                  onTap: () => context.push(AppRoutes.editEmail),
                ),
                _SettingRow(
                  icon: Icons.lock_outline_rounded,
                  caption: 'Password',
                  title: '••••••••',
                  showChevron: true,
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
              ]),
              const SizedBox(height: 20),
              const SectionLabel('Privacy'),
              const SizedBox(height: 10),
              _GroupCard(children: [
                _SettingRow(
                  icon: Icons.insights_outlined,
                  title: 'Share anonymous usage',
                  subtitle: 'Which features are used, never their content',
                  trailing: Switch(
                    value: ref.watch(usageOptInProvider).asData?.value ?? false,
                    onChanged: _setUsage,
                  ),
                ),
                _SettingRow(
                  icon: Icons.history_rounded,
                  title: 'My activity',
                  subtitle: 'What your account has recorded online',
                  showChevron: true,
                  onTap: () => context.push(AppRoutes.myActivity),
                ),
                _SettingRow(
                  icon: Icons.policy_outlined,
                  title: 'Privacy notice',
                  showChevron: true,
                  onTap: () => context.push(AppRoutes.privacyNotice),
                ),
                _SettingRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  onTap: _signOut,
                ),
                _SettingRow(
                  icon: Icons.delete_outline_rounded,
                  iconTint: c.destructive,
                  title: 'Delete account',
                  subtitle: 'Removes your online account and activity log',
                  onTap: _deleteAccount,
                ),
              ]),
              const AdminCard(),
            ] else ...[
              const SectionLabel('Account'),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => context.push(AppRoutes.signIn),
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
                iconTint: c.success,
                title: 'Import data',
                subtitle: signedIn
                    ? 'Restore from a backup file'
                    : 'Sign in to restore a backup',
                enabled: signedIn && !_backupBusy,
                showChevron: true,
                onTap: _importData,
              ),
              _SettingRow(
                icon: Icons.file_download_outlined,
                title: 'Export data',
                subtitle: signedIn
                    ? 'Save a backup of all your data'
                    : 'Sign in to save a backup',
                enabled: signedIn && !_backupBusy,
                showChevron: true,
                onTap: _exportData,
              ),
            ]),
            const SizedBox(height: 24),
            Text(
              'Your tasks, events and alarms are stored on this device only.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportConfirmDialog extends StatelessWidget {
  const _ImportConfirmDialog({required this.picked});

  final PickedBackup picked;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final backup = picked.contents;
    final exported = backup.exportedAt?.toLocal();
    final counts = [
      '${backup.count('tasks')} tasks',
      '${backup.count('calendar_events')} events',
      '${backup.count('alarms')} alarms',
      '${backup.count('categories')} categories',
    ].join(' · ');

    return AlertDialog(
      title: const Text('Replace all data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Importing ${picked.fileName} replaces everything on this device. '
            'This cannot be undone.',
          ),
          const SizedBox(height: 12),
          Text(
            [
              if (exported != null)
                'Saved ${exported.day}/${exported.month}/${exported.year}',
              counts,
            ].join('\n'),
            style: TextStyle(fontSize: 13, color: c.mutedForeground),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Replace', style: TextStyle(color: c.destructive)),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(accountServiceProvider)
          .deleteAccount(password: _password.text);
      if (mounted) Navigator.pop(context, true);
    } on AccountException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AlertDialog(
      title: const Text('Delete account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This deletes your online account and your activity log. Only '
            'anonymous monthly totals are kept. Your tasks, events and alarms '
            'stay on this device. This cannot be undone.',
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _password,
            hint: 'Password',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _delete(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            FormMessage(_error!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _delete,
          child: Text('Delete', style: TextStyle(color: c.destructive)),
        ),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.account, this.onChangePicture});

  final Account? account;
  final VoidCallback? onChangePicture;

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
    final picture = user?.imagePath;
    final hasPicture = picture != null && File(picture).existsSync();

    final avatar = Container(
      width: 88,
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user == null ? c.muted : null,
        gradient: user == null || hasPicture
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
          : hasPicture
              ? Image.file(File(picture), fit: BoxFit.cover, width: 88, height: 88)
              : Text(
                  _initials(user.displayName),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: c.primaryForeground,
                  ),
                ),
    );

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Semantics(
              label: user == null ? 'No profile picture' : 'Profile picture',
              child: avatar,
            ),
            if (onChangePicture != null)
              Positioned(
                right: -4,
                bottom: -4,
                child: Semantics(
                  button: true,
                  label: 'Change profile picture',
                  child: Material(
                    color: c.primary,
                    shape: CircleBorder(side: BorderSide(color: c.card, width: 2)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onChangePicture,
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(Icons.photo_camera_outlined,
                            size: 18, color: c.primaryForeground),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user?.displayName ?? 'Not signed in',
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
