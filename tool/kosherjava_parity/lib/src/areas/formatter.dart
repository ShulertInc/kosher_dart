import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;

import '../area.dart';
import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';
import 'tefila_calendar.dart';

const hebrewNumberEdges = [0, 1, 9, 10, 11, 14, 15, 16, 17, 19, 20, 99, 100, 115, 116, 270, 275, 300, 400, 401, 500, 515,
  516, 700, 999, 1000, 1001, 1015, 5000, 5015, 5016, 5020, 5780, 5790, 5800, 9000, 9999];
const hebrewNumberInvalid = [-1, -1000, 10000, 12345, 2147483647];

class FormatterFlags {
  FormatterFlags(this.hebrewFormat, this.useGershGershayim, this.longWeekFormat, this.useFinalFormLetters,
      this.useLongHebrewYears,
      {this.omerPrefix, this.shabbosName, this.customMonths = false, this.customHolidays = false});

  factory FormatterFlags.random(Random rng) => FormatterFlags(
      chance(rng, 0.5), chance(rng, 0.7), chance(rng, 0.7), chance(rng, 0.5), chance(rng, 0.5),
      omerPrefix: chance(rng, 0.2) ? pick(rng, const ['ל', '', 'ביום ']) : null,
      shabbosName: chance(rng, 0.2) ? pick(rng, const ['Shabbat', 'Sabbath', 'Sh']) : null,
      customMonths: chance(rng, 0.15),
      customHolidays: chance(rng, 0.15));

  final bool hebrewFormat;
  final bool useGershGershayim;
  final bool longWeekFormat;
  final bool useFinalFormLetters;
  final bool useLongHebrewYears;
  final String? omerPrefix;
  final String? shabbosName;
  final bool customMonths;
  final bool customHolidays;

  String get mode => hebrewFormat ? 'hebrew' : 'transliterated';

