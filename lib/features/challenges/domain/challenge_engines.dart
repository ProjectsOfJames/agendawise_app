import 'dart:math';

/// One generated maths question with a single integer answer.
class MathsQuestion {
  const MathsQuestion(this.text, this.answer, this.operands);

  final String text;
  final int answer;

  /// The numbers in the question, used to check difficulty scaling.
  final List<int> operands;
}

/// Arithmetic that grows harder with the level: single digits at 1,
/// two-digit sums at 2 and 3, multiplication at 4 and a mixed expression at 5.
class MathsEngine {
  MathsEngine([Random? random]) : _random = random ?? Random();

  final Random _random;

  int _between(int min, int max) => min + _random.nextInt(max - min + 1);

  MathsQuestion generate(int level) {
    switch (level.clamp(1, 5)) {
      case 1:
        final a = _between(2, 9), b = _between(2, 9);
        return MathsQuestion('$a + $b', a + b, [a, b]);
      case 2:
        final a = _between(12, 59), b = _between(11, 39);
        return MathsQuestion('$a + $b', a + b, [a, b]);
      case 3:
        final a = _between(41, 99), b = _between(12, 40);
        return _random.nextBool()
            ? MathsQuestion('$a + $b', a + b, [a, b])
            : MathsQuestion('$a − $b', a - b, [a, b]);
      case 4:
        final a = _between(13, 49), b = _between(3, 9);
        return MathsQuestion('$a × $b', a * b, [a, b]);
      default:
        final a = _between(13, 39), b = _between(4, 9), c = _between(21, 99);
        return MathsQuestion('$a × $b + $c', a * b + c, [a, b, c]);
    }
  }

  /// A new question at [level] that differs from [previous].
  MathsQuestion next(int level, MathsQuestion previous) {
    for (var i = 0; i < 20; i++) {
      final candidate = generate(level);
      if (candidate.text != previous.text) return candidate;
    }
    return generate(level);
  }

  bool check(MathsQuestion question, String answer) =>
      int.tryParse(answer.trim()) == question.answer;
}

/// Sequences of tiles on a 3 × 3 grid, 3 to 7 steps long.
class MemoryEngine {
  MemoryEngine([Random? random]) : _random = random ?? Random();

  static const tileCount = 9;

  final Random _random;

  static int lengthFor(int level) => level.clamp(1, 5) + 2;

  /// No tile repeats straight after itself, so every step is visible.
  List<int> generate(int level) {
    final sequence = <int>[];
    while (sequence.length < lengthFor(level)) {
      final tile = _random.nextInt(tileCount);
      if (sequence.isEmpty || sequence.last != tile) sequence.add(tile);
    }
    return sequence;
  }

  bool check(List<int> expected, List<int> entered) {
    if (expected.length != entered.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (expected[i] != entered[i]) return false;
    }
    return true;
  }
}

/// Phrases to type exactly; longer at higher levels.
class PhraseEngine {
  PhraseEngine([Random? random]) : _random = random ?? Random();

  final Random _random;

  static const _phrases = <List<String>>[
    [
      'Rise and shine',
      'Good morning world',
      'Time to wake',
      'Up and at it',
      'Hello new day',
    ],
    [
      'The early bird catches the worm',
      'Today is a brand new day',
      'Coffee first and then the world',
      'Open the curtains and stretch',
      'Fresh air and a clear mind',
    ],
    [
      'Every morning brings a fresh chance to begin again',
      'A good plan today beats a perfect plan tomorrow',
      'Small steps every day add up to big results',
      'Make your bed and the rest of the day follows',
      'The sun is up and so am I right now',
    ],
    [
      'Discipline is choosing what you want most over what you want now',
      'Wake up with determination and go to bed with satisfaction today',
      'The secret of getting ahead is getting started on the first task',
      'Do something today that your future self will thank you for later',
      'Mornings are a fresh page waiting for the very first sentence',
    ],
    [
      'Success is the sum of small efforts repeated day in and day out, '
          'so start now',
      'Each sunrise is an invitation to brighten the day for everyone '
          'around you, including yourself',
      'Get out of bed, drink some water and plan the three most important '
          'tasks',
      'Snoozing feels good for a moment but keeping promises to yourself '
          'feels better',
      'The best way to predict your day is to create it before breakfast '
          'is over',
    ],
  ];

  String generate(int level) {
    final options = _phrases[level.clamp(1, 5) - 1];
    return options[_random.nextInt(options.length)];
  }

  /// A new phrase at [level] that differs from [previous].
  String next(int level, String previous) {
    for (var i = 0; i < 20; i++) {
      final candidate = generate(level);
      if (candidate != previous) return candidate;
    }
    return generate(level);
  }

  /// Exact match: case, spelling and punctuation must agree. Surrounding
  /// spaces are ignored.
  bool check(String phrase, String typed) => typed.trim() == phrase;
}

/// Number of shakes required: 5 at level 1 up to 25 at level 5.
int shakesRequired(int level) => level.clamp(1, 5) * 5;

/// Counts shakes from accelerometer samples. A shake is a spike above
/// [thresholdG] that comes at least [minimumGap] after the previous one.
class ShakeCounter {
  ShakeCounter({
    this.thresholdG = 2.2,
    this.minimumGap = const Duration(milliseconds: 350),
  });

  static const _gravity = 9.80665;

  final double thresholdG;
  final Duration minimumGap;

  int count = 0;
  DateTime? _lastShake;

  /// Feeds one sample in m/s². Returns true when it counted as a shake.
  bool add(double x, double y, double z, DateTime at) {
    final gForce = sqrt(x * x + y * y + z * z) / _gravity;
    if (gForce < thresholdG) return false;
    final last = _lastShake;
    if (last != null && at.difference(last) < minimumGap) return false;
    _lastShake = at;
    count++;
    return true;
  }

  void reset() {
    count = 0;
    _lastShake = null;
  }
}
