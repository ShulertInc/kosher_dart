import 'dart:math';

import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';
import 'zman_getters.dart';
import 'zmanim.dart' show dartDurationMillis, durationMillis;

class Moment {
  const Moment(this.label, this.millis);
  final String label;
  final int? millis;

  kj.Instant? get java => instantAt(millis);
  DateTime? get dart => millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis!, isUtc: true);

  @override
  String toString() => millis == null ? '$label=null' : '$label=${iso(millis!)}';
}

kj.Instant? instantAt(int? millis) => millis == null ? null : kj.Instant.ofEpochMilli(millis);

int? millisOrNull(kj.Instant? instant) {
  if (instant == null) return null;
  final millis = instant.toEpochMilli();
  instant.release();
  return millis;
}

List<Moment> candidateMoments(Random rng, JavaCalendar java, int midnight) => [
      Moment('seaLevelSunrise', millisOrNull(java.seaLevelSunrise)),
      Moment('sunrise', millisOrNull(java.sunrise)),
      Moment('alos16.1', millisOrNull(java.alos16Point1Degrees)),
      Moment('alos72', millisOrNull(java.alos72Minutes)),
      Moment('chatzos', millisOrNull(java.chatzosHayom)),
      Moment('fixedLocalChatzos', millisOrNull(java.fixedLocalChatzosHayom)),
      Moment('sunset', millisOrNull(java.sunset)),
      Moment('seaLevelSunset', millisOrNull(java.seaLevelSunset)),
      Moment('tzais72', millisOrNull(java.tzais72Minutes)),
      Moment('tzais8.5', millisOrNull(java.tzaisGeonim8Point5Degrees)),
      Moment('random', midnight + (uniform(rng, -1.5, 2.5) * 86400000).round()),
      const Moment('null', null),
    ];

double randomHours(Random rng) {
  final roll = rng.nextDouble();
  if (roll < 0.3) return pick(rng, const [0.0, 0.5, 1.0, 3.0, 4.0, 5.0, 6.5, 9.0, 9.5, 10.75, 12.0, -1.0, -3.0]);
  if (roll < 0.6) return between(rng, -6, 18) / 4;
  return uniform(rng, -12, 24);
}

