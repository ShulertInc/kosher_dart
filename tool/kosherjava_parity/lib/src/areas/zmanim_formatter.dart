import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;
import 'package:kosher_dart/src/util/java_double.dart' as jd;
import 'package:kosher_dart/src/util/sun_times_calculator.dart' as kd;
import 'package:timezone/timezone.dart' as tz;

import '../area.dart';
import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';
import '../zones.dart';
import 'zman_getters.dart';
import 'zmanim.dart';

const _day = 86400000;
const _billion = 1000000000;

const _patternPieces = [
  'yyyy', 'yy', 'y', 'yyy', 'yyyyy', 'MM', 'M', 'MMM', 'MMMM', 'MMMMM', 'dd', 'd', 'HH', 'H', 'hh', 'h', 'mm', 'm',
    'ss', 's', 'S', 'SSS', 'SSSSSS', 'SSSSSSSSS', 'a', 'X', 'XX', 'XXX', 'XXXX', 'XXXXX', 'zzzz', "'T'", ' ', '-', ':',
  '.', '/', "''", "'o''clock'", ',',
];

const _javaPatterns = [
  'h:mm:ss',
  "yyyy-MM-dd'T'HH:mm:ss",
  "yyyy-MM-dd'T'HH:mm:ssXXX",
  'yyyy-MM-dd',
  "yyyy-MM-dd'T'HH:mm:ss.SSS",
  'zzzz',
];

const _names = ['case', 'Lakewood, NJ', 'Jerusalem', '', 'a & b <c> "d"', 'ירושלים'];

const _labels = ['Sunrise', 'Sunset', 'sunrise', 'Alos', 'Tzais', 'A', 'a', 'Zman', ''];

String _javaText(JString? text) => text == null ? 'null' : text.toDartString(releaseOriginal: true);

(int, int) _split(int micros) => ((micros - micros % 1000000) ~/ 1000000, micros % 1000000 * 1000);

class _Jvm {
  _Jvm() {
    final roundingMode = JClass.forName('java/math/RoundingMode');
    halfUp = roundingMode.staticFieldId('HALF_UP', 'Ljava/math/RoundingMode;').get(roundingMode, JObject.type);
    floor = roundingMode.staticFieldId('FLOOR', 'Ljava/math/RoundingMode;').get(roundingMode, JObject.type);
  }

  final formatterClass = JClass.forName('java/time/format/DateTimeFormatter');
  late final _ofPattern =
      formatterClass.staticMethodId('ofPattern', '(Ljava/lang/String;)Ljava/time/format/DateTimeFormatter;');
  final bigDecimal = JClass.forName('java/math/BigDecimal');
  late final _newBigDecimal = bigDecimal.constructorId('(D)V');
  late final _movePointLeft = bigDecimal.instanceMethodId('movePointLeft', '(I)Ljava/math/BigDecimal;');
  late final _movePointRight = bigDecimal.instanceMethodId('movePointRight', '(I)Ljava/math/BigDecimal;');
  late final _setScale =
      bigDecimal.instanceMethodId('setScale', '(ILjava/math/RoundingMode;)Ljava/math/BigDecimal;');
  late final _subtract =
      bigDecimal.instanceMethodId('subtract', '(Ljava/math/BigDecimal;)Ljava/math/BigDecimal;');
  late final _longValueExact = bigDecimal.instanceMethodId('longValueExact', '()J');
  late final _intValueExact = bigDecimal.instanceMethodId('intValueExact', '()I');
  late final JObject halfUp;
  late final JObject floor;
  final arrayList = JClass.forName('java/util/ArrayList');
  late final _newList = arrayList.constructorId('()V');
  late final _add = arrayList.instanceMethodId('add', '(Ljava/lang/Object;)Z');
  late final _get = arrayList.instanceMethodId('get', '(I)Ljava/lang/Object;');
  late final _sort = arrayList.instanceMethodId('sort', '(Ljava/util/Comparator;)V');
  final comparator = JClass.forName('java/util/Comparator');
  late final _compare = comparator.instanceMethodId('compare', '(Ljava/lang/Object;Ljava/lang/Object;)I');
  final objectClass = JClass.forName('java/lang/Object');
  late final _getClass = objectClass.instanceMethodId('getClass', '()Ljava/lang/Class;');
  final classClass = JClass.forName('java/lang/Class');
  late final _getName = classClass.instanceMethodId('getName', '()Ljava/lang/String;');
  late final _getMethod =
      classClass.instanceMethodId('getMethod', '(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;');
  final methodClass = JClass.forName('java/lang/reflect/Method');
  late final _invoke =
      methodClass.instanceMethodId('invoke', '(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;');
  final Map<String, JObject> _methods = {};

  final doubleClass = JClass.forName('java/lang/Double');
  late final _doubleToString = doubleClass.staticMethodId('toString', '(D)Ljava/lang/String;');

  String doubleToString(double value) =>
      _doubleToString.call(doubleClass, JString.type, [value]).toDartString(releaseOriginal: true);

  kj.DateTimeFormatter ofPattern(String pattern, Arena arena) {
    final text = pattern.toJString()..releasedBy(arena);
    return _ofPattern.call(formatterClass, JObject.type, [text]).as(kj.DateTimeFormatter.type, releaseOriginal: true)
      ..releasedBy(arena);
  }

  kj.Duration durationOfMillis(double millis, Arena arena) {
    final exact = _newBigDecimal.call(bigDecimal, [millis])..releasedBy(arena);
    final secondsExact = _movePointLeft.call(exact, JObject.type, [JValueInt(3)])..releasedBy(arena);
    final rounded = _setScale.call(secondsExact, JObject.type, [JValueInt(9), halfUp])..releasedBy(arena);
    final whole = _setScale.call(rounded, JObject.type, [JValueInt(0), floor])..releasedBy(arena);
    final seconds = _longValueExact.call(whole, jlong.type, []);
    final fraction = _subtract.call(rounded, JObject.type, [whole])..releasedBy(arena);
    final nanosExact = _movePointRight.call(fraction, JObject.type, [JValueInt(9)])..releasedBy(arena);
    final nanos = _intValueExact.call(nanosExact, jint.type, []);
    return kj.Duration.ofSeconds$1(seconds, nanos)!..releasedBy(arena);
  }

