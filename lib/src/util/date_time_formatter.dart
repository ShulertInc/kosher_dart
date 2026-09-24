
import 'package:timezone/timezone.dart';

import 'zone_names.dart';

class DateTimeFormatter {
  DateTimeFormatter._(this._pattern, this._fields, this._zone);

  factory DateTimeFormatter.ofPattern(String pattern) => DateTimeFormatter._(pattern, _parse(pattern), null);

  final String _pattern;
  final List<_Field> _fields;
  final Location? _zone;

  String getPattern() => _pattern;

  Location? getZone() => _zone;

  DateTimeFormatter withZone(Location? zone) => DateTimeFormatter._(_pattern, _fields, zone);

  String format(DateTime instant, [Location? zone]) {
    final location = _zone ?? zone ?? (instant is TZDateTime ? instant.location : null);
    if (location == null && _fields.any((field) => field.letter == 'X' || field.letter == 'z')) {
      throw ArgumentError('Unable to extract ZoneId from temporal $instant');
    }
    final local = location == null ? instant : TZDateTime.fromMicrosecondsSinceEpoch(location, instant.microsecondsSinceEpoch);
    final buffer = StringBuffer();
    for (final field in _fields) {
      field.write(buffer, local, location);
    }
    return buffer.toString();
  }

  @override
  String toString() => _pattern;

  static List<_Field> _parse(String pattern) {
    final fields = <_Field>[];
    var index = 0;
    while (index < pattern.length) {
      final char = pattern[index];
      if (_isLetter(char)) {
        var end = index + 1;
        while (end < pattern.length && pattern[end] == char) {
          end++;
        }
        fields.add(_Field.letter(char, end - index));
        index = end;
      } else if (char == "'") {
        final literal = StringBuffer();
        var end = index + 1;
        while (true) {
          if (end >= pattern.length) throw ArgumentError('Pattern ends with an incomplete string literal: $pattern');
          if (pattern[end] == "'") {
            if (end + 1 < pattern.length && pattern[end + 1] == "'") {
              literal.write("'");
              end += 2;
              continue;
            }
            break;
          }
          literal.write(pattern[end]);
          end++;
        }
        fields.add(_Field.literal(end == index + 1 ? "'" : literal.toString()));
        index = end + 1;
      } else if ('[]{}#'.contains(char)) {
        throw ArgumentError("Pattern includes reserved or unsupported character '$char'");
      } else {
        fields.add(_Field.literal(char));
        index++;
      }
    }
    return fields;
  }

