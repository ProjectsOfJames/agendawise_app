import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/task_priority.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/colour_hex.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../categories/application/category_providers.dart';
import '../../tasks/application/task_controller.dart';
import '../../tasks/application/task_providers.dart';
import '../../tasks/presentation/priority_style.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _controller = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(taskControllerProvider).quickAdd(text, _priority);
  }

  // Cycles medium → high → low
  void _cyclePriority() => setState(() {
        const order = [TaskPriority.medium, TaskPriority.high, TaskPriority.low];
        _priority = order[(order.indexOf(_priority) + 1) % order.length];
      });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final openAsync = ref.watch(openTasksProvider);
    final doneAsync = ref.watch(completedTasksProvider);
    final open = openAsync.asData?.value ?? const <Task>[];
    final done = doneAsync.asData?.value ?? const <Task>[];
    final loading = openAsync.isLoading || doneAsync.isLoading;
    final error = openAsync.hasError ? openAsync.error : doneAsync.error;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const ScreenHeader(label: 'To-Do'),
          const SizedBox(height: 16),
          ScreenTitle(
            eyebrow: 'Today',
            title: 'My Tasks',
            subtitle: '${open.length} remaining · ${done.length} done',
          ),
          const SizedBox(height: 16),
          _QuickAddRow(
            controller: _controller,
            priority: _priority,
            onCyclePriority: _cyclePriority,
            onAdd: _addTask,
          ),
          const SizedBox(height: 16),
          if (error != null)
            Text('Could not load tasks: $error',
                style: TextStyle(color: c.destructive))
          else if (loading && open.isEmpty && done.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (open.isEmpty && done.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: PlaceholderNote('No tasks yet. Add one above.'),
            ),
          for (final task in open)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskItem(task: task),
            ),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 14),
            const SectionLabel('Completed'),
            const SizedBox(height: 10),
            for (final task in done)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskItem(task: task),
              ),
          ],
        ],
      ),
    );
  }
}

class _QuickAddRow extends StatelessWidget {
  const _QuickAddRow({
    required this.controller,
    required this.priority,
    required this.onCyclePriority,
    required this.onAdd,
  });

  final TextEditingController controller;
  final TaskPriority priority;
  final VoidCallback onCyclePriority;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Priority ${priorityName(priority)}, tap to change',
                  child: InkResponse(
                    onTap: onCyclePriority,
                    radius: 20,
                    child: SizedBox(
                      width: 40,
                      height: 52,
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: priorityColour(priority, c),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => onAdd(),
                    style: TextStyle(fontSize: 15, color: c.foreground),
                    decoration: InputDecoration(
                      hintText: 'Add a task...',
                      hintStyle:
                          TextStyle(fontSize: 15, color: c.mutedForeground),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add task with details',
                  onPressed: () => context.push(AppRoutes.newTask),
                  icon: Icon(Icons.tune_rounded,
                      size: 18, color: c.mutedForeground),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'Add task',
          child: Material(
            color: c.primary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.add_rounded, color: c.primaryForeground),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskItem extends ConsumerWidget {
  const _TaskItem({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final controller = ref.read(taskControllerProvider);
    final category = task.categoryId == null
        ? null
        : ref.watch(categoriesByIdProvider)[task.categoryId];
    final now = ref.watch(clockProvider)();

    final barColour =
        task.isDone ? c.success : priorityColour(task.priority, c);
    final dueAt = task.dueAt;
    final overdue = !task.isDone &&
        dueAt != null &&
        (task.isAllDay
            ? dateOnly(dueAt).isBefore(dateOnly(now))
            : dueAt.isBefore(now));

    final details = <Widget>[
      if (dueAt != null)
        Text(
          dueLabel(dueAt, allDay: task.isAllDay, now: now),
          style: TextStyle(
            fontSize: 12,
            color: overdue ? c.destructive : c.mutedForeground,
          ),
        ),
      if (category != null) ...[
        if (dueAt != null) const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColourHex.decode(category.colour),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            category.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: c.mutedForeground),
          ),
        ),
      ],
    ];

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: BorderSide(color: c.border),
    );

    return AnimatedOpacity(
      opacity: task.isDone ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: c.card,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => context.push(AppRoutes.task(task.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 32,
                  decoration: BoxDecoration(
                    color: barColour,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Semantics(
                  checked: task.isDone,
                  child: IconButton(
                    tooltip: task.isDone ? 'Mark as not done' : 'Mark as done',
                    onPressed: () => controller.setDone(task, !task.isDone),
                    icon: Icon(
                      task.isDone
                          ? Icons.check_rounded
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: task.isDone ? c.success : c.mutedForeground,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            color: c.foreground,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: c.foreground,
                          ),
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(children: details),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete task',
                  onPressed: () => _delete(context, controller),
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 20, color: c.mutedForeground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, TaskController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    await controller.delete(task.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Deleted "${task.title}"')));
  }
}