  JObject newList(Arena arena) => _newList.call(arrayList, [])..releasedBy(arena);

  void add(JObject list, JObject? value) => _add.call(list, jboolean.type, [value ?? nullptr]);

  JObject? get(JObject list, int index) => _get.callNullable(list, JObject.type, [JValueInt(index)]);

  void sort(JObject list, JObject comparator) => _sort.call(list, jvoid.type, [comparator]);

  int compare(JObject comparator, JObject? first, JObject? second) =>
      _compare.call(comparator, jint.type, [first ?? nullptr, second ?? nullptr]);

  JObject? invokeGetter(JObject target, String name, Arena arena) {
    final cls = _getClass.call(target, JObject.type, [])..releasedBy(arena);
    final className = _getName.call(cls, JString.type, []).toDartString(releaseOriginal: true);
    final method = _methods.putIfAbsent('$className.$name', () {
      final methodName = name.toJString();
      final found = _getMethod.call(cls, JObject.type, [methodName, nullptr]);
      methodName.release();
      return found;
    });
    return _invoke.callNullable(method, JObject.type, [target, nullptr])?..releasedBy(arena);
  }
}

class _FormatterSetup {
  _FormatterSetup(Random rng, Zones zones, this.around) {
    final roll = rng.nextDouble();
    timeFormat = roll < 0.05 ? pick(rng, const [5, -1, 99]) : between(rng, 0, 4);
    defaultConstructor = chance(rng, 0.2);
    pattern = _randomPattern(rng);
    zone = chance(rng, 0.1) ? null : pick(rng, zones.names);
    laterPattern = chance(rng, 0.2) ? _randomPattern(rng) : null;
    laterTimeFormat = chance(rng, 0.05) ? pick(rng, const [5, -1, 99]) : null;
    laterZone = chance(rng, 0.1) ? pick(rng, zones.names) : null;
  }

  final int around;
  late final int timeFormat;
  late final bool defaultConstructor;
  late final String pattern;
  late final String? zone;
  late final String? laterPattern;
  late final int? laterTimeFormat;
  late final String? laterZone;

  @override
  String toString() => defaultConstructor
      ? 'ZmanimFormatter(zone=$zone)'
      : 'ZmanimFormatter(timeFormat=$timeFormat, pattern="$pattern", zone=$zone)'
          '${laterPattern == null ? '' : ' setDateTimeFormatter("$laterPattern")'}'
          '${laterTimeFormat == null ? '' : ' setTimeFormat($laterTimeFormat)'}'
          '${laterZone == null ? '' : ' setZoneId($laterZone)'}';
}

String _randomPattern(Random rng) {
  if (chance(rng, 0.3)) return pick(rng, _javaPatterns);
  final count = between(rng, 1, 6);
  return [for (var index = 0; index < count; index++) pick(rng, _patternPieces)].join();
}

class ZmanimFormatterArea extends Area {
  ZmanimFormatterArea(super.zones) : _zmanim = ZmanimArea(zones);

  final ZmanimArea _zmanim;
  final _Jvm _jvm = _Jvm();

  @override
  String get name => 'zmanim-formatter';

  @override
  void run(int seed, Iterable<int> indexes, Report report) {
    for (final index in indexes) {
      final rng = caseRandom(seed, name, index);
      final id = '$name#$index seed=$seed';
      _doubles(rng, id, report);
      using((arena) => _formatter(rng, id, report, arena));
      using((arena) => _comparators(rng, id, report, arena));
      using((arena) => _zmanXml(rng, id, report, arena));
      using((arena) => _geoXml(rng, id, report, arena));
      using((arena) => _calendar(rng, id, report, arena));
    }
  }

  void _doubles(Random rng, String id, Report report) {
    for (var repeat = 0; repeat < 40; repeat++) {
      final value = _randomDouble(rng);
      final bits = ByteData(8)..setFloat64(0, value);
      final input = '$id double=$value bits=${bits.getUint32(0).toRadixString(16)}:${bits.getUint32(4).toRadixString(16)}';
      report.exact('Double.toString', input, attempt(() => _jvm.doubleToString(value)), attempt(() => jd.javaDouble(value)));
    }
  }

  double _randomDouble(Random rng) {
    final sign = chance(rng, 0.5) ? -1.0 : 1.0;
    switch (rng.nextInt(9)) {
      case 0:
        final bits = ByteData(8)
          ..setUint32(0, rng.nextInt(1 << 32))
          ..setUint32(4, rng.nextInt(1 << 32));
        return bits.getFloat64(0);
      case 1:
        final bits = ByteData(8)
          ..setUint32(0, rng.nextInt(0x100000))
          ..setUint32(4, rng.nextInt(1 << 32));
        return sign * bits.getFloat64(0).abs();
      case 2:
        return sign * rng.nextInt(1 << 32) * pow(2, rng.nextInt(40)).toDouble();
      case 3:
        final power = pow(10, between(rng, -30, 30)).toDouble();
        return sign * (chance(rng, 0.5) ? power : _nextUp(power, rng.nextInt(3) - 1));
      case 4:
        return sign * uniform(rng, 0, 1) * pow(10, between(rng, -12, 12));
      case 5:
        return sign * (rng.nextInt(100000) / pow(10, rng.nextInt(8)));
      case 6:
        return between(rng, -1400, 1400) / 3600.0 * 60;
      case 7:
        return sign * pow(2, between(rng, -1074, 1023)).toDouble();
      default:
        return uniform(rng, -180, 180);
    }
  }

