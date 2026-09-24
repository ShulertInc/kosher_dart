/// Tests for the solar calculations, checked as moments in time rather than as clock
/// readings so that they hold whatever time zone the machine running them is in.
///
/// The expected values come from kosher-rust, which is parity tested against
/// KosherJava: https://github.com/dickermoshe/kosher-rust
library;

import 'package:kosher_dart/kosher_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:test/test.dart';

ComprehensiveZmanimCalendar calendarFor(
  double latitude,
  double longitude,
  double elevation,
  DateTime date, {
  bool useElevation = false,
}) {
  final ComprehensiveZmanimCalendar calendar = ComprehensiveZmanimCalendar.withGeoLocation(
    GeoLocation.withElevation('test', latitude, longitude, elevation, tz.UTC),
  );
  calendar.setLocalDate(date);
  calendar.setUseElevation(useElevation);
  return calendar;
}

/// Jerusalem, which is high enough for the elevation adjustment to be visible.
ComprehensiveZmanimCalendar jerusalem(DateTime date, {bool useElevation = false}) =>
    calendarFor(31.778, 35.2354, 754, date, useElevation: useElevation);

/// kosher-rust keeps nanoseconds where `DateTime` keeps milliseconds, and a zman built
/// on a division of the day can land either side of the last one.
void expectMoment(DateTime? actual, DateTime expected) {
  expect(actual, isNotNull);
  expect(actual!.toUtc().millisecondsSinceEpoch,
      closeTo(expected.millisecondsSinceEpoch, 2),
      reason: 'expected $expected, got ${actual.toUtc()}');
}

void expectMillisecond(DateTime? actual, DateTime expected) {
  expect(actual, isNotNull);
  expect(actual!.toUtc().millisecondsSinceEpoch, expected.millisecondsSinceEpoch,
      reason: 'expected $expected, got ${actual.toUtc()}');
}

