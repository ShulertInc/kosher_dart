import 'dart:math' as math;

import 'package:jni/jni.dart';

sealed class Got<T> {
  const Got();
}

final class Value<T> extends Got<T> {
  const Value(this.value);
  final T value;
}

final class Threw<T> extends Got<T> {
  const Threw(this.error);
  final Object error;

  String get summary {
    final error = this.error;
    final text = error is JThrowable ? error.message : '$error';
    return text.split('\n').first.trim();
  }
}

Got<T> attempt<T>(T Function() body) {
  try {
    return Value(body());
  } catch (error) {
    return Threw(error);
  }
}

enum Outcome { same, rounding, differs, absentInJava, absentInDart, throwsInJava, throwsInDart, throwsInBoth }

class Example {
  Example(this.input, this.detail);
  final String input;
  final String detail;
}

class Check {
  Check(this.name);

  final String name;
  final Map<Outcome, int> counts = {};
  final Map<Outcome, List<Example>> examples = {};
  final Map<String, int> diffBuckets = {};
  num largestDifference = 0;

  int get total => counts.values.fold(0, (sum, count) => sum + count);
  int get failures =>
      total - (counts[Outcome.same] ?? 0) - (counts[Outcome.rounding] ?? 0) - (counts[Outcome.throwsInBoth] ?? 0);
}

class Report {
  Report({this.examplesPerOutcome = 3});

  final int examplesPerOutcome;
  final Map<String, Check> checks = {};
  final Map<String, int> notes = {};

  void note(String reason) => notes[reason] = (notes[reason] ?? 0) + 1;

  void record(String check, Outcome outcome, String input, String detail, {num difference = 0, String? bucket}) {
    final entry = checks.putIfAbsent(check, () => Check(check));
    entry.counts[outcome] = (entry.counts[outcome] ?? 0) + 1;
    if (bucket != null) entry.diffBuckets[bucket] = (entry.diffBuckets[bucket] ?? 0) + 1;
    if (difference.abs() > entry.largestDifference) entry.largestDifference = difference.abs();
    if (outcome == Outcome.same) return;
    final list = entry.examples.putIfAbsent(outcome, () => []);
    if (list.length < examplesPerOutcome) list.add(Example(input, detail));
  }

  bool _recordThrows<J, D>(String check, String input, Got<J> java, Got<D> dart) {
    if (java is Threw<J> && dart is Threw<D>) {
      record(check, Outcome.throwsInBoth, input, 'java: ${java.summary} | dart: ${dart.summary}');
    } else if (java is Threw<J>) {
      record(check, Outcome.throwsInJava, input, 'java: ${java.summary} | dart: ${(dart as Value<D>).value}');
    } else if (dart is Threw<D>) {
      record(check, Outcome.throwsInDart, input, 'dart: ${dart.summary} | java: ${(java as Value<J>).value}');
    } else {
      return false;
    }
    return true;
  }

  void instant(String check, String input, Got<int?> java, Got<int?> dart) {
    if (_recordThrows(check, input, java, dart)) return;
    final j = (java as Value<int?>).value;
    final d = (dart as Value<int?>).value;
    if (j == null && d == null) return record(check, Outcome.same, input, '');
    if (j == null) return record(check, Outcome.absentInJava, input, 'dart ${iso(d!)}');
    if (d == null) return record(check, Outcome.absentInDart, input, 'java ${iso(j)}');
    final difference = d - j;
    if (difference == 0) return record(check, Outcome.same, input, '');
    final outcome = difference.abs() <= 1 ? Outcome.rounding : Outcome.differs;
    record(check, outcome, input, 'java ${iso(j)} dart ${iso(d)} (dart ${signed(difference)} ms)',
        difference: difference, bucket: durationBucket(difference));
  }

