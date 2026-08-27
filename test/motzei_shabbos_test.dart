import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  group('JewishCalendar - motzei shabbos', () {
    JewishCalendar cal() => JewishCalendar()..inIsrael = false;

    test('is the day whose night follows shabbos', () {
      final c = cal();

      for (var day = 1; day <= 29; day++) {
        c.setJewishDate(5784, JewishDate.CHESHVAN, day);
        expect(c.isMotzeiShabbos(), equals(c.isSunday()), reason: '$day Cheshvan');
      }
    });

    test('shabbos itself is not motzei shabbos', () {
      final c = cal();

      for (var day = 1; day <= 29; day++) {
        c.setJewishDate(5784, JewishDate.CHESHVAN, day);
        if (!c.isShabbos()) continue;
        expect(c.isMotzeiShabbos(), isFalse, reason: '$day Cheshvan');
        return;
      }
      fail('no shabbos in Cheshvan 5784');
    });
  });
}
