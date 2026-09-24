/*
 * Zmanim Java API
 * Copyright (C) 2004-2020 Eliyahu Hershfeld
 *
 * This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General
 * Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 * You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA,
 * or connect to: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
 */

import 'dart:core';

import 'package:kosher_dart/src/util/astronomical_calculator.dart';
import 'package:kosher_dart/src/util/date_time_formatter.dart';
import 'package:kosher_dart/src/util/geo_location.dart';
import 'package:kosher_dart/src/util/omitted.dart';
import 'package:kosher_dart/src/util/zmanim_formatter.dart';
import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

enum SolarEvent { SUNRISE, SUNSET, NOON, MIDNIGHT }

/// A calendar that calculates astronomical times such as [getSunrise], [getSunset] and twilight times for the
/// [getLocalDate] it holds. The calculation engine used to calculate the astronomical times can be
/// changed to a different implementation by implementing the abstract [AstronomicalCalculator] and setting it with
/// the [setAstronomicalCalculator]. A number of different calculation engine
/// implementations are included in the util package.
/// **Note:** There are times when the algorithms can't calculate proper values for sunrise, sunset and twilight. This
/// is usually caused by trying to calculate times for areas either very far North or South, where sunrise / sunset never
/// happen on that date. This is common when calculating twilight with a deep dip below the horizon for locations as far
/// south of the North Pole as London, in the northern hemisphere. The sun never reaches this dip at certain times of the
/// year. When the calculations encounter this condition a null will be returned when a
/// [DateTime] is expected and double.nan when a `long` is expected. The
/// reason that `Exception`s are not thrown in these cases is because the lack of a rise/set or twilight is
/// not an exception, but an expected condition in many parts of the world.
///
/// Here is a simple example of how to use the API to calculate sunrise.
/// First create the Calendar for the location you would like to calculate sunrise or sunset times for:
///
///
/// ```dart
///  String locationName = "Lakewood, NJ";
///  double latitude = 40.0828; // Lakewood, NJ
///  double longitude = -74.2094; // Lakewood, NJ
///  double elevation = 20; // optional elevation correction in Meters
///  tz.Location zoneId = tz.getLocation("America/New_York");
///  GeoLocation location = GeoLocation.withElevation(locationName, latitude, longitude, elevation, zoneId);
///  AstronomicalCalendar ac = AstronomicalCalendar.withGeoLocation(location);
/// ```
///
/// To get the time of sunrise, first set the date you want (if not set, the date will default to today):
///
///
/// ```dart
///  ac.setLocalDate(DateTime.utc(2024, 2, 8));
///  DateTime? sunrise = ac.getSunrise();
/// ```
///
///
/// © Eliyahu Hershfeld 2004 - 2020
class AstronomicalCalendar {
  /// 90° below the vertical. Used as a basis for most calculations since the location of the sun is 90° below
  /// the horizon at sunrise and sunset.
  /// **Note **: it is important to note that for sunrise and sunset the [AstronomicalCalculator.adjustZenith] is required to account for the radius of the sun and refraction. The adjusted zenith should not
  /// be used for calculations above or below 90° since they are usually calculated as an offset to 90°.
  static const double GEOMETRIC_ZENITH = 90;

  /// Default value for Sun's zenith and true rise/set Zenith (used in this class and subclasses) is the angle that the
  /// center of the Sun makes to a line perpendicular to the Earth's surface. If the Sun were a point and the Earth
  /// were without an atmosphere, true sunset and sunrise would correspond to a 90° zenith. Because the Sun is not
  /// a point, and because the atmosphere refracts light, this 90° zenith does not, in fact, correspond to true
  /// sunset or sunrise, instead the center of the Sun's disk must lie just below the horizon for the upper edge to be
  /// obscured. This means that a zenith of just above 90° must be used. The Sun subtends an angle of 16 minutes of
  /// arc (this can be changed via the [setSunRadius] method , and atmospheric refraction accounts for
  /// 34 minutes or so (this can be changed via the [setRefraction] method), giving a total of 50
  /// arcminutes. The total value for ZENITH is 90+(5/6) or 90.8333333° for true sunrise/sunset.
  // public static double ZENITH = GEOMETRIC_ZENITH + 5.0 / 6.0;
  /// Sun's zenith at civil twilight (96°).
  static const double CIVIL_ZENITH = 96;

