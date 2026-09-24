import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:args/args.dart';
import 'package:kosher_dart/kosher_dart.dart';

const List<String> bavli = [
  'Berachos',
  'Shabbos',
  'Eruvin',
  'Pesachim',
  'Shekalim',
  'Yoma',
  'Sukkah',
  'Beitzah',
  'RoshHashanah',
  'Taanis',
  'Megillah',
  'MoedKatan',
  'Chagigah',
  'Yevamos',
  'Kesubos',
  'Nedarim',
  'Nazir',
  'Sotah',
  'Gitin',
  'Kiddushin',
  'BavaKamma',
  'BavaMetzia',
  'BavaBasra',
  'Sanhedrin',
  'Makkos',
  'Shevuos',
  'AvodahZarah',
  'Horiyos',
  'Zevachim',
  'Menachos',
  'Chullin',
  'Bechoros',
  'Arachin',
  'Temurah',
  'Kerisos',
  'Meilah',
  'Kinnim',
  'Tamid',
  'Midos',
  'Niddah',
];

const List<String> yerushalmi = [
  'Berachos',
  'Peah',
  'Demai',
  'Kilayim',
  'Sheviis',
  'Terumos',
  'Maasros',
  'MaaserSheni',
  'Chalah',
  'Orlah',
  'Bikurim',
  'Shabbos',
  'Eruvin',
  'Pesachim',
  'Beitzah',
  'RoshHashanah',
  'Yoma',
  'Sukkah',
  'Taanis',
  'Shekalim',
  'Megillah',
  'Chagigah',
  'MoedKatan',
  'Yevamos',
  'Kesubos',
  'Sotah',
  'Nedarim',
  'Nazir',
  'Gitin',
  'Kiddushin',
  'BavaKamma',
  'BavaMetzia',
  'BavaBasra',
  'Shevuos',
  'Makkos',
  'Sanhedrin',
  'AvodahZarah',
  'Horiyos',
  'Niddah',
];

const List<String> mishnaic = [
  'Berachos',
  'Peah',
  'Demai',
  'Kilayim',
  'Sheviis',
  'Terumos',
  'Maasros',
  'MaaserSheni',
  'Chalah',
  'Orlah',
  'Bikurim',
  'Shabbos',
  'Eruvin',
  'Pesachim',
  'Shekalim',
  'Yoma',
  'Sukkah',
  'Beitzah',
  'RoshHashanah',
  'Taanis',
  'Megillah',
  'MoedKatan',
  'Chagigah',
  'Yevamos',
  'Kesubos',
  'Nedarim',
  'Nazir',
  'Sotah',
  'Gitin',
  'Kiddushin',
  'BavaKamma',
  'BavaMetzia',
  'BavaBasra',
  'Sanhedrin',
  'Makkos',
  'Shevuos',
  'Eduyos',
  'AvodahZarah',
  'Avos',
  'Horiyos',
  'Zevachim',
  'Menachos',
  'Chullin',
  'Bechoros',
  'Arachin',
  'Temurah',
  'Kerisos',
  'Meilah',
  'Tamid',
  'Midos',
  'Kinnim',
  'Keilim',
  'Ohalos',
  'Negaim',
  'Parah',
  'Taharos',
  'Mikvaos',
  'Niddah',
  'Machshirin',
  'Zavim',
  'TevulYom',
  'Yadayim',
  'Uktzin',
];

const List<String> limudim = [
  'dafYomiBavli',
  'dafYomiYerushalmi',
  'dafHashavuaBavli',
  'amudYomiBavliDirshu',
  'mishnaYomis',
  'pirkeiAvosIsrael',
  'pirkeiAvosDiaspora',
  'tehillimMonthly',
];

const String none = 'none';
const String error = 'error';

final DateTime dafYomiBavliStart = DateTime.utc(1923, 9, 11);
final DateTime dafYomiYerushalmiStart = DateTime.utc(1980, 2, 2);

class Input {
  Input(this.date, Random random, this.source)
    : inIsrael = random.nextBool(),
      build = random.nextInt(5);

  final DateTime date;
  final bool inIsrael;
  final int build;
  final String source;

  String get iso => isoOf(date);
}

