import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;
import 'package:timezone/timezone.dart' as tz;

import '../area.dart';
import '../calculator_kinds.dart';
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

bool _hasNoRoot(CalculatorKind kind, double zenith) => kind == CalculatorKind.spa && (zenith < 0 || zenith > 180);

void _hours(Report report, String check, String input, double Function() java, double Function() dart,
    {bool noRoot = false}) {
  if (noRoot) {
    report.exact('$check.noRoot', input, attempt(() => java().isNaN), attempt(() => dart().isNaN));
    return;
  }
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
      for (final kind in CalculatorKind.values) {
        _raw(setup, report, kind);
      }
      _solarPosition(setup, report);
      _settings(setup, report);
      _calendar(setup, report, pick(rng, CalculatorKind.values), dips: index % 25 == 0);
      setup.release();
    }
  }

  (kj.AstronomicalCalculator, kd.AstronomicalCalculator, String) _configured(Random rng, CalculatorKind kind) {
    var java = kind.java();
    var dart = kind.dart();
    final precision = kind.hasPrecisionSettings ? PrecisionSettings(rng, kind) : null;
    precision?.applyToJava(java);
    precision?.applyToDart(dart);
    final cloned = chance(rng, 0.2);
    if (cloned) {
      final javaClone = java.clone()!;
      java.release();
      java = javaClone;
      dart = dart.clone();
    }
    return (java, dart, '${precision == null ? '' : ' $precision'}${cloned ? ' cloned' : ''}');
  }

  void _precisionGetters(
    Report report,
    String prefix,
    String input,
    CalculatorKind kind,
    kj.AstronomicalCalculator java,
    kd.AstronomicalCalculator dart,
  ) {
    switch (kind) {
      case CalculatorKind.meeus:
        report.exact('$prefix.isApplyDeltaT', input, attempt(() => (java as kj.MeeusCalculator).isApplyDeltaT),
            attempt(() => (dart as kd.MeeusCalculator).isApplyDeltaT()));
      case CalculatorKind.spa:
        final javaSpa = java as kj.SPACalculator;
        final dartSpa = dart as kd.SPACalculator;
        report.exact('$prefix.isApplyDeltaT', input, attempt(() => javaSpa.isApplyDeltaT),
            attempt(() => dartSpa.isApplyDeltaT()));
        report.exact(
          '$prefix.getDeltaTOverride',
          input,
          attempt(() => '${javaSpa.deltaTOverride?.toDartDouble(releaseOriginal: true)}'),
          attempt(() => '${dartSpa.getDeltaTOverride()}'),
        );
        report.exact('$prefix.getPressure', input, attempt(() => javaSpa.pressure), attempt(() => dartSpa.getPressure()));
        report.exact('$prefix.getTemperature', input, attempt(() => javaSpa.temperature),
            attempt(() => dartSpa.getTemperature()));
      case CalculatorKind.noaa || CalculatorKind.suntimes:
        break;
    }
  }

  void _raw(_Setup setup, Report report, CalculatorKind kind) {
    final rng = setup.rng;
    final (java, dart, settings) = _configured(rng, kind);
    final zenith = chance(rng, 0.7) ? pick(rng, _zeniths) : (chance(rng, 0.8) ? uniform(rng, 80, 120) : uniform(rng, -10, 200));
    final adjust = chance(rng, 0.5);
    final input = '${setup.input}$settings zenith=$zenith adjustForElevation=$adjust';
    final prefix = 'calculators.${kind.name}';
    final noRoot = _hasNoRoot(kind, zenith);
    final settingsInput = '${setup.input}$settings';
    _precisionGetters(report, prefix, settingsInput, kind, java, dart);
    final utcDate = DateTime.utc(setup.date.year, setup.date.month, setup.date.day);

    _hours(
      report,
      '$prefix.getUTCSunrise',
      input,
      () => java.getUTCSunrise(setup.javaDate, setup.javaGeo, zenith, adjust),
      () => dart.getUTCSunrise(setup.dartDate, setup.dartGeo, zenith, adjust),
      noRoot: noRoot,
    );
    _hours(
      report,
      '$prefix.getUTCSunset',
      input,
      () => java.getUTCSunset(setup.javaDate, setup.javaGeo, zenith, adjust),
      () => dart.getUTCSunset(setup.dartDate, setup.dartGeo, zenith, adjust),
      noRoot: noRoot,
    );
    _hours(
      report,
      '$prefix.getUTCSunrise.utcDateTime',
      input,
      () => java.getUTCSunrise(setup.javaDate, setup.javaGeo, zenith, adjust),
      () => dart.getUTCSunrise(utcDate, setup.dartGeo, zenith, adjust),
      noRoot: noRoot,
    );
    _hours(
      report,
      '$prefix.getUTCSunset.utcDateTime',
      input,
      () => java.getUTCSunset(setup.javaDate, setup.javaGeo, zenith, adjust),
      () => dart.getUTCSunset(utcDate, setup.dartGeo, zenith, adjust),
      noRoot: noRoot,
    );
    _hours(
      report,
      '$prefix.getUTCNoon',
      settingsInput,
      () => java.getUTCNoon(setup.javaDate, setup.javaGeo),
      () => dart.getUTCNoon(setup.dartDate, setup.dartGeo),
    );
    _hours(
      report,
      '$prefix.getUTCMidnight',
      settingsInput,
      () => java.getUTCMidnight(setup.javaDate, setup.javaGeo),
      () => dart.getUTCMidnight(setup.dartDate, setup.dartGeo),
    );

    final azimuth = pick(rng, const [90.0, 270.0]);
    _hours(
      report,
      '$prefix.getTimeAtAzimuth',
      '$settingsInput azimuth=$azimuth',
      () => java.getTimeAtAzimuth(setup.javaDate, setup.javaGeo, azimuth),
      () => dart.getUTCTimeAtAzimuth(setup.dartDate, setup.dartGeo, azimuth),
    );
    final otherAzimuth = uniform(rng, 0, 360);
    _hours(
      report,
      '$prefix.getTimeAtAzimuth.otherAzimuth',
      '$settingsInput azimuth=$otherAzimuth',
      () => java.getTimeAtAzimuth(setup.javaDate, setup.javaGeo, otherAzimuth),
      () => dart.getUTCTimeAtAzimuth(setup.dartDate, setup.dartGeo, otherAzimuth),
    );

    report.exact(
      '$prefix.getCalculatorName',
      settingsInput,
      attempt(() => java.calculatorName!.toDartString(releaseOriginal: true)),
      attempt(() => dart.getCalculatorName()),
    );
    report.real(
      '$prefix.getRefraction',
      settingsInput,
      attempt(() => java.refraction),
      attempt(() => dart.getRefraction()),
    );
    report.real(
      '$prefix.getSolarRadius',
      settingsInput,
      attempt(() => java.solarRadius),
      attempt(() => dart.getSolarRadius()),
    );
    report.real(
      '$prefix.getEarthRadius',
      settingsInput,
      attempt(() => java.earthRadius),
      attempt(() => dart.getEarthRadius()),
    );
    report.real(
      '$prefix.getApparentSolarRadius',
      settingsInput,
      attempt(() => java.getApparentSolarRadius(setup.javaDate)),
      attempt(() => dart.getApparentSolarRadius(setup.dartDate)),
    );
    java.release();
  }

  int _solarPositionInstant(_Setup setup) {
    final rng = setup.rng;
    if (chance(rng, 0.5)) {
      final zenith = uniform(rng, 88, 92);
      final hours = chance(rng, 0.5)
          ? kd.NOAACalculator().getUTCSunrise(setup.dartDate, setup.dartGeo, zenith, false)
          : kd.NOAACalculator().getUTCSunset(setup.dartDate, setup.dartGeo, zenith, false);
      if (hours.isFinite) {
        final utcMidnight = DateTime.utc(setup.date.year, setup.date.month, setup.date.day).millisecondsSinceEpoch;
        return utcMidnight + (hours * 3600000).floor() + rng.nextInt(600000) - 300000;
      }
    }
    return setup.midnight + rng.nextInt(_day);
  }

  void _solarPosition(_Setup setup, Report report) {
    final rng = setup.rng;
    for (final kind in const [CalculatorKind.noaa, CalculatorKind.meeus, CalculatorKind.spa]) {
      final at = _solarPositionInstant(setup);
      final micros = rng.nextInt(1000);
      final (java, dart, precision) = _configured(rng, kind);
      final refraction = chance(rng, 0.5) ? null : uniform(rng, 0, 1.5);
      final solarRadius = chance(rng, 0.5) ? null : uniform(rng, 0, 0.5);
      if (refraction != null) {
        java.refraction = refraction;
        dart.setRefraction(refraction);
      }
      if (solarRadius != null) {
        java.solarRadius = solarRadius;
        dart.setSolarRadius(solarRadius);
      }
      final input = '${setup.input}$precision refraction=${refraction ?? 'default'} '
          'solarRadius=${solarRadius ?? 'default'} instant=${iso(at)}';
      final prefix = 'calculators.${kind.name}';
      final tolerance = kind == CalculatorKind.noaa ? 1e-6 : 1e-9;
      final instant = kj.Instant.ofEpochMilli(at)!;
      final utc = DateTime.fromMillisecondsSinceEpoch(at, isUtc: true);
      report.real(
        '$prefix.getSolarElevation',
        input,
        attempt(() => java.getSolarElevation(instant, setup.javaGeo)),
        attempt(() => dart.getSolarElevation(utc, setup.dartGeo)),
        tolerance: tolerance,
      );
      report.real(
        '$prefix.getSolarAzimuth',
        input,
        attempt(() => java.getSolarAzimuth(instant, setup.javaGeo)),
        attempt(() => dart.getSolarAzimuth(utc, setup.dartGeo)),
        tolerance: tolerance,
      );
      final zoned = tz.TZDateTime.fromMillisecondsSinceEpoch(setup.location, at);
      report.real(
        '$prefix.getSolarElevation.zonedDateTime',
        input,
        attempt(() => java.getSolarElevation(instant, setup.javaGeo)),
        attempt(() => dart.getSolarElevation(zoned, setup.dartGeo)),
        tolerance: tolerance,
      );
      instant.release();
      final microInstant = kj.Instant.ofEpochSecond$1((at - at % 1000) ~/ 1000, (at % 1000) * 1000000 + micros * 1000)!;
      final microUtc = DateTime.fromMicrosecondsSinceEpoch(at * 1000 + micros, isUtc: true);
      final microInput = '$input micros=$micros';
      report.real(
        '$prefix.getSolarElevation.microseconds',
        microInput,
        attempt(() => java.getSolarElevation(microInstant, setup.javaGeo)),
        attempt(() => dart.getSolarElevation(microUtc, setup.dartGeo)),
        tolerance: tolerance,
      );
      report.real(
        '$prefix.getSolarAzimuth.microseconds',
        microInput,
        attempt(() => java.getSolarAzimuth(microInstant, setup.javaGeo)),
        attempt(() => dart.getSolarAzimuth(microUtc, setup.dartGeo)),
        tolerance: tolerance,
      );
      microInstant.release();
      java.release();
    }
  }

  void _settings(_Setup setup, Report report) {
    final rng = setup.rng;
    final refraction = uniform(rng, 0, 1.5);
    final solarRadius = pick(rng, [uniform(rng, 0, 0.5), 0.0, -0.1, double.nan]);
    final earthRadius = uniform(rng, 6300, 6400);
    final zenith = chance(rng, 0.8) ? 90.0 : pick(rng, _zeniths);
    final apparent = pick(rng, const [null, true, false]);
    final baseInput =
        '${setup.input} refraction=$refraction solarRadius=$solarRadius earthRadius=$earthRadius '
        'useApparentSolarRadius=${apparent ?? 'after setSolarRadius'} zenith=$zenith';
    for (final kind in CalculatorKind.values) {
      var java = kind.java();
      var dart = kind.dart();
      final precision = kind.hasPrecisionSettings ? PrecisionSettings(rng, kind) : null;
      final cloned = chance(rng, 0.3);
      final input = '$baseInput${precision == null ? '' : ' $precision'}${cloned ? ' cloned' : ''}';
      final prefix = 'calculators.${kind.name}';
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
      precision?.applyToJava(java);
      precision?.applyToDart(dart);
      if (cloned) {
        final javaClone = java.clone()!;
        java.release();
        java = javaClone;
        dart = dart.clone();
      }
      _precisionGetters(report, '$prefix.configured', input, kind, java, dart);
      report.real('$prefix.getRefraction.configured', input, attempt(() => java.refraction),
          attempt(() => dart.getRefraction()));
      report.real('$prefix.getSolarRadius.configured', input, attempt(() => java.solarRadius),
          attempt(() => dart.getSolarRadius()));
      report.real('$prefix.getEarthRadius.configured', input, attempt(() => java.earthRadius),
          attempt(() => dart.getEarthRadius()));
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
      _hours(
        report,
        '$prefix.getUTCNoon.configured',
        input,
        () => java.getUTCNoon(setup.javaDate, setup.javaGeo),
        () => dart.getUTCNoon(setup.dartDate, setup.dartGeo),
      );
      _hours(
        report,
        '$prefix.getUTCMidnight.configured',
        input,
        () => java.getUTCMidnight(setup.javaDate, setup.javaGeo),
        () => dart.getUTCMidnight(setup.dartDate, setup.dartGeo),
      );
      java.release();
    }
  }

  void _calendar(_Setup setup, Report report, CalculatorKind kind, {required bool dips}) {
    final rng = setup.rng;
    final java = kj.ComprehensiveZmanimCalendar.new1(setup.javaGeo);
    java.localDate = setup.javaDate;
    final dart = kd.ComplexZmanimCalendar.intGeoLocation(setup.dartGeo);
    final (javaCalculator, dartCalculator, settings) = _configured(rng, kind);
    java.astronomicalCalculator = javaCalculator;
    javaCalculator.release();
    dart.setAstronomicalCalculator(dartCalculator);
    final prefix = 'calculators.calendar.${kind.name}';
    final zenith = chance(rng, 0.6) ? pick(rng, _zeniths) : (chance(rng, 0.8) ? uniform(rng, 80, 120) : uniform(rng, -10, 200));
    final input = '${setup.input} calculator=${kind.label}$settings zenith=$zenith';
    final noRoot = _hasNoRoot(kind, zenith);
    int? present(int? millis) => noRoot && millis != null ? 0 : millis;

    report.instant(
      '$prefix.getSunriseOffsetByDegrees',
      input,
      attempt(() => present(_millis(java.getSunriseOffsetByDegrees(zenith)))),
      attempt(() => present(dart.getSunriseOffsetByDegrees(zenith)?.flooredMillis)),
    );
    report.instant(
      '$prefix.getSunsetOffsetByDegrees',
      input,
      attempt(() => present(_millis(java.getSunsetOffsetByDegrees(zenith)))),
      attempt(() => present(dart.getSunsetOffsetByDegrees(zenith)?.flooredMillis)),
    );
    _hours(report, '$prefix.getUTCSunrise', input, () => java.getUTCSunrise(zenith), () => dart.getUTCSunrise(zenith),
        noRoot: noRoot);
    _hours(
      report,
      '$prefix.getUTCSeaLevelSunrise',
      input,
      () => java.getUTCSeaLevelSunrise(zenith),
      () => dart.getUTCSeaLevelSunrise(zenith),
      noRoot: noRoot,
    );
    _hours(report, '$prefix.getUTCSunset', input, () => java.getUTCSunset(zenith), () => dart.getUTCSunset(zenith),
        noRoot: noRoot);
    _hours(
      report,
      '$prefix.getUTCSeaLevelSunset',
      input,
      () => java.getUTCSeaLevelSunset(zenith),
      () => dart.getUTCSeaLevelSunset(zenith),
      noRoot: noRoot,
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
