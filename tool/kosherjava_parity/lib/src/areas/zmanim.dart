import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;
import 'package:timezone/timezone.dart' as tz;

import '../calculator_kinds.dart';
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
        earthRadius = chance(rng, 0.5) ? null : uniform(rng, 6350, 6400),
        useApparentSolarRadius = chance(rng, 0.5) ? null : chance(rng, 0.5);

  final double? refraction;
  final double? solarRadius;
  final double? earthRadius;
  final bool? useApparentSolarRadius;

  @override
  String toString() => 'refraction=$refraction solarRadius=$solarRadius earthRadius=$earthRadius '
      'useApparentSolarRadius=$useApparentSolarRadius';
}

class ZmanimCase {
  ZmanimCase(Random rng, Zones zones) {
    final machineZone = zones.machineZone;
    machineLocal = machineZone != null && chance(rng, 0.3);
    final roll = rng.nextDouble();
    String? zone = machineLocal ? machineZone : null;
    CivilDate? chosen;
    if (machineLocal) {
      if (roll < 0.6) {
        final day = zones.transitionDay(machineZone!, between(rng, 1970, 2037), rng.nextDouble());
        if (day != null) chosen = CivilDate(day.$1, day.$2, day.$3);
      }
      chosen ??= randomDate(rng, 1970, 2037);
    } else if (roll < 0.05) {
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
    final straddle = !machineLocal && roll >= 0.3 && roll < 0.4 ? straddlingPlace(rng, zones, date) : null;
    place = straddle ??
        (machineLocal ? null : extremePlace(rng, zones)) ??
        randomPlace(rng, zones, date, chosenZone: zone);
    useElevation = chance(rng, 0.2) ? null : chance(rng, 0.5);
    useAstronomicalChatzos = chance(rng, 0.4) ? null : chance(rng, 0.5);
    useAstronomicalChatzosForOtherZmanim = chance(rng, 0.4) ? null : chance(rng, 0.5);
    candleLightingOffset = chance(rng, 0.15) ? null : offset(rng, 18);
    ateretTorahSunsetOffset = chance(rng, 0.15) ? null : offset(rng, 40);
    calculator = chance(rng, 0.55) ? CalculatorKind.noaa : pick(rng, CalculatorKind.values);
    precision = calculator.hasPrecisionSettings ? PrecisionSettings(rng, calculator) : null;
    settings = chance(rng, 0.2) ? CalculatorSettings(rng) : null;
    timeOfDay = chance(rng, 0.5) ? null : rng.nextDouble();
    cloned = chance(rng, 0.1);
    viaSetLocalDate = chance(rng, 0.5);
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

  late final bool machineLocal;
  late final CivilDate date;
  late final Place place;
  late final bool? useElevation;
  late final bool? useAstronomicalChatzos;
  late final bool? useAstronomicalChatzosForOtherZmanim;
  late final double? candleLightingOffset;
  late final double? ateretTorahSunsetOffset;
  late final CalculatorKind calculator;
  late final PrecisionSettings? precision;
  late final CalculatorSettings? settings;
  late final double? timeOfDay;
  late final bool cloned;
  late final int? movedFromDays;
  late final bool viaSetLocalDate;

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

  String describe(String id) => '$id date=$date $place${machineLocal ? ' as a local DateTime' : ''} '
      'useElevation=${useElevation ?? 'default'} astronomicalChatzos=${useAstronomicalChatzos ?? 'default'} '
      'forOtherZmanim=${useAstronomicalChatzosForOtherZmanim ?? 'default'} candle=${candleLightingOffset ?? 'default'} '
      'ateret=${ateretTorahSunsetOffset ?? 'default'} calculator=${calculator.label}${precision == null ? '' : ' $precision'}'
      '${settings == null ? '' : ' $settings'}${timeOfDay == null ? '' : ' timeOfDay=$timeOfDay'}'
      '${cloned ? ' cloned' : ''}${movedFromDays == null ? '' : ' builtOn=$movedFromDays days away, then ${viaSetLocalDate ? 'setLocalDate' : 'setCalendar'}'}';
}

const day = 86400000;

CivilDate erevPesach(Random rng) {
  final date = kd.JewishDate.fromJewishDate(between(rng, 5661, 6060), kd.JewishDate.NISSAN, 14).getLocalDate();
  return CivilDate(date.year, date.month, date.day);
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
      final other = otherDate(input);
      final otherMidnight =
          other == null ? javaMidnight : zones.javaStartOfDay(zone, other.year, other.month, other.day);
      if (input.machineLocal &&
          !zones.machineAgrees(
              min(javaMidnight, otherMidnight) - 3 * day, max(javaMidnight, otherMidnight) + 4 * day)) {
        report.note('skipped: the machine zone disagrees with java.time near the date');
        continue;
      }
      if (!input.machineLocal &&
          tz.TZDateTime(zones.dart(zone), input.date.year, input.date.month, input.date.day).millisecondsSinceEpoch !=
              javaMidnight) {
        report.note('package:timezone disagrees with java.time about midnight, zone rebuilt from java.time');
      }
      final location =
          input.machineLocal ? null : zones.dartFromJava(zone, javaMidnight - 3 * day, javaMidnight + 4 * day);
      DateTime at(int millis) => location == null
          ? DateTime.fromMillisecondsSinceEpoch(millis)
          : tz.TZDateTime.fromMillisecondsSinceEpoch(location, millis);
      final midnight = at(javaMidnight);
      if (midnight.year != input.date.year || midnight.month != input.date.month || midnight.day != input.date.day) {
        report.note('skipped: the date does not exist in its zone, so no DateTime can name it');
        continue;
      }
      final named = location == null
          ? DateTime(input.date.year, input.date.month, input.date.day)
          : tz.TZDateTime(location, input.date.year, input.date.month, input.date.day);
      if (named.millisecondsSinceEpoch != javaMidnight) {
        report.note('midnight repeats or is skipped, the DateTime constructor picks a different instant than java.time');
      }
      var dartDate = input.timeOfDay == null ? midnight : withinDay(zone, at, midnight, input.timeOfDay!);
      if (dartDate.day != midnight.day) {
        report.note('the clocks went back past midnight, so the time of day named the previous date; used midnight');
        dartDate = midnight;
      }
      final builtOn = other == null ? dartDate : dartMidnight(input, otherMidnight, javaMidnight);
      if (input.machineLocal) report.note('compared as a plain local DateTime in the machine zone');

      var javaCalendar = javaCalendarFor(input);
      var dartCalendar = dartCalendarFor(input, builtOn);
      if (input.movedFromDays != null) {
        if (input.viaSetLocalDate) {
          dartCalendar.setLocalDate(DateTime.utc(input.date.year, input.date.month, input.date.day));
        } else {
          dartCalendar.setCalendar(dartDate);
        }
      }
      if (input.cloned) {
        final javaClone = javaCalendar.clone() as JavaCalendar;
        javaCalendar.release();
        javaCalendar = javaClone;
        dartCalendar = dartCalendar.clone();
      }
      final prefix = 'zmanim.${input.calculator.name}';
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
      compareProtectedDays(prefix, describe, javaCalendar, dartCalendar, report);
      javaCalendar.release();
    }
  }

