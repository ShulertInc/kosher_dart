import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;
import 'package:kosher_dart/src/util/sun_times_calculator.dart' as kd;
import 'package:timezone/timezone.dart' as tz;

import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';
import '../area.dart';
import '../zones.dart';
import 'zman_getters.dart';
import 'zmanim_arguments.dart';
import 'zmanim_removed.dart';

class CalculatorSettings {
  CalculatorSettings(Random rng)
      : refraction = chance(rng, 0.5) ? null : uniform(rng, 0, 1.2),
        solarRadius = chance(rng, 0.5) ? null : uniform(rng, 0.2, 0.3),
        earthRadius = chance(rng, 0.5) ? null : uniform(rng, 6350, 6400);

  final double? refraction;
  final double? solarRadius;
  final double? earthRadius;

  @override
  String toString() => 'refraction=$refraction solarRadius=$solarRadius earthRadius=$earthRadius';
}

class ZmanimCase {
  ZmanimCase(Random rng, Zones zones) {
    final roll = rng.nextDouble();
    String? zone;
    CivilDate? chosen;
    if (roll < 0.05) {
      chosen = erevPesach(rng);
    } else if (roll < 0.2) {
      final picked = pick(rng, zones.names);
      zone = picked;
      final day = zones.transitionDay(picked, between(rng, 1900, 2300), rng.nextDouble());
      if (day != null) chosen = CivilDate(day.$1, day.$2, day.$3);
    } else if (roll < 0.3) {
      chosen = randomDate(rng, 1000, 3000);
    }
    date = chosen ?? randomDate(rng, 1900, 2300);
    final straddle = roll >= 0.3 && roll < 0.4 ? straddlingPlace(rng, zones, date) : null;
    place = straddle ?? extremePlace(rng, zones) ?? randomPlace(rng, zones, date, chosenZone: zone);
    useElevation = chance(rng, 0.5);
    candleLightingOffset = offset(rng, 18);
    ateretTorahSunsetOffset = offset(rng, 40);
    sunTimes = chance(rng, 0.15);
    settings = chance(rng, 0.2) ? CalculatorSettings(rng) : null;
    timeOfDay = chance(rng, 0.5) ? null : rng.nextDouble();
    cloned = chance(rng, 0.1);
    movedFromDays = straddle != null
        ? pick(rng, const [182, -182, 91, -91])
        : chance(rng, 0.1)
            ? between(rng, 1, 400) * (chance(rng, 0.5) ? 1 : -1)
            : null;
  }

  static Place? straddlingPlace(Random rng, Zones zones, CivilDate date) {
    for (var attempt = 0; attempt < 20; attempt++) {
      final zone = pick(rng, zones.names);
      final january = zones.javaOffsetMillis(zone, DateTime.utc(date.year, 1, 15).millisecondsSinceEpoch) / 3600000;
      final july = zones.javaOffsetMillis(zone, DateTime.utc(date.year, 7, 15).millisecondsSinceEpoch) / 3600000;
      if (january == july) continue;
      final middle = (january + july) / 2;
      for (final side in [20.0, -20.0]) {
        final longitude = 15 * (side + middle);
        if (longitude.abs() <= 180) {
          return Place(uniform(rng, -60, 60), longitude, chance(rng, 0.5) ? 0.0 : uniform(rng, 0, 3000), zone);
        }
      }
    }
    return null;
  }

  late final CivilDate date;
  late final Place place;
  late final bool useElevation;
  late final double candleLightingOffset;
  late final double ateretTorahSunsetOffset;
  late final bool sunTimes;
  late final CalculatorSettings? settings;
  late final double? timeOfDay;
  late final bool cloned;
  late final int? movedFromDays;

  static double offset(Random rng, double usual) {
    final roll = rng.nextDouble();
    if (roll < 0.5) return usual;
    if (roll < 0.9) return between(rng, 0, 60).toDouble();
    return uniform(rng, -30, 90);
  }

