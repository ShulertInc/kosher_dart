import 'dart:math';

import 'package:kosher_dart/kosher_dart.dart' as kd;

import '../area.dart';
import '../kosherjava.g.dart' as kj;
import '../random_input.dart';
import '../report.dart';
import 'tefila_calendar.dart';

const tefilaFlags = [
  'tachanunRecitedEndOfTishrei',
  'tachanunRecitedWeekAfterShavuos',
  'tachanunRecited13SivanOutOfIsrael',
  'tachanunRecitedPesachSheni',
  'tachanunRecited15IyarOutOfIsrael',
  'tachanunRecitedMinchaErevLagBaomer',
  'tachanunRecitedShivasYemeiHamiluim',
  'tachanunRecitedWeekOfHod',
  'tachanunRecitedWeekOfPurim',
  'tachanunRecitedFridays',
  'tachanunRecitedSundays',
  'tachanunRecitedMinchaAllYear',
  'mizmorLesodaRecitedErevYomKippurAndPesach',
];

class TefilaInput {
  TefilaInput(Random rng)
      : day = CalendarDay.random(rng),
        flags = {for (final flag in tefilaFlags) flag: chance(rng, 0.5)};

  final CalendarDay day;
  final Map<String, bool> flags;

  bool flag(String name) => flags[name]!;

  String describe(String id) => '$id $day on=${flags.entries.where((e) => e.value).map((e) => e.key).join(',')}';

  kj.TefilaRules java() => kj.TefilaRules()
    ..tachanunRecitedEndOfTishrei = flag('tachanunRecitedEndOfTishrei')
    ..tachanunRecitedWeekAfterShavuos = flag('tachanunRecitedWeekAfterShavuos')
    ..tachanunRecited13SivanOutOfIsrael = flag('tachanunRecited13SivanOutOfIsrael')
    ..tachanunRecitedPesachSheni = flag('tachanunRecitedPesachSheni')
    ..tachanunRecited15IyarOutOfIsrael = flag('tachanunRecited15IyarOutOfIsrael')
    ..tachanunRecitedMinchaErevLagBaomer = flag('tachanunRecitedMinchaErevLagBaomer')
    ..tachanunRecitedShivasYemeiHamiluim = flag('tachanunRecitedShivasYemeiHamiluim')
    ..tachanunRecitedWeekOfHod = flag('tachanunRecitedWeekOfHod')
    ..tachanunRecitedWeekOfPurim = flag('tachanunRecitedWeekOfPurim')
    ..tachanunRecitedFridays = flag('tachanunRecitedFridays')
    ..tachanunRecitedSundays = flag('tachanunRecitedSundays')
    ..tachanunRecitedMinchaAllYear = flag('tachanunRecitedMinchaAllYear')
    ..mizmorLesodaRecitedErevYomKippurAndPesach = flag('mizmorLesodaRecitedErevYomKippurAndPesach');

  kd.TefilaRules dart() => kd.TefilaRules(
        tachanunRecitedEndOfTishrei: flag('tachanunRecitedEndOfTishrei'),
        tachanunRecitedWeekAfterShavuos: flag('tachanunRecitedWeekAfterShavuos'),
        tachanunRecited13SivanOutOfIsrael: flag('tachanunRecited13SivanOutOfIsrael'),
        tachanunRecitedPesachSheni: flag('tachanunRecitedPesachSheni'),
        tachanunRecited15IyarOutOfIsrael: flag('tachanunRecited15IyarOutOfIsrael'),
        tachanunRecitedMinchaErevLagBaomer: flag('tachanunRecitedMinchaErevLagBaomer'),
        tachanunRecitedShivasYemeiHamiluim: flag('tachanunRecitedShivasYemeiHamiluim'),
        tachanunRecitedWeekOfHod: flag('tachanunRecitedWeekOfHod'),
        tachanunRecitedWeekOfPurim: flag('tachanunRecitedWeekOfPurim'),
        tachanunRecitedFridays: flag('tachanunRecitedFridays'),
        tachanunRecitedSundays: flag('tachanunRecitedSundays'),
        tachanunRecitedMinchaAllYear: flag('tachanunRecitedMinchaAllYear'),
        mizmorLesodaRecitedErevYomKippurAndPesach: flag('mizmorLesodaRecitedErevYomKippurAndPesach'),
      );
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
  'JewishCalendar.isVeseinTalUmatarStartDate': (
    (r, c) => r.isVeseinTalUmatarStartDate(c),
    (r, c) => c.isVeseinTalUmatarStartDate()
  ),
  'JewishCalendar.isVeseinTalUmatarStartingTonight': (
    (r, c) => r.isVeseinTalUmatarStartingTonight(c),
    (r, c) => c.isVeseinTalUmatarStartingTonight()
  ),
  'JewishCalendar.isVeseinTalUmatarRecited': (
    (r, c) => r.isVeseinTalUmatarRecited(c),
    (r, c) => c.isVeseinTalUmatarRecited()
  ),
  'JewishCalendar.isVeseinBerachaRecited': ((r, c) => r.isVeseinBerachaRecited(c), (r, c) => c.isVeseinBerachaRecited()),
  'JewishCalendar.isMashivHaruachStartDate': (
    (r, c) => r.isMashivHaruachStartDate(c),
    (r, c) => c.isMashivHaruachStartDate()
  ),
  'JewishCalendar.isMashivHaruachEndDate': ((r, c) => r.isMashivHaruachEndDate(c), (r, c) => c.isMashivHaruachEndDate()),
  'JewishCalendar.isMashivHaruachRecited': ((r, c) => r.isMashivHaruachRecited(c), (r, c) => c.isMashivHaruachRecited()),
  'JewishCalendar.isMoridHatalRecited': ((r, c) => r.isMoridHatalRecited(c), (r, c) => c.isMoridHatalRecited()),
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
      if (!input.day.agrees(report, name, describe)) continue;
      final javaRules = input.java();
      final dartRules = input.dart();
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
    report.exact(
        'tefila.default flags',
        'defaults',
        Value([
          java.isTachanunRecitedEndOfTishrei,
          java.isTachanunRecitedWeekAfterShavuos,
          java.isTachanunRecited13SivanOutOfIsrael,
          java.isTachanunRecitedPesachSheni,
          java.isTachanunRecited15IyarOutOfIsrael,
          java.isTachanunRecitedMinchaErevLagBaomer,
          java.isTachanunRecitedShivasYemeiHamiluim,
          java.isTachanunRecitedWeekOfHod,
          java.isTachanunRecitedWeekOfPurim,
          java.isTachanunRecitedFridays,
          java.isTachanunRecitedSundays,
          java.isTachanunRecitedMinchaAllYear,
          java.isMizmorLesodaRecitedErevYomKippurAndPesach,
        ].join(',')),
        Value([
          dart.tachanunRecitedEndOfTishrei,
          dart.tachanunRecitedWeekAfterShavuos,
          dart.tachanunRecited13SivanOutOfIsrael,
          dart.tachanunRecitedPesachSheni,
          dart.tachanunRecited15IyarOutOfIsrael,
          dart.tachanunRecitedMinchaErevLagBaomer,
          dart.tachanunRecitedShivasYemeiHamiluim,
          dart.tachanunRecitedWeekOfHod,
          dart.tachanunRecitedWeekOfPurim,
          dart.tachanunRecitedFridays,
          dart.tachanunRecitedSundays,
          dart.tachanunRecitedMinchaAllYear,
          dart.mizmorLesodaRecitedErevYomKippurAndPesach,
        ].join(',')));
    java.release();
  }
}
