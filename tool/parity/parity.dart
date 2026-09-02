// Differential harness: compares kosher_dart against golden output dumped from
// kosher-rust (https://github.com/dickermoshe/kosher-rust).
//
// Usage: dart run tool/parity/parity.dart <goldens-dir> [--limit N] [--only prefix]

import 'dart:convert';
import 'dart:io';

import 'package:kosher_dart/kosher_dart.dart';

import 'zman_dispatch.dart';

const int _minute = 60 * 1000;
const int _hour = 60 * _minute;

class Divergence {
  Divergence(this.check);

  final String check;
  int count = 0;
  final List<String> samples = [];

  void add(String sample) {
    count++;
    if (samples.length < 5) samples.add(sample);
  }
}

class Report {
  final Map<String, Divergence> _checks = {};
  int recordsCompared = 0;
  int valuesCompared = 0;

  void fail(String check, String sample) {
    _checks.putIfAbsent(check, () => Divergence(check)).add(sample);
  }

  List<Divergence> get sorted {
    final list = _checks.values.toList();
    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }
}

/// Hebrew month codes as ICU spells them, mapped to kosher_dart's month numbers.
int jewishMonthFromCode(String code, bool leapYear) {
  switch (code) {
    case 'M01':
      return JewishDate.TISHREI;
    case 'M02':
      return JewishDate.CHESHVAN;
    case 'M03':
      return JewishDate.KISLEV;
    case 'M04':
      return JewishDate.TEVES;
    case 'M05':
      return JewishDate.SHEVAT;
    case 'M05L':
      return JewishDate.ADAR;
    case 'M06':
      return leapYear ? JewishDate.ADAR_II : JewishDate.ADAR;
    case 'M07':
      return JewishDate.NISSAN;
    case 'M08':
      return JewishDate.IYAR;
    case 'M09':
      return JewishDate.SIVAN;
    case 'M10':
      return JewishDate.TAMMUZ;
    case 'M11':
      return JewishDate.AV;
    case 'M12':
      return JewishDate.ELUL;
    default:
      throw ArgumentError('unknown Hebrew month code $code');
  }
}

/// kosher-rust `Holiday` variants that map onto a kosher_dart yom tov index.
/// Rosh Chodesh is deliberately absent: getYomTovIndex never returns it.
const Map<String, int> holidayIndex = {
  'ErevPesach': JewishCalendar.EREV_PESACH,
  'Pesach': JewishCalendar.PESACH,
  'CholHamoedPesach': JewishCalendar.CHOL_HAMOED_PESACH,
  'PesachSheni': JewishCalendar.PESACH_SHENI,
  'ErevShavuos': JewishCalendar.EREV_SHAVUOS,
  'Shavuos': JewishCalendar.SHAVUOS,
  'SeventeenthOfTammuz': JewishCalendar.SEVENTEEN_OF_TAMMUZ,
  'TishahBav': JewishCalendar.TISHA_BEAV,
  'TuBav': JewishCalendar.TU_BEAV,
  'ErevRoshHashana': JewishCalendar.EREV_ROSH_HASHANA,
  'RoshHashana': JewishCalendar.ROSH_HASHANA,
  'FastOfGedalyah': JewishCalendar.FAST_OF_GEDALYAH,
  'ErevYomKippur': JewishCalendar.EREV_YOM_KIPPUR,
  'YomKippur': JewishCalendar.YOM_KIPPUR,
  'ErevSuccos': JewishCalendar.EREV_SUCCOS,
  'Succos': JewishCalendar.SUCCOS,
  'CholHamoedSuccos': JewishCalendar.CHOL_HAMOED_SUCCOS,
  'HoshanaRabbah': JewishCalendar.HOSHANA_RABBA,
  'SheminiAtzeres': JewishCalendar.SHEMINI_ATZERES,
  'SimchasTorah': JewishCalendar.SIMCHAS_TORAH,
  'Chanukah': JewishCalendar.CHANUKAH,
  'TenthOfTeves': JewishCalendar.TENTH_OF_TEVES,
  'TuBshvat': JewishCalendar.TU_BESHVAT,
  'FastOfEsther': JewishCalendar.FAST_OF_ESTHER,
  'Purim': JewishCalendar.PURIM,
  'ShushanPurim': JewishCalendar.SHUSHAN_PURIM,
  'PurimKatan': JewishCalendar.PURIM_KATAN,
  'YomHaShoah': JewishCalendar.YOM_HASHOAH,
  'YomHazikaron': JewishCalendar.YOM_HAZIKARON,
  'YomHaatzmaut': JewishCalendar.YOM_HAATZMAUT,
  'YomYerushalayim': JewishCalendar.YOM_YERUSHALAYIM,
  'LagBomer': JewishCalendar.LAG_BAOMER,
  'ShushanPurimKatan': JewishCalendar.SHUSHAN_PURIM_KATAN,
  'IsruChag': JewishCalendar.ISRU_CHAG,
};

