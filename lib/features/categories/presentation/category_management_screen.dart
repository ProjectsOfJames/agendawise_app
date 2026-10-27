import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/validation_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/colour_hex.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../application/category_providers.dart';
import '../data/category_repository.dart';
import 'category_palette.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Next unused palette colour, cycling once all are taken.
  Color _nextColour(List<TaskCategory> existing) {
    final used = existing.map((c) => c.colour.toUpperCase()).toSet();
    for (final colour in categoryPalette) {
      if (!used.contains(ColourHex.encode(colour))) return colour;
    }
    return categoryPalette[
        existing.length % categoryPalette.length];
  }

  Future<void> _add(List<TaskCategory> existing) async {
    final name = _nameController.text;
    if (name.trim().isEmpty) return;
    try {
      await ref.read(categoryRepositoryProvider).create(
            name: name,
            colour: ColourHex.encode(_nextColour(existing)),
          );
      if (!mounted) return;
      _nameController.clear();
      setState(() => _error = null);
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _edit(TaskCategory category) async {
    final result = await showDialog<_CategoryEdit>(
      context: context,
      builder: (_) => _EditCategoryDialog(category: category),
    );
    if (result == null || !mounted) return;
    try {
      await ref.read(categoryRepositoryProvider).update(
            category.id,
            name: result.name,
            colour: ColourHex.encode(result.colour),
          );
    } on ValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(TaskCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: const Text('Its tasks will be kept and become uncategorised.'),
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
    if (confirmed == true) {
      await ref.read(categoryRepositoryProvider).delete(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final mutedFg = c.mutedForeground;
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.asData?.value ?? const <TaskCategory>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 4),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    semanticLabel: 'Back',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  const SectionLabel('Categories'),
                ],
              ),
            ),
            Expanded(
              child: categoriesAsync.isLoading && categories.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : categories.isEmpty
                      ? Center(
                          child: Text(
                            'No categories yet.',
                            style: TextStyle(fontSize: 14, color: mutedFg),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: categories.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final category = categories[index];
                            return _CategoryRow(
                              category: category,
                              onEdit: () => _edit(category),
                              onDelete: () => _delete(category),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _add(categories),
                          onChanged: (_) {
                            if (_error != null) setState(() => _error = null);
                          },
                          decoration: InputDecoration(
                            hintText: 'New category name',
                            errorText: _error,
                            filled: true,
                            fillColor: c.inputBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Semantics(
                        button: true,
                        label: 'Add category',
                        child: Material(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: InkWell(
                            onTap: () => _add(categories),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: Icon(
                                Icons.add_rounded,
                                color: c.primaryForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Names must be unique. Deleting a category leaves its '
                    'tasks uncategorised.',
                    style: TextStyle(fontSize: 12, color: mutedFg),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final mutedFg = c.mutedForeground;
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColourHex.decode(category.colour),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              category.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.foreground,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit ${category.name}',
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, size: 18, color: mutedFg),
          ),
          IconButton(
            tooltip: 'Delete ${category.name}',
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: 18, color: mutedFg),
          ),
        ],
      ),
    );
  }
}

class _CategoryEdit {
  const _CategoryEdit(this.name, this.colour);

  final String name;
  final Color colour;
}

class _EditCategoryDialog extends StatefulWidget {
  const _EditCategoryDialog({required this.category});

  final TaskCategory category;

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  late final _controller = TextEditingController(text: widget.category.name);
  late Color _colour = ColourHex.decode(widget.category.colour);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    Navigator.pop(context, _CategoryEdit(_controller.text, _colour));
  }

  @override
  Widget build(BuildContext context) {
    final swatches = [
      ...categoryPalette,
      if (!categoryPalette
          .any((c) => ColourHex.encode(c) == ColourHex.encode(_colour)))
        _colour,
    ];
    return AlertDialog(
      title: const Text('Edit category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(hintText: 'Name'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final colour in swatches)
                Semantics(
                  button: true,
                  selected:
                      ColourHex.encode(colour) == ColourHex.encode(_colour),
                  label: 'Colour ${ColourHex.encode(colour)}',
                  child: InkResponse(
                    onTap: () => setState(() => _colour = colour),
                    radius: 22,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colour,
                          ),
                          child: ColourHex.encode(colour) ==
                                  ColourHex.encode(_colour)
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
