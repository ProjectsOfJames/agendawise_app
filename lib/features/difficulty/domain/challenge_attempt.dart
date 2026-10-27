import '../../../core/domain/challenge_type.dart';

/// One logged attempt at a challenge, as used by the difficulty rule.
class ChallengeAttempt {
  const ChallengeAttempt({
    required this.type,
    required this.difficulty,
    required this.duration,
    required this.success,
    required this.at,
  });

  final ChallengeType type;
  final int difficulty;
  final Duration duration;
  final bool success;
  final DateTime at;
}
