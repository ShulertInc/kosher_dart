import 'package:jni/jni.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'kosherjava.g.dart' as kj;

class Zones {
  Zones._(this.names, this.machineZone);

  factory Zones.load({String? machineZone}) {
    tzdata.initializeTimeZones();
    final java = <String>{};
    final ids = kj.ZoneId.availableZoneIds!;
    for (final id in ids.asDart()) {
      java.add(id!.toDartString(releaseOriginal: true));
    }
    ids.release();
    final shared = tz.timeZoneDatabase.locations.keys.where(java.contains).toList()..sort();
    if (machineZone != null && !java.contains(machineZone)) {
      throw ArgumentError.value(machineZone, 'machineZone', 'not a java.time zone');
    }
    return Zones._(shared, machineZone);
  }

  final List<String> names;
  final String? machineZone;
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
    final offsetChanges = <int>[];
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
      offsetChanges.add(at);
    }
    final starts = <int>[fromMillis];
    final ends = [...offsetChanges, toMillis + 1];
    for (var index = 0; index < ends.length; index++) {
      final start = index == 0 ? fromMillis : offsetChanges[index - 1];
      if (index > 0) starts.add(start);
      final end = ends[index];
      final dstAtEnd = _isDst(rules, end - 1);
      if (end - 1 > start && _isDst(rules, start) != dstAtEnd) {
        var low = start + 1;
        var high = end - 1;
        while (low < high) {
          final middle = low + (high - low) ~/ 2;
          if (_isDst(rules, middle) == dstAtEnd) {
            high = middle;
          } else {
            low = middle + 1;
          }
        }
        starts.add(low);
      }
    }
    final transitionAt = <int>[tz.minTime, ...starts.skip(1)];
    final zones = [for (final start in starts) _timeZone(rules, start)];
    rules.release();
    return tz.Location(name, transitionAt, List.generate(zones.length, (index) => index), zones);
  }

  bool _isDst(kj.ZoneRules rules, int atMillis) {
    final instant = kj.Instant.ofEpochMilli(atMillis)!;
    final dst = rules.isDaylightSavings(instant);
    instant.release();
    return dst;
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

  bool machineAgrees(int fromMillis, int toMillis) {
    final name = machineZone!;
    bool agreesAt(int millis) =>
        DateTime.fromMillisecondsSinceEpoch(millis).timeZoneOffset.inMilliseconds == javaOffsetMillis(name, millis);
    for (var at = fromMillis; at <= toMillis; at += 1800000) {
      if (!agreesAt(at)) return false;
    }
    final rules = java(name).rules!;
    var at = fromMillis;
    try {
      while (true) {
        final cursor = kj.Instant.ofEpochMilli(at)!;
        final transition = rules.nextTransition(cursor);
        cursor.release();
        if (transition == null) return true;
        final instant = transition.instant!;
        transition.release();
        at = instant.toEpochMilli();
        instant.release();
        if (at > toMillis) return true;
        if (!agreesAt(at - 1) || !agreesAt(at)) return false;
      }
    } finally {
      rules.release();
    }
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
