/// Comprehensive unit tests for [JewishCalendar].
///
/// Covers the following areas with a focus on edge cases:
///
/// - **Holidays outside Israel** — verifies [JewishCalendar.getYomTovIndex]
///   for every major holiday (Erev Pesach, Pesach, Chol Hamoed Pesach,
///   Shavuos, Rosh Hashana, Yom Kippur, Succos, Hoshana Rabba, Shemini
///   Atzeret, Chanukah days 1 and 8, Purim, Purim Katan, Tu BeShvat,
///   Tisha BeAv) and confirms that a plain weekday returns -1.
///
/// - **Modern Israeli holidays (postponement rules)** — verifies correct
///   handling of Yom Hazikaron and Yom Ha'atzmaut for all postponement
///   scenarios: standard (Wednesday), Friday→Thursday, Saturday→Thursday,
///   and Monday→Tuesday.
///
/// - **Holidays inside Israel** — checks cases where the Israel schedule
///   differs from the Diaspora (e.g. 16 Nisan is Chol Hamoed in Israel vs.
///   a second day of Pesach outside Israel; 22 Tishrei behaviour).
///
/// - **Leap year Adar edge cases** — verifies that on a leap year 14 Adar I
///   is Purim Katan (not Purim), while 14 Adar II is Purim; and that on a
///   non-leap year 14 Adar is simply Purim.
///
/// - **isYomTov / isCholHamoed helpers** — tests [JewishCalendar.isYomTovAssurBemelacha]
///   and [JewishCalendar.isCholHamoed] for Pesach and regular days.
///
/// - **Shabbat detection** — verifies day-of-week values for known
///   Saturdays and Sundays.
///
/// - **Rosh Chodesh** — checks [JewishCalendar.isRoshChodesh] for the 1st
///   and 30th of a 30-day month, and a non-Rosh-Chodesh date.
///
/// - **Omer counting** — verifies [JewishCalendar.getDayOfOmer] returns the
///   correct count on day 1 (16 Nisan), day 33 (Lag BaOmer, 18 Iyar),
///   day 49 (5 Sivan), and -1 outside the Omer period.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  // ────────────────────────────────────────────────────────────────
  // Holidays - out of Israel
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - holidays (outside Israel)', () {
    JewishCalendar cal() => JewishCalendar()..inIsrael = false;

    test('Erev Pesach - 14 Nisan', () {
      final c = cal()..setJewishDate(5784, JewishDate.NISSAN, 14);
      expect(c.getYomTovIndex(), equals(JewishCalendar.EREV_PESACH));
    });

    test('Pesach - 15 Nisan', () {
      final c = cal()..setJewishDate(5784, JewishDate.NISSAN, 15);
      expect(c.getYomTovIndex(), equals(JewishCalendar.PESACH));
    });

    test('Chol Hamoed Pesach - 17 Nisan (outside Israel)', () {
      final c = cal()..setJewishDate(5784, JewishDate.NISSAN, 17);
      expect(c.getYomTovIndex(), equals(JewishCalendar.CHOL_HAMOED_PESACH));
    });

    test('Shavuos - 6 Sivan', () {
      final c = cal()..setJewishDate(5784, JewishDate.SIVAN, 6);
      expect(c.getYomTovIndex(), equals(JewishCalendar.SHAVUOS));
    });

    test('Rosh Hashana - 1 Tishrei', () {
      final c = cal()..setJewishDate(5784, JewishDate.TISHREI, 1);
      expect(c.getYomTovIndex(), equals(JewishCalendar.ROSH_HASHANA));
    });

    test('Yom Kippur - 10 Tishrei', () {
      final c = cal()..setJewishDate(5784, JewishDate.TISHREI, 10);
      expect(c.getYomTovIndex(), equals(JewishCalendar.YOM_KIPPUR));
    });

    test('Succos - 15 Tishrei', () {
      final c = cal()..setJewishDate(5784, JewishDate.TISHREI, 15);
      expect(c.getYomTovIndex(), equals(JewishCalendar.SUCCOS));
    });

    test('Hoshana Rabba - 21 Tishrei', () {
      final c = cal()..setJewishDate(5784, JewishDate.TISHREI, 21);
      expect(c.getYomTovIndex(), equals(JewishCalendar.HOSHANA_RABBA));
    });

    test('Shemini Atzeret - 22 Tishrei (outside Israel)', () {
      final c = cal()..setJewishDate(5784, JewishDate.TISHREI, 22);
      expect(c.getYomTovIndex(), equals(JewishCalendar.SHEMINI_ATZERES));
    });

    test('Chanukah - 25 Kislev', () {
      final c = cal()..setJewishDate(5784, JewishDate.KISLEV, 25);
      expect(c.getYomTovIndex(), equals(JewishCalendar.CHANUKAH));
    });

    test('Chanukah day 8 - 2 Tevet (in non-short Kislev years)', () {
      // 5784 Kislev is full (30 days), so day 8 of Chanukah = 2 Tevet
      final c = cal()..setJewishDate(5784, JewishDate.TEVES, 2);
      expect(c.getYomTovIndex(), equals(JewishCalendar.CHANUKAH));
    });

    test('Purim - 14 Adar (non-leap year)', () {
      // 5785 is a non-leap year
      final c = cal()..setJewishDate(5785, JewishDate.ADAR, 14);
      expect(c.getYomTovIndex(), equals(JewishCalendar.PURIM));
    });

    test('Purim - 14 Adar II (leap year)', () {
      // 5784 is a leap year - Purim falls on Adar II
      final c = cal()..setJewishDate(5784, JewishDate.ADAR_II, 14);
      expect(c.getYomTovIndex(), equals(JewishCalendar.PURIM));
    });

    test('Purim Katan - 14 Adar I (leap year)', () {
      // 5784 is a leap year - Purim Katan is 14 Adar I
      final c = cal()..setJewishDate(5784, JewishDate.ADAR, 14);
      expect(c.getYomTovIndex(), equals(JewishCalendar.PURIM_KATAN));
    });

    test('Tu BeShvat - 15 Shevat', () {
      final c = cal()..setJewishDate(5784, JewishDate.SHEVAT, 15);
      expect(c.getYomTovIndex(), equals(JewishCalendar.TU_BESHVAT));
    });

    test('Tisha BeAv - 9 Av', () {
      final c = cal()..setJewishDate(5784, JewishDate.AV, 9);
      expect(c.getYomTovIndex(), equals(JewishCalendar.TISHA_BEAV));
    });

    test('Regular day has no Yom Tov', () {
      final c = cal()..setJewishDate(5784, JewishDate.NISSAN, 5);
      expect(c.getYomTovIndex(), equals(-1));
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Holidays - in Israel (different rules)
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - holidays (inside Israel)', () {
    JewishCalendar cal() => JewishCalendar()..inIsrael = true;

    test('Pesach in Israel: 16 Nisan is Chol Hamoed (not second Yom Tov)', () {
      final c = cal()..setJewishDate(5784, JewishDate.NISSAN, 16);
      expect(c.getYomTovIndex(), equals(JewishCalendar.CHOL_HAMOED_PESACH));
    });

    test(
        'Shemini Atzeret in Israel: 22 Tishrei is Shemini Atzeret (code returns SHEMINI_ATZERES for both)',
        () {
      // In Israel, 22 Tishrei is both Shemini Atzeret and Simchat Torah,
      // but the implementation returns SHEMINI_ATZERES for 22 Tishrei regardless.
      // SIMCHAS_TORAH (19) is only returned for 23 Tishrei outside Israel.
      final c = cal()..setJewishDate(5784, JewishDate.TISHREI, 22);
      expect(c.getYomTovIndex(), equals(JewishCalendar.SHEMINI_ATZERES));
    });
  });

  // ────────────────────────────────────────────────────────────────
  // isYomTov / isCholHamoed helpers
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - isYomTov / isCholHamoed', () {
    test('Pesach day 1 isYomTov returns true', () {
      final c = JewishCalendar()..setJewishDate(5784, JewishDate.NISSAN, 15);
      expect(c.isYomTovAssurBemelacha(), isTrue);
    });

    test('Chol Hamoed Pesach isYomTov returns false (work is permitted)', () {
      final c = JewishCalendar()
        ..inIsrael = false
        ..setJewishDate(5784, JewishDate.NISSAN, 17);
      expect(c.isYomTovAssurBemelacha(), isFalse);
    });

    test('isCholHamoed returns true during Chol Hamoed Pesach', () {
      final c = JewishCalendar()
        ..inIsrael = false
        ..setJewishDate(5784, JewishDate.NISSAN, 17);
      expect(c.isCholHamoed(), isTrue);
    });

    test('isCholHamoed returns false on regular weekday', () {
      final c = JewishCalendar()..setJewishDate(5784, JewishDate.NISSAN, 5);
      expect(c.isCholHamoed(), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Shabbat detection
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - Shabbat', () {
    test('isShabbos returns true on a known Saturday', () {
      // Sep 16, 2023 = Rosh Hashana 5784 = Saturday
      final c = JewishCalendar.fromDateTime(DateTime(2023, 9, 16));
      expect(c.getDayOfWeek(), equals(JewishDate.saturday));
    });

    test('isShabbos returns false on a known Sunday', () {
      // Sep 17, 2023 = 2 Tishrei 5784 = Sunday
      final c = JewishCalendar.fromDateTime(DateTime(2023, 9, 17));
      expect(c.getDayOfWeek(), equals(JewishDate.sunday));
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Rosh Chodesh
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - Rosh Chodesh', () {
    test('1st of Cheshvan is Rosh Chodesh', () {
      final c = JewishCalendar()..setJewishDate(5784, JewishDate.CHESHVAN, 1);
      expect(c.isRoshChodesh(), isTrue);
    });

    test('30th of Tishrei is Rosh Chodesh (30-day month)', () {
      final c = JewishCalendar()..setJewishDate(5784, JewishDate.TISHREI, 30);
      expect(c.isRoshChodesh(), isTrue);
    });

    test('15th of Nissan is NOT Rosh Chodesh', () {
      final c = JewishCalendar()..setJewishDate(5784, JewishDate.NISSAN, 15);
      expect(c.isRoshChodesh(), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Omer
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - Omer', () {
    test('getDayOfOmer returns 1 on 16 Nisan', () {
      final c = JewishCalendar()..setJewishDate(5784, JewishDate.NISSAN, 16);
      expect(c.getDayOfOmer(), equals(1));
    });

    test('getDayOfOmer returns 33 on Lag BaOmer (18 Iyar)', () {
      final c = JewishCalendar()..setJewishDate(5784, JewishDate.IYAR, 18);
      expect(c.getDayOfOmer(), equals(33));
    });

    test('getDayOfOmer returns 49 on 5 Sivan (day before Shavuos)', () {
      final c = JewishCalendar()..setJewishDate(5784, JewishDate.SIVAN, 5);
      expect(c.getDayOfOmer(), equals(49));
    });

    test('getDayOfOmer returns -1 outside Omer period', () {
      final c = JewishCalendar()..setJewishDate(5784, JewishDate.TISHREI, 1);
      expect(c.getDayOfOmer(), equals(-1));
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Leap year edge case: Adar I vs Adar II holidays
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - leap year Adar edge cases', () {
    test('On a leap year, 14 Adar I is Purim Katan not Purim', () {
      final c = JewishCalendar()
        ..inIsrael = false
        ..setJewishDate(5784, JewishDate.ADAR, 14); // Adar I
      expect(c.getYomTovIndex(), equals(JewishCalendar.PURIM_KATAN));
      expect(c.getYomTovIndex(), isNot(equals(JewishCalendar.PURIM)));
    });

    test('On a non-leap year, 14 Adar is Purim', () {
      final c = JewishCalendar()
        ..inIsrael = false
        ..setJewishDate(5785, JewishDate.ADAR, 14); // only Adar
      expect(c.getYomTovIndex(), equals(JewishCalendar.PURIM));
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Modern holidays: Yom Hazikaron & Yom Ha'atzmaut postponements
  //
  // 5 Iyar can only fall on Wed/Fri/Sat/Mon in the Hebrew calendar.
  // Postponement rules:
  //   Wed  → no change (5 Iyar = Yom Ha'atzmaut)
  //   Fri  → moved back 1 day to 4 Iyar (Thursday)
  //   Sat  → moved back 2 days to 3 Iyar (Thursday)
  //   Mon  → moved forward 1 day to 6 Iyar (Tuesday)   ← Issue #42
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - Yom Hazikaron & Yom Ha\'atzmaut postponements', () {
    JewishCalendar cal() => JewishCalendar()
      ..inIsrael = true
      ..setUseModernHolidays(true);

    // ── 5783: 5 Iyar = Wednesday (standard, no postponement) ──────
    // 15 Nissan 5783 = Thursday → 5 Iyar 5783 = Wednesday
    test('5783: Yom Hazikaron on 4 Iyar (Tuesday) when 5 Iyar is Wednesday',
        () {
      final c = cal()..setJewishDate(5783, JewishDate.IYAR, 4);
      expect(c.getYomTovIndex(), equals(JewishCalendar.YOM_HAZIKARON));
    });

    test('5783: Yom Ha\'atzmaut on 5 Iyar (Wednesday) — standard case', () {
      final c = cal()..setJewishDate(5783, JewishDate.IYAR, 5);
      expect(c.getYomTovIndex(), equals(JewishCalendar.YOM_HAATZMAUT));
    });

    // ── 5782: 5 Iyar = Friday → moved back to 4 Iyar (Thursday) ──
    // 15 Nissan 5782 = Saturday → 5 Iyar 5782 = Friday
    test('5782: Yom Hazikaron on 3 Iyar (Wednesday) when 5 Iyar is Friday', () {
      final c = cal()..setJewishDate(5782, JewishDate.IYAR, 3);
      expect(c.getYomTovIndex(), equals(JewishCalendar.YOM_HAZIKARON));
    });

    test('5782: Yom Ha\'atzmaut on 4 Iyar (Thursday) when 5 Iyar is Friday',
        () {
      final c = cal()..setJewishDate(5782, JewishDate.IYAR, 4);
      expect(c.getYomTovIndex(), equals(JewishCalendar.YOM_HAATZMAUT));
    });

    test('5782: 5 Iyar itself (Friday) is not Yom Ha\'atzmaut', () {
      final c = cal()..setJewishDate(5782, JewishDate.IYAR, 5);
      expect(c.getYomTovIndex(), isNot(equals(JewishCalendar.YOM_HAATZMAUT)));
    });

    // ── 5781: 5 Iyar = Saturday → moved back to 3 Iyar (Thursday) ─
    // 15 Nissan 5781 = Sunday → 5 Iyar 5781 = Saturday
    test('5781: Yom Hazikaron on 2 Iyar (Wednesday) when 5 Iyar is Saturday',
        () {
      final c = cal()..setJewishDate(5781, JewishDate.IYAR, 2);
      expect(c.getYomTovIndex(), equals(JewishCalendar.YOM_HAZIKARON));
    });

    test('5781: Yom Ha\'atzmaut on 3 Iyar (Thursday) when 5 Iyar is Saturday',
        () {
      final c = cal()..setJewishDate(5781, JewishDate.IYAR, 3);
      expect(c.getYomTovIndex(), equals(JewishCalendar.YOM_HAATZMAUT));
    });

    test('5781: 5 Iyar itself (Saturday) is not Yom Ha\'atzmaut', () {
      final c = cal()..setJewishDate(5781, JewishDate.IYAR, 5);
      expect(c.getYomTovIndex(), isNot(equals(JewishCalendar.YOM_HAATZMAUT)));
    });

    // ── 5784: 5 Iyar = Monday → moved forward to 6 Iyar (Tuesday) ─
    // This is the case reported in issue #42 (תשפ״ד).
    // 15 Nissan 5784 = Tuesday → 5 Iyar 5784 = Monday
    test('5784: Yom Hazikaron on 5 Iyar (Monday) when 5 Iyar falls on Monday',
        () {
      final c = cal()..setJewishDate(5784, JewishDate.IYAR, 5);
      expect(c.getYomTovIndex(), equals(JewishCalendar.YOM_HAZIKARON));
    });

    test(
        '5784: Yom Ha\'atzmaut on 6 Iyar (Tuesday) when 5 Iyar falls on Monday — issue #42',
        () {
      final c = cal()..setJewishDate(5784, JewishDate.IYAR, 6);
      expect(c.getYomTovIndex(), equals(JewishCalendar.YOM_HAATZMAUT));
    });

    test('5784: 5 Iyar (Monday) is Yom Hazikaron, not Yom Ha\'atzmaut', () {
      final c = cal()..setJewishDate(5784, JewishDate.IYAR, 5);
      expect(c.getYomTovIndex(), isNot(equals(JewishCalendar.YOM_HAATZMAUT)));
    });

    // ── Verify useModernHolidays=false returns no modern holidays ──
    test('Modern holidays not returned when useModernHolidays is false', () {
      final c = JewishCalendar()
        ..inIsrael = true
        ..setUseModernHolidays(false)
        ..setJewishDate(5784, JewishDate.IYAR, 6);
      expect(c.getYomTovIndex(), isNot(equals(JewishCalendar.YOM_HAATZMAUT)));
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Isru chag
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - isru chag', () {
    JewishCalendar diaspora() => JewishCalendar()..inIsrael = false;
    JewishCalendar israel() => JewishCalendar()..inIsrael = true;

    test('22 Nisan is isru chag in Israel', () {
      final c = israel()..setJewishDate(5784, JewishDate.NISSAN, 22);
      expect(c.getYomTovIndex(), equals(JewishCalendar.ISRU_CHAG));
      expect(c.isIsruChag(), isTrue);
    });

    test('23 Nisan is isru chag outside Israel', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.NISSAN, 23);
      expect(c.isIsruChag(), isTrue);
    });

    test('22 Nisan is still Pesach outside Israel', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.NISSAN, 22);
      expect(c.getYomTovIndex(), equals(JewishCalendar.PESACH));
      expect(c.isIsruChag(), isFalse);
    });

    test('7 Sivan is isru chag in Israel', () {
      final c = israel()..setJewishDate(5784, JewishDate.SIVAN, 7);
      expect(c.isIsruChag(), isTrue);
    });

    test('7 Sivan is still Shavuos outside Israel', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.SIVAN, 7);
      expect(c.getYomTovIndex(), equals(JewishCalendar.SHAVUOS));
      expect(c.isIsruChag(), isFalse);
    });

    test('8 Sivan is isru chag outside Israel', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.SIVAN, 8);
      expect(c.isIsruChag(), isTrue);
    });

    test('23 Tishrei is isru chag in Israel', () {
      final c = israel()..setJewishDate(5784, JewishDate.TISHREI, 23);
      expect(c.isIsruChag(), isTrue);
    });

    test('23 Tishrei is still Simchas Torah outside Israel', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.TISHREI, 23);
      expect(c.getYomTovIndex(), equals(JewishCalendar.SIMCHAS_TORAH));
      expect(c.isIsruChag(), isFalse);
    });

    test('24 Tishrei is isru chag outside Israel', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.TISHREI, 24);
      expect(c.isIsruChag(), isTrue);
    });

    // 15 Adar I of a leap year. It shared a constant value with isru chag, which is how
    // the two came to answer for each other.
    test('Shushan Purim Katan is not isru chag', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.ADAR, 15);
      expect(c.getYomTovIndex(), equals(JewishCalendar.SHUSHAN_PURIM_KATAN));
      expect(c.isIsruChag(), isFalse);
    });

    test('isru chag and Shushan Purim Katan are different days', () {
      expect(
        JewishCalendar.ISRU_CHAG,
        isNot(equals(JewishCalendar.SHUSHAN_PURIM_KATAN)),
      );
    });

    test('an ordinary day is not isru chag', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.CHESHVAN, 12);
      expect(c.isIsruChag(), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Holiday index values, against KosherJava
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - holiday indexes match KosherJava', () {
    // Every index KosherJava defines, and nothing it does not, so a future port of one of
    // its methods can be taken across without checking the numbering first.
    const expected = <String, int>{
      'EREV_PESACH': 0,
      'PESACH': 1,
      'CHOL_HAMOED_PESACH': 2,
      'PESACH_SHENI': 3,
      'EREV_SHAVUOS': 4,
      'SHAVUOS': 5,
      'SEVENTEEN_OF_TAMMUZ': 6,
      'TISHA_BEAV': 7,
      'TU_BEAV': 8,
      'EREV_ROSH_HASHANA': 9,
      'ROSH_HASHANA': 10,
      'FAST_OF_GEDALYAH': 11,
      'EREV_YOM_KIPPUR': 12,
      'YOM_KIPPUR': 13,
      'EREV_SUCCOS': 14,
      'SUCCOS': 15,
      'CHOL_HAMOED_SUCCOS': 16,
      'HOSHANA_RABBA': 17,
      'SHEMINI_ATZERES': 18,
      'SIMCHAS_TORAH': 19,
      'CHANUKAH': 21,
      'TENTH_OF_TEVES': 22,
      'TU_BESHVAT': 23,
      'FAST_OF_ESTHER': 24,
      'PURIM': 25,
      'SHUSHAN_PURIM': 26,
      'PURIM_KATAN': 27,
      'ROSH_CHODESH': 28,
      'YOM_HASHOAH': 29,
      'YOM_HAZIKARON': 30,
      'YOM_HAATZMAUT': 31,
      'YOM_YERUSHALAYIM': 32,
      'LAG_BAOMER': 33,
      'SHUSHAN_PURIM_KATAN': 34,
      'ISRU_CHAG': 35,
    };

    final actual = <String, int>{
      'EREV_PESACH': JewishCalendar.EREV_PESACH,
      'PESACH': JewishCalendar.PESACH,
      'CHOL_HAMOED_PESACH': JewishCalendar.CHOL_HAMOED_PESACH,
      'PESACH_SHENI': JewishCalendar.PESACH_SHENI,
      'EREV_SHAVUOS': JewishCalendar.EREV_SHAVUOS,
      'SHAVUOS': JewishCalendar.SHAVUOS,
      'SEVENTEEN_OF_TAMMUZ': JewishCalendar.SEVENTEEN_OF_TAMMUZ,
      'TISHA_BEAV': JewishCalendar.TISHA_BEAV,
      'TU_BEAV': JewishCalendar.TU_BEAV,
      'EREV_ROSH_HASHANA': JewishCalendar.EREV_ROSH_HASHANA,
      'ROSH_HASHANA': JewishCalendar.ROSH_HASHANA,
      'FAST_OF_GEDALYAH': JewishCalendar.FAST_OF_GEDALYAH,
      'EREV_YOM_KIPPUR': JewishCalendar.EREV_YOM_KIPPUR,
      'YOM_KIPPUR': JewishCalendar.YOM_KIPPUR,
      'EREV_SUCCOS': JewishCalendar.EREV_SUCCOS,
      'SUCCOS': JewishCalendar.SUCCOS,
      'CHOL_HAMOED_SUCCOS': JewishCalendar.CHOL_HAMOED_SUCCOS,
      'HOSHANA_RABBA': JewishCalendar.HOSHANA_RABBA,
      'SHEMINI_ATZERES': JewishCalendar.SHEMINI_ATZERES,
      'SIMCHAS_TORAH': JewishCalendar.SIMCHAS_TORAH,
      'CHANUKAH': JewishCalendar.CHANUKAH,
      'TENTH_OF_TEVES': JewishCalendar.TENTH_OF_TEVES,
      'TU_BESHVAT': JewishCalendar.TU_BESHVAT,
      'FAST_OF_ESTHER': JewishCalendar.FAST_OF_ESTHER,
      'PURIM': JewishCalendar.PURIM,
      'SHUSHAN_PURIM': JewishCalendar.SHUSHAN_PURIM,
      'PURIM_KATAN': JewishCalendar.PURIM_KATAN,
      'ROSH_CHODESH': JewishCalendar.ROSH_CHODESH,
      'YOM_HASHOAH': JewishCalendar.YOM_HASHOAH,
      'YOM_HAZIKARON': JewishCalendar.YOM_HAZIKARON,
      'YOM_HAATZMAUT': JewishCalendar.YOM_HAATZMAUT,
      'YOM_YERUSHALAYIM': JewishCalendar.YOM_YERUSHALAYIM,
      'LAG_BAOMER': JewishCalendar.LAG_BAOMER,
      'SHUSHAN_PURIM_KATAN': JewishCalendar.SHUSHAN_PURIM_KATAN,
      'ISRU_CHAG': JewishCalendar.ISRU_CHAG,
    };

    test('every index KosherJava defines has the same value here', () {
      expect(actual, equals(expected));
    });

    test('no two holiday indexes share a value', () {
      final values = actual.values.toList();
      expect(values.toSet().length, equals(values.length));
    });
  });

  // ────────────────────────────────────────────────────────────────
  // Holiday helpers ported from KosherJava
  // ────────────────────────────────────────────────────────────────
  group('JewishCalendar - holiday helpers', () {
    JewishCalendar diaspora() => JewishCalendar()..inIsrael = false;
    JewishCalendar israel() => JewishCalendar()..inIsrael = true;

    test('isPesach covers yom tov and chol hamoed', () {
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.NISSAN, 15)).isPesach(),
        isTrue,
      );
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.NISSAN, 18)).isPesach(),
        isTrue,
      );
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.NISSAN, 14)).isPesach(),
        isFalse,
      );
    });

    test('isSuccos covers yom tov, chol hamoed and hoshana rabba', () {
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.TISHREI, 15)).isSuccos(),
        isTrue,
      );
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.TISHREI, 18)).isSuccos(),
        isTrue,
      );
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.TISHREI, 21)).isSuccos(),
        isTrue,
      );
    });

    test('shemini atzeres is not succos', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.TISHREI, 22);
      expect(c.isSuccos(), isFalse);
      expect(c.isShminiAtzeres(), isTrue);
    });

    // Hoshana Rabba is chol hamoed, and leaving it out hid the festival insertions of
    // that day.
    test('isCholHamoedSuccos includes hoshana rabba', () {
      final c = diaspora()..setJewishDate(5784, JewishDate.TISHREI, 21);
      expect(c.getYomTovIndex(), equals(JewishCalendar.HOSHANA_RABBA));
      expect(c.isCholHamoedSuccos(), isTrue);
      expect(c.isCholHamoed(), isTrue);
    });

    test('simchas torah is only outside Israel', () {
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.TISHREI, 23))
            .isSimchasTorah(),
        isTrue,
      );
      expect(
        (israel()..setJewishDate(5784, JewishDate.TISHREI, 23)).isSimchasTorah(),
        isFalse,
      );
    });

    test('isShavuos, isRoshHashana, isYomKippur, isTishaBav', () {
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.SIVAN, 6)).isShavuos(),
        isTrue,
      );
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.TISHREI, 1)).isRoshHashana(),
        isTrue,
      );
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.TISHREI, 10)).isYomKippur(),
        isTrue,
      );
      expect(
        (diaspora()..setJewishDate(5784, JewishDate.AV, 9)).isTishaBav(),
        isTrue,
      );
    });

    test('isPurim follows isMukafChoma', () {
      final open = diaspora()..setJewishDate(5784, JewishDate.ADAR_II, 14);
      expect(open.isPurim(), isTrue);

      final walled = diaspora()
        ..isMukafChoma = true
        ..setJewishDate(5784, JewishDate.ADAR_II, 14);
      expect(walled.isPurim(), isFalse);

      final shushan = diaspora()
        ..isMukafChoma = true
        ..setJewishDate(5784, JewishDate.ADAR_II, 15);
      expect(shushan.isPurim(), isTrue);
    });
  });
}
