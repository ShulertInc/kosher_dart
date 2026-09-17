import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;
import 'package:timezone/timezone.dart' as tz;

import '../area.dart';
import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';

const _sweepSpanDays = 150000;
const _day = 86400000;

Got<Object?> orThrows(Object? Function() body) {
  try {
    return Value(body());
  } catch (_) {
    return const Value('throws');
  }
}

String javaString(JString? value) =>
    withKosherDartMonthNames(value?.toDartString(releaseOriginal: true) ?? 'null');

String javaEnumName(JObject? value) {
  if (value == null) return 'null';
  final name = value.toString();
  value.release();
  return name;
}

int? javaMillis(kj.Instant? instant) {
  if (instant == null) return null;
  final millis = instant.toEpochMilli();
  instant.release();
  return millis;
}

class CalendarPair {
  CalendarPair(this.java, this.dart, this.describe);

  final kj.JewishCalendar java;
  final kd.JewishCalendar dart;
  final String describe;
}

class JewishDateFields {
  const JewishDateFields(this.year, this.month, this.day);
  final int year;
  final int month;
  final int day;

  @override
  String toString() => '$year-$month-$day';
}

typedef CalendarCheck = (String, Object? Function(kj.JewishCalendar), Object? Function(kd.JewishCalendar));

final List<CalendarCheck> calendarChecks = [
  ('getInIsrael', (j) => j.inIsrael, (d) => d.inIsrael),
  ('getIsMukafChoma', (j) => j.isMukafChoma, (d) => d.isMukafChoma),
  ('isUseModernHolidays', (j) => j.isUseModernHolidays, (d) => d.isUseModernHolidays()),
  ('getYomTovIndex', (j) => j.yomTovIndex, (d) => d.getYomTovIndex()),
  ('isBirkasHachamah', (j) => j.isBirkasHachamah, (d) => d.isBirkasHachamah()),
  ('isYomTov', (j) => j.isYomTov, (d) => d.isYomTov()),
  ('isYomTovAssurBemelacha', (j) => j.isYomTovAssurBemelacha, (d) => d.isYomTovAssurBemelacha()),
  ('isAssurBemelacha', (j) => j.isAssurBemelacha, (d) => d.isAssurBemelacha()),
  ('isTonightMutarBemelacha', (j) => j.isTonightMutarBemelacha, (d) => d.isTonightMutarBemelacha()),
  ('hasCandleLighting', (j) => j.hasCandleLighting(), (d) => d.hasCandleLighting()),
  ('isTomorrowShabbosOrYomTov', (j) => j.isTomorrowShabbosOrYomTov, (d) => d.isTomorrowShabbosOrYomTov()),
  ('isErevYomTovSheni', (j) => j.isErevYomTovSheni, (d) => d.isErevYomTovSheni()),
  ('isAseresYemeiTeshuva', (j) => j.isAseresYemeiTeshuva, (d) => d.isAseresYemeiTeshuva()),
  ('isPesach', (j) => j.isPesach, (d) => d.isPesach()),
  ('isCholHamoedPesach', (j) => j.isCholHamoedPesach, (d) => d.isCholHamoedPesach()),
  ('isShavuos', (j) => j.isShavuos, (d) => d.isShavuos()),
  ('isRoshHashana', (j) => j.isRoshHashana, (d) => d.isRoshHashana()),
  ('isYomKippur', (j) => j.isYomKippur, (d) => d.isYomKippur()),
  ('isSuccos', (j) => j.isSuccos, (d) => d.isSuccos()),
  ('isHoshanaRabba', (j) => j.isHoshanaRabba, (d) => d.isHoshanaRabba()),
  ('isShminiAtzeres', (j) => j.isShminiAtzeres, (d) => d.isShminiAtzeres()),
  ('isSimchasTorah', (j) => j.isSimchasTorah, (d) => d.isSimchasTorah()),
  ('isCholHamoedSuccos', (j) => j.isCholHamoedSuccos, (d) => d.isCholHamoedSuccos()),
  ('isCholHamoed', (j) => j.isCholHamoed, (d) => d.isCholHamoed()),
  ('isErevYomTov', (j) => j.isErevYomTov, (d) => d.isErevYomTov()),
  ('isErevRoshChodesh', (j) => j.isErevRoshChodesh, (d) => d.isErevRoshChodesh()),
  ('isYomKippurKatan', (j) => j.isYomKippurKatan, (d) => d.isYomKippurKatan()),
  ('isBeHaB', (j) => j.isBeHaB, (d) => d.isBeHaB()),
  ('isTaanis', (j) => j.isTaanis, (d) => d.isTaanis()),
  ('isTaanisBechoros', (j) => j.isTaanisBechoros, (d) => d.isTaanisBechoros()),
  ('getDayOfChanukah', (j) => j.dayOfChanukah, (d) => d.getDayOfChanukah()),
  ('isChanukah', (j) => j.isChanukah, (d) => d.isChanukah()),
  ('isPurim', (j) => j.isPurim, (d) => d.isPurim()),
  ('isRoshChodesh', (j) => j.isRoshChodesh, (d) => d.isRoshChodesh()),
  ('isMacharChodesh', (j) => j.isMacharChodesh, (d) => d.isMacharChodesh()),
  ('isShabbosMevorchim', (j) => j.isShabbosMevorchim, (d) => d.isShabbosMevorchim()),
  ('getDayOfOmer', (j) => j.dayOfOmer, (d) => d.getDayOfOmer()),
  ('isTishaBav', (j) => j.isTishaBav, (d) => d.isTishaBav()),
  ('isIsruChag', (j) => j.isIsruChag, (d) => d.isIsruChag()),
  ('getTekufasTishreiElapsedDays', (j) => j.tekufasTishreiElapsedDays, (d) => d.getTekufasTishreiElapsedDays()),
  ('getParshah', (j) => javaEnumName(j.parshah), (d) => d.getParshah().name),
  ('getSpecialShabbos', (j) => javaEnumName(j.specialShabbos), (d) => d.getSpecialShabbos().name),
  ('getUpcomingParshah', (j) => javaEnumName(j.upcomingParshah), (d) => d.getUpcomingParshah().name),
];

