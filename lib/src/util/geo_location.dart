/*
 * Zmanim Java API
 * Copyright (C) 2004-2018 Eliyahu Hershfeld
 *
 * This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General
 * Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 * You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA,
 * or connect to: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
 */

import 'dart:math';
import 'package:timezone/timezone.dart' as tz;
import 'package:vector_math/vector_math.dart';

import 'date_time_formatter.dart';
import 'java_double.dart';

/// A class that contains location information such as latitude and longitude required for astronomical calculations. The
/// elevation field may not be used by some calculation engines and would be ignored if set. Check the documentation for
/// specific implementations of the [AstronomicalCalculator] to see if elevation is calculated as part of the
/// algorithm.
///
/// © Eliyahu Hershfeld 2004 - 2018
class GeoLocation {
  /// See also [getLatitude].
  /// See also [setLatitude].
  /// See also [setLatitude].
  late double _latitude;

  /// See also [getLongitude].
  /// See also [setLongitude].
  /// See also [setLongitude].
  late double _longitude;
  late String _locationName;
  late tz.Location _zoneId;

  /// See also [getElevation].
  /// See also [setElevation].
  double _elevation = 0;

  /// Constant for a distance type calculation.
  /// See also [getGeodesicDistance].
  static const int _DISTANCE = 0;

  /// Constant for a initial bearing type calculation.
  /// See also [getGeodesicInitialBearing].
  static const int _INITIAL_BEARING = 1;

  /// Constant for a final bearing type calculation.
  /// See also [getGeodesicFinalBearing].
  static const int _FINAL_BEARING = 2;

  /// constant for milliseconds in a minute (60,000)
  static const int _MINUTE_MILLIS = 60 * 1000;

  /// constant for milliseconds in an hour (3,600,000)
  static const int _HOUR_MILLIS = _MINUTE_MILLIS * 60;

  /// Default GeoLocation constructor will set location to the Prime Meridian at Greenwich, England and a TimeZone of
  /// GMT. The longitude will be set to 0 and the latitude will be 51.4772 to match the location of the [Royal Observatory, Greenwich ](http://www.rog.nmm.ac.uk). No daylight savings time will be used.
  GeoLocation() {
    setLocationName("Greenwich, England");
    setLongitude(0);
    setLatitude(51.4772);
    setZoneId(tz.timeZoneDatabase.locations['GMT'] ??
        tz.Location('GMT', [tz.minTime], [0], [tz.TimeZone.UTC]));
  }

  GeoLocation.withZoneId(String name, double latitude, double longitude, tz.Location zoneId)
      : this.withElevation(name, latitude, longitude, 0, zoneId);

  /// GeoLocation constructor with parameters for all required fields.
  ///
  /// - [locationName]: 
  ///   The location name for display use such as "Lakewood, NJ"
  /// - [latitude]: 
  ///   the latitude in a double format such as 40.095965 for Lakewood, NJ.
  ///   **Note: ** For latitudes south of the equator, a negative value should be used.
  /// - [longitude]: 
  ///   double the longitude in a double format such as -74.222130 for Lakewood, NJ.
  ///   **Note: ** For longitudes east of the [Prime Meridian ](http://en.wikipedia.org/wiki/Prime_Meridian) (Greenwich), a negative value should be used.
  /// - [elevation]: 
  ///   the elevation above sea level in Meters. Elevation is not used in most algorithms used for calculating
  ///   sunrise and set.
  /// - [zoneId]: 
  ///   the zone for the location.
  GeoLocation.withElevation(
      String name, double latitude, double longitude, double elevation, tz.Location zoneId) {
    setLocationName(name);
    setLatitude(latitude);
    setLongitude(longitude);
    setElevation(elevation);
    setZoneId(zoneId);
  }

  /// Method to get the elevation in Meters.
  ///
  /// Returns the elevation in Meters.
  double getElevation() {
    return _elevation;
  }

  /// Method to set the elevation in Meters **above ** sea level.
  ///
  /// - [elevation]: 
  ///   The elevation to set in Meters. An IllegalArgumentException will be thrown if the value is a negative.
  void setElevation(double elevation) {
    if (elevation < 0) {
      throw ArgumentError("Elevation cannot be negative");
    }
    if (!elevation.isFinite) {
      throw ArgumentError("Elevation cannot be NaN or infinite");
    }
    _elevation = elevation;
  }