  double _nextUp(double value, int steps) {
    final bits = ByteData(8)..setFloat64(0, value);
    bits.setUint32(4, bits.getUint32(4) + steps);
    return bits.getFloat64(0);
  }

  tz.Location _dartZone(String name, int around) => zones.dartFromJava(name, around - 5 * _day, around + 5 * _day);

  int _randomInstantMicros(Random rng, String? zone) {
    final roll = rng.nextDouble();
    if (roll < 0.25 && zone != null) {
      final start = DateTime.utc(between(rng, 1900, 2100)).millisecondsSinceEpoch;
      final rules = zones.java(zone).rules!;
      final cursor = kj.Instant.ofEpochMilli(start + (rng.nextDouble() * 365 * _day).floor())!;
      final transition = rules.nextTransition(cursor);
      cursor.release();
      rules.release();
      if (transition != null) {
        final instant = transition.instant!;
        transition.release();
        final at = instant.toEpochMilli();
        instant.release();
        final shift = pick(rng, const [0, 1, -1, 1000, -1000, 1800000, -1800000, 3600000, -3600000]);
        return (at + shift) * 1000 + (chance(rng, 0.5) ? 0 : rng.nextInt(1000));
      }
    }
    final firstYear = roll < 0.4 ? -3000 : 1850;
    final lastYear = roll < 0.4 ? 12000 : 2150;
    final from = DateTime.utc(firstYear).microsecondsSinceEpoch;
    final to = DateTime.utc(lastYear).microsecondsSinceEpoch;
    final micros = from + (rng.nextDouble() * (to - from)).floor();
    return switch (rng.nextInt(4)) {
      0 => micros - micros % 1000000,
      1 => micros - micros % 1000,
      _ => micros,
    };
  }

  int _randomDurationMicros(Random rng) {
    final sign = chance(rng, 0.3) ? -1 : 1;
    return sign *
        switch (rng.nextInt(8)) {
          0 => 0,
          1 => rng.nextInt(1000),
          2 => rng.nextInt(1000000),
          3 => rng.nextInt(1 << 32),
          4 => (rng.nextDouble() * 86400e6).floor(),
          5 => (rng.nextDouble() * 1e15).floor(),
          6 => (rng.nextDouble() * 9.2e18).floor(),
          _ => pick(rng, const [1, 999, 1000, 999999, 1000000, 59999999, 60000000, 3599999999, 3600000000]),
        };
  }

  double _randomMillis(Random rng) {
    final sign = chance(rng, 0.3) ? -1.0 : 1.0;
    return sign *
        switch (rng.nextInt(8)) {
          0 => 0.0,
          1 => rng.nextDouble(),
          2 => rng.nextDouble() * 1000,
          3 => rng.nextDouble() * 86400000,
          4 => pow(10, uniform(rng, -12, 22)).toDouble(),
          5 => (rng.nextInt(1 << 31) * 1000 + rng.nextInt(1000)) / 12000,
          6 => pick(rng, const [0.0000005, 0.0000015, 0.0000025, 1e-9, 5e-7, 999.9999995, 3600000.0, 9.2233720368547e15]),
          _ => rng.nextInt(1 << 31) / pick(rng, const [3.0, 7.0, 12.0, 1024.0]),
        };
  }