  /// Sun's zenith at nautical twilight (102°).
  static const double NAUTICAL_ZENITH = 102;

  /// Sun's zenith at astronomical twilight (108°).
  static const double ASTRONOMICAL_ZENITH = 108;

  static const int MINUTE_NANOS = 60 * 1000 * 1000 * 1000;

  static const int HOUR_NANOS = MINUTE_NANOS * 60;

  late DateTime _localDate;

  late GeoLocation _geoLocation;

  late AstronomicalCalculator _astronomicalCalculator;

  /// The getSunrise method Returns a `Date` representing the
  /// [AstronomicalCalculator.getElevationAdjustment] sunrise time. The zenith used
  /// for the calculation uses [GEOMETRIC_ZENITH] of 90° plus
  /// [AstronomicalCalculator.getElevationAdjustment]. This is adjusted by the
  /// [AstronomicalCalculator] to add approximately 50/60 of a degree to account for 34 archminutes of refraction
  /// and 16 archminutes for the sun's radius for a total of [AstronomicalCalculator.adjustZenith].
  /// See documentation for the specific implementation of the [AstronomicalCalculator] that you are using.
  ///
  /// Returns the `Date` representing the exact sunrise time. If the calculation can't be computed such as
  /// in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  /// does not set, a null will be returned. See detailed explanation on top of the page.
  /// See also [AstronomicalCalculator.adjustZenith].
  /// See also [getSeaLevelSunrise].
  /// See also [AstronomicalCalendar.getUTCSunrise].
  DateTime? getSunrise() {
    double sunrise = getUTCSunrise(GEOMETRIC_ZENITH);
    if (sunrise.isNaN) {
      return null;
    } else {
      return getInstantFromTime(sunrise, SolarEvent.SUNRISE);
    }
  }

  /// A method that returns the sunrise without [AstronomicalCalculator.getElevationAdjustment]. Non-sunrise and sunset calculations such as dawn and dusk, depend on the amount of visible light,
  /// something that is not affected by elevation. This method returns sunrise calculated at sea level. This forms the
  /// base for dawn calculations that are calculated as a dip below the horizon before sunrise.
  ///
  /// Returns the `Date` representing the exact sea-level sunrise time. If the calculation can't be computed
  /// such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  /// where it does not set, a null will be returned. See detailed explanation on top of the page.
  /// See also [AstronomicalCalendar.getSunrise].
  /// See also [AstronomicalCalendar.getUTCSeaLevelSunrise].
  /// See also [getSeaLevelSunset].
  DateTime? getSeaLevelSunrise() {
    double sunrise = getUTCSeaLevelSunrise(GEOMETRIC_ZENITH);
    if (sunrise.isNaN) {
      return null;
    } else {
      return getInstantFromTime(sunrise, SolarEvent.SUNRISE);
    }
  }

  /// A method that returns the beginning of civil twilight (dawn) using a zenith of [CIVIL_ZENITH].
  ///
  /// Returns The `Date` of the beginning of civil twilight using a zenith of 96°. If the calculation
  /// can't be computed, null will be returned. See detailed explanation on top of the page.
  /// See also [CIVIL_ZENITH].
  DateTime? getBeginCivilTwilight() {
    return getSunriseOffsetByDegrees(CIVIL_ZENITH);
  }

  /// A method that returns the beginning of nautical twilight using a zenith of [NAUTICAL_ZENITH].
  ///
  /// Returns The `Date` of the beginning of nautical twilight using a zenith of 102°. If the
  /// calculation can't be computed null will be returned. See detailed explanation on top of the page.
  /// See also [NAUTICAL_ZENITH].
  DateTime? getBeginNauticalTwilight() {
    return getSunriseOffsetByDegrees(NAUTICAL_ZENITH);
  }

