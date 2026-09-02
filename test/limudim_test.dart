/// Tests for the learning schedules ported from kosher-rust: Daf Hashavua Bavli, the
/// Dirshu Amud Yomi, Mishna Yomis, Pirkei Avos and the monthly Tehillim.
library;

import 'package:kosher_dart/kosher_dart.dart';
import 'package:test/test.dart';

JewishCalendar on(int year, int month, int day, {bool inIsrael = false}) =>
    JewishCalendar.fromDateTime(DateTime(year, month, day))..inIsrael = inIsrael;

void main() {
  group('Daf Hashavua Bavli', () {
    test('opens on Berachos 2 the week the cycle begins', () {
      // The first cycle began on Sunday 6 March 2005.
      for (final day in [6, 7, 12]) {
        final daf = on(2005, 3, day).getDafHashavuaBavli()!;
        expect(daf.getMasechtaTransliterated(), 'Berachos', reason: 'March $day');
        expect(daf.getDaf(), 2, reason: 'March $day');
      }
    });

    test('turns the page on the Sunday, not mid week', () {
      expect(on(2005, 3, 13).getDafHashavuaBavli()!.getDaf(), 3);
      expect(on(2005, 3, 19).getDafHashavuaBavli()!.getDaf(), 3);
      expect(on(2005, 3, 20).getDafHashavuaBavli()!.getDaf(), 4);
    });

    test('is null before the first cycle', () {
      expect(on(2005, 3, 5).getDafHashavuaBavli(), isNull);
    });
  });

  group('Dirshu Amud Yomi', () {
    test('opens on Berachos 2a the day the cycle begins', () {
      final amud = on(2023, 10, 16).getAmudYomiBavliDirshu()!;
      expect(amud.getMasechtaTransliterated(), 'Berachos');
      expect(amud.getDaf(), 2);
      expect(amud.getSide(), AmudSide.ALEPH);
    });

    test('turns to the second side the next day', () {
      final amud = on(2023, 10, 17).getAmudYomiBavliDirshu()!;
      expect(amud.getDaf(), 2);
      expect(amud.getSide(), AmudSide.BEIS);
    });

    test('is null before the first cycle', () {
      expect(on(2023, 10, 15).getAmudYomiBavliDirshu(), isNull);
    });
  });

  group('Mishna Yomis', () {
    test('opens on Berachos 1:1 and 1:2', () {
      final mishnayos = on(1947, 5, 20).getMishnaYomis()!;
      expect(mishnayos.first.getMasechtaTransliterated(), 'Berachos');
      expect(mishnayos.first.getChapter(), 1);
      expect(mishnayos.first.getMishna(), 1);
      expect(mishnayos.second.getMishna(), 2);
    });

    test('is null before the first cycle', () {
      expect(on(1947, 5, 19).getMishnaYomis(), isNull);
    });
  });

  group('Pirkei Avos', () {
    test('opens the Shabbos after Pesach and runs the six perakim in order', () {
      // 5778: the cycle opens 23 Nissan outside Israel, and a week later is perek 2.
      final first = JewishCalendar.initDate(5778, JewishDate.NISSAN, 23);
      expect(first.getPirkeiAvos()!.first, 1);
      expect(first.getPirkeiAvos()!.isCombined, isFalse);

      final second = JewishCalendar.initDate(5778, JewishDate.IYAR, 1);
      expect(second.getPirkeiAvos()!.first, 2);
    });

    test('doubles up the perakim at the end of the season', () {
      final late = JewishCalendar.initDate(5778, JewishDate.ELUL, 20);
      final unit = late.getPirkeiAvos()!;
      expect(unit.isCombined, isTrue);
      expect(unit.first, 3);
      expect(unit.second, 4);
    });

    test('is null outside the season', () {
      expect(JewishCalendar.initDate(5778, JewishDate.NISSAN, 20).getPirkeiAvos(),
          isNull);
      expect(JewishCalendar.initDate(5778, JewishDate.ELUL, 29).getPirkeiAvos(),
          isNull);
    });

    test('the diaspora starts a day after Israel does', () {
      final israel =
          JewishCalendar.initDate(5778, JewishDate.NISSAN, 22, inIsrael: true);
      final diaspora = JewishCalendar.initDate(5778, JewishDate.NISSAN, 22);

      expect(israel.getPirkeiAvos(), isNotNull);
      expect(diaspora.getPirkeiAvos(), isNull);
    });
  });

  group('monthly Tehillim', () {
    test('divides the sefer across the days of the month', () {
      expect(
          JewishCalendar.initDate(5778, JewishDate.TEVES, 1)
              .getTehillimMonthly()
              .toString(),
          '1 - 9');
      expect(
          JewishCalendar.initDate(5778, JewishDate.TEVES, 8)
              .getTehillimMonthly()
              .toString(),
          '44 - 48');
    });

    test('splits kapitel 119 over the twenty fifth and twenty sixth', () {
      final twentyFifth =
          JewishCalendar.initDate(5778, JewishDate.SHEVAT, 25).getTehillimMonthly();
      expect(twentyFifth.isPartialPsalm, isTrue);
      expect(twentyFifth.psalm, 119);
      expect(twentyFifth.startVerse, 1);
      expect(twentyFifth.endVerse, 96);

      final twentySixth =
          JewishCalendar.initDate(5778, JewishDate.SHEVAT, 26).getTehillimMonthly();
      expect(twentySixth.startVerse, 97);
      expect(twentySixth.endVerse, 176);
    });

    test('a month of 29 days says the thirtieth day too on the twenty ninth', () {
      // Teves 5778 has 29 days, Shevat has 30.
      expect(
          JewishCalendar.initDate(5778, JewishDate.TEVES, 29)
              .getTehillimMonthly()
              .toString(),
          '140 - 150');
      expect(
          JewishCalendar.initDate(5778, JewishDate.SHEVAT, 29)
              .getTehillimMonthly()
              .toString(),
          '140 - 144');
      expect(
          JewishCalendar.initDate(5778, JewishDate.SHEVAT, 30)
              .getTehillimMonthly()
              .toString(),
          '145 - 150');
    });
  });
}