  void _formatter(Random rng, String id, Report report, Arena arena) {
    final zoneName = chance(rng, 0.9) ? pick(rng, zones.names) : null;
    final base = _randomInstantMicros(rng, zoneName);
    final around = base ~/ 1000;
    final setup = _FormatterSetup(rng, zones, around);
    final describe = '$id $setup';
    kj.ZoneId? javaZone(String? name) => name == null ? null : zones.java(name);
    tz.Location? dartZone(String? name) => name == null ? null : _dartZone(name, around);

    final javaFormatter = attempt(() {
      final formatter = setup.defaultConstructor
          ? kj.ZmanimFormatter(javaZone(setup.zone))
          : kj.ZmanimFormatter.new$1(setup.timeFormat, _jvm.ofPattern(setup.pattern, arena), javaZone(setup.zone));
      formatter.releasedBy(arena);
      return formatter;
    });
    final dartFormatter = attempt(() => setup.defaultConstructor
        ? kd.ZmanimFormatter(dartZone(setup.zone))
        : kd.ZmanimFormatter.withFormat(
            setup.timeFormat, kd.DateTimeFormatter.ofPattern(setup.pattern), dartZone(setup.zone)));
    report.exact('formatter.constructor', describe, attempt(() => (javaFormatter as Value).value != null),
        attempt(() => (dartFormatter as Value).value != null));
    if (javaFormatter is! Value<kj.ZmanimFormatter> || dartFormatter is! Value<kd.ZmanimFormatter>) return;
    final java = javaFormatter.value;
    final dart = dartFormatter.value;
    if (setup.laterPattern != null) {
      report.exact(
          'formatter.setDateTimeFormatter',
          describe,
          attempt(() {
            java.dateTimeFormatter = _jvm.ofPattern(setup.laterPattern!, arena);
            return true;
          }),
          attempt(() {
            dart.setDateTimeFormatter(kd.DateTimeFormatter.ofPattern(setup.laterPattern!));
            return true;
          }));
    }
    if (setup.laterTimeFormat != null) {
      report.exact('formatter.setTimeFormat invalid', describe, attempt(() {
        java.timeFormat = setup.laterTimeFormat!;
        return true;
      }), attempt(() {
        dart.setTimeFormat(setup.laterTimeFormat!);
        return true;
      }));
    }
    if (setup.laterZone != null) {
      java.zoneId = javaZone(setup.laterZone);
      dart.setZoneId(dartZone(setup.laterZone));
    }
    final format = 'format(${setup.defaultConstructor ? 'default' : setup.timeFormat})';

    for (var repeat = 0; repeat < 4; repeat++) {
      final micros = repeat == 0 && chance(rng, 0.2) ? null : _randomDurationMicros(rng);
      final input = '$describe duration=${micros == null ? 'null' : '${micros}us'}';
      kj.Duration? javaDuration() {
        if (micros == null) return null;
        final (seconds, nanos) = _split(micros);
        return kj.Duration.ofSeconds$1(seconds, nanos)!..releasedBy(arena);
      }

      final dartDuration = micros == null ? null : Duration(microseconds: micros);
      report.exact('formatter.$format Duration', input, attempt(() => _javaText(java.format(javaDuration()))),
          attempt(() => dart.format(dartDuration)));
      report.exact('formatter.formatXSDDurationTime Duration', input,
          attempt(() => _javaText(java.formatXSDDurationTime(javaDuration()))),
          attempt(() => dart.formatXSDDurationTime(dartDuration)));
    }

    for (var repeat = 0; repeat < 3; repeat++) {
      final millis = _randomMillis(rng);
      final input = '$describe millis=$millis';
      final reference = attempt(() => _jvm.durationOfMillis(millis, arena));
      report.exact('formatter.$format millis', input,
          attempt(() => _javaText(java.format((reference as Value<kj.Duration>).value))),
          attempt(() => dart.formatMillis(millis)));
      report.exact('formatter.formatXSDDurationTime millis', input,
          attempt(() => _javaText(java.formatXSDDurationTime((reference as Value<kj.Duration>).value))),
          attempt(() => dart.formatXSDDurationMillis(millis)));
    }

    final time = kd.Time(between(rng, 0, 200), between(rng, 0, 59), between(rng, 0, 59), between(rng, 0, 999))
      ..setIsNegative(chance(rng, 0.3));
    final timeMillis = (time.getTime().toInt()) * (time.isNegative() ? -1 : 1);
    report.exact('formatter.$format Time', '$describe time=$time negative=${time.isNegative()}',
        attempt(() => _javaText(java.format(kj.Duration.ofMillis(timeMillis)!..releasedBy(arena)))),
        attempt(() => dart.formatTime(time)));

    final instantZone = chance(rng, 0.2) ? zoneName : pick(rng, zones.names);
    for (var repeat = 0; repeat < 3; repeat++) {
      final micros = repeat == 0 ? base : base + (chance(rng, 0.5) ? 0 : between(rng, -3 * _day, 3 * _day) * 1000);
      final (seconds, nanos) = _split(micros);
      final javaInstant = kj.Instant.ofEpochSecond$1(seconds, nanos)!..releasedBy(arena);
      final dartInstant = DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
      final input = '$describe instant=${micros}us (${dartInstant.toIso8601String()}) zone=$instantZone';
      final dartZoneForInstant = instantZone == null ? null : _dartZone(instantZone, micros ~/ 1000);
      report.exact('formatter.formatInstant', input,
          attempt(() => _javaText(java.formatInstant(javaInstant, javaZone(instantZone)))),
          attempt(() => dart.formatInstant(dartInstant, dartZoneForInstant!)));
      report.exact('formatter.formatXSDateTime', input, attempt(() => _javaText(java.formatXSDateTime(javaInstant))),
          attempt(() => dart.formatXSDateTime(dartInstant)));
    }
  }

  (kj.Zman?, kd.Zman?, String) _randomZman(Random rng, int index, Arena arena, {bool allowNull = true}) {
    if (allowNull && chance(rng, 0.05)) return (null, null, 'null');
    final label = chance(rng, 0.1) ? null : pick(rng, _labels);
    final instant = chance(rng, 0.3) ? null : _randomInstantMicros(rng, null) - (chance(rng, 0.5) ? 0 : 1);
    final duration = chance(rng, 0.6) ? null : _randomDurationMicros(rng) % 1000000000000;
    final description = '#$index';
    final javaLabel = label?.toJString()?..releasedBy(arena);
    kj.Instant? javaInstant;
    if (instant != null) {
      final (seconds, nanos) = _split(instant);
      javaInstant = kj.Instant.ofEpochSecond$1(seconds, nanos)!..releasedBy(arena);
    }
    kj.Duration? javaDuration;
    if (duration != null) {
      final (seconds, nanos) = _split(duration);
      javaDuration = kj.Duration.ofSeconds$1(seconds, nanos)!..releasedBy(arena);
    }
    final java = (instant == null && duration != null
        ? kj.Zman.new$2(javaDuration, javaLabel)
        : kj.Zman(javaInstant, javaLabel))
      ..releasedBy(arena);
    if (instant != null && duration != null) java.duration = javaDuration;
    java.description = description.toJString()..releasedBy(arena);
    final dart = instant == null && duration != null
        ? kd.Zman.duration(duration / 1000, label)
        : kd.Zman(instant == null ? null : DateTime.fromMicrosecondsSinceEpoch(instant, isUtc: true), label);
    if (instant != null && duration != null) dart.setDuration(duration / 1000);
    dart.setDescription(description);
    return (java, dart, '$description(label=$label instant=$instant duration=$duration)');
  }