  /// A method that returns the beginning of astronomical twilight using a zenith of [ASTRONOMICAL_ZENITH].
  ///
  /// Returns The `Date` of the beginning of astronomical twilight using a zenith of 108°. If the
  /// calculation can't be computed, null will be returned. See detailed explanation on top of the page.
  /// See also [ASTRONOMICAL_ZENITH].
  DateTime? getBeginAstronomicalTwilight() {
    return getSunriseOffsetByDegrees(ASTRONOMICAL_ZENITH);
  }

  /// The getSunset method Returns a `Date` representing the
  /// [AstronomicalCalculator.getElevationAdjustment] sunset time. The zenith used for
  /// the calculation uses [GEOMETRIC_ZENITH] of 90° plus
  /// [AstronomicalCalculator.getElevationAdjustment]. This is adjusted by the
  /// [AstronomicalCalculator] to add approximately 50/60 of a degree to account for 34 archminutes of refraction
  /// and 16 archminutes for the sun's radius for a total of [AstronomicalCalculator.adjustZenith].
  /// See documentation for the specific implementation of the [AstronomicalCalculator] that you are using. Note:
  /// In certain cases the calculates sunset will occur before sunrise. This will typically happen when a timezone
  /// other than the local timezone is used (calculating Los Angeles sunset using a GMT timezone for example). In this
  /// case the sunset date will be incremented to the following date.
  ///
  /// Returns the `Date` representing the exact sunset time. If the calculation can't be computed such as in
  /// the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  /// does not set, a null will be returned. See detailed explanation on top of the page.
  /// See also [AstronomicalCalculator.adjustZenith].
  /// See also [getSeaLevelSunset].
  /// See also [AstronomicalCalendar.getUTCSunset].
  DateTime? getSunset() {
    double sunset = getUTCSunset(GEOMETRIC_ZENITH);
    if (sunset.isNaN) {
      return null;
    } else {
      return getInstantFromTime(sunset, SolarEvent.SUNSET);
    }
  }

  /// A method that returns the sunset without [AstronomicalCalculator.getElevationAdjustment]. Non-sunrise and sunset calculations such as dawn and dusk, depend on the amount of visible light,
  /// something that is not affected by elevation. This method returns sunset calculated at sea level. This forms the
  /// base for dusk calculations that are calculated as a dip below the horizon after sunset.
  ///
  /// Returns the `Date` representing the exact sea-level sunset time. If the calculation can't be computed
  /// such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  /// where it does not set, a null will be returned. See detailed explanation on top of the page.
  /// See also [AstronomicalCalendar.getSunset].
  /// See also [AstronomicalCalendar.getUTCSeaLevelSunset 2see [getSunset]].
  DateTime? getSeaLevelSunset() {
    double sunset = getUTCSeaLevelSunset(GEOMETRIC_ZENITH);
    if (sunset.isNaN) {
      return null;
    } else {
      return getInstantFromTime(sunset, SolarEvent.SUNSET);
    }
  }

  /// A method that returns the end of civil twilight using a zenith of [CIVIL_ZENITH].
  ///
  /// Returns The `Date` of the end of civil twilight using a zenith of [CIVIL_ZENITH]. If
  /// the calculation can't be computed, null will be returned. See detailed explanation on top of the page.
  /// See also [CIVIL_ZENITH].
  DateTime? getEndCivilTwilight() {
    return getSunsetOffsetByDegrees(CIVIL_ZENITH);
  }

  /// A method that returns the end of nautical twilight using a zenith of [NAUTICAL_ZENITH].
  ///
  /// Returns The `Date` of the end of nautical twilight using a zenith of [NAUTICAL_ZENITH]
  /// . If the calculation can't be computed, null will be returned. See detailed explanation on top of the
  /// page.
  /// See also [NAUTICAL_ZENITH].
  DateTime? getEndNauticalTwilight() {
    return getSunsetOffsetByDegrees(NAUTICAL_ZENITH);
  }

