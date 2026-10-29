import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/back_screen_scaffold.dart';
import '../../../shared/widgets/screen_header.dart';
import '../data/account_service.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import 'account_widgets.dart';

/// Two steps: account details, then the privacy notice with the age
/// confirmation, consent and optional usage sharing.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _consentStep = false;
  bool _ageConfirmed = false;
  bool _consentAccepted = false;
  bool _usageOptIn = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _continue() {
    final problem = validateDisplayName(_name.text) ??
        validateEmail(_email.text) ??
        validateNewPassword(_password.text, _confirm.text);
    setState(() {
      _error = problem;
      if (problem == null) _consentStep = true;
    });
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountServiceProvider).signUp(SignUpRequest(
            displayName: _name.text,
            email: _email.text,
            password: _password.text,
            ageConfirmed: _ageConfirmed,
            consentAccepted: _consentAccepted,
            usageOptIn: _usageOptIn,
          ));
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
      title: 'Create account',
      onBack: () {
        if (_consentStep) {
          setState(() {
            _consentStep = false;
            _error = null;
          });
        } else {
          context.pop();
        }
      },
      children: _consentStep ? _consentChildren(context) : _detailChildren(),
    );
  }

  List<Widget> _detailChildren() => [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountField(
                controller: _name,
                hint: 'Full name',
                capitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 10),
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
                newPassword: true,
              ),
              const SizedBox(height: 10),
              PasswordField(
                controller: _confirm,
                hint: 'Confirm password',
                newPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continue(),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          FormMessage(_error!),
        ],
        const SizedBox(height: 16),
        PrimaryButton(label: 'Continue', onPressed: _continue),
        const SizedBox(height: 10),
        SecondaryButton(
          label: 'I already have an account',
          onPressed: () => context.pushReplacement(AppRoutes.signIn),
        ),
        const SizedBox(height: 12),
        const HelpText(
          'Your name, email and sign-in details are kept online by Firebase. '
          'Tasks, events, alarms and your photo never leave this device. '
          'Passwords must match and be at least 8 characters.',
        ),
      ];

  List<Widget> _consentChildren(BuildContext context) {
    final c = AppColors.of(context);
    return [
      const SectionLabel('Before you continue'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in privacySummary)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Icon(Icons.circle, size: 6, color: c.primary),
                    ),
                    Expanded(
                      child: Text(line,
                          style: TextStyle(fontSize: 14, color: c.foreground)),
                    ),
                  ],
                ),
              ),
            TextButton(
              onPressed: () => context.push(AppRoutes.privacyNotice),
              child: const Text('Read the full privacy notice'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      CheckboxListTile(
        value: _ageConfirmed,
        onChanged: (value) => setState(() => _ageConfirmed = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: const Text('I am 18 years or older'),
      ),
      CheckboxListTile(
        value: _consentAccepted,
        onChanged: (value) => setState(() => _consentAccepted = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: const Text('I have read and accept the privacy notice'),
      ),
      SwitchListTile(
        value: _usageOptIn,
        onChanged: (value) => setState(() => _usageOptIn = value),
        contentPadding: EdgeInsets.zero,
        title: const Text('Share anonymous usage (optional)'),
        subtitle: const Text(
          'Records that features such as alarms or tasks were used, never '
          'their content. You can change this later on your profile.',
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        FormMessage(_error!),
      ],
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Create account',
        busy: _busy,
        onPressed: _ageConfirmed && _consentAccepted ? _create : null,
      ),
      const SizedBox(height: 8),
      const HelpText('Creating an account needs an internet connection.'),
    ];
  }
}

/// Short version of the privacy notice shown before sign-up.
const privacySummary = [
  'An account is optional. The app works fully without one.',
  'Online we keep your name, email, sign-up date, the date you last opened '
      'the app and your consent choices.',
  'We also keep a log of account actions such as sign-ins and backups, '
      'without any of your content, for up to 12 months.',
  'Your tasks, notes, events, alarms, voice input and photo stay on this '
      'device.',
  'Data is stored in Johannesburg; sign-in is handled by Google Firebase, '
      'which may process it outside South Africa.',
  'You can delete your account at any time from your profile.',
];
