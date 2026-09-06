/// Coverage for the _selichos_ count, which is the only rule here whose answer is an
/// ordinal rather than a day: a print sets an order per numbered day, and a year holds
/// between three and seven of the Elul ones.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  final rules = TefilaRules();

  JewishCalendar day(int year, int month, int dayOfMonth) =>
      JewishCalendar.initDate(year, month, dayOfMonth)..inIsrael = false;

  /// The days of Elul that carry a numbered order, as `day of Elul -> its number`.
  Map<int, int> elul(int year) => {
        for (var of = 1; of <= 29; of++)
          if (day(year, JewishDate.ELUL, of).getDayOfSelichos() != -1)
            of: day(year, JewishDate.ELUL, of).getDayOfSelichos(),
      };

  /// The same for the days of Tishrei between Rosh Hashana and Yom Kippur.
  Map<int, int> teshuva(int year) => {
        for (var of = 1; of <= 10; of++)
          if (day(year, JewishDate.TISHREI, of).getDayOfSelichosOfTeshuva() !=
              -1)
            of: day(year, JewishDate.TISHREI, of).getDayOfSelichosOfTeshuva(),
      };

  /// Which day of the week Rosh Hashana of the year after this one falls on.
  int roshHashanaFallsOn(int year) =>
      day(year + 1, JewishDate.TISHREI, 1).getDayOfWeek();

  group('JewishCalendar - the Elul selichos', () {
    test('open on the motzei shabbos before Rosh Hashana', () {
      for (var year = 5780; year < 5830; year++) {
        final days = elul(year);
        final opens = days.keys.reduce((a, b) => a < b ? a : b);

        expect(days[opens], equals(1), reason: '$year');
        expect(day(year, JewishDate.ELUL, opens).isSunday(), isTrue,
            reason: '$year opens on $opens Elul');
      }
    });

    test('open a week earlier when Rosh Hashana is Monday or Tuesday', () {
      var mondayOrTuesday = 0;
      var thursdayOrShabbos = 0;

      for (var year = 5780; year < 5830; year++) {
        final falls = roshHashanaFallsOn(year);
        final opens = elul(year).keys.reduce((a, b) => a < b ? a : b);

        if (falls == JewishDate.monday || falls == JewishDate.tuesday) {
          expect(opens, equals(31 - falls - 7), reason: '$year');
          mondayOrTuesday++;
        } else {
          expect(opens, equals(31 - falls), reason: '$year');
          thursdayOrShabbos++;
        }
      }

      expect(mondayOrTuesday, greaterThan(0));
      expect(thursdayOrShabbos, greaterThan(0));
    });

    test('are never fewer than four days counting erev Rosh Hashana', () {
      for (var year = 5780; year < 5830; year++) {
        final numbered = elul(year).length;
        expect(numbered + 1, greaterThanOrEqualTo(4), reason: '$year');
        expect(numbered, lessThanOrEqualTo(7), reason: '$year');
      }
    });

    test('run 1, 2, 3 … with no gap, and skip shabbos', () {
      for (var year = 5780; year < 5830; year++) {
        final days = elul(year);
        expect(days.values.toList(),
            equals([for (var n = 1; n <= days.length; n++) n]),
            reason: '$year');

        for (final of in days.keys) {
          expect(day(year, JewishDate.ELUL, of).isShabbos(), isFalse,
              reason: '$of Elul $year');
        }
      }
    });

    test('erev Rosh Hashana carries no number of its own', () {
      for (var year = 5780; year < 5830; year++) {
        final erev = day(year, JewishDate.ELUL, 29);
        expect(erev.isErevRoshHashana(), isTrue, reason: '$year');
        expect(erev.getDayOfSelichos(), equals(-1), reason: '$year');
      }
    });

    test('no other month answers', () {
      for (var month = 1; month <= 12; month++) {
        if (month == JewishDate.ELUL) continue;
        for (var of = 1; of <= 29; of++) {
          expect(day(5784, month, of).getDayOfSelichos(), equals(-1),
              reason: '$of/$month');
        }
      }
    });
  });

  group('JewishCalendar - the selichos of the Aseres Yemei Teshuva', () {
    test('are five in every year, opening on Tzom Gedalyah', () {
      for (var year = 5781; year < 5831; year++) {
        final days = teshuva(year);

        expect(days.length, equals(5), reason: '$year');
        expect(days.values.toList(), equals([1, 2, 3, 4, 5]), reason: '$year');

        final opens = days.keys.reduce((a, b) => a < b ? a : b);
        expect(day(year, JewishDate.TISHREI, opens).isFastOfGedalyah(), isTrue,
            reason: '$year opens on $opens Tishrei');
      }
    });

    test('skip shabbos, and stop before erev Yom Kippur', () {
      for (var year = 5781; year < 5831; year++) {
        for (final of in teshuva(year).keys) {
          expect(day(year, JewishDate.TISHREI, of).isShabbos(), isFalse,
              reason: '$of Tishrei $year');
        }

        final erev = day(year, JewishDate.TISHREI, 9);
        expect(erev.isErevYomKippur(), isTrue, reason: '$year');
        expect(erev.getDayOfSelichosOfTeshuva(), equals(-1), reason: '$year');
        expect(day(year, JewishDate.TISHREI, 10).getDayOfSelichosOfTeshuva(),
            equals(-1),
            reason: '$year');
      }
    });
  });

  group('TefilaRules - selichos', () {
    test('the numbered predicates agree with the count', () {
      for (var year = 5781; year < 5800; year++) {
        for (var of = 1; of <= 29; of++) {
          final calendar = day(year, JewishDate.ELUL, of);
          for (var numbered = 1; numbered <= 7; numbered++) {
            expect(rules.isSelichosDayRecited(calendar, numbered),
                equals(calendar.getDayOfSelichos() == numbered),
                reason: '$of Elul $year, day $numbered');
          }
        }

        for (var of = 1; of <= 10; of++) {
          final calendar = day(year, JewishDate.TISHREI, of);
          for (var numbered = 1; numbered <= 5; numbered++) {
            expect(rules.isSelichosDayOfTeshuvaRecited(calendar, numbered),
                equals(calendar.getDayOfSelichosOfTeshuva() == numbered),
                reason: '$of Tishrei $year, day $numbered');
          }
        }
      }
    });

    test('a number no print sets an order for is an error', () {
      final calendar = day(5784, JewishDate.ELUL, 25);
      expect(
          () => rules.isSelichosDayRecited(calendar, 0), throwsArgumentError);
      expect(
          () => rules.isSelichosDayRecited(calendar, 8), throwsArgumentError);
      expect(() => rules.isSelichosDayOfTeshuvaRecited(calendar, 6),
          throwsArgumentError);
    });

    test('isSelichosRecited runs from the opening through erev Yom Kippur', () {
      final calendar = day(5783, JewishDate.ELUL, 1);
      final said = <String>[];

      for (var date = 0; date < 60; date++) {
        if (rules.isSelichosRecited(calendar)) {
          said.add('${calendar.getJewishDayOfMonth()}/'
              '${calendar.getJewishMonth()}');
        }
        calendar.forward(Calendar.DATE, 1);
      }

      expect(said.length, equals(elul(5783).length + 1 + 5 + 1));
      expect(said.last, equals('9/${JewishDate.TISHREI}'));
    });
  });
}
