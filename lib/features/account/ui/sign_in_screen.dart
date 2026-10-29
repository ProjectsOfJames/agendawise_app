import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/back_screen_scaffold.dart';
import '../data/account_service.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import 'account_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final emailProblem = validateEmail(_email.text);
    if (emailProblem != null || _password.text.isEmpty) {
      setState(() => _error = emailProblem ?? 'Enter your password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(accountServiceProvider)
          .signIn(email: _email.text, password: _password.text);
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
      title: 'Sign in',
      onBack: () => context.pop(),
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountField(
                controller: _email,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 10),
              PasswordField(
                controller: _password,
                hint: 'Password',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          FormMessage(_error!),
        ],
        const SizedBox(height: 16),
        PrimaryButton(label: 'Sign in', busy: _busy, onPressed: _signIn),
        const SizedBox(height: 10),
        SecondaryButton(
          label: 'Create account',
          onPressed: () => context.pushReplacement(AppRoutes.createAccount),
        ),
        const SizedBox(height: 4),
        Align(
          child: TextButton(
            onPressed: () => context.push(AppRoutes.forgotPassword),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 8),
        const HelpText(
          'Signing in needs an internet connection. Your tasks, events and '
          'alarms always stay on this device.',
        ),
      ],
    );
  }
}
