import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  final rules = TefilaRules();

  List<int> read(int year, int day, {required bool inIsrael}) {
    final calendar = JewishCalendar.fromJewishDate(year, JewishDate.NISSAN, day)
      ..setInIsrael(inIsrael);
    return [
      for (var reading = 1; reading <= 5; reading++)
        if (rules.isPesachReadingRead(calendar, reading)) reading,
    ];
  }

  Map<int, List<int>> week(int year, {required bool inIsrael}) => {
        for (var day = 15; day <= 22; day++)
          day: read(year, day, inIsrael: inIsrael),
      };

  int firstDayOfWeek(int year) =>
      JewishCalendar.fromJewishDate(year, JewishDate.NISSAN, 15)
          .getDayOfWeek();

  group('TefilaRules.isPesachReadingRead', () {
    test('the years the tests rest on open Pesach on the days they say', () {
      expect(firstDayOfWeek(5785), 1, reason: 'Sunday');
      expect(firstDayOfWeek(5784), 3, reason: 'Tuesday');
      expect(firstDayOfWeek(5786), 5, reason: 'Thursday');
      expect(firstDayOfWeek(5782), 7, reason: 'Shabbos');
    });

    test('with no shabbos in chol hamoed each day reads in turn', () {
      expect(week(5785, inIsrael: false), {
        15: [], 16: [], 17: [2], 18: [3], 19: [4], 20: [5], 21: [], 22: [],
      });
      expect(week(5782, inIsrael: false), {
        15: [], 16: [], 17: [2], 18: [3], 19: [4], 20: [5], 21: [], 22: [],
      });
      expect(week(5785, inIsrael: true), {
        15: [], 16: [1], 17: [2], 18: [3], 19: [4], 20: [5], 21: [], 22: [],
      });
    });

    test('shabbos on the 17th moves קדש לי to sunday and אם כסף to monday', () {
      expect(week(5786, inIsrael: false), {
        15: [], 16: [], 17: [], 18: [2], 19: [3], 20: [5], 21: [], 22: [],
      });
      expect(week(5786, inIsrael: true), {
        15: [], 16: [1], 17: [], 18: [2], 19: [3], 20: [5], 21: [], 22: [],
      });
    });

    test('shabbos on the 19th leaves פסל לך to the shabbos reading', () {
      expect(week(5784, inIsrael: false), {
        15: [], 16: [], 17: [2], 18: [3], 19: [], 20: [5], 21: [], 22: [],
      });
      expect(week(5784, inIsrael: true), {
        15: [], 16: [1], 17: [2], 18: [3], 19: [], 20: [5], 21: [], 22: [],
      });
    });

    test('chol hamoed Succos reads none of them', () {
      final succos = JewishCalendar.fromJewishDate(5785, JewishDate.TISHREI, 17);
      for (var reading = 1; reading <= 5; reading++) {
        expect(rules.isPesachReadingRead(succos, reading), isFalse);
      }
    });

    test('a reading outside 1 through 5 is refused', () {
      final calendar = JewishCalendar.fromJewishDate(5785, JewishDate.NISSAN, 17);
      expect(() => rules.isPesachReadingRead(calendar, 0), throwsArgumentError);
      expect(() => rules.isPesachReadingRead(calendar, 6), throwsArgumentError);
    });
  });
}
