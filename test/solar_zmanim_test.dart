/// Tests for the solar calculations, checked as moments in time rather than as clock
/// readings so that they hold whatever time zone the machine running them is in.
///
/// The expected values come from kosher-rust, which is parity tested against
/// KosherJava: https://github.com/dickermoshe/kosher-rust
library;

import 'package:kosher_dart/kosher_dart.dart';
import 'package:test/test.dart';

ComplexZmanimCalendar calendarFor(
  double latitude,
  double longitude,
  double elevation,
  DateTime date, {
  bool useElevation = false,
}) {
  final ComplexZmanimCalendar calendar = ComplexZmanimCalendar.intGeoLocation(
    GeoLocation.setLocation('test', latitude, longitude, date, elevation),
  );
  calendar.setUseElevation(useElevation);
  return calendar;
}

/// Jerusalem, which is high enough for the elevation adjustment to be visible.
ComplexZmanimCalendar jerusalem(DateTime date, {bool useElevation = false}) =>
    calendarFor(31.778, 35.2354, 754, date, useElevation: useElevation);

void main() {
  final DateTime springDay = DateTime(1990, 3, 20);

  group('fixed local chatzos', () {
    test('is noon local mean time, wherever the machine is', () {
      // 35.2354° east is 2 hours 20 minutes 56.496 seconds of longitude, so local mean
      // noon there is that much before noon UTC. Reading the offset off the machine's
      // own time zone, as this once did, put the answer on the wrong day entirely.
      expect(jerusalem(springDay).getFixedLocalChatzos()!.toUtc(),
          DateTime.utc(1990, 3, 20, 9, 39, 3, 504));
    });

    test('is noon UTC on the prime meridian', () {
      expect(
          calendarFor(51.4772, 0, 0, springDay).getFixedLocalChatzos()!.toUtc(),
          DateTime.utc(1990, 3, 20, 12));
    });
  });

  group('chatzos', () {
    test('is the sun crossing the meridian, not the middle of the day', () {
      // The midpoint of sunrise and sunset misses the transit by up to a minute or so,
      // by more the further from the equator.
      expect(jerusalem(springDay).getChatzos()!.toUtc(),
          DateTime.utc(1990, 3, 20, 9, 46, 37, 603));

      final ComplexZmanimCalendar reykjavik =
          calendarFor(64.1466, -21.9426, 0, DateTime(1992, 5, 20));
      expect(reykjavik.getChatzos()!.toUtc(),
          DateTime.utc(1992, 5, 20, 13, 24, 17, 206));

      final DateTime midpoint = reykjavik.getSunTransit(
          reykjavik.getSeaLevelSunrise(), reykjavik.getSeaLevelSunset())!;
      expect((midpoint.difference(reykjavik.getChatzos()!)).inSeconds.abs(),
          greaterThan(60));
    });

    test('solar midnight is the transit on the far side of the earth', () {
      expect(
          calendarFor(64.1466, -21.9426, 0, DateTime(1992, 5, 20))
              .getSolarMidnight()!
              .toUtc(),
          DateTime.utc(1992, 5, 21, 1, 24, 19, 111));
    });
  });

  group('elevation', () {
    test('alos 60 follows the elevation setting like the other offsets do', () {
      // It used to read visual sunrise whatever the setting said, so at 754 metres it
      // came out four minutes early.
      expect(jerusalem(springDay).getAlos60()!.toUtc(),
          DateTime.utc(1990, 3, 20, 2, 43, 29, 286));
      expect(
          jerusalem(springDay).getAlos60(),
          jerusalem(springDay)
              .getSeaLevelSunrise()!
              .subtract(const Duration(minutes: 60)));
      expect(
          jerusalem(springDay, useElevation: true).getAlos60(),
          jerusalem(springDay, useElevation: true)
              .getSunrise()!
              .subtract(const Duration(minutes: 60)));
    });
  });

  test('zmanim keep their milliseconds', () {
    expect(jerusalem(springDay).getSunrise()!.toUtc(),
        DateTime.utc(1990, 3, 20, 3, 39, 20, 645));
  });

  group('where the sun never reaches the dip', () {
    // London in high summer: the sun does not get 18° below the horizon at all, so
    // there is no alos of 18° and nothing that is built on one.
    final ComplexZmanimCalendar london =
        calendarFor(51.5074, -0.1278, 0, DateTime(1993, 6, 27));

    test('the degree based zmanim are null rather than invented', () {
      expect(london.getAlos18Degrees(), isNull);
      expect(london.getAlos26Degrees(), isNull);
      expect(london.getBeginAstronomicalTwilight(), isNull);
    });

    test('a zman of a day that has no start is null, not the GRA day', () {
      expect(london.getSofZmanShmaMGA18Degrees(), isNull);
      expect(london.getPlagHamincha18Degrees(), isNull);
      // The GRA day itself is fine there; it is only the 18° day that does not exist.
      expect(london.getSofZmanShmaGRA(), isNotNull);
    });

    test('sunrise and sunset themselves still answer', () {
      expect(london.getSunrise()!.toUtc(), DateTime.utc(1993, 6, 27, 3, 45, 9, 411));
      expect(london.getSunset(), isNotNull);
    });
  });

  test('tonight midnight is tomorrow, not last night again', () {
    final ComplexZmanimCalendar calendar = jerusalem(springDay);
    expect(
        calendar.getMidnightTonight()!
            .difference(calendar.getMidnightLastNight()!)
            .inHours,
        24);
  });
}