/// kosher-rust `Parsha` variants whose kosher_dart name is not the plain
/// upper-snake-case of the Rust one.
const Map<String, String> parshaAlias = {
  'HaAzinu': 'HAAZINU',
  'VezosHabracha': 'VZOS_HABERACHA',
  'Shekalim': 'SHKALIM',
  'Parah': 'PARA',
};

/// Special shabbosim kosher-rust knows about and kosher_dart has no enum for.
const Set<String> parshaUnsupported = {
  'Shuva',
  'Shira',
  'Hagadol',
  'Chazon',
  'Nachamu',
};

String upperSnake(String camel) {
  final buffer = StringBuffer();
  for (var i = 0; i < camel.length; i++) {
    final ch = camel[i];
    if (i > 0 && ch.toUpperCase() == ch && ch.toLowerCase() != ch) buffer.write('_');
    buffer.write(ch.toUpperCase());
  }
  return buffer.toString();
}

Parsha? parshaFor(String? rustName) {
  if (rustName == null) return Parsha.NONE;
  if (parshaUnsupported.contains(rustName)) return null;
  final dartName = parshaAlias[rustName] ?? upperSnake(rustName);
  for (final parsha in Parsha.values) {
    if (parsha.name == dartName) return parsha;
  }
  throw ArgumentError('no kosher_dart Parsha for $rustName (looked for $dartName)');
}

/// kosher-rust and kosher_dart transliterate a few tractates differently in ways
/// that collapsing doubled letters does not reconcile.
const Map<String, String> tractateAlias = {
  'kesuvos': 'kesubos',
  'horayos': 'horiyos',
  'roshashanah': 'roshashana',
};

/// Zmanim answered on a different contract from kosher-rust's, so a difference here is
/// not a finding.
const Set<String> deliberatelyDifferent = {
  // This fork returns candle lighting only on a day that has it, and lights
  // before shkia when yom tov starts on a Friday.
  'getCandleLighting',
  // kosher-rust refuses these off erev Pesach; kosher_dart, like KosherJava,
  // calculates the time on any day and leaves the day to the caller.
  'getSofZmanAchilasChametzGRA',
  'getSofZmanAchilasChametzMGA72Minutes',
  'getSofZmanAchilasChametzMGA16Point1Degrees',
  'getSofZmanAchilasChametzBaalHatanya',
  'getSofZmanBiurChametzGRA',
  'getSofZmanBiurChametzMGA72Minutes',
  'getSofZmanBiurChametzMGA16Point1Degrees',
  'getSofZmanBiurChametzBaalHatanya',
  // kosher_dart answers these only when the moment falls in the current day, and
  // pulls it to alos or tzais when it lands in daylight; kosher-rust returns the
  // molad based moment itself.
  'getTchilasZmanKidushLevana3Days',
  'getTchilasZmanKidushLevana7Days',
  'getSofZmanKidushLevana15Days',
  'getSofZmanKidushLevanaBetweenMoldos',
};

/// kosher-rust keeps nanoseconds where DateTime keeps milliseconds, so the last
/// millisecond of a zman is not a divergence.
const int toleranceMillis = 2;

String normalizeTractate(String name) {
  final letters = name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  final buffer = StringBuffer();
  for (var i = 0; i < letters.length; i++) {
    if (i == 0 || letters[i] != letters[i - 1]) buffer.write(letters[i]);
  }
  final squashed = buffer.toString();
  return tractateAlias[squashed] ?? squashed;
}

