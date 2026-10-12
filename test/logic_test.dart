import 'package:flutter_test/flutter_test.dart';
import 'package:project/utils.dart';

void main() {
  group('sleepHours', () {
    test('crosses midnight', () => expect(sleepHours('23:00', '07:00'), 8.0));
    test('same-day nap', () => expect(sleepHours('13:00', '14:30'), 1.5));
    test('equal times count as 24h wrap', () => expect(sleepHours('07:00', '07:00'), 24.0));
  });

  group('bedtime averaging', () {
    test('after-midnight bedtimes sort after evening ones', () {
      expect(bedtimeMinutesNormalized('00:30') > bedtimeMinutesNormalized('23:30'), isTrue);
    });
    test('clock12 formats', () {
      expect(clock12(23 * 60 + 5), '11:05 PM');
      expect(clock12(25 * 60), '1:00 AM');
    });
  });

  group('dates', () {
    test('dateKey pads', () => expect(dateKey(DateTime(2026, 3, 5)), '2026-03-05'));
    test('daysBetween', () {
      expect(daysBetween(DateTime(2026, 2, 28), DateTime(2026, 3, 1)), 1);
    });
    test('prettyNameFromEmail', () {
      expect(prettyNameFromEmail('john_doe99@uni.edu'), 'John Doe');
      expect(prettyNameFromEmail('123@uni.edu'), 'Student');
    });
  });

  group('PasswordRules', () {
    test('accepts 8+ chars with letter and number', () => expect(PasswordRules.ok('abcdef12'), isTrue));
    test('rejects short', () => expect(PasswordRules.ok('ab12'), isFalse));
    test('rejects no number', () => expect(PasswordRules.ok('abcdefgh'), isFalse));
    test('rejects no letter', () => expect(PasswordRules.ok('12345678'), isFalse));
    test('email check', () {
      expect(looksLikeEmail('a@b.edu'), isTrue);
      expect(looksLikeEmail('nope'), isFalse);
    });
  });
}
