import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  final rules = TefilaRules();

  JewishCalendar tishrei(int day, {required bool inIsrael}) =>
      JewishCalendar.initDate(5784, JewishDate.TISHREI, day)..inIsrael = inIsrael;

  /// Which korbanos the mussaf of this day reads, as day numbers of Succos.
  List<int> read(int day, {required bool inIsrael}) {
    final calendar = tishrei(day, inIsrael: inIsrael);
    return [
      for (var korban = 2; korban <= 7; korban++)
        if (rules.isSuccosKorbanRecited(calendar, korban)) korban,
    ];
  }

  group('TefilaRules - the korban of chol hamoed Succos', () {
    test('in Israel each day reads its own', () {
      expect(read(16, inIsrael: true), equals([2]));
      expect(read(17, inIsrael: true), equals([3]));
      expect(read(18, inIsrael: true), equals([4]));
      expect(read(19, inIsrael: true), equals([5]));
      expect(read(20, inIsrael: true), equals([6]));
      expect(read(21, inIsrael: true), equals([7]), reason: 'Hoshana Rabba');
    });

    test('outside Israel each day reads its own and the next day\'s', () {
      expect(read(17, inIsrael: false), equals([2, 3]));
      expect(read(18, inIsrael: false), equals([3, 4]));
      expect(read(19, inIsrael: false), equals([4, 5]));
      expect(read(20, inIsrael: false), equals([5, 6]));
      expect(read(21, inIsrael: false), equals([6, 7]), reason: 'Hoshana Rabba');
    });

    test('the days of yom tov read none of them', () {
      for (final day in [15, 16, 22, 23]) {
        expect(read(day, inIsrael: false), isEmpty, reason: '$day Tishrei');
      }
      for (final day in [15, 22]) {
        expect(read(day, inIsrael: true), isEmpty, reason: '$day Tishrei in Israel');
      }
    });

    test('chol hamoed Pesach reads none of them', () {
      final pesach = JewishCalendar.initDate(5784, JewishDate.NISSAN, 18)
        ..inIsrael = false;
      for (var korban = 2; korban <= 7; korban++) {
        expect(rules.isSuccosKorbanRecited(pesach, korban), isFalse);
      }
    });

    test('every day of chol hamoed reads at least one', () {
      for (final inIsrael in [true, false]) {
        for (var day = 16; day <= 21; day++) {
          final calendar = tishrei(day, inIsrael: inIsrael);
          if (!calendar.isCholHamoedSuccos()) continue;
          expect(read(day, inIsrael: inIsrael), isNotEmpty,
              reason: '$day Tishrei, inIsrael $inIsrael');
        }
      }
    });

    test('a day outside 2 through 7 is not a korban of chol hamoed', () {
      final calendar = tishrei(18, inIsrael: true);
      expect(() => rules.isSuccosKorbanRecited(calendar, 1), throwsArgumentError);
      expect(() => rules.isSuccosKorbanRecited(calendar, 8), throwsArgumentError);
    });
  });
}
