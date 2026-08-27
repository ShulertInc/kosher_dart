/// Coverage for the predicates that name a day or a rule outright, so a caller never has
/// to compare a holiday index or a weekday number itself.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  JewishCalendar cal() => JewishCalendar()..inIsrael = false;
  final rules = TefilaRules();

  group('JewishCalendar - days named outright', () {
    test('each predicate answers for its own day', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 14)).isErevPesach(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 9)).isErevYomKippur(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 21)).isHoshanaRabba(),
        isTrue,
      );
    });

    // Taanis Esther moves off the 13th when the 13th is Friday or Shabbos, so the day is
    // found rather than assumed: the predicate has to agree with the index, whichever day
    // that turns out to be.
    test('isTaanisEsther agrees with the index, wherever the fast lands', () {
      final c = cal();
      var found = 0;

      for (var day = 1; day <= 29; day++) {
        c.setJewishDate(5784, JewishDate.ADAR_II, day);
        final byIndex =
            c.getYomTovIndex() == JewishCalendar.FAST_OF_ESTHER;
        expect(c.isTaanisEsther(), equals(byIndex), reason: '$day Adar II');
        if (byIndex) found++;
      }

      expect(found, equals(1));
    });

    test('none of them answers for an ordinary day', () {
      final c = cal()..setJewishDate(5784, JewishDate.CHESHVAN, 12);
      expect(c.isErevPesach(), isFalse);
      expect(c.isErevYomKippur(), isFalse);
      expect(c.isHoshanaRabba(), isFalse);
      expect(c.isTaanisEsther(), isFalse);
      expect(c.isShushanPurim(), isFalse);
      expect(c.isPurimKatan(), isFalse);
      expect(c.isShushanPurimKatan(), isFalse);
    });

    test('purim katan is a leap year only', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.ADAR, 14)).isPurimKatan(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.ADAR, 15)).isShushanPurimKatan(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5783, JewishDate.ADAR, 14)).isPurimKatan(),
        isFalse,
      );
    });

    // isPurim answers the day Purim is kept, which a walled city keeps on the 15th.
    // isShushanPurim answers the 15th itself, whoever is asking.
    test('isShushanPurim is the day, isPurim is the observance', () {
      final open = cal()..setJewishDate(5784, JewishDate.ADAR_II, 15);
      expect(open.isShushanPurim(), isTrue);
      expect(open.isPurim(), isFalse);

      final walled = cal()
        ..isMukafChoma = true
        ..setJewishDate(5784, JewishDate.ADAR_II, 15);
      expect(walled.isShushanPurim(), isTrue);
      expect(walled.isPurim(), isTrue);
    });

    test('modern holidays answer only when they are turned on', () {
      final off = cal()
        ..setUseModernHolidays(false)
        ..setJewishDate(5784, JewishDate.IYAR, 6);
      expect(off.isYomHaatzmaut(), isFalse);

      final on = cal()
        ..setUseModernHolidays(true)
        ..setJewishDate(5784, JewishDate.IYAR, 6);
      expect(on.isYomHaatzmaut(), isTrue);
    });
  });

  group('JewishCalendar - periods', () {
    test('sefiras haomer spans the 49 days', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 15)).isSefirasHaomer(),
        isFalse,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 16)).isSefirasHaomer(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.SIVAN, 5)).isSefirasHaomer(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.SIVAN, 6)).isSefirasHaomer(),
        isFalse,
      );
    });

    test('ledavid runs from Elul through hoshana rabba', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.AV, 29)).isLeDavidPeriod(),
        isFalse,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.ELUL, 1)).isLeDavidPeriod(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 21)).isLeDavidPeriod(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 22)).isLeDavidPeriod(),
        isFalse,
      );
    });
  });

  group('JewishDate - day of week', () {
    test('exactly one predicate is true, and it is the one getDayOfWeek names', () {
      final c = cal()..setJewishDate(5784, JewishDate.TISHREI, 1);

      for (var day = 1; day <= 29; day++) {
        c.setJewishDate(5784, JewishDate.CHESHVAN, day);
        final answers = [
          c.isSunday(),
          c.isMonday(),
          c.isTuesday(),
          c.isWednesday(),
          c.isThursday(),
          c.isFriday(),
          c.isShabbos(),
        ];
        expect(answers.where((answer) => answer).length, equals(1),
            reason: '$day Cheshvan');
        expect(answers[c.getDayOfWeek() - 1], isTrue, reason: '$day Cheshvan');
        expect(c.isMondayOrThursday(), equals(c.isMonday() || c.isThursday()),
            reason: '$day Cheshvan');
      }
    });
  });

  group('TefilaRules - avinu malkeinu', () {
    test('said through the ten days and on a public fast', () {
      expect(
        rules.isAvinuMalkeinuRecited(
          cal()..setJewishDate(5784, JewishDate.TISHREI, 5),
        ),
        isTrue,
      );
      expect(
        rules.isAvinuMalkeinuRecited(
          cal()..setJewishDate(5784, JewishDate.TEVES, 10),
        ),
        isTrue,
      );
    });

    test('not said on tisha bav, which is a fast', () {
      final c = cal()..setJewishDate(5784, JewishDate.AV, 9);
      expect(c.isTaanis(), isTrue);
      expect(rules.isAvinuMalkeinuRecited(c), isFalse);
    });

    test('not said on shabbos, even inside the ten days', () {
      final c = cal();
      for (var day = 1; day <= 10; day++) {
        c.setJewishDate(5784, JewishDate.TISHREI, day);
        if (!c.isShabbos()) continue;
        expect(c.isAseresYemeiTeshuva(), isTrue);
        expect(rules.isAvinuMalkeinuRecited(c), isFalse);
        return;
      }
      fail('no shabbos in the ten days of 5784');
    });

    test('not said on an ordinary day', () {
      expect(
        rules.isAvinuMalkeinuRecited(
          cal()..setJewishDate(5784, JewishDate.CHESHVAN, 12),
        ),
        isFalse,
      );
    });
  });

  group('TefilaRules - long tachanun', () {
    test('a Monday or Thursday that says tachanun at all, and no other day', () {
      final c = cal();
      for (var day = 1; day <= 29; day++) {
        c.setJewishDate(5784, JewishDate.CHESHVAN, day);
        expect(
          rules.isLongTachanunRecited(c),
          equals(c.isMondayOrThursday() && rules.isTachanunRecitedShacharis(c)),
          reason: '$day Cheshvan',
        );
      }
    });

    test('never on rosh chodesh', () {
      final c = cal()..setJewishDate(5784, JewishDate.CHESHVAN, 1);
      expect(c.isRoshChodesh(), isTrue);
      expect(rules.isLongTachanunRecited(c), isFalse);
    });
  });

  group('TefilaRules - mussaf', () {
    test('said on rosh chodesh, yom tov, yom kippur and chol hamoed', () {
      for (final date in [
        [JewishDate.CHESHVAN, 1],
        [JewishDate.TISHREI, 15],
        [JewishDate.TISHREI, 18],
        [JewishDate.TISHREI, 10],
      ]) {
        final c = cal()..setJewishDate(5784, date[0], date[1]);
        expect(rules.isMussafRecited(c), isTrue, reason: '$date');
      }
    });

    test('not said on chanukah, purim or an ordinary weekday', () {
      for (final date in [
        [JewishDate.KISLEV, 25],
        [JewishDate.ADAR_II, 14],
        [JewishDate.CHESHVAN, 12],
      ]) {
        final c = cal()..setJewishDate(5784, date[0], date[1]);
        if (c.isShabbos()) continue;
        expect(rules.isMussafRecited(c), isFalse, reason: '$date');
      }
    });

    test('said on every shabbos', () {
      final c = cal();
      for (var day = 1; day <= 29; day++) {
        c.setJewishDate(5784, JewishDate.CHESHVAN, day);
        if (!c.isShabbos()) continue;
        expect(rules.isMussafRecited(c), isTrue, reason: '$day Cheshvan');
      }
    });
  });
}