  @override
  String toString() => 'hebrew=$hebrewFormat gersh=$useGershGershayim longWeek=$longWeekFormat '
      'finalForms=$useFinalFormLetters longYears=$useLongHebrewYears'
      '${omerPrefix == null ? '' : ' omerPrefix="$omerPrefix"'}${shabbosName == null ? '' : ' shabbos=$shabbosName'}'
      '${customMonths ? ' customMonths' : ''}${customHolidays ? ' customHolidays' : ''}';

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
      formatter.transliteratedMonthList = javaArray(marked(defaults.transliteratedMonths));
      formatter.hebrewMonthList = javaArray(marked(defaults.hebrewMonths));
    }
    if (customHolidays) formatter.transliteratedHolidayList = javaArray(marked(defaults.transliteratedHolidays));
    return formatter;
  }

  kd.HebrewDateFormatter dart() {
    final formatter = kd.HebrewDateFormatter()
      ..hebrewFormat = hebrewFormat
      ..useGershGershayim = useGershGershayim
      ..longWeekFormat = longWeekFormat
      ..useFinalFormLetters = useFinalFormLetters
      ..useLongHebrewYears = useLongHebrewYears;
    if (omerPrefix != null) formatter.hebrewOmerPrefix = omerPrefix!;
    if (shabbosName != null) formatter.transliteratedShabbosDayOfWeek = shabbosName!;
    if (customMonths) {
      formatter.transliteratedMonths = marked(formatter.transliteratedMonths);
      formatter.hebrewMonths = marked(formatter.hebrewMonths);
    }
    if (customHolidays) formatter.transliteratedHolidays = marked(formatter.transliteratedHolidays);
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
        parshah = rng.nextInt(kd.Parsha.values.length);

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
      'bavli=${bavli.$1}:${bavli.$2} yerushalmi=${yerushalmi.$1}:${yerushalmi.$2} parshah=${kd.Parsha.values[parshah].name}';
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

      final parshah = kd.Parsha.values[input.parshah];
      compareOrBothThrow(report, 'formatter.formatParshah(Parshah)[$mode]', describe,
          attempt(() => javaParshah(java, parshah.name)),
          attempt(() => (input.flags.hebrewFormat ? dart.hebrewParshaMap : dart.transliteratedParshaMap)[parshah]));

      if (input.day.agrees(report, name, describe)) {
        compareCalendar(report, describe, mode, input, java, dart);
      }
      java.release();
    }
  }

  String? javaParshah(kj.HebrewDateFormatter java, String name) {
    final key = name.toJString();
    final parshah = kj.JewishCalendar$Parshah.valueOf(key);
    key.release();
    final formatted = javaString(java.formatParshah$1(parshah));
    parshah?.release();
    return formatted;
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
      'formatParshah / formatParsha': ((c) => javaString(java.formatParshah(c)), (c) => dart.formatParsha(c)),
      'formatSpecialParshah / formatSpecialParsha': (
        (c) => javaString(java.formatSpecialParshah(c)),
        (c) => dart.formatSpecialParsha(c)
      ),
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
      for (var year = 3762; year <= 13760; year++) {
        if (hebrew) {
          compareOrBothThrow(report, 'formatter.sweep.getFormattedKviah', 'sweep kviahYear=$year',
              attempt(() => javaString(java.getFormattedKviah(year))), attempt(() => dart.getFormattedKviah(year)));
        }
      }
      final javaNames = javaEnumNames();
      for (final parshah in kd.Parsha.values) {
        compareOrBothThrow(report, 'formatter.sweep.formatParshah(Parshah)[$mode]', 'sweep parshah=${parshah.name}',
            attempt(() => javaParshah(java, parshah.name)),
            attempt(() => (hebrew ? dart.hebrewParshaMap : dart.transliteratedParshaMap)[parshah]));
      }
      report.exact('formatter.sweep.Parshah enum names', 'sweep', Value(javaNames),
          Value(kd.Parsha.values.map((parshah) => parshah.name).join('|')));
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
          attempt(() => dartDaf.getYerushlmiMasechtaTransliterated()));
      javaDaf.release();
    }

    final java = kj.HebrewDateFormatter();
    final dart = kd.HebrewDateFormatter();
    report.exact('formatter.sweep.default transliteratedMonths', 'sweep',
        attempt(() => javaStrings(java.transliteratedMonthList)), Value(dart.transliteratedMonths.join('|')));
    report.exact('formatter.sweep.default hebrewMonths', 'sweep', attempt(() => javaStrings(java.hebrewMonthList)),
        Value(dart.hebrewMonths.join('|')));
    report.exact('formatter.sweep.default transliteratedHolidays', 'sweep',
        attempt(() => javaStrings(java.transliteratedHolidayList)), Value(dart.transliteratedHolidays.join('|')));
    report.exact('formatter.sweep.default hebrewOmerPrefix', 'sweep', attempt(() => javaString(java.hebrewOmerPrefix)),
        Value(dart.hebrewOmerPrefix));
    report.exact('formatter.sweep.default transliteratedShabbosDayOfWeek', 'sweep',
        attempt(() => javaString(java.transliteratedShabbosDayOfWeek)), Value(dart.transliteratedShabbosDayOfWeek));
    report.exact('formatter.sweep.default flags', 'sweep',
        Value('${java.isHebrewFormat} ${java.isUseGershGershayim} ${java.isLongWeekFormat} '
            '${java.isUseFinalFormLetters} ${java.isUseLongHebrewYears}'),
        Value('${dart.hebrewFormat} ${dart.useGershGershayim} ${dart.longWeekFormat} '
            '${dart.useFinalFormLetters} ${dart.useLongHebrewYears}'));
    java.release();
    report.exact('formatter.sweep.Daf.getYerushalmiMasechtos', 'sweep',
        attempt(() => javaStrings(kj.Daf.yerushalmiMasechtos)),
        Value([for (var i = 0; i < 40; i++) kd.Daf(i, 0).getYerushalmiMasechta()].join('|')));
    report.exact('formatter.sweep.Daf.getYerushalmiMasechtosTransliterated', 'sweep',
        attempt(() => javaStrings(kj.Daf.yerushalmiMasechtosTransliterated)),
        Value([for (var i = 0; i < 40; i++) kd.Daf(i, 0).getYerushlmiMasechtaTransliterated()].join('|')));
  }

  String javaEnumNames() {
    final values = kj.JewishCalendar$Parshah.values()!;
    final names = [for (var i = 0; i < values.length; i++) values[i]!.toString()];
    values.release();
    return names.join('|');
  }
}
