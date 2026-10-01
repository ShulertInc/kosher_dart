import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  JewishCalendar date(int year, int month, int day, {bool walled = false}) =>
      JewishCalendar.fromJewishDate(year, month, day)..setIsMukafChoma(walled);

  group('JewishCalendar.isPurimMeshulashSunday', () {
    test('16 Adar 5781, the Sunday after a Shabbos 15 Adar', () {
      final sunday = date(5781, JewishDate.ADAR, 16);
      expect(sunday.getDayOfWeek(), 1);
      for (final walled in [true, false]) {
        expect(
            date(5781, JewishDate.ADAR, 16, walled: walled)
                .isPurimMeshulashSunday(),
            isTrue,
            reason: 'walled $walled');
      }
    });

    test('16 Adar II in a leap year whose 15th is Shabbos', () {
      final years = [for (var year = 5700; year < 5900; year++) year]
          .where((year) =>
              JewishCalendar.fromJewishDate(year, JewishDate.TISHREI, 1)
                  .isJewishLeapYear() &&
              date(year, JewishDate.ADAR_II, 15).getDayOfWeek() == 7)
          .toList();
      expect(years, isNotEmpty);
      for (final year in years) {
        expect(
            date(year, JewishDate.ADAR_II, 16).isPurimMeshulashSunday(), isTrue,
            reason: '$year');
        expect(
            date(year, JewishDate.ADAR, 16).isPurimMeshulashSunday(), isFalse,
            reason: 'Adar I $year');
      }
    });

    test('16 Adar on any other day of the week', () {
      for (var year = 5700; year < 5900; year++) {
        final leap = JewishCalendar.fromJewishDate(year, JewishDate.TISHREI, 1)
            .isJewishLeapYear();
        final sixteenth =
            date(year, leap ? JewishDate.ADAR_II : JewishDate.ADAR, 16);
        expect(
            sixteenth.isPurimMeshulashSunday(), sixteenth.getDayOfWeek() == 1,
            reason: '$year');
      }
    });

    test('the 14th and 15th of a Purim Meshulash are not it', () {
      expect(date(5781, JewishDate.ADAR, 14).isPurimMeshulashSunday(), isFalse);
      expect(date(5781, JewishDate.ADAR, 15).isPurimMeshulashSunday(), isFalse);
      expect(date(5781, JewishDate.ADAR, 17).isPurimMeshulashSunday(), isFalse);
    });
  });
}
