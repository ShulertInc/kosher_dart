import 'dart:math';

import 'package:kosher_dart/src/util/astronomical_calculator.dart';
import 'package:kosher_dart/src/util/geo_location.dart';
import 'package:kosher_dart/src/util/vsop87_earth.dart';
import 'package:vector_math/vector_math.dart';

enum _SolarEvent { sunrise, sunset, noon, midnight }

class MeeusCalculator extends AstronomicalCalculator {
  bool _applyDeltaT = true;

  @override
  MeeusCalculator clone() =>
      copyCalculatorSettings(this, MeeusCalculator()).._applyDeltaT = _applyDeltaT;

  @override
  String getCalculatorName() =>
      "Jean Meeus Higher-Accuracy (VSOP87) Algorithm";

  void setApplyDeltaT(bool applyDeltaT) {
    _applyDeltaT = applyDeltaT;
  }

  bool isApplyDeltaT() => _applyDeltaT;

  @override
  bool operator ==(Object other) =>
      super == other && _applyDeltaT == (other as MeeusCalculator)._applyDeltaT;

  @override
  int get hashCode => Object.hash(super.hashCode, _applyDeltaT);

  @override
  double getUTCSunrise(DateTime dateTime, GeoLocation geoLocation,
          double zenith, bool adjustForElevation) =>
      _getUTCSunRiseSet(dateTime, geoLocation, zenith, adjustForElevation,
          _SolarEvent.sunrise);

  @override
  double getUTCSunset(DateTime dateTime, GeoLocation geoLocation,
          double zenith, bool adjustForElevation) =>
      _getUTCSunRiseSet(dateTime, geoLocation, zenith, adjustForElevation,
          _SolarEvent.sunset);

  double _getUTCSunRiseSet(DateTime dateTime, GeoLocation geoLocation,
      double zenith, bool adjustForElevation, _SolarEvent solarEvent) {
    final double elevation =
        adjustForElevation ? geoLocation.getElevation() : 0;
    final double adjustedZenith = adjustZenith(zenith, elevation, dateTime);
    final double riseSet = _getSunRiseSetUTC(dateTime,
            geoLocation.getLatitude(), -geoLocation.getLongitude(),
            adjustedZenith, solarEvent) /
        60;
    return _normalizeHours(riseSet);
  }

  @override
  double getUTCNoon(DateTime dateTime, GeoLocation geoLocation) =>
      _normalizeHours(_getSolarNoonMidnightUTC(julianDayOfDate(dateTime),
              -geoLocation.getLongitude(), _SolarEvent.noon) /
          60);

  @override
  double getUTCMidnight(DateTime dateTime, GeoLocation geoLocation) =>
      _normalizeHours(_getSolarNoonMidnightUTC(julianDayOfDate(dateTime),
              -geoLocation.getLongitude(), _SolarEvent.midnight) /
          60);

  static double _normalizeHours(double hours) =>
      (hours.remainder(24) + 24).remainder(24);

  double _getSolarNoonMidnightUTC(
      double julianDay, double longitude, _SolarEvent solarEvent) {
    final double base = solarEvent == _SolarEvent.noon ? 720.0 : 1440.0;
    final double tnoon =
        _getJulianCenturiesFromJulianDay(julianDay + longitude / 360.0);
    double equationOfTime = _getEquationOfTime(tnoon);
    double solNoonUTC = base + (longitude * 4) - equationOfTime;
    for (int i = 0; i < 3; i++) {
      final double newt =
          _getJulianCenturiesFromJulianDay(julianDay + solNoonUTC / 1440.0);
      equationOfTime = _getEquationOfTime(newt);
      solNoonUTC = base + (longitude * 4) - equationOfTime;
    }
    return solNoonUTC;
  }

  double _getSunRiseSetUTC(DateTime dateTime, double latitude,
      double longitude, double zenith, _SolarEvent solarEvent) {
    final double julianDay = julianDayOfDate(dateTime);
    final double noonmin =
        _getSolarNoonMidnightUTC(julianDay, longitude, _SolarEvent.noon);
    final double tnoon =
        _getJulianCenturiesFromJulianDay(julianDay + noonmin / 1440.0);
    double equationOfTime = _getEquationOfTime(tnoon);
    double solarDeclination = _getSunDeclination(tnoon);
    double hourAngle =
        _getSunHourAngle(latitude, solarDeclination, zenith, solarEvent);
    double delta = longitude - degrees(hourAngle);
    double timeUTC = 720 + (4 * delta) - equationOfTime;
    for (int i = 0; i < 2; i++) {
      final double newt =
          _getJulianCenturiesFromJulianDay(julianDay + timeUTC / 1440.0);
      equationOfTime = _getEquationOfTime(newt);
      solarDeclination = _getSunDeclination(newt);
      hourAngle =
          _getSunHourAngle(latitude, solarDeclination, zenith, solarEvent);
      if (hourAngle.isNaN) {
        return double.nan;
      }
      delta = longitude - degrees(hourAngle);
      timeUTC = 720 + (4 * delta) - equationOfTime;
    }
    return timeUTC;
  }