  void _comparators(Random rng, String id, Report report, Arena arena) {
    final count = between(rng, 0, 14);
    final javaList = _jvm.newList(arena);
    final dartList = <kd.Zman?>[];
    final javaItems = <kj.Zman?>[];
    final described = <String>[];
    for (var index = 0; index < count; index++) {
      final reuse = index > 0 && chance(rng, 0.15);
      final (java, dart, text) = reuse
          ? (javaItems[rng.nextInt(index)], dartList[rng.nextInt(index)], 'repeat')
          : _randomZman(rng, index, arena);
      if (reuse) {
        final source = rng.nextInt(index);
        javaItems.add(javaItems[source]);
        dartList.add(dartList[source]);
        described.add('same as ${described[source].split('(').first}');
      } else {
        javaItems.add(java);
        dartList.add(dart);
        described.add(text);
      }
      _jvm.add(javaList, javaItems.last);
    }
    final input = '$id zmanim=[${described.join(', ')}]';
    final comparators = {
      'DATE_ORDER': (kj.Zman.DATE_ORDER!..releasedBy(arena), kd.Zman.DATE_ORDER),
      'NAME_ORDER': (kj.Zman.NAME_ORDER!..releasedBy(arena), kd.Zman.NAME_ORDER),
      'DURATION_ORDER': (kj.Zman.DURATION_ORDER!..releasedBy(arena), kd.Zman.DURATION_ORDER),
    };
    for (final MapEntry(key: name, value: (javaComparator, dartComparator)) in comparators.entries) {
      final pairs = <String>[];
      final javaSigns = <String>[];
      final dartSigns = <String>[];
      for (var first = 0; first < count; first++) {
        for (var second = 0; second < count; second++) {
          pairs.add('$first,$second');
          javaSigns.add('${_jvm.compare(javaComparator, javaItems[first], javaItems[second]).sign}');
          dartSigns.add('${dartComparator(dartList[first], dartList[second]).sign}');
        }
      }
      report.exact('Zman.$name compare', input, Value(javaSigns.join(' ')), Value(dartSigns.join(' ')));
      final javaCopy = _jvm.newList(arena);
      for (final item in javaItems) {
        _jvm.add(javaCopy, item);
      }
      _jvm.sort(javaCopy, javaComparator);
      final javaOrder = [
        for (var index = 0; index < count; index++)
          (_jvm.get(javaCopy, index)?..releasedBy(arena))?.as(kj.Zman.type).use((zman) => _javaText(zman.description)) ??
              'null',
      ];
      final dartCopy = [...dartList];
      _insertionSort(dartCopy, dartComparator);
      final dartOrder = [for (final zman in dartCopy) zman == null ? 'null' : '${zman.getDescription()}'];
      report.exact('Zman.$name sort', input, Value(javaOrder.join(' ')), Value(dartOrder.join(' ')));
    }
  }

  (kj.GeoLocation, kd.GeoLocation, String) _randomGeo(Random rng, int around, Arena arena) {
    final name = pick(rng, _names);
    final latitude = _interesting(rng, 90);
    final longitude = _interesting(rng, 180);
    final elevation = chance(rng, 0.3) ? 0.0 : _interesting(rng, chance(rng, 0.1) ? 1e12 : 9000).abs();
    final zone = pick(rng, zones.names);
    final javaName = name.toJString()..releasedBy(arena);
    final java = kj.GeoLocation.new$1(javaName, latitude, longitude, elevation, zones.java(zone))..releasedBy(arena);
    final location = _dartZone(zone, around);
    final viaDateTime = chance(rng, 0.5);
    final dart = kd.GeoLocation.setLocation(name, latitude, longitude,
        viaDateTime ? tz.TZDateTime.fromMillisecondsSinceEpoch(location, around) : DateTime.utc(2000), elevation);
    if (!viaDateTime) dart.setZoneId(location);
    return (java, dart, 'geo(name="$name" lat=$latitude lon=$longitude elev=$elevation zone=$zone'
        '${viaDateTime ? ' from TZDateTime' : ' setZoneId'})');
  }

  double _interesting(Random rng, double limit) {
    final sign = chance(rng, 0.5) ? -1.0 : 1.0;
    return switch (rng.nextInt(6)) {
      0 => uniform(rng, -limit, limit),
      1 => sign * pow(10, uniform(rng, -12, log(limit) / ln10)).toDouble().clamp(0, limit),
      2 => sign * pick(rng, [0.0, limit, 1e-3, 9.999999999999999e-4, 1e-4, 0.1, 0.5, 45.0, 4.9e-324, limit / 3]),
      3 => (uniform(rng, -limit, limit) * 1000).round() / 1000,
      4 => (uniform(rng, -limit, limit)).roundToDouble(),
      _ => sign * uniform(rng, 0, 1) * pow(10, -rng.nextInt(8)),
    };
  }

  void _zmanXml(Random rng, String id, Report report, Arena arena) {
    final (java, dart, text) = _randomZman(rng, 0, arena, allowNull: false);
    if (java == null || dart == null) return;
    var input = '$id $text';
    if (chance(rng, 0.6)) {
      final around = dart.getZman()?.millisecondsSinceEpoch ?? DateTime.utc(2025).millisecondsSinceEpoch;
      final (javaGeo, dartGeo, geoText) = _randomGeo(rng, around, arena);
      java.geoLocation = javaGeo;
      dart.setGeoLocation(dartGeo);
      input = '$input $geoText';
    }
    if (chance(rng, 0.3)) {
      java.description = null;
      dart.setDescription(null);
    }
    report.exact('Zman.toXML', input, attempt(() => _javaText(java.toXML())), attempt(() => dart.toXML()));
    report.exact('Zman.toString', input, attempt(() => _javaText(java.toString$1())), attempt(() => dart.toString()));
  }

  void _geoXml(Random rng, String id, Report report, Arena arena) {
    final around = _randomInstantMicros(rng, null) ~/ 1000;
    final (java, dart, text) = _randomGeo(rng, around, arena);
    report.exact('GeoLocation.toXML', '$id $text', attempt(() => _javaText(java.toXML())), attempt(() => dart.toXML()));
    report.exact('GeoLocation.toString', '$id $text', attempt(() => _javaText(java.toString$1())),
        attempt(() => dart.toString()));
  }

  void _calendar(Random rng, String id, Report report, Arena arena) {
    final input = ZmanimCase(rng, zones);
    if (input.machineLocal) return;
    final kind = pick(rng, const ['ComprehensiveZmanimCalendar', 'ComprehensiveZmanimCalendar', 'ZmanimCalendar', 'AstronomicalCalendar']);
    final locationName = pick(rng, _names);
    final describe = '${input.describe(id)} kind=$kind name="$locationName"';
    final zone = input.place.zone;
    final javaMidnight = zones.javaStartOfDay(zone, input.date.year, input.date.month, input.date.day);
    final location = zones.dartFromJava(zone, javaMidnight - 3 * _day, javaMidnight + 4 * _day);
    final midnight = tz.TZDateTime.fromMillisecondsSinceEpoch(location, javaMidnight);
    if (midnight.year != input.date.year || midnight.month != input.date.month || midnight.day != input.date.day) {
      report.note('skipped: the date does not exist in its zone, so no DateTime can name it');
      return;
    }
    final kj.AstronomicalCalendar java;
    final kd.AstronomicalCalendar dart;
    if (kind == 'ComprehensiveZmanimCalendar') {
      java = _zmanim.javaCalendarFor(input)..releasedBy(arena);
      dart = _zmanim.dartCalendarFor(input, midnight);
    } else {
      (java, dart) = _simpleCalendars(input, kind, midnight, arena);
    }
    final javaGeo = java.geoLocation!..releasedBy(arena);
    javaGeo.locationName = locationName.toJString()..releasedBy(arena);
    dart.getGeoLocation().setLocationName(locationName);

    final exact = <String, _Exact?>{};
    _Exact? exactOf(String tag) => exact.putIfAbsent(tag, () {
          try {
            final value = _jvm.invokeGetter(java, 'get$tag', arena);
            if (value == null) return null;
            if (value.isA(kj.Instant.type)) {
              final instant = value.as(kj.Instant.type)..releasedBy(arena);
              return _Exact(instant.epochSecond, instant.nano);
            }
            final duration = value.as(kj.Duration.type)..releasedBy(arena);
            return _Exact(duration.seconds, duration.nano);
          } catch (_) {
            return null;
          }
        });

    int? dartOf(String tag) {
      final base = _baseGetters[tag];
      final Object? value;
      if (base != null) {
        value = base(dart);
      } else if (dart is kd.ComplexZmanimCalendar) {
        value = switch (_dartGetters[tag]) {
          InstantZman(dart: final getter) => getter(dart),
          DurationZman(dart: final getter) => getter(dart),
          _ => null,
        };
      } else {
        return null;
      }
      if (value is DateTime) return value.microsecondsSinceEpoch;
      if (value is double && !value.isNaN) return (value * 1000).round();
      return null;
    }

    final values = (exactOf, dartOf);
    _compareSerialized(report, 'ZmanimFormatter.toXML', describe, attempt(() => _javaText(kj.ZmanimFormatter.toXML(java))),
        attempt(() => kd.ZmanimFormatter.toXML(dart)), values);
    _compareSerialized(report, 'AstronomicalCalendar.toJSON', describe, attempt(() => _javaText(java.toJSON())),
        attempt(() => dart.toJSON()), values);
    _compareSerialized(report, 'AstronomicalCalendar.toString', describe, attempt(() => _javaText(java.toString$1())),
        attempt(() => dart.toString()), values);
  }

  static final Map<String, Object? Function(kd.AstronomicalCalendar)> _baseGetters = {
    'BeginAstronomicalTwilight': (calendar) => calendar.getBeginAstronomicalTwilight(),
    'BeginCivilTwilight': (calendar) => calendar.getBeginCivilTwilight(),
    'BeginNauticalTwilight': (calendar) => calendar.getBeginNauticalTwilight(),
    'EndAstronomicalTwilight': (calendar) => calendar.getEndAstronomicalTwilight(),
    'EndCivilTwilight': (calendar) => calendar.getEndCivilTwilight(),
    'EndNauticalTwilight': (calendar) => calendar.getEndNauticalTwilight(),
    'SeaLevelSunrise': (calendar) => calendar.getSeaLevelSunrise(),
    'SeaLevelSunset': (calendar) => calendar.getSeaLevelSunset(),
    'SolarMidnight': (calendar) => calendar.getSolarMidnight(),
    'SunTransit': (calendar) => calendar.getSunTransit(),
    'Sunrise': (calendar) => calendar.getSunrise(),
    'Sunset': (calendar) => calendar.getSunset(),
    'TemporalHour': (calendar) => calendar.getTemporalHour(),
    'Alos16Point1Degrees': (calendar) => (calendar as kd.ZmanimCalendar).getAlosHashachar(),
    'Alos72Minutes': (calendar) => (calendar as kd.ZmanimCalendar).getAlos72(),
    'CandleLighting': (calendar) => (calendar as kd.ZmanimCalendar).getCandleLighting(),
    'ChatzosHalayla': (calendar) => (calendar as kd.ZmanimCalendar).getChatzosHalayla(),
    'ChatzosHayom': (calendar) => (calendar as kd.ZmanimCalendar).getChatzos(),
    'ChatzosHayomAsHalfDay': (calendar) => (calendar as kd.ZmanimCalendar).getChatzosAsHalfDay(),
    'MinchaGedolaGRA': (calendar) => (calendar as kd.ZmanimCalendar).getMinchaGedola(),
    'MinchaKetanaGRA': (calendar) => (calendar as kd.ZmanimCalendar).getMinchaKetana(),
    'PlagHaminchaGRA': (calendar) => (calendar as kd.ZmanimCalendar).getPlagHamincha(),
    'ShaahZmanis72Minutes': (calendar) => (calendar as kd.ZmanimCalendar).getShaahZmanisMGA(),
    'ShaahZmanisGRA': (calendar) => (calendar as kd.ZmanimCalendar).getShaahZmanisGra(),
    'SofZmanShmaGRA': (calendar) => (calendar as kd.ZmanimCalendar).getSofZmanShmaGRA(),
    'SofZmanShmaMGA72Minutes': (calendar) => (calendar as kd.ZmanimCalendar).getSofZmanShmaMGA(),
    'SofZmanTfilaGRA': (calendar) => (calendar as kd.ZmanimCalendar).getSofZmanTfilaGRA(),
    'SofZmanTfilaMGA72Minutes': (calendar) => (calendar as kd.ZmanimCalendar).getSofZmanTfilaMGA(),
    'Tzais72Minutes': (calendar) => (calendar as kd.ZmanimCalendar).getTzais72(),
    'TzaisGeonim8Point5Degrees': (calendar) => (calendar as kd.ZmanimCalendar).getTzais(),
  };

  static final Map<String, ZmanGetter> _dartGetters = {
    for (final getter in zmanGetters) getter.name.split(' / ').first.substring(3): getter,
  };

  (kj.AstronomicalCalendar, kd.AstronomicalCalendar) _simpleCalendars(
      ZmanimCase input, String kind, DateTime midnight, Arena arena) {
    final place = input.place;
    final name = 'case'.toJString()..releasedBy(arena);
    final geo = kj.GeoLocation.new$1(name, place.latitude, place.longitude, place.elevation, zones.java(place.zone))
      ..releasedBy(arena);
    final dartGeo = kd.GeoLocation.setLocation('case', place.latitude, place.longitude, midnight, place.elevation);
    final kj.AstronomicalCalendar java;
    final kd.AstronomicalCalendar dart;
    if (kind == 'ZmanimCalendar') {
      final javaZmanim = kj.ZmanimCalendar.new1(geo)..releasedBy(arena);
      final dartZmanim = kd.ZmanimCalendar.intGeolocation(dartGeo);
      if (input.useElevation != null) {
        javaZmanim.useElevation = input.useElevation!;
        dartZmanim.setUseElevation(input.useElevation!);
      }
      if (input.useAstronomicalChatzos != null) {
        javaZmanim.useAstronomicalChatzos = input.useAstronomicalChatzos!;
        dartZmanim.setUseAstronomicalChatzos(input.useAstronomicalChatzos!);
      }
      if (input.useAstronomicalChatzosForOtherZmanim != null) {
        javaZmanim.useAstronomicalChatzosForOtherZmanim = input.useAstronomicalChatzosForOtherZmanim!;
        dartZmanim.setUseAstronomicalChatzosForOtherZmanim(input.useAstronomicalChatzosForOtherZmanim!);
      }
      if (input.candleLightingOffset != null) {
        javaZmanim.candleLightingOffset = input.candleLightingOffset!;
        dartZmanim.setCandleLightingOffset(input.candleLightingOffset!);
      }
      java = javaZmanim;
      dart = dartZmanim;
    } else {
      java = kj.AstronomicalCalendar.new$1(geo)..releasedBy(arena);
      dart = kd.AstronomicalCalendar(geoLocation: dartGeo);
    }
    final date = kj.LocalDate.of$1(input.date.year, input.date.month, input.date.day)!..releasedBy(arena);
    java.localDate = date;
    if (input.sunTimes) {
      java.astronomicalCalculator = kj.SunTimesCalculator()..releasedBy(arena);
      dart.setAstronomicalCalculator(kd.SunTimesCalculator());
    }
    final settings = input.settings;
    if (settings != null) {
      final calculator = java.astronomicalCalculator!..releasedBy(arena);
      final dartCalculator = dart.getAstronomicalCalculator();
      if (settings.refraction != null) {
        calculator.refraction = settings.refraction!;
        dartCalculator.setRefraction(settings.refraction!);
      }
      if (settings.solarRadius != null) {
        calculator.solarRadius = settings.solarRadius!;
        dartCalculator.setSolarRadius(settings.solarRadius!);
      }
      if (settings.earthRadius != null) {
        calculator.earthRadius = settings.earthRadius!;
        dartCalculator.setEarthRadius(settings.earthRadius!);
      }
    }
    return (java, dart);
  }

  void _compareSerialized(Report report, String check, String input, Got<String> java, Got<String> dart,
      (_Exact? Function(String tag), int? Function(String tag)) values) {
    if (java is! Value<String> || dart is! Value<String>) return report.exact(check, input, java, dart);
    final (exactOf, dartOf) = values;
    final javaDocument = _Document.parse(java.value);
    final canonical = javaDocument.canonical(exactOf);
    if (canonical == dart.value) return report.record(check, Outcome.same, input, '');
    final dartDocument = _Document.parse(dart.value);
    final problem = _roundingOnly(javaDocument, dartDocument, exactOf, dartOf);
    final firstDifference = _firstDifference(canonical, dart.value);
    if (problem == null) {
      report.record(check, Outcome.rounding, input, firstDifference);
    } else {
      report.record(check, Outcome.differs, input, '$problem; $firstDifference');
    }
  }

  String? _roundingOnly(
      _Document java, _Document dart, _Exact? Function(String tag) exactOf, int? Function(String tag) dartOf) {
    if (java.frame.join('\n') != dart.frame.join('\n')) return 'header or footer differs';
    final javaValues = {for (final entry in java.entries) entry.tag: entry.value};
    final dartValues = {for (final entry in dart.entries) entry.tag: entry.value};
    if (java.entries.length != dart.entries.length || javaValues.length != dartValues.length) {
      return 'entry count differs';
    }
    for (final MapEntry(key: tag, value: javaValue) in javaValues.entries) {
      final dartValue = dartValues[tag];
      if (dartValue == null) return 'dart has no $tag';
      if (dartValue == javaValue) continue;
      final kind = _kindOf(javaValue);
      if (kind != _kindOf(dartValue)) return '$tag: $javaValue vs $dartValue';
      if (kind == _Kind.duration) {
        final difference = (_durationNanos(javaValue) - _durationNanos(dartValue)).abs();
        if (difference > 1000) return '$tag differs by ${difference}ns';
      } else if (kind == _Kind.instant) {
        final exact = exactOf(tag);
        final shown = DateTime.parse(dartValue).millisecondsSinceEpoch ~/ 1000;
        final boundary = shown > DateTime.parse(javaValue).millisecondsSinceEpoch ~/ 1000 ? shown : shown + 1;
        if (exact == null || (exact.minus(_Exact(boundary, 0))).abs() > 1000000) return '$tag: $javaValue vs $dartValue';
      } else {
        return '$tag: $javaValue vs $dartValue';
      }
    }
    for (var index = 1; index < dart.entries.length; index++) {
      final previous = dart.entries[index - 1];
      final current = dart.entries[index];
      final previousKind = _kindOf(previous.value);
      final currentKind = _kindOf(current.value);
      if (previousKind.index > currentKind.index) return 'sections out of order at ${current.tag}';
      if (previousKind != currentKind) continue;
      if (currentKind == _Kind.missing) {
        if (previous.tag.compareTo(current.tag) > 0) return 'N/A entries out of order at ${current.tag}';
        continue;
      }
      final before = exactOf(previous.tag);
      final after = exactOf(current.tag);
      if (before == null || after == null) return 'no java value for ${previous.tag} or ${current.tag}';
      final gap = after.minus(before);
      if (gap < -1000) return '${previous.tag} placed before ${current.tag}, ${-gap}ns later in java';
      if (gap == 0 && previous.tag.compareTo(current.tag) > 0) {
        final dartBefore = dartOf(previous.tag);
        final dartAfter = dartOf(current.tag);
        final splitByRounding =
            dartBefore != null && dartAfter != null && dartBefore < dartAfter && dartAfter - dartBefore <= 1000;
        if (!splitByRounding) return 'tie ${previous.tag}, ${current.tag} not by name';
      }
    }
    return null;
  }

  String _firstDifference(String java, String dart) {
    final javaLines = java.split('\n');
    final dartLines = dart.split('\n');
    for (var index = 0; index < max(javaLines.length, dartLines.length); index++) {
      final javaLine = index < javaLines.length ? javaLines[index] : '<none>';
      final dartLine = index < dartLines.length ? dartLines[index] : '<none>';
      if (javaLine != dartLine) return 'line $index java ${javaLine.trim()} | dart ${dartLine.trim()}';
    }
    return 'no line differs';
  }
}

enum _Kind { instant, duration, missing }

_Kind _kindOf(String value) => value == 'N/A'
    ? _Kind.missing
    : value.startsWith('P')
        ? _Kind.duration
        : _Kind.instant;

int _durationNanos(String text) {
  final match = RegExp(r'^PT(?:(-?\d+)H)?(?:(-?\d+)M)?(?:(-?)(\d+)(?:\.(\d+))?S)?$').firstMatch(text)!;
  final hours = int.parse(match.group(1) ?? '0');
  final minutes = int.parse(match.group(2) ?? '0');
  final secondsSign = match.group(3) == '-' ? -1 : 1;
  final seconds = int.parse(match.group(4) ?? '0');
  final fraction = int.parse((match.group(5) ?? '').padRight(9, '0'));
  return (hours * 3600 + minutes * 60) * _billion + secondsSign * (seconds * _billion + fraction);
}

class _Exact {
  const _Exact(this.seconds, this.nanos);
  final int seconds;
  final int nanos;

