/// Coverage for [TefilaRules.isVihiNoamRecited], which is the one rule in this library
/// that reads the week ahead rather than the day it is asked about.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  final rules = TefilaRules();

  JewishCalendar day(int year, int month, int dayOfMonth,
          {bool inIsrael = false}) =>
      JewishCalendar.initDate(year, month, dayOfMonth)..inIsrael = inIsrael;

  /// The Sunday that opens the week the given day falls in.
  JewishCalendar sundayOf(JewishCalendar from) {
    final calendar = from.clone();
    while (!calendar.isSunday()) {
      calendar.back();
    }
    return calendar;
  }

  group('TefilaRules - vihi noam', () {
    test('is said on an ordinary motzei shabbos', () {
      final calendar = sundayOf(day(5784, JewishDate.CHESHVAN, 12));
      expect(rules.isVihiNoamRecited(calendar), isTrue);
    });

    test('is not said on any day but the one motzei shabbos opened', () {
      final calendar = day(5784, JewishDate.CHESHVAN, 1);

      for (var of = 1; of <= 29; of++) {
        calendar.setJewishDate(5784, JewishDate.CHESHVAN, of);
        if (calendar.isSunday()) continue;
        expect(rules.isVihiNoamRecited(calendar), isFalse,
            reason: '$of Cheshvan');
      }
    });

    test('a yom tov anywhere from the Sunday to the Friday silences it', () {
      final year = 5784;

      for (var of = 1; of <= 29; of++) {
        final calendar = day(year, JewishDate.TISHREI, of);
        if (!calendar.isSunday()) continue;

        var yomTov = false;
        final week = calendar.clone();
        for (var ahead = 0; ahead < 6; ahead++) {
          yomTov = yomTov || week.isYomTovAssurBemelacha();
          week.forward(Calendar.DATE, 1);
        }

        expect(rules.isVihiNoamRecited(calendar), equals(!yomTov),
            reason: '$of Tishrei');
      }
    });

    test('a yom tov on the shabbos that closes the week does not', () {
      final calendar = day(5780, JewishDate.TISHREI, 1);
      var found = 0;

      for (var date = 0; date < 20 * 365; date++) {
        calendar.forward(Calendar.DATE, 1);
        if (!calendar.isSunday()) continue;

        final shabbos = calendar.clone()..forward(Calendar.DATE, 6);
        if (!shabbos.isYomTovAssurBemelacha()) continue;

        final week = calendar.clone();
        var earlier = false;
        for (var ahead = 0; ahead < 6; ahead++) {
          earlier = earlier || week.isYomTovAssurBemelacha();
          week.forward(Calendar.DATE, 1);
        }
        if (earlier) continue;

        expect(rules.isVihiNoamRecited(calendar), isTrue,
            reason: '${calendar.getJewishDayOfMonth()}/'
                '${calendar.getJewishMonth()}/${calendar.getJewishYear()}');
        found++;
      }

      expect(found, greaterThan(0));
    });

    test('the motzei shabbos of Tisha Bav is silent, pushed off or not', () {
      final calendar = day(5784, JewishDate.AV, 1);
      var kept = 0;
      var pushed = 0;

      for (var year = 5780; year < 5820; year++) {
        for (var of = 9; of <= 10; of++) {
          calendar.setJewishDate(year, JewishDate.AV, of);
          if (!calendar.isTishaBav() || !calendar.isSunday()) continue;

          expect(rules.isVihiNoamRecited(calendar), isFalse,
              reason: '$of Av $year');
          if (of == 9) kept++;
          if (of == 10) pushed++;
        }
      }

      expect(kept, greaterThan(0));
      expect(pushed, greaterThan(0));
    });
  });
}
