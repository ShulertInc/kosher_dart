import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;

import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';

bool isJewishLeapYear(int year) => (7 * year + 1) % 19 < 7;

void compareOrBothThrow<T>(Report report, String check, String input, Got<T> java, Got<T> dart) {
  if (java is Threw<T> && dart is Threw<T>) return report.record(check, Outcome.same, input, '');
  report.exact(check, input, java, dart);
}

String? javaString(JString? value) {
  final text = value?.toDartString(releaseOriginal: true);
  return text == null ? null : withKosherDartMonthNames(text);
}

String javaStrings(JArray<JString?>? values) {
  final strings = [for (var i = 0; i < values!.length; i++) javaString(values[i])];
  values.release();
  return strings.join('|');
}

class CalendarDay {
  CalendarDay._(this.gregorian, this.jewish, this.inIsrael, this.isMukafChoma, this.useModernHolidays, this.utc);

  factory CalendarDay.random(Random rng) {
    final inIsrael = chance(rng, 0.5);
    final isMukafChoma = chance(rng, 0.3);
    final useModernHolidays = chance(rng, 0.5);
    final utc = chance(rng, 0.5);
    if (chance(rng, 0.6)) {
      final date = chance(rng, 0.75) ? randomDate(rng, 1900, 2300) : randomDate(rng, 1, 9999);
      return CalendarDay._(date, null, inIsrael, isMukafChoma, useModernHolidays, utc);
    }
    final year = chance(rng, 0.75) ? between(rng, 5660, 6060) : between(rng, 3762, 13700);
    final month = between(rng, 1, isJewishLeapYear(year) ? 13 : 12);
    var day = between(rng, 1, 29);
    if (chance(rng, 0.2)) {
      final probe = kj.JewishDate.new$1(year, month, 1);
      if (probe.daysInJewishMonth == 30) day = 30;
      probe.release();
    }
    return CalendarDay._(null, (year, month, day), inIsrael, isMukafChoma, useModernHolidays, utc);
  }

  final CivilDate? gregorian;
  final (int, int, int)? jewish;
  final bool inIsrael;
  final bool isMukafChoma;
  final bool useModernHolidays;
  final bool utc;

  @override
  String toString() {
    final origin = gregorian != null
        ? 'gregorian=$gregorian ${utc ? 'utc' : 'local'}'
        : 'jewish=${jewish!.$1}-${jewish!.$2}-${jewish!.$3}';
    return '$origin inIsrael=$inIsrael mukafChoma=$isMukafChoma modern=$useModernHolidays';
  }

  kj.JewishCalendar java() {
    final kj.JewishCalendar calendar;
    if (gregorian case final date?) {
      final local = kj.LocalDate.of$1(date.year, date.month, date.day);
      calendar = kj.JewishCalendar.new4(local);
      local?.release();
    } else {
      calendar = kj.JewishCalendar.new1(jewish!.$1, jewish!.$2, jewish!.$3);
    }
    calendar
      ..inIsrael = inIsrael
      ..isMukafChoma = isMukafChoma
      ..useModernHolidays = useModernHolidays;
    return calendar;
  }

  kd.JewishCalendar dart() {
    final kd.JewishCalendar calendar;
    if (gregorian case final date?) {
      calendar = kd.JewishCalendar.fromDateTime(
          utc ? DateTime.utc(date.year, date.month, date.day) : DateTime(date.year, date.month, date.day));
    } else {
      calendar = kd.JewishCalendar.initDate(jewish!.$1, jewish!.$2, jewish!.$3);
    }
    calendar
      ..inIsrael = inIsrael
      ..isMukafChoma = isMukafChoma
      ..setUseModernHolidays(useModernHolidays);
    return calendar;
  }

  String stateOfJava(kj.JewishDate date) {
    final local = date.localDate!;
    final state = '${date.jewishYear}-${date.jewishMonth}-${date.jewishDayOfMonth} dow=${date.dayOfWeek} '
        '${local.year}-${local.monthValue}-${local.dayOfMonth}';
    local.release();
    return state;
  }

  String stateOfDart(kd.JewishDate date) =>
      '${date.getJewishYear()}-${date.getJewishMonth()}-${date.getJewishDayOfMonth()} dow=${date.getDayOfWeek()} '
      '${date.getGregorianYear()}-${date.getGregorianMonth()}-${date.getGregorianDayOfMonth()}';

  bool agrees(Report report, String area, String describe) {
    final javaState = attempt(() {
      final calendar = java();
      final state = stateOfJava(calendar);
      calendar.release();
      return state;
    });
    final dartState = attempt(() => stateOfDart(dart()));
    report.exact('$area.construction', describe, javaState, dartState);
    return javaState is Value<String> && dartState is Value<String> && javaState.value == dartState.value;
  }
}
