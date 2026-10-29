import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/back_screen_scaffold.dart';
import '../domain/account_rules.dart';

class PrivacyNoticeScreen extends StatelessWidget {
  const PrivacyNoticeScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'Who is responsible',
      'AgendaWise is a student project. The developer is responsible for the '
          'personal information described here and can be contacted through '
          'the details provided with the app.',
    ),
    (
      'What stays on your device',
      'Tasks, notes, calendar events, alarms, challenge results, voice input '
          'and your profile picture are stored only on this phone. They are '
          'never uploaded.',
    ),
    (
      'What is kept online and why',
      'If you create an account we keep your display name, email address, '
          'the date you signed up, the date you last opened the app, your '
          'confirmation that you are 18 or older and the version of this '
          'notice you accepted. These are needed to sign you in and to manage '
          'accounts.\n\nWe also keep a log of account actions (for example '
          'sign-in, sign-out, password changes and backups) with the time, '
          'app version and platform. If you choose to share anonymous usage, '
          'the log also records that features were used, such as an alarm '
          'being stopped or a task being completed, never what they contain.',
    ),
    (
      'Where it is stored',
      'Account records and the activity log are stored by Google Firebase in '
          'Johannesburg, South Africa. Sign-in itself is handled by Firebase '
          'Authentication, which may process your email address and password '
          'outside South Africa under Google\'s data processing terms. Your '
          'password is never visible to the developer.',
    ),
    (
      'Who can see it',
      'You can see your own account details. A small number of '
          'administrators can view the activity log to look after the app; '
          'they cannot see anything stored on your device.',
    ),
    (
      'How long it is kept',
      'Activity log entries are deleted after 12 months. When you delete '
          'your account, your account record and all your log entries are '
          'deleted; only anonymous monthly totals that cannot identify you '
          'are kept.',
    ),
    (
      'Your choices',
      'You can use the app without an account, turn usage sharing on or off '
          'on your profile, change your name, email and password, and delete '
          'your account at any time. Accounts are for people aged 18 or older.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return BackScreenScaffold(
      title: 'Privacy notice',
      onBack: () => context.pop(),
      children: [
        Text('Version $privacyNoticeVersion',
            style: TextStyle(fontSize: 12, color: c.mutedForeground)),
        const SizedBox(height: 12),
        for (final (heading, body) in _sections) ...[
          Text(
            heading,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(fontSize: 14, color: c.foreground)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
