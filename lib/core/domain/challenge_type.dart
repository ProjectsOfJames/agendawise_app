enum ChallengeType {
  maths('maths'),
  memory('memory'),
  phrase('phrase'),
  shake('shake');

  const ChallengeType(this.dbValue);

  final String dbValue;

  static ChallengeType fromDb(String value) {
    for (final type in values) {
      if (type.dbValue == value) return type;
    }
    throw ArgumentError.value(value, 'value', 'Unknown challenge type');
  }
}