typedef CalendarInstant = (String, kj.Instant? Function(kj.JewishCalendar), DateTime? Function(kd.JewishCalendar));

final List<CalendarInstant> calendarInstants = [
  ('getMoladAsInstant / getMoladAsDateTime', (j) => j.moladAsInstant, (d) => d.getMoladAsDateTime()),
  ('getTchilasZmanKidushLevana3Days', (j) => j.tchilasZmanKidushLevana3Days, (d) => d.getTchilasZmanKidushLevana3Days()),
  ('getTchilasZmanKidushLevana7Days', (j) => j.tchilasZmanKidushLevana7Days, (d) => d.getTchilasZmanKidushLevana7Days()),
  (
    'getSofZmanKidushLevanaBetweenMoldos',
    (j) => j.sofZmanKidushLevanaBetweenMoldos,
    (d) => d.getSofZmanKidushLevanaBetweenMoldos()
  ),
  ('getSofZmanKidushLevana15Days', (j) => j.sofZmanKidushLevana15Days, (d) => d.getSofZmanKidushLevana15Days()),
];

const _arithmeticOperations = [
  'plusDays',
  'minusDays',
  'plusMonths',
  'minusMonths',
  'plusYears',
  'minusYears',
  'setJewishYear',
  'setJewishMonth',
  'setJewishDayOfMonth',
  'setJewishDate',
  'setGregorianDate',
];

class CalendarArea extends Area {
  CalendarArea(super.zones);

  @override
  String get name => 'calendar';

  @override
  void run(int seed, Iterable<int> indexes, Report report) {
    for (final index in indexes) {
      final rng = caseRandom(seed, 'calendar', index);
      final id = 'calendar#$index seed=$seed';

      final sweep = sweepPair(rng, index, id);
      compareCalendar(report, 'calendar', sweep);
      compareDafYomi(rng, report, sweep, 'setGregorianDate');
      sweep.java.release();

      final (random, path) = randomPair(rng, id);
      compareCalendar(report, 'calendar', random);
      compareDafYomi(rng, report, random, path);
      compareMolad(report, random);
      if (chance(rng, 0.2)) {
        final javaClone = random.java.clone() as kj.JewishCalendar;
        compareCalendar(report, 'calendar.clone', CalendarPair(javaClone, random.dart.clone(), '${random.describe} cloned'));
        javaClone.release();
      }
      random.java.release();

      compareArithmetic(rng, report, id);
      compareMoladConstructor(rng, report, id);
      compareStatics(rng, report, id);
      compareInvalid(rng, report, id);
      compareOrdering(rng, report, id);
      compareMasechtaNames(report, index, id);
    }
  }

