import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/back_screen_scaffold.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../account/ui/account_widgets.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'log_widgets.dart';

/// Superadmin only: add and remove admins, or hand over the superadmin role.
class ManageAdminsScreen extends ConsumerStatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  ConsumerState<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends ConsumerState<ManageAdminsScreen> {
  final _email = TextEditingController();
  bool _adding = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final repo = ref.read(adminRepositoryProvider);
    if (repo == null) return;
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      await repo.addAdmin(_email.text);
      _email.clear();
      ref.invalidate(adminListProvider);
      if (mounted) _show('Admin added.');
    } on AdminException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _remove(AdminInfo admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove admin?'),
        content: Text(
            '${admin.displayName} will no longer see the activity log.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider)?.removeAdmin(admin.uid);
      ref.invalidate(adminListProvider);
      if (mounted) _show('Admin removed.');
    } on AdminException catch (e) {
      if (mounted) _show(e.message);
    }
  }

  Future<void> _transfer(AdminInfo admin) async {
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => _TransferDialog(target: admin),
    );
    if (done != true || !mounted) return;
    ref.invalidate(adminStatusProvider);
    _show('${admin.displayName} is now the superadmin.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final admins = ref.watch(adminListProvider);

    return BackScreenScaffold(
      title: 'Manage admins',
      onBack: () => context.pop(),
      children: [
        Text(
          'Admins can view, export and clean up the activity log. Only you '
          'can add or remove them.',
          style: TextStyle(fontSize: 13, color: c.mutedForeground),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Add admin'),
        const SizedBox(height: 10),
        AccountField(
          controller: _email,
          hint: 'Exact email of an existing account',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _add(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          FormMessage(_error!),
        ],
        const SizedBox(height: 10),
        PrimaryButton(label: 'Add admin', busy: _adding, onPressed: _add),
        const SizedBox(height: 24),
        const SectionLabel('Current admins'),
        const SizedBox(height: 10),
        admins.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) =>
              Text('$error', style: TextStyle(color: c.destructive)),
          data: (list) => list.isEmpty
              ? Text('No other admins yet.',
                  style: TextStyle(color: c.mutedForeground))
              : AdminPanel(children: [
                  for (final admin in list)
                    ListTile(
                      title: Text(admin.displayName),
                      subtitle: Text(
                          admin.email.isEmpty ? shortUid(admin.uid) : admin.email),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Admin options',
                        onSelected: (choice) => choice == 'remove'
                            ? _remove(admin)
                            : _transfer(admin),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'transfer',
                              child: Text('Make superadmin')),
                          PopupMenuItem(
                              value: 'remove', child: Text('Remove admin')),
                        ],
                      ),
                    ),
                ]),
        ),
        const SizedBox(height: 16),
        Text(
          'To hand over the superadmin role, choose "Make superadmin" next to '
          'an admin. You become an ordinary user afterwards unless they add '
          'you back.',
          style: TextStyle(fontSize: 12, color: c.mutedForeground),
        ),
      ],
    );
  }
}

class _TransferDialog extends ConsumerStatefulWidget {
  const _TransferDialog({required this.target});

  final AdminInfo target;

  @override
  ConsumerState<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<_TransferDialog> {
  final _password = TextEditingController();
  bool _confirmed = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(adminRepositoryProvider)?.transferSuperadmin(
            targetUid: widget.target.uid,
            password: _password.text,
          );
      if (mounted) Navigator.pop(context, true);
    } on AdminException catch (e) {
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
    return AlertDialog(
      title: const Text('Transfer superadmin?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.target.displayName} becomes the superadmin. You lose '
            'access to the admin tools unless they add you back.',
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _password,
            hint: 'Your password',
            textInputAction: TextInputAction.done,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            title: const Text('I understand this cannot be undone by me'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_error != null) FormMessage(_error!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy || !_confirmed ? null : _submit,
          child: const Text('Transfer'),
        ),
      ],
    );
  }
}