  static Place? extremePlace(Random rng, Zones zones) {
    if (!chance(rng, 0.05)) return null;
    return Place(pick(rng, const [0.0, 90.0, -90.0, 89.9999, -89.9999, 66.5, -66.5]),
        pick(rng, const [0.0, 180.0, -180.0, 179.9999, -179.9999, 7.5, -172.5]),
        pick(rng, const [0.0, 0.001, 8848.0]), pick(rng, zones.names));
  }

  String describe(String id) => '$id date=$date $place useElevation=$useElevation '
      'candle=$candleLightingOffset ateret=$ateretTorahSunsetOffset calculator=${sunTimes ? 'SunTimes' : 'NOAA'}'
      '${settings == null ? '' : ' $settings'}${timeOfDay == null ? '' : ' timeOfDay=$timeOfDay'}'
      '${cloned ? ' cloned' : ''}${movedFromDays == null ? '' : ' builtOn=$movedFromDays days away, then setCalendar'}';
}

const day = 86400000;

CivilDate erevPesach(Random rng) {
  final jewishDate =
      kd.JewishDate.initDate(jewishYear: between(rng, 5661, 6060), jewishMonth: kd.JewishDate.NISSAN, jewishDayOfMonth: 14);
  return CivilDate(jewishDate.getGregorianYear(), jewishDate.getGregorianMonth(), jewishDate.getGregorianDayOfMonth());
}

int? millisOf(kj.Instant? instant) {
  if (instant == null) return null;
  final millis = instant.toEpochMilli();
  instant.release();
  return millis;
}

double? durationMillis(kj.Duration? duration) {
  if (duration == null) return null;
  final nanos = duration.toNanos();
  duration.release();
  return nanos / 1e6;
}

class ZmanimArea extends Area {
  ZmanimArea(super.zones);

  @override
  String get name => 'zmanim';

  @override
  void run(int seed, Iterable<int> indexes, Report report) {
    for (final index in indexes) {
      final rng = caseRandom(seed, 'zmanim', index);
      final input = ZmanimCase(rng, zones);
      final id = 'zmanim#$index seed=$seed';
      final describe = input.describe(id);
      final zone = input.place.zone;
      final javaMidnight = zones.javaStartOfDay(zone, input.date.year, input.date.month, input.date.day);
      final bundled = tz.TZDateTime(zones.dart(zone), input.date.year, input.date.month, input.date.day);
      if (bundled.millisecondsSinceEpoch != javaMidnight) {
        report.note('package:timezone disagrees with java.time about midnight, zone rebuilt from java.time');
      }
      final location = zones.dartFromJava(zone, javaMidnight - 3 * day, javaMidnight + 4 * day);
      final midnight = tz.TZDateTime.fromMillisecondsSinceEpoch(location, javaMidnight);
      if (midnight.year != input.date.year || midnight.month != input.date.month || midnight.day != input.date.day) {
        report.note('skipped: the date does not exist in its zone, so no DateTime can name it');
        continue;
      }
      if (tz.TZDateTime(location, input.date.year, input.date.month, input.date.day).millisecondsSinceEpoch !=
          javaMidnight) {
        report.note('midnight repeats or is skipped, TZDateTime picks a different instant than java.time');
      }
      final dartDate = input.timeOfDay == null ? midnight : withinDay(location, midnight, input.timeOfDay!);

      var javaCalendar = javaCalendarFor(input);
      var dartCalendar = dartCalendarFor(input, builtOn(input, dartDate));
      if (input.movedFromDays != null) dartCalendar.setCalendar(dartDate);
      if (input.cloned) {
        final javaClone = javaCalendar.clone() as JavaCalendar;
        javaCalendar.release();
        javaCalendar = javaClone;
        dartCalendar = dartCalendar.clone();
      }
      final prefix = 'zmanim.${input.sunTimes ? 'suntimes' : 'noaa'}';
      for (final getter in [...zmanGetters, ...removedZmanGetters]) {
        final name = '$prefix.${getter.name}';
        switch (getter) {
          case InstantZman(:final java, :final dart):
            report.instant(name, describe, attempt(() => millisOf(java(javaCalendar))),
                attempt(() => dart(dartCalendar)?.flooredMillis));
          case DurationZman(:final java, :final dart):
            report.real(name, describe, attempt(() => durationMillis(java(javaCalendar))),
                attempt(() => dart(dartCalendar)), tolerance: 1e-6);
          case RealZman(:final java, :final dart):
            report.real(name, describe, attempt(() => java(javaCalendar)), attempt(() => dart(dartCalendar)));
        }
      }
      runArgumentChecks(rng, prefix, describe, javaCalendar, dartCalendar, javaMidnight, report);
      javaCalendar.release();
    }
  }

