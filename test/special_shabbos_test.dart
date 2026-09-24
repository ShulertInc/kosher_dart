/// Tests for the named Shabbosos beyond the four parshiyos, and for the parsha of the
/// coming Shabbos.
library;

import 'package:kosher_dart/kosher_dart.dart';
import 'package:test/test.dart';

JewishCalendar hebrew(int year, int month, int day, {bool inIsrael = false}) =>
    JewishCalendar.fromJewishDateInIsrael(year, month, day, inIsrael);

void main() {
  group('the named Shabbosos', () {
    test('Shuva is the Shabbos of the Aseres Yemei Teshuva', () {
      // 5 Tishrei 5786, 27 September 2025.
      expect(hebrew(5786, JewishDate.TISHREI, 5).getSpecialShabbos(), Parshah.SHUVA);
      expect(hebrew(5786, JewishDate.TISHREI, 4).getSpecialShabbos(), Parshah.NONE);
    });

    test('Shira is the Shabbos the shiras hayam is read', () {
      // 10 Shevat 5785, 8 February 2025.
      final shabbos = hebrew(5785, JewishDate.SHEVAT, 10);
      expect(shabbos.getParshah(), Parshah.BESHALACH);
      expect(shabbos.getSpecialShabbos(), Parshah.SHIRA);
    });

    test('Hagadol is the Shabbos before Pesach', () {
      // 14 Nissan 5785, 12 April 2025.
      expect(hebrew(5785, JewishDate.NISSAN, 14).getSpecialShabbos(), Parshah.HAGADOL);
      expect(hebrew(5785, JewishDate.NISSAN, 7).getSpecialShabbos(), Parshah.NONE);
    });

    test('Chazon and Nachamu bracket Tisha B Av', () {
      // 8 Av and 15 Av 5785, 2 and 9 August 2025.
      expect(hebrew(5785, JewishDate.AV, 8).getSpecialShabbos(), Parshah.CHAZON);
      expect(hebrew(5785, JewishDate.AV, 15).getSpecialShabbos(), Parshah.NACHAMU);
    });

    test('a weekday is never a named Shabbos', () {
      expect(hebrew(5785, JewishDate.AV, 9).getSpecialShabbos(), Parshah.NONE);
    });

    test('the four parshiyos still answer', () {
      // 1 Adar 5785, 1 March 2025.
      expect(hebrew(5785, JewishDate.ADAR, 1).getSpecialShabbos(), Parshah.SHKALIM);
    });
  });

  group('the parsha of the coming Shabbos', () {
    test('a weekday looks ahead to that Shabbos', () {
      final wednesday = JewishCalendar.fromLocalDate(DateTime(2026, 1, 14));
      final shabbos = JewishCalendar.fromLocalDate(DateTime(2026, 1, 17));

      expect(shabbos.getDayOfWeek(), 7);
      expect(wednesday.getUpcomingParshah(), shabbos.getParshah());
      expect(wednesday.getUpcomingParshah(), isNot(Parshah.NONE));
    });

    test('a Shabbos looks ahead to the next one, not to itself', () {
      final shabbos = JewishCalendar.fromLocalDate(DateTime(2026, 1, 17));
      final next = JewishCalendar.fromLocalDate(DateTime(2026, 1, 24));

      expect(shabbos.getUpcomingParshah(), next.getParshah());
      expect(shabbos.getUpcomingParshah(), isNot(shabbos.getParshah()));
    });

    test('it skips a Shabbos whose reading yom tov displaces', () {
      // The Shabbos of Succos 5786 has no parsha of its own, so the Thursday before it
      // reads past it to the next Shabbos that does.
      final beforeSuccos = hebrew(5786, JewishDate.TISHREI, 12);
      expect(beforeSuccos.getUpcomingParshah(), isNot(Parshah.NONE));
    });
  });
}