  void compareMasechtaNames(Report report, int index, String id) {
    final bavli = index % 40;
    final yerushalmi = index % 39;
    final input = '$id masechta bavli=$bavli yerushalmi=$yerushalmi';
    final javaDaf = kj.Daf(bavli, 2);
    final dartDaf = kd.Daf(bavli, 2);
    report.exact('calendar.Daf.getMasechtaTransliterated', input, attempt(() => javaString(javaDaf.masechtaTransliterated)),
        attempt(() => dartDaf.getMasechtaTransliterated()));
    report.exact('calendar.Daf.getMasechta', input, attempt(() => javaString(javaDaf.masechta)),
        attempt(() => dartDaf.getMasechta()));
    javaDaf.masechtaNumber = yerushalmi;
    dartDaf.setMasechtaNumber(yerushalmi);
    report.exact('calendar.Daf.getYerushalmiMasechtaTransliterated', input,
        attempt(() => javaString(javaDaf.yerushalmiMasechtaTransliterated)),
        attempt(() => dartDaf.getYerushlmiMasechtaTransliterated()));
    report.exact('calendar.Daf.getYerushalmiMasechta', input, attempt(() => javaString(javaDaf.yerushalmiMasechta)),
        attempt(() => dartDaf.getYerushalmiMasechta()));
    report.exact('calendar.Daf.getDaf / setDaf', input, attempt(() {
      javaDaf.daf = index % 180;
      return javaDaf.daf;
    }), attempt(() {
      dartDaf.setDaf(index % 180);
      return dartDaf.getDaf();
    }));
    javaDaf.release();
  }

  void applyFlags(Random rng, kj.JewishCalendar java, kd.JewishCalendar dart) {
    if (chance(rng, 0.2)) return;
    final inIsrael = chance(rng, 0.5);
    final mukafChoma = chance(rng, 0.3);
    final modern = chance(rng, 0.5);
    java
      ..inIsrael = inIsrael
      ..isMukafChoma = mukafChoma
      ..useModernHolidays = modern;
    dart
      ..inIsrael = inIsrael
      ..isMukafChoma = mukafChoma
      ..setUseModernHolidays(modern);
  }

  String flags(kd.JewishCalendar dart) =>
      'inIsrael=${dart.inIsrael} mukafChoma=${dart.isMukafChoma} modern=${dart.isUseModernHolidays()}';

  CalendarPair sweepPair(Random rng, int index, String id) {
    final date = DateTime.utc(1900, 1, 1).add(Duration(days: index % _sweepSpanDays));
    final localDate = kj.LocalDate.of$1(date.year, date.month, date.day)!;
    final java = kj.JewishCalendar.new4(localDate);
    localDate.release();
    final dart = kd.JewishCalendar()..setGregorianDate(date.year, date.month, date.day);
    applyFlags(rng, java, dart);
    return CalendarPair(
        java, dart, '$id sweep gregorian=${CivilDate(date.year, date.month, date.day)} ${flags(dart)}');
  }

  CivilDate randomGregorian(Random rng) {
    if (chance(rng, 0.08)) {
      final edge = pick(rng, const [CivilDate(1923, 9, 11), CivilDate(1975, 6, 24), CivilDate(1980, 2, 2)]);
      final shifted = DateTime.utc(edge.year, edge.month, edge.day).add(Duration(days: between(rng, -2, 1)));
      return CivilDate(shifted.year, shifted.month, shifted.day);
    }
    if (chance(rng, 0.05)) {
      final cycles = between(rng, -68, 285);
      return CivilDate(1925 + 28 * cycles, pick(rng, const [3, 4, 4, 4]), between(rng, 1, 31).clamp(1, 30));
    }
    if (chance(rng, 0.04)) return CivilDate(between(rng, 1, 9999), 12, between(rng, 1, 10));
    if (chance(rng, 0.01)) return CivilDate(1, 1, between(rng, 1, 31));
    final roll = rng.nextDouble();
    if (roll < 0.65) return randomDate(rng, 1900, 2300);
    if (roll < 0.9) return randomDate(rng, 1, 9999);
    return randomDate(rng, 1920, 1985);
  }

  JewishDateFields randomJewish(Random rng) {
    final yearRoll = rng.nextDouble();
    final year = yearRoll < 0.03
        ? pick(rng, const [3761, 3762])
        : yearRoll < 0.6
            ? between(rng, 5660, 6060)
            : between(rng, 3762, 13000);
    final leap = kj.JewishDate.isJewishLeapYear(year);
    final int month;
    final monthRoll = rng.nextDouble();
    if (year == 3761) {
      month = monthRoll < 0.5 ? kd.JewishDate.TEVES : pick(rng, [11, 12, if (leap) 13, 1, 2, 3, 4, 5, 6]);
    } else if (monthRoll < 0.1) {
      month = kd.JewishDate.IYAR;
    } else if (monthRoll < 0.25) {
      month = leap ? pick(rng, const [kd.JewishDate.ADAR, kd.JewishDate.ADAR_II]) : kd.JewishDate.ADAR;
    } else if (monthRoll < 0.3) {
      month = pick(rng, const [kd.JewishDate.CHESHVAN, kd.JewishDate.KISLEV, kd.JewishDate.ELUL, kd.JewishDate.TISHREI]);
    } else {
      month = between(rng, 1, leap ? 13 : 12);
    }
    final firstValid = year == 3761 && month == kd.JewishDate.TEVES ? 18 : 1;
    final first = kj.JewishDate.new$1(year, month, firstValid);
    final length = first.daysInJewishMonth;
    first.release();
    final day = chance(rng, 0.25) ? length : between(rng, firstValid, length);
    return JewishDateFields(year, month, day);
  }

