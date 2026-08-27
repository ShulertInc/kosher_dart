/// Coverage for [TefilaRules].
///
/// The first two groups are KosherJava's own `TefilaRulesTest`, assertion for assertion, so
/// this port can be checked against the library it came from. Its second case is named
/// `firstDayOfSukkos` there, but 7 October 2023 is 22 Tishrei - Shemini Atzeres outside
/// Israel - which is what its assertions describe, so it is named for the day it is.
///
/// The groups after them cover the three predicates this port was missing:
/// [TefilaRules.isAlHanissimRecited], [TefilaRules.isYaalehVeyavoRecited] and
/// [TefilaRules.isMizmorLesodaRecited].
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  final rules = TefilaRules();

  // ────────────────────────────────────────────────────────────────
  // KosherJava TefilaRulesTest, ported
  // ────────────────────────────────────────────────────────────────
  group('TefilaRules - ordinary summer weekday (21 August 2023)', () {
    final date = JewishCalendar.fromDateTime(DateTime(2023, 8, 21));

    test('tachanun is recited', () {
      expect(rules.isTachanunRecitedShacharis(date), isTrue);
      expect(rules.isTachanunRecitedMincha(date), isTrue);
    });

    test('vesein beracha, not vesein tal umatar', () {
      expect(rules.isVeseinTalUmatarStartDate(date), isFalse);
      expect(rules.isVeseinTalUmatarStartingTonight(date), isFalse);
      expect(rules.isVeseinTalUmatarRecited(date), isFalse);
      expect(rules.isVeseinBerachaRecited(date), isTrue);
    });

    test('morid hatal, not mashiv haruach', () {
      expect(rules.isMashivHaruachStartDate(date), isFalse);
      expect(rules.isMashivHaruachEndDate(date), isFalse);
      expect(rules.isMashivHaruachRecited(date), isFalse);
      expect(rules.isMoridHatalRecited(date), isTrue);
    });

    test('no hallel', () {
      expect(rules.isHallelRecited(date), isFalse);
      expect(rules.isHallelShalemRecited(date), isFalse);
    });

    test('no al hanissim, no yaaleh vyavo, mizmor lesoda is said', () {
      expect(rules.isAlHanissimRecited(date), isFalse);
      expect(rules.isYaalehVeyavoRecited(date), isFalse);
      expect(rules.isMizmorLesodaRecited(date), isTrue);
    });
  });

  group('TefilaRules - Shemini Atzeres (7 October 2023)', () {
    final date = JewishCalendar.fromDateTime(DateTime(2023, 10, 7));

    test('no tachanun', () {
      expect(rules.isTachanunRecitedShacharis(date), isFalse);
      expect(rules.isTachanunRecitedMincha(date), isFalse);
    });

    test('mashiv haruach starts today but is not yet said', () {
      expect(rules.isMashivHaruachStartDate(date), isTrue);
      expect(rules.isMashivHaruachEndDate(date), isFalse);
      expect(rules.isMashivHaruachRecited(date), isFalse);
      expect(rules.isMoridHatalRecited(date), isTrue);
    });

    test('vesein beracha, not vesein tal umatar', () {
      expect(rules.isVeseinTalUmatarStartDate(date), isFalse);
      expect(rules.isVeseinTalUmatarStartingTonight(date), isFalse);
      expect(rules.isVeseinTalUmatarRecited(date), isFalse);
      expect(rules.isVeseinBerachaRecited(date), isTrue);
    });

    test('whole hallel', () {
      expect(rules.isHallelRecited(date), isTrue);
      expect(rules.isHallelShalemRecited(date), isTrue);
    });

    test('yaaleh vyavo but no al hanissim, and no mizmor lesoda', () {
      expect(rules.isAlHanissimRecited(date), isFalse);
      expect(rules.isYaalehVeyavoRecited(date), isTrue);
      expect(rules.isMizmorLesodaRecited(date), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────
  // The three predicates this port was missing
  // ────────────────────────────────────────────────────────────────
  group('TefilaRules - al hanissim', () {
    JewishCalendar cal() => JewishCalendar()..inIsrael = false;

    test('said on Chanukah', () {
      final c = cal()..setJewishDate(5784, JewishDate.KISLEV, 25);
      expect(rules.isAlHanissimRecited(c), isTrue);
    });

    test('said on Purim', () {
      final c = cal()..setJewishDate(5784, JewishDate.ADAR_II, 14);
      expect(rules.isAlHanissimRecited(c), isTrue);
    });

    test('not said on Shushan Purim in an unwalled city', () {
      final c = cal()..setJewishDate(5784, JewishDate.ADAR_II, 15);
      expect(rules.isAlHanissimRecited(c), isFalse);
    });

    test('said on Shushan Purim in a walled city', () {
      final c = cal()
        ..isMukafChoma = true
        ..setJewishDate(5784, JewishDate.ADAR_II, 15);
      expect(rules.isAlHanissimRecited(c), isTrue);
    });

    test('not said on an ordinary day', () {
      final c = cal()..setJewishDate(5784, JewishDate.CHESHVAN, 12);
      expect(rules.isAlHanissimRecited(c), isFalse);
    });
  });

  group('TefilaRules - yaaleh vyavo', () {
    JewishCalendar diaspora() => JewishCalendar()..inIsrael = false;
    JewishCalendar israel() => JewishCalendar()..inIsrael = true;

    test('said on rosh chodesh', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.CHESHVAN, 1);
      expect(rules.isYaalehVeyavoRecited(c), isTrue);
    });

    test('said through Pesach, yom tov and chol hamoed alike', () {
      for (final day in [15, 17, 21]) {
        final c = diaspora()..setJewishDate(5784, JewishDate.NISSAN, day);
        expect(rules.isYaalehVeyavoRecited(c), isTrue, reason: '$day Nisan');
      }
    });

    test('said on hoshana rabba', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.TISHREI, 21);
      expect(rules.isYaalehVeyavoRecited(c), isTrue);
    });

    test('said on shemini atzeres and simchas torah', () {
      expect(
        rules.isYaalehVeyavoRecited(
          diaspora()..setJewishDate(5784, JewishDate.TISHREI, 22),
        ),
        isTrue,
      );
      expect(
        rules.isYaalehVeyavoRecited(
          diaspora()..setJewishDate(5784, JewishDate.TISHREI, 23),
        ),
        isTrue,
      );
      expect(
        rules.isYaalehVeyavoRecited(
          israel()..setJewishDate(5784, JewishDate.TISHREI, 22),
        ),
        isTrue,
      );
    });

    test('said on Shavuos, Rosh Hashana and Yom Kippur', () {
      expect(
        rules.isYaalehVeyavoRecited(
          diaspora()..setJewishDate(5784, JewishDate.SIVAN, 6),
        ),
        isTrue,
      );
      expect(
        rules.isYaalehVeyavoRecited(
          diaspora()..setJewishDate(5784, JewishDate.TISHREI, 1),
        ),
        isTrue,
      );
      expect(
        rules.isYaalehVeyavoRecited(
          diaspora()..setJewishDate(5784, JewishDate.TISHREI, 10),
        ),
        isTrue,
      );
    });

    test('not said on erev pesach, chanukah or an ordinary day', () {
      expect(
        rules.isYaalehVeyavoRecited(
          diaspora()..setJewishDate(5784, JewishDate.NISSAN, 14),
        ),
        isFalse,
      );
      expect(
        rules.isYaalehVeyavoRecited(
          diaspora()..setJewishDate(5784, JewishDate.KISLEV, 25),
        ),
        isFalse,
      );
      expect(
        rules.isYaalehVeyavoRecited(
          diaspora()..setJewishDate(5784, JewishDate.CHESHVAN, 12),
        ),
        isFalse,
      );
    });
  });

  group('TefilaRules - mizmor lesoda', () {
    JewishCalendar cal() => JewishCalendar()..inIsrael = false;

    test('said on an ordinary weekday', () {
      final c = cal()..setJewishDate(5784, JewishDate.CHESHVAN, 12);
      expect(rules.isMizmorLesodaRecited(c), isTrue);
    });

    test('not said on a day work is forbidden', () {
      final c = cal()..setJewishDate(5784, JewishDate.TISHREI, 15);
      expect(rules.isMizmorLesodaRecited(c), isFalse);
    });

    test('not said on erev yom kippur, erev pesach or chol hamoed pesach', () {
      for (final date in [
        [JewishDate.TISHREI, 9],
        [JewishDate.NISSAN, 14],
        [JewishDate.NISSAN, 18],
      ]) {
        final c = cal()..setJewishDate(5784, date[0], date[1]);
        expect(rules.isMizmorLesodaRecited(c), isFalse, reason: '$date');
      }
    });

    test('said on those days when the minhag says so', () {
      final saying = TefilaRules(mizmorLesodaRecitedErevYomKippurAndPesach: true);
      final c = cal()..setJewishDate(5784, JewishDate.NISSAN, 14);
      expect(saying.isMizmorLesodaRecited(c), isTrue);
    });

    test('the minhag does not override a day work is forbidden', () {
      final saying = TefilaRules(mizmorLesodaRecitedErevYomKippurAndPesach: true);
      final c = cal()..setJewishDate(5784, JewishDate.TISHREI, 15);
      expect(saying.isMizmorLesodaRecited(c), isFalse);
    });
  });
}
