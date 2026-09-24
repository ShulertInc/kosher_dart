import 'package:kosher_dart/kosher_dart.dart';
import 'package:test/test.dart';

JewishCalendar _on(int year, int month, int day) =>
    JewishCalendar.fromLocalDate(DateTime(year, month, day));

void main() {
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
        final day = _on(2026, 4, 3).getLocalDate().add(
              Duration(days: offset),
            );
        final calendar = JewishCalendar.fromLocalDate(day);

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
