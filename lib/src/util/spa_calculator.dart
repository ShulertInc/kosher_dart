import 'dart:math';

import 'package:kosher_dart/src/util/astronomical_calculator.dart';
import 'package:kosher_dart/src/util/geo_location.dart';
import 'package:kosher_dart/src/util/vsop87_earth.dart';
import 'package:vector_math/vector_math.dart';

enum _SolarEvent { sunrise, sunset, noon, midnight }

class SPACalculator extends AstronomicalCalculator {
  bool _applyDeltaT = true;
  double? _deltaTOverride;
  double _pressure = 1013.25;
  double _temperature = 10.0;

  @override
  SPACalculator clone() => copyCalculatorSettings(this, SPACalculator())
    .._applyDeltaT = _applyDeltaT
    .._deltaTOverride = _deltaTOverride
    .._pressure = _pressure
    .._temperature = _temperature;

  @override
  String getCalculatorName() => "NREL Solar Position Algorithm";

  void setApplyDeltaT(bool applyDeltaT) {
    _applyDeltaT = applyDeltaT;
  }

  bool isApplyDeltaT() => _applyDeltaT;

  void setDeltaTOverride(double? deltaTSeconds) {
    _deltaTOverride = deltaTSeconds;
  }

  double? getDeltaTOverride() => _deltaTOverride;

  void setPressure(double pressureMillibars) {
    _pressure = pressureMillibars;
  }

  double getPressure() => _pressure;

  void setTemperature(double temperatureCelsius) {
    _temperature = temperatureCelsius;
  }

  double getTemperature() => _temperature;

