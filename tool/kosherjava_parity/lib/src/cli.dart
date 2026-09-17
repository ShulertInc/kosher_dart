import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

import 'area.dart';
import 'jvm.dart';
import 'report.dart';
import 'zones.dart';

void runParity(List<String> arguments, Map<String, Area Function(Zones)> areaFactories) {
  final parser = ArgParser()
    ..addOption('seed', help: 'Random seed; a fresh one is drawn when omitted')
    ..addOption('cases', defaultsTo: '200', help: 'Random cases per area')
    ..addOption('case', help: 'Run only this case index, to replay a divergence')
    ..addMultiOption('only', allowed: areaFactories.keys, help: 'Areas to run')
    ..addOption('examples', defaultsTo: '3', help: 'Examples kept per check and outcome')
    ..addFlag('help', abbr: 'h', negatable: false);
  final options = parser.parse(arguments);
  if (options.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }
  final seed = int.tryParse(options.option('seed') ?? '') ?? Random().nextInt(1 << 32);
  final single = int.tryParse(options.option('case') ?? '');
  final cases = int.parse(options.option('cases')!);
  final indexes = single == null ? List.generate(cases, (index) => index) : [single];
  final selected = options.multiOption('only').isEmpty ? areaFactories.keys : options.multiOption('only');

  startJvm();
  final zones = Zones.load();
  final report = Report(examplesPerOutcome: int.parse(options.option('examples')!));
  stdout.writeln('seed $seed, ${indexes.length} cases per area, ${zones.names.length} shared time zones');
  for (final name in selected) {
    final stopwatch = Stopwatch()..start();
    areaFactories[name]!(zones).run(seed, indexes, report);
    stdout.writeln('$name done in ${stopwatch.elapsed}');
  }
  stdout.writeln(report.render());
  exitCode = report.checks.values.any((check) => check.failures > 0) ? 1 : 0;
}
