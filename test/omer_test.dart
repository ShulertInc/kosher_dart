import 'package:kosher_dart/kosher_dart.dart';
import 'package:test/test.dart';

JewishCalendar _on(int year, int month, int day) =>
    JewishCalendar.fromDateTime(DateTime(year, month, day));

String _unpointed(String text) =>
    text.replaceAll(RegExp('[֑-ׇ]'), '');

void main() {
  group('formatOmer', () {
    final formatter = HebrewDateFormatter()
      ..hebrewFormat = true
      ..longOmerFormat = true;

    test('the first day says one day, not two', () {
      expect(_on(2026, 4, 3).getDayOfOmer(), 1);
      expect(
        _unpointed(formatter.formatOmer(_on(2026, 4, 3))),
        'היום יום אחד לעמר:',
      );
    });

    test('the thirty-third day says thirty-three', () {
      expect(_on(2026, 5, 5).getDayOfOmer(), 33);
      expect(
        _unpointed(formatter.formatOmer(_on(2026, 5, 5))),
        'היום שלשה ושלשים יום לעמר, שהם ארבעה שבועות וחמשה ימים:',
      );
    });

    test('the last day is reachable', () {
      expect(_on(2026, 5, 21).getDayOfOmer(), 49);
      expect(
        _unpointed(formatter.formatOmer(_on(2026, 5, 21))),
        'היום תשעה וארבעים יום לעמר, שהם שבעה שבועות:',
      );
    });

    test('a day outside the omer says nothing', () {
      expect(formatter.formatOmer(_on(2026, 6, 15)), isEmpty);
    });
  });

  group('isOmerDay', () {
    test('answers only the day it is asked about', () {
      expect(_on(2026, 5, 5).isOmerDay(33), isTrue);
      expect(_on(2026, 5, 5).isOmerDay(32), isFalse);
      expect(_on(2026, 5, 5).isOmerDay(34), isFalse);
    });

    test('reaches both ends of the count', () {
      expect(_on(2026, 4, 3).isOmerDay(1), isTrue);
      expect(_on(2026, 5, 21).isOmerDay(49), isTrue);
    });

    test('every day of the omer answers for itself and no other', () {
      final counted = <int>{};

      for (var offset = 0; offset < 49; offset++) {
        final day = _on(2026, 4, 3).getGregorianCalendar().add(
              Duration(days: offset),
            );
        final calendar = JewishCalendar.fromDateTime(day);

        for (var asked = 1; asked <= 49; asked++) {
          expect(calendar.isOmerDay(asked), asked == offset + 1,
              reason: 'day ${offset + 1} asked about $asked');
        }

        counted.add(calendar.getDayOfOmer());
      }

      expect(counted, {for (var day = 1; day <= 49; day++) day});
    });

    test('a day outside the omer is no day of it', () {
      expect(_on(2026, 6, 15).isOmerDay(1), isFalse);
      expect(_on(2026, 6, 15).isOmerDay(49), isFalse);
    });

    test('a day off the count is refused rather than answered', () {
      expect(() => _on(2026, 5, 5).isOmerDay(0), throwsArgumentError);
      expect(() => _on(2026, 5, 5).isOmerDay(50), throwsArgumentError);
    });
  });
}
