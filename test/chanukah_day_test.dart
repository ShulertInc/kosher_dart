import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  List<int> days(JewishCalendar calendar) => [
        for (var day = 1; day <= 8; day++)
          if (calendar.isChanukahDay(day)) day,
      ];

  group('JewishCalendar.isChanukahDay', () {
    test('the eight days from 25 Kislev, short Kislev and long alike', () {
      for (final year in [5783, 5784, 5785, 5786, 5787]) {
        final calendar =
            JewishCalendar.fromJewishDate(year, JewishDate.KISLEV, 25);
        for (var day = 1; day <= 8; day++) {
          expect(days(calendar), equals([day]),
              reason: 'day $day of chanukah $year');
          calendar.plusDays(1);
        }
        expect(days(calendar), isEmpty, reason: 'the day after chanukah $year');
      }
    });

    test('the eighth day is in Teves', () {
      for (final year in [5784, 5785, 5786]) {
        final calendar =
            JewishCalendar.fromJewishDate(year, JewishDate.KISLEV, 25)
              ..plusDays(7);
        expect(calendar.getJewishMonth(), JewishDate.TEVES);
        expect(calendar.isChanukahDay(8), isTrue);
      }
    });

    test('erev chanukah is no day of chanukah', () {
      final calendar =
          JewishCalendar.fromJewishDate(5785, JewishDate.KISLEV, 24);
      expect(days(calendar), isEmpty);
    });

    test('a day outside 1 through 8 is refused', () {
      final calendar =
          JewishCalendar.fromJewishDate(5785, JewishDate.KISLEV, 27);
      expect(() => calendar.isChanukahDay(0), throwsArgumentError);
      expect(() => calendar.isChanukahDay(9), throwsArgumentError);
    });
  });
}