  /// A method that returns the end of astronomical twilight using a zenith of [ASTRONOMICAL_ZENITH].
  ///
  /// Returns the `Date` of the end of astronomical twilight using a zenith of [ASTRONOMICAL_ZENITH]. If the calculation can't be computed, null will be returned. See detailed explanation on top
  /// of the page.
  /// See also [ASTRONOMICAL_ZENITH].
  DateTime? getEndAstronomicalTwilight() {
    return getSunsetOffsetByDegrees(ASTRONOMICAL_ZENITH);
  }

  /// A utility method that returns a date offset by the offset time passed in. Please note that the level of light
  /// during twilight is not affected by elevation, so if this is being used to calculate an offset before sunrise or
  /// after sunset with the intent of getting a rough "level of light" calculation, the sunrise or sunset time passed
  /// to this method should be sea level sunrise and sunset.
  ///
  /// - [time]: 
  ///   the start time
  /// - [offset]: 
  ///   the offset to add to the time.
  /// Returns the [DateTime] with the offset added to it
  static DateTime? getTimeOffset(DateTime? time, Duration? offset) {
    if (time == null || offset == null) {
      return null;
    }
    return time.add(offset);
  }

  /// A utility method that returns the time of an offset by degrees below or above the horizon of
  /// [getSunrise]. Note that the degree offset is from the vertical, so for a calculation of 14°
  /// before sunrise, an offset of 14 + [GEOMETRIC_ZENITH] = 104 would have to be passed as a parameter.
  ///
  /// - [offsetZenith]: 
  ///   the degrees before [getSunrise] to use in the calculation. For time after sunrise use
  ///   negative numbers. Note that the degree offset is from the vertical, so for a calculation of 14°
  ///   before sunrise, an offset of 14 + [GEOMETRIC_ZENITH] = 104 would have to be passed as a
  ///   parameter.
  /// Returns The [DateTime] of the offset after (or before) [getSunrise]. If the calculation
  /// can't be computed such as in the Arctic Circle where there is at least one day a year where the sun does
  /// not rise, and one where it does not set, a null will be returned. See detailed explanation on top of the
  /// page.
  DateTime? getSunriseOffsetByDegrees(double offsetZenith) {
    double dawn = getUTCSunrise(offsetZenith);
    if (dawn.isNaN) {
      return null;
    } else {
      return getInstantFromTime(dawn, SolarEvent.SUNRISE);
    }
  }

  /// A utility method that returns the time of an offset by degrees below or above the horizon of [getSunset]. Note that the degree offset is from the vertical, so for a calculation of 14° after sunset, an
  /// offset of 14 + [GEOMETRIC_ZENITH] = 104 would have to be passed as a parameter.
  ///
  /// - [offsetZenith]: 
  ///   the degrees after [getSunset] to use in the calculation. For time before sunset use negative
  ///   numbers. Note that the degree offset is from the vertical, so for a calculation of 14° after
  ///   sunset, an offset of 14 + [GEOMETRIC_ZENITH] = 104 would have to be passed as a parameter.
  /// Returns The [DateTime]of the offset after (or before) [getSunset]. If the calculation can't
  /// be computed such as in the Arctic Circle where there is at least one day a year where the sun does not
  /// rise, and one where it does not set, a null will be returned. See detailed explanation on top of the
  /// page.
  DateTime? getSunsetOffsetByDegrees(double offsetZenith) {
    double sunset = getUTCSunset(offsetZenith);
    if (sunset.isNaN) {
      return null;
    } else {
      return getInstantFromTime(sunset, SolarEvent.SUNSET);
    }
  }

  /// A constructor that takes in [geolocation](http://en.wikipedia.org/wiki/Geolocation) information as a
  /// parameter. The default [AstronomicalCalculator.getDefault] used for solar
  /// calculations is the the [NOAACalculator].
  ///
  /// - [geoLocation]: 
  ///   The location information used for calculating astronomical sun times.
  ///
  /// See also [setAstronomicalCalculator for changing the calculator class.].
  AstronomicalCalendar() : this.withGeoLocation(GeoLocation());