  static bool _isLetter(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class _Field {
  _Field.literal(this.text)
      : letter = '',
        count = 0;

  _Field.letter(this.letter, this.count) : text = '' {
    final maximum = switch (letter) {
      'y' => 19,
      'M' => 5,
      'd' || 'H' || 'h' || 'm' || 's' => 2,
      'S' => 9,
      'a' => 1,
      'X' => 5,
      'z' => 4,
      _ => throw ArgumentError('Unsupported pattern letter: $letter'),
    };
    if (count > maximum) throw ArgumentError('Too many pattern letters: $letter');
    if (letter == 'z' && count < 4) throw ArgumentError('Unsupported pattern letter count: $letter');
  }

  final String letter;
  final int count;
  final String text;

  void write(StringBuffer buffer, DateTime local, Location? zone) {
    switch (letter) {
      case '':
        buffer.write(text);
      case 'y':
        final year = local.year > 0 ? local.year : 1 - local.year;
        if (count == 2) {
          buffer.write((year % 100).toString().padLeft(2, '0'));
        } else {
          final digits = year.toString();
          if (count >= 4 && digits.length > count) buffer.write('+');
          buffer.write(digits.padLeft(count, '0'));
        }
      case 'M':
        switch (count) {
          case 3:
            buffer.write(_monthNames[local.month - 1].substring(0, 3));
          case 4:
            buffer.write(_monthNames[local.month - 1]);
          case 5:
            buffer.write(_monthNames[local.month - 1][0]);
          default:
            _number(buffer, local.month);
        }
      case 'd':
        _number(buffer, local.day);
      case 'H':
        _number(buffer, local.hour);
      case 'h':
        _number(buffer, local.hour % 12 == 0 ? 12 : local.hour % 12);
      case 'm':
        _number(buffer, local.minute);
      case 's':
        _number(buffer, local.second);
      case 'S':
        final nanos = (local.millisecond * 1000 + local.microsecond) * 1000;
        buffer.write(nanos.toString().padLeft(9, '0').substring(0, count));
      case 'a':
        buffer.write(local.hour < 12 ? 'AM' : 'PM');
      case 'X':
        buffer.write(offsetText(local.timeZoneOffset.inSeconds, count));
      case 'z':
        buffer.write(zoneName(zone!, (local as TZDateTime).timeZone.isDst));
    }
  }

  void _number(StringBuffer buffer, int value) => buffer.write(value.toString().padLeft(count, '0'));
}

String offsetText(int totalSeconds, int count) {
  if (totalSeconds == 0) return 'Z';
  final colon = count == 3 || count == 5;
  final absHours = (totalSeconds ~/ 3600).abs() % 100;
  final absMinutes = (totalSeconds ~/ 60).abs() % 60;
  final absSeconds = totalSeconds.abs() % 60;
  final buffer = StringBuffer(totalSeconds < 0 ? '-' : '+')..write(absHours.toString().padLeft(2, '0'));
  var output = absHours;
  if (count > 1 || absMinutes > 0) {
    if (colon) buffer.write(':');
    buffer.write(absMinutes.toString().padLeft(2, '0'));
    output += absMinutes;
    if (count >= 4 && absSeconds > 0) {
      if (colon) buffer.write(':');
      buffer.write(absSeconds.toString().padLeft(2, '0'));
      output += absSeconds;
    }
  }
  return output == 0 ? 'Z' : buffer.toString();
}

String zoneName(Location zone, bool daylight) => zoneNames[zone.name]?[daylight ? 1 : 0] ?? zone.name;

String zoneGenericName(Location zone) => zoneNames[zone.name]?[2] ?? zone.name;

TZDateTime startOfDay(Location zone, int year, int month, int day) {
  final wall = DateTime.utc(year, month, day).millisecondsSinceEpoch;
  int offsetAt(int millis) => TZDateTime.fromMillisecondsSinceEpoch(zone, millis).timeZoneOffset.inMilliseconds;
  final candidates = {
    for (final probe in [wall - 86400000, wall, wall + 86400000]) offsetAt(probe),
  };
  final valid = candidates.where((offset) => offsetAt(wall - offset) == offset).toList();
  final offset = valid.isEmpty
      ? candidates.reduce((a, b) => a < b ? a : b)
      : valid.reduce((a, b) => a > b ? a : b);
  return TZDateTime.fromMillisecondsSinceEpoch(zone, wall - offset);
}

String instantText(DateTime instant) {
  final utc = instant.toUtc();
  final year = utc.year;
  final yearText = year > 9999
      ? '+$year'
      : year < 0
          ? '-${(-year).toString().padLeft(4, '0')}'
          : year.toString().padLeft(4, '0');
  String two(int value) => value.toString().padLeft(2, '0');
  final micros = utc.millisecond * 1000 + utc.microsecond;
  final fraction = micros == 0
      ? ''
      : micros % 1000 == 0
          ? '.${(micros ~/ 1000).toString().padLeft(3, '0')}'
          : '.${micros.toString().padLeft(6, '0')}';
  return '$yearText-${two(utc.month)}-${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}$fraction'
      'Z';
}

(int, int) spanOfMicros(int micros) {
  final nanos = micros % 1000000 * 1000;
  return ((micros - micros % 1000000) ~/ 1000000, nanos);
}

String javaDurationText(int seconds, int nanos) {
  if (seconds == 0 && nanos == 0) return 'PT0S';
  var effectiveTotalSeconds = seconds;
  if (seconds < 0 && nanos > 0) effectiveTotalSeconds++;
  final hours = effectiveTotalSeconds ~/ 3600;
  final minutes = effectiveTotalSeconds.remainder(3600) ~/ 60;
  final secs = effectiveTotalSeconds.remainder(60);
  final buffer = StringBuffer('PT');
  if (hours != 0) buffer.write('${hours}H');
  if (minutes != 0) buffer.write('${minutes}M');
  if (secs == 0 && nanos == 0 && buffer.length > 2) return buffer.toString();
  if (seconds < 0 && nanos > 0 && secs == 0) {
    buffer.write('-0');
  } else {
    buffer.write(secs);
  }
  if (nanos > 0) {
    var fraction = (seconds < 0 ? 1000000000 - nanos : nanos).toString().padLeft(9, '0');
    while (fraction.endsWith('0')) {
      fraction = fraction.substring(0, fraction.length - 1);
    }
    buffer.write('.$fraction');
  }
  buffer.write('S');
  return buffer.toString();
}