  kj.JewishCalendar javaFromLocalDate(CivilDate date) {
    final localDate = kj.LocalDate.of$1(date.year, date.month, date.day)!;
    final java = kj.JewishCalendar.new4(localDate);
    localDate.release();
    return java;
  }

  (CalendarPair, String) randomPair(Random rng, String id) {
    final path =
        pick(rng, const ['localDateTime', 'utcDateTime', 'tzDateTime', 'setGregorianDate', 'setDate', 'jewish']);
    final kj.JewishCalendar java;
    final kd.JewishCalendar dart;
    final String input;
    switch (path) {
      case 'localDateTime':
        final date = randomGregorian(rng);
        final hour = between(rng, 0, 23);
        java = javaFromLocalDate(date);
        dart = kd.JewishCalendar.fromDateTime(DateTime(date.year, date.month, date.day, hour));
        input = 'gregorian=$date hour=$hour';
      case 'utcDateTime':
        final date = randomGregorian(rng);
        final hour = between(rng, 0, 23);
        java = javaFromLocalDate(date);
        dart = kd.JewishCalendar.fromDateTime(DateTime.utc(date.year, date.month, date.day, hour));
        input = 'gregorian=$date hour=$hour';
      case 'tzDateTime':
        final zone = pick(rng, zones.names);
        final millis = uniform(rng, -2208988800000, 10413792000000).floor();
        final instant = kj.Instant.ofEpochMilli(millis)!;
        final zoned = instant.atZone(zones.java(zone))!;
        java = kj.JewishCalendar.new3(zoned);
        final javaLocal = zoned.toLocalDate()!;
        final javaDate = CivilDate(javaLocal.year, javaLocal.monthValue, javaLocal.dayOfMonth);
        javaLocal.release();
        zoned.release();
        instant.release();
        final location = zones.dartFromJava(zone, millis - 3 * _day, millis + 3 * _day);
        final zonedDart = tz.TZDateTime.fromMillisecondsSinceEpoch(location, millis);
        dart = kd.JewishCalendar.fromDateTime(zonedDart);
        input = 'instant=${iso(millis)} zone=$zone javaLocal=$javaDate dartLocal=${zonedDart.toIso8601String()}';
      case 'setGregorianDate':
        final date = randomGregorian(rng);
        final localDate = kj.LocalDate.of$1(date.year, date.month, date.day)!;
        java = kj.JewishCalendar.new2()..gregorianDate$1 = localDate;
        localDate.release();
        dart = kd.JewishCalendar()..setGregorianDate(date.year, date.month, date.day);
        input = 'gregorian=$date';
      case 'setDate':
        final date = randomGregorian(rng);
        final localDate = kj.LocalDate.of$1(date.year, date.month, date.day)!;
        java = kj.JewishCalendar.new2()..gregorianDate$1 = localDate;
        localDate.release();
        dart = kd.JewishCalendar()..setDate(DateTime.utc(date.year, date.month, date.day));
        input = 'gregorian=$date';
      default:
        final date = randomJewish(rng);
        java = kj.JewishCalendar.new1(date.year, date.month, date.day);
        dart = kd.JewishCalendar.initDate(date.year, date.month, date.day);
        input = 'jewish=$date';
    }
    applyFlags(rng, java, dart);
    return (CalendarPair(java, dart, '$id random path=$path $input ${flags(dart)}'), path);
  }

  void compareDate(Report report, String prefix, String input, kj.JewishDate java, kd.JewishDate dart) {
    report.exact('$prefix.getJewishYear', input, attempt(() => java.jewishYear), attempt(() => dart.getJewishYear()));
    report.exact(
        '$prefix.getJewishMonth', input, attempt(() => java.jewishMonth), attempt(() => dart.getJewishMonth()));
    report.exact('$prefix.getJewishDayOfMonth', input, attempt(() => java.jewishDayOfMonth),
        attempt(() => dart.getJewishDayOfMonth()));
    report.exact('$prefix.getLocalDate / getGregorian*', input, attempt(() {
      final local = java.localDate!;
      final text = CivilDate(local.year, local.monthValue, local.dayOfMonth).toString();
      local.release();
      return text;
    }),
        attempt(() =>
            CivilDate(dart.getGregorianYear(), dart.getGregorianMonth(), dart.getGregorianDayOfMonth()).toString()));
    report.exact('$prefix.getDayOfWeek', input, attempt(() => java.dayOfWeek), attempt(() => dart.getDayOfWeek()));
    report.exact('$prefix.getAbsDate', input, attempt(() => java.absDate), attempt(() => dart.getAbsDate()));
  }

