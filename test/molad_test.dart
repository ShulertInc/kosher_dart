/// Tests for the molad as a point in time, and the Kiddush Levana zmanim built on it.
///
/// The traditional molad is reckoned in local time at Har Habayis, whose longitude
/// of 35.2354° sits 0.2354° east of the 35° line its GMT+2 timezone is measured
/// from. Local mean time there therefore runs 20 minutes, 56 seconds and 496
/// milliseconds ahead of standard time, and KosherJava subtracts exactly that to
/// get the molad in Yerushalayim standard time. This port used to compute the
/// offset from a GeoLocation built around `DateTime.now()` - so it varied with the
/// machine's own timezone - and then threw the result away, because `DateTime.add`
/// returns a new value rather than mutating in place as Java's `Calendar.add` does.
/// It also lost the sub-second part of the molad, computing the milliseconds as
/// `1000 * (moladSeconds - moladSeconds)`, which is always zero.
///
/// The moments below are written in UTC. Yerushalayim standard time is GMT+2 the
/// year round, so a molad whose clock reading is 08:15 there is 06:15 UTC; reading
/// those clock fields as the machine's own local time, as this port also used to,
/// moved the moment by the gap between the two zones.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  /// The gap between local mean time at Har Habayis and Yerushalayim standard time.
  const Duration localMeanTimeOffset =
      Duration(minutes: 20, seconds: 56, milliseconds: 496);

  test('molad is the molad in standard time, not local mean time', () {
    final JewishCalendar jewishCalendar =
        JewishCalendar.fromDateTime(DateTime(2026, 8, 27));
    final JewishDate molad = jewishCalendar.getMolad();

    // Molad of Elul 5786: Thursday 13 August 2026, 8 hours 15 minutes 0 chalakim.
    expect(molad.getMoladHours(), 8);
    expect(molad.getMoladMinutes(), 15);
    expect(molad.getMoladChalakim(), 0);

    expect(jewishCalendar.getMoladAsDateTime().toUtc(),
        DateTime.utc(2026, 8, 13, 6, 15).subtract(localMeanTimeOffset));
    expect(jewishCalendar.getMoladAsDateTime().toUtc(),
        DateTime.utc(2026, 8, 13, 5, 54, 3, 504));
  });

  test('chalakim that are not whole seconds keep their milliseconds', () {
    final JewishCalendar jewishCalendar =
        JewishCalendar.fromDateTime(DateTime(2027, 1, 10));
    final JewishDate molad = jewishCalendar.getMolad();

    // 23 hours 55 minutes 5 chalakim. A chelek is 10/3 of a second, so five of
    // them are 16.666 seconds - 16 seconds and 666 milliseconds.
    expect(molad.getMoladHours(), 23);
    expect(molad.getMoladMinutes(), 55);
    expect(molad.getMoladChalakim(), 5);

    expect(jewishCalendar.getMoladAsDateTime().toUtc(),
        DateTime.utc(2027, 1, 7, 21, 55, 16, 666).subtract(localMeanTimeOffset));
    expect(jewishCalendar.getMoladAsDateTime().toUtc(),
        DateTime.utc(2027, 1, 7, 21, 34, 20, 170));
    expect(jewishCalendar.getMoladAsDateTime().toUtc().millisecond, isNot(0));
  });

  test('every day of a month reports that month s molad', () {
    // The offset applied is a constant of Har Habayis, not anything read off the
    // host, so any day of Sivan 5786 must give the same answer.
    final DateTime fromEarly =
        JewishCalendar.fromDateTime(DateTime(2026, 5, 20)).getMoladAsDateTime();
    final DateTime fromLate =
        JewishCalendar.fromDateTime(DateTime(2026, 6, 10)).getMoladAsDateTime();

    expect(fromEarly, fromLate);
    expect(fromEarly.toUtc(), DateTime.utc(2026, 5, 16, 15, 41, 53, 504));
    // 18 hours 2 minutes 15 chalakim, which is 50 whole seconds.
    expect(fromEarly.toUtc(),
        DateTime.utc(2026, 5, 16, 16, 2, 50).subtract(localMeanTimeOffset));
  });

  test('Kiddush Levana zmanim are reckoned from that moment', () {
    final JewishCalendar jewishCalendar =
        JewishCalendar.fromDateTime(DateTime(2026, 8, 27));
    final DateTime molad = jewishCalendar.getMoladAsDateTime();

    expect(jewishCalendar.getTchilasZmanKidushLevana3Days(),
        molad.add(const Duration(days: 3)));
    expect(jewishCalendar.getTchilasZmanKidushLevana7Days(),
        molad.add(const Duration(days: 7)));
    expect(jewishCalendar.getSofZmanKidushLevana15Days(),
        molad.add(const Duration(days: 15)));
    // Half of 29 days, 12 hours and 793 chalakim.
    expect(
        jewishCalendar.getSofZmanKidushLevanaBetweenMoldos(),
        molad.add(const Duration(
            days: 14, hours: 18, minutes: 22, seconds: 1, milliseconds: 666)));
  });
}
