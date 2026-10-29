/// Groups used to filter the activity log.
enum ActivityGroup {
  account('Account'),
  data('Data'),
  usage('Usage'),
  admin('Admin');

  const ActivityGroup(this.label);

  final String label;
}

/// Every action that can appear in the cloud activity log. Usage actions
/// are only recorded for users who opted in; the rest are always recorded
/// while signed in. Entries never contain task, event, alarm or voice
/// content.
enum ActivityAction {
  accountCreated('account_created', 'Account created', ActivityGroup.account),
  consentAccepted('consent_accepted', 'Consent accepted', ActivityGroup.account),
  signIn('sign_in', 'Signed in', ActivityGroup.account),
  signOut('sign_out', 'Signed out', ActivityGroup.account),
  passwordChanged('password_changed', 'Password changed', ActivityGroup.account),
  passwordResetRequested(
      'password_reset_requested', 'Password reset requested', ActivityGroup.account),
  emailChanged('email_changed', 'Email change requested', ActivityGroup.account),
  backupExported('backup_exported', 'Backup exported', ActivityGroup.data),
  backupImported('backup_imported', 'Backup imported', ActivityGroup.data),
  alarmCreated('alarm_created', 'Alarm created', ActivityGroup.usage),
  alarmDismissed('alarm_dismissed', 'Alarm dismissed', ActivityGroup.usage),
  alarmSnoozed('alarm_snoozed', 'Alarm snoozed', ActivityGroup.usage),
  challengeCompleted(
      'challenge_completed', 'Challenge completed', ActivityGroup.usage),
  taskCreated('task_created', 'Task created', ActivityGroup.usage),
  taskCompleted('task_completed', 'Task completed', ActivityGroup.usage),
  eventCreated('event_created', 'Event created', ActivityGroup.usage),
  voiceUsed('voice_used', 'Voice input used', ActivityGroup.usage),
  adminLogsExported('admin_logs_exported', 'Logs exported', ActivityGroup.admin),
  adminLogsPurged('admin_logs_purged', 'Old logs deleted', ActivityGroup.admin),
  adminAdded('admin_added', 'Admin added', ActivityGroup.admin),
  adminRemoved('admin_removed', 'Admin removed', ActivityGroup.admin),
  superadminTransferred(
      'superadmin_transferred', 'Superadmin transferred', ActivityGroup.admin),
  superadminClaimed(
      'superadmin_claimed', 'Superadmin claimed', ActivityGroup.admin);

  const ActivityAction(this.wire, this.label, this.group);

  /// Value stored in Firestore.
  final String wire;
  final String label;
  final ActivityGroup group;

  bool get needsOptIn => group == ActivityGroup.usage;

  static ActivityAction? fromWire(String? value) {
    for (final action in values) {
      if (action.wire == value) return action;
    }
    return null;
  }
}

/// Version string recorded with each entry. Keep in step with pubspec.yaml.
const appVersion = '1.0.0';
