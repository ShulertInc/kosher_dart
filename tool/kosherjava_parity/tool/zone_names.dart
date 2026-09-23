import 'dart:io';

import 'package:jni/jni.dart';
import 'package:kosherjava_parity/src/jvm.dart';
import 'package:kosherjava_parity/src/kosherjava.g.dart' as kj;
import 'package:path/path.dart' as p;

const firstMillis = -30610224000000;
const lastMillis = 32503680000000;

void main() {
  startJvm();
  final locale = JClass.forName('java/util/Locale');
  final english = locale.staticFieldId('ENGLISH', 'Ljava/util/Locale;').get(locale, JObject.type);
  final formatterClass = JClass.forName('java/time/format/DateTimeFormatter');
  final ofPattern = formatterClass.staticMethodId(
      'ofPattern', '(Ljava/lang/String;Ljava/util/Locale;)Ljava/time/format/DateTimeFormatter;');
  final formatId = formatterClass.instanceMethodId('format', '(Ljava/time/temporal/TemporalAccessor;)Ljava/lang/String;');
  final fullName = ofPattern.call(formatterClass, JObject.type, ['zzzz'.toJString(), english]);
  final textStyle = JClass.forName('java/time/format/TextStyle');
  final full = textStyle.staticFieldId('FULL', 'Ljava/time/format/TextStyle;').get(textStyle, JObject.type);
  final zoneIdClass = JClass.forName('java/time/ZoneId');
  final displayName = zoneIdClass.instanceMethodId(
      'getDisplayName', '(Ljava/time/format/TextStyle;Ljava/util/Locale;)Ljava/lang/String;');
  final timeZoneClass = JClass.forName('java/util/TimeZone');
  final getTimeZone = timeZoneClass.staticMethodId('getTimeZone', '(Ljava/lang/String;)Ljava/util/TimeZone;');
  final legacyName = timeZoneClass.instanceMethodId('getDisplayName', '(ZILjava/util/Locale;)Ljava/lang/String;');

  String nameAt(kj.ZoneId zone, int millis) {
    final instant = kj.Instant.ofEpochMilli(millis)!;
    final zoned = kj.ZonedDateTime.ofInstant(instant, zone)!;
    final text = formatId.call(fullName, JString.type, [zoned]).toDartString(releaseOriginal: true);
    zoned.release();
    instant.release();
    return text;
  }

  final ids = kj.ZoneId.availableZoneIds!;
  final names = [for (final id in ids.asDart()) id!.toDartString(releaseOriginal: true)]..sort();
  ids.release();
  final rows = <String>[];
  for (final name in names) {
    final zone = kj.ZoneId.of$1(name.toJString())!;
    final rules = zone.rules!;
    String? standard;
    String? daylight;
    void look(int millis) {
      final instant = kj.Instant.ofEpochMilli(millis)!;
      final isDaylight = rules.isDaylightSavings(instant);
      instant.release();
      if (isDaylight) {
        daylight ??= nameAt(zone, millis);
      } else {
        standard ??= nameAt(zone, millis);
      }
    }

    look(firstMillis);
    var at = firstMillis;
    while (standard == null || daylight == null) {
      final cursor = kj.Instant.ofEpochMilli(at)!;
      final transition = rules.nextTransition(cursor);
      cursor.release();
      if (transition == null) break;
      final instant = transition.instant!;
      transition.release();
      at = instant.toEpochMilli();
      instant.release();
      if (at > lastMillis) break;
      look(at);
    }
    final legacy = getTimeZone.call(timeZoneClass, JObject.type, [name.toJString()]);
    standard ??= legacyName.call(legacy, JString.type, [false, JValueInt(1), english]).toDartString(releaseOriginal: true);
    daylight ??= legacyName.call(legacy, JString.type, [true, JValueInt(1), english]).toDartString(releaseOriginal: true);
    legacy.release();
    final generic = displayName.call(zone, JString.type, [full, english]).toDartString(releaseOriginal: true);
    rules.release();
    zone.release();
    rows.add("  '$name': ['$standard', '$daylight', '$generic'],");
  }
  final target = p.join(packageRoot, '..', '..', 'lib', 'src', 'util', 'zone_names.dart');
  File(target).writeAsStringSync('const zoneNames = <String, List<String>>{\n${rows.join('\n')}\n};\n');
  stdout.writeln('${rows.length} zones written to ${p.normalize(target)}');
}
