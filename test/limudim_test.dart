/// Tests for the learning schedules ported from kosher-rust: Daf Hashavua Bavli, the
/// Dirshu Amud Yomi, Mishna Yomis, Pirkei Avos and the monthly Tehillim.
library;

import 'package:kosher_dart/kosher_dart.dart';
import 'package:test/test.dart';

JewishCalendar on(int year, int month, int day, {bool inIsrael = false}) =>
    JewishCalendar.fromLocalDate(DateTime(year, month, day))..setInIsrael(inIsrael);

void main() {
  group('Daf Hashavua Bavli', () {
    test('opens on Berachos 2 the week the cycle begins', () {
      // The first cycle began on Sunday 6 March 2005.
      for (final day in [6, 7, 12]) {
        final daf = DafHashavuaBavliCalculator.getDafHashavuaBavli(on(2005, 3, day))!;
        expect(daf.getMasechtaTransliterated(), 'Berachos', reason: 'March $day');
        expect(daf.getDaf(), 2, reason: 'March $day');
      }
    });

    test('turns the page on the Sunday, not mid week', () {
      expect(DafHashavuaBavliCalculator.getDafHashavuaBavli(on(2005, 3, 13))!.getDaf(), 3);
      expect(DafHashavuaBavliCalculator.getDafHashavuaBavli(on(2005, 3, 19))!.getDaf(), 3);
      expect(DafHashavuaBavliCalculator.getDafHashavuaBavli(on(2005, 3, 20))!.getDaf(), 4);
    });

    test('is null before the first cycle', () {
      expect(DafHashavuaBavliCalculator.getDafHashavuaBavli(on(2005, 3, 5)), isNull);
    });
  });

  group('Dirshu Amud Yomi', () {
    test('opens on Berachos 2a the day the cycle begins', () {
      final amud = AmudYomiBavliDirshuCalculator.getAmudYomiBavliDirshu(on(2023, 10, 16))!;
      expect(amud.getMasechtaTransliterated(), 'Berachos');
      expect(amud.getDaf(), 2);
      expect(amud.getSide(), AmudSide.ALEPH);
    });

    test('turns to the second side the next day', () {
      final amud = AmudYomiBavliDirshuCalculator.getAmudYomiBavliDirshu(on(2023, 10, 17))!;
      expect(amud.getDaf(), 2);
      expect(amud.getSide(), AmudSide.BEIS);
    });

    test('is null before the first cycle', () {
      expect(AmudYomiBavliDirshuCalculator.getAmudYomiBavliDirshu(on(2023, 10, 15)), isNull);
    });
  });

  group('Mishna Yomis', () {
    test('opens on Berachos 1:1 and 1:2', () {
      final mishnayos = MishnaYomisCalculator.getMishnaYomis(on(1947, 5, 20))!;
      expect(mishnayos.first.getMasechtaTransliterated(), 'Berachos');
      expect(mishnayos.first.getChapter(), 1);
      expect(mishnayos.first.getMishna(), 1);
      expect(mishnayos.second.getMishna(), 2);
    });

    test('is null before the first cycle', () {
      expect(MishnaYomisCalculator.getMishnaYomis(on(1947, 5, 19)), isNull);
    });
  });

  group('Pirkei Avos', () {
    test('opens the Shabbos after Pesach and runs the six perakim in order', () {
      // 5778: the cycle opens 23 Nissan outside Israel, and a week later is perek 2.
      final first = JewishCalendar.fromJewishDate(5778, JewishDate.NISSAN, 23);
      expect(PirkeiAvosCalculator.getPirkeiAvos(first)!.first, 1);
      expect(PirkeiAvosCalculator.getPirkeiAvos(first)!.isCombined, isFalse);

      final second = JewishCalendar.fromJewishDate(5778, JewishDate.IYAR, 1);
      expect(PirkeiAvosCalculator.getPirkeiAvos(second)!.first, 2);
    });

    test('doubles up the perakim at the end of the season', () {
      final late = JewishCalendar.fromJewishDate(5778, JewishDate.ELUL, 20);
      final unit = PirkeiAvosCalculator.getPirkeiAvos(late)!;
      expect(unit.isCombined, isTrue);
      expect(unit.first, 3);
      expect(unit.second, 4);
    });

    test('is null outside the season', () {
      expect(PirkeiAvosCalculator.getPirkeiAvos(JewishCalendar.fromJewishDate(5778, JewishDate.NISSAN, 20)),
          isNull);
      expect(PirkeiAvosCalculator.getPirkeiAvos(JewishCalendar.fromJewishDate(5778, JewishDate.ELUL, 29)),
          isNull);
    });

    test('is null before Pesach of the earliest year the calendar reaches', () {
      expect(PirkeiAvosCalculator.getPirkeiAvos(JewishCalendar.fromLocalDate(DateTime(1, 1, 10))),
          isNull);
    });

    test('the diaspora starts a day after Israel does', () {
      final israel =
          JewishCalendar.fromJewishDateInIsrael(5778, JewishDate.NISSAN, 22, true);
      final diaspora = JewishCalendar.fromJewishDate(5778, JewishDate.NISSAN, 22);

      expect(PirkeiAvosCalculator.getPirkeiAvos(israel), isNotNull);
      expect(PirkeiAvosCalculator.getPirkeiAvos(diaspora), isNull);
    });
  });

  group('monthly Tehillim', () {
    test('divides the sefer across the days of the month', () {
      expect(
          TehillimMonthlyCalculator.getTehillimMonthly(JewishCalendar.fromJewishDate(5778, JewishDate.TEVES, 1))
              .toString(),
          '1 - 9');
      expect(
          TehillimMonthlyCalculator.getTehillimMonthly(JewishCalendar.fromJewishDate(5778, JewishDate.TEVES, 8))
              .toString(),
          '44 - 48');
    });

    test('splits kapitel 119 over the twenty fifth and twenty sixth', () {
      final twentyFifth =
          TehillimMonthlyCalculator.getTehillimMonthly(JewishCalendar.fromJewishDate(5778, JewishDate.SHEVAT, 25));
      expect(twentyFifth.isPartialPsalm, isTrue);
      expect(twentyFifth.psalm, 119);
      expect(twentyFifth.startVerse, 1);
      expect(twentyFifth.endVerse, 96);

      final twentySixth =
          TehillimMonthlyCalculator.getTehillimMonthly(JewishCalendar.fromJewishDate(5778, JewishDate.SHEVAT, 26));
      expect(twentySixth.startVerse, 97);
      expect(twentySixth.endVerse, 176);
    });

    test('a month of 29 days says the thirtieth day too on the twenty ninth', () {
      // Teves 5778 has 29 days, Shevat has 30.
      expect(
          TehillimMonthlyCalculator.getTehillimMonthly(JewishCalendar.fromJewishDate(5778, JewishDate.TEVES, 29))
              .toString(),
          '140 - 150');
      expect(
          TehillimMonthlyCalculator.getTehillimMonthly(JewishCalendar.fromJewishDate(5778, JewishDate.SHEVAT, 29))
              .toString(),
          '140 - 144');
      expect(
          TehillimMonthlyCalculator.getTehillimMonthly(JewishCalendar.fromJewishDate(5778, JewishDate.SHEVAT, 30))
              .toString(),
          '145 - 150');
    });
  });
}
