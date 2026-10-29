import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cloud/activity_actions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../shared/widgets/screen_header.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'log_widgets.dart';

/// Profile section shown only to admins: headline numbers, the latest
/// entries and the admin tools.
class AdminCard extends ConsumerStatefulWidget {
  const AdminCard({super.key});

  @override
  ConsumerState<AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends ConsumerState<AdminCard> {
  bool _purging = false;

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _purge() async {
    final ok = await _confirm(
      title: 'Delete old entries?',
      body: 'Every activity entry older than 12 months is deleted for all '
          'users. Anonymous monthly totals are not affected.',
      action: 'Delete',
    );
    if (!ok) return;
    setState(() => _purging = true);
    try {
      final count = await ref.read(adminRepositoryProvider)?.purgeOld() ?? 0;
      ref
        ..invalidate(adminSummaryProvider)
        ..invalidate(latestLogsProvider);
      if (mounted) {
        _show(count == 0
            ? 'Nothing older than 12 months.'
            : 'Deleted $count old ${count == 1 ? 'entry' : 'entries'}.');
      }
    } on AdminException catch (e) {
      if (mounted) _show(e.message);
    } finally {
      if (mounted) setState(() => _purging = false);
    }
  }

  Future<void> _claim() async {
    final ok = await _confirm(
      title: 'Claim superadmin role?',
      body: 'The current superadmin has been inactive for more than '
          '${superadminInactivityLimit.inDays} days. You will become the '
          'superadmin and they will lose admin access.',
      action: 'Claim',
    );
    if (!ok) return;
    try {
      await ref.read(adminRepositoryProvider)?.claimSuperadmin();
      ref.invalidate(adminStatusProvider);
      if (mounted) _show('You are now the superadmin.');
    } on AdminException catch (e) {
      if (mounted) _show(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(adminStatusProvider).asData?.value;
    if (status == null || !status.isAdmin) return const SizedBox.shrink();

    final c = AppColors.of(context);
    final now = ref.watch(clockProvider)();
    final summary = ref.watch(adminSummaryProvider);
    final latest = ref.watch(latestLogsProvider);

    Widget toolRow(IconData icon, String title, VoidCallback? onTap,
            {String? subtitle, Color? tint, Widget? trailing}) =>
        ListTile(
          leading: Icon(icon, color: tint ?? c.primary),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: trailing ??
              Icon(Icons.chevron_right_rounded, color: c.mutedForeground),
          onTap: onTap,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: SectionLabel('Admin')),
            Text(
              status.isSuperadmin ? 'Superadmin' : 'Admin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        summary.when(
          loading: () => const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Could not load numbers: $error',
              style: TextStyle(color: c.destructive)),
          data: (s) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              _StatTile(
                value: s.signUpsLast7Days,
                label: 'Sign-ups, 7 days',
                onTap: () => context.push(AppRoutes.adminLogs(
                  preset: DatePreset.last7Days,
                  action: ActivityAction.accountCreated,
                )),
              ),
              _StatTile(
                value: s.activeToday,
                label: 'Active today',
                onTap: () => context.push(AppRoutes.adminLogs(
                  preset: DatePreset.today,
                  action: ActivityAction.signIn,
                )),
              ),
              _StatTile(
                value: s.entriesToday,
                label: 'Log entries today',
                onTap: () => context
                    .push(AppRoutes.adminLogs(preset: DatePreset.today)),
              ),
              _StatTile(
                value: s.accountsDeletedThisMonth,
                label: 'Deleted this month',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AdminPanel(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(
              'Latest activity',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.mutedForeground,
              ),
            ),
          ),
          ...latest.when<List<Widget>>(
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text('$error', style: TextStyle(color: c.destructive)),
              ),
            ],
            data: (entries) => entries.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('No entries yet.',
                          style: TextStyle(color: c.mutedForeground)),
                    ),
                  ]
                : [
                    for (final entry in entries)
                      LogEntryTile(
                        entry: entry,
                        onTap: () => showLogEntrySheet(context, entry),
                      ),
                  ],
          ),
          toolRow(Icons.manage_search_rounded, 'Open log viewer',
              () => context.push(AppRoutes.adminLogs())),
          if (status.isSuperadmin)
            toolRow(Icons.group_outlined, 'Manage admins',
                () => context.push(AppRoutes.manageAdmins)),
          if (status.canClaim(now))
            toolRow(
              Icons.workspace_premium_outlined,
              'Claim superadmin role',
              _claim,
              subtitle: 'The superadmin has been inactive for over '
                  '${superadminInactivityLimit.inDays} days',
            ),
          toolRow(
            Icons.auto_delete_outlined,
            'Delete logs older than 12 months',
            _purging ? null : _purge,
            tint: c.destructive,
            trailing: _purging
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ]),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: c.foreground,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: c.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