  void setLatitude(double latitude) {
    if (latitude > 90 || latitude < -90 || latitude.isNaN) {
      throw ArgumentError("Latitude must be between -90 and  90");
    }
    _latitude = latitude;
  }

  /// Returns the latitude.
  double getLatitude() {
    return _latitude;
  }

  void setLongitude(double longitude) {
    if (longitude > 180 || longitude < -180 || longitude.isNaN) {
      throw ArgumentError("Longitude must be between -180 and  180");
    }
    _longitude = longitude;
  }

  /// Returns the longitude.
  double getLongitude() {
    return _longitude;
  }

  /// Returns the location name.
  String getLocationName() {
    return _locationName;
  }

  /// - [name]: 
  ///   The setter method for the display name.
  void setLocationName(String name) {
    _locationName = name;
  }

  tz.Location getZoneId() => _zoneId;

  void setZoneId(tz.Location zoneId) {
    _zoneId = zoneId;
  }

  /// A method that will return the location's local mean time offset in milliseconds from local [standard time](http://en.wikipedia.org/wiki/Standard_time). The globe is split into 360°, with
  /// 15° per hour of the day. For a local that is at a longitude that is evenly divisible by 15 (longitude % 15 ==
  /// 0), at solar [AstronomicalCalendar.getSunTransit] (with adjustment for the [equation of time](http://en.wikipedia.org/wiki/Equation_of_time)) the sun should be directly overhead,
  /// so a user who is 1° west of this will have noon at 4 minutes after standard time noon, and conversely, a user
  /// who is 1° east of the 15° longitude will have noon at 11:56 AM. Lakewood, N.J., whose longitude is
  /// -74.2094, is 0.7906 away from the closest multiple of 15 at -75°. This is multiplied by 4 to yield 3 minutes
  /// and 10 seconds earlier than standard time. The offset returned does not account for the [Daylight saving time](http://en.wikipedia.org/wiki/Daylight_saving_time) offset since this class is
  /// unaware of dates.
  ///
  /// Returns the offset in milliseconds not accounting for Daylight saving time. A positive value will be returned
  /// East of the 15° timezone line, and a negative value West of it.
  int getLocalMeanTimeOffset(DateTime instant) {
    final int timezoneOffsetMillis =
        tz.TZDateTime.from(instant, _zoneId).timeZoneOffset.inSeconds * 1000;
    return (getLongitude() * 4 * _MINUTE_MILLIS - timezoneOffsetMillis).truncate();
  }

  /// Adjust the date for [antimeridian](https://en.wikipedia.org/wiki/180th_meridian) crossover. This is
  /// needed to deal with edge cases such as Samoa that use a different calendar date than expected based on their
  /// geographic location.
  ///
  /// The actual Time Zone offset may deviate from the expected offset based on the longitude. Since the 'absolute time'
  /// calculations are always based on longitudinal offset from UTC for a given date, the date is presumed to only
  /// increase East of the Prime Meridian, and to only decrease West of it. For Time Zones that cross the antimeridian,
  /// the date will be artificially adjusted before calculation to conform with this presumption.
  ///
  /// For example, Apia, Samoa with a longitude of -171.75 uses a local offset of +14:00.  When calculating sunrise for
  /// 2018-02-03, the calculator should operate using 2018-02-02 since the expected zone is -11.  After determining the
  /// UTC time, the local DST offset of [UTC+14:00](https://en.wikipedia.org/wiki/UTC%2B14:00) should be applied
  /// to bring the date back to 2018-02-03.
  ///
  /// Returns the number of days to adjust the date This will typically be 0 unless the date crosses the antimeridian
  int getAntimeridianAdjustment(DateTime instant) {
    double localHoursOffset = getLocalMeanTimeOffset(instant) / _HOUR_MILLIS;

    if (localHoursOffset >= 20) {
      // if the offset is 20 hours or more in the future (never expected anywhere other
      // than a location using a timezone across the anti meridian to the east such as Samoa)
      return 1; // roll the date forward a day
    } else if (localHoursOffset <= -20) {
      // if the offset is 20 hours or more in the past (no current location is known
      //that crosses the antimeridian to the west, but better safe than sorry)
      return -1; // roll the date back a day
    }
    return 0; //99.999% of the world will have no adjustment
  }

