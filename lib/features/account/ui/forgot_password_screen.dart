import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/back_screen_scaffold.dart';
import '../data/account_service.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import 'account_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final problem = validateEmail(_email.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountServiceProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AccountException catch (e) {
      // Unknown addresses are reported as sent so the screen cannot be used
      // to find out which emails have accounts.
      if (!mounted) return;
      setState(() {
        if (e.message == messageForAuthCode('user-not-found')) {
          _sent = true;
        } else {
          _error = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackScreenScaffold(
      title: 'Reset password',
      onBack: () => context.pop(),
      children: [
        const HelpText(
          'Enter the email address of your account. We will send a link to '
          'choose a new password.',
        ),
        const SizedBox(height: 12),
        AccountField(
          controller: _email,
          hint: 'Email',
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _send(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          FormMessage(_error!),
        ],
        if (_sent) ...[
          const SizedBox(height: 10),
          const FormMessage(
            'If an account exists for this email, a reset link is on its way. '
            'Check your inbox and spam folder.',
            success: true,
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: _sent ? 'Send again' : 'Send reset link',
          busy: _busy,
          onPressed: _send,
        ),
      ],
    );
  }
}
