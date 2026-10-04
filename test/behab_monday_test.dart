import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  List<JewishCalendar> behab(int year, int month) => [
        for (var day = 1; day <= 29; day++)
          JewishCalendar.fromJewishDate(year, month, day),
      ].where((c) => c.isBeHaB()).toList();

  group('JewishCalendar.isBeHaBFirstMonday and isBeHaBSecondMonday', () {
    test('split the two BeHaB Mondays in every Cheshvan and Iyar', () {
      for (var year = 5700; year <= 6000; year++) {
        for (final month in [JewishDate.CHESHVAN, JewishDate.IYAR]) {
          final days = behab(year, month);
          final where = '$year month $month';

          expect(days.length, equals(3), reason: where);
          expect(days[0].isBeHaBFirstMonday(), isTrue, reason: where);
          expect(days[0].isBeHaBSecondMonday(), isFalse, reason: where);
          expect(days[1].isBeHaBFirstMonday(), isFalse, reason: where);
          expect(days[1].isBeHaBSecondMonday(), isFalse, reason: where);
          expect(days[2].isBeHaBFirstMonday(), isFalse, reason: where);
          expect(days[2].isBeHaBSecondMonday(), isTrue, reason: where);
          expect(days[2].getJewishDayOfMonth() - days[0].getJewishDayOfMonth(),
              equals(7),
              reason: where);
        }
      }
    });

    test('never on a day that is not BeHaB', () {
      for (var date = DateTime.utc(2020, 1, 1);
          date.isBefore(DateTime.utc(2040, 1, 1));
          date = date.add(const Duration(days: 1))) {
        final c = JewishCalendar.fromLocalDate(date);
        if (c.isBeHaB()) continue;

        expect(c.isBeHaBFirstMonday(), isFalse, reason: '$date');
        expect(c.isBeHaBSecondMonday(), isFalse, reason: '$date');
      }
    });
  });
}