  void compareCalendar(Report report, String prefix, CalendarPair pair) {
    final java = pair.java;
    final dart = pair.dart;
    final input = pair.describe;
    compareDate(report, prefix, input, java, dart);
    report.exact('$prefix.isJewishLeapYear', input, attempt(() => java.isJewishLeapYear$1),
        attempt(() => dart.isJewishLeapYear()));
    report.exact('$prefix.getDaysInJewishYear', input, attempt(() => java.daysInJewishYear),
        attempt(() => dart.getDaysInJewishYear()));
    report.exact('$prefix.getDaysInJewishMonth', input, attempt(() => java.daysInJewishMonth),
        attempt(() => dart.getDaysInJewishMonth()));
    report.exact(
        '$prefix.isCheshvanLong', input, attempt(() => java.isCheshvanLong), attempt(() => dart.isCheshvanLong()));
    report.exact(
        '$prefix.isKislevShort', input, attempt(() => java.isKislevShort), attempt(() => dart.isKislevShort()));
    report.exact('$prefix.getCheshvanKislevKviah', input, attempt(() => java.cheshvanKislevKviah),
        attempt(() => dart.getCheshvanKislevKviah()));
    report.exact('$prefix.getDaysSinceStartOfJewishYear', input, attempt(() => java.daysSinceStartOfJewishYear),
        attempt(() => dart.getDaysSinceStartOfJewishYear()));
    report.exact('$prefix.getChalakimSinceMoladTohu', input, attempt(() => java.chalakimSinceMoladTohu),
        attempt(() => dart.getChalakimSinceMoladTohu().toInt()));
    report.exact(
        '$prefix.toString', input, attempt(() => javaString(java.toString$1())), attempt(() => dart.toString()));
    report.exact('$prefix.getMoladHours', input, attempt(() => java.moladHours), attempt(() => dart.getMoladHours()));
    report.exact(
        '$prefix.getMoladMinutes', input, attempt(() => java.moladMinutes), attempt(() => dart.getMoladMinutes()));
    report.exact(
        '$prefix.getMoladChalakim', input, attempt(() => java.moladChalakim), attempt(() => dart.getMoladChalakim()));
    for (final (name, javaGetter, dartGetter) in calendarChecks) {
      report.exact('$prefix.$name', input, attempt(() => javaGetter(java)), attempt(() => dartGetter(dart)));
    }
    for (final (name, javaGetter, dartGetter) in calendarInstants) {
      report.instant('$prefix.$name', input, attempt(() => javaMillis(javaGetter(java))),
          attempt(() => dartGetter(dart)?.flooredMillis));
    }
  }

  void compareMolad(Report report, CalendarPair pair) {
    final input = pair.describe;
    final Got<kj.JewishDate?> javaMolad = attempt(() => pair.java.molad);
    final Got<kd.JewishDate> dartMolad = attempt(() => pair.dart.getMolad());
    if (javaMolad is! Value<kj.JewishDate?> || dartMolad is! Value<kd.JewishDate>) {
      report.exact<Object?>('calendar.getMolad', input, javaMolad, dartMolad);
      return;
    }
    final java = javaMolad.value!;
    final dart = dartMolad.value;
    compareDate(report, 'calendar.getMolad', input, java, dart);
    report.exact('calendar.getMolad.getMoladHours', input, attempt(() => java.moladHours),
        attempt(() => dart.getMoladHours()));
    report.exact('calendar.getMolad.getMoladMinutes', input, attempt(() => java.moladMinutes),
        attempt(() => dart.getMoladMinutes()));
    report.exact('calendar.getMolad.getMoladChalakim', input, attempt(() => java.moladChalakim),
        attempt(() => dart.getMoladChalakim()));
    java.release();
  }

  void compareDafYomi(Random rng, Report report, CalendarPair pair, String path) {
    final input = pair.describe;
    final useStatic = chance(rng, 0.5);
    report.exact(
        'calendar.getDafYomiBavli[$path]',
        input,
        orThrows(() {
          final daf = useStatic ? kj.YomiCalculator.getDafYomiBavli(pair.java) : pair.java.dafYomiBavli;
          if (daf == null) return null;
          final text =
              '${daf.masechtaNumber}:${daf.daf} ${javaString(daf.masechtaTransliterated)} ${javaString(daf.masechta)}';
          daf.release();
          return text;
        }),
        orThrows(() {
          final daf = useStatic ? kd.YomiCalculator.getDafYomiBavli(pair.dart) : pair.dart.getDafYomiBavli();
          return '${daf.getMasechtaNumber()}:${daf.getDaf()} ${daf.getMasechtaTransliterated()} ${daf.getMasechta()}';
        }));
    report.exact(
        'calendar.getDafYomiYerushalmi',
        input,
        orThrows(() {
          final daf =
              useStatic ? kj.YerushalmiYomiCalculator.getDafYomiYerushalmi(pair.java) : pair.java.dafYomiYerushalmi;
          if (daf == null) return null;
          final text = '${daf.masechtaNumber}:${daf.daf} '
              '${javaString(daf.yerushalmiMasechtaTransliterated)} ${javaString(daf.yerushalmiMasechta)}';
          daf.release();
          return text;
        }),
        orThrows(() {
          final daf = useStatic
              ? kd.YerushalmiYomiCalculator.getDafYomiYerushalmi(pair.dart)
              : pair.dart.getDafYomiYerushalmi();
          if (daf == null) return null;
          return '${daf.getMasechtaNumber()}:${daf.getDaf()} '
              '${daf.getYerushlmiMasechtaTransliterated()} ${daf.getYerushalmiMasechta()}';
        }));
  }