void compareHolidayView(
  Report report,
  String prefix,
  Map<String, dynamic> view,
  JewishCalendar calendar,
  String date,
) {
  final holidays = (view['hol'] as List).cast<String>();

  if (calendar.isAssurBemelacha() != view['assur']) {
    report.fail('$prefix.assurBemelacha', '$date rust=${view['assur']} dart=${calendar.isAssurBemelacha()}');
  }
  if (calendar.hasCandleLighting() != view['cl']) {
    report.fail('$prefix.hasCandleLighting', '$date rust=${view['cl']} dart=${calendar.hasCandleLighting()}');
  }
  if (calendar.isAseresYemeiTeshuva() != view['ayt']) {
    report.fail(
        '$prefix.aseresYemeiTeshuva', '$date rust=${view['ayt']} dart=${calendar.isAseresYemeiTeshuva()}');
  }

  final todaysParsha = parshaFor(view['tp'] as String?);
  if (todaysParsha != null && calendar.getParshah() != todaysParsha) {
    report.fail('$prefix.parsha', '$date rust=${view['tp']} dart=${calendar.getParshah().name}');
  }

  final specialParsha = parshaFor(view['sp'] as String?);
  if (specialParsha != null && calendar.getSpecialShabbos() != specialParsha) {
    report.fail('$prefix.specialShabbos', '$date rust=${view['sp']} dart=${calendar.getSpecialShabbos().name}');
  }

  final indexable = <int>{};
  for (final holiday in holidays) {
    final base = holiday.contains('(') ? holiday.substring(0, holiday.indexOf('(')) : holiday;
    final index = holidayIndex[base];
    if (index != null) indexable.add(index);
  }

  final dartIndex = calendar.getYomTovIndex();
  if (indexable.isEmpty) {
    if (dartIndex != -1) {
      report.fail('$prefix.yomTovIndex.extra', '$date rust=[] dart=$dartIndex');
    }
  } else if (!indexable.contains(dartIndex)) {
    report.fail('$prefix.yomTovIndex', '$date rust=$indexable dart=$dartIndex holidays=$holidays');
  }

  int? argOf(String holiday) {
    final open = holiday.indexOf('(');
    if (open < 0) return null;
    return int.parse(holiday.substring(open + 1, holiday.length - 1));
  }

  final omer = holidays.firstWhere((h) => h.startsWith('CountOfTheOmer'), orElse: () => '');
  final expectedOmer = omer.isEmpty ? 0 : argOf(omer)!;
  final actualOmer = calendar.getDayOfOmer() < 0 ? 0 : calendar.getDayOfOmer();
  if (actualOmer != expectedOmer) {
    report.fail('$prefix.dayOfOmer', '$date rust=$expectedOmer dart=$actualOmer');
  }

  final chanukah = holidays.firstWhere((h) => h.startsWith('Chanukah'), orElse: () => '');
  final expectedChanukah = chanukah.isEmpty ? 0 : argOf(chanukah)!;
  final actualChanukah = calendar.getDayOfChanukah() < 0 ? 0 : calendar.getDayOfChanukah();
  if (actualChanukah != expectedChanukah) {
    report.fail('$prefix.dayOfChanukah', '$date rust=$expectedChanukah dart=$actualChanukah');
  }

  final predicates = <String, bool Function()>{
    'BirchasHachamah': calendar.isBirkasHachamah,
    'MacharHachodesh': calendar.isMacharChodesh,
    'ShabbosMevarchim': calendar.isShabbosMevorchim,
    'YomKippurKatan': calendar.isYomKippurKatan,
    'Behab': calendar.isBeHaB,
    'FastOfTheFirstborn': calendar.isTaanisBechoros,
    'IsruChag': calendar.isIsruChag,
    'RoshChodesh': calendar.isRoshChodesh,
  };
  predicates.forEach((holiday, predicate) {
    final expected = holidays.contains(holiday);
    final actual = predicate();
    if (expected != actual) {
      report.fail('$prefix.is$holiday', '$date rust=$expected dart=$actual');
    }
  });
}

