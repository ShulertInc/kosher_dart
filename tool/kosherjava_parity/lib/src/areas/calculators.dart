import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;
import 'package:kosher_dart/src/astronomical_calendar.dart' as kd;
import 'package:kosher_dart/src/util/astronomical_calculator.dart' as kd;
import 'package:kosher_dart/src/util/noaa_calculator.dart' as kd;
import 'package:kosher_dart/src/util/sun_times_calculator.dart' as kd;
import 'package:timezone/timezone.dart' as tz;

import '../area.dart';
import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';
import '../zones.dart';

const _day = 86400000;

const _zeniths = [90.0, 90.0, 90.0, 96.0, 102.0, 108.0, 106.1, 108.8, 98.5, 97.8, 93.25, 89.0, 84.0, 120.0];

int? _millis(kj.Instant? instant) {
  if (instant == null) return null;
  final millis = instant.toEpochMilli();
  instant.release();
  return millis;
}

double? _durationMillis(kj.Duration? duration) {
  if (duration == null) return null;
  final nanos = duration.toNanos();
  duration.release();
  return nanos / 1e6;
}

void _hours(Report report, String check, String input, double Function() java, double Function() dart) {
  final javaValue = attempt(java);
  final dartValue = attempt(dart);
  if (javaValue is Value<double> && dartValue is Value<double>) {
    final j = javaValue.value;
    final d = dartValue.value;
    if (j.isFinite && d.isFinite) {
      final nearest = j + ((d - j + 12) % 24 - 12);
      if (nearest != d) {
        report.real(check, '$input dart=$d', javaValue, Value(nearest));
        return;
      }
    }
  }
  report.real(check, input, javaValue, dartValue);
}

void _dip(Report report, String check, String input, double Function() java, double Function() dart) {
  final javaValue = attempt(java);
  final dartValue = attempt(dart);
  if (javaValue is Value<double> && dartValue is Value<double>) {
    final j = javaValue.value;
    final d = dartValue.value;
    if (!j.isNaN && !d.isNaN && j != d && (d - j).abs() <= 1e-4) {
      report.record(check, Outcome.rounding, input, 'java $j dart $d', difference: d - j);
      return;
    }
  }
  report.real(check, input, javaValue, dartValue, tolerance: 0);
}

Got<String> _accepted(String Function() body) {
  try {
    return Value(body());
  } catch (_) {
    return const Value('rejected');
  }
}

class _Setup {
  _Setup(this.rng, this.zones, this.id) {
    date = _date(rng);
    place = randomPlace(rng, zones, date);
    midnight = zones.javaStartOfDay(place.zone, date.year, date.month, date.day);
    location = zones.dartFromJava(place.zone, midnight - 3 * _day, midnight + 4 * _day);
    dartDate = tz.TZDateTime.fromMillisecondsSinceEpoch(location, midnight);
    final name = 'case'.toJString();
    javaGeo = kj.GeoLocation.new$1(name, place.latitude, place.longitude, place.elevation, zones.java(place.zone));
    name.release();
    javaDate = kj.LocalDate.of$1(date.year, date.month, date.day)!;
    dartGeo = kd.GeoLocation.setLocation('case', place.latitude, place.longitude, dartDate, place.elevation);
  }

  final Random rng;
  final Zones zones;
  final String id;
  late final CivilDate date;
  late final Place place;
  late final int midnight;
  late final tz.Location location;
  late final tz.TZDateTime dartDate;
  late final kj.GeoLocation javaGeo;
  late final kj.LocalDate javaDate;
  late final kd.GeoLocation dartGeo;

  String get input => '$id date=$date $place';

  bool get dateExists => dartDate.year == date.year && dartDate.month == date.month && dartDate.day == date.day;

  void release() {
    javaGeo.release();
    javaDate.release();
  }

