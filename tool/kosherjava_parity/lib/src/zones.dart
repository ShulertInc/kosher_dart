import 'package:jni/jni.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'kosherjava.g.dart' as kj;

class Zones {
  Zones._(this.names);

  factory Zones.load() {
    tzdata.initializeTimeZones();
    final java = <String>{};
    final ids = kj.ZoneId.availableZoneIds!;
    for (final id in ids.asDart()) {
      java.add(id!.toDartString(releaseOriginal: true));
    }
    ids.release();
    final shared = tz.timeZoneDatabase.locations.keys.where(java.contains).toList()..sort();
    return Zones._(shared);
  }

  final List<String> names;
  final Map<String, kj.ZoneId> _java = {};

  kj.ZoneId java(String name) => _java.putIfAbsent(name, () => kj.ZoneId.of$1(name.toJString())!);

  tz.Location dart(String name) => tz.getLocation(name);

  (int, int, int)? transitionDay(String name, int year, double fractionOfYear) {
    final from = DateTime.utc(year).add(Duration(milliseconds: (fractionOfYear * 365 * 86400000).round()));
    final rules = java(name).rules!;
    final cursor = kj.Instant.ofEpochMilli(from.millisecondsSinceEpoch)!;
    final transition = rules.nextTransition(cursor);
    cursor.release();
    rules.release();
    if (transition == null) return null;
    final instant = transition.instant!;
    transition.release();
    final at = instant.toEpochMilli();
    instant.release();
    final local = DateTime.fromMillisecondsSinceEpoch(at + javaOffsetMillis(name, at - 1), isUtc: true);
    return local.year > 9999 ? null : (local.year, local.month, local.day);
  }

  tz.Location dartFromJava(String name, int fromMillis, int toMillis) {
    final rules = java(name).rules!;
    final transitionAt = <int>[tz.minTime];
    final zones = <tz.TimeZone>[_timeZone(rules, fromMillis)];
    var at = fromMillis;
    while (true) {
      final cursor = kj.Instant.ofEpochMilli(at)!;
      final transition = rules.nextTransition(cursor);
      cursor.release();
      if (transition == null) break;
      final instant = transition.instant!;
      transition.release();
      at = instant.toEpochMilli();
      instant.release();
      if (at > toMillis) break;
      transitionAt.add(at);
      zones.add(_timeZone(rules, at));
    }
    rules.release();
    return tz.Location(name, transitionAt, List.generate(zones.length, (index) => index), zones);
  }

  tz.TimeZone _timeZone(kj.ZoneRules rules, int atMillis) {
    final instant = kj.Instant.ofEpochMilli(atMillis)!;
    final offset = rules.getOffset(instant)!;
    final zone = tz.TimeZone(Duration(seconds: offset.totalSeconds),
        isDst: rules.isDaylightSavings(instant), abbreviation: offset.id!.toDartString(releaseOriginal: true));
    offset.release();
    instant.release();
    return zone;
  }

  int javaOffsetMillis(String name, int epochMillis) {
    final instant = kj.Instant.ofEpochMilli(epochMillis)!;
    final rules = java(name).rules!;
    final offset = rules.getOffset(instant)!;
    final seconds = offset.totalSeconds;
    offset.release();
    rules.release();
    instant.release();
    return seconds * 1000;
  }

  int javaStartOfDay(String name, int year, int month, int day) {
    final date = kj.LocalDate.of$1(year, month, day)!;
    final zoned = date.atStartOfDay$1(java(name))!;
    final instant = zoned.toInstant()!;
    final millis = instant.toEpochMilli();
    instant.release();
    zoned.release();
    date.release();
    return millis;
  }
}