  void compareProtectedDays(String prefix, String describe, JavaCalendar java, DartCalendar dart, Report report) {
    report.exact('$prefix.getLocalDate', describe, attempt(() {
      final date = java.localDate!;
      final text = date.toString$1()!.toDartString(releaseOriginal: true);
      date.release();
      return text;
    }), attempt(() {
      final date = dart.getLocalDate();
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }));
    final lastNight = attempt(() => javaMidnightAfter(java, 0));
    report.instant('$prefix.getMidnightLastNight (protected in Java)', describe, lastNight,
        attempt(() => dart.getMidnightLastNight()?.flooredMillis));
    report.instant('$prefix.getMidnightTonight (protected in Java)', describe, attempt(() => javaMidnightAfter(java, 1)),
        attempt(() => dart.getMidnightTonight()?.flooredMillis));
    report.exact(
      '$prefix.getAdjustedCalendar / getAdjustedLocalDate (protected in Java)',
      describe,
      attempt(() {
        final instant = kj.Instant.ofEpochMilli((lastNight as Value<int>).value)!;
        final geo = java.geoLocation!;
        final adjustment = geo.getAntimeridianAdjustment(instant);
        geo.release();
        instant.release();
        final date = java.localDate!;
        final adjusted = date.plusDays(adjustment)!;
        final text = adjusted.toString$1()!.toDartString(releaseOriginal: true);
        adjusted.release();
        date.release();
        return text;
      }),
      attempt(() {
        final date = dart.getAdjustedCalendar();
        return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
      }),
    );
  }

