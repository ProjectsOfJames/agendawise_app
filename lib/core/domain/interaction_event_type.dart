enum InteractionEventType {
  alarmDismissed('alarm_dismissed'),
  alarmSnoozed('alarm_snoozed'),
  challengeCompleted('challenge_completed'),
  challengeFailed('challenge_failed'),
  taskCompleted('task_completed');

  const InteractionEventType(this.dbValue);

  final String dbValue;

  static InteractionEventType fromDb(String value) {
    for (final type in values) {
      if (type.dbValue == value) return type;
    }
    throw ArgumentError.value(value, 'value', 'Unknown interaction event type');
  }
}
