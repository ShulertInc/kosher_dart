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

class ZmanimCase {
  ZmanimCase(Random rng, Zones zones) : date = chance(rng, 0.05) ? erevPesach(rng) : randomDate(rng, 1900, 2300) {
    place = randomPlace(rng, zones, date);
    useElevation = chance(rng, 0.5);
    candleLightingOffset = chance(rng, 0.5) ? 18.0 : between(rng, 0, 60).toDouble();
    ateretTorahSunsetOffset = chance(rng, 0.5) ? 40.0 : between(rng, 0, 60).toDouble();
    sunTimes = chance(rng, 0.15);
  }

  final CivilDate date;
  late final Place place;
  late final bool useElevation;
  late final double candleLightingOffset;
  late final double ateretTorahSunsetOffset;
  late final bool sunTimes;

  String describe(String id) => '$id date=$date $place useElevation=$useElevation '
      'candle=$candleLightingOffset ateret=$ateretTorahSunsetOffset calculator=${sunTimes ? 'SunTimes' : 'NOAA'}';
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
      final dartDate = tz.TZDateTime.fromMillisecondsSinceEpoch(location, javaMidnight);
      if (dartDate.year != input.date.year || dartDate.month != input.date.month || dartDate.day != input.date.day) {
        throw StateError('rebuilt zone $zone disagrees about midnight of ${input.date}');
      }
      if (tz.TZDateTime(location, input.date.year, input.date.month, input.date.day).millisecondsSinceEpoch !=
          javaMidnight) {
        report.note('midnight repeats or is skipped, TZDateTime picks a different instant than java.time');
      }

      final javaCalendar = javaCalendarFor(input);
      final dartCalendar = dartCalendarFor(input, dartDate);
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
    return calendar;
  }
}