  static CivilDate _date(Random rng) {
    final year = between(rng, 1900, 2300);
    return switch (rng.nextInt(12)) {
      0 => CivilDate(year, 1, 1),
      1 => CivilDate(year, 12, 31),
      2 => CivilDate(year, 2, isGregorianLeapYear(year) ? 29 : 28),
      3 => CivilDate(year, 3, 1),
      _ => randomDate(rng, year, year),
    };
  }
}

class CalculatorsArea extends Area {
  CalculatorsArea(super.zones);

  @override
  String get name => 'calculators';

  @override
  void run(int seed, Iterable<int> indexes, Report report) {
    for (final index in indexes) {
      final rng = caseRandom(seed, name, index);
      final setup = _Setup(rng, zones, 'calculators#$index seed=$seed');
      if (!setup.dateExists) {
        report.note('skipped: the date does not exist in its zone, so no DateTime can name it');
        setup.release();
        continue;
      }
      _raw(setup, report, 'noaa', kj.NOAACalculator(), kd.NOAACalculator());
      _raw(setup, report, 'suntimes', kj.SunTimesCalculator(), kd.SunTimesCalculator());
      _solarPosition(setup, report);
      _settings(setup, report);
      final sunTimes = chance(rng, 0.3);
      _calendar(setup, report, sunTimes, dips: index % 25 == 0);
      setup.release();
    }
  }

  void _raw(
    _Setup setup,
    Report report,
    String calculatorName,
    kj.AstronomicalCalculator java,
    kd.AstronomicalCalculator dart,
  ) {
    final rng = setup.rng;
    final zenith = chance(rng, 0.7) ? pick(rng, _zeniths) : (chance(rng, 0.8) ? uniform(rng, 80, 120) : uniform(rng, -10, 200));
    final adjust = chance(rng, 0.5);
    final input = '${setup.input} zenith=$zenith adjustForElevation=$adjust';
    final prefix = 'calculators.$calculatorName';
    final utcDate = DateTime.utc(setup.date.year, setup.date.month, setup.date.day);

    _hours(
      report,
      '$prefix.getUTCSunrise',
      input,
      () => java.getUTCSunrise(setup.javaDate, setup.javaGeo, zenith, adjust),
      () => dart.getUTCSunrise(setup.dartDate, setup.dartGeo, zenith, adjust),
    );
    _hours(
      report,
      '$prefix.getUTCSunset',
      input,
      () => java.getUTCSunset(setup.javaDate, setup.javaGeo, zenith, adjust),
      () => dart.getUTCSunset(setup.dartDate, setup.dartGeo, zenith, adjust),
    );
    _hours(
      report,
      '$prefix.getUTCSunrise.utcDateTime',
      input,
      () => java.getUTCSunrise(setup.javaDate, setup.javaGeo, zenith, adjust),
      () => dart.getUTCSunrise(utcDate, setup.dartGeo, zenith, adjust),
    );
    _hours(
      report,
      '$prefix.getUTCSunset.utcDateTime',
      input,
      () => java.getUTCSunset(setup.javaDate, setup.javaGeo, zenith, adjust),
      () => dart.getUTCSunset(utcDate, setup.dartGeo, zenith, adjust),
    );
    _hours(
      report,
      '$prefix.getUTCNoon',
      setup.input,
      () => java.getUTCNoon(setup.javaDate, setup.javaGeo),
      () => dart.getUTCNoon(setup.dartDate, setup.dartGeo),
    );
    _hours(
      report,
      '$prefix.getUTCMidnight',
      setup.input,
      () => java.getUTCMidnight(setup.javaDate, setup.javaGeo),
      () => dart.getUTCMidnight(setup.dartDate, setup.dartGeo),
    );

    final azimuth = pick(rng, const [90.0, 270.0]);
    _hours(
      report,
      '$prefix.getTimeAtAzimuth',
      '${setup.input} azimuth=$azimuth',
      () => java.getTimeAtAzimuth(setup.javaDate, setup.javaGeo, azimuth),
      () => dart.getUTCTimeAtAzimuth(setup.dartDate, setup.dartGeo, azimuth),
    );
    final otherAzimuth = uniform(rng, 0, 360);
    _hours(
      report,
      '$prefix.getTimeAtAzimuth.otherAzimuth',
      '${setup.input} azimuth=$otherAzimuth',
      () => java.getTimeAtAzimuth(setup.javaDate, setup.javaGeo, otherAzimuth),
      () => dart.getUTCTimeAtAzimuth(setup.dartDate, setup.dartGeo, otherAzimuth),
    );

    report.exact(
      '$prefix.getCalculatorName',
      setup.input,
      attempt(() => java.calculatorName!.toDartString(releaseOriginal: true)),
      attempt(() => dart.getCalculatorName()),
    );
    report.real(
      '$prefix.getRefraction',
      setup.input,
      attempt(() => java.refraction),
      attempt(() => dart.getRefraction()),
    );
    report.real(
      '$prefix.getSolarRadius',
      setup.input,
      attempt(() => java.solarRadius),
      attempt(() => dart.getSolarRadius()),
    );
    report.real(
      '$prefix.getEarthRadius',
      setup.input,
      attempt(() => java.earthRadius),
      attempt(() => dart.getEarthRadius()),
    );
    report.real(
      '$prefix.getApparentSolarRadius',
      setup.input,
      attempt(() => java.getApparentSolarRadius(setup.javaDate)),
      attempt(() => dart.getApparentSolarRadius(setup.dartDate)),
    );
    java.release();
  }