  void compareArithmetic(Random rng, Report report, String id) {
    final start = randomJewish(rng);
    final java = kj.JewishCalendar.new1(start.year, start.month, start.day);
    final dart = kd.JewishCalendar.initDate(start.year, start.month, start.day);
    final operations = between(rng, 1, 3);
    var input = '$id arithmetic start=$start';
    for (var step = 0; step < operations; step++) {
      final op = pick(rng, _arithmeticOperations);
      final small = chance(rng, 0.5);
      final amount = chance(rng, 0.03)
          ? 0
          : switch (op) {
              'plusDays' || 'minusDays' => small ? between(rng, 1, 3) : between(rng, 1, 40000),
              'plusMonths' || 'minusMonths' => small ? between(rng, 1, 3) : between(rng, 1, 400),
              _ => small ? between(rng, 1, 3) : between(rng, 1, 300),
            };
      final adarAleph = chance(rng, 0.5);
      final before = '$input state=${dart.getJewishYear()}-${dart.getJewishMonth()}-${dart.getJewishDayOfMonth()}';
      final String detail;
      final Got<void> javaResult;
      final Got<void> dartResult;
      switch (op) {
        case 'plusDays':
          detail = '$op($amount)';
          javaResult = attempt(() => java.plusDays(amount));
          dartResult = attempt(() => dart.plusDays(amount));
        case 'minusDays':
          detail = '$op($amount)';
          javaResult = attempt(() => java.minusDays(amount));
          dartResult = attempt(() => dart.minusDays(amount));
        case 'plusMonths':
          detail = '$op($amount)';
          javaResult = attempt(() => java.plusMonths(amount));
          dartResult = attempt(() => dart.plusMonths(amount));
        case 'minusMonths':
          detail = '$op($amount)';
          javaResult = attempt(() => java.minusMonths(amount));
          dartResult = attempt(() => dart.minusMonths(amount));
        case 'plusYears':
          detail = '$op($amount, adarAleph=$adarAleph)';
          javaResult = attempt(() => java.plusYears(amount, adarAleph));
          dartResult = attempt(() => dart.plusYears(amount, adarAleph));
        case 'minusYears':
          detail = '$op($amount, adarAleph=$adarAleph)';
          javaResult = attempt(() => java.minusYears(amount, adarAleph));
          dartResult = attempt(() => dart.minusYears(amount, adarAleph));
        case 'setJewishYear':
          final year = small ? dart.getJewishYear() + between(rng, -2, 2) : between(rng, 3762, 13000);
          detail = '$op($year)';
          javaResult = attempt(() => java.jewishYear = year);
          dartResult = attempt(() => dart.setJewishYear(year));
        case 'setJewishMonth':
          final month = between(rng, 1, 13);
          detail = '$op($month)';
          javaResult = attempt(() => java.jewishMonth = month);
          dartResult = attempt(() => dart.setJewishMonth(month));
        case 'setJewishDayOfMonth':
          final day = chance(rng, 0.4) ? pick(rng, const [29, 30]) : between(rng, 1, 30);
          detail = '$op($day)';
          javaResult = attempt(() => java.jewishDayOfMonth = day);
          dartResult = attempt(() => dart.setJewishDayOfMonth(day));
        case 'setJewishDate':
          final date = randomJewish(rng);
          detail = '$op($date)';
          javaResult = attempt(() => java.setJewishDate(date.year, date.month, date.day));
          dartResult = attempt(() => dart.setJewishDate(date.year, date.month, date.day));
        default:
          final date = randomGregorian(rng);
          detail = '$op($date)';
          javaResult = attempt(() {
            final local = kj.LocalDate.of$1(date.year, date.month, date.day)!;
            java.gregorianDate$1 = local;
            local.release();
          });
          dartResult = attempt(() => dart.setGregorianDate(date.year, date.month, date.day));
      }
      input = '$input -> $detail';
      final check = 'calendar.arithmetic.$op';
      if (javaResult is Threw<void> && dartResult is Threw<void>) {
        report.record(check, Outcome.same, input, '');
        break;
      }
      if (javaResult is Threw<void>) {
        report.record(check, Outcome.throwsInJava, before, '$detail java: ${javaResult.summary}');
        break;
      }
      if (dartResult is Threw<void>) {
        report.record(check, Outcome.throwsInDart, before, '$detail dart: ${dartResult.summary}');
        break;
      }
      final javaState = '${java.jewishYear}-${java.jewishMonth}-${java.jewishDayOfMonth} abs=${java.absDate} '
          'dow=${java.dayOfWeek}';
      final dartState = '${dart.getJewishYear()}-${dart.getJewishMonth()}-${dart.getJewishDayOfMonth()} '
          'abs=${dart.getAbsDate()} dow=${dart.getDayOfWeek()}';
      final javaGregorian = attempt(() {
        final local = java.localDate!;
        final text = CivilDate(local.year, local.monthValue, local.dayOfMonth).toString();
        local.release();
        return text;
      });
      final dartGregorian =
          CivilDate(dart.getGregorianYear(), dart.getGregorianMonth(), dart.getGregorianDayOfMonth()).toString();
      final javaFull = '$javaState ${javaGregorian is Value<String> ? javaGregorian.value : 'gregorian threw'}';
      final dartFull = '$dartState $dartGregorian';
      if (javaFull != dartFull) {
        report.record(check, Outcome.differs, before, '$detail java $javaFull | dart $dartFull');
        break;
      }
      report.record(check, Outcome.same, input, '');
      if (step == operations - 1) {
        final israel = chance(rng, 0.5);
        final modern = chance(rng, 0.5);
        java
          ..inIsrael = israel
          ..useModernHolidays = modern;
        dart
          ..inIsrael = israel
          ..setUseModernHolidays(modern);
        compareCalendar(report, 'calendar.afterArithmetic', CalendarPair(java, dart, '$input inIsrael=$israel modern=$modern'));
      }
    }
    java.release();
  }

