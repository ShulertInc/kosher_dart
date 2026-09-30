import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  final rules = TefilaRules();

  final singles = [
    for (final parshah in Parshah.values)
      if (parshah.index >= Parshah.BERESHIS.index &&
          parshah.index <= Parshah.VZOS_HABERACHA.index)
        parshah,
  ];

  JewishCalendar date(int year, int month, int day,
          {bool inIsrael = false, bool walled = false}) =>
      JewishCalendar.fromJewishDate(year, month, day)
        ..setInIsrael(inIsrael)
        ..setIsMukafChoma(walled);

  List<Parshah> read(JewishCalendar calendar) => [
        for (final parshah in singles)
          if (rules.isWeekdayParshahRead(calendar, parshah)) parshah,
      ];

  group('TefilaRules.isWeekdayParshahRead', () {
    test('fifty-four parshiyos can be asked', () {
      expect(singles, hasLength(54));
    });

    test('Monday and Thursday read the coming shabbos\'s parshah', () {
      final monday = date(5785, JewishDate.TISHREI, 26);
      final thursday = date(5785, JewishDate.TISHREI, 29);
      expect(monday.getDayOfWeek(), 2);
      expect(thursday.getDayOfWeek(), 5);
      expect(read(monday), [Parshah.NOACH]);
      expect(read(thursday), [Parshah.NOACH]);
    });

    test('the other days of the week read nothing', () {
      final tuesday = date(5785, JewishDate.TISHREI, 27);
      expect(tuesday.getDayOfWeek(), 3);
      expect(read(tuesday), isEmpty);
    });

    test('a joined week reads its first parshah', () {
      final monday = date(5786, JewishDate.ADAR, 20);
      expect(monday.getDayOfWeek(), 2);
      expect(monday.getUpcomingParshah(), Parshah.VAYAKHEL_PEKUDEI);
      expect(read(monday), [Parshah.VAYAKHEL]);
    });

    test('וזאת הברכה after shabbos Haazinu when it is shabbos shuva', () {
      for (final day in [5, 8, 12]) {
        final calendar = date(5785, JewishDate.TISHREI, day);
        expect(calendar.isMondayOrThursday(), isTrue, reason: '$day Tishrei');
        expect(read(calendar), [Parshah.VZOS_HABERACHA],
            reason: '$day Tishrei');
      }
    });

    test('וזאת הברכה on erev Succos after shabbos Haazinu', () {
      for (final inIsrael in [true, false]) {
        final erevSuccos = date(5786, JewishDate.TISHREI, 14, inIsrael: inIsrael);
        expect(erevSuccos.getDayOfWeek(), 2);
        expect(read(erevSuccos), [Parshah.VZOS_HABERACHA]);
      }
    });

    test('Haazinu before its shabbos when Vayeilech is shabbos shuva', () {
      final monday = date(5786, JewishDate.TISHREI, 7);
      expect(monday.getDayOfWeek(), 2);
      expect(read(monday), [Parshah.HAAZINU]);
    });

    test('Bereshis after Simchas Torah', () {
      for (final inIsrael in [true, false]) {
        final thursday = date(5786, JewishDate.TISHREI, 24, inIsrael: inIsrael);
        expect(thursday.getDayOfWeek(), 5);
        expect(read(thursday), [Parshah.BERESHIS]);
      }
    });

    test('Israel and outside it part after an eighth day of Pesach on shabbos',
        () {
      final israel = date(5782, JewishDate.NISSAN, 24, inIsrael: true);
      final outside = date(5782, JewishDate.NISSAN, 24);
      expect(israel.getDayOfWeek(), 2);
      expect(read(israel), [Parshah.KEDOSHIM]);
      expect(read(outside), [Parshah.ACHREI_MOS]);
    });

    test('Purim displaces it where Purim is kept that day', () {
      final fourteenth = date(5782, JewishDate.ADAR_II, 14);
      expect(fourteenth.getDayOfWeek(), 5);
      expect(read(fourteenth), isEmpty);
      expect(read(date(5782, JewishDate.ADAR_II, 14, walled: true)),
          [Parshah.TZAV]);

      final shushan = date(5784, JewishDate.ADAR_II, 15);
      expect(shushan.getDayOfWeek(), 2);
      expect(read(shushan), [Parshah.TZAV]);
      expect(read(date(5784, JewishDate.ADAR_II, 15, walled: true)), isEmpty);
    });

    test('every Monday and Thursday reads one parshah or is displaced', () {
      for (final year in [5782, 5784, 5785, 5786]) {
        for (final inIsrael in [true, false]) {
          final calendar = date(year, JewishDate.TISHREI, 1, inIsrael: inIsrael);
          while (calendar.getJewishYear() == year) {
            final displaced = calendar.isRoshChodesh() ||
                calendar.isChanukah() ||
                calendar.isPurim() ||
                calendar.isTaanis() ||
                calendar.isCholHamoed() ||
                calendar.isYomTovAssurBemelacha();
            final expected =
                calendar.isMondayOrThursday() && !displaced ? 1 : 0;
            expect(read(calendar), hasLength(expected),
                reason: '${calendar.getJewishDayOfMonth()}/'
                    '${calendar.getJewishMonth()}/$year, inIsrael $inIsrael');
            calendar.plusDays(1);
          }
        }
      }
    });

    test('rosh chodesh, chanukah, a fast and chol hamoed read their own', () {
      JewishCalendar first(bool Function(JewishCalendar) day) {
        final calendar = date(5785, JewishDate.TISHREI, 1);
        while (!(calendar.isMondayOrThursday() && day(calendar))) {
          calendar.plusDays(1);
        }
        return calendar;
      }

      for (final calendar in [
        first((day) => day.isRoshChodesh()),
        first((day) => day.isChanukah()),
        first((day) => day.isTaanis()),
        first((day) => day.isCholHamoed()),
      ]) {
        expect(read(calendar), isEmpty, reason: calendar.toString());
      }
    });

    test('a joined, special or empty parshah is refused', () {
      final calendar = date(5785, JewishDate.TISHREI, 26);
      for (final parshah in [
        Parshah.NONE,
        Parshah.VAYAKHEL_PEKUDEI,
        Parshah.NITZAVIM_VAYEILECH,
        Parshah.ZACHOR,
        Parshah.NACHAMU,
      ]) {
        expect(() => rules.isWeekdayParshahRead(calendar, parshah),
            throwsArgumentError,
            reason: parshah.name);
      }
    });
  });
}