void compareCalendarRecord(Report report, Map<String, dynamic> record) {
  final parts = (record['g'] as String).split('-');
  final gregorian = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

  final calendar = JewishCalendar.fromDateTime(gregorian);
  final date = record['g'] as String;

  final leap = record['leap'] as bool;
  final expectedMonth = jewishMonthFromCode(record['hmCode'] as String, leap);

  if (calendar.getJewishYear() != record['hy'] ||
      calendar.getJewishMonth() != expectedMonth ||
      calendar.getJewishDayOfMonth() != record['hd']) {
    report.fail(
      'jewishDate',
      '$date rust=${record['hy']}/${record['hmCode']}/${record['hd']} '
          'dart=${calendar.getJewishYear()}/${calendar.getJewishMonth()}/${calendar.getJewishDayOfMonth()}',
    );
    return;
  }

  if (calendar.getDayOfWeek() != record['dow']) {
    report.fail('dayOfWeek', '$date rust=${record['dow']} dart=${calendar.getDayOfWeek()}');
  }
  if (calendar.isJewishLeapYear() != leap) {
    report.fail('isJewishLeapYear', '$date rust=$leap dart=${calendar.isJewishLeapYear()}');
  }
  if (record['diy'] != null && calendar.getDaysInJewishYear() != record['diy']) {
    report.fail('daysInJewishYear', '$date rust=${record['diy']} dart=${calendar.getDaysInJewishYear()}');
  }
  if (record['dim'] != null && calendar.getDaysInJewishMonth() != record['dim']) {
    report.fail('daysInJewishMonth', '$date rust=${record['dim']} dart=${calendar.getDaysInJewishMonth()}');
  }

  const kviahValues = {
    'Chaserim': JewishDate.CHASERIM,
    'Kesidran': JewishDate.KESIDRAN,
    'Shelaimim': JewishDate.SHELAIMIM,
  };
  final expectedKviah = kviahValues[record['kviah']];
  if (expectedKviah != null && calendar.getCheshvanKislevKviah() != expectedKviah) {
    report.fail('kviah', '$date rust=${record['kviah']} dart=${calendar.getCheshvanKislevKviah()}');
  }

  calendar.inIsrael = true;
  calendar.setUseModernHolidays(false);
  compareHolidayView(report, 'israel', record['il'] as Map<String, dynamic>, calendar, date);

  calendar.inIsrael = false;
  compareHolidayView(report, 'diaspora', record['ch'] as Map<String, dynamic>, calendar, date);

  calendar.inIsrael = true;
  calendar.setUseModernHolidays(true);
  compareHolidayView(report, 'israelModern', record['ilModern'] as Map<String, dynamic>, calendar, date);
  calendar.setUseModernHolidays(false);

  final molad = record['molad'];
  if (molad != null && (record['hd'] as int) <= 2) {
    final expected = JewishDate.initDate(
      jewishYear: calendar.getJewishYear(),
      jewishMonth: calendar.getJewishMonth(),
      jewishDayOfMonth: calendar.getJewishDayOfMonth(),
    ).getMolad();
    final actualSeconds = expected.getMoladChalakim() * 10 / 3;
    final mismatch = expected.getGregorianYear() != molad['y'] ||
        expected.getGregorianMonth() != molad['mon'] ||
        expected.getGregorianDayOfMonth() != molad['d'] ||
        expected.getMoladHours() != molad['h'] ||
        expected.getMoladMinutes() != molad['mi'] ||
        actualSeconds.floor() != molad['s'];
    if (mismatch) {
      report.fail(
        'molad',
        '$date rust=${molad['y']}-${molad['mon']}-${molad['d']} ${molad['h']}:${molad['mi']}:${molad['s']} '
            'dart=${expected.getGregorianYear()}-${expected.getGregorianMonth()}-${expected.getGregorianDayOfMonth()} '
            '${expected.getMoladHours()}:${expected.getMoladMinutes()}:${actualSeconds.floor()}',
      );
    }
  }

  compareDaf(report, 'dafYomiBavli', record['dafYomiBavli'], date, () {
    final daf = calendar.getDafYomiBavli();
    return [daf.getMasechtaTransliterated(), daf.getDaf()];
  });
  compareDaf(report, 'dafYomiYerushalmi', record['dafYomiYerushalmi'], date, () {
    final daf = calendar.getDafYomiYerushalmi();
    return [daf.getYerushlmiMasechtaTransliterated(), daf.getDaf()];
  });

  report.recordsCompared++;
}

