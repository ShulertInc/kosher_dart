/// Tests for the two fasts that move off the day they fall on. Both conditions named
/// the wrong weekday: the seventeenth of Tammuz was pushed off a Friday rather than off
/// Shabbos, and the fast of the firstborn looked for a Tuesday rather than the Thursday
/// it is brought back to.
library;

import 'package:kosher_dart/kosher_dart.dart';
import 'package:test/test.dart';

JewishCalendar on(int year, int month, int day) =>
    JewishCalendar.fromDateTime(DateTime(year, month, day));

void main() {
  group('the seventeenth of Tammuz', () {
    test('is fasted on the Sunday when the seventeenth is Shabbos', () {
      // 17 Tammuz 5779 fell on Shabbos, 20 July 2019.
      final JewishCalendar shabbos = on(2019, 7, 20);
      expect(shabbos.getJewishDayOfMonth(), 17);
      expect(shabbos.getDayOfWeek(), JewishDate.saturday);
      expect(shabbos.getYomTovIndex(), isNot(JewishCalendar.SEVENTEEN_OF_TAMMUZ));
      expect(shabbos.isTaanis(), isFalse);

      final JewishCalendar sunday = on(2019, 7, 21);
      expect(sunday.getYomTovIndex(), JewishCalendar.SEVENTEEN_OF_TAMMUZ);
      expect(sunday.isTaanis(), isTrue);
    });

    test('is fasted on the day itself in an ordinary year', () {
      // 17 Tammuz 5784 fell on Tuesday, 23 July 2024.
      final JewishCalendar fast = on(2024, 7, 23);
      expect(fast.getJewishDayOfMonth(), 17);
      expect(fast.getYomTovIndex(), JewishCalendar.SEVENTEEN_OF_TAMMUZ);
      expect(on(2024, 7, 24).getYomTovIndex(),
          isNot(JewishCalendar.SEVENTEEN_OF_TAMMUZ));
    });
  });

  group('the fast of the firstborn', () {
    test('moves back to the Thursday when erev Pesach is Shabbos', () {
      // Erev Pesach 5785 fell on Shabbos, 12 April 2025.
      final JewishCalendar erevPesach = on(2025, 4, 12);
      expect(erevPesach.getJewishDayOfMonth(), 14);
      expect(erevPesach.getDayOfWeek(), JewishDate.saturday);
      expect(erevPesach.isTaanisBechoros(), isFalse);

      final JewishCalendar thursday = on(2025, 4, 10);
      expect(thursday.getJewishDayOfMonth(), 12);
      expect(thursday.getDayOfWeek(), JewishDate.thursday);
      expect(thursday.isTaanisBechoros(), isTrue);

      expect(on(2025, 4, 8).isTaanisBechoros(), isFalse);
    });

    test('is on erev Pesach itself in an ordinary year', () {
      // Erev Pesach 5784 fell on Monday, 22 April 2024.
      final JewishCalendar erevPesach = on(2024, 4, 22);
      expect(erevPesach.getJewishDayOfMonth(), 14);
      expect(erevPesach.isTaanisBechoros(), isTrue);
      expect(on(2024, 4, 20).isTaanisBechoros(), isFalse);
    });
  });
}