  void compareMoladConstructor(Random rng, Report report, String id) {
    final year = chance(rng, 0.7) ? between(rng, 5660, 6060) : between(rng, 3762, 12990);
    final probe = kj.JewishDate.new$1(year, kd.JewishDate.TISHREI, 1);
    final base = probe.chalakimSinceMoladTohu;
    probe.release();
    final chalakim = base + rng.nextInt(765433 * 13);
    final input = '$id molad chalakim=$chalakim';
    final Got<kj.JewishDate> java = attempt(() => kj.JewishDate(chalakim));
    final Got<kd.JewishDate> dart = attempt(() => kd.JewishDate.fromMolad(chalakim.toDouble()));
    if (java is! Value<kj.JewishDate> || dart is! Value<kd.JewishDate>) {
      report.exact<Object?>('calendar.JewishDate(molad)', input, java, dart);
      return;
    }
    final javaDate = java.value;
    final dartDate = dart.value;
    compareDate(report, 'calendar.JewishDate(molad)', input, javaDate, dartDate);
    final javaClone = javaDate.clone() as kj.JewishDate;
    final dartClone = dartDate.clone();
    compareDate(report, 'calendar.JewishDate(molad).clone', input, javaClone, dartClone);
    report.exact('calendar.JewishDate(molad).clone molad time', input,
        attempt(() => '${javaClone.moladHours}:${javaClone.moladMinutes}:${javaClone.moladChalakim}'),
        attempt(() => '${dartClone.getMoladHours()}:${dartClone.getMoladMinutes()}:${dartClone.getMoladChalakim()}'));
    javaClone.release();
    report.exact('calendar.JewishDate(molad).getMoladHours', input, attempt(() => javaDate.moladHours),
        attempt(() => dartDate.getMoladHours()));
    report.exact('calendar.JewishDate(molad).getMoladMinutes', input, attempt(() => javaDate.moladMinutes),
        attempt(() => dartDate.getMoladMinutes()));
    report.exact('calendar.JewishDate(molad).getMoladChalakim', input, attempt(() => javaDate.moladChalakim),
        attempt(() => dartDate.getMoladChalakim()));
    final javaMolad = javaDate.molad!;
    final dartMolad = dartDate.getMolad();
    compareDate(report, 'calendar.JewishDate(molad).getMolad', input, javaMolad, dartMolad);
    report.exact('calendar.JewishDate(molad).getMolad.getMoladHours', input, attempt(() => javaMolad.moladHours),
        attempt(() => dartMolad.getMoladHours()));
    javaMolad.release();
    final target = randomJewish(rng);
    final hours = chance(rng, 0.9) ? between(rng, 0, 23) : between(rng, -1, 25);
    final minutes = chance(rng, 0.9) ? between(rng, 0, 59) : between(rng, -1, 61);
    final parts = chance(rng, 0.9) ? between(rng, 0, 17) : between(rng, -1, 19);
    final six = chance(rng, 0.5);
    final setInput = '$input then setJewishDate($target${six ? ', $hours, $minutes, $parts' : ''})';
    report.exact(
        'calendar.setJewishDate${six ? '(y,m,d,h,m,c)' : '(y,m,d)'} molad fields',
        setInput,
        orThrows(() {
          six
              ? javaDate.setJewishDate$1(target.year, target.month, target.day, hours, minutes, parts)
              : javaDate.setJewishDate(target.year, target.month, target.day);
          return '${javaDate.jewishYear}-${javaDate.jewishMonth}-${javaDate.jewishDayOfMonth} '
              '${javaDate.moladHours}:${javaDate.moladMinutes}:${javaDate.moladChalakim}';
        }),
        orThrows(() {
          six
              ? dartDate.setJewishDate(target.year, target.month, target.day, hours, minutes, parts)
              : dartDate.setJewishDate(target.year, target.month, target.day);
          return '${dartDate.getJewishYear()}-${dartDate.getJewishMonth()}-${dartDate.getJewishDayOfMonth()} '
              '${dartDate.getMoladHours()}:${dartDate.getMoladMinutes()}:${dartDate.getMoladChalakim()}';
        }));
    javaDate.release();
  }