  @override
  bool operator ==(Object other) {
    if (super != other) {
      return false;
    }
    final SPACalculator spa = other as SPACalculator;
    return _applyDeltaT == spa._applyDeltaT &&
        (_deltaTOverride == null
            ? spa._deltaTOverride == null
            : spa._deltaTOverride != null && _deltaTOverride!.compareTo(spa._deltaTOverride!) == 0) &&
        _pressure.compareTo(spa._pressure) == 0 &&
        _temperature.compareTo(spa._temperature) == 0;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, _applyDeltaT, _deltaTOverride, _pressure, _temperature);

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
    final double riseSet =
        _solveRiseSet(dateTime, geoLocation, adjustedZenith, solarEvent);
    if (riseSet.isNaN) {
      return double.nan;
    }
    return _normalizeHours(riseSet / 60);
  }

  static double _normalizeHours(double hours) =>
      (hours.remainder(24) + 24).remainder(24);

  double _solveRiseSet(DateTime dateTime, GeoLocation geoLocation,
      double adjustedZenith, _SolarEvent solarEvent) {
    final double jdDay = julianDayOfDate(dateTime);
    final double lonWest = -geoLocation.getLongitude();
    final double lat = geoLocation.getLatitude();
    final double longitude = geoLocation.getLongitude();
    final double elevation = geoLocation.getElevation();

    final double noonMin = _solveNoonMidnight(jdDay, lonWest, _SolarEvent.noon);
    final double declNoon = _solarCoords(jdDay + noonMin / 1440.0)[1];
    final double eot = _equationOfTime(jdDay + noonMin / 1440.0);
    final double cosH0 =
        (cosDeg(adjustedZenith) - sinDeg(lat) * sinDeg(declNoon)) /
            (cosDeg(lat) * cosDeg(declNoon));
    if (cosH0 < -1.0 || cosH0 > 1.0) {
      return double.nan;
    }
    final double h0 = acosDeg(cosH0);
    final double signed = solarEvent == _SolarEvent.sunrise ? h0 : -h0;
    final double guess = 720 + 4 * (lonWest - signed) - eot;

    double t0 = guess;
    double t1 = guess + 0.5;
    double f0 = _topocentricTrueZenith(
            jdDay + t0 / 1440.0, lat, longitude, elevation) -
        adjustedZenith;
    double f1 = _topocentricTrueZenith(
            jdDay + t1 / 1440.0, lat, longitude, elevation) -
        adjustedZenith;
    for (int i = 0; i < 12 && f1.abs() > 1e-9; i++) {
      final double denom = f1 - f0;
      if (denom == 0) {
        break;
      }
      final double t2 = t1 - f1 * (t1 - t0) / denom;
      t0 = t1;
      f0 = f1;
      t1 = t2;
      f1 = _topocentricTrueZenith(
              jdDay + t1 / 1440.0, lat, longitude, elevation) -
          adjustedZenith;
    }
    return t1;
  }

  @override
  double getUTCNoon(DateTime dateTime, GeoLocation geoLocation) =>
      _normalizeHours(_solveNoonMidnight(julianDayOfDate(dateTime),
              -geoLocation.getLongitude(), _SolarEvent.noon) /
          60);

  @override
  double getUTCMidnight(DateTime dateTime, GeoLocation geoLocation) =>
      _normalizeHours(_solveNoonMidnight(julianDayOfDate(dateTime),
              -geoLocation.getLongitude(), _SolarEvent.midnight) /
          60);

  double _solveNoonMidnight(
      double julianDay, double lonWest, _SolarEvent solarEvent) {
    final double lonEast = -lonWest;
    final double targetHourAngle = solarEvent == _SolarEvent.noon ? 0.0 : 180.0;
    double dayFraction =
        (solarEvent == _SolarEvent.noon ? 0.5 : 1.0) - lonEast / 360.0;
    for (int i = 0; i < 3; i++) {
      final List<double> sc = _solarCoords(julianDay + dayFraction);
      final double alpha = sc[0];
      final double nu = sc[3];
      final double hourAngle =
          ((nu + lonEast - alpha - targetHourAngle).remainder(360) + 540)
                  .remainder(360) -
              180;
      dayFraction -= hourAngle / 360.0;
    }
    return dayFraction * 1440.0;
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
    for (int i = 0; i < 4; i++) {
      final double jd = julianDay + dayFraction;
      final double decl = _solarCoords(jd)[1];
      final double ratio = tanDeg(decl) / tanDeg(geoLocation.getLatitude());
      if (ratio.isNaN || ratio > 1.0 || ratio < -1.0) {
        return double.nan;
      }
      final double offset =
          (azimuth == 90.0 ? -1.0 : 1.0) * (acosDeg(ratio) / 360.0);
      dayFraction = solarNoonBase + offset - (_equationOfTime(jd) / 1440.0);
    }
    return _normalizeHours(dayFraction * 24.0);
  }

  @override
  double getSolarElevation(DateTime instant, GeoLocation geoLocation) =>
      _topocentric(julianDayOfInstant(instant), geoLocation.getLatitude(),
          geoLocation.getLongitude(), geoLocation.getElevation())[1];

  @override
  double getSolarAzimuth(DateTime instant, GeoLocation geoLocation) =>
      _topocentric(julianDayOfInstant(instant), geoLocation.getLatitude(),
          geoLocation.getLongitude(), geoLocation.getElevation())[2];

  double _deltaTSeconds(double julianDayUT) => _applyDeltaT
      ? (_deltaTOverride ?? estimateDeltaT(julianDayUT))
      : 0.0;

  List<double> _solarCoords(double julianDayUT) {
    final double deltaTSeconds = _deltaTSeconds(julianDayUT);
    final double jde = julianDayUT + deltaTSeconds / 86400.0;
    final double jce = (jde - julianDayJan1_2000) / julianDaysPerCentury;
    final double jc = (julianDayUT - julianDayJan1_2000) / julianDaysPerCentury;
    final double jme = jce / 10.0;

    final double earthLongitude = degrees(sumSeries(earthL, jme));
    final double earthLatitude = degrees(sumSeries(earthB, jme));
    final double radius = sumSeries(earthR, jme);

    final double theta = (earthLongitude + 180.0).remainder(360.0);
    final double beta = -earthLatitude;

    final List<double> nut = _nutation(jce);
    final double epsilon = _meanObliquity(jme) + nut[1];
    final double aberration = -20.4898 / (3600.0 * radius);
    final double lambda = theta + nut[0] + aberration;

    double nu0 = 280.46061837 +
        360.98564736629 * (julianDayUT - julianDayJan1_2000) +
        0.000387933 * jc * jc -
        jc * jc * jc / 38710000.0;
    nu0 = (nu0.remainder(360) + 360).remainder(360);
    final double nu = nu0 + nut[0] * cosDeg(epsilon);

    double alpha = degrees(atan2(
        sinDeg(lambda) * cosDeg(epsilon) - tanDeg(beta) * sinDeg(epsilon),
        cosDeg(lambda)));
    alpha = (alpha.remainder(360) + 360).remainder(360);
    final double delta = asinDeg(sinDeg(beta) * cosDeg(epsilon) +
        cosDeg(beta) * sinDeg(epsilon) * sinDeg(lambda));

    return [alpha, delta, epsilon, nu, radius, lambda];
  }

  List<double> _topocentric(double julianDayUT, double latitude,
      double longitude, double elevationMeters) {
    final List<double> sc = _solarCoords(julianDayUT);
    final double alpha = sc[0], delta = sc[1], nu = sc[3], radius = sc[4];

    double h = (nu + longitude - alpha).remainder(360.0);
    h = (h + 360).remainder(360);

    final double xi = 8.794 / (3600.0 * radius);
    final double u = atan(0.99664719 * tanDeg(latitude));
    final double x = cos(u) + (elevationMeters / 6378140.0) * cosDeg(latitude);
    final double y = 0.99664719 * sin(u) +
        (elevationMeters / 6378140.0) * sinDeg(latitude);

    final double deltaAlpha = degrees(atan2(-x * sinDeg(xi) * sinDeg(h),
        cosDeg(delta) - x * sinDeg(xi) * cosDeg(h)));
    final double deltaPrime = degrees(atan2(
        (sinDeg(delta) - y * sinDeg(xi)) * cosDeg(deltaAlpha),
        cosDeg(delta) - x * sinDeg(xi) * cosDeg(h)));
    final double hPrime = h - deltaAlpha;

    final double e0 = asinDeg(sinDeg(latitude) * sinDeg(deltaPrime) +
        cosDeg(latitude) * cosDeg(deltaPrime) * cosDeg(hPrime));

    final double deltaE = _refractionCorrection(e0);
    final double e = e0 + deltaE;

    final double gamma = degrees(atan2(sinDeg(hPrime),
        cosDeg(hPrime) * sinDeg(latitude) - tanDeg(deltaPrime) * cosDeg(latitude)));
    double azimuth = (gamma + 180.0).remainder(360.0);
    azimuth = (azimuth + 360).remainder(360);

    return [e0, e, azimuth];
  }

  double _topocentricTrueZenith(double julianDayUT, double latitude,
          double longitude, double elevationMeters) =>
      90.0 -
      _topocentric(julianDayUT, latitude, longitude, elevationMeters)[0];

  double _refractionCorrection(double trueElevation) {
    final double atmosRefract = getRefraction();
    final double sunRadius = getSolarRadius();
    if (trueElevation < -1.0 * (sunRadius + atmosRefract)) {
      return 0.0;
    }
    return (_pressure / 1010.0) *
        (283.0 / (273.0 + _temperature)) *
        1.02 /
        (60.0 * tanDeg(trueElevation + 10.3 / (trueElevation + 5.11)));
  }

  double _equationOfTime(double julianDayUT) {
    final List<double> sc = _solarCoords(julianDayUT);
    final double alpha = sc[0], epsilon = sc[2];
    final double deltaTSeconds = _deltaTSeconds(julianDayUT);
    final double jme = ((julianDayUT + deltaTSeconds / 86400.0) -
            julianDayJan1_2000) /
        julianDaysPerCentury /
        10.0;
    double l0 = 280.4664567 +
        jme *
            (360007.6982779 +
                jme *
                    (0.03032028 +
                        jme *
                            (1.0 / 49931.0 -
                                jme * (1.0 / 15300.0 + jme / 2000000.0))));
    l0 = (l0.remainder(360) + 360).remainder(360);
    final double deltaPsi = _nutation(
        ((julianDayUT + deltaTSeconds / 86400.0) - julianDayJan1_2000) /
            julianDaysPerCentury)[0];
    double e = l0 - 0.0057183 - alpha + deltaPsi * cosDeg(epsilon);
    e = ((e + 180).remainder(360) + 360).remainder(360) - 180;
    return e * 4.0;
  }

  static double _meanObliquity(double jme) {
    final double u = jme / 10.0;
    final double seconds = 84381.448 -
        4680.93 * u -
        1.55 * u * u +
        1999.25 * pow(u, 3) -
        51.38 * pow(u, 4) -
        249.67 * pow(u, 5) -
        39.05 * pow(u, 6) +
        7.12 * pow(u, 7) +
        27.87 * pow(u, 8) +
        5.79 * pow(u, 9) +
        2.45 * pow(u, 10);
    return seconds / 3600.0;
  }

  static List<double> _nutation(double jce) {
    final double t = jce;
    final double omega =
        125.04452 - 1934.136261 * t + 0.0020708 * t * t + t * t * t / 450000.0;
    final double lSun = 280.4665 + 36000.7698 * t;
    final double lMoon = 218.3165 + 481267.8813 * t;
    final double deltaPsiArcsec = -17.20 * sinDeg(omega) -
        1.32 * sinDeg(2 * lSun) -
        0.23 * sinDeg(2 * lMoon) +
        0.21 * sinDeg(2 * omega);
    final double deltaEpsArcsec = 9.20 * cosDeg(omega) +
        0.57 * cosDeg(2 * lSun) +
        0.10 * cosDeg(2 * lMoon) -
        0.09 * cosDeg(2 * omega);
    return [deltaPsiArcsec / 3600.0, deltaEpsArcsec / 3600.0];
  }
}
