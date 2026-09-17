import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;
import 'package:timezone/timezone.dart' as tz;

import '../area.dart';
import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';

const _farFromMeridian = [
  'Pacific/Apia',
  'Pacific/Kiritimati',
  'Asia/Kathmandu',
  'Pacific/Chatham',
  'Pacific/Tongatapu',
  'Pacific/Marquesas',
  'Australia/Lord_Howe',
  'America/St_Johns',
  'Pacific/Pago_Pago',
  'Pacific/Honolulu',
  'Etc/GMT-14',
  'Etc/GMT+12',
  'Asia/Kolkata',
  'Europe/Madrid',
  'America/Adak',
];

const _setterValues = [
  0.0,
  -0.0,
  45.5,
  -45.5,
  90.0,
  -90.0,
  90.0000000001,
  -90.0000000001,
  179.999999,
  180.0,
  -180.0,
  180.0000000001,
  -180.0000000001,
  -1.0,
  4000.0,
  double.nan,
  double.infinity,
  double.negativeInfinity,
];

Got<String> _accepted(String Function() body) {
  try {
    return Value(body());
  } catch (_) {
    return const Value('rejected');
  }
}

class GeoArea extends Area {
  GeoArea(super.zones);

  @override
  String get name => 'geo';

  @override
  void run(int seed, Iterable<int> indexes, Report report) {
    for (final index in indexes) {
      final rng = caseRandom(seed, name, index);
      final id = 'geo#$index seed=$seed';
      _distances(rng, id, report);
      _localMeanTime(rng, id, report);
      _setters(rng, id, report);
    }
  }

  (double, double, double, double, String) _pair(Random rng) {
    double lat() => uniform(rng, -90, 90);
    double lon() => uniform(rng, -180, 180);
    switch (rng.nextInt(10)) {
      case 0:
        final a = lat();
        final b = lon();
        return (a, b, a, b, 'identical');
      case 1:
        final a = lat();
        final b = lon();
        return (a, b, -a, wrapLongitude(b + 180), 'antipodal');
      case 2:
        final a = lat();
        final b = lon();
        final epsilon = pick(rng, const [1e-9, 1e-6, 1e-3, 0.1, 0.5]);
        final sign = chance(rng, 0.5) ? 1 : -1;
        return (a, b, (-a + epsilon * sign).clamp(-90.0, 90.0), wrapLongitude(b + 180 - epsilon), 'near-antipodal');
      case 3:
        return (pick(rng, const [90.0, -90.0]), lon(), lat(), lon(), 'pole');
      case 4:
        return (pick(rng, const [90.0, -90.0]), lon(), pick(rng, const [90.0, -90.0]), lon(), 'pole-to-pole');
      case 5:
        return (lat(), uniform(rng, 179, 180), lat(), uniform(rng, -180, -179), 'antimeridian');
      case 6:
        return (0.0, lon(), 0.0, lon(), 'equator');
      case 7:
        final b = lon();
        return (lat(), b, lat(), b, 'meridian');
      default:
        return (lat(), lon(), lat(), lon(), 'random');
    }
  }

  void _distances(Random rng, String id, Report report) {
    final (lat1, lon1, lat2, lon2, kind) = _pair(rng);
    final input = '$id kind=$kind from=($lat1, $lon1) to=($lat2, $lon2)';
    final zone = zones.java('UTC');
    final name = 'geo'.toJString();
    final javaFrom = kj.GeoLocation(name, lat1, lon1, zone);
    final javaTo = kj.GeoLocation(name, lat2, lon2, zone);
    name.release();
    final epoch = DateTime.utc(2000);
    final dartFrom = kd.GeoLocation.setLocation('geo', lat1, lon1, epoch);
    final dartTo = kd.GeoLocation.setLocation('geo', lat2, lon2, epoch);
    report.real(
      'geo.getGeodesicInitialBearing.$kind',
      input,
      attempt(() => javaFrom.getGeodesicInitialBearing(javaTo)),
      attempt(() => dartFrom.getGeodesicInitialBearing(dartTo)),
    );
    report.real(
      'geo.getGeodesicFinalBearing.$kind',
      input,
      attempt(() => javaFrom.getGeodesicFinalBearing(javaTo)),
      attempt(() => dartFrom.getGeodesicFinalBearing(dartTo)),
    );
    report.real(
      'geo.getGeodesicDistance.$kind',
      input,
      attempt(() => javaFrom.getGeodesicDistance(javaTo)),
      attempt(() => dartFrom.getGeodesicDistance(dartTo)),
    );
    report.real(
      'geo.getRhumbLineBearing.$kind',
      input,
      attempt(() => javaFrom.getRhumbLineBearing(javaTo)),
      attempt(() => dartFrom.getRhumbLineBearing(dartTo)),
    );
    report.real(
      'geo.getRhumbLineDistance.$kind',
      input,
      attempt(() => javaFrom.getRhumbLineDistance(javaTo)),
      attempt(() => dartFrom.getRhumbLineDistance(dartTo)),
    );
    javaFrom.release();
    javaTo.release();
  }

