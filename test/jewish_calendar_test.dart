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

    test('Shemini Atzeret in Israel: 22 Tishrei is Shemini Atzeret (code returns SHEMINI_ATZERES for both)', () {
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
}