  @override
  double getTimeAtAzimuth(
      DateTime dateTime, GeoLocation geoLocation, double azimuth) {
    if (azimuth != 90.0 && azimuth != 270.0) {
      throw ArgumentError(
          "The targetAzimuth must be 90 or 270. Other azimuth values are not supported");
    }
    final double julianDay = julianDayOfDate(dateTime);
    final double solarNoonBase = 0.5 - (geoLocation.getLongitude() / 360.0);
    double dayFraction = solarNoonBase + (azimuth == 90.0 ? 0.25 : 0.75);
    for (int i = 0; i < 3; i++) {
      final double julianCenturies =
          _getJulianCenturiesFromJulianDay(julianDay + dayFraction);
      final double ratio = tanDeg(_getSunDeclination(julianCenturies)) /
          tanDeg(geoLocation.getLatitude());
      if (ratio.isNaN || ratio > 1.0 || ratio < -1.0) {
        return double.nan;
      }
      final double offset =
          (azimuth == 90.0 ? -1.0 : 1.0) * (acosDeg(ratio) / 360.0);
      dayFraction = solarNoonBase +
          offset -
          (_getEquationOfTime(julianCenturies) / 1440.0);
    }
    return _normalizeHours(dayFraction * 24.0);
  }

  @override
  double getSolarElevation(DateTime instant, GeoLocation geoLocation) =>
      _getSolarElevationAzimuth(instant, geoLocation, false);

  @override
  double getSolarAzimuth(DateTime instant, GeoLocation geoLocation) =>
      _getSolarElevationAzimuth(instant, geoLocation, true);

  double _getSolarElevationAzimuth(
      DateTime instant, GeoLocation geoLocation, bool isAzimuth) {
    final double lat = geoLocation.getLatitude();
    final double lon = geoLocation.getLongitude();
    final double fractionalDay = fractionalDayOfInstant(instant);
    final double jc = _getJulianCenturiesFromJulianDay(
        julianDayOfDate(instant.toUtc()) + fractionalDay);
    final double decl = _getSunDeclination(jc);
    final double eot = _getEquationOfTime(jc);
    final double trueSolarTime =
        ((fractionalDay + eot / 1440.0 + lon / 360.0) + 2).remainder(1);
    final double hourAngle = trueSolarTime * 2 * pi - pi;
    final double cosZenith = sinDeg(lat) * sinDeg(decl) +
        cosDeg(lat) * cosDeg(decl) * cos(hourAngle);
    final double zenithDeg = acosDeg(max(-1.0, min(1.0, cosZenith)));
    final double elevation =
        (90.0 - zenithDeg) + _adjustElevationForRefraction(90.0 - zenithDeg);
    double azimuth;
    final double azDenom = cosDeg(lat) * sinDeg(zenithDeg);
    if (azDenom.abs() > 0.001) {
      final double az =
          (sinDeg(lat) * cosDeg(zenithDeg) - sinDeg(decl)) / azDenom;
      azimuth = 180 -
          acosDeg(max(-1.0, min(1.0, az))) * (hourAngle > 0 ? -1 : 1);
    } else {
      azimuth = lat > 0 ? 180.0 : 0.0;
    }
    return isAzimuth ? (azimuth + 360).remainder(360) : elevation;
  }

  static double _adjustElevationForRefraction(double elevation) {
    if (elevation > 85.0) {
      return 0.0;
    }
    final double te = tanDeg(elevation);
    final double correction;
    if (elevation > 5.0) {
      correction = 58.1 / te - 0.07 / pow(te, 3) + 0.000086 / pow(te, 5);
    } else if (elevation > -0.575) {
      correction = 1735.0 +
          elevation *
              (-518.2 +
                  elevation *
                      (103.4 + elevation * (-12.79 + 0.711 * elevation)));
    } else {
      correction = -20.774 / te;
    }
    return correction / 3600.0;
  }

  static double _getSunHourAngle(double latitude, double solarDeclination,
      double zenith, _SolarEvent solarEvent) {
    final double ratio =
        cosDeg(zenith) / (cosDeg(latitude) * cosDeg(solarDeclination)) -
            tanDeg(latitude) * tanDeg(solarDeclination);
    if (ratio < -1.0 || ratio > 1.0) {
      return double.nan;
    }
    final double hourAngle = acos(ratio);
    return solarEvent == _SolarEvent.sunset ? -hourAngle : hourAngle;
  }