  AstronomicalCalendar.withGeoLocation(GeoLocation geoLocation) {
    final tz.TZDateTime now = tz.TZDateTime.now(geoLocation.getZoneId());
    setLocalDate(DateTime.utc(now.year, now.month, now.day));
    setGeoLocation(geoLocation);
    setAstronomicalCalculator(AstronomicalCalculator.getDefault());
  }

  /// A method that returns the sunrise in UTC time without correction for time zone offset from GMT and without using
  /// daylight savings time.
  ///
  /// - [zenith]: 
  ///   the degrees below the horizon. For time after sunrise use negative numbers.
  /// Returns The time in the format: 18.75 for 18:45:00 UTC/GMT. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, double.nan will be returned. See detailed explanation on top of the page.
  double getUTCSunrise(double zenith) {
    return getAstronomicalCalculator()
        .getUTCSunrise(getAdjustedLocalDate(), getGeoLocation(), zenith, true);
  }

  /// A method that returns the sunrise in UTC time without correction for time zone offset from GMT and without using
  /// daylight savings time. Non-sunrise and sunset calculations such as dawn and dusk, depend on the amount of visible
  /// light, something that is not affected by elevation. This method returns UTC sunrise calculated at sea level. This
  /// forms the base for dawn calculations that are calculated as a dip below the horizon before sunrise.
  ///
  /// - [zenith]: 
  ///   the degrees below the horizon. For time after sunrise use negative numbers.
  /// Returns The time in the format: 18.75 for 18:45:00 UTC/GMT. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, double.nan will be returned. See detailed explanation on top of the page.
  /// See also [AstronomicalCalendar.getUTCSunrise].
  /// See also [AstronomicalCalendar.getUTCSeaLevelSunset].
  double getUTCSeaLevelSunrise(double zenith) {
    return getAstronomicalCalculator()
        .getUTCSunrise(getAdjustedLocalDate(), getGeoLocation(), zenith, false);
  }

  /// A method that returns the sunset in UTC time without correction for time zone offset from GMT and without using
  /// daylight savings time.
  ///
  /// - [zenith]: 
  ///   the degrees below the horizon. For time after sunset use negative numbers.
  /// Returns The time in the format: 18.75 for 18:45:00 UTC/GMT. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, double.nan will be returned. See detailed explanation on top of the page.
  /// See also [AstronomicalCalendar.getUTCSeaLevelSunset].
  double getUTCSunset(double zenith) {
    return getAstronomicalCalculator()
        .getUTCSunset(getAdjustedLocalDate(), getGeoLocation(), zenith, true);
  }

  /// A method that returns the sunset in UTC time without correction for elevation, time zone offset from GMT and
  /// without using daylight savings time. Non-sunrise and sunset calculations such as dawn and dusk, depend on the
  /// amount of visible light, something that is not affected by elevation. This method returns UTC sunset calculated
  /// at sea level. This forms the base for dusk calculations that are calculated as a dip below the horizon after
  /// sunset.
  ///
  /// - [zenith]: 
  ///   the degrees below the horizon. For time before sunset use negative numbers.
  /// Returns The time in the format: 18.75 for 18:45:00 UTC/GMT. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, double.nan will be returned. See detailed explanation on top of the page.
  /// See also [AstronomicalCalendar.getUTCSunset].
  /// See also [AstronomicalCalendar.getUTCSeaLevelSunrise].
  double getUTCSeaLevelSunset(double zenith) {
    return getAstronomicalCalculator()
        .getUTCSunset(getAdjustedLocalDate(), getGeoLocation(), zenith, false);
  }