  tz.TZDateTime builtOn(ZmanimCase input, tz.TZDateTime date) {
    final days = input.movedFromDays;
    if (days == null) return date;
    final other = DateTime.utc(date.year, date.month, date.day + days);
    final zone = input.place.zone;
    final midnight = zones.javaStartOfDay(zone, other.year, other.month, other.day);
    return tz.TZDateTime.fromMillisecondsSinceEpoch(zones.dartFromJava(zone, midnight - 3 * day, midnight + 4 * day), midnight);
  }

  tz.TZDateTime withinDay(tz.Location location, tz.TZDateTime midnight, double fraction) {
    final next = midnight.add(const Duration(hours: 36));
    final nextMidnight = zones.javaStartOfDay(midnight.location.name, next.year, next.month, next.day);
    final span = nextMidnight - midnight.millisecondsSinceEpoch;
    return tz.TZDateTime.fromMillisecondsSinceEpoch(location, midnight.millisecondsSinceEpoch + (span * fraction).floor());
  }

  JavaCalendar javaCalendarFor(ZmanimCase input) {
    final place = input.place;
    final name = 'case'.toJString();
    final geo = kj.GeoLocation.new$1(name, place.latitude, place.longitude, place.elevation, zones.java(place.zone));
    name.release();
    final calendar = kj.ComprehensiveZmanimCalendar.new1(geo);
    final date = kj.LocalDate.of$1(input.date.year, input.date.month, input.date.day);
    calendar.localDate = date;
    date?.release();
    calendar.useElevation = input.useElevation;
    calendar.candleLightingOffset = input.candleLightingOffset;
    calendar.ateretTorahSunsetOffset = input.ateretTorahSunsetOffset;
    if (input.sunTimes) {
      final calculator = kj.SunTimesCalculator();
      calendar.astronomicalCalculator = calculator;
      calculator.release();
    }
    final settings = input.settings;
    if (settings != null) {
      final calculator = calendar.astronomicalCalculator!;
      if (settings.refraction != null) calculator.refraction = settings.refraction!;
      if (settings.solarRadius != null) calculator.solarRadius = settings.solarRadius!;
      if (settings.earthRadius != null) calculator.earthRadius = settings.earthRadius!;
      calculator.release();
    }
    return calendar;
  }

  DartCalendar dartCalendarFor(ZmanimCase input, tz.TZDateTime date) {
    final place = input.place;
    final geo = kd.GeoLocation.setLocation('case', place.latitude, place.longitude, date, place.elevation);
    final calendar = kd.ComplexZmanimCalendar.intGeoLocation(geo)
      ..setUseElevation(input.useElevation)
      ..setCandleLightingOffset(input.candleLightingOffset)
      ..setAteretTorahSunsetOffset(input.ateretTorahSunsetOffset);
    if (input.sunTimes) calendar.setAstronomicalCalculator(kd.SunTimesCalculator());
    final settings = input.settings;
    if (settings != null) {
      final calculator = calendar.getAstronomicalCalculator();
      if (settings.refraction != null) calculator.setRefraction(settings.refraction!);
      if (settings.solarRadius != null) calculator.setSolarRadius(settings.solarRadius!);
      if (settings.earthRadius != null) calculator.setEarthRadius(settings.earthRadius!);
    }
    return calendar;
  }
}