  int minus(_Exact other) => (seconds - other.seconds) * _billion + nanos - other.nanos;
}

class _Entry {
  _Entry(this.tag, this.value);
  final String tag;
  final String value;
}

class _Document {
  _Document(this.lines, this.entryLines, this.entries, this.json);

  factory _Document.parse(String text) {
    final lines = text.split('\n');
    final json = text.startsWith('{');
    final pattern = json ? RegExp(r'^\t"(\w+)":"(.*?)"(,|\})$') : RegExp(r'^\t<(\w+)>(.*)</\1>$');
    final entryLines = <int>[];
    final entries = <_Entry>[];
    var inBody = !json;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (json && !inBody) {
        inBody = RegExp(r'^"\w*":\{$').hasMatch(line) && index > 0 && lines[index - 1] != '{';
        continue;
      }
      final match = pattern.firstMatch(line);
      if (match == null || index == 0) continue;
      entryLines.add(index);
      entries.add(_Entry(match.group(1)!, match.group(2)!));
    }
    return _Document(lines, entryLines, entries, json);
  }

  final List<String> lines;
  final List<int> entryLines;
  final List<_Entry> entries;
  final bool json;

  List<String> get frame => [
        for (var index = 0; index < lines.length; index++)
          if (!entryLines.contains(index))
            lines[index]
          else if (json && lines[index].endsWith('}'))
            '<last entry>}',
      ];

