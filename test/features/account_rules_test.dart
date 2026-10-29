import 'package:agendawise/features/account/domain/account_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validation', () {
    test('display name is required and limited in length', () {
      expect(validateDisplayName('  '), isNotNull);
      expect(validateDisplayName('Thandi'), isNull);
      expect(validateDisplayName('x' * 61), isNotNull);
    });

    test('email must look like an address', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('thandi'), isNotNull);
      expect(validateEmail('thandi@example'), isNotNull);
      expect(validateEmail(' thandi@example.com '), isNull);
    });

    test('passwords need 8 characters and must match', () {
      expect(validateNewPassword('short', 'short'), isNotNull);
      expect(validateNewPassword('longenough', 'different'), isNotNull);
      expect(validateNewPassword('longenough', 'longenough'), isNull);
    });
  });

  group('messages', () {
    test('wrong credentials share one message', () {
      final wrong = messageForAuthCode('wrong-password');
      expect(messageForAuthCode('user-not-found'), wrong);
      expect(messageForAuthCode('invalid-credential'), wrong);
    });

    test('unknown codes are still readable', () {
      expect(messageForAuthCode('odd-code'), contains('odd-code'));
    });
  });

  group('stamps', () {
    test('day and month stamps are zero-padded', () {
      expect(dayStamp(DateTime(2026, 3, 7)), '2026-03-07');
      expect(monthStamp(DateTime(2026, 3, 7)), '2026-03');
    });
  });
}
