import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  group('JewishCalendar - motzei yom tov', () {
    JewishCalendar at(int year, int month, int day, {bool inIsrael = false}) =>
        JewishCalendar.initDate(year, month, day)..inIsrael = inIsrael;

    test('the day after a one day yom tov in Israel', () {
      // 22 Tishrei is Shemini Atzeres, and in Israel the 23rd is a plain day.
      expect(at(5784, JewishDate.TISHREI, 22, inIsrael: true).isMotzeiYomTov(), isFalse);
      expect(at(5784, JewishDate.TISHREI, 23, inIsrael: true).isMotzeiYomTov(), isTrue);
    });

    test('the second day of yom tov is not motzei yom tov', () {
      // Out of Israel the 23rd is Simchas Torah, so the night before it was still yom tov.
      expect(at(5784, JewishDate.TISHREI, 23).isMotzeiYomTov(), isFalse);
      expect(at(5784, JewishDate.TISHREI, 24).isMotzeiYomTov(), isTrue);
    });

    test('chol hamoed opens with a motzei yom tov in Israel but not out of it', () {
      expect(at(5784, JewishDate.NISSAN, 16, inIsrael: true).isMotzeiYomTov(), isTrue);
      expect(at(5784, JewishDate.NISSAN, 16).isMotzeiYomTov(), isFalse);
      expect(at(5784, JewishDate.NISSAN, 17).isMotzeiYomTov(), isTrue);
    });

    test('the middle of chol hamoed is not', () {
      expect(at(5784, JewishDate.NISSAN, 18, inIsrael: true).isMotzeiYomTov(), isFalse);
    });

    test('the day after the last day of Pesach', () {
      expect(at(5784, JewishDate.NISSAN, 22, inIsrael: true).isMotzeiYomTov(), isTrue);
      expect(at(5784, JewishDate.NISSAN, 22).isMotzeiYomTov(), isFalse);
      expect(at(5784, JewishDate.NISSAN, 23).isMotzeiYomTov(), isTrue);
    });

    test('Rosh Hashana and Yom Kippur', () {
      expect(at(5784, JewishDate.TISHREI, 2).isMotzeiYomTov(), isFalse);
      expect(at(5784, JewishDate.TISHREI, 3).isMotzeiYomTov(), isTrue);
      expect(at(5784, JewishDate.TISHREI, 11).isMotzeiYomTov(), isTrue);
    });

    test('an ordinary weekday is not', () {
      final c = at(5784, JewishDate.CHESHVAN, 1);

      for (var day = 1; day <= 29; day++) {
        c.setJewishDate(5784, JewishDate.CHESHVAN, day);
        expect(c.isMotzeiYomTov(), isFalse, reason: '$day Cheshvan');
      }
    });

    test('yom tov running into shabbos leaves a shabbos that is both', () {
      final c = at(5780, JewishDate.TISHREI, 1);
      var found = false;

      for (var year = 5780; year <= 5800 && !found; year++) {
        for (var day = 1; day <= 29; day++) {
          c.setJewishDate(year, JewishDate.NISSAN, day);
          if (!c.isYomTovAssurBemelacha() || c.getDayOfWeek() != JewishDate.friday) {
            continue;
          }

          c.forward();
          expect(c.isShabbos(), isTrue);
          expect(c.isMotzeiYomTov(), isTrue, reason: '$day Nissan $year');
          found = true;
          break;
        }
      }

      expect(found, isTrue, reason: 'no yom tov fell on a Friday in Nissan 5780-5800');
    });
  });
}