  String canonical(_Exact? Function(String tag) exactOf) {
    final ordered = <_Entry>[];
    var start = 0;
    while (start < entries.length) {
      final kind = _kindOf(entries[start].value);
      var end = start + 1;
      bool sameGroup(_Entry first, _Entry next) {
        if (_kindOf(next.value) != kind) return false;
        if (kind == _Kind.missing) return true;
        final a = exactOf(first.tag);
        final b = exactOf(next.tag);
        return a != null && b != null && a.minus(b) == 0;
      }

      while (end < entries.length && sameGroup(entries[start], entries[end])) {
        end++;
      }
      ordered.addAll(entries.sublist(start, end)..sort((a, b) => a.tag.compareTo(b.tag)));
      start = end;
    }
    final result = [...lines];
    for (var index = 0; index < entryLines.length; index++) {
      final line = lines[entryLines[index]];
      final entry = ordered[index];
      result[entryLines[index]] = json
          ? '\t"${entry.tag}":"${entry.value}"${line.substring(line.length - 1)}'
          : '\t<${entry.tag}>${entry.value}</${entry.tag}>';
    }
    return result.join('\n');
  }
}

void _insertionSort<T>(List<T> list, Comparator<T> compare) {
  for (var index = 1; index < list.length; index++) {
    final item = list[index];
    var position = index;
    while (position > 0 && compare(list[position - 1], item) > 0) {
      list[position] = list[position - 1];
      position--;
    }
    list[position] = item;
  }
}