  /// Calculate the initial [geodesic](http://en.wikipedia.org/wiki/Great_circle) bearing between this
  /// Object and a second Object passed to this method using [Thaddeus Vincenty's](http://en.wikipedia.org/wiki/Thaddeus_Vincenty) inverse formula See T Vincenty, "[Direct and Inverse Solutions of Geodesics on the Ellipsoid with application of nested equations](http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf)", Survey Review, vol XXII no 176, 1975
  ///
  /// - [location]: 
  ///   the destination location
  /// Returns the initial bearing
  double getGeodesicInitialBearing(GeoLocation location) {
    return _vincentyInverseFormula(location, _INITIAL_BEARING);
  }

  /// Calculate the final [geodesic](http://en.wikipedia.org/wiki/Great_circle) bearing between this Object
  /// and a second Object passed to this method using [Thaddeus Vincenty's](http://en.wikipedia.org/wiki/Thaddeus_Vincenty) inverse formula See T Vincenty, "[Direct and Inverse Solutions of Geodesics on the Ellipsoid with application of nested equations](http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf)", Survey Review, vol
  /// XXII no 176, 1975
  ///
  /// - [location]: 
  ///   the destination location
  /// Returns the final bearing
  double getGeodesicFinalBearing(GeoLocation location) {
    return _vincentyInverseFormula(location, _FINAL_BEARING);
  }

  /// Calculate [geodesic distance](http://en.wikipedia.org/wiki/Great-circle_distance) in Meters between
  /// this Object and a second Object passed to this method using [Thaddeus Vincenty's](http://en.wikipedia.org/wiki/Thaddeus_Vincenty) inverse formula See T Vincenty, "[Direct and Inverse Solutions of Geodesics on the Ellipsoid with application of nested equations](http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf)", Survey Review, vol XXII no 176, 1975
  ///
  /// - [location]: 
  ///   the destination location
  /// Returns the geodesic distance in Meters
  double getGeodesicDistance(GeoLocation location) {
    return _vincentyInverseFormula(location, _DISTANCE);
  }

