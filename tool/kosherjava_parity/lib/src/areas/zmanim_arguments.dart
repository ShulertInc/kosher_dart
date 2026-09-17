import 'dart:math';

import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';
import 'zman_getters.dart';
import 'zmanim_removed.dart';

class Moment {
  const Moment(this.label, this.millis);
  final String label;
  final int? millis;

  kj.Instant? get java => instantAt(millis);
  DateTime? get dart => millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis!);

  @override
  String toString() => millis == null ? '$label=null' : '$label=${iso(millis!)}';
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
  pair('getSofZmanShma(s,e) / getSofZmanShmaOfDay', java.getSofZmanShma$1, dart.getSofZmanShmaOfDay);
  pair('getSofZmanTfila(s,e)', java.getSofZmanTfila$1, dart.getSofZmanTfila);
  pair('getSofZmanTfila(s,e) / getSofZmanTfilaOfDay', java.getSofZmanTfila$1, dart.getSofZmanTfilaOfDay);
  pair('getMinchaGedola(s,e)', java.getMinchaGedola$1, dart.getMinchaGedola);
  pair('getMinchaGedola(s,e) / getMinchaGedolaOfDay', java.getMinchaGedola$1, dart.getMinchaGedolaOfDay);
  pair('getSamuchLeMinchaKetana(s,e) / getSamuchLeMinchaKetanaOfDay', java.getSamuchLeMinchaKetana$1,
      dart.getSamuchLeMinchaKetanaOfDay);
  pair('getMinchaKetana(s,e)', java.getMinchaKetana$1, dart.getMinchaKetana);
  pair('getMinchaKetana(s,e) / getMinchaKetanaOfDay', java.getMinchaKetana$1, dart.getMinchaKetanaOfDay);
  pair('getPlagHamincha(s,e)', java.getPlagHamincha$1, dart.getPlagHamincha);
  pair('getPlagHamincha(s,e) / getPlagHaminchaOfDay', java.getPlagHamincha$1, dart.getPlagHaminchaOfDay);
  pair('getSofZmanShma(s,e,synchronous) / getSofZmanShma', (s, e) => java.getSofZmanShma(s, e, true),
      dart.getSofZmanShma);
  pair('getPlagHamincha(s,e,synchronous) / getPlagHamincha', (s, e) => java.getPlagHamincha(s, e, true),
      dart.getPlagHamincha);

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
    if (start.millis != null && end.millis != null) {
      report.instant('$prefix.getShaahZmanisBasedZman(s,e,hours)', input,
          attempt(() => millisOrNull(java.getShaahZmanisBasedZman(start.java, end.java, hours))),
          attempt(() => dart.getShaahZmanisBasedZman(start.dart!, end.dart!, hours)?.flooredMillis));
    }
    if (hours < 0) {
      report.note('contract: getFixedLocalChatzosBasedZmanim keeps 2.x negative hours, counted from the start of the half day');
    } else {
      report.instant('$prefix.getHalfDayBasedZman(s,e,hours) / getFixedLocalChatzosBasedZmanim', input,
          attempt(() => millisOrNull(java.getHalfDayBasedZman(start.java, end.java, hours))),
          attempt(() => dart.getFixedLocalChatzosBasedZmanim(start.dart, end.dart, hours)?.flooredMillis));
    }
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
    report.exact('$prefix.isAssurBemelacha / isAssurBemlacha', '$describe current=$current tzais=$tzaisMoment inIsrael=$inIsrael',
        attempt(() => java.isAssurBemelacha(current.java, tzaisMoment.java, inIsrael)),
        attempt(() => dart.isAssurBemlacha(current.dart!, tzaisMoment.dart!, inIsrael)));
  }
}