  /// A utility method that will allow the calculation of a temporal (solar) hour based on the sunrise and sunset
  /// passed as parameters to this method. An example of the use of this method would be the calculation of a
  /// non-elevation adjusted temporal hour by passing in [getSeaLevelSunrise] and
  /// [getSeaLevelSunset] as parameters.
  ///
  /// - [startOfDay]:
  ///   The start of the day.
  /// - [endOfDay]:
  ///   The end of the day.
  ///
  /// Returns the length of the temporal hour. If the calculation can't be computed null will be returned. See
  /// detailed explanation on top of the page.
  Duration? getTemporalHour([DateTime? startOfDay = omitted, DateTime? endOfDay = omitted]) {
    if (isOmitted(startOfDay) && isOmitted(endOfDay)) {
      return getTemporalHour(getSeaLevelSunrise(), getSeaLevelSunset());
    }
    if (startOfDay == null || endOfDay == null || isOmitted(startOfDay) || isOmitted(endOfDay)) {
      return null;
    }
    return Duration(microseconds: ((endOfDay.microsecondsSinceEpoch - startOfDay.microsecondsSinceEpoch) / 12).round());
  }

  /// A method that returns sundial or solarnoon. It occurs when the Sun is [transiting](http://en.wikipedia.org/wiki/Transit_%28astronomy%29) the [celestial meridian](http://en.wikipedia.org/wiki/Meridian_%28astronomy%29). In this class it is
  /// calculated as halfway between the sunrise and sunset passed to this method. This time can be slightly off the
  /// real transit time due to changes in declination (the lengthening or shortening day).
  ///
  /// - [startOfDay]:
  ///   the start of day for calculating the sun's transit. This can be sea level sunrise, visual sunrise (or
  ///   any arbitrary start of day) passed to this method.
  /// - [endOfDay]:
  ///   the end of day for calculating the sun's transit. This can be sea level sunset, visual sunset (or any
  ///   arbitrary end of day) passed to this method.
  ///
  /// Returns the `Date` representing Sun's transit. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, null will be returned. See detailed explanation on top of the page.
  DateTime? getSunTransit([DateTime? startOfDay = omitted, DateTime? endOfDay = omitted]) {
    if (isOmitted(startOfDay) && isOmitted(endOfDay)) {
      return getInstantFromTime(
          getAstronomicalCalculator().getUTCNoon(getAdjustedLocalDate(), getGeoLocation()), SolarEvent.NOON);
    }
    if (isOmitted(startOfDay) || isOmitted(endOfDay)) {
      return null;
    }
    final DateTime? start = startOfDay;
    final DateTime? end = endOfDay;
    if (start == null || end == null) {
      return null;
    }
    return offsetByParts(start, start, end, 12, 6);
  }

  /// A method that returns astronomical _chatzos halayla_ - solar midnight, the moment the sun crosses the
  /// meridian on the far side of the earth.
  ///
  /// Returns the `DateTime` representing solar midnight, or null when it cannot be calculated.
  DateTime? getSolarMidnight() => getInstantFromTime(
      getAstronomicalCalculator().getUTCMidnight(getAdjustedLocalDate(), getGeoLocation()), SolarEvent.MIDNIGHT);

  DateTime? getTimeAtAzimuth90Or270(double azimuth) => getInstantFromTime(
      getAstronomicalCalculator().getTimeAtAzimuth(getAdjustedLocalDate(), getGeoLocation(), azimuth),
      azimuth == 90 ? SolarEvent.SUNRISE : SolarEvent.SUNSET);