  int _randomInstant(Random rng, String zone) {
    final base =
        DateTime.utc(between(rng, 1900, 2300)).millisecondsSinceEpoch +
        rng.nextInt(365) * 86400000 +
        rng.nextInt(86400000);
    if (chance(rng, 0.5)) return base;
    final rules = zones.java(zone).rules!;
    final cursor = kj.Instant.ofEpochMilli(base)!;
    final transition = rules.nextTransition(cursor);
    cursor.release();
    rules.release();
    if (transition == null) return base;
    final instant = transition.instant!;
    transition.release();
    final at = instant.toEpochMilli();
    instant.release();
    return at + pick(rng, const [-3600001, -1, 0, 1, 3599999, -86400000, 86400000]);
  }

  void _localMeanTime(Random rng, String id, Report report) {
    final candidate = chance(rng, 0.4) ? pick(rng, _farFromMeridian) : pick(rng, zones.names);
    final zone = zones.names.contains(candidate) ? candidate : pick(rng, zones.names);
    final at = _randomInstant(rng, zone);
    final offsetHours = zones.javaOffsetMillis(zone, at) / 3600000;
    final nudge = pick(rng, const [0.0, 0.0, 1e-7, -1e-7, 1e-12, -1e-12, 0.01, -0.01]);
    final longitude = switch (rng.nextInt(4)) {
      0 => ((offsetHours + 20) * 15 + nudge).clamp(-180.0, 180.0),
      1 => ((offsetHours - 20) * 15 + nudge).clamp(-180.0, 180.0),
      2 => wrapLongitude(offsetHours * 15 + uniform(rng, -30, 30)),
      _ => uniform(rng, -180, 180),
    };
    final latitude = uniform(rng, -90, 90);
    final input = '$id lmt zone=$zone instant=${iso(at)} lat=$latitude lon=$longitude';

    final name = 'geo'.toJString();
    final java = kj.GeoLocation(name, latitude, longitude, zones.java(zone));
    name.release();
    final instant = kj.Instant.ofEpochMilli(at)!;
    final location = zones.dartFromJava(zone, at - 2 * 86400000, at + 2 * 86400000);
    final dart = kd.GeoLocation.setLocation(
      'geo',
      latitude,
      longitude,
      tz.TZDateTime.fromMillisecondsSinceEpoch(location, at),
    );

    report.exact(
      'geo.getLocalMeanTimeOffset',
      input,
      attempt(() => java.getLocalMeanTimeOffset(instant)),
      attempt(() => dart.getLocalMeanTimeOffset().truncate()),
    );
    report.exact(
      'geo.getAntimeridianAdjustment',
      input,
      attempt(() => java.getAntimeridianAdjustment(instant)),
      attempt(() => dart.getAntimeridianAdjustment()),
    );
    instant.release();
    java.release();
  }

  void _setters(Random rng, String id, Report report) {
    final value = chance(rng, 0.5) ? pick(rng, _setterValues) : uniform(rng, -200, 200);
    final input = '$id setter value=$value';
    final zone = zones.java('UTC');
    final name = 'geo'.toJString();
    final java = kj.GeoLocation(name, 0, 0, zone);
    name.release();
    final dart = kd.GeoLocation.setLocation('geo', 0, 0, DateTime.utc(2000));
    report.exact(
      'geo.setLatitude',
      input,
      _accepted(() {
        java.latitude = value;
        return '${java.latitude}';
      }),
      _accepted(() {
        dart.setLatitude(latitude: value);
        return '${dart.getLatitude()}';
      }),
    );
    report.exact(
      'geo.setLongitude',
      input,
      _accepted(() {
        java.longitude = value;
        return '${java.longitude}';
      }),
      _accepted(() {
        dart.setLongitude(longitude: value);
        return '${dart.getLongitude()}';
      }),
    );
    report.exact(
      'geo.setElevation',
      input,
      _accepted(() {
        java.elevation = value;
        return '${java.elevation}';
      }),
      _accepted(() {
        dart.setElevation(value);
        return '${dart.getElevation()}';
      }),
    );
    java.release();
  }
}