void compareDaf(
  Report report,
  String check,
  dynamic expected,
  String date,
  List<dynamic> Function() read,
) {
  List<dynamic>? actual;
  try {
    actual = read();
  } catch (_) {
    actual = null;
  }

  if (expected == null) {
    // kosher_dart has no "before the cycle started" answer for Yerushalmi; it
    // returns tractate 39 (no daf) rather than throwing, so treat that as null.
    if (actual != null && actual[1] != 0) {
      report.fail('$check.extra', '$date rust=null dart=${actual[0]} ${actual[1]}');
    }
    return;
  }

  if (actual == null) {
    report.fail('$check.missing', '$date rust=${expected['t']} ${expected['p']} dart=<threw>');
    return;
  }

  final sameTractate =
      normalizeTractate(actual[0] as String) == normalizeTractate(expected['t'] as String);
  if (!sameTractate || actual[1] != expected['p']) {
    report.fail(check, '$date rust=${expected['t']} ${expected['p']} dart=${actual[0]} ${actual[1]}');
  }
}

void compareZmanRecord(Report report, Map<String, dynamic> record) {
  final config = record['cfg'] as String;
  if (config == 'halfday') return; // kosher_dart has no half-day chatzos switch

  final parts = (record['g'] as String).split('-');
  final gregorian = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

  final location = GeoLocation.setLocation(
    record['loc'] as String,
    (record['lat'] as num).toDouble(),
    (record['lon'] as num).toDouble(),
    gregorian,
    (record['elev'] as num).toDouble(),
  );

  final calendar = ComplexZmanimCalendar.intGeoLocation(location);
  calendar.setUseElevation(config == 'elevation');

  final times = record['t'] as Map<String, dynamic>;
  final label = '${record['loc']}/$config/${record['g']}';

  times.forEach((method, expected) {
    if (deliberatelyDifferent.contains(method)) return;
    final getter = zmanDispatch[method];
    if (getter == null) return;

    DateTime? actual;
    try {
      actual = getter(calendar);
    } catch (error) {
      report.fail('$method.threw', '$label $error');
      return;
    }

    report.valuesCompared++;

    if (expected is String) {
      if (actual != null) {
        report.fail('$method.rustError', '$label rust=$expected dart=${actual.toUtc()}');
      }
      return;
    }

    if (actual == null) {
      report.fail('$method.dartNull', '$label rust=${DateTime.fromMillisecondsSinceEpoch(expected as int, isUtc: true)}');
      return;
    }

    final diff = (actual.millisecondsSinceEpoch - (expected as int)).abs();
    if (diff <= toleranceMillis) return;

    final bucket = diff <= 1000
        ? 'ms'
        : diff <= _minute
            ? 'sub-minute'
            : diff <= _hour
                ? 'sub-hour'
                : 'over-hour';
    report.fail(
      '$method.$bucket',
      '$label rust=${DateTime.fromMillisecondsSinceEpoch(expected, isUtc: true)} '
          'dart=${actual.toUtc()} diff=${diff}ms',
    );
  });

  report.recordsCompared++;
}

Future<void> readNdjson(File file, void Function(Map<String, dynamic>) onRecord, int limit) async {
  var seen = 0;
  final lines = file
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final line in lines) {
    if (line.trim().isEmpty) continue;
    onRecord(jsonDecode(line) as Map<String, dynamic>);
    seen++;
    if (limit > 0 && seen >= limit) break;
  }
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/parity/parity.dart <goldens-dir> [--limit N] [--only calendar|zmanim]');
    exit(64);
  }

  final directory = Directory(args.first);
  var limit = 0;
  String? only;
  for (var i = 1; i < args.length; i++) {
    if (args[i] == '--limit') limit = int.parse(args[++i]);
    if (args[i] == '--only') only = args[++i];
  }

  final report = Report();

  if (only == null || only == 'calendar') {
    await readNdjson(
      File('${directory.path}/calendar.ndjson'),
      (record) => compareCalendarRecord(report, record),
      limit,
    );
  }
  if (only == null || only == 'zmanim') {
    await readNdjson(
      File('${directory.path}/zmanim.ndjson'),
      (record) => compareZmanRecord(report, record),
      limit,
    );
  }

  final buffer = StringBuffer();
  buffer.writeln('records compared: ${report.recordsCompared}');
  buffer.writeln('zman values compared: ${report.valuesCompared}');
  buffer.writeln('unimplemented zmanim: ${unimplementedZmanim.length}');
  buffer.writeln('');

  for (final divergence in report.sorted) {
    buffer.writeln('${divergence.count.toString().padLeft(7)}  ${divergence.check}');
    for (final sample in divergence.samples) {
      buffer.writeln('         $sample');
    }
  }

  stdout.write(buffer.toString());
}