void runArgumentChecks(
    Random rng, String prefix, String describe, JavaCalendar java, DartCalendar dart, int midnight, Report report) {
  final moments = candidateMoments(rng, java, midnight);
  Moment any() => pick(rng, moments);

  void pair(String name, kj.Instant? Function(kj.Instant?, kj.Instant?) javaCall,
      DateTime? Function(DateTime?, DateTime?) dartCall) {
    for (var sample = 0; sample < 2; sample++) {
      final start = any();
      final end = any();
      report.instant('$prefix.$name', '$describe $start $end',
          attempt(() => millisOrNull(javaCall(start.java, end.java))),
          attempt(() => dartCall(start.dart, end.dart)?.flooredMillis));
    }
  }

  pair('getSofZmanShma(s,e)', java.getSofZmanShma$1, dart.getSofZmanShma);
  pair('getSofZmanTfila(s,e)', java.getSofZmanTfila$1, dart.getSofZmanTfila);
  pair('getMinchaGedola(s,e)', java.getMinchaGedola$1, dart.getMinchaGedola);
  pair('getSamuchLeMinchaKetana(s,e)', java.getSamuchLeMinchaKetana$1, dart.getSamuchLeMinchaKetana);
  pair('getMinchaKetana(s,e)', java.getMinchaKetana$1, dart.getMinchaKetana);
  pair('getPlagHamincha(s,e)', java.getPlagHamincha$1, dart.getPlagHamincha);
  pair('getChatzos(s,e)', java.getChatzos, dart.getChatzos);
  for (var sample = 0; sample < 2; sample++) {
    final minchaGedola = any();
    report.instant('$prefix.getMinchaGedolaGreaterThan30(minchaGedola)', '$describe $minchaGedola',
        attempt(() => millisOrNull(java.getMinchaGedolaGreaterThan30(minchaGedola.java))),
        attempt(() => dart.getMinchaGedolaGreaterThan30(minchaGedola.dart)?.flooredMillis));
  }

  for (final synchronous in [true, false]) {
    void synced(String name, kj.Instant? Function(kj.Instant?, kj.Instant?, bool) javaCall,
        DateTime? Function(DateTime?, DateTime?, bool) dartCall) {
      pair('$name(s,e,$synchronous)', (s, e) => javaCall(s, e, synchronous), (s, e) => dartCall(s, e, synchronous));
    }

    synced('getSofZmanShma', java.getSofZmanShma, dart.getSofZmanShma);
    synced('getSofZmanTfila', java.getSofZmanTfila, dart.getSofZmanTfila);
    synced('getMinchaGedola', java.getMinchaGedola, dart.getMinchaGedola);
    synced('getSamuchLeMinchaKetana', java.getSamuchLeMinchaKetana, dart.getSamuchLeMinchaKetana);
    synced('getMinchaKetana', java.getMinchaKetana, dart.getMinchaKetana);
    synced('getPlagHamincha', java.getPlagHamincha, dart.getPlagHamincha);
    synced('getSofZmanBiurChametz', java.getSofZmanBiurChametz, dart.getSofZmanBiurChametz);
    synced('getSofZmanAchilasChametz', java.getSofZmanAchilasChametz, dart.getSofZmanAchilasChametz);
  }

  for (var sample = 0; sample < 2; sample++) {
    final start = any();
    final end = any();
    report.real('$prefix.getHalfDayBasedShaahZmanis(s,e)', '$describe $start $end',
        attempt(() => durationMillis(java.getHalfDayBasedShaahZmanis(start.java, end.java)) ?? double.nan),
        attempt(() => dartDurationMillis(dart.getHalfDayBasedShaahZmanis(start.dart, end.dart)) ?? double.nan),
        tolerance: 1e-6,
        absolute: 0.001);
  }

  for (var sample = 0; sample < 2; sample++) {
    final degrees = chance(rng, 0.5) ? pick(rng, const [0.0, 1.583, 3.7, 7.083, 8.5, 16.1, 18.0]) : uniform(rng, -5, 30);
    final sunset = chance(rng, 0.5);
    report.real('$prefix.getPercentOfShaahZmanisFromDegrees(degrees,sunset)', '$describe degrees=$degrees sunset=$sunset',
        attempt(() => java.getPercentOfShaahZmanisFromDegrees(degrees, sunset)),
        attempt(() => dart.getPercentOfShaahZmanisFromDegrees(degrees, sunset)),
        tolerance: 1e-6);
  }

  {
    final seconds = chance(rng, 0.3) ? pick(rng, const [0, 43200, 86399]) : rng.nextInt(86400);
    final nanos = chance(rng, 0.5) ? 0 : rng.nextInt(1000000) * 1000;
    final time = kj.LocalTime.ofSecondOfDay(seconds)!;
    final withNanos = time.withNano(nanos)!;
    time.release();
    report.instant('$prefix.getLocalMeanTime(localTime)', '$describe secondOfDay=$seconds nanos=$nanos',
        attempt(() => millisOrNull(java.getLocalMeanTime(withNanos))),
        attempt(() => dart.getLocalMeanTime(Duration(seconds: seconds, microseconds: nanos ~/ 1000)).flooredMillis));
    withNanos.release();
  }

  pair('getSofZmanKidushLevanaBetweenMoldos(alos,tzais)', java.getSofZmanKidushLevanaBetweenMoldos,
      dart.getSofZmanKidushLevanaBetweenMoldos);
  pair('getSofZmanKidushLevana15Days(alos,tzais)', java.getSofZmanKidushLevana15Days, dart.getSofZmanKidushLevana15Days);
  pair('getTchilasZmanKidushLevana3Days(alos,tzais)', java.getTchilasZmanKidushLevana3Days,
      dart.getTchilasZmanKidushLevana3Days);
  pair('getTchilasZmanKidushLevana7Days(alos,tzais)', java.getTchilasZmanKidushLevana7Days,
      dart.getTchilasZmanKidushLevana7Days);
  final alos = Moment('alos72', millisOrNull(java.alos72Minutes));
  final tzais = Moment('tzais72', millisOrNull(java.tzais72Minutes));
  for (final entry in <String, (kj.Instant? Function(kj.Instant?, kj.Instant?), DateTime? Function(DateTime?, DateTime?))>{
    'getSofZmanKidushLevanaBetweenMoldos(alos72,tzais72)':
        (java.getSofZmanKidushLevanaBetweenMoldos, dart.getSofZmanKidushLevanaBetweenMoldos),
    'getSofZmanKidushLevana15Days(alos72,tzais72)': (java.getSofZmanKidushLevana15Days, dart.getSofZmanKidushLevana15Days),
    'getTchilasZmanKidushLevana3Days(alos72,tzais72)':
        (java.getTchilasZmanKidushLevana3Days, dart.getTchilasZmanKidushLevana3Days),
    'getTchilasZmanKidushLevana7Days(alos72,tzais72)':
        (java.getTchilasZmanKidushLevana7Days, dart.getTchilasZmanKidushLevana7Days),
  }.entries) {
    report.instant('$prefix.${entry.key}', describe, attempt(() => millisOrNull(entry.value.$1(alos.java, tzais.java))),
        attempt(() => entry.value.$2(alos.dart, tzais.dart)?.flooredMillis));
  }

  for (var sample = 0; sample < 2; sample++) {
    final start = any();
    final end = any();
    final hours = randomHours(rng);
    final input = '$describe $start $end hours=$hours';
    report.instant('$prefix.getShaahZmanisBasedZman(s,e,hours)', input,
        attempt(() => millisOrNull(java.getShaahZmanisBasedZman(start.java, end.java, hours))),
        attempt(() => dart.getShaahZmanisBasedZman(start.dart, end.dart, hours)?.flooredMillis));
    report.instant('$prefix.getHalfDayBasedZman(s,e,hours)', input,
        attempt(() => millisOrNull(java.getHalfDayBasedZman(start.java, end.java, hours))),
        attempt(() => dart.getHalfDayBasedZman(start.dart, end.dart, hours)?.flooredMillis));
    report.instant('$prefix.getZmanisBasedOffset(hours)', input,
        attempt(() => millisOrNull(java.getZmanisBasedOffset(hours))),
        attempt(() => dart.getZmanisBasedOffset(hours)?.flooredMillis));
  }

  for (var sample = 0; sample < 3; sample++) {
    final near = any();
    final tzaisMoment = any();
    final inIsrael = chance(rng, 0.5);
    if (near.millis == null || tzaisMoment.millis == null) continue;
    final current = Moment('near ${near.label}', near.millis! + between(rng, 1, 1800000) * (chance(rng, 0.5) ? 1 : -1));
    report.exact('$prefix.isAssurBemelacha', '$describe current=$current tzais=$tzaisMoment inIsrael=$inIsrael',
        attempt(() => java.isAssurBemelacha(current.java, tzaisMoment.java, inIsrael)),
        attempt(() => dart.isAssurBemelacha(current.dart!, tzaisMoment.dart!, inIsrael)));
  }
}
