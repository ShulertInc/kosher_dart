import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  JewishCalendar adar(int year, int month, int day, {required bool walled}) =>
      JewishCalendar.fromJewishDate(year, month, day)..setIsMukafChoma(walled);

  group('JewishCalendar.isPurimDePrazim', () {
    test('14 Adar, whether or not the reader is in a walled city', () {
      for (final walled in [true, false]) {
        expect(adar(5785, JewishDate.ADAR, 14, walled: walled).isPurimDePrazim(),
            isTrue,
            reason: 'walled $walled');
      }
    });

    test('14 Adar II in a leap year', () {
      for (final walled in [true, false]) {
        expect(
            adar(5784, JewishDate.ADAR_II, 14, walled: walled)
                .isPurimDePrazim(),
            isTrue,
            reason: 'walled $walled');
        expect(
            adar(5784, JewishDate.ADAR, 14, walled: walled).isPurimDePrazim(),
            isFalse,
            reason: 'Purim Katan, walled $walled');
      }
    });

    test('the 15th is Shushan Purim and not the 14th', () {
      for (final walled in [true, false]) {
        final shushan = adar(5785, JewishDate.ADAR, 15, walled: walled);
        expect(shushan.isPurimDePrazim(), isFalse, reason: 'walled $walled');
        expect(shushan.isShushanPurim(), isTrue, reason: 'walled $walled');
      }
    });

    test('in a walled city isPurim is the 15th and this is still the 14th', () {
      final fourteenth = adar(5785, JewishDate.ADAR, 14, walled: true);
      expect(fourteenth.isPurim(), isFalse);
      expect(fourteenth.isPurimDePrazim(), isTrue);
    });
  });
}