  void compareStatics(Random rng, Report report, String id) {
    final year = chance(rng, 0.7) ? between(rng, 5660, 6060) : between(rng, 3762, 13000);
    final input = '$id statics year=$year';
    report.exact('calendar.getJewishCalendarElapsedDays(year)', input,
        attempt(() => kj.JewishDate.getJewishCalendarElapsedDays(year)),
        attempt(() => kd.JewishDate.getJewishCalendarElapsedDays(year)));
    final dart = kd.JewishCalendar.initDate(year, kd.JewishDate.TISHREI, 1);
    report.exact('calendar.isJewishLeapYear(year)', input, attempt(() => kj.JewishDate.isJewishLeapYear(year)),
        attempt(() => dart.isJewishLeapYear()));
    report.exact('calendar.getDaysInJewishYear(year)', input, attempt(() => kj.JewishDate.getDaysInJewishYear(year)),
        attempt(() => dart.getDaysInJewishYear()));
  }

  void compareInvalid(Random rng, Report report, String id) {
    final epoch = chance(rng, 0.15);
    final year = epoch ? 3761 : chance(rng, 0.8) ? between(rng, 5700, 5800) : between(rng, 3755, 3765);
    final month = epoch ? pick(rng, const [7, 8, 9, 10, 10, 10, 11]) : between(rng, 0, 14);
    final day = epoch
        ? between(rng, 15, 20)
        : chance(rng, 0.5)
            ? pick(rng, const [0, 29, 30, 31])
            : between(rng, 1, 30);
    final input = '$id jewishDateValidation jewish=$year-$month-$day';
    report.exact('calendar.JewishCalendar(y,m,d) validation', input, orThrows(() {
      final java = kj.JewishCalendar.new1(year, month, day);
      final text = '${java.jewishYear}-${java.jewishMonth}-${java.jewishDayOfMonth}';
      java.release();
      return text;
    }), orThrows(() {
      final dart = kd.JewishCalendar.initDate(year, month, day);
      return '${dart.getJewishYear()}-${dart.getJewishMonth()}-${dart.getJewishDayOfMonth()}';
    }));
  }

  void compareOrdering(Random rng, Report report, String id) {
    final first = randomJewish(rng);
    final second = chance(rng, 0.3) ? first : randomJewish(rng);
    final israelFirst = chance(rng, 0.5);
    final israelSecond = chance(rng, 0.5);
    final input = '$id ordering $first inIsrael=$israelFirst vs $second inIsrael=$israelSecond';
    final javaFirst = kj.JewishCalendar.new$5(first.year, first.month, first.day, israelFirst);
    final javaSecond = kj.JewishCalendar.new$5(second.year, second.month, second.day, israelSecond);
    final dartFirst = kd.JewishCalendar.initDate(first.year, first.month, first.day, inIsrael: israelFirst);
    final dartSecond = kd.JewishCalendar.initDate(second.year, second.month, second.day, inIsrael: israelSecond);
    report.exact('calendar.compareTo', input, attempt(() => javaFirst.compareTo(javaSecond).sign),
        attempt(() => dartFirst.compareTo(dartSecond).sign));
    report.exact(
        'calendar.equals', input, attempt(() => javaFirst.equals(javaSecond)), attempt(() => dartFirst == dartSecond));
    javaFirst.release();
    javaSecond.release();
  }
}
