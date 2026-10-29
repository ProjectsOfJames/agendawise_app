import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/back_screen_scaffold.dart';
import '../../../shared/widgets/screen_header.dart';
import '../application/account_providers.dart';
import '../data/account_service.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import 'account_widgets.dart';

class EditNameScreen extends ConsumerStatefulWidget {
  const EditNameScreen({super.key});

  @override
  ConsumerState<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends ConsumerState<EditNameScreen> {
  late final _name = TextEditingController(
    text: ref.read(currentAccountProvider)?.displayName ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final problem = validateDisplayName(_name.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountServiceProvider).updateDisplayName(_name.text);
      if (mounted) context.pop();
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackScreenScaffold(
      title: 'Edit name',
      onBack: () => context.pop(),
      bottom: [PrimaryButton(label: 'Save', busy: _busy, onPressed: _save)],
      children: [
        const SectionLabel('Full name'),
        const SizedBox(height: 8),
        AccountField(
          controller: _name,
          hint: 'Full name',
          autofocus: true,
          capitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          FormMessage(_error!),
        ],
        const SizedBox(height: 10),
        const HelpText('Names do not need to be unique.'),
      ],
    );
  }
}

class EditEmailScreen extends ConsumerStatefulWidget {
  const EditEmailScreen({super.key});

  @override
  ConsumerState<EditEmailScreen> createState() => _EditEmailScreenState();
}

class _EditEmailScreenState extends ConsumerState<EditEmailScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final current = ref.read(currentAccountProvider)?.email ?? '';
    final problem = validateEmail(_email.text) ??
        (_email.text.trim().toLowerCase() == current.toLowerCase()
            ? 'This is already your email address'
            : null) ??
        (_password.text.isEmpty ? 'Enter your current password' : null);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountServiceProvider).requestEmailChange(
            newEmail: _email.text,
            password: _password.text,
          );
      if (mounted) setState(() => _sentTo = _email.text.trim());
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentAccountProvider)?.email ?? '';
    return BackScreenScaffold(
      title: 'Edit email',
      onBack: () => context.pop(),
      bottom: [
        PrimaryButton(
          label: 'Send confirmation link',
          busy: _busy,
          onPressed: _send,
        ),
      ],
      children: [
        const SectionLabel('Email'),
        const SizedBox(height: 8),
        HelpText('Current: $current'),
        const SizedBox(height: 10),
        AccountField(
          controller: _email,
          hint: 'New email',
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 10),
        PasswordField(
          controller: _password,
          hint: 'Current password',
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _send(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          FormMessage(_error!),
        ],
        if (_sentTo != null) ...[
          const SizedBox(height: 10),
          FormMessage(
            'We sent a link to $_sentTo. Your email changes once you open it; '
            'you may then need to sign in again.',
            success: true,
          ),
        ],
        const SizedBox(height: 10),
        const HelpText(
          'The new address must be valid and not used by another account.',
        ),
      ],
    );
  }
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final problem = (_current.text.isEmpty ? 'Enter your current password' : null) ??
        validateNewPassword(_new.text, _confirm.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountServiceProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Your password has been changed.')),
      );
      if (mounted) context.pop();
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackScreenScaffold(
      title: 'Change password',
      onBack: () => context.pop(),
      bottom: [
        PrimaryButton(label: 'Save password', busy: _busy, onPressed: _save),
      ],
      children: [
        PasswordField(controller: _current, hint: 'Current password'),
        const SizedBox(height: 10),
        PasswordField(controller: _new, hint: 'New password', newPassword: true),
        const SizedBox(height: 10),
        PasswordField(
          controller: _confirm,
          hint: 'Confirm new password',
          newPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          FormMessage(_error!),
        ],
      ],
    );
  }
}
