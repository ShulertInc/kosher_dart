import 'dart:math';

import 'package:kosher_dart/kosher_dart.dart' as kd;

import '../area.dart';
import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';
import 'tefila_calendar.dart';

typedef TefilaFlag = (
  String,
  void Function(kj.TefilaRules, bool),
  bool Function(kj.TefilaRules),
  void Function(kd.TefilaRules, bool),
  bool Function(kd.TefilaRules),
);

final List<TefilaFlag> tefilaFlags = [
  (
    'TachanunRecitedEndOfTishrei',
    (r, v) => r.tachanunRecitedEndOfTishrei = v,
    (r) => r.isTachanunRecitedEndOfTishrei,
    (r, v) => r.setTachanunRecitedEndOfTishrei(v),
    (r) => r.isTachanunRecitedEndOfTishrei(),
  ),
  (
    'TachanunRecitedWeekAfterShavuos',
    (r, v) => r.tachanunRecitedWeekAfterShavuos = v,
    (r) => r.isTachanunRecitedWeekAfterShavuos,
    (r, v) => r.setTachanunRecitedWeekAfterShavuos(v),
    (r) => r.isTachanunRecitedWeekAfterShavuos(),
  ),
  (
    'TachanunRecited13SivanOutOfIsrael',
    (r, v) => r.tachanunRecited13SivanOutOfIsrael = v,
    (r) => r.isTachanunRecited13SivanOutOfIsrael,
    (r, v) => r.setTachanunRecited13SivanOutOfIsrael(v),
    (r) => r.isTachanunRecited13SivanOutOfIsrael(),
  ),
  (
    'TachanunRecitedPesachSheni',
    (r, v) => r.tachanunRecitedPesachSheni = v,
    (r) => r.isTachanunRecitedPesachSheni,
    (r, v) => r.setTachanunRecitedPesachSheni(v),
    (r) => r.isTachanunRecitedPesachSheni(),
  ),
  (
    'TachanunRecited15IyarOutOfIsrael',
    (r, v) => r.tachanunRecited15IyarOutOfIsrael = v,
    (r) => r.isTachanunRecited15IyarOutOfIsrael,
    (r, v) => r.setTachanunRecited15IyarOutOfIsrael(v),
    (r) => r.isTachanunRecited15IyarOutOfIsrael(),
  ),
  (
    'TachanunRecitedMinchaErevLagBaomer',
    (r, v) => r.tachanunRecitedMinchaErevLagBaomer = v,
    (r) => r.isTachanunRecitedMinchaErevLagBaomer,
    (r, v) => r.setTachanunRecitedMinchaErevLagBaomer(v),
    (r) => r.isTachanunRecitedMinchaErevLagBaomer(),
  ),
  (
    'TachanunRecitedShivasYemeiHamiluim',
    (r, v) => r.tachanunRecitedShivasYemeiHamiluim = v,
    (r) => r.isTachanunRecitedShivasYemeiHamiluim,
    (r, v) => r.setTachanunRecitedShivasYemeiHamiluim(v),
    (r) => r.isTachanunRecitedShivasYemeiHamiluim(),
  ),
  (
    'TachanunRecitedWeekOfHod',
    (r, v) => r.tachanunRecitedWeekOfHod = v,
    (r) => r.isTachanunRecitedWeekOfHod,
    (r, v) => r.setTachanunRecitedWeekOfHod(v),
    (r) => r.isTachanunRecitedWeekOfHod(),
  ),
  (
    'TachanunRecitedWeekOfPurim',
    (r, v) => r.tachanunRecitedWeekOfPurim = v,
    (r) => r.isTachanunRecitedWeekOfPurim,
    (r, v) => r.setTachanunRecitedWeekOfPurim(v),
    (r) => r.isTachanunRecitedWeekOfPurim(),
  ),
  (
    'TachanunRecitedFridays',
    (r, v) => r.tachanunRecitedFridays = v,
    (r) => r.isTachanunRecitedFridays,
    (r, v) => r.setTachanunRecitedFridays(v),
    (r) => r.isTachanunRecitedFridays(),
  ),
  (
    'TachanunRecitedSundays',
    (r, v) => r.tachanunRecitedSundays = v,
    (r) => r.isTachanunRecitedSundays,
    (r, v) => r.setTachanunRecitedSundays(v),
    (r) => r.isTachanunRecitedSundays(),
  ),
  (
    'TachanunRecitedMinchaAllYear',
    (r, v) => r.tachanunRecitedMinchaAllYear = v,
    (r) => r.isTachanunRecitedMinchaAllYear,
    (r, v) => r.setTachanunRecitedMinchaAllYear(v),
    (r) => r.isTachanunRecitedMinchaAllYear(),
  ),
  (
    'MizmorLesodaRecitedErevYomKippurAndPesach',
    (r, v) => r.mizmorLesodaRecitedErevYomKippurAndPesach = v,
    (r) => r.isMizmorLesodaRecitedErevYomKippurAndPesach,
    (r, v) => r.setMizmorLesodaRecitedErevYomKippurAndPesach(v),
    (r) => r.isMizmorLesodaRecitedErevYomKippurAndPesach(),
  ),
];

class TefilaInput {
  TefilaInput(Random rng)
      : day = CalendarDay.random(rng),
        flags = {for (final (name, _, _, _, _) in tefilaFlags) name: chance(rng, 0.5)},
        setFlags = {for (final (name, _, _, _, _) in tefilaFlags) name: chance(rng, 0.8)};

