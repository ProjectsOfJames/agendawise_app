import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/cloud/activity_actions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/time_text.dart';
import '../domain/admin_models.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "29 Oct 2026, 14:05" in local time; "Pending" while the server time is
/// not yet known.
String formatLogTime(BuildContext context, DateTime? time) {
  if (time == null) return 'Pending';
  final local = time.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}, '
      '${formatTime(context, local)}';
}

IconData iconForGroup(ActivityGroup? group) => switch (group) {
      ActivityGroup.account => Icons.person_outline_rounded,
      ActivityGroup.data => Icons.save_alt_rounded,
      ActivityGroup.usage => Icons.touch_app_outlined,
      ActivityGroup.admin => Icons.admin_panel_settings_outlined,
      null => Icons.help_outline_rounded,
    };

String shortUid(String uid) => uid.length <= 8 ? uid : '${uid.substring(0, 8)}…';

class LogEntryTile extends StatelessWidget {
  const LogEntryTile({
    super.key,
    required this.entry,
    this.showUser = true,
    this.onTap,
  });

  final LogEntry entry;
  final bool showUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final group = ActivityAction.fromWire(entry.action)?.group;
    final tint = entry.success ? c.primary : c.destructive;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconForGroup(group), size: 18, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.success
                        ? entry.actionLabel
                        : '${entry.actionLabel} (failed)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.foreground,
                    ),
                  ),
                  Text(
                    [
                      formatLogTime(context, entry.createdAt),
                      if (showUser) shortUid(entry.uid),
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: c.mutedForeground),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: c.mutedForeground),
          ],
        ),
      ),
    );
  }
}

Future<void> showLogEntrySheet(BuildContext context, LogEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final c = AppColors.of(sheetContext);
      Widget row(String label, String value, {bool copyable = false}) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(label,
                      style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                ),
                Expanded(
                  child: SelectableText(value,
                      style: TextStyle(fontSize: 13, color: c.foreground)),
                ),
                if (copyable)
                  IconButton(
                    tooltip: 'Copy',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: value)),
                  ),
              ],
            ),
          );

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.actionLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.foreground,
                ),
              ),
              const SizedBox(height: 12),
              row('Time', formatLogTime(sheetContext, entry.createdAt)),
              row('Outcome', entry.success ? 'Success' : 'Failure'),
              row('Action', entry.action),
              row('User ID', entry.uid, copyable: true),
              row('App version', entry.appVersion),
              row('Platform', entry.platform),
              row('Entry ID', entry.id, copyable: true),
              const SizedBox(height: 8),
              Text('Details',
                  style: TextStyle(fontSize: 13, color: c.mutedForeground)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: SelectableText(
                  entry.meta.isEmpty
                      ? 'None'
                      : const JsonEncoder.withIndent('  ').convert(entry.meta),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: c.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Bordered card used by the admin screens.
class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key, required this.children});

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.border),
            children[i],
          ],
        ],
      ),
    );
  }
}
