import 'dart:convert';
import 'dart:io';

const areasByFile = {
  'lib/src/astronomical_calendar.dart': ['zmanim', 'calculators', 'zmanim-formatter'],
  'lib/src/zmanim_calendar.dart': ['zmanim', 'zmanim-formatter', 'calendar'],
  'lib/src/comprehensive_zmanim_calendar.dart': ['zmanim', 'zmanim-formatter'],
  'lib/src/util/noaa_calculator.dart': ['calculators', 'zmanim'],
  'lib/src/util/sun_times_calculator.dart': ['calculators', 'zmanim'],
  'lib/src/util/meeus_calculator.dart': ['calculators', 'zmanim'],
  'lib/src/util/spa_calculator.dart': ['calculators', 'zmanim'],
  'lib/src/util/vsop87_earth.dart': ['calculators'],
  'lib/src/util/astronomical_calculator.dart': ['calculators', 'zmanim'],
  'lib/src/util/solar_radius.dart': ['calculators', 'zmanim'],
  'lib/src/util/geo_location.dart': ['geo', 'calculators', 'zmanim', 'zmanim-formatter'],
  'lib/src/util/zmanim_formatter.dart': ['zmanim-formatter'],
  'lib/src/util/date_time_formatter.dart': ['zmanim-formatter'],
  'lib/src/util/java_double.dart': ['zmanim-formatter'],
  'lib/src/util/zman.dart': ['zmanim-formatter'],
  'lib/src/hebrewcalendar/jewish_date.dart': ['calendar', 'tefila', 'formatter', 'zmanim'],
  'lib/src/hebrewcalendar/jewish_calendar.dart': ['calendar', 'tefila', 'formatter', 'zmanim'],
  'lib/src/hebrewcalendar/tefila_rules.dart': ['tefila'],
  'lib/src/hebrewcalendar/hebrew_date_formatter.dart': ['formatter'],
  'lib/src/hebrewcalendar/daf.dart': ['formatter', 'calendar'],
  'lib/src/hebrewcalendar/yomi_calculator.dart': ['calendar', 'formatter'],
  'lib/src/hebrewcalendar/yerushalmi_yomi_calculator.dart': ['calendar', 'formatter'],
};

const swaps = [
  (' <= ', ' < '),
  (' >= ', ' > '),
  (' < ', ' <= '),
  (' > ', ' >= '),
  (' == ', ' != '),
  (' != ', ' == '),
  (' && ', ' || '),
  (' || ', ' && '),
  (' + ', ' - '),
  (' - ', ' + '),
  (' * ', ' / '),
  (' / ', ' * '),
  (' ~/ ', ' * '),
  (' % ', ' * '),
  ('true', 'false'),
  ('false', 'true'),
  ('.floor()', '.ceil()'),
  ('.ceil()', '.floor()'),
  ('.round()', '.floor()'),
  ('.truncate()', '.floor()'),
  ('.toInt()', '.round()'),
  ('min(', 'max('),
  ('max(', 'min('),
  ('.isAfter(', '.isBefore('),
  ('.isBefore(', '.isAfter('),
  ('.add(', '.subtract('),
  ('.subtract(', '.add('),
  ('++', '--'),
  ('--', '++'),
  ('return null;', 'return null ?? (throw StateError(\'mutant\'));'),
];

final numberLiteral = RegExp(r'(?<![\w.$])(\d+)(\.\d+)?(?![\w.])');

class Mutant {
  Mutant(this.file, this.line, this.column, this.from, this.to, this.original);
  final String file;
  final int line;
  final int column;
  final String from;
  final String to;
  final String original;
}

List<bool> codeMask(String line) {
  final mask = List<bool>.filled(line.length, true);
  String? quote;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quote == null) {
      if (c == '/' && i + 1 < line.length && line[i + 1] == '/') {
        for (var j = i; j < line.length; j++) {
          mask[j] = false;
        }
        break;
      }
      if (c == "'" || c == '"') {
        quote = c;
        mask[i] = false;
      }
    } else {
      mask[i] = false;
      if (c == r'\') {
        if (i + 1 < line.length) mask[i + 1] = false;
        i++;
      } else if (c == quote) {
        quote = null;
      }
    }
  }
  return mask;
}

List<Mutant> enumerate(String root) {
  final mutants = <Mutant>[];
  for (final file in areasByFile.keys) {
    final lines = File('$root/$file').readAsLinesSync();
    var inBlockComment = false;
    for (var index = 0; index < lines.length; index++) {
      final text = lines[index];
      final trimmed = text.trimLeft();
      if (inBlockComment) {
        if (trimmed.contains('*/')) inBlockComment = false;
        continue;
      }
      if (trimmed.startsWith('/*')) {
        inBlockComment = !trimmed.contains('*/');
        continue;
      }
      if (trimmed.startsWith('//') || trimmed.startsWith('import ') || trimmed.startsWith('export ')) continue;
      final mask = codeMask(text);
      final taken = <int>{};
      for (final (from, to) in swaps) {
        var at = text.indexOf(from);
        while (at >= 0) {
          final inCode = List.generate(from.length, (k) => mask[at + k]).every((b) => b);
          final wordBoundary = !(from == 'true' || from == 'false') ||
              ((at == 0 || !RegExp(r'\w').hasMatch(text[at - 1])) &&
                  (at + from.length == text.length || !RegExp(r'\w').hasMatch(text[at + from.length])));
          if (inCode && wordBoundary && !taken.contains(at)) {
            taken.add(at);
            mutants.add(Mutant(file, index + 1, at, from, to, text));
          }
          at = text.indexOf(from, at + 1);
        }
      }
      if (trimmed.startsWith("'") || trimmed.startsWith('"') || RegExp(r'^[\d.,\s\[\]()eE+-]+,?$').hasMatch(trimmed)) continue;
      for (final match in numberLiteral.allMatches(text)) {
        final at = match.start;
        final literal = match.group(0)!;
        if (!List.generate(literal.length, (k) => mask[at + k]).every((b) => b) || taken.contains(at)) continue;
        final String to;
        if (match.group(2) == null) {
          to = '${int.parse(literal) + 1}';
        } else {
          final value = double.parse(literal);
          to = value == 0 ? '0.001' : '${value * 1.01}';
        }
        taken.add(at);
        mutants.add(Mutant(file, index + 1, at, literal, to, text));
      }
    }
  }
  return mutants;
}

