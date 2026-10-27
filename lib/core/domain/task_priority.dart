enum TaskPriority {
  high('high'),
  medium('medium'),
  low('low');

  const TaskPriority(this.dbValue);

  final String dbValue;

  static TaskPriority fromDb(String value) {
    for (final priority in values) {
      if (priority.dbValue == value) return priority;
    }
    throw ArgumentError.value(value, 'value', 'Unknown task priority');
  }
}
