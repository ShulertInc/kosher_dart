/// Tests for weekly Torah portion (parsha) formatting via [HebrewDateFormatter].
///
/// The Torah is divided into 54 portions read on Shabbat throughout the year.
/// The schedule differs between Israel and the Diaspora because Israel
/// celebrates one day of Yom Tov while the Diaspora celebrates two, causing
/// the portions to fall on different Shabbatot for several weeks each year.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  HebrewDateFormatter hdf = HebrewDateFormatter();

  // Wednesday May 25, 2022: Israel reads Bamidbar; Diaspora reads Bechukosai.
  test('formatParshah of getUpcomingParshah', () async {
    DateTime dateTime = DateTime(2022, 5, 25);
    JewishCalendar jewishCalendar = JewishCalendar.fromLocalDate(dateTime);
    jewishCalendar.setInIsrael(true);
    print("Testing WeeklyParsha - inIsreal = true");
    expect(hdf.formatParshah(jewishCalendar.getUpcomingParshah()), "Bamidbar");
    print("Pass");
    print("Testing WeeklyParsha - inIsreal = false");
    jewishCalendar.setInIsrael(false);
    expect(hdf.formatParshah(jewishCalendar.getUpcomingParshah()), "Bechukosai");
    print("Pass");
  });

  // Shabbat May 28, 2022: Israel reads Bamidbar; Diaspora reads Bechukosai.
  test('formatParsha', () async {
    DateTime dateTime = DateTime(2022, 5, 28);
    JewishCalendar jewishCalendar = JewishCalendar.fromLocalDate(dateTime);
    jewishCalendar.setInIsrael(true);
    print("Testing Parshah - inIsreal = true");
    expect(hdf.formatParshah(jewishCalendar), "Bamidbar");
    print("Pass");
    print("Testing Parshah - inIsreal = false");
    jewishCalendar.setInIsrael(false);
    expect(hdf.formatParshah(jewishCalendar), "Bechukosai");
    print("Pass");
  });
}