  void _solarPosition(_Setup setup, Report report) {
    final rng = setup.rng;
    final at = setup.midnight + rng.nextInt(_day);
    final input = '${setup.input} instant=${iso(at)}';
    final java = kj.NOAACalculator();
    final instant = kj.Instant.ofEpochMilli(at)!;
    final utc = DateTime.fromMillisecondsSinceEpoch(at, isUtc: true);
    report.real(
      'calculators.noaa.getSolarElevation',
      input,
      attempt(() => java.getSolarElevation(instant, setup.javaGeo)),
      attempt(() => kd.NOAACalculator().getSolarElevation(utc, setup.dartGeo)),
      tolerance: 1e-6,
    );
    report.real(
      'calculators.noaa.getSolarAzimuth',
      input,
      attempt(() => java.getSolarAzimuth(instant, setup.javaGeo)),
      attempt(() => kd.NOAACalculator().getSolarAzimuth(utc, setup.dartGeo)),
      tolerance: 1e-6,
    );
    final zoned = tz.TZDateTime.fromMillisecondsSinceEpoch(setup.location, at);
    report.real(
      'calculators.noaa.getSolarElevation.zonedDateTime',
      input,
      attempt(() => java.getSolarElevation(instant, setup.javaGeo)),
      attempt(() => kd.NOAACalculator().getSolarElevation(zoned, setup.dartGeo)),
      tolerance: 1e-6,
    );
    instant.release();
    java.release();
  }