  final CalendarDay day;
  final Map<String, bool> flags;
  final Map<String, bool> setFlags;

  String describe(String id) => '$id $day '
      'set=${setFlags.entries.where((e) => e.value).map((e) => '${e.key}:${flags[e.key]}').join(',')}';

  kj.TefilaRules java() {
    final rules = kj.TefilaRules();
    for (final (name, set, _, _, _) in tefilaFlags) {
      if (setFlags[name]!) set(rules, flags[name]!);
    }
    return rules;
  }

  kd.TefilaRules dart() {
    final rules = kd.TefilaRules();
    for (final (name, _, _, set, _) in tefilaFlags) {
      if (setFlags[name]!) set(rules, flags[name]!);
    }
    return rules;
  }
}

typedef JavaRule = bool Function(kj.TefilaRules rules, kj.JewishCalendar calendar);
typedef DartRule = bool Function(kd.TefilaRules rules, kd.JewishCalendar calendar);

final tefilaRules = <String, (JavaRule, DartRule)>{
  'isTachanunRecitedShacharis': ((r, c) => r.isTachanunRecitedShacharis(c), (r, c) => r.isTachanunRecitedShacharis(c)),
  'isTachanunRecitedMincha': ((r, c) => r.isTachanunRecitedMincha(c), (r, c) => r.isTachanunRecitedMincha(c)),
  'isVeseinTalUmatarStartDate': ((r, c) => r.isVeseinTalUmatarStartDate(c), (r, c) => r.isVeseinTalUmatarStartDate(c)),
  'isVeseinTalUmatarStartingTonight': (
    (r, c) => r.isVeseinTalUmatarStartingTonight(c),
    (r, c) => r.isVeseinTalUmatarStartingTonight(c)
  ),
  'isVeseinTalUmatarRecited': ((r, c) => r.isVeseinTalUmatarRecited(c), (r, c) => r.isVeseinTalUmatarRecited(c)),
  'isVeseinBerachaRecited': ((r, c) => r.isVeseinBerachaRecited(c), (r, c) => r.isVeseinBerachaRecited(c)),
  'isMashivHaruachStartDate': ((r, c) => r.isMashivHaruachStartDate(c), (r, c) => r.isMashivHaruachStartDate(c)),
  'isMashivHaruachEndDate': ((r, c) => r.isMashivHaruachEndDate(c), (r, c) => r.isMashivHaruachEndDate(c)),
  'isMashivHaruachRecited': ((r, c) => r.isMashivHaruachRecited(c), (r, c) => r.isMashivHaruachRecited(c)),
  'isMoridHatalRecited': ((r, c) => r.isMoridHatalRecited(c), (r, c) => r.isMoridHatalRecited(c)),
  'isHallelRecited': ((r, c) => r.isHallelRecited(c), (r, c) => r.isHallelRecited(c)),
  'isHallelShalemRecited': ((r, c) => r.isHallelShalemRecited(c), (r, c) => r.isHallelShalemRecited(c)),
  'isAlHanissimRecited': ((r, c) => r.isAlHanissimRecited(c), (r, c) => r.isAlHanissimRecited(c)),
  'isYaalehVeyavoRecited': ((r, c) => r.isYaalehVeyavoRecited(c), (r, c) => r.isYaalehVeyavoRecited(c)),
  'isMizmorLesodaRecited': ((r, c) => r.isMizmorLesodaRecited(c), (r, c) => r.isMizmorLesodaRecited(c)),
};

class TefilaArea extends Area {
  TefilaArea(super.zones);

  @override
  String get name => 'tefila';

  @override
  void run(int seed, Iterable<int> indexes, Report report) {
    if (indexes.contains(0)) compareDefaults(report);
    for (final index in indexes) {
      final input = TefilaInput(caseRandom(seed, name, index));
      final describe = input.describe('tefila#$index seed=$seed');
      final javaRules = input.java();
      final dartRules = input.dart();
      for (final (flag, _, javaGet, _, dartGet) in tefilaFlags) {
        report.exact('tefila.is$flag', describe, attempt(() => javaGet(javaRules)), attempt(() => dartGet(dartRules)));
      }
      if (!input.day.agrees(report, name, describe)) {
        javaRules.release();
        continue;
      }
      for (final MapEntry(key: rule, value: (java, dart)) in tefilaRules.entries) {
        final javaCalendar = input.day.java();
        final dartCalendar = input.day.dart();
        final before = input.day.stateOfDart(dartCalendar);
        compareOrBothThrow(report, 'tefila.$rule', describe, attempt(() => java(javaRules, javaCalendar)),
            attempt(() => dart(dartRules, dartCalendar)));
        report.exact('tefila.$rule leaves its calendar unchanged', describe, Value(before),
            attempt(() => input.day.stateOfDart(dartCalendar)));
        javaCalendar.release();
      }
      javaRules.release();
    }
  }

  void compareDefaults(Report report) {
    final java = kj.TefilaRules();
    final dart = kd.TefilaRules();
    for (final (flag, _, javaGet, _, dartGet) in tefilaFlags) {
      report.exact('tefila.default is$flag', 'defaults', attempt(() => javaGet(java)), attempt(() => dartGet(dart)));
    }
    java.release();
  }
}