void main() {
  final DateTime springDay = DateTime.utc(1990, 3, 20);

  group('fixed local chatzos', () {
    test('is noon local mean time, wherever the machine is', () {
      // 35.2354° east is 2 hours 20 minutes 56.496 seconds of longitude, so local mean
      // noon there is that much before noon UTC. Reading the offset off the machine's
      // own time zone, as this once did, put the answer on the wrong day entirely.
      expectMillisecond(jerusalem(springDay).getFixedLocalChatzosHayom(), DateTime.utc(1990, 3, 20, 9, 39, 3, 504));
    });

    test('is noon UTC on the prime meridian', () {
      expectMillisecond(calendarFor(51.4772, 0, 0, springDay).getFixedLocalChatzosHayom(), DateTime.utc(1990, 3, 20, 12));
    });
  });

  group('chatzos', () {
    test('is the sun crossing the meridian, not the middle of the day', () {
      // The midpoint of sunrise and sunset misses the transit by up to a minute or so,
      // by more the further from the equator.
      expectMillisecond(jerusalem(springDay).getChatzosHayom(), DateTime.utc(1990, 3, 20, 9, 46, 37, 603));

      final ComprehensiveZmanimCalendar reykjavik =
          calendarFor(64.1466, -21.9426, 0, DateTime.utc(1992, 5, 20));
      expectMillisecond(reykjavik.getChatzosHayom(), DateTime.utc(1992, 5, 20, 13, 24, 17, 206));

      final DateTime midpoint = reykjavik.getSunTransit(
          reykjavik.getSeaLevelSunrise(), reykjavik.getSeaLevelSunset())!;
      expect((midpoint.difference(reykjavik.getChatzosHayom()!)).inSeconds.abs(),
          greaterThan(60));
    });

    test('solar midnight is the transit on the far side of the earth', () {
      expectMillisecond(calendarFor(64.1466, -21.9426, 0, DateTime.utc(1992, 5, 20))
              .getSolarMidnight(), DateTime.utc(1992, 5, 21, 1, 24, 19, 111));
    });
  });

  group('elevation', () {
    test('alos 60 follows the elevation setting like the other offsets do', () {
      // It used to read visual sunrise whatever the setting said, so at 754 metres it
      // came out four minutes early.
      expectMillisecond(jerusalem(springDay).getAlos60Minutes(), DateTime.utc(1990, 3, 20, 2, 43, 29, 286));
      expect(
          jerusalem(springDay).getAlos60Minutes(),
          jerusalem(springDay)
              .getSeaLevelSunrise()!
              .subtract(const Duration(minutes: 60)));
      expect(
          jerusalem(springDay, useElevation: true).getAlos60Minutes(),
          jerusalem(springDay, useElevation: true)
              .getSunrise()!
              .subtract(const Duration(minutes: 60)));
    });
  });

  test('zmanim keep their milliseconds', () {
    expectMillisecond(jerusalem(springDay).getSunrise(), DateTime.utc(1990, 3, 20, 3, 39, 20, 645));
  });

  group('where the sun never reaches the dip', () {
    // London in high summer: the sun does not get 18° below the horizon at all, so
    // there is no alos of 18° and nothing that is built on one.
    final ComprehensiveZmanimCalendar london =
        calendarFor(51.5074, -0.1278, 0, DateTime.utc(1993, 6, 27));

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
      expectMillisecond(london.getSunrise(), DateTime.utc(1993, 6, 27, 3, 45, 9, 411));
      expect(london.getSunset(), isNotNull);
    });
  });


  group('the zmanim brought over from kosher-rust', () {
    final ComprehensiveZmanimCalendar calendar = jerusalem(springDay);

    test('the Ahavat Shalom zmanim', () {
      expectMoment(calendar.getMinchaGedolaAhavatShalom(),
          DateTime.utc(1990, 3, 20, 10, 20, 28, 580));
      expectMoment(calendar.getMinchaKetanaAhavatShalom(),
          DateTime.utc(1990, 3, 20, 13, 14, 52, 738));
      expectMoment(calendar.getPlagAhavatShalom(),
          DateTime.utc(1990, 3, 20, 14, 39, 33, 125));
    });

    test('samuch lemincha ketana is nine shaos zmaniyos into the day', () {
      expectMoment(calendar.getSamuchLeMinchaKetanaGRA(),
          DateTime.utc(1990, 3, 20, 12, 48, 34, 9));
      expect(calendar.getSamuchLeMinchaKetana16Point1Degrees(), isNotNull);
      expect(calendar.getSamuchLeMinchaKetana72Minutes(), isNotNull);
    });

    test('the degree based zmanim kosher_dart was missing', () {
      expectMillisecond(calendar.getMisheyakir12Point85Degrees(), DateTime.utc(1990, 3, 20, 2, 46, 49, 561));
      expectMillisecond(calendar.getTzaisGeonim4Point42Degrees(), DateTime.utc(1990, 3, 20, 16, 7, 8, 794));
      expect(calendar.getTzaisGeonim4Point66Degrees(), isNotNull);
    });

    test('chatzos as half the day is not quite the transit', () {
      expectMoment(calendar.getChatzosHayomAsHalfDay(),
          DateTime.utc(1990, 3, 20, 9, 46, 52, 435));
      expect(calendar.getChatzosHayomAsHalfDay(), isNot(calendar.getChatzosHayom()));
      // And null where there is no day to halve.
      expect(calendarFor(78.22, 15.63, 0, DateTime.utc(1992, 5, 20)).getChatzosHayomAsHalfDay(),
          isNull);
    });
  });

  group('inside the arctic circle', () {
    // Longyearbyen in a midnight sun, where the sun neither rises nor sets.
    ComprehensiveZmanimCalendar longyearbyen(DateTime date) =>
        calendarFor(78.22, 15.63, 0, date);

    final DateTime midnightSun = DateTime.utc(1992, 5, 20);
    final DateTime polarNight = DateTime.utc(1995, 12, 3);

    test('the Ben Ish Chai substitutes answer where sunrise and sunset do not', () {
      final ComprehensiveZmanimCalendar calendar = longyearbyen(midnightSun);
      expect(calendar.getSunrise(), isNull);
      expect(calendar.getSunset(), isNull);

      expectMillisecond(calendar.getPolarSunriseBenIshChai(), DateTime.utc(1992, 5, 20, 5, 11, 25, 151));
      expectMillisecond(calendar.getPolarSunsetBenIshChai(), DateTime.utc(1992, 5, 20, 16, 36, 28, 111));

      final ComprehensiveZmanimCalendar dark = longyearbyen(polarNight);
      expectMillisecond(dark.getPolarSunriseBenIshChai(), DateTime.utc(1995, 12, 3, 4, 27, 40, 165));
      expectMillisecond(dark.getPolarSunsetBenIshChai(), DateTime.utc(1995, 12, 3, 17, 6, 39, 793));
    });

    test('they answer null on a day that has a real sunrise and sunset', () {
      expect(jerusalem(springDay).getPolarSunriseBenIshChai(), isNull);
      expect(jerusalem(springDay).getPolarSunsetBenIshChai(), isNull);
    });

    test('a day with no sunrise leaves every zman of the day null, not thrown', () {
      final ComprehensiveZmanimCalendar calendar = longyearbyen(midnightSun);

      // getTemporalHour used to force unwrap the sunrise it fell back on.
      expect(calendar.getTemporalHour(), isNull);
      expect(calendar.getSofZmanTfilaGRA(), isNull);
      expect(calendar.getAlos72Zmanis(), isNull);
      expect(calendar.getSofZmanShmaAteretTorah(), isNull);
      expect(calendar.getPlagHamincha96MinutesZmanis(), isNull);
    });
  });
}
