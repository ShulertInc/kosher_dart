/// Coverage for the days KosherJava keeps out of `isYomTov`, and for the predicates the
/// published package never carried across.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  JewishCalendar cal({bool inIsrael = false}) =>
      JewishCalendar()..setInIsrael(inIsrael);

  group('isYomTov', () {
    // Erev yom tov is not yom tov, and the fork read the test the other way round: it
    // required the day to be chol hamoed Pesach before excluding it, so erev Pesach, erev
    // Shavuos and erev Succos all answered true.
    test('erev yom tov answers false', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 14)).isYomTov(),
        isFalse,
        reason: 'erev Pesach',
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.SIVAN, 5)).isYomTov(),
        isFalse,
        reason: 'erev Shavuos',
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 14)).isYomTov(),
        isFalse,
        reason: 'erev Succos',
      );
    });

    // The two days erev yom tov is kept in: Hoshana Rabba, and erev the last day of Pesach,
    // both of which are chol hamoed in their own right.
    test('Hoshana Rabba and erev the last day of Pesach answer true', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 21)).isYomTov(),
        isTrue,
        reason: 'Hoshana Rabba',
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 20)).isYomTov(),
        isTrue,
        reason: 'erev the seventh day of Pesach',
      );
    });

    test('isru chag answers false', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 23)).isYomTov(),
        isFalse,
        reason: 'isru chag Pesach out of Israel',
      );
      expect(
        (cal(inIsrael: true)..setJewishDate(5784, JewishDate.NISSAN, 22))
            .isYomTov(),
        isFalse,
        reason: 'isru chag Pesach in Israel',
      );
    });

    test('a public fast answers false, and Yom Kippur answers true', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.TEVES, 10)).isYomTov(),
        isFalse,
        reason: 'Asara b\'Teves',
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 10)).isYomTov(),
        isTrue,
        reason: 'Yom Kippur',
      );
    });

    test('yom tov itself and chol hamoed answer true', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 15)).isYomTov(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 17)).isYomTov(),
        isTrue,
      );
    });
  });

  // The days a siddur means by ביו"ט: yom tov proper, and neither chol hamoed nor the
  // minor days isYomTov also answers.
  group('isYomTovAssurBemelacha', () {
    test('true on yom tov, false on chol hamoed and the minor days', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 15))
            .isYomTovAssurBemelacha(),
        isTrue,
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.NISSAN, 17))
            .isYomTovAssurBemelacha(),
        isFalse,
        reason: 'chol hamoed Pesach',
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.KISLEV, 26))
            .isYomTovAssurBemelacha(),
        isFalse,
        reason: 'Chanukah',
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 1))
            .isYomTovAssurBemelacha(),
        isTrue,
        reason: 'Rosh Hashanah',
      );
    });
  });

  group('isBeHaB', () {
    test('the Monday, Thursday and Monday after the first Shabbos', () {
      final c = cal();
      final days = <int>[];

      for (var day = 1; day <= 29; day++) {
        c.setJewishDate(5784, JewishDate.IYAR, day);
        if (c.isBeHaB()) days.add(day);
      }

      expect(days.length, equals(3));
      expect(
        (cal()..setJewishDate(5784, JewishDate.IYAR, days[0])).getDayOfWeek(),
        equals(2),
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.IYAR, days[1])).getDayOfWeek(),
        equals(5),
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.IYAR, days[2])).getDayOfWeek(),
        equals(2),
      );
    });

    test('no other month has one', () {
      final c = cal();
      for (final month in [JewishDate.SIVAN, JewishDate.KISLEV]) {
        for (var day = 1; day <= 29; day++) {
          c.setJewishDate(5784, month, day);
          expect(c.isBeHaB(), isFalse, reason: '$day of month $month');
        }
      }
    });
  });

  group('isYomKippurKatan', () {
    test('erev rosh chodesh, moved back off Friday and Shabbos', () {
      final c = cal();

      for (var month = 1; month <= 12; month++) {
        var found = 0;
        for (var day = 25; day <= 29; day++) {
          c.setJewishDate(5784, month, day);
          if (c.getJewishDayOfMonth() != day) continue;
          if (!c.isYomKippurKatan()) continue;

          found++;
          expect(
            c.getDayOfWeek(),
            isNot(6),
            reason: 'month $month',
          );
          expect(
            c.getDayOfWeek(),
            isNot(7),
            reason: 'month $month',
          );
        }

        final skipped = month == JewishDate.ELUL ||
            month == JewishDate.TISHREI ||
            month == JewishDate.KISLEV ||
            month == JewishDate.NISSAN;
        expect(found, equals(skipped ? 0 : 1), reason: 'month $month');
      }
    });
  });

  group('isTonightMutarBemelacha', () {
    test('true on the last day assur bemelacha, false on the first of two', () {
      // In 5784 the first day of Succos is Shabbos, so the two days run together and
      // melacha stays forbidden into the second.
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 15))
            .isTonightMutarBemelacha(),
        isFalse,
        reason: 'Shabbos that is also the first day of yom tov',
      );
      expect(
        (cal()..setJewishDate(5784, JewishDate.TISHREI, 16))
            .isTonightMutarBemelacha(),
        isTrue,
        reason: 'the second day, with chol hamoed after it',
      );
    });

    test('false on a weekday', () {
      expect(
        (cal()..setJewishDate(5784, JewishDate.CHESHVAN, 12))
            .isTonightMutarBemelacha(),
        isFalse,
      );
    });
  });

  group('the named fasts', () {
    test('each answers for its own fast alone', () {
      final gedalyah = cal()..setJewishDate(5784, JewishDate.TISHREI, 3);
      expect(gedalyah.isFastOfGedalyah(), isTrue);
      expect(gedalyah.isTenthOfTeves(), isFalse);
      expect(gedalyah.isTaanis(), isTrue);

      final teves = cal()..setJewishDate(5784, JewishDate.TEVES, 10);
      expect(teves.isTenthOfTeves(), isTrue);
      expect(teves.isFastOfGedalyah(), isFalse);

      final tammuz = cal()..setJewishDate(5784, JewishDate.TAMMUZ, 17);
      expect(tammuz.isSeventeenthOfTammuz(), isTrue);
      expect(tammuz.isFastOfGedalyah(), isFalse);
    });

    test('Tzom Gedalyah moves off Shabbos', () {
      final c = cal();
      var found = 0;

      for (var day = 3; day <= 4; day++) {
        c.setJewishDate(5785, JewishDate.TISHREI, day);
        expect(
          c.isFastOfGedalyah(),
          equals(c.getYomTovIndex() == JewishCalendar.FAST_OF_GEDALYAH),
          reason: '$day Tishrei',
        );
        if (c.isFastOfGedalyah()) found++;
      }

      expect(found, equals(1));
    });
  });

  group('isEruvTavshilin', () {
    bool eruv(int year, int month, int day, {required bool inIsrael}) =>
        (cal(inIsrael: inIsrael)..setJewishDate(year, month, day))
            .isEruvTavshilin();

    test('before a yom tov that runs into Shabbos, everywhere', () {
      for (final inIsrael in [false, true]) {
        expect(eruv(5784, JewishDate.ELUL, 29, inIsrael: inIsrael), isTrue,
            reason: 'Rosh Hashana on Thursday and Friday');
        expect(eruv(5782, JewishDate.NISSAN, 20, inIsrael: inIsrael), isTrue,
            reason: 'the seventh day of Pesach on Friday');
        expect(eruv(5786, JewishDate.SIVAN, 5, inIsrael: inIsrael), isTrue,
            reason: 'Shavuos on Friday');
      }
    });

    test('before a Thursday yom tov only where it lasts two days', () {
      expect(eruv(5785, JewishDate.TISHREI, 14, inIsrael: false), isTrue);
      expect(eruv(5785, JewishDate.TISHREI, 14, inIsrael: true), isFalse);
      expect(eruv(5785, JewishDate.TISHREI, 21, inIsrael: false), isTrue);
      expect(eruv(5785, JewishDate.TISHREI, 21, inIsrael: true), isFalse);
      expect(eruv(5786, JewishDate.NISSAN, 14, inIsrael: false), isTrue);
      expect(eruv(5786, JewishDate.NISSAN, 14, inIsrael: true), isFalse);
    });

    test('never on the yom tov itself', () {
      expect(eruv(5785, JewishDate.TISHREI, 15, inIsrael: false), isFalse);
      expect(eruv(5785, JewishDate.TISHREI, 1, inIsrael: false), isFalse);
    });

    test('not before a yom tov that ends before Friday', () {
      expect(eruv(5785, JewishDate.TISHREI, 9, inIsrael: false), isFalse,
          reason: 'erev Yom Kippur');
      expect(eruv(5784, JewishDate.NISSAN, 14, inIsrael: false), isFalse,
          reason: 'Pesach on Tuesday');
      expect(eruv(5784, JewishDate.CHESHVAN, 11, inIsrael: false), isFalse,
          reason: 'an ordinary Thursday');
    });
  });
}
