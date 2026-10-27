import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/task_priority.dart';
import '../../../core/errors/validation_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/colour_hex.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared/widgets/form_screen_scaffold.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../categories/application/category_providers.dart';
import '../application/task_controller.dart';
import 'priority_style.dart';

/// Creates a task when [taskId] is null, otherwise edits that task.
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, this.taskId});

  final String? taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueAt;
  bool _isAllDay = false;
  String? _categoryId;

  bool _loading = true;
  bool _missing = false;
  bool _saving = false;
  String? _titleError;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.taskId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final loaded = await ref.read(taskControllerProvider).load(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (loaded == null) {
        _missing = true;
        return;
      }
      final task = loaded.task;
      _titleController.text = task.title;
      _noteController.text = loaded.note?.body ?? '';
      _priority = task.priority;
      _dueAt = task.dueAt;
      _isAllDay = task.isAllDay;
      _categoryId = task.categoryId;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _close() => context.pop();

  Future<void> _pickDue() async {
    final now = ref.read(clockProvider)();
    final initial = _dueAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      helpText: 'Due date',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _dueAt != null && !_isAllDay
          ? TimeOfDay.fromDateTime(_dueAt!)
          : const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Due time (cancel for all day)',
    );
    if (!mounted) return;
    setState(() {
      if (time == null) {
        _dueAt = DateTime(date.year, date.month, date.day);
        _isAllDay = true;
      } else {
        _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        _isAllDay = false;
      }
    });
  }

  Future<void> _pickCategory(List<TaskCategory> categories) async {
    final picked = await showModalBottomSheet<_CategoryChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.block, size: 18),
              title: const Text('None'),
              selected: _categoryId == null,
              onTap: () => Navigator.pop(sheetContext, const _CategoryChoice(null)),
            ),
            for (final category in categories)
              ListTile(
                leading: CircleAvatar(
                  radius: 6,
                  backgroundColor: ColourHex.decode(category.colour),
                ),
                title: Text(category.name),
                selected: _categoryId == category.id,
                onTap: () =>
                    Navigator.pop(sheetContext, _CategoryChoice(category.id)),
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, size: 18),
              title: const Text('Manage categories'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.categories);
              },
            ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _categoryId = picked.id);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = 'A title is required');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(taskControllerProvider).save(
            TaskForm(
              title: _titleController.text,
              priority: _priority,
              dueAt: _dueAt,
              isAllDay: _isAllDay,
              categoryId: _categoryId,
              note: _noteController.text,
            ),
            id: widget.taskId,
          );
      if (mounted) _close();
    } on ValidationException catch (e) {
      if (mounted) setState(() => _titleError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.taskId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('The task and its notes will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.of(dialogContext).destructive,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(taskControllerProvider).delete(id);
    if (mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_loading || _missing) {
      return FormScreenScaffold(
        title: 'Task',
        onClose: _close,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(
                      'This task no longer exists.',
                      style: TextStyle(color: c.mutedForeground),
                    ),
            ),
          ),
        ],
      );
    }

    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    TaskCategory? category;
    for (final item in categories) {
      if (item.id == _categoryId) category = item;
    }
    final now = ref.watch(clockProvider)();

    return FormScreenScaffold(
      title: 'Task',
      onClose: _close,
      bottom: [
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
            child: const Text('Save task',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _saving ? null : _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.destructive,
                side: BorderSide(color: c.destructive),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
              ),
              child: const Text('Delete task',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
      children: [
        TextField(
          controller: _titleController,
          autofocus: !_isEditing,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
          decoration: InputDecoration(
            hintText: 'Task title',
            errorText: _titleError,
            filled: true,
            fillColor: c.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide(color: c.border),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Priority'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final priority in TaskPriority.values)
              _PriorityChip(
                priority: priority,
                selected: priority == _priority,
                onTap: () => setState(() => _priority = priority),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _RowCard(
          label: 'Due date and time',
          value: _dueAt == null
              ? 'Optional'
              : dueLabel(_dueAt!, allDay: _isAllDay, now: now),
          onTap: _pickDue,
          trailing: _dueAt == null
              ? null
              : IconButton(
                  tooltip: 'Clear due date',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() {
                    _dueAt = null;
                    _isAllDay = false;
                  }),
                ),
        ),
        const SizedBox(height: 10),
        _RowCard(
          label: 'Category',
          value: category?.name ?? 'None',
          leadingDot:
              category == null ? null : ColourHex.decode(category.colour),
          onTap: () => _pickCategory(categories),
          trailing: TextButton(
            onPressed: () => context.push(AppRoutes.categories),
            child: const Text('Manage'),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _noteController,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Notes',
            filled: true,
            fillColor: c.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide(color: c.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChoice {
  const _CategoryChoice(this.id);

  final String? id;
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final colour = priorityColour(priority, c);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: colour, width: 1.5),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: '${priorityName(priority)} priority',
      child: Material(
        color: selected ? colour : c.card,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  priorityName(priority),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? c.primaryForeground
                        : c.foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
    this.leadingDot,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? leadingDot;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final mutedFg = c.mutedForeground;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: trailing == null ? 16 : 4),
            child: Row(
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.foreground,
                    )),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (leadingDot != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: leadingDot,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 13, color: mutedFg),
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
