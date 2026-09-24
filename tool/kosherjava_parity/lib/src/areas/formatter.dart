import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;

import '../area.dart';
import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';
import 'calendar.dart' show orThrows;
import 'tefila_calendar.dart';

const hebrewNumberEdges = [0, 1, 9, 10, 11, 14, 15, 16, 17, 19, 20, 99, 100, 115, 116, 270, 275, 300, 400, 401, 500, 515,
  516, 700, 999, 1000, 1001, 1015, 5000, 5015, 5016, 5020, 5780, 5790, 5800, 9000, 9999];
const hebrewNumberInvalid = [-1, -1000, 10000, 12345, 2147483647];

class _EnumMaps {
  final enumMap = JClass.forName('java/util/EnumMap');
  late final _copy = enumMap.constructorId('(Ljava/util/EnumMap;)V');
  late final _put = enumMap.instanceMethodId('put', '(Ljava/lang/Enum;Ljava/lang/Object;)Ljava/lang/Object;');
  late final _get = enumMap.instanceMethodId('get', '(Ljava/lang/Object;)Ljava/lang/Object;');

  kj.EnumMap copy(kj.EnumMap source) => _copy.call(enumMap, [source]).as(kj.EnumMap.type, releaseOriginal: true);

  void put(kj.EnumMap map, JObject key, String value) {
    final text = value.toJString();
    _put.call(map, JObject.type, [key, text]).release();
    text.release();
  }

  String? get(kj.EnumMap map, JObject key) {
    final value = _get.callNullable(map, JObject.type, [key]);
    if (value == null) return null;
    return javaString(value.as(JString.type, releaseOriginal: true));
  }
}

final _enumMaps = _EnumMaps();

kj.JewishCalendar$Parshah javaParshahValue(String name) {
  final key = name.toJString();
  final parshah = kj.JewishCalendar$Parshah.valueOf(key)!;
  key.release();
  return parshah;
}

class FormatterFlags {
  FormatterFlags(this.hebrewFormat, this.useGershGershayim, this.longWeekFormat, this.useFinalFormLetters,
      this.useLongHebrewYears,
      {this.omerPrefix,
      this.shabbosName,
      this.customMonths = false,
      this.customHolidays = false,
      this.customParshiyos = false});

  factory FormatterFlags.random(Random rng) => FormatterFlags(
      chance(rng, 0.5), chance(rng, 0.7), chance(rng, 0.7), chance(rng, 0.5), chance(rng, 0.5),
      omerPrefix: chance(rng, 0.2) ? pick(rng, const ['ל', '', 'ביום ']) : null,
      shabbosName: chance(rng, 0.2) ? pick(rng, const ['Shabbat', 'Sabbath', 'Sh']) : null,
      customMonths: chance(rng, 0.15),
      customHolidays: chance(rng, 0.15),
      customParshiyos: chance(rng, 0.15));

  final bool hebrewFormat;
  final bool useGershGershayim;
  final bool longWeekFormat;
  final bool useFinalFormLetters;
  final bool useLongHebrewYears;
  final String? omerPrefix;
  final String? shabbosName;
  final bool customMonths;
  final bool customHolidays;
  final bool customParshiyos;

  String get mode => hebrewFormat ? 'hebrew' : 'transliterated';

  @override
  String toString() => 'hebrew=$hebrewFormat gersh=$useGershGershayim longWeek=$longWeekFormat '
      'finalForms=$useFinalFormLetters longYears=$useLongHebrewYears'
      '${omerPrefix == null ? '' : ' omerPrefix="$omerPrefix"'}${shabbosName == null ? '' : ' shabbos=$shabbosName'}'
      '${customMonths ? ' customMonths' : ''}${customHolidays ? ' customHolidays' : ''}'
      '${customParshiyos ? ' customParshiyos' : ''}';

  static List<String> marked(List<String> names) => [for (final name in names) '$name°'];

  static JArray<JString?> javaArray(List<String> names) => JArray.of<JString?>(JString.type, [
        for (final name in names) name.toJString(),
      ]);