  int javaMidnightAfter(JavaCalendar java, int days) {
    final date = java.localDate!;
    final shifted = date.plusDays(days)!;
    final geo = java.geoLocation!;
    final zone = geo.zoneId!;
    final midnightTime = kj.LocalTime.MIDNIGHT!;
    final zoned = kj.ZonedDateTime.of(shifted, midnightTime, zone)!;
    final instant = zoned.toInstant()!;
    final millis = instant.toEpochMilli();
    for (final object in <JObject>[instant, zoned, midnightTime, zone, geo, shifted, date]) {
      object.release();
    }
    return millis;
  }

  DateTime? otherDate(ZmanimCase input) {
    final days = input.movedFromDays;
    if (days == null) return null;
    return DateTime.utc(input.date.year, input.date.month, input.date.day + days);
  }

  DateTime dartMidnight(ZmanimCase input, int midnight, int targetMidnight) {
    if (input.machineLocal) return DateTime.fromMillisecondsSinceEpoch(midnight);
    final zone = input.place.zone;
    return tz.TZDateTime.fromMillisecondsSinceEpoch(zones.dartFromJava(zone, min(midnight, targetMidnight) - 3 * day, max(midnight, targetMidnight) + 4 * day), midnight);
  }

  DateTime withinDay(String zone, DateTime Function(int) at, DateTime midnight, double fraction) {
    final next = midnight.add(const Duration(hours: 36));
    final nextMidnight = zones.javaStartOfDay(zone, next.year, next.month, next.day);
    final span = nextMidnight - midnight.millisecondsSinceEpoch;
    return at(midnight.millisecondsSinceEpoch + (span * fraction).floor());
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
    if (input.useElevation != null) calendar.useElevation = input.useElevation!;
    if (input.useAstronomicalChatzos != null) calendar.useAstronomicalChatzos = input.useAstronomicalChatzos!;
    if (input.useAstronomicalChatzosForOtherZmanim != null) {
      calendar.useAstronomicalChatzosForOtherZmanim = input.useAstronomicalChatzosForOtherZmanim!;
    }
    if (input.candleLightingOffset != null) calendar.candleLightingOffset = input.candleLightingOffset!;
    if (input.ateretTorahSunsetOffset != null) calendar.ateretTorahSunsetOffset = input.ateretTorahSunsetOffset!;
    if (input.calculator != CalculatorKind.noaa || input.precision != null) {
      final calculator = input.calculator.java();
      input.precision?.applyToJava(calculator);
      calendar.astronomicalCalculator = calculator;
      calculator.release();
    }
    final settings = input.settings;
    if (settings != null) {
      final calculator = calendar.astronomicalCalculator!;
      if (settings.refraction != null) calculator.refraction = settings.refraction!;
      if (settings.solarRadius != null) calculator.solarRadius = settings.solarRadius!;
      if (settings.earthRadius != null) calculator.earthRadius = settings.earthRadius!;
      if (settings.useApparentSolarRadius != null) calculator.useApparentSolarRadius = settings.useApparentSolarRadius!;
      calculator.release();
    }
    return calendar;
  }

  DartCalendar dartCalendarFor(ZmanimCase input, DateTime date) {
    final place = input.place;
    final geo = kd.GeoLocation.setLocation('case', place.latitude, place.longitude, date, place.elevation);
    final calendar = kd.ComplexZmanimCalendar.intGeoLocation(geo);
    if (input.useElevation != null) calendar.setUseElevation(input.useElevation!);
    if (input.useAstronomicalChatzos != null) calendar.setUseAstronomicalChatzos(input.useAstronomicalChatzos!);
    if (input.useAstronomicalChatzosForOtherZmanim != null) {
      calendar.setUseAstronomicalChatzosForOtherZmanim(input.useAstronomicalChatzosForOtherZmanim!);
    }
    if (input.candleLightingOffset != null) calendar.setCandleLightingOffset(input.candleLightingOffset!);
    if (input.ateretTorahSunsetOffset != null) calendar.setAteretTorahSunsetOffset(input.ateretTorahSunsetOffset!);
    if (input.calculator != CalculatorKind.noaa || input.precision != null) {
      final calculator = input.calculator.dart();
      input.precision?.applyToDart(calculator);
      calendar.setAstronomicalCalculator(calculator);
    }
    final settings = input.settings;
    if (settings != null) {
      final calculator = calendar.getAstronomicalCalculator();
      if (settings.refraction != null) calculator.setRefraction(settings.refraction!);
      if (settings.solarRadius != null) calculator.setSolarRadius(settings.solarRadius!);
      if (settings.earthRadius != null) calculator.setEarthRadius(settings.earthRadius!);
      if (settings.useApparentSolarRadius != null) {
        calculator.setUseApparentSolarRadius(settings.useApparentSolarRadius!);
      }
    }
    return calendar;
  }
}
