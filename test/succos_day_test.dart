import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  JewishCalendar tishrei(int year, int day, {required bool inIsrael}) =>
      JewishCalendar.fromJewishDate(year, JewishDate.TISHREI, day)
        ..setInIsrael(inIsrael);

  List<int> days(JewishCalendar calendar) => [
        for (var day = 1; day <= 7; day++)
          if (calendar.isSuccosDay(day)) day,
      ];

  group('JewishCalendar.isSuccosDay', () {
    test('each date of succos is its own day, in Israel and outside it', () {
      for (final year in [5784, 5785, 5786, 5787]) {
        for (final inIsrael in [true, false]) {
          for (var date = 15; date <= 21; date++) {
            expect(days(tishrei(year, date, inIsrael: inIsrael)),
                equals([date - 14]),
                reason: '$date Tishrei $year, inIsrael $inIsrael');
          }
        }
      }
    });

    test('the seventh day is Hoshana Rabba', () {
      for (final inIsrael in [true, false]) {
        final calendar = tishrei(5785, 21, inIsrael: inIsrael);
        expect(calendar.isHoshanaRabba(), isTrue);
        expect(calendar.isSuccosDay(7), isTrue);
      }
    });

    test('Shemini Atzeres, Simchas Torah and erev succos are no day of succos',
        () {
      for (final inIsrael in [true, false]) {
        for (final date in [14, 22, 23]) {
          expect(days(tishrei(5785, date, inIsrael: inIsrael)), isEmpty,
              reason: '$date Tishrei, inIsrael $inIsrael');
        }
      }
    });

    test('the same dates of another month are no day of succos', () {
      for (var date = 15; date <= 21; date++) {
        final pesach =
            JewishCalendar.fromJewishDate(5785, JewishDate.NISSAN, date);
        expect(days(pesach), isEmpty, reason: '$date Nissan');
      }
    });

    test('a day outside 1 through 7 is refused', () {
      final calendar = tishrei(5785, 17, inIsrael: false);
      expect(() => calendar.isSuccosDay(0), throwsArgumentError);
      expect(() => calendar.isSuccosDay(8), throwsArgumentError);
    });
  });
}