  void real(String check, String input, Got<double?> java, Got<double?> dart, {double tolerance = 1e-9}) {
    if (_recordThrows(check, input, java, dart)) return;
    final j = (java as Value<double?>).value;
    final d = (dart as Value<double?>).value;
    final javaAbsent = j == null || j.isNaN;
    final dartAbsent = d == null || d.isNaN;
    if (javaAbsent && dartAbsent) return record(check, Outcome.same, input, '');
    if (javaAbsent) return record(check, Outcome.absentInJava, input, 'java $j dart $d');
    if (dartAbsent) return record(check, Outcome.absentInDart, input, 'java $j dart $d');
    if (j == d) return record(check, Outcome.same, input, '');
    final difference = d - j;
    final scale = math.max(1.0, math.max(j.abs(), d.abs()));
    final outcome = difference.abs() <= tolerance * scale ? Outcome.rounding : Outcome.differs;
    record(check, outcome, input, 'java $j dart $d (dart ${signed(difference)})', difference: difference);
  }

  void exact<T>(String check, String input, Got<T> java, Got<T> dart) {
    if (_recordThrows(check, input, java, dart)) return;
    final j = (java as Value<T>).value;
    final d = (dart as Value<T>).value;
    if (j == d) return record(check, Outcome.same, input, '');
    if (j == null) return record(check, Outcome.absentInJava, input, 'dart $d');
    if (d == null) return record(check, Outcome.absentInDart, input, 'java $j');
    record(check, Outcome.differs, input, 'java $j | dart $d');
  }

  String render() {
    final buffer = StringBuffer();
    final all = checks.values.toList();
    final failing = all.where((check) => check.failures > 0).toList()
      ..sort((a, b) => b.failures.compareTo(a.failures));
    final rounding = all.where((check) => check.failures == 0 && (check.counts[Outcome.rounding] ?? 0) > 0).toList()
      ..sort((a, b) => (b.counts[Outcome.rounding]!).compareTo(a.counts[Outcome.rounding]!));
    final values = all.fold(0, (sum, check) => sum + check.total);
    buffer.writeln('${all.length} checks, $values values compared, '
        '${failing.length} checks diverge, ${rounding.length} differ only by rounding');
    for (final note in notes.entries) {
      buffer.writeln('note: ${note.key}: ${note.value}');
    }
    for (final check in failing) {
      buffer.writeln();
      buffer.writeln('${check.name}: ${check.failures}/${check.total} diverge'
          '${check.largestDifference != 0 ? ', largest ${check.largestDifference}' : ''}');
      buffer.writeln('  ${_counts(check)}');
      if (check.diffBuckets.isNotEmpty) {
        buffer.writeln('  by size: ${check.diffBuckets.entries.map((e) => '${e.key} ${e.value}').join(', ')}');
      }
      for (final entry in check.examples.entries) {
        for (final example in entry.value) {
          buffer.writeln('  [${entry.key.name}] ${example.detail}');
          buffer.writeln('      ${example.input}');
        }
      }
    }
    if (rounding.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('rounding only:');
      for (final check in rounding) {
        buffer.writeln('  ${check.name}: ${check.counts[Outcome.rounding]}/${check.total}');
        final example = check.examples[Outcome.rounding]?.first;
        if (example != null) buffer.writeln('      ${example.detail}  ${example.input}');
      }
    }
    return buffer.toString();
  }

  String _counts(Check check) => Outcome.values
      .where((outcome) => (check.counts[outcome] ?? 0) > 0)
      .map((outcome) => '${outcome.name} ${check.counts[outcome]}')
      .join(', ');
}

String iso(int millis) => DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toIso8601String();

String signed(num value) => value >= 0 ? '+$value' : '$value';

String durationBucket(int millis) {
  final size = millis.abs();
  if (size <= 1) return '<=1ms';
  if (size < 1000) return '<1s';
  if (size < 60000) return '<1min';
  if (size < 3600000) return '<1h';
  if (size < 86400000) return '<1d';
  return '>=1d';
}

extension FlooredMillis on DateTime {
  int get flooredMillis => (microsecondsSinceEpoch - microsecondsSinceEpoch % 1000) ~/ 1000;
}

String withKosherDartMonthNames(String text) =>
    text.replaceAll('Cheshvan', 'Marcheshvan').replaceAll('חשון', 'מרחשון');