  /// A method that returns an instant from the time passed in as a parameter.
  ///
  /// - [time]:
  ///   The time to be set as the time for the instant. The time expected is in the format: 18.75
  ///   for 6:45:00 PM.
  /// - [solarEvent]:
  ///   the type of event, used to adjust the date when the event crosses midnight UTC.
  /// Returns the instant, in UTC.
  @protected
  DateTime? getInstantFromTime(double time, SolarEvent solarEvent) {
    if (time.isNaN) {
      return null;
    }
    final DateTime date = getAdjustedLocalDate();
    int dayShift = 0;
    final double localTimeHours = getGeoLocation().getLongitude() / 15 + time;
    if (solarEvent == SolarEvent.SUNRISE && localTimeHours > 18) {
      dayShift = -1;
    } else if (solarEvent == SolarEvent.SUNSET && localTimeHours < 6) {
      dayShift = 1;
    } else if (solarEvent == SolarEvent.MIDNIGHT && localTimeHours < 12) {
      dayShift = 1;
    } else if (solarEvent == SolarEvent.NOON) {
      if (localTimeHours < 0) {
        dayShift = 1;
      } else if (localTimeHours > 24) {
        dayShift = -1;
      }
    }
    final int nanos = (time * HOUR_NANOS + 0.5).floor();
    return DateTime.utc(date.year, date.month, date.day + dayShift)
        .add(Duration(microseconds: _floorDivide(nanos, 1000)));
  }

  /// Returns the dip below the horizon before sunrise that matches the offset minutes on passed in as a parameter. For
  /// example passing in 72 minutes for a calendar set to the equinox in Jerusalem returns a value close to 16.1°
  /// Please note that this method is very slow and inefficient and should NEVER be used in a loop.
  ///
  /// - [minutes]:
  ///   offset
  /// Returns the degrees below the horizon before sunrise that match the offset in minutes passed it as a parameter.
  /// See also [getSunsetSolarDipFromOffset].
  double getSunriseSolarDipFromOffset(double minutes) =>
      _solarDipFromOffset(minutes, getSeaLevelSunrise(), -1, getSunriseOffsetByDegrees);

  /// Returns the dip below the horizon after sunset that matches the offset minutes on passed in as a parameter. For
  /// example passing in 72 minutes for a calendar set to the equinox in Jerusalem returns a value close to 16.1°
  /// Please note that this method is very slow and inefficient and should NEVER be used in a loop.
  ///
  /// - [minutes]:
  ///   offset
  /// Returns the degrees below the horizon after sunset that match the offset in minutes passed it as a parameter.
  /// See also [getSunriseSolarDipFromOffset].
  double getSunsetSolarDipFromOffset(double minutes) =>
      _solarDipFromOffset(minutes, getSeaLevelSunset(), 1, getSunsetOffsetByDegrees);

  double _solarDipFromOffset(double minutes, DateTime? event, int direction,
      DateTime? Function(double zenith) offsetByDegrees) {
    if (minutes == 0.0) {
      return 0.0;
    }
    if (minutes.isNaN || event == null) {
      return double.nan;
    }
    const double incrementor = 0.0001;
    final int offsetByTimeMillis = _floorDivide(
        event.microsecondsSinceEpoch + _floorDivide((direction * minutes * MINUTE_NANOS).truncate(), 1000), 1000);
    final double step = minutes > 0.0 ? incrementor : -incrementor;
    final bool continuesWhileLater = (minutes > 0.0) == (direction < 0);
    double degrees = 0.0;
    while (true) {
      degrees += step;
      final DateTime? time = offsetByDegrees(GEOMETRIC_ZENITH + degrees);
      if (time == null || degrees.abs() > 30.0) {
        return double.nan;
      }
      final int millis = _floorDivide(time.microsecondsSinceEpoch, 1000);
      final bool continues = continuesWhileLater ? millis > offsetByTimeMillis : millis < offsetByTimeMillis;
      if (!continues) {
        return degrees;
      }
    }
  }

  DateTime getLocalMeanTime(Duration localTime) {
    final DateTime date = getAdjustedLocalDate();
    final int totalNanos = (getGeoLocation().getLongitude() * 4 * MINUTE_NANOS).truncate();
    return DateTime.utc(date.year, date.month, date.day)
        .add(localTime)
        .add(Duration(microseconds: _floorDivide(-totalNanos, 1000)));
  }