  void _settings(_Setup setup, Report report) {
    final rng = setup.rng;
    final refraction = uniform(rng, 0, 1.5);
    final solarRadius = pick(rng, [uniform(rng, 0, 0.5), 0.0, -0.1, double.nan]);
    final earthRadius = uniform(rng, 6300, 6400);
    final zenith = chance(rng, 0.8) ? 90.0 : pick(rng, _zeniths);
    final apparent = pick(rng, const [null, true, false]);
    final input = '${setup.input} refraction=$refraction solarRadius=$solarRadius earthRadius=$earthRadius '
        'useApparentSolarRadius=${apparent ?? 'after setSolarRadius'} zenith=$zenith';
    for (final calculatorName in const ['noaa', 'suntimes']) {
      final kj.AstronomicalCalculator java = calculatorName == 'noaa' ? kj.NOAACalculator() : kj.SunTimesCalculator();
      final kd.AstronomicalCalculator dart = calculatorName == 'noaa' ? kd.NOAACalculator() : kd.SunTimesCalculator();
      final prefix = 'calculators.$calculatorName';
      report.exact(
        '$prefix.setSolarRadius',
        input,
        _accepted(() {
          java.solarRadius = solarRadius;
          return '${java.solarRadius}';
        }),
        _accepted(() {
          dart.setSolarRadius(solarRadius);
          return '${dart.getSolarRadius()}';
        }),
      );
      if (solarRadius.isNaN || solarRadius < 0) {
        java.release();
        continue;
      }
      java.refraction = refraction;
      java.earthRadius = earthRadius;
      dart.setRefraction(refraction);
      dart.setEarthRadius(earthRadius);
      if (apparent != null) {
        java.useApparentSolarRadius = apparent;
        dart.setUseApparentSolarRadius(apparent);
      }
      report.exact('$prefix.isUseApparentSolarRadius', input, attempt(() => java.isUseApparentSolarRadius),
          attempt(() => dart.isUseApparentSolarRadius()));
      _hours(
        report,
        '$prefix.getUTCSunrise.configured',
        input,
        () => java.getUTCSunrise(setup.javaDate, setup.javaGeo, zenith, true),
        () => dart.getUTCSunrise(setup.dartDate, setup.dartGeo, zenith, true),
      );
      _hours(
        report,
        '$prefix.getUTCSunset.configured',
        input,
        () => java.getUTCSunset(setup.javaDate, setup.javaGeo, zenith, true),
        () => dart.getUTCSunset(setup.dartDate, setup.dartGeo, zenith, true),
      );
      java.release();
    }
  }