  kj.HebrewDateFormatter java() {
    final formatter = kj.HebrewDateFormatter()
      ..hebrewFormat = hebrewFormat
      ..useGershGershayim = useGershGershayim
      ..longWeekFormat = longWeekFormat
      ..useFinalFormLetters = useFinalFormLetters
      ..useLongHebrewYears = useLongHebrewYears;
    if (omerPrefix != null) formatter.hebrewOmerPrefix = omerPrefix!.toJString();
    if (shabbosName != null) formatter.transliteratedShabbosDayOfWeek = shabbosName!.toJString();
    final defaults = kd.HebrewDateFormatter();
    if (customMonths) {
      formatter.transliteratedMonthList = javaArray(marked(defaults.getTransliteratedMonthList()));
      formatter.hebrewMonthList = javaArray(marked(defaults.getHebrewMonthList()));
    }
    if (customHolidays) formatter.transliteratedHolidayList = javaArray(marked(defaults.getTransliteratedHolidayList()));
    if (customParshiyos) {
      final source = formatter.transliteratedParshiyosList!;
      final map = _enumMaps.copy(source);
      source.release();
      for (final entry in defaults.getTransliteratedParshiyosList().entries) {
        final key = javaParshahValue(entry.key.name);
        _enumMaps.put(map, key, '${entry.value}°');
        key.release();
      }
      formatter.transliteratedParshiyosList = map;
      map.release();
    }
    return formatter;
  }

  kd.HebrewDateFormatter dart() {
    final formatter = kd.HebrewDateFormatter()
      ..setHebrewFormat(hebrewFormat)
      ..setUseGershGershayim(useGershGershayim)
      ..setLongWeekFormat(longWeekFormat)
      ..setUseFinalFormLetters(useFinalFormLetters)
      ..setUseLongHebrewYears(useLongHebrewYears);
    if (omerPrefix != null) formatter.setHebrewOmerPrefix(omerPrefix!);
    if (shabbosName != null) formatter.setTransliteratedShabbosDayOfWeek(shabbosName!);
    if (customMonths) {
      formatter.setTransliteratedMonthList(marked(formatter.getTransliteratedMonthList()));
      formatter.setHebrewMonthList(marked(formatter.getHebrewMonthList()));
    }
    if (customHolidays) formatter.setTransliteratedHolidayList(marked(formatter.getTransliteratedHolidayList()));
    if (customParshiyos) {
      formatter.setTransliteratedParshiyosList({
        for (final entry in formatter.getTransliteratedParshiyosList().entries) entry.key: '${entry.value}°',
      });
    }
    return formatter;
  }
}

class FormatterInput {
  FormatterInput(Random rng)
      : day = CalendarDay.random(rng),
        flags = FormatterFlags.random(rng),
        number = _randomNumber(rng),
        kviahYear = chance(rng, 0.7) ? between(rng, 5660, 6060) : between(rng, 3762, 13700),
        bavli = (between(rng, 0, 39), between(rng, 2, 180)),
        yerushalmi = (between(rng, 0, 38), between(rng, 1, 110)),
        parshah = rng.nextInt(kd.Parshah.values.length);

  static int _randomNumber(Random rng) {
    final roll = rng.nextDouble();
    if (roll < 0.1) return pick(rng, hebrewNumberInvalid);
    if (roll < 0.3) return pick(rng, hebrewNumberEdges);
    return between(rng, 0, 9999);
  }

  final CalendarDay day;
  final FormatterFlags flags;
  final int number;
  final int kviahYear;
  final (int, int) bavli;
  final (int, int) yerushalmi;
  final int parshah;

  String describe(String id) => '$id $day $flags number=$number kviahYear=$kviahYear '
      'bavli=${bavli.$1}:${bavli.$2} yerushalmi=${yerushalmi.$1}:${yerushalmi.$2} parshah=${kd.Parshah.values[parshah].name}';
}

class FormatterArea extends Area {
  FormatterArea(super.zones);

  @override
  String get name => 'formatter';

