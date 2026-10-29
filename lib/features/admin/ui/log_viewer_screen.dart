import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cloud/activity_actions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/back_screen_scaffold.dart';
import '../../account/application/account_providers.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'log_widgets.dart';

/// Browses the cloud activity log. Admins see every user's entries and can
/// export them; with [ownOnly] the list is limited to the signed-in user.
class LogViewerScreen extends ConsumerStatefulWidget {
  const LogViewerScreen({
    super.key,
    this.initial = const LogFilter(),
    this.ownOnly = false,
  });

  final LogFilter initial;
  final bool ownOnly;

  @override
  ConsumerState<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends ConsumerState<LogViewerScreen> {
  final _userText = TextEditingController();
  late LogFilter _filter = widget.initial;
  final _entries = <LogEntry>[];
  Object? _cursor;
  bool _hasMore = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _userText.text = widget.initial.userQuery ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _userText.dispose();
    super.dispose();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// The filter actually sent; own-activity mode always pins the user.
  LogFilter? _effectiveFilter() {
    if (!widget.ownOnly) return _filter;
    final uid = ref.read(currentAccountProvider)?.uid;
    if (uid == null) return null;
    return _filter.copyWith(uids: {uid});
  }

  Future<void> _reload() async {
    setState(() {
      _entries.clear();
      _cursor = null;
      _hasMore = false;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    final repo = ref.read(adminRepositoryProvider);
    final filter = _effectiveFilter();
    if (repo == null || filter == null) {
      setState(() => _error = 'Sign in and connect to the internet to view activity.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await repo.page(filter, after: _cursor);
      if (!mounted) return;
      setState(() {
        _entries.addAll(page.entries);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } on AdminException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(LogFilter filter) {
    setState(() => _filter = filter);
    _reload();
  }

  Future<void> _searchUser() async {
    final text = _userText.text.trim();
    if (text.isEmpty) {
      _apply(_filter.copyWith(clearUser: true));
      return;
    }
    final repo = ref.read(adminRepositoryProvider);
    if (repo == null) return;
    try {
      final uids = await repo.findUsers(text);
      if (!mounted) return;
      if (uids.isEmpty) {
        _show('No account matches "$text". Use the full email or exact name.');
        return;
      }
      _apply(_filter.copyWith(uids: uids, userQuery: text));
    } on Object {
      if (mounted) _show('Could not look up that user.');
    }
  }

  Future<void> _pickActions() async {
    final picked = await showModalBottomSheet<Set<ActivityAction>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ActionPicker(initial: _filter.actions),
    );
    if (picked != null) _apply(_filter.copyWith(actions: picked));
  }

  Future<void> _export() async {
    final filter = _effectiveFilter();
    if (filter == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExportSheet(filter: filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final actionsLabel = _filter.actions.isEmpty
        ? 'All actions'
        : _filter.actions.length == 1
            ? _filter.actions.single.label
            : '${_filter.actions.length} actions';

    return BackScreenScaffold(
      title: widget.ownOnly ? 'My activity' : 'Activity log',
      onBack: () => context.pop(),
      bottom: [
        if (!widget.ownOnly)
          OutlinedButton.icon(
            onPressed: _entries.isEmpty ? null : _export,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Export filtered results'),
          ),
      ],
      children: [
        if (widget.ownOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'What your account has recorded online. Entries never include '
              'the content of your tasks, events or alarms.',
              style: TextStyle(fontSize: 13, color: c.mutedForeground),
            ),
          )
        else ...[
          TextField(
            controller: _userText,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _searchUser(),
            decoration: InputDecoration(
              hintText: 'User email or exact name',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _filter.uids.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear user',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _userText.clear();
                        _apply(_filter.copyWith(clearUser: true));
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in DatePreset.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(preset.label),
                    selected: _filter.datePreset == preset,
                    onSelected: (_) =>
                        _apply(_filter.copyWith(datePreset: preset)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickActions,
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: Text(actionsLabel, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<OutcomeFilter>(
              initialValue: _filter.outcome,
              onSelected: (o) => _apply(_filter.copyWith(outcome: o)),
              itemBuilder: (_) => [
                for (final o in OutcomeFilter.values)
                  PopupMenuItem(value: o, child: Text(o.label)),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_filter.outcome.label,
                        style: TextStyle(fontSize: 13, color: c.foreground)),
                    Icon(Icons.arrow_drop_down_rounded, color: c.foreground),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(color: c.destructive)),
          ),
        if (_entries.isEmpty && !_loading && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No entries match these filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.mutedForeground),
            ),
          ),
        if (_entries.isNotEmpty)
          AdminPanel(children: [
            for (final entry in _entries)
              LogEntryTile(
                entry: entry,
                showUser: !widget.ownOnly,
                onTap: () => showLogEntrySheet(context, entry),
              ),
          ]),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_hasMore)
          TextButton(
            onPressed: _loadMore,
            child: const Text('Load more'),
          ),
      ],
    );
  }
}

class _ActionPicker extends StatefulWidget {
  const _ActionPicker({required this.initial});

  final Set<ActivityAction> initial;

  @override
  State<_ActionPicker> createState() => _ActionPickerState();
}

class _ActionPickerState extends State<_ActionPicker> {
  late final Set<ActivityAction> _selected = {...widget.initial};

  bool get _full => _selected.length >= maxActionFilters;

  void _toggle(ActivityAction action, bool on) {
    setState(() {
      if (!on) {
        _selected.remove(action);
      } else if (!_full) {
        _selected.add(action);
      }
    });
  }

  void _toggleGroup(ActivityGroup group) {
    final members = ActivityAction.values.where((a) => a.group == group);
    setState(() {
      if (members.every(_selected.contains)) {
        _selected.removeAll(members);
      } else {
        for (final a in members) {
          if (_full) break;
          _selected.add(a);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter by action (up to $maxActionFilters)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.foreground,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final group in ActivityGroup.values) ...[
                    ListTile(
                      dense: true,
                      title: Text(
                        group.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: c.mutedForeground,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => _toggleGroup(group),
                        child: const Text('Group'),
                      ),
                    ),
                    for (final action in ActivityAction.values
                        .where((a) => a.group == group))
                      CheckboxListTile(
                        dense: true,
                        value: _selected.contains(action),
                        onChanged: !_selected.contains(action) && _full
                            ? null
                            : (on) => _toggle(action, on ?? false),
                        title: Text(action.label),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text(_selected.isEmpty
                      ? 'Show all actions'
                      : 'Apply (${_selected.length})'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet({required this.filter});

  final LogFilter filter;

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  ExportFormat _format = ExportFormat.csv;
  bool _includeEmails = false;
  bool _busy = false;
  String? _error;

  Future<void> _run() async {
    final repo = ref.read(adminRepositoryProvider);
    if (repo == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.export(
        widget.filter,
        format: _format,
        includeEmails: _includeEmails,
      );
      if (mounted) Navigator.pop(context);
    } on AdminException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object catch (e) {
      if (mounted) setState(() => _error = 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Export activity log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Exports the entries matching the current filters, up to '
              '$exportRowCap rows.',
              style: TextStyle(fontSize: 13, color: c.mutedForeground),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ExportFormat>(
              segments: const [
                ButtonSegment(value: ExportFormat.csv, label: Text('CSV')),
                ButtonSegment(value: ExportFormat.json, label: Text('JSON')),
              ],
              selected: {_format},
              onSelectionChanged:
                  _busy ? null : (s) => setState(() => _format = s.single),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include emails'),
              subtitle: const Text('Off by default; user IDs are always included'),
              value: _includeEmails,
              onChanged:
                  _busy ? null : (v) => setState(() => _includeEmails = v),
            ),
            if (_includeEmails)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.priorityMedium.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Text(
                  'The file will contain personal data. Share it only with '
                  'people who need it and delete it when you are done.',
                  style: TextStyle(fontSize: 13, color: c.foreground),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: c.destructive)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _run,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: Text(_busy ? 'Preparing…' : 'Export and share'),
            ),
          ],
        ),
      ),
    );
  }
}
