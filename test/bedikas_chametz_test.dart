import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  JewishCalendar nissan(int year, int day) =>
      JewishCalendar.fromJewishDate(year, JewishDate.NISSAN, day);

  group('JewishCalendar.isBedikasChametz', () {
    test('erev Pesach, 14 Nissan 5786', () {
      expect(nissan(5786, 13).isBedikasChametz(), isFalse);
      expect(nissan(5786, 14).isBedikasChametz(), isTrue);
    });

    test('13 Nissan when erev Pesach is Shabbos, as in 5785', () {
      expect(nissan(5785, 14).getDayOfWeek(), 7);
      expect(nissan(5785, 13).isBedikasChametz(), isTrue);
      expect(nissan(5785, 14).isBedikasChametz(), isFalse);
    });

    test('exactly one day a year, the 13th only when the 14th is Shabbos', () {
      for (var year = 5700; year <= 6000; year++) {
        final days = [
          for (var day = 1; day <= 30; day++)
            if (nissan(year, day).isBedikasChametz()) day,
        ];
        final shabbos = nissan(year, 14).getDayOfWeek() == 7;

        expect(days, [shabbos ? 13 : 14], reason: '$year');
      }
    });

    test('never outside Nissan', () {
      for (var date = DateTime.utc(2024, 1, 1);
          date.isBefore(DateTime.utc(2030, 1, 1));
          date = date.add(const Duration(days: 1))) {
        final c = JewishCalendar.fromLocalDate(date);
        if (c.getJewishMonth() == JewishDate.NISSAN) continue;

        expect(c.isBedikasChametz(), isFalse, reason: '$date');
      }
    });
  });
}