  /// Adjusts the local date to deal with edge cases where the location crosses the antimeridian.
  ///
  /// See also [GeoLocation.getAntimeridianAdjustment].
  /// Returns the adjusted local date
  @protected
  DateTime getAdjustedLocalDate() {
    final int offset = getGeoLocation().getAntimeridianAdjustment(getMidnightLastNight());
    final DateTime localDate = getLocalDate();
    return offset == 0 ? localDate : DateTime.utc(localDate.year, localDate.month, localDate.day + offset);
  }

  @protected
  tz.TZDateTime getMidnightLastNight() {
    final DateTime localDate = getLocalDate();
    return startOfDay(getGeoLocation().getZoneId(), localDate.year, localDate.month, localDate.day);
  }

  @protected
  tz.TZDateTime getMidnightTonight() {
    final DateTime localDate = getLocalDate();
    return startOfDay(getGeoLocation().getZoneId(), localDate.year, localDate.month, localDate.day + 1);
  }

  @override
  String toString() => ZmanimFormatter.toXML(this);

  String toJSON() => ZmanimFormatter.toJSON(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! AstronomicalCalendar || other.runtimeType != runtimeType) {
      return false;
    }
    return getLocalDate() == other.getLocalDate() &&
        getGeoLocation() == other.getGeoLocation() &&
        getAstronomicalCalculator() == other.getAstronomicalCalculator();
  }

  @override
  int get hashCode => Object.hash(runtimeType, getLocalDate(), getGeoLocation(), getAstronomicalCalculator());

  /// A method that returns the currently set [GeoLocation] which contains location information used for the
  /// astronomical calculations.
  ///
  /// Returns the geoLocation.
  GeoLocation getGeoLocation() => _geoLocation;

  /// Sets the [GeoLocation] `Object` to be used for astronomical calculations.
  ///
  /// - [geoLocation]:
  ///   The geoLocation to set.
  void setGeoLocation(GeoLocation geoLocation) {
    _geoLocation = geoLocation;
  }

  /// A method that returns the currently set AstronomicalCalculator.
  ///
  /// Returns the astronomicalCalculator.
  /// See also [setAstronomicalCalculator].
  AstronomicalCalculator getAstronomicalCalculator() => _astronomicalCalculator;

  /// A method to set the [AstronomicalCalculator] used for astronomical calculations. The Zmanim package ships
  /// with a number of different implementations of the `abstract` [AstronomicalCalculator] based on
  /// different algorithms, including [SunTimesCalculator] based
  /// on the [US Naval Observatory's](http://aa.usno.navy.mil/) algorithm, and
  /// [NOAACalculator] based on [NOAA's](http://noaa.gov)
  /// algorithm. This allows easy runtime switching and comparison of different algorithms.
  ///
  /// - [astronomicalCalculator]:
  ///   The astronomicalCalculator to set.
  void setAstronomicalCalculator(AstronomicalCalculator astronomicalCalculator) {
    _astronomicalCalculator = astronomicalCalculator;
  }

  DateTime getLocalDate() => _localDate;

  void setLocalDate(DateTime localDate) {
    _localDate = DateTime.utc(localDate.year, localDate.month, localDate.day);
  }

  AstronomicalCalendar clone() => copyCalendarSettings(this, AstronomicalCalendar.withGeoLocation(getGeoLocation()));

  static int _floorDivide(int dividend, int divisor) => (dividend - dividend % divisor) ~/ divisor;
}

T copyCalendarSettings<T extends AstronomicalCalendar>(AstronomicalCalendar from, T to) => to
  .._localDate = from._localDate
  .._geoLocation = from._geoLocation.clone()
  .._astronomicalCalculator = from._astronomicalCalculator.clone();

DateTime offsetByParts(DateTime origin, DateTime start, DateTime end, int parts, double count) {
  final int partNanos = (end.microsecondsSinceEpoch - start.microsecondsSinceEpoch) * 1000 ~/ parts;
  return origin.add(durationOfNanos((partNanos * count).truncate()));
}

Duration durationOfNanos(int nanos) => Duration(microseconds: AstronomicalCalendar._floorDivide(nanos, 1000));