  @override
  void run(int seed, Iterable<int> indexes, Report report) {
    if (indexes.contains(0)) sweep(report);
    for (final index in indexes) {
      final input = FormatterInput(caseRandom(seed, name, index));
      final describe = input.describe('formatter#$index seed=$seed');
      final java = input.flags.java();
      final dart = input.flags.dart();
      final mode = input.flags.mode;

      compareSettings(report, 'formatter', describe, java, dart);
      compareOrBothThrow(report, 'formatter.formatHebrewNumber', describe,
          attempt(() => javaString(java.formatHebrewNumber(input.number))),
          attempt(() => dart.formatHebrewNumber(input.number)));
      compareOrBothThrow(report, 'formatter.getFormattedKviah', describe,
          attempt(() => javaString(java.getFormattedKviah(input.kviahYear))),
          attempt(() => dart.getFormattedKviah(input.kviahYear)));

      final javaBavli = kj.Daf(input.bavli.$1, input.bavli.$2);
      compareOrBothThrow(report, 'formatter.formatDafYomiBavli[$mode]', describe,
          attempt(() => javaString(java.formatDafYomiBavli(javaBavli))),
          attempt(() => dart.formatDafYomiBavli(kd.Daf(input.bavli.$1, input.bavli.$2))));
      javaBavli.release();
      final javaYerushalmi = kj.Daf(input.yerushalmi.$1, input.yerushalmi.$2);
      compareOrBothThrow(report, 'formatter.formatDafYomiYerushalmi[$mode]', describe,
          attempt(() => javaString(java.formatDafYomiYerushalmi(javaYerushalmi))),
          attempt(() => dart.formatDafYomiYerushalmi(kd.Daf(input.yerushalmi.$1, input.yerushalmi.$2))));
      javaYerushalmi.release();

      final parshah = kd.Parshah.values[input.parshah];
      compareOrBothThrow(report, 'formatter.formatParshah(Parshah)[$mode]', describe,
          attempt(() => javaParshah(java, parshah.name)), attempt(() => dart.formatParshah(parshah)));
      compareOrBothThrow(report, 'formatter.getTransliteratedParshiyosList', describe,
          attempt(() => javaParshiyosEntry(java, parshah.name)),
          attempt(() => dart.getTransliteratedParshiyosList()[parshah]));

      if (input.day.agrees(report, name, describe)) {
        compareCalendar(report, describe, mode, input, java, dart);
      }
      java.release();
    }
  }

  String? javaParshah(kj.HebrewDateFormatter java, String name) {
    final parshah = javaParshahValue(name);
    final formatted = javaString(java.formatParshah$1(parshah));
    parshah.release();
    return formatted;
  }

  String? javaParshiyosEntry(kj.HebrewDateFormatter java, String name) {
    final map = java.transliteratedParshiyosList!;
    final parshah = javaParshahValue(name);
    final value = _enumMaps.get(map, parshah);
    parshah.release();
    map.release();
    return value;
  }

  void compareSettings(
      Report report, String prefix, String describe, kj.HebrewDateFormatter java, kd.HebrewDateFormatter dart) {
    report.exact('$prefix.isHebrewFormat', describe, attempt(() => java.isHebrewFormat),
        attempt(() => dart.isHebrewFormat()));
    report.exact('$prefix.isUseGershGershayim', describe, attempt(() => java.isUseGershGershayim),
        attempt(() => dart.isUseGershGershayim()));
    report.exact('$prefix.isLongWeekFormat', describe, attempt(() => java.isLongWeekFormat),
        attempt(() => dart.isLongWeekFormat()));
    report.exact('$prefix.isUseFinalFormLetters', describe, attempt(() => java.isUseFinalFormLetters),
        attempt(() => dart.isUseFinalFormLetters()));
    report.exact('$prefix.isUseLongHebrewYears', describe, attempt(() => java.isUseLongHebrewYears),
        attempt(() => dart.isUseLongHebrewYears()));
    report.exact('$prefix.getHebrewOmerPrefix', describe, attempt(() => javaString(java.hebrewOmerPrefix)),
        attempt(() => dart.getHebrewOmerPrefix()));
    report.exact('$prefix.getTransliteratedShabbosDayOfWeek', describe,
        attempt(() => javaString(java.transliteratedShabbosDayOfWeek)),
        attempt(() => dart.getTransliteratedShabbosDayOfWeek()));
    report.exact('$prefix.getTransliteratedMonthList', describe,
        attempt(() => javaStrings(java.transliteratedMonthList)),
        attempt(() => dart.getTransliteratedMonthList().join('|')));
    report.exact('$prefix.getHebrewMonthList', describe, attempt(() => javaStrings(java.hebrewMonthList)),
        attempt(() => dart.getHebrewMonthList().join('|')));
    report.exact('$prefix.getTransliteratedHolidayList', describe,
        attempt(() => javaStrings(java.transliteratedHolidayList)),
        attempt(() => dart.getTransliteratedHolidayList().join('|')));
  }