  void _calendar(_Setup setup, Report report, bool sunTimes, {required bool dips}) {
    final rng = setup.rng;
    final java = kj.ComprehensiveZmanimCalendar.new1(setup.javaGeo);
    java.localDate = setup.javaDate;
    final dart = kd.ComplexZmanimCalendar.intGeoLocation(setup.dartGeo);
    if (sunTimes) {
      final calculator = kj.SunTimesCalculator();
      java.astronomicalCalculator = calculator;
      calculator.release();
      dart.setAstronomicalCalculator(kd.SunTimesCalculator());
    }
    final prefix = 'calculators.calendar.${sunTimes ? 'suntimes' : 'noaa'}';
    final zenith = chance(rng, 0.6) ? pick(rng, _zeniths) : (chance(rng, 0.8) ? uniform(rng, 80, 120) : uniform(rng, -10, 200));
    final input = '${setup.input} calculator=${sunTimes ? 'SunTimes' : 'NOAA'} zenith=$zenith';

    report.instant(
      '$prefix.getSunriseOffsetByDegrees',
      input,
      attempt(() => _millis(java.getSunriseOffsetByDegrees(zenith))),
      attempt(() => dart.getSunriseOffsetByDegrees(zenith)?.flooredMillis),
    );
    report.instant(
      '$prefix.getSunsetOffsetByDegrees',
      input,
      attempt(() => _millis(java.getSunsetOffsetByDegrees(zenith))),
      attempt(() => dart.getSunsetOffsetByDegrees(zenith)?.flooredMillis),
    );
    _hours(report, '$prefix.getUTCSunrise', input, () => java.getUTCSunrise(zenith), () => dart.getUTCSunrise(zenith));
    _hours(
      report,
      '$prefix.getUTCSeaLevelSunrise',
      input,
      () => java.getUTCSeaLevelSunrise(zenith),
      () => dart.getUTCSeaLevelSunrise(zenith),
    );
    _hours(report, '$prefix.getUTCSunset', input, () => java.getUTCSunset(zenith), () => dart.getUTCSunset(zenith));
    _hours(
      report,
      '$prefix.getUTCSeaLevelSunset',
      input,
      () => java.getUTCSeaLevelSunset(zenith),
      () => dart.getUTCSeaLevelSunset(zenith),
    );

    final anchors = <String, int?>{
      'null': null,
      'sunrise': dart.getSunrise()?.flooredMillis,
      'sunset': dart.getSunset()?.flooredMillis,
      'seaLevelSunrise': dart.getSeaLevelSunrise()?.flooredMillis,
      'seaLevelSunset': dart.getSeaLevelSunset()?.flooredMillis,
      'random': setup.midnight + rng.nextInt(_day),
      'randomEarlier': setup.midnight - rng.nextInt(_day),
    };
    final startName = pick(rng, anchors.keys.toList());
    final endName = pick(rng, anchors.keys.toList());
    final start = anchors[startName];
    final end = anchors[endName];
    final spanInput =
        '$input start=$startName ${start == null ? '' : iso(start)} end=$endName ${end == null ? '' : iso(end)}';
    final javaStart = start == null ? null : kj.Instant.ofEpochMilli(start);
    final javaEnd = end == null ? null : kj.Instant.ofEpochMilli(end);
    final dartStart = start == null ? null : DateTime.fromMillisecondsSinceEpoch(start, isUtc: true);
    final dartEnd = end == null ? null : DateTime.fromMillisecondsSinceEpoch(end, isUtc: true);
    report.real(
      '$prefix.getTemporalHour(start, end)',
      spanInput,
      attempt(() => _durationMillis(java.getTemporalHour(javaStart, javaEnd))),
      attempt(() => dart.getTemporalHour(dartStart, dartEnd)),
      tolerance: 1e-6,
    );
    report.instant(
      '$prefix.getSunTransit(start, end)',
      spanInput,
      attempt(() => _millis(java.getSunTransit(javaStart, javaEnd))),
      attempt(() => dart.getSunTransit(dartStart, dartEnd)?.flooredMillis),
    );

    final wholeOffset = rng.nextInt(4 * _day) - 2 * _day;
    final fractionalOffset = uniform(rng, -3 * 3600000, 3 * 3600000);
    final offsetInput = '$spanInput whole=$wholeOffset fractional=$fractionalOffset';
    report.instant(
      '$prefix.getTimeOffset.wholeMillis',
      offsetInput,
      attempt(() {
        final duration = kj.Duration.ofMillis(wholeOffset);
        final result = _millis(kj.AstronomicalCalendar.getTimeOffset(javaStart, duration));
        duration?.release();
        return result;
      }),
      attempt(() => kd.AstronomicalCalendar.getTimeOffset(dartStart, wholeOffset.toDouble())?.flooredMillis),
    );
    report.instant(
      '$prefix.getTimeOffset.fractionalMillis',
      offsetInput,
      attempt(() {
        final duration = kj.Duration.ofNanos((fractionalOffset * 1e6).round());
        final result = _millis(kj.AstronomicalCalendar.getTimeOffset(javaStart, duration));
        duration?.release();
        return result;
      }),
      attempt(() => kd.AstronomicalCalendar.getTimeOffset(dartStart, fractionalOffset)?.flooredMillis),
    );
    javaStart?.release();
    javaEnd?.release();

    if (dips) {
      final minutes = pick(rng, [0.0, 72.0, -72.0, 13.5, 40.0, uniform(rng, -120, 120)]);
      final dipInput = '$input minutes=$minutes';
      _dip(
        report,
        '$prefix.getSunriseSolarDipFromOffset',
        dipInput,
        () => java.getSunriseSolarDipFromOffset(minutes),
        () => dart.getSunriseSolarDipFromOffset(minutes),
      );
      _dip(
        report,
        '$prefix.getSunsetSolarDipFromOffset',
        dipInput,
        () => java.getSunsetSolarDipFromOffset(minutes),
        () => dart.getSunsetSolarDipFromOffset(minutes),
      );
    }
    java.release();
  }
}