List<Mutant> fromRecords(String root, String path) {
  final mutants = <Mutant>[];
  for (final line in File(path).readAsLinesSync()) {
    final record = jsonDecode(line) as Map<String, dynamic>;
    final file = record['file'] as String;
    final lines = File('$root/$file').readAsLinesSync();
    final wanted = record['line'] as int;
    final code = record['code'] as String;
    int? found;
    for (var distance = 0; distance < 40 && found == null; distance++) {
      for (final candidate in [wanted - distance, wanted + distance]) {
        if (candidate >= 1 && candidate <= lines.length && lines[candidate - 1].trim() == code) {
          found = candidate;
          break;
        }
      }
    }
    if (found == null) {
      stderr.writeln('not found: $file:$wanted $code');
      continue;
    }
    final original = record['from'] as String;
    final column = record['column'] as int;
    final text = lines[found - 1];
    final to = record['to'] as String;
    if (!text.startsWith(original, column)) {
      stderr.writeln('column mismatch: $file:$found $code');
      continue;
    }
    mutants.add(Mutant(file, found, column, original, to, text));
  }
  return mutants;
}

void main(List<String> arguments) {
  final root = arguments[0];
  final shard = int.parse(arguments[1]);
  final shards = int.parse(arguments[2]);
  final out = File(arguments[3]);
  final cases = arguments.length > 4 ? arguments[4] : '400';
  final all = arguments.length > 5 ? fromRecords(root, arguments[5]) : enumerate(root);
  if (shard < 0) {
    stdout.writeln('${all.length} mutants');
    return;
  }
  final done = <String>{};
  for (final previous in out.parent.listSync().whereType<File>().where((f) => f.path.endsWith('.jsonl'))) {
    for (final line in previous.readAsLinesSync()) {
      if (line.trim().isEmpty) continue;
      try {
        final record = jsonDecode(line) as Map<String, dynamic>;
        done.add('${record['file']}:${record['line']}:${record['column']}');
      } on FormatException {
        continue;
      }
    }
  }
  final harness = '$root/tool/kosherjava_parity';
  for (var index = 0; index < all.length; index++) {
    if (index % shards != shard) continue;
    final mutant = all[index];
    final key = '${mutant.file}:${mutant.line}:${mutant.column}';
    if (done.contains(key)) continue;
    final path = '$root/${mutant.file}';
    final original = File(path).readAsStringSync();
    final lines = original.split('\n');
    final text = lines[mutant.line - 1];
    lines[mutant.line - 1] = text.replaceRange(mutant.column, mutant.column + mutant.from.length, mutant.to);
    File(path).writeAsStringSync(lines.join('\n'));
    final stopwatch = Stopwatch()..start();
    final result = Process.runSync('timeout', [
      '-s',
      'KILL',
      '900',
      'dart',
      'run',
      'bin/parity.dart',
      '--seed',
      '11',
      '--cases',
      cases,
      for (final area in areasByFile[mutant.file]!) ...['--only', area],
      ...?Platform.environment['PARITY_EXTRA']?.split(' '),
    ], workingDirectory: harness);
    final output = '${result.stdout}\n${result.stderr}';
    String status;
    if (result.exitCode == 137 || result.exitCode == 124) {
      status = 'timeout';
    } else if (RegExp(r'\.dart:\d+:\d+: Error: ').hasMatch(output) && !output.contains('checks, ')) {
      status = 'invalid';
    } else if (result.exitCode == 0 && output.contains(' 0 checks diverge')) {
      status = 'survived';
    } else {
      status = 'killed';
    }
    final diverging = RegExp(r'^(\S+): \d+/\d+ diverge', multiLine: true)
        .allMatches(output)
        .map((m) => m.group(1))
        .take(3)
        .toList();
    if (status == 'survived' && Platform.environment['RUN_TESTS'] == '1') {
      final tests = Process.runSync('timeout', ['-s', 'KILL', '600', 'dart', 'test'], workingDirectory: root);
      if (tests.exitCode != 0) {
        status = 'killed';
        diverging.add('dart test');
      }
    }
    File(path).writeAsStringSync(original);
    out.writeAsStringSync('${jsonEncode({
      'file': mutant.file,
      'line': mutant.line,
      'column': mutant.column,
      'from': mutant.from,
      'to': mutant.to,
      'status': status,
      'seconds': stopwatch.elapsed.inSeconds,
      'killedBy': diverging,
      if (status == 'killed' && diverging.isEmpty) 'tail': output.split('\n').where((l) => l.trim().isNotEmpty).take(4).join(' | '),
      'code': mutant.original.trim(),
    })}\n', mode: FileMode.append);
  }
}