  /// Calculate [geodesic distance](http://en.wikipedia.org/wiki/Great-circle_distance) in Meters between
  /// this Object and a second Object passed to this method using [Thaddeus Vincenty's](http://en.wikipedia.org/wiki/Thaddeus_Vincenty) inverse formula See T Vincenty, "[Direct and Inverse Solutions of Geodesics on the Ellipsoid with application of nested equations](http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf)", Survey Review, vol XXII no 176, 1975
  ///
  /// - [location]: 
  ///   the destination location
  /// - [formula]: 
  ///   This formula calculates initial bearing ([INITIAL_BEARING]), final bearing (
  ///   [FINAL_BEARING]) and distance ([DISTANCE]).
  /// Returns geodesic distance in Meters
  double _vincentyInverseFormula(GeoLocation location, int formula) {
    double a = 6378137;
    double b = 6356752.3142;
    double f = 1 / 298.257223563; // WGS-84 ellipsiod
    double L = radians(location.getLongitude() - getLongitude());
    double u1 = atan((1 - f) * tan(radians(getLatitude())));
    double u2 = atan((1 - f) * tan(radians(location.getLatitude())));
    double sinU1 = sin(u1), cosU1 = cos(u1);
    double sinU2 = sin(u2), cosU2 = cos(u2);

    double lambda = L;
    double lambdaP = 2 * pi;
    double iterLimit = 20;
    double sinLambda = 0;
    double cosLambda = 0;
    double sinSigma = 0;
    double cosSigma = 0;
    double sigma = 0;
    double sinAlpha = 0;
    double cosSqAlpha = 0;
    double cos2SigmaM = 0;
    double C;
    while ((lambda - lambdaP).abs() > 1e-12 && --iterLimit > 0) {
      sinLambda = sin(lambda);
      cosLambda = cos(lambda);
      sinSigma = sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) +
          (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
              (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
      if (sinSigma == 0) return 0; // co-incident points
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = atan2(sinSigma, cosSigma);
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1 - sinAlpha * sinAlpha;
      cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
      if (cos2SigmaM.isNaN) {
        cos2SigmaM = 0;
      } // equatorial line: cosSqAlpha=0 (§6)
      C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
      lambdaP = lambda;
      lambda = L +
          (1 - C) *
              f *
              sinAlpha *
              (sigma +
                  C *
                      sinSigma *
                      (cos2SigmaM +
                          C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    }
    if (iterLimit == 0) return double.nan; // formula failed to converge

    double uSq = cosSqAlpha * (a * a - b * b) / (b * b);
    double A =
        1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    double B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
    double deltaSigma = B *
        sinSigma *
        (cos2SigmaM +
            B /
                4 *
                (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                    B /
                        6 *
                        cos2SigmaM *
                        (-3 + 4 * sinSigma * sinSigma) *
                        (-3 + 4 * cos2SigmaM * cos2SigmaM)));
    double distance = b * A * (sigma - deltaSigma);

    // initial bearing
    double fwdAz = degrees(
        atan2(cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
    // final bearing
    double revAz = degrees(
        atan2(cosU1 * sinLambda, -sinU1 * cosU2 + cosU1 * sinU2 * cosLambda));
    if (formula == _DISTANCE) {
      return distance;
    } else if (formula == _INITIAL_BEARING) {
      return fwdAz;
    } else if (formula == _FINAL_BEARING) {
      return revAz;
    } else {
      // should never happen
      return double.nan;
    }
  }

  /// Returns the [rhumb line](http://en.wikipedia.org/wiki/Rhumb_line) bearing from the current location to
  /// the GeoLocation passed in.
  ///
  /// - [location]: 
  ///   destination location
  /// Returns the bearing in degrees
  double getRhumbLineBearing(GeoLocation location) {
    double dLon = radians(location.getLongitude() - getLongitude());
    double dPhi = log(tan(radians(location.getLatitude()) / 2 + pi / 4) /
        tan(radians(getLatitude()) / 2 + pi / 4));
    if (dLon.abs() > pi) dLon = dLon > 0 ? -(2 * pi - dLon) : (2 * pi + dLon);
    return degrees(atan2(dLon, dPhi));
  }

  /// Returns the [rhumb line](http://en.wikipedia.org/wiki/Rhumb_line) distance from the current location
  /// to the GeoLocation passed in.
  ///
  /// - [location]: 
  ///   the destination location
  /// Returns the distance in Meters
  double getRhumbLineDistance(GeoLocation location) {
    double earthRadius = 6378137; // Earth's radius in meters (WGS-84)
    double dLat = radians(location.getLatitude()) - radians(getLatitude());
    double dLon =
        (radians(location.getLongitude()) - radians(getLongitude())).abs();
    double dPhi = log(tan(radians(location.getLatitude()) / 2 + pi / 4) /
        tan(radians(getLatitude()) / 2 + pi / 4));
    double q = dLat / dPhi;

    if (!(q.abs() <= double.maxFinite)) {
      q = cos(radians(getLatitude()));
    }
    // if dLon over 180° take shorter rhumb across 180° meridian:
    if (dLon > pi) {
      dLon = 2 * pi - dLon;
    }
    double d = sqrt(dLat * dLat + q * q * dLon * dLon);
    return d * earthRadius;
  }

  String toXML() {
    return '<GeoLocation>\n'
        '\t<LocationName>${getLocationName()}</LocationName>\n'
        '\t<Latitude>${javaDouble(getLatitude())}</Latitude>\n'
        '\t<Longitude>${javaDouble(getLongitude())}</Longitude>\n'
        '\t<Elevation>${javaDouble(getElevation())} Meters</Elevation>\n'
        '\t<TimezoneName>${getZoneId().name}</TimezoneName>\n'
        '\t<TimeZoneDisplayName>${zoneGenericName(getZoneId())}</TimeZoneDisplayName>\n'
        '</GeoLocation>';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! GeoLocation || other.runtimeType != runtimeType) {
      return false;
    }
    return _latitude.compareTo(other._latitude) == 0 &&
        _longitude.compareTo(other._longitude) == 0 &&
        _elevation.compareTo(other._elevation) == 0 &&
        _locationName == other._locationName &&
        _zoneId.name == other._zoneId.name;
  }

  @override
  int get hashCode => Object.hash(runtimeType, _latitude, _longitude, _elevation, _locationName, _zoneId.name);

  @override
  String toString() {
    final degrees = String.fromCharCode(0xB0);
    return '\nLocation Name:\t\t\t${getLocationName()}'
        '\nLatitude:\t\t\t${javaDouble(getLatitude())}$degrees'
        '\nLongitude:\t\t\t${javaDouble(getLongitude())}$degrees'
        '\nElevation:\t\t\t${javaDouble(getElevation())} Meters'
        '\nTimezone ID:\t\t\t${getZoneId().name}'
        '\nTimezone Display Name:\t\t${zoneGenericName(getZoneId())}';
  }

  /// Create clone of this GeoLocation
  GeoLocation clone() =>
      GeoLocation.withElevation(getLocationName(), getLatitude(), getLongitude(), getElevation(), getZoneId());
}