  double _getJulianCenturiesFromJulianDay(double julianDayUT) {
    double jde = julianDayUT;
    if (_applyDeltaT) {
      jde += estimateDeltaT(julianDayUT) / 86400.0;
    }
    return (jde - julianDayJan1_2000) / julianDaysPerCentury;
  }

  static double _getSunDeclination(double julianCenturies) {
    final List<double> sun = _getSunApparentEclipticCoordinates(julianCenturies);
    final double lambda = sun[0];
    final double beta = sun[1];
    final double epsilon = _getTrueObliquity(julianCenturies);
    final double sinDec = sinDeg(beta) * cosDeg(epsilon) +
        cosDeg(beta) * sinDeg(epsilon) * sinDeg(lambda);
    return asinDeg(sinDec);
  }

  static double _getSunRightAscension(double julianCenturies) {
    final List<double> sun = _getSunApparentEclipticCoordinates(julianCenturies);
    final double lambda = sun[0];
    final double beta = sun[1];
    final double epsilon = _getTrueObliquity(julianCenturies);
    final double y =
        sinDeg(lambda) * cosDeg(epsilon) - tanDeg(beta) * sinDeg(epsilon);
    final double x = cosDeg(lambda);
    final double ra = degrees(atan2(y, x));
    return (ra.remainder(360) + 360).remainder(360);
  }

  static List<double> _getSunApparentEclipticCoordinates(
      double julianCenturies) {
    final double tau = julianCenturies / 10.0;
    final double earthLongitude = degrees(sumSeries(earthL, tau));
    final double earthLatitude = degrees(sumSeries(earthB, tau));
    final double earthRadius = sumSeries(earthR, tau);

    double theta = earthLongitude + 180.0;
    double beta = -earthLatitude;

    final double lambdaPrime = theta -
        1.397 * julianCenturies -
        0.00031 * julianCenturies * julianCenturies;
    final double deltaLongFK5 = -0.09033 +
        0.03916 *
            (cosDeg(lambdaPrime) + sinDeg(lambdaPrime)) *
            tanDeg(beta);
    final double deltaLatFK5 =
        0.03916 * (cosDeg(lambdaPrime) - sinDeg(lambdaPrime));
    theta += deltaLongFK5 / 3600.0;
    beta += deltaLatFK5 / 3600.0;

    final List<double> nut = _getNutation(julianCenturies);
    final double aberration = -20.4898 / earthRadius;
    final double lambda = theta + nut[0] / 3600.0 + aberration / 3600.0;

    return [(lambda.remainder(360) + 360).remainder(360), beta];
  }

  static double _getTrueObliquity(double julianCenturies) {
    final double seconds = 21.448 -
        julianCenturies *
            (46.8150 +
                julianCenturies * (0.00059 - julianCenturies * 0.001813));
    final double epsilon0 = 23.0 + (26.0 + (seconds / 60.0)) / 60.0;
    final double deltaEpsilon = _getNutation(julianCenturies)[1] / 3600.0;
    return epsilon0 + deltaEpsilon;
  }

  static List<double> _getNutation(double julianCenturies) {
    final double t = julianCenturies;
    final double omega =
        125.04452 - 1934.136261 * t + 0.0020708 * t * t + t * t * t / 450000.0;
    final double lSun = 280.4665 + 36000.7698 * t;
    final double lMoon = 218.3165 + 481267.8813 * t;
    final double deltaPsi = -17.20 * sinDeg(omega) -
        1.32 * sinDeg(2 * lSun) -
        0.23 * sinDeg(2 * lMoon) +
        0.21 * sinDeg(2 * omega);
    final double deltaEpsilon = 9.20 * cosDeg(omega) +
        0.57 * cosDeg(2 * lSun) +
        0.10 * cosDeg(2 * lMoon) -
        0.09 * cosDeg(2 * omega);
    return [deltaPsi, deltaEpsilon];
  }

  static double _getEquationOfTime(double julianCenturies) {
    final double tau = julianCenturies / 10.0;
    double l0 = 280.4664567 +
        tau *
            (360007.6982779 +
                tau *
                    (0.03032028 +
                        tau *
                            (1.0 / 49931.0 -
                                tau * (1.0 / 15300.0 + tau / 2000000.0))));
    l0 = (l0.remainder(360) + 360).remainder(360);
    final double alpha = _getSunRightAscension(julianCenturies);
    final List<double> nut = _getNutation(julianCenturies);
    final double epsilon = _getTrueObliquity(julianCenturies);
    double e = l0 - 0.0057183 - alpha + (nut[0] / 3600.0) * cosDeg(epsilon);
    e = ((e + 180).remainder(360) + 360).remainder(360) - 180;
    return e * 4.0;
  }
}
