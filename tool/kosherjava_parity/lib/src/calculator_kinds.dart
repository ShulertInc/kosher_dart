import 'dart:math';

import 'package:jni/jni.dart';
import 'package:kosher_dart/kosher_dart.dart' as kd;

import 'kosherjava.g.dart' as kj;
import 'random_input.dart';

enum CalculatorKind {
  noaa('NOAA'),
  suntimes('SunTimes'),
  meeus('Meeus'),
  spa('SPA');

  const CalculatorKind(this.label);

  final String label;

  kj.AstronomicalCalculator java() => switch (this) {
        noaa => kj.NOAACalculator(),
        suntimes => kj.SunTimesCalculator(),
        meeus => kj.MeeusCalculator(),
        spa => kj.SPACalculator(),
      };

  kd.AstronomicalCalculator dart() => switch (this) {
        noaa => kd.NOAACalculator(),
        suntimes => kd.SunTimesCalculator(),
        meeus => kd.MeeusCalculator(),
        spa => kd.SPACalculator(),
      };

  bool get hasPrecisionSettings => this == meeus || this == spa;
}

class PrecisionSettings {
  PrecisionSettings(Random rng, this.kind)
      : applyDeltaT = chance(rng, 0.3) ? null : chance(rng, 0.7),
        overridesDeltaT = kind == CalculatorKind.spa && chance(rng, 0.6),
        deltaTOverride = pick(rng, [
          null,
          67.0,
          0.0,
          uniform(rng, -50, 300),
          uniform(rng, -5000, 5000),
          if (chance(rng, 0.05)) double.nan,
        ]),
        pressure = kind == CalculatorKind.spa && chance(rng, 0.7)
            ? pick(rng, [uniform(rng, 500, 1100), uniform(rng, 0, 3000), 0.0, -uniform(rng, 0, 100)])
            : null,
        temperature = kind == CalculatorKind.spa && chance(rng, 0.7)
            ? pick(rng, [uniform(rng, -60, 60), uniform(rng, -300, 300), -273.0, 0.0])
            : null;

  final CalculatorKind kind;
  final bool? applyDeltaT;
  final bool overridesDeltaT;
  final double? deltaTOverride;
  final double? pressure;
  final double? temperature;

  void applyToJava(kj.AstronomicalCalculator java) {
    switch (kind) {
      case CalculatorKind.meeus:
        if (applyDeltaT != null) (java as kj.MeeusCalculator).applyDeltaT = applyDeltaT!;
      case CalculatorKind.spa:
        final spa = java as kj.SPACalculator;
        if (applyDeltaT != null) spa.applyDeltaT = applyDeltaT!;
        if (overridesDeltaT) {
          final boxed = deltaTOverride?.toJDouble();
          spa.deltaTOverride = boxed;
          boxed?.release();
        }
        if (pressure != null) spa.pressure = pressure!;
        if (temperature != null) spa.temperature = temperature!;
      case CalculatorKind.noaa || CalculatorKind.suntimes:
        break;
    }
  }

  void applyToDart(kd.AstronomicalCalculator dart) {
    switch (kind) {
      case CalculatorKind.meeus:
        if (applyDeltaT != null) (dart as kd.MeeusCalculator).setApplyDeltaT(applyDeltaT!);
      case CalculatorKind.spa:
        final spa = dart as kd.SPACalculator;
        if (applyDeltaT != null) spa.setApplyDeltaT(applyDeltaT!);
        if (overridesDeltaT) spa.setDeltaTOverride(deltaTOverride);
        if (pressure != null) spa.setPressure(pressure!);
        if (temperature != null) spa.setTemperature(temperature!);
      case CalculatorKind.noaa || CalculatorKind.suntimes:
        break;
    }
  }

  @override
  String toString() => [
        'applyDeltaT=${applyDeltaT ?? 'default'}',
        if (kind == CalculatorKind.spa) ...[
          'deltaTOverride=${overridesDeltaT ? '$deltaTOverride' : 'default'}',
          'pressure=${pressure ?? 'default'}',
          'temperature=${temperature ?? 'default'}',
        ],
      ].join(' ');
}
