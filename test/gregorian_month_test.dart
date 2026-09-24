import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('the setter takes the month the way DateTime gives it', () {
    final JewishDate jewishDate = JewishDate();
    jewishDate.setGregorianDate(DateTime.utc(2026, 8, 27)); // 27 August 2026

    expect(jewishDate.getLocalDate().year, 2026);
    expect(jewishDate.getLocalDate().month, 8);
    expect(jewishDate.getLocalDate().day, 27);

    // 27 August 2026 is 14 Elul 5786.
    expect(jewishDate.getJewishYear(), 5786);
    expect(jewishDate.getJewishMonth(), JewishDate.ELUL);
    expect(jewishDate.getJewishDayOfMonth(), 14);
  });

  test('setting and reading a date agree with fromDateTime', () {
    final DateTime date = DateTime(2026, 8, 27);

    final JewishDate viaSetter = JewishDate();
    viaSetter.setGregorianDate(DateTime.utc(date.year, date.month, date.day));

    final JewishDate viaDateTime = JewishDate.fromLocalDate(date);

    expect(viaSetter.getLocalDate().month, viaDateTime.getLocalDate().month);
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
      final JewishDate original = JewishDate.fromLocalDate(date);
      final JewishDate copy = JewishDate();
      copy.setGregorianDate(original.getLocalDate());

      expect(copy.getLocalDate().year, date.year);
      expect(copy.getLocalDate().month, date.month);
      expect(copy.getLocalDate().day, date.day);
    }
  });

  test('clone keeps the date it was made from', () {
    final JewishDate original = JewishDate.fromLocalDate(DateTime(2026, 12, 31));
    final JewishDate copy = original.clone();

    expect(copy.getLocalDate().year, 2026);
    expect(copy.getLocalDate().month, 12);
    expect(copy.getLocalDate().day, 31);
    expect(copy.getJewishMonth(), original.getJewishMonth());
    expect(copy.getJewishDayOfMonth(), original.getJewishDayOfMonth());
  });

  test('the day melacha is judged on is the day the calendar is set to', () {
    // isAssurBemelacha reads its day through setGregorianDate, so a month shifted
    // there answered for the wrong day entirely. Friday 21 August 2026 after
    // shkia is erev shabbos; a month on it would have been a Monday.
    final ComprehensiveZmanimCalendar zmanimCalendar = ComprehensiveZmanimCalendar.withGeoLocation(
        GeoLocation.withZoneId('New York', 40.7128, -74.0060, tz.UTC));
    zmanimCalendar.setLocalDate(DateTime.utc(2026, 8, 21));

    expect(JewishCalendar.fromLocalDate(DateTime(2026, 8, 21)).getDayOfWeek(), 6,
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
