/// Tests that Gregorian months count from 1 for January everywhere in the API.
///
/// [JewishDate.getGregorianMonth] always returned the month 1-based, the way
/// [DateTime] and KosherJava both count them, but [JewishDate.setGregorianDate]
/// and [JewishDate.setGregorianMonth] used to expect 0 for January and add one
/// internally. Feeding the getter into the setter therefore moved the date on by
/// a month, and six places inside this library did exactly that by passing
/// `getLocalDate().month` - a [DateTime] month - straight in. That put
/// [ComprehensiveZmanimCalendar]'s Kiddush Levana zmanim and
/// [ZmanimCalendar.isAssurBemelacha] a whole month out.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('the setter takes the month the way DateTime gives it', () {
    final JewishDate jewishDate = JewishDate();
    jewishDate.setGregorianDate(2026, 8, 27); // 27 August 2026

    expect(jewishDate.getGregorianYear(), 2026);
    expect(jewishDate.getGregorianMonth(), 8);
    expect(jewishDate.getGregorianDayOfMonth(), 27);

    // 27 August 2026 is 14 Elul 5786.
    expect(jewishDate.getJewishYear(), 5786);
    expect(jewishDate.getJewishMonth(), JewishDate.ELUL);
    expect(jewishDate.getJewishDayOfMonth(), 14);
  });

  test('setting and reading a date agree with fromDateTime', () {
    final DateTime date = DateTime(2026, 8, 27);

    final JewishDate viaSetter = JewishDate();
    viaSetter.setGregorianDate(date.year, date.month, date.day);

    final JewishDate viaDateTime = JewishDate.fromDateTime(date);

    expect(viaSetter.getGregorianMonth(), viaDateTime.getGregorianMonth());
    expect(viaSetter.getJewishMonth(), viaDateTime.getJewishMonth());
    expect(viaSetter.getJewishYear(), viaDateTime.getJewishYear());
    expect(viaSetter.getJewishDayOfMonth(), viaDateTime.getJewishDayOfMonth());
  });

  test('the getter round trips through the setter', () {
    for (final DateTime date in [
      DateTime(2026, 1, 1),
      DateTime(2026, 6, 15),
      DateTime(2026, 12, 31),
    ]) {
      final JewishDate original = JewishDate.fromDateTime(date);
      final JewishDate copy = JewishDate();
      copy.setGregorianDate(original.getGregorianYear(),
          original.getGregorianMonth(), original.getGregorianDayOfMonth());

      expect(copy.getGregorianYear(), date.year);
      expect(copy.getGregorianMonth(), date.month);
      expect(copy.getGregorianDayOfMonth(), date.day);
    }
  });

  test('clone keeps the date it was made from', () {
    final JewishDate original = JewishDate.fromDateTime(DateTime(2026, 12, 31));
    final JewishDate copy = original.clone();

    expect(copy.getGregorianYear(), 2026);
    expect(copy.getGregorianMonth(), 12);
    expect(copy.getGregorianDayOfMonth(), 31);
    expect(copy.getJewishMonth(), original.getJewishMonth());
    expect(copy.getJewishDayOfMonth(), original.getJewishDayOfMonth());
  });

  test('setGregorianMonth counts January as 1', () {
    final JewishDate jewishDate = JewishDate.fromDateTime(DateTime(2026, 6, 15));

    jewishDate.setGregorianMonth(1);
    expect(jewishDate.getGregorianMonth(), 1);

    jewishDate.setGregorianMonth(12);
    expect(jewishDate.getGregorianMonth(), 12);
  });

  test('a month outside 1 - 12 is rejected', () {
    final JewishDate jewishDate = JewishDate();

    expect(() => jewishDate.setGregorianDate(2026, 0, 1), throwsArgumentError);
    expect(() => jewishDate.setGregorianDate(2026, 13, 1), throwsArgumentError);
    expect(() => jewishDate.setGregorianMonth(0), throwsArgumentError);
    expect(() => jewishDate.setGregorianMonth(13), throwsArgumentError);
  });

  test('the day melacha is judged on is the day the calendar is set to', () {
    // isAssurBemelacha reads its day through setGregorianDate, so a month shifted
    // there answered for the wrong day entirely. Friday 21 August 2026 after
    // shkia is erev shabbos; a month on it would have been a Monday.
    final ComprehensiveZmanimCalendar zmanimCalendar = ComprehensiveZmanimCalendar.withGeoLocation(
        GeoLocation.withZoneId('New York', 40.7128, -74.0060, tz.UTC));
    zmanimCalendar.setLocalDate(DateTime.utc(2026, 8, 21));

    expect(JewishCalendar.fromDateTime(DateTime(2026, 8, 21)).getDayOfWeek(), 6,
        reason: 'the test date is a Friday');

    final DateTime sunset = zmanimCalendar.getSunset()!;
    final DateTime tzais = zmanimCalendar.getTzaisGeonim8Point5Degrees()!;

    expect(zmanimCalendar.isAssurBemelacha(
            sunset.add(const Duration(minutes: 1)), tzais, false),
        isTrue,
        reason: 'after shkia on erev shabbos');

    // The following Wednesday is an ordinary weekday at the same hour.
    zmanimCalendar.setLocalDate(DateTime.utc(2026, 8, 26));
    expect(
        zmanimCalendar.isAssurBemelacha(
            zmanimCalendar.getSunset()!.add(const Duration(minutes: 1)),
            zmanimCalendar.getTzaisGeonim8Point5Degrees()!,
            false),
        isFalse);
  });
}
