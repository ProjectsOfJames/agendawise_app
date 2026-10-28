import 'dart:math';

import 'package:agendawise/core/domain/challenge_type.dart';
import 'package:agendawise/features/challenges/domain/challenge_engines.dart';
import 'package:agendawise/features/difficulty/domain/challenge_attempt.dart';
import 'package:agendawise/features/difficulty/domain/difficulty_adjuster.dart';
import 'package:flutter_test/flutter_test.dart';

ChallengeAttempt _attempt(int seconds, {bool success = true}) =>
    ChallengeAttempt(
      type: ChallengeType.maths,
      difficulty: 3,
      duration: Duration(seconds: seconds),
      success: success,
      at: DateTime(2026),
    );

void main() {
  group('MathsEngine', () {
    test('level 5 operands are larger than level 1 and answers are integers',
        () {
      final engine = MathsEngine(Random(1));
      for (var i = 0; i < 50; i++) {
        final easy = engine.generate(1);
        final hard = engine.generate(5);
        expect(easy.operands.reduce(max), lessThan(10));
        expect(hard.operands.reduce(max), greaterThan(9));
        expect(engine.check(easy, '${easy.answer}'), isTrue);
      }
    });

    test('correct answer passes, wrong answer fails', () {
      final engine = MathsEngine(Random(2));
      final q = engine.generate(3);
      expect(engine.check(q, ' ${q.answer} '), isTrue);
      expect(engine.check(q, '${q.answer + 1}'), isFalse);
      expect(engine.check(q, 'abc'), isFalse);
    });

    test('a wrong answer leads to a different question', () {
      final engine = MathsEngine(Random(3));
      final q = engine.generate(2);
      expect(engine.next(2, q).text, isNot(q.text));
    });

    test('subtraction never goes below zero', () {
      final engine = MathsEngine(Random(4));
      for (var i = 0; i < 100; i++) {
        expect(engine.generate(3).answer, greaterThanOrEqualTo(0));
      }
    });
  });

  group('MemoryEngine', () {
    test('lengths are 3 to 7 for levels 1 to 5', () {
      final engine = MemoryEngine(Random(5));
      expect([for (var l = 1; l <= 5; l++) engine.generate(l).length],
          [3, 4, 5, 6, 7]);
    });

    test('same sequence passes; any difference fails', () {
      final engine = MemoryEngine(Random(6));
      final seq = engine.generate(3);
      expect(engine.check(seq, List.of(seq)), isTrue);
      final changed = List.of(seq)..[0] = (seq[0] + 1) % 9;
      expect(engine.check(seq, changed), isFalse);
      expect(engine.check(seq, seq.sublist(1)), isFalse);
    });

    test('no tile repeats straight after itself', () {
      final engine = MemoryEngine(Random(7));
      for (var i = 0; i < 50; i++) {
        final seq = engine.generate(5);
        for (var j = 1; j < seq.length; j++) {
          expect(seq[j], isNot(seq[j - 1]));
        }
      }
    });
  });

  group('PhraseEngine', () {
    test('level 5 phrases are longer than level 1', () {
      final engine = PhraseEngine(Random(8));
      expect(engine.generate(5).length, greaterThan(engine.generate(1).length));
    });

    test('exact text passes; one wrong letter or different case fails', () {
      final engine = PhraseEngine(Random(9));
      final phrase = engine.generate(2);
      expect(engine.check(phrase, phrase), isTrue);
      expect(engine.check(phrase, '$phrase  '), isTrue);
      expect(engine.check(phrase, phrase.toLowerCase()), isFalse);
      expect(engine.check(phrase, phrase.replaceFirst(RegExp('[a-z]'), 'z')),
          isFalse);
    });
  });

  group('Shake', () {
    test('required shakes are 5 at level 1 and 25 at level 5', () {
      expect(shakesRequired(1), 5);
      expect(shakesRequired(5), 25);
    });

    test('only spikes above the threshold and apart in time count', () {
      final counter = ShakeCounter();
      final t0 = DateTime(2026);
      // Resting: about 1 g.
      expect(counter.add(0, 0, 9.8, t0), isFalse);
      // Spike.
      expect(counter.add(25, 5, 9.8, t0.add(const Duration(milliseconds: 100))),
          isTrue);
      // Second spike too soon.
      expect(counter.add(25, 5, 9.8, t0.add(const Duration(milliseconds: 300))),
          isFalse);
      // Spike after the gap.
      expect(counter.add(-25, 0, 9.8, t0.add(const Duration(milliseconds: 600))),
          isTrue);
      expect(counter.count, 2);
    });
  });

  group('DifficultyAdjuster', () {
    const adjuster = DifficultyAdjuster();
    const avg = Duration(seconds: 20);

    test('two attempts leave the level unchanged', () {
      expect(
        adjuster.adjust(
            current: 3,
            recentNewestFirst: [_attempt(5), _attempt(5)],
            historicalAverage: avg),
        3,
      );
    });

    test('ten quick successes raise the level', () {
      expect(
        adjuster.adjust(
            current: 3,
            recentNewestFirst: List.generate(10, (_) => _attempt(10)),
            historicalAverage: avg),
        4,
      );
    });

    test('four failures in ten lower the level', () {
      final attempts = [
        for (var i = 0; i < 4; i++) _attempt(15, success: false),
        for (var i = 0; i < 6; i++) _attempt(15),
      ];
      expect(
        adjuster.adjust(
            current: 3, recentNewestFirst: attempts, historicalAverage: avg),
        2,
      );
    });

    test('a latest attempt at 160% of the average lowers the level', () {
      final attempts = [_attempt(32), _attempt(20), _attempt(20)];
      expect(
        adjuster.adjust(
            current: 3, recentNewestFirst: attempts, historicalAverage: avg),
        2,
      );
    });

    test('level 5 stays 5 when rising; level 1 stays 1 when falling', () {
      expect(
        adjuster.adjust(
            current: 5,
            recentNewestFirst: List.generate(10, (_) => _attempt(5)),
            historicalAverage: avg),
        5,
      );
      expect(
        adjuster.adjust(
            current: 1,
            recentNewestFirst: List.generate(5, (_) => _attempt(30, success: false)),
            historicalAverage: avg),
        1,
      );
    });

    test('only the last ten attempts count', () {
      final attempts = [
        ...List.generate(10, (_) => _attempt(10)),
        // The two oldest are failures and would lower the level if counted.
        _attempt(60, success: false),
        _attempt(60, success: false),
      ];
      expect(
        adjuster.adjust(
            current: 3, recentNewestFirst: attempts, historicalAverage: avg),
        4,
      );
    });
  });
}