  void compareCalendar(Report report, String describe, String mode, FormatterInput input, kj.HebrewDateFormatter java,
      kd.HebrewDateFormatter dart) {
    final checks = <String, (String? Function(kj.JewishCalendar), String? Function(kd.JewishCalendar))>{
      'format': ((c) => javaString(java.format(c)), (c) => dart.format(c)),
      'formatMonth': ((c) => javaString(java.formatMonth(c)), (c) => dart.formatMonth(c)),
      'formatDayOfWeek': ((c) => javaString(java.formatDayOfWeek(c)), (c) => dart.formatDayOfWeek(c)),
      'formatOmer': ((c) => javaString(java.formatOmer(c)), (c) => dart.formatOmer(c)),
      'formatYomTov': ((c) => javaString(java.formatYomTov(c)), (c) => dart.formatYomTov(c)),
      'formatRoshChodesh': ((c) => javaString(java.formatRoshChodesh(c)), (c) => dart.formatRoshChodesh(c)),
      'formatTekufaName': ((c) => javaString(java.formatTekufaName(c)), (c) => dart.formatTekufaName(c)),
      'formatParshah(JewishCalendar)': ((c) => javaString(java.formatParshah(c)), (c) => dart.formatParshah(c)),
      'formatSpecialParshah': ((c) => javaString(java.formatSpecialParshah(c)), (c) => dart.formatSpecialParshah(c)),
      'formatDafYomiBavli(getDafYomiBavli)': (
        (c) {
          final daf = c.dafYomiBavli;
          final formatted = javaString(java.formatDafYomiBavli(daf));
          daf?.release();
          return formatted;
        },
        (c) => dart.formatDafYomiBavli(c.getDafYomiBavli())
      ),
      'formatDafYomiYerushalmi(getDafYomiYerushalmi)': (
        (c) {
          final daf = c.dafYomiYerushalmi;
          final formatted = javaString(java.formatDafYomiYerushalmi(daf));
          daf?.release();
          return formatted;
        },
        (c) => dart.formatDafYomiYerushalmi(c.getDafYomiYerushalmi())
      ),
    };
    for (final MapEntry(key: check, value: (javaFormat, dartFormat)) in checks.entries) {
      final javaCalendar = input.day.java();
      final dartCalendar = input.day.dart();
      final before = input.day.stateOfDart(dartCalendar);
      compareOrBothThrow(report, 'formatter.$check[$mode]', describe, attempt(() => javaFormat(javaCalendar)),
          attempt(() => dartFormat(dartCalendar)));
      report.exact('formatter.$check leaves its calendar unchanged', describe, Value(before),
          attempt(() => input.day.stateOfDart(dartCalendar)));
      javaCalendar.release();
    }
  }