String isoOf(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime parseIso(String text) {
  final List<int> parts = text.split('-').map(int.parse).toList();
  return DateTime.utc(parts[0], parts[1], parts[2]);
}

class Tally {
  int compared = 0;
  int agreedValue = 0;
  int agreedNone = 0;
  int agreedError = 0;
  final List<String> examples = [];
  int diffs = 0;
  String? lastDiff;
}

String rustDaf(Object? value) {
  if (value == null) return none;
  if (value is String) return value;
  final Map<String, dynamic> daf = value as Map<String, dynamic>;
  return '${daf['t']} ${daf['p']}';
}

String rustAmud(Object? value) {
  if (value == null) return none;
  if (value is String) return value;
  final Map<String, dynamic> amud = value as Map<String, dynamic>;
  return '${amud['t']} ${amud['p']} ${amud['s']}';
}

String rustMishnas(Object? value) {
  if (value == null) return none;
  if (value is String) return value;
  return (value as List<dynamic>)
      .map((dynamic entry) {
        final Map<String, dynamic> mishna = entry as Map<String, dynamic>;
        return '${mishna['t']} ${mishna['c']}:${mishna['m']}';
      })
      .join(', ');
}

String rustPirkeiAvos(Object? value) {
  if (value == null) return none;
  if (value is String) return value;
  return (value as List<dynamic>).join('-');
}

String rustTehillim(Object? value) {
  if (value == null) return none;
  if (value is String) return value;
  final Map<String, dynamic> unit = value as Map<String, dynamic>;
  return unit.containsKey('psalm')
      ? '${unit['psalm']}:${unit['startVerse']}-${unit['endVerse']}'
      : '${unit['start']}-${unit['end']}';
}

Map<String, String> rustValues(Map<String, dynamic> record) => {
  'dafYomiBavli': rustDaf(record['dafYomiBavli']),
  'dafYomiYerushalmi': rustDaf(record['dafYomiYerushalmi']),
  'dafHashavuaBavli': rustDaf(record['dafHashavuaBavli']),
  'amudYomiBavliDirshu': rustAmud(record['amudYomiBavliDirshu']),
  'mishnaYomis': rustMishnas(record['mishnaYomis']),
  'pirkeiAvosIsrael': rustPirkeiAvos(record['pirkeiAvosIsrael']),
  'pirkeiAvosDiaspora': rustPirkeiAvos(record['pirkeiAvosDiaspora']),
  'tehillimMonthly': rustTehillim(record['tehillimMonthly']),
};

String named(List<String> names, int index) =>
    index >= 0 && index < names.length ? names[index] : 'masechta#$index';

String guarded(
  String Function() compute, {
  DateTime? noneBefore,
  DateTime? date,
}) {
  try {
    return compute();
  } on ArgumentError {
    if (noneBefore != null && date!.isBefore(noneBefore)) {
      return none;
    }
    return error;
  } catch (_) {
    return error;
  }
}

String dartDaf(Daf? daf, List<String> names) => daf == null
    ? none
    : '${named(names, daf.getMasechtaNumber())} ${daf.getDaf()}';

String dartAmud(Amud? amud) => amud == null
    ? none
    : '${named(bavli, amud.getMasechtaNumber())} ${amud.getDaf()} '
          '${amud.getSide() == AmudSide.ALEPH ? 'Aleph' : 'Bet'}';

String dartMishna(Mishna mishna) =>
    '${named(mishnaic, mishna.getMasechtaNumber())} ${mishna.getChapter()}:${mishna.getMishna()}';

String dartMishnas(Mishnas? mishnas) => mishnas == null
    ? none
    : '${dartMishna(mishnas.first)}, ${dartMishna(mishnas.second)}';

String dartPirkeiAvos(PirkeiAvosUnit? unit) => unit == null
    ? none
    : unit.second == null
    ? '${unit.first}'
    : '${unit.first}-${unit.second}';

String dartTehillim(TehillimUnit unit) => unit.isPartialPsalm
    ? '${unit.psalm}:${unit.startVerse}-${unit.endVerse}'
    : '${unit.start}-${unit.end}';

JewishCalendar reused = JewishCalendar.fromJewishDate(5784, JewishDate.ADAR_II, 14);

JewishCalendar buildCalendar(int build, DateTime date) {
  switch (build) {
    case 0:
      return JewishCalendar.fromLocalDate(
        DateTime(date.year, date.month, date.day),
      );
    case 1:
      return JewishCalendar.fromZonedDateTime(date);
    case 2:
      return JewishCalendar()
        ..setGregorianDate(DateTime.utc(date.year, date.month, date.day));
    case 3:
      final JewishCalendar hebrew = JewishCalendar.fromLocalDate(date);
      return JewishCalendar.fromJewishDate(
        hebrew.getJewishYear(),
        hebrew.getJewishMonth(),
        hebrew.getJewishDayOfMonth(),
      );
    default:
      return reused..setGregorianDate(date);
  }
}

Map<String, String> dartValues(Input input) {
  final DateTime date = input.date;
  JewishCalendar calendarFor(bool inIsrael) =>
      buildCalendar(input.build, date)..setInIsrael(inIsrael);

  JewishCalendar? calendar;
  String? calendarError;
  try {
    calendar = calendarFor(input.inIsrael);
  } catch (e) {
    calendarError = error;
  }
  if (calendar == null) {
    return {for (final String limud in limudim) limud: calendarError!};
  }
  final JewishCalendar c = calendar;

  return {
    'dafYomiBavli': guarded(
      () => dartDaf(c.getDafYomiBavli(), bavli),
      noneBefore: dafYomiBavliStart,
      date: date,
    ),
    'dafYomiYerushalmi': guarded(
      () => dartDaf(c.getDafYomiYerushalmi(), yerushalmi),
      noneBefore: dafYomiYerushalmiStart,
      date: date,
    ),
    'dafHashavuaBavli': guarded(() => dartDaf(DafHashavuaBavliCalculator.getDafHashavuaBavli(c), bavli)),
    'amudYomiBavliDirshu': guarded(() => dartAmud(AmudYomiBavliDirshuCalculator.getAmudYomiBavliDirshu(c))),
    'mishnaYomis': guarded(() => dartMishnas(MishnaYomisCalculator.getMishnaYomis(c))),
    'tehillimMonthly': guarded(() => dartTehillim(TehillimMonthlyCalculator.getTehillimMonthly(c))),
    'pirkeiAvosIsrael': guarded(
      () => dartPirkeiAvos(PirkeiAvosCalculator.getPirkeiAvos(calendarFor(true))),
    ),
    'pirkeiAvosDiaspora': guarded(
      () => dartPirkeiAvos(PirkeiAvosCalculator.getPirkeiAvos(calendarFor(false))),
    ),
  };
}

List<Input> buildInputs({
  required DateTime sweepFrom,
  required DateTime sweepTo,
  required DateTime randomFrom,
  required DateTime randomTo,
  required int randomCount,
  required int edgeDays,
  required int seed,
}) {
  final Random random = Random(seed);
  final List<Input> inputs = [];
  void sweep(DateTime from, DateTime to, String source) {
    for (
      DateTime day = from;
      !day.isAfter(to);
      day = day.add(const Duration(days: 1))
    ) {
      inputs.add(Input(day, random, source));
    }
  }

  sweep(sweepFrom, sweepTo, 'sweep');
  sweep(randomFrom, randomFrom.add(Duration(days: edgeDays)), 'edge');
  sweep(randomTo.subtract(Duration(days: edgeDays)), randomTo, 'edge');
  final int span = randomTo.difference(randomFrom).inDays;
  for (int i = 0; i < randomCount; i++) {
    final int offset = random.nextInt(span + 1);
    inputs.add(Input(randomFrom.add(Duration(days: offset)), random, 'random'));
  }
  return inputs;
}

Future<List<Map<String, dynamic>>> runGolden(
  String golden,
  List<Input> inputs,
) async {
  final Process process = await Process.start(golden, const []);
  final Future<List<String>> lines = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .toList();
  final Future<String> errors = process.stderr.transform(utf8.decoder).join();
  final StringBuffer buffer = StringBuffer();
  for (final Input input in inputs) {
    buffer.writeln(input.iso);
  }
  process.stdin.write(buffer.toString());
  await process.stdin.close();
  final int exitCode = await process.exitCode;
  final List<String> output = await lines;
  if (exitCode != 0) {
    throw StateError('$golden exited $exitCode: ${await errors}');
  }
  stdout.write(await errors);
  return output
      .map((String line) => jsonDecode(line) as Map<String, dynamic>)
      .toList();
}

Future<List<Map<String, String>>> runChunk(List<Input> part) =>
    Isolate.run(() => part.map(dartValues).toList());

Future<List<Map<String, String>>> computeDart(List<Input> inputs) async {
  final int workers = max(1, Platform.numberOfProcessors);
  final int chunk = (inputs.length / workers).ceil();
  final List<Future<List<Map<String, String>>>> jobs = [];
  for (int start = 0; start < inputs.length; start += chunk) {
    jobs.add(
      runChunk(inputs.sublist(start, min(start + chunk, inputs.length))),
    );
  }
  return [
    for (final List<Map<String, String>> part in await Future.wait(jobs))
      ...part,
  ];
}

String defaultGolden() {
  final String script = File.fromUri(Platform.script).parent.parent.path;
  final String exe = Platform.isWindows ? '.exe' : '';
  return '$script${Platform.pathSeparator}rust${Platform.pathSeparator}target'
      '${Platform.pathSeparator}release${Platform.pathSeparator}limudim_golden$exe';
}

Future<void> main(List<String> arguments) async {
  final ArgParser parser = ArgParser()
    ..addOption('seed', help: 'Seed for the random dates; random when omitted.')
    ..addOption('random', defaultsTo: '20000', help: 'Random dates to draw.')
    ..addOption('sweep-from', defaultsTo: '1900-01-01')
    ..addOption('sweep-to', defaultsTo: '2300-12-31')
    ..addOption('random-from', defaultsTo: '0001-01-01')
    ..addOption('random-to', defaultsTo: '6235-12-31')
    ..addOption(
      'edge-days',
      defaultsTo: '1500',
      help: 'Days swept at each end of the random range.',
    )
    ..addOption('examples', defaultsTo: '8')
    ..addOption('golden', help: 'Path to the limudim_golden binary.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults options = parser.parse(arguments);
  if (options.flag('help')) {
    print(parser.usage);
    return;
  }

  final int seed = options.option('seed') != null
      ? int.parse(options.option('seed')!)
      : Random().nextInt(1 << 32);
  final int exampleLimit = int.parse(options.option('examples')!);
  final String golden = options.option('golden') ?? defaultGolden();
  if (!File(golden).existsSync()) {
    stderr.writeln(
      'No kosher-rust binary at $golden; build it with '
      'cargo build --release in rust/.',
    );
    exit(2);
  }

  final List<Input> inputs = buildInputs(
    sweepFrom: parseIso(options.option('sweep-from')!),
    sweepTo: parseIso(options.option('sweep-to')!),
    randomFrom: parseIso(options.option('random-from')!),
    randomTo: parseIso(options.option('random-to')!),
    randomCount: int.parse(options.option('random')!),
    edgeDays: int.parse(options.option('edge-days')!),
    seed: seed,
  );
  print('seed $seed, ${inputs.length} dates');

  final Stopwatch clock = Stopwatch()..start();
  final Future<List<Map<String, dynamic>>> rustRun = runGolden(golden, inputs);
  final List<Map<String, String>> dartResults = await computeDart(inputs);
  final List<Map<String, dynamic>> records = await rustRun;
  print('both computed in ${clock.elapsed.inSeconds}s');
  if (records.length != inputs.length) {
    stderr.writeln(
      'kosher-rust answered ${records.length} of ${inputs.length} dates',
    );
    exit(1);
  }

  final Map<String, Tally> tallies = {
    for (final String limud in limudim) limud: Tally(),
  };
  for (int i = 0; i < inputs.length; i++) {
    final Input input = inputs[i];
    final Map<String, dynamic> record = records[i];
    if (record['g'] != input.iso || record['unparsed'] == true) {
      stderr.writeln(
        'kosher-rust line $i is ${record['g']}, expected ${input.iso}',
      );
      exit(1);
    }
    final Map<String, String> rust = rustValues(record);
    final Map<String, String> dart = dartResults[i];
    for (final String limud in limudim) {
      final Tally tally = tallies[limud]!;
      tally.compared++;
      final String want = rust[limud]!;
      final String got = dart[limud]!;
      if (want == got) {
        if (want == none) {
          tally.agreedNone++;
        } else if (want == error) {
          tally.agreedError++;
        } else {
          tally.agreedValue++;
        }
        continue;
      }
      tally.diffs++;
      final String line =
          '${input.iso} ${input.source} inIsrael=${input.inIsrael} build=${input.build} rust=$want dart=$got';
      tally.lastDiff = line;
      if (tally.examples.length < exampleLimit) {
        tally.examples.add(line);
      }
    }
  }

  int divergences = 0;
  for (final String limud in limudim) {
    final Tally tally = tallies[limud]!;
    divergences += tally.diffs;
    print(
      '${limud.padRight(20)} compared ${tally.compared}  value ${tally.agreedValue}  '
      'none ${tally.agreedNone}  both-error ${tally.agreedError}  diffs ${tally.diffs}',
    );
  }
  for (final String limud in limudim) {
    final Tally tally = tallies[limud]!;
    if (tally.diffs == 0) continue;
    print('\n$limud: ${tally.diffs} diffs');
    for (final String example in tally.examples) {
      print('  $example');
    }
    if (tally.diffs > tally.examples.length) {
      print('  last: ${tally.lastDiff}');
    }
  }
  exit(divergences == 0 ? 0 : 1);
}
