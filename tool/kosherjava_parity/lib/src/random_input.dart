import 'dart:math';

import 'zones.dart';

Random caseRandom(int seed, String area, int index) {
  var state = seed ^ 0x9E3779B97F4A7C15;
  for (final unit in area.codeUnits) {
    state = mix(state ^ unit);
  }
  return Random(mix(state ^ index) & 0x7fffffff);
}

int mix(int value) {
  var z = value + 0x9E3779B97F4A7C15;
  z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
  z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
  return z ^ (z >>> 31);
}

double uniform(Random rng, double low, double high) => low + rng.nextDouble() * (high - low);

int between(Random rng, int low, int high) => low + rng.nextInt(high - low + 1);

T pick<T>(Random rng, List<T> values) => values[rng.nextInt(values.length)];

bool chance(Random rng, double probability) => rng.nextDouble() < probability;

bool isGregorianLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

int daysInGregorianMonth(int year, int month) => const [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1] +
    (month == 2 && isGregorianLeapYear(year) ? 1 : 0);

class CivilDate {
  const CivilDate(this.year, this.month, this.day);
  final int year;
  final int month;
  final int day;

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

CivilDate randomDate(Random rng, int firstYear, int lastYear) {
  final year = between(rng, firstYear, lastYear);
  final month = between(rng, 1, 12);
  return CivilDate(year, month, between(rng, 1, daysInGregorianMonth(year, month)));
}

class Place {
  const Place(this.latitude, this.longitude, this.elevation, this.zone);
  final double latitude;
  final double longitude;
  final double elevation;
  final String zone;

  @override
  String toString() => 'lat=$latitude lon=$longitude elev=$elevation zone=$zone';
}

double wrapLongitude(double longitude) => (longitude + 180) % 360 - 180;

Place randomPlace(Random rng, Zones zones, CivilDate date) {
  final zone = pick(rng, zones.names);
  final elevation = chance(rng, 0.5) ? 0.0 : uniform(rng, 0, 4000);
  final roll = rng.nextDouble();
  if (roll < 0.2) {
    return Place(uniform(rng, -90, 90), uniform(rng, -180, 180), elevation, zone);
  }
  final noonUtc = zones.javaStartOfDay(zone, date.year, date.month, date.day);
  final offsetHours = zones.javaOffsetMillis(zone, noonUtc) / 3600000;
  final longitude = wrapLongitude(offsetHours * 15 + uniform(rng, -25, 25));
  final latitude = roll < 0.35
      ? (chance(rng, 0.5) ? 1 : -1) * uniform(rng, 60, 90)
      : uniform(rng, -60, 60);
  return Place(latitude, longitude, elevation, zone);
}