  void sweep(Report report) {
    for (var number = -3; number <= 10003; number++) {
      for (var variant = 0; variant < 8; variant++) {
        final flags = FormatterFlags(false, variant & 1 != 0, true, variant & 2 != 0, variant & 4 != 0);
        final java = flags.java();
        final describe = 'sweep number=$number $flags';
        compareOrBothThrow(report, 'formatter.sweep.formatHebrewNumber', describe,
            attempt(() => javaString(java.formatHebrewNumber(number))),
            attempt(() => flags.dart().formatHebrewNumber(number)));
        java.release();
      }
    }

    for (var hebrew in [false, true]) {
      final flags = FormatterFlags(hebrew, true, true, false, false);
      final java = flags.java();
      final dart = flags.dart();
      final mode = flags.mode;
      final javaDay = kj.JewishCalendar.new1(5660, kd.JewishDate.TISHREI, 1);
      final dartDay = kd.JewishCalendar.fromJewishDate(5660, kd.JewishDate.TISHREI, 1);
      for (var day = 0; day < 146100; day++) {
        compareOrBothThrow(report, 'formatter.sweep.formatTekufaName[$mode]', 'sweep ${dartDay.toString()}',
            attempt(() => javaString(java.formatTekufaName(javaDay))), attempt(() => dart.formatTekufaName(dartDay)));
        javaDay.plusDays(1);
        dartDay.plusDays(1);
      }
      javaDay.release();
      for (var year = 3762; year <= 13760; year++) {
        if (hebrew) {
          compareOrBothThrow(report, 'formatter.sweep.getFormattedKviah', 'sweep kviahYear=$year',
              attempt(() => javaString(java.getFormattedKviah(year))), attempt(() => dart.getFormattedKviah(year)));
        }
      }
      final javaNames = javaEnumNames();
      for (final parshah in kd.Parshah.values) {
        compareOrBothThrow(report, 'formatter.sweep.formatParshah(Parshah)[$mode]', 'sweep parshah=${parshah.name}',
            attempt(() => javaParshah(java, parshah.name)), attempt(() => dart.formatParshah(parshah)));
      }
      report.exact('formatter.sweep.Parshah enum names', 'sweep', Value(javaNames),
          Value(kd.Parshah.values.map((parshah) => parshah.name).join('|')));
      for (var daf = 0; daf <= 3; daf++) {
        for (var masechta = -1; masechta <= 41; masechta++) {
          final javaDaf = kj.Daf(masechta, daf);
          final describe = 'sweep masechta=$masechta daf=$daf';
          compareOrBothThrow(report, 'formatter.sweep.formatDafYomiBavli[$mode]', describe,
              attempt(() => javaString(java.formatDafYomiBavli(javaDaf))),
              attempt(() => dart.formatDafYomiBavli(kd.Daf(masechta, daf))));
          compareOrBothThrow(report, 'formatter.sweep.formatDafYomiYerushalmi${daf == 0 ? '(daf 0)' : ''}[$mode]', describe,
              attempt(() => javaString(java.formatDafYomiYerushalmi(javaDaf))),
              attempt(() => dart.formatDafYomiYerushalmi(kd.Daf(masechta, daf))));
          javaDaf.release();
        }
      }
      compareOrBothThrow(report, 'formatter.sweep.formatDafYomiYerushalmi(null)[$mode]', 'sweep null daf',
          attempt(() => javaString(java.formatDafYomiYerushalmi(null))), attempt(() => dart.formatDafYomiYerushalmi(null)));
      java.release();
    }

    for (var masechta = -1; masechta <= 41; masechta++) {
      final javaDaf = kj.Daf(masechta, 2);
      final dartDaf = kd.Daf(masechta, 2);
      final describe = 'sweep masechta=$masechta';
      compareOrBothThrow(report, 'formatter.sweep.Daf.getMasechta', describe,
          attempt(() => javaString(javaDaf.masechta)), attempt(() => dartDaf.getMasechta()));
      compareOrBothThrow(report, 'formatter.sweep.Daf.getMasechtaTransliterated', describe,
          attempt(() => javaString(javaDaf.masechtaTransliterated)), attempt(() => dartDaf.getMasechtaTransliterated()));
      compareOrBothThrow(report, 'formatter.sweep.Daf.getYerushalmiMasechta', describe,
          attempt(() => javaString(javaDaf.yerushalmiMasechta)), attempt(() => dartDaf.getYerushalmiMasechta()));
      compareOrBothThrow(report, 'formatter.sweep.Daf.getYerushalmiMasechtaTransliterated', describe,
          attempt(() => javaString(javaDaf.yerushalmiMasechtaTransliterated)),
          attempt(() => dartDaf.getYerushalmiMasechtaTransliterated()));
      javaDaf.release();
    }

    final java = kj.HebrewDateFormatter();
    final dart = kd.HebrewDateFormatter();
    compareSettings(report, 'formatter.sweep.default', 'defaults', java, dart);
    for (final length in const [0, 13, 14, 15]) {
      final names = [for (var i = 0; i < length; i++) 'm$i'];
      compareOrBothThrow(report, 'formatter.sweep.setHebrewMonthList(length $length)', 'sweep',
          orThrows(() {
            java.hebrewMonthList = FormatterFlags.javaArray(names);
            return javaStrings(java.hebrewMonthList);
          }), orThrows(() {
            dart.setHebrewMonthList(names);
            return dart.getHebrewMonthList().join('|');
          }));
      compareOrBothThrow(report, 'formatter.sweep.setTransliteratedMonthList(length $length)', 'sweep',
          orThrows(() {
            java.transliteratedMonthList = FormatterFlags.javaArray(names);
            return javaStrings(java.transliteratedMonthList);
          }), orThrows(() {
            dart.setTransliteratedMonthList(names);
            return dart.getTransliteratedMonthList().join('|');
          }));
    }
    java.release();
    report.exact('formatter.sweep.Daf.getYerushalmiMasechtos', 'sweep',
        attempt(() => javaStrings(kj.Daf.yerushalmiMasechtos)),
        Value(kd.Daf.getYerushalmiMasechtos().join('|')));
    report.exact('formatter.sweep.Daf.getYerushalmiMasechtosTransliterated', 'sweep',
        attempt(() => javaStrings(kj.Daf.yerushalmiMasechtosTransliterated)),
        Value(kd.Daf.getYerushalmiMasechtosTransliterated().join('|')));
  }

  String javaEnumNames() {
    final values = kj.JewishCalendar$Parshah.values()!;
    final names = [for (var i = 0; i < values.length; i++) values[i]!.toString()];
    values.release();
    return names.join('|');
  }
}
