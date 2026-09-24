/*
 * Zmanim Java API
 * Copyright (C) 2004-2020 Eliyahu Hershfeld
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
import 'dart:core';

import 'package:kosher_dart/src/zmanim_calendar.dart';
import 'package:kosher_dart/src/util/geo_location.dart';
import 'package:kosher_dart/src/astronomical_calendar.dart';
import 'package:kosher_dart/src/hebrewcalendar/jewish_date.dart';
import 'package:kosher_dart/src/util/astronomical_calculator.dart';
import 'package:meta/meta.dart';
import 'package:kosher_dart/src/hebrewcalendar/jewish_calendar.dart';

/// This class extends ZmanimCalendar and provides many more zmanim than available in the ZmanimCalendar. The basis for
/// most zmanim in this class are from the _sefer_ **[Yisroel Vehazmanim](http://hebrewbooks.org/9765)**
/// by **[Rabbi Yisrael Dovid Harfenes](https://en.wikipedia.org/wiki/Yisroel_Dovid_Harfenes)**.
/// As an example of the number of different _zmanim_ made available by this class, there are methods to return 18
/// different calculations for _alos_ (dawn), 18 for _plag hamincha_ and 29 for _tzais_ available in this
/// API. The real power of this API is the ease in calculating _zmanim_ that are not part of the library. The methods for
/// _zmanim_ calculations not present in this class or it's superclass  [ZmanimCalendar] are contained in the
/// [AstronomicalCalendar], the base class of the calendars in our API since they are generic methods for calculating
/// time based on degrees or time before or after [getSunrise sunrise and [getSunset sunset and are of interest
/// for calculation beyond _zmanim_ calculations. Here are some examples.
/// First create the Calendar for the location you would like to calculate:
///
///
/// ```dart
///  String locationName = "Lakewood, NJ";
///  double latitude = 40.0828; // Lakewood, NJ
///  double longitude = -74.2094; // Lakewood, NJ
///  double elevation = 20; // optional elevation correction in Meters
///  tz.Location zoneId = tz.getLocation("America/New_York");
///  GeoLocation location = GeoLocation.withElevation(locationName, latitude, longitude, elevation, zoneId);
///  ComprehensiveZmanimCalendar czc = ComprehensiveZmanimCalendar.withGeoLocation(location);
///  czc.setLocalDate(DateTime.utc(2024, 2, 8));
/// ```
/// 
/// **Note:** For locations such as Israel where the beginning and end of daylight savings time can fluctuate from
/// year to year, if your version of Java does not have an [up to date timezone database](http://www.oracle.com/technetwork/java/javase/tzdata-versions-138805.html), create a
/// {link java.util.SimpleTimeZone with the known start and end of DST.
/// To get _alos_ calculated as 14° below the horizon (as calculated in the calendars published in Montreal),
/// add {link AstronomicalCalendar#GEOMETRIC_ZENITH (90) to the 14° offset to get the desired time:
/// 
///
/// ```dart
/// Date alos14 = czc.getSunriseOffsetByDegrees({link AstronomicalCalendar#GEOMETRIC_ZENITH + 14);
/// ```
/// 
/// To get _mincha gedola_ calculated based on the _Magen Avraham (MGA)_ using a _shaah zmanis_ based on the day starting
/// 16.1° below the horizon (and ending 16.1° after sunset) the following calculation can be used:
///
///
/// ```dart
/// Date minchaGedola = czc.getTimeOffset(czc.getAlos16point1Degrees], czc.getShaahZmanis16Point1Degrees] * 6.5);
/// ```
/// 
/// or even simpler using the included convenience methods
///
/// ```dart
/// Date minchaGedola = czc.getMinchaGedola(czc.getAlos16point1Degrees], czc.getShaahZmanis16Point1Degrees]);
/// ```
/// 
/// A little more complex example would be calculating zmanim that rely on a _shaah zmanis_ that is
/// not present in this library. While a drop more complex, it is still rather easy. An example would be to calculate
/// the _[Trumas Hadeshen](https://en.wikipedia.org/wiki/Israel_Isserlein)'s_ _alos_ to
/// _tzais_ based _plag hamincha_ as calculated in the Machzikei Hadass calendar in Manchester, England.
/// A number of this calendar's zmanim are calculated based on a day starting at _alos_ of 12° before sunrise
/// and ending at _tzais_ of 7.083° after sunset. Be aware that since the _alos_ and _tzais_
/// do not use identical degree based offsets, this leads to _chatzos_ being at a time other than the
/// [getSunTransit] solar transit (solar midday). To calculate this zman, use the following steps. Note that
/// _plag hamincha_ is 10.75 hours after the start of the day, and the following steps are all that it takes.
/// 
///
/// ```dart
///  Date plag = czc.getPlagHamincha(czc.getSunriseOffsetByDegrees({link AstronomicalCalendar#GEOMETRIC_ZENITH + 12),
/// czc.getSunsetOffsetByDegrees({link AstronomicalCalendar#GEOMETRIC_ZENITH + ZENITH_7_POINT_083));
/// ```
/// 
/// Something a drop more challenging, but still simple, would be calculating a zman using the same "complex" offset day
/// used in the above mentioned Manchester calendar, but for a _shaos zmaniyos_ based _zman_ not not
/// supported by this library, such as calculating the point that one should be _makpid_
/// not to eat on _erev Shabbos_ or _erev Yom Tov_. This is 9 _shaos zmaniyos_ into the day.
/// 
/// 	- Calculate the _shaah zmanis_ in milliseconds for this day
/// 	- Add 9 of these _shaos zmaniyos_ to alos starting at 12°
/// 
/// 
///
/// ```dart
///  long shaahZmanis = czc.getTemporalHour(czc.getSunriseOffsetByDegrees({link AstronomicalCalendar#GEOMETRIC_ZENITH + 12),
///  						czc.getSunsetOffsetByDegrees({link AstronomicalCalendar#GEOMETRIC_ZENITH + ZENITH_7_POINT_083));
///  Date sofZmanAchila = getTimeOffset(czc.getSunriseOffsetByDegrees({link AstronomicalCalendar#GEOMETRIC_ZENITH + 12),
/// shaahZmanis * 9);
/// ```
/// 
/// Calculating this _sof zman achila_ according to the _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_
/// is simplicity itself.
///
/// ```dart
/// Date sofZamnAchila = czc.getTimeOffset(czc.getSunrise], czc.getShaahZmanisGRA] * 9);
/// ```
///
/// ## Documentation from the {link ZmanimCalendar parent class
/// {inheritDoc
///
/// author © Eliyahu Hershfeld 2004 - 2020
class ComprehensiveZmanimCalendar extends ZmanimCalendar {
  /// The zenith of 3.7° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _tzais_ (nightfall) based on the opinion of the _Geonim_ that _tzais_ is the
  /// time it takes to walk 3/4 of a _Mil_ at 18 minutes a _Mil_, or 13.5 minutes after sunset. The sun
  /// is 3.7° below [GEOMETRIC_ZENITH] geometric zenith at this time in Jerusalem on March 16, about 4 days
  /// before the equinox, the day that a solar hour is 60 minutes.
  ///
  /// _see [getTzaisGeonim3Point7Degrees]_
  @protected
  static const double ZENITH_3_POINT_7 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 3.7;

  /// The zenith of 3.8° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _tzais_ (nightfall) based on the opinion of the _Geonim_ that _tzais_ is the
  /// time it takes to walk 3/4 of a _Mil_ at 18 minutes a _Mil_, or 13.5 minutes after sunset. The sun
  /// is 3.8° below [GEOMETRIC_ZENITH geometric zenith at this time in Jerusalem on March 16, about 4 days
  /// before the equinox, the day that a solar hour is 60 minutes.
  ///
  /// _see [getTzaisGeonim3Point8Degrees]_
  @protected
  static const double ZENITH_3_POINT_8 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 3.8;

  /// The zenith of 5.95° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _tzais_ (nightfall) according to some opinions. This calculation is based on the position of
  /// the sun 24 minutes after sunset in Jerusalem on March 16, about 4 days before the equinox, the day that a solar
  /// hour is 60 minutes, which calculates to 5.95° below [GEOMETRIC_ZENITH] geometric zenith.
  ///
  /// _see [getTzaisGeonim5Point95Degrees]_
  @protected
  static const double ZENITH_5_POINT_95 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 5.95;

  /// The zenith of 7.083° below [GEOMETRIC_ZENITH] geometric zenith (90°). This is often referred to as
  /// 7°5' or 7° and 5 minutes. This calculation is used for calculating _alos_ (dawn) and
  /// _tzais_ (nightfall) according to some opinions. This calculation is based on the position of the sun 30
  /// minutes after sunset in Jerusalem on March 16, about 4 days before the equinox, the day that a solar hour is 60
  /// minutes, which calculates to 7.0833333° below [GEOMETRIC_ZENITH] geometric zenith. This is time some
  /// opinions consider dark enough for 3 stars to be visible. This is the opinion of the
  /// _[Sh"Ut Melamed Leho'il](http://www.hebrewbooks.org/1053)_, _Sh"Ut Bnei Tziyon_, _Tenuvas
  /// Sadeh_ and very close to the time of the _[Mekor Chesed](http://www.hebrewbooks.org/22044)_ of
  /// the _Sefer chasidim_.
  /// todo Confirm the proper source.
  ///
  /// _see [getTzaisGeonim7Point083Degrees]_
  /// _see [getBainHashmashosRT13Point5MinutesBefore7Point083Degrees]_
  @protected
  static const double ZENITH_7_POINT_083 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 7 + (5.0 / 60);

  /// The zenith of 10.2° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _misheyakir_ according to some opinions. This calculation is based on the position of the sun
  /// 45 minutes before [getSunrise] sunrise in Jerusalem on March 16, about 4 days before the equinox, the day
  /// that a solar hour is 60 minutes which calculates to 10.2° below [GEOMETRIC_ZENITH] geometric zenith.
  ///
  /// _see [getMisheyakir10Point2Degrees]_
  @protected
  static const double ZENITH_10_POINT_2 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 10.2;

  /// The zenith of 11° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _misheyakir_ according to some opinions. This calculation is based on the position of the sun
  /// 48 minutes before [getSunrise] sunrise in Jerusalem on March 16, about 4 days before the equinox, the day
  /// that a solar hour is 60 minutes which calculates to 11° below [GEOMETRIC_ZENITH] geometric zenith
  ///
  /// _see [getMisheyakir11Degrees]_
  @protected
  static const double ZENITH_11_DEGREES =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 11;

  /// The zenith of 11.5° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _misheyakir_ according to some opinions. This calculation is based on the position of the sun
  /// 52 minutes before [getSunrise] sunrise in Jerusalem on March 16, about 4 days before the equinox, the day
  /// that a solar hour is 60 minutes which calculates to 11.5° below [GEOMETRIC_ZENITH] geometric zenith
  ///
  /// _see [getMisheyakir11Point5Degrees]_
  @protected
  static const double ZENITH_11_POINT_5 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 11.5;

  /// The zenith of 13.24° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _Rabbeinu Tam's bain hashmashos_ according to some opinions.
  /// NOTE: See comments on [getBainHashmashosRT13Point24Degrees] for additional details about the degrees.
  ///
  /// _see [getBainHashmashosRT13Point24Degrees]_
  ///
  @protected
  static const double ZENITH_13_POINT_24 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 13.24;

  /// The zenith of 19° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _alos_ according to some opinions.
  ///
  /// _see [getAlos19Degrees]_
  /// _see [getAlos18Degrees]_
  @protected
  static const double ZENITH_19_DEGREES =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 19;

  /// The zenith of 19.8° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _alos_ (dawn) and _tzais_ (nightfall) according to some opinions. This calculation is
  /// based on the position of the sun 90 minutes after sunset in Jerusalem on March 16, about 4 days before the
  /// equinox, the day that a solar hour is 60 minutes which calculates to 19.8° below [GEOMETRIC_ZENITH] geometric zenith
  ///
  /// _see [getTzais19Point8Degrees]_
  /// _see [getAlos19Point8Degrees]_
  /// _see [getAlos90Minutes]_
  /// _see [getTzais90Minutes]_
  @protected
  static const double ZENITH_19_POINT_8 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 19.8;

  /// The zenith of 26° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _alos_ (dawn) and _tzais_ (nightfall) according to some opinions. This calculation is
  /// based on the position of the sun [getAlos120Minutes] 120 minutes after sunset in Jerusalem on March 16, about 4
  /// days before the equinox, the day that a solar hour is 60 minutes which calculates to 26° below
  /// [GEOMETRIC_ZENITH] geometric zenith
  ///
  /// _see [getAlos26Degrees]_
  /// _see [getTzais26Degrees]_
  /// _see [getAlos120Minutes]_
  /// _see [getTzais120Minutes]_
  @protected
  static const double ZENITH_26_DEGREES =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 26.0;


  /// The zenith of 4.42° below [GEOMETRIC_ZENITH] geometric zenith (90°), used for
  /// _tzais_ according to some opinions.
  ///
  /// _see [getTzaisGeonim4Point42Degrees]_
  @protected
  static const double ZENITH_4_POINT_42 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 4.42;

  /// The zenith of 4.66° below [GEOMETRIC_ZENITH] geometric zenith (90°), used for
  /// _tzais_ according to some opinions.
  ///
  /// _see [getTzaisGeonim4Point66Degrees]_
  @protected
  static const double ZENITH_4_POINT_66 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 4.66;

  /// The zenith of 12.85° below [GEOMETRIC_ZENITH] geometric zenith (90°), used for
  /// _misheyakir_ according to some opinions.
  ///
  /// _see [getMisheyakir12Point85Degrees]_
  @protected
  static const double ZENITH_12_POINT_85 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 12.85;


  /// The zenith of 5.88° below [GEOMETRIC_ZENITH] geometric zenith (90°).
  /// todo Add more documentation.
  /// _see [getTzaisGeonim4Point8Degrees]_
  @protected
  static const double ZENITH_4_POINT_8 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 4.8;





  /// The zenith of 16.9° below geometric zenith (90°). This calculation is used for determining _alos_
  /// (dawn) based on the opinion of the _Baal Hatanya_. It is based on the calculation that the time between dawn
  /// and _netz amiti_ (sunrise) is 72 minutes, the time that is takes to walk 4 _mil_ at 18 minutes
  /// a mil (_[Rambam](https://en.wikipedia.org/wiki/Maimonides)_ and others). The sun's position at 72
  /// minutes before [getSunriseBaalHatanya] _netz amiti_ (sunrise) in Jerusalem on the equinox (on March 16,
  /// about 4 days before the astronomical equinox, the day that a solar hour is 60 minutes) is 16.9° below
  /// [GEOMETRIC_ZENITH] geometric zenith.
  ///
  /// _see [getAlosBaalHatanya]_
  @protected
  static const double ZENITH_16_POINT_9 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 16.9;

  /// The zenith of 6° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for calculating
  /// _tzais_ (nightfall) based on the opinion of the _Baal Hatanya_. This calculation is based on the position
  /// of the sun 24 minutes after [getSunset] sunset in Jerusalem on March 16, about 4 days before the equinox, the day
  /// that a solar hour is 60 minutes, which is 6° below [GEOMETRIC_ZENITH] geometric zenith.
  ///
  /// _see [getTzaisBaalHatanya]_
  @protected
  static const double ZENITH_6_DEGREES =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 6;

  /// The zenith of 6.45° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _tzais_ (nightfall) according to some opinions. This is based on the calculations of
  /// [Rabbi Yechiel Michel Tucazinsky](https://en.wikipedia.org/wiki/Yechiel_Michel_Tucazinsky) of the position of
  /// the sun no later than [getTzaisGeonim6Point45Degrees] 31 minutes after sunset in Jerusalem, and at the
  /// height of the summer solstice, this zman is 28 minutes after_shkiah_. This computes to 6.45° below
  /// [GEOMETRIC_ZENITH]. This calculation is found in the [Birur Halacha Yoreh Deah 262]
  /// (https://hebrewbooks.org/pdfpager.aspx?req=50536&st=&pgnum=51) it the commonly used
  /// _zman_ in Israel. It should be noted that this differs from the 6.1°/6.2° calculation for Rabbi
  /// Tucazinsky's time as calculated by the Hazmanim Bahalacha Vol II chapter 50:7 (page 515).
  ///
  /// _see #[getTzaisGeonim6Point45Degrees]_
  @protected
  static const double ZENITH_6_POINT_45 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 6.45;

  /// The zenith of 7.65° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _misheyakir_ according to some opinions.
  ///
  /// _see [getMisheyakir7Point65Degrees]_
  @protected
  static const double ZENITH_7_POINT_65 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 7.65;

  /// The zenith of 7.67° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _tzais_ according to some opinions.
  ///
  /// _see [getMisheyakir7Point65Degrees]_
  @protected
  static const double ZENITH_7_POINT_67 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 7.67;

  /// The zenith of 9.3° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _tzais_ (nightfall) according to some opinions.
  ///
  /// _see [getTzaisGeonim9Point3Degrees]_
  @protected
  static const double ZENITH_9_POINT_3 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 9.3;

  /// The zenith of 9.5° below [[GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _misheyakir_ according to some opinions.
  ///
  /// _see [getMisheyakir9Point5Degrees]_
  @protected
  static const double ZENITH_9_POINT_5 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 9.5;

  /// The zenith of 9.75° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _alos_ (dawn) and _tzais_ (nightfall) according to some opinions.
  ///
  /// _see [getTzaisGeonim9Point75Degrees]_
  @protected
  static const double ZENITH_9_POINT_75 =
      AstronomicalCalendar.GEOMETRIC_ZENITH + 9.75;

  /// The zenith of 2.1° above [GEOMETRIC_ZENITH] (90°). This calculation is used for
  /// calculating the start of _bain hashmashos_ (twilight) of 13.5 minutes before sunset converted to degrees
  /// according to the Yereim. As is traditional with degrees below the horizon, this is calculated without refraction
  /// and from the center of the sun. It would be 0.833° less without this.
  ///
  /// See also [getBainHashmashosYereim2Point1Degrees].
  @protected
  static const double ZENITH_MINUS_2_POINT_1 =
      AstronomicalCalendar.GEOMETRIC_ZENITH - 2.1;

  ///The zenith of 2.8° above [GEOMETRIC_ZENITH] (90°). This calculation is used for
  ///calculating the start of _bain hashmashos_ (twilight) of 16.875 minutes before sunset converted to degrees
  ///according to the Yereim. As is traditional with degrees below the horizon, this is calculated without refraction
  ///and from the center of the sun. It would be 0.833° less without this.
  ///
  ///See also [getBainHashmashosYereim2Point8Degrees].
  @protected
  static const double ZENITH_MINUS_2_POINT_8 =
      AstronomicalCalendar.GEOMETRIC_ZENITH - 2.8;

  /// The zenith of 3.05° above [GEOMETRIC_ZENITH] (90°). This calculation is used for
  /// calculating the start of _bain hashmashos_ (twilight) of 18 minutes before sunset converted to degrees
  /// according to the Yereim. As is traditional with degrees below the horizon, this is calculated without refraction
  /// and from the center of the sun. It would be 0.833° less without this.
  ///
  /// See also [getBainHashmashosYereim3Point05Degrees].
  @protected
  static const double ZENITH_MINUS_3_POINT_05 =
      AstronomicalCalendar.GEOMETRIC_ZENITH - 3.05;

  /// The offset in minutes (defaults to 40) after sunset used for _tzeit_ for Ateret Torah calculations.
  /// _see [getTzaisAteretTorah]_
  /// _see [getAteretTorahSunsetOffset]_
  /// _see [setAteretTorahSunsetOffset]_
  double _ateretTorahSunsetOffset = 40;

  /// Default constructor will set a default [GeoLocation], a default
  /// [AstronomicalCalculator.getDefault] AstronomicalCalculator and default the calendar to the current date.
  ///
  /// _see [AstronomicalCalendar.AstronomicalCalendar]_
  ComprehensiveZmanimCalendar() : this.withGeoLocation(GeoLocation());

  ComprehensiveZmanimCalendar.withGeoLocation(super.location) : super.withGeoLocation();

  /// divides the day based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)
  /// that the day runs from dawn to dusk. Dawn for this calculation is when the sun is 19.8°
  /// below the eastern geometric horizon before sunrise. Dusk for this is when the sun is 19.8° below the western
  /// geometric horizon after sunset. This day is split into 12 equal parts with each part being a _shaah zmanis_.
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a double.minPositive
  ///         will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  Duration? getShaahZmanis19Point8Degrees() =>
      getTemporalHour(getAlos19Point8Degrees(), getTzais19Point8Degrees());

  /// the day based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)
  /// that the day runs from dawn to dusk. Dawn for this calculation is when the sun is 18° below the
  /// eastern geometric horizon before sunrise. Dusk for this is when the sun is 18° below the western geometric
  /// horizon after sunset. This day is split into 12 equal parts with each part being a _shaah zmanis_.
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a double.minPositive
  ///         will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  Duration? getShaahZmanis18Degrees() =>
      getTemporalHour(getAlos18Degrees(), getTzais18Degrees());

  /// Method to return a _shaah zmanis_ (temporal hour) calculated using a dip of 26°. This calculation
  /// divides the day based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)
  /// that the day runs from dawn to dusk. Dawn for this calculation is when the sun is
  /// [getAlos26Degrees] below the eastern geometric horizon before sunrise. Dusk for this is when
  /// the sun is [getTzais26Degrees] below the western geometric horizon after sunset. This day is
  /// split into 12 equal parts with each part being a _shaah zmanis_.
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a double.minPositive
  ///         will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  Duration? getShaahZmanis26Degrees() =>
      getTemporalHour(getAlos26Degrees(), getTzais26Degrees());

  /// Method to return a _shaah zmanis_ (temporal hour) calculated using a dip of 16.1°. This calculation
  /// divides the day based on the opinion that the day runs from dawn to dusk. Dawn for this calculation is when the
  /// sun is 16.1° below the eastern geometric horizon before sunrise and dusk is when the sun is 16.1° below
  /// the western geometric horizon after sunset. This day is split into 12 equal parts with each part being a
  /// _shaah zmanis_.
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a double.minPositive
  ///         will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getAlos16Point1Degrees]_
  /// _see [getTzais16Point1Degrees]_
  /// _see [getSofZmanShmaMGA16Point1Degrees]_
  /// _see [getSofZmanTfilaMGA16Point1Degrees]_
  /// _see [getMinchaGedola16Point1Degrees]_
  /// _see [getMinchaKetana16Point1Degrees]_
  /// _see [getPlagHamincha16Point1Degrees]_
  Duration? getShaahZmanis16Point1Degrees() =>
      getTemporalHour(getAlos16Point1Degrees(), getTzais16Point1Degrees());

  Duration? getShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point8Degrees() =>
      getTemporalHour(getAlos16Point1Degrees(), getTzaisGeonim3Point8Degrees());

  Duration? getShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point7Degrees() =>
      getTemporalHour(getAlos16Point1Degrees(), getTzaisGeonim3Point7Degrees());

  Duration? getShaahZmanisAlos16Point1DegreesToTzaisGeonim7Point083Degrees() =>
      getTemporalHour(getAlos16Point1Degrees(), getTzaisGeonim7Point083Degrees());

  /// Method to return a _shaah zmanis_ (solar hour) according to the opinion of the [Magen Avraham (MGA)]
  /// (https://en.wikipedia.org/wiki/Avraham_Gombinern). This calculation divides the day based on the opinion of
  /// the _MGA_ that the day runs from dawn to dusk. Dawn for this calculation is 60 minutes before sunrise and dusk
  /// is 60 minutes after sunset. This day is split into 12 equal parts with each part being a _shaah zmanis_.
  /// Alternate methods of calculating a _shaah zmanis_ are available in the subclass [ComprehensiveZmanimCalendar]
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a double.minPositive will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  Duration? getShaahZmanis60Minutes() =>
      getTemporalHour(getAlos60Minutes(), getTzais60Minutes());


  /// Method to return a _shaah zmanis_ (temporal hour) according to the opinion of the _alos_ being
  /// [getAlos72Zmanis] minutes _zmaniyos_ before [getSunrise]. This calculation
  /// divides the day based on the opinion of the _MGA_ that the day runs from dawn to dusk. Dawn for this
  /// calculation is 72 minutes _zmaniyos_ before sunrise and dusk is 72 minutes _zmaniyos_ after sunset.
  /// This day is split into 12 equal parts with each part being a _shaah zmanis_. This is identical to 1/10th
  /// of the day from [getSunrise] to [getSunset].
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a double.minPositive will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getAlos72Zmanis]_
  /// _see [getTzais72Zmanis]_
  Duration? getShaahZmanis72MinutesZmanis() =>
      getTemporalHour(getAlos72Zmanis(), getTzais72Zmanis());

  /// Method to return a _shaah zmanis_ (temporal hour) calculated using a dip of 90 minutes. This calculation
  /// divides the day based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)
  /// that the day runs from dawn to dusk. Dawn for this calculation is 90 minutes before sunrise
  /// and dusk is 90 minutes after sunset. This day is split into 12 equal parts with each part being a _shaah zmanis_.
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a double.minPositive will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  Duration? getShaahZmanis90Minutes() =>
      getTemporalHour(getAlos90Minutes(), getTzais90Minutes());

  /// Method to return a _shaah zmanis_ (temporal hour) according to the opinion of the [Magen Avraham (MGA)]
  /// (https://en.wikipedia.org/wiki/Avraham_Gombinern) based on _alos_ being [getAlos90Zmanis] minutes
  /// _zmaniyos_ before [getSunrise]. This calculation divides the day based on the opinion of the
  /// _MGA_ that the day runs from dawn to dusk. Dawn for this calculation is 90 minutes _zmaniyos_ before
  /// sunrise and dusk is 90 minutes _zmaniyos_ after sunset. This day is split into 12 equal parts with each part
  /// being a _shaah zmanis_. This is identical to 1/8th of the day from [getSunrise] to
  /// [getSunset].
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a double.minPositive will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getAlos90Zmanis]_
  /// _see [getTzais90Zmanis]_
  Duration? getShaahZmanis90MinutesZmanis() =>
      getTemporalHour(getAlos90Zmanis(), getTzais90Zmanis());

  /// Method to return a _shaah zmanis_ (temporal hour) according to the opinion of the [Magen Avraham (MGA)]
  /// (https://en.wikipedia.org/wiki/Avraham_Gombinern) based on _alos_ being [getAlos96Zmanis]
  /// minutes _zmaniyos_ before [getSunrise]. This calculation divides the day based on the
  /// opinion of the _MGA_ that the day runs from dawn to dusk. Dawn for this calculation is 96 minutes
  /// _zmaniyos_ before sunrise and dusk is 96 minutes _zmaniyos_ after sunset. This day is split
  /// into 12 equal parts with each part being a _shaah zmanis_. This is identical to 1/7.5th of the day from
  /// [getSunrise] to [getSunset].
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a double.minPositive will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getAlos96Zmanis]_
  /// _see [getTzais96Zmanis]_
  Duration? getShaahZmanis96MinutesZmanis() =>
      getTemporalHour(getAlos96Zmanis(), getTzais96Zmanis());

  /// Method to return a _shaah zmanis_ (temporal hour) according to the opinion of the
  /// _Chacham Yosef Harari-Raful_ of _Yeshivat Ateret Torah_ calculated with _alos_ being 1/10th
  /// of sunrise to sunset day, or [getAlos72Zmanis] 72 minutes _zmaniyos_ of such a day before
  /// [getSunrise] sunrise, and _tzais_ is usually calculated as [getTzaisAteretTorah] 40
  /// minutes (configurable to any offset via [setAteretTorahSunsetOffset]) after [getSunset]]
  /// sunset. This day is split into 12 equal parts with each part being a _shaah zmanis_. Note that with this
  /// system, _chatzos_ (mid-day) will not be the point that the sun is [getSunTransit] halfway across
  /// the sky.
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a double.minPositive will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getAlos72Zmanis]_
  /// _see [getTzaisAteretTorah]_
  /// _see [getAteretTorahSunsetOffset]_
  /// _see [setAteretTorahSunsetOffset]_
  Duration? getShaahZmanisAteretTorah() =>
      getTemporalHour(getAlos72Zmanis(), getTzaisAteretTorah());

  /// Method to return a _shaah zmanis_ (temporal hour) calculated using a dip of 96 minutes. This calculation
  /// divides the day based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)
  /// that the day runs from dawn to dusk. Dawn for this calculation is 96 minutes before sunrise and dusk is 96 minutes
  /// after sunset. This day is split into 12 equal parts with each part being a _shaah zmanis_.
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a double.minPositive will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  Duration? getShaahZmanis96Minutes() =>
      getTemporalHour(getAlos96Minutes(), getTzais96Minutes());

  /// Method to return a _shaah zmanis_ (temporal hour) calculated using a dip of 120 minutes. This calculation
  /// divides the day based on the opinion of the [Magen Avraham (MGA)]https://en.wikipedia.org/wiki/Avraham_Gombinern
  /// that the day runs from dawn to dusk. Dawn for this calculation is 120 minutes before sunrise and dusk is 120 minutes
  /// after sunset. This day is split into 12 equal parts with each part being a _shaah zmanis_.
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a double.minPositive will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  Duration? getShaahZmanis120Minutes() =>
      getTemporalHour(getAlos120Minutes(), getTzais120Minutes());

  /// Method to return a _shaah zmanis_ (temporal hour) according to the opinion of the [Magen Avraham (MGA)]
  /// (https://en.wikipedia.org/wiki/Avraham_Gombinern) based on _alos_ being [getAlos120Zmanis]
  /// minutes _zmaniyos_ before [getSunrise]. This calculation divides the day based on the
  /// opinion of the _MGA_ that the day runs from dawn to dusk. Dawn for this calculation is 120 minutes
  /// _zmaniyos_ before sunrise and dusk is 120 minutes _zmaniyos_ after sunset. This day is
  /// split into 12 equal parts with each part being a _shaah zmanis_. This is identical to 1/6th of the day from
  /// [getSunrise] to [getSunset].
  ///
  /// return the `double` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a double.minPositive will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getAlos120Zmanis]_
  /// _see [getTzais120Zmanis]_
  Duration? getShaahZmanis120MinutesZmanis() =>
      getTemporalHour(getAlos120Zmanis(), getTzais120Zmanis());

  /// This method returns the time of _plag hamincha_ based on sunrise being 120 minutes _zmaniyos_
  /// or 1/6th of the day before sunrise. This is calculated as 10.75 hours after [getAlos120Zmanis] dawn.
  /// The formula used is 10.75 * [getShaahZmanis120MinutesZmanis] after [getAlos120Zmanis] dawn.
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  ///
  /// see [getShaahZmanis120MinutesZmanis]
  DateTime? getPlagHamincha120MinutesZmanis() =>
      getPlagHamincha(getAlos120Zmanis(), getTzais120Zmanis(), true);

  /// This method returns the time of _plag hamincha_ according to the _Magen Avraham_ with the day
  /// starting 120 minutes before sunrise and ending 120 minutes after sunset. This is calculated as 10.75 hours after
  /// [getAlos120Minutes] dawn 120 minutes. The formula used is
  /// 10.75 [getShaahZmanis120Minutes] after [getAlos120Minutes].
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  ///
  /// see #getShaahZmanis120Minutes]
  DateTime? getPlagHamincha120Minutes() =>
      getPlagHamincha(getAlos120Minutes(), getTzais120Minutes(), true);

  /// Method to return _alos_ (dawn) calculated as 60 minutes before sunrise. This is the time to walk the
  /// distance of 4 _Mil_ at 15 minutes a _Mil_. This seems to be the opinion of the
  /// _[Chavas Yair](https://en.wikipedia.org/wiki/Yair_Bacharach)_ in the _Mekor Chaim, Orach Chaim Ch.
  /// 90_, though  the Mekor chaim in Ch. 58 and in the _[Chut Hashani Cha 97](http://www.hebrewbooks.org/pdfpager.aspx?req=45193&pgnum=214)_
  /// states that a a person walks 3 and a 1/3 _mil_ in an hour, or an 18 minute _mil_. Also see the
  /// [Divrei Malkiel](https://he.wikipedia.org/wiki/%D7%9E%D7%9C%D7%9B%D7%99%D7%90%D7%9C_%D7%A6%D7%91%D7%99_%D7%98%D7%A0%D7%A0%D7%91%D7%95%D7%99%D7%9D)
  /// [Vol. 4, Ch. 20, page 34](http://www.hebrewbooks.org/pdfpager.aspx?req=803&pgnum=33)
  /// who mentions the 15 minute _mil_ lechumra by baking matzos. Also see the
  /// [Maharik](https://en.wikipedia.org/wiki/Joseph_Colon_Trabotto) [Ch. 173](http://www.hebrewbooks.org/pdfpager.aspx?req=1142&pgnum=216)
  /// where the questioner quoting the [Ra'avan](https://en.wikipedia.org/wiki/Eliezer_ben_Nathan) is of the opinion that the time to walk a
  /// _mil_ is 15 minutes (5 _mil_ in a little over an hour). There are many who believe that there is a
  /// _ta'us sofer_ (scribe's error) in the Ra'avan, and it should 4 _mil_ in a little over an hour, or an
  /// 18 minute _mil_. Time based offset calculations are based on the opinion of the
  /// _[Rishonim](https://en.wikipedia.org/wiki/Rishonim)_ who stated that the time of the _neshef_
  /// (time between dawn and sunrise) does not vary by the time of year or location but purely depends on the time it takes to
  /// walk the distance of 4* _mil_. [getTzaisGeonim9Point75Degrees] is a related _zman_ that is a
  /// degree based calculation based on 60 minutes.
  ///
  /// todo Apply documentation to Tzais once reviewed.
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  ///
  /// _see [getTzaisGeonim9Point75Degrees]
  DateTime? getAlos60Minutes() => AstronomicalCalendar.getTimeOffset(getSunriseBasedOnElevationSetting(), const Duration(minutes: -60));

  /// Method to return _alos_ (dawn) calculated using 72 minutes _zmaniyos_ or 1/10th of the day before
  /// sunrise. This is based on an 18 minute _Mil_ so the time for 4 _Mil_ is 72 minutes which is 1/10th
  /// of a day (12 * 60 = 720) based on the a day being from [getSeaLevelSunrise] sea level sunrise to
  /// [getSeaLevelSunrise] sea level sunset or [getSunrise sunrise to [getSunset] sunset
  /// (depending on the [isUseElevation] setting).
  /// The actual calculation is [getSeaLevelSunrise]- ( [getShaahZmanisGRA] * 1.2). This calculation
  /// is used in the calendars published by
  /// _[Hisachdus Harabanim D'Artzos Habris Ve'Canada](https://en.wikipedia.org/wiki/Central_Rabbinical_Congress)_
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanisGRA]_
  DateTime? getAlos72Zmanis() {
    return getZmanisBasedOffset(-1.2);
  }


  /// Method to return _alos_ (dawn) calculated using 96 minutes before before [getSunrise] sunrise or
  /// [getSeaLevelSunrise] sea level sunrise (depending on the [isUseElevation] setting) that is based
  /// on the time to walk the distance of 4 _Mil_ at 24 minutes a _Mil_. Time based offset
  /// calculations for _alos_ are based on the opinion of the _[Rishonim](https://en.wikipedia.org/wiki/Rishonim)_
  /// who stated that the time of the _Neshef_ (time between dawn and sunrise) does not vary
  /// by the time of year or location but purely depends on the time it takes to walk the distance of 4 _Mil_.
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getAlos96Minutes() => AstronomicalCalendar.getTimeOffset(getSunriseBasedOnElevationSetting(), const Duration(minutes: -96));

  /// Method to return _alos_ (dawn) calculated using 90 minutes _zmaniyos_ or 1/8th of the day before
  /// [getSunrise] sunrise or [getSeaLevelSunrise] sea level sunrise (depending on the
  /// [isUseElevation] setting). This is based on a 22.5 minute _Mil_ so the time for 4 _Mil_ is 90
  /// minutes which is 1/8th of a day (12 * 60) / 8 = 90
  /// The day is calculated from [getSeaLevelSunrise] sea level sunrise to [getSeaLevelSunrise] sea level
  /// sunset or [getSunrise] sunrise to [getSunset] sunset (depending on the [isUseElevation].
  /// The actual calculation used is [getSunrise] - ( [getShaahZmanisGRA] * 1.5).
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getShaahZmanisGRA]_
  DateTime? getAlos90Zmanis() => getZmanisBasedOffset(-1.5);

  /// This method returns _alos_ (dawn) calculated using 96 minutes _zmaniyos_ or 1/7.5th of the day before
  /// [getSunrise] sunrise or [getSeaLevelSunrise] sea level sunrise (depending on the
  /// [isUseElevation] setting). This is based on a 24 minute _Mil_ so the time for 4 _Mil_ is 96
  /// minutes which is 1/7.5th of a day (12 * 60 / 7.5 = 96).
  /// The day is calculated from [getSeaLevelSunrise sea level sunrise to [getSeaLevelSunrise] sea level
  /// sunset or [getSunrise] sunrise to [getSunset] sunset (depending on the [isUseElevation].
  /// The actual calculation used is [getSunrise] - ( [getShaahZmanisGRA] * 1.6).
  ///
  /// _return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getShaahZmanisGRA]_
  DateTime? getAlos96Zmanis() {
    return getZmanisBasedOffset(-1.6);
  }

  /// Method to return _alos_ (dawn) calculated using 90 minutes before [getSeaLevelSunrise] sea level
  /// sunrise based on the time to walk the distance of 4 _Mil_ at 22.5 minutes a _Mil_. Time based
  /// offset calculations for _alos_ are based on the opinion of the _[Rishonim](https://en.wikipedia.org/wiki/Rishonim)_
  /// who stated that the time of the _Neshef_ (time between dawn and sunrise) does not vary by the time of year or
  /// location but purely depends on the time it takes to walk the distance of 4 _Mil_.
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getAlos90Minutes() => AstronomicalCalendar.getTimeOffset(getSunriseBasedOnElevationSetting(), const Duration(minutes: -90));

  /// Method to return _alos_ (dawn) calculated using 120 minutes before [getSeaLevelSunrise] sea level
  /// sunrise (no adjustment for elevation is made) based on the time to walk the distance of 5 _Mil_(
  /// _Ula_) at 24 minutes a _Mil_. Time based offset calculations for _alos_ are based on the
  /// opinion of the _[Rishonim](https://en.wikipedia.org/wiki/Rishonim)_ who stated that the time
  /// of the _Neshef_ (time between dawn and sunrise) does not vary by the time of year or location but purely
  /// depends on the time it takes to walk the distance of 5
  /// _Mil_(_Ula_).
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getAlos120Minutes() => AstronomicalCalendar.getTimeOffset(getSunriseBasedOnElevationSetting(), const Duration(minutes: -120));

  /// This method returns _alos_ (dawn) calculated using 120 minutes _zmaniyos_ or 1/6th of the day before
  /// [getSunrise] sunrise or [getSeaLevelSunrise] sea level sunrise (depending on the {link
  /// #isUseElevation] setting). This is based on a 24 minute _Mil_ so the time for 5 _Mil_ is 120
  /// minutes which is 1/6th of a day (12 * 60 / 6 = 120).
  /// The day is calculated from [getSeaLevelSunrise] sea level sunrise to [getSeaLevelSunrise sea level
  /// sunset or [getSunrise] sunrise to [getSunset] sunset (depending on the [isUseElevation].
  /// The actual calculation used is [getSunrise] - ( [getShaahZmanisGRA] * 2).
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getShaahZmanisGRA]_
  DateTime? getAlos120Zmanis() {
    return getZmanisBasedOffset(-2.0);
  }

  /// A method to return _alos_ (dawn) calculated when the sun is [ZENITH_26_DEGREES] 26° below the
  /// eastern geometric horizon before sunrise. This calculation is based on the same calculation of
  /// [getAlos120Minutes] 120 minutes but uses a degree based calculation instead of 120 exact minutes. This
  /// calculation is based on the position of the sun 120 minutes before sunrise in Jerusalem during the equinox (on March
  /// 16, about 4 days before the astronomical equinox, the day that a solar hour is 60 minutes) which calculates to 26°
  /// below [GEOMETRIC_ZENITH] geometric zenith.
  ///
  /// return the `DateTime` representing _alos_. If the calculation can't be computed such as northern
  ///         and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
  ///         may not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [ZENITH_26_DEGREES]_
  /// _see [getAlos120Minutes]_
  /// _see [getTzais120Minutes]_
  DateTime? getAlos26Degrees() => getSunriseOffsetByDegrees(ZENITH_26_DEGREES);

  /// A method to return _alos_ (dawn) calculated when the sun is [ASTRONOMICAL_ZENITH] 18° below the
  /// eastern geometric horizon before sunrise.
  ///
  /// return the `DateTime` representing _alos_. If the calculation can't be computed such as northern
  ///         and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
  ///         may not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  /// see [ASTRONOMICAL_ZENITH]
  DateTime? getAlos18Degrees() =>
      getSunriseOffsetByDegrees(AstronomicalCalendar.ASTRONOMICAL_ZENITH);

  /// A method to return _alos_ (dawn) calculated when the sun is [ZENITH_19_DEGREES] 19° below the
  /// eastern geometric horizon before sunrise. This is the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_'s
  /// alos according to Rabbi Moshe Kosower's [Maaglei Tzedek](http://www.worldcat.org/oclc/145454098), page 88,
  /// [Ayeles Hashachar Vol. I, page 12](http://www.hebrewbooks.org/pdfpager.aspx?req=33464&pgnum=13),
  /// [Yom Valayla Shel Torah, Ch. 34, p. 222](http://www.hebrewbooks.org/pdfpager.aspx?req=55960&pgnum=258) and
  /// Rabbi Yaakov Shakow's [Luach Ikvei Hayom](http://www.worldcat.org/oclc/1043573513).
  ///
  /// return the `DateTime` representing _alos_. If the calculation can't be computed such as northern
  ///         and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
  ///         may not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  /// _see _[ASTRONOMICAL_ZENITH]_
  DateTime? getAlos19Degrees() => getSunriseOffsetByDegrees(ZENITH_19_DEGREES);

  /// Method to return _alos_ (dawn) calculated when the sun is [ZENITH_19_POINT_8] 19.8° below the
  /// eastern geometric horizon before sunrise. This calculation is based on the same calculation of
  /// [getAlos90Minutes] 90 minutes but uses a degree based calculation instead of 90 exact minutes. This calculation
  /// is based on the position of the sun 90 minutes before sunrise in Jerusalem during the equinox (on March 16,
  /// about 4 days before the astronomical equinox, the day that a solar hour is 60 minutes) which calculates to
  /// 19.8° below [GEOMETRIC_ZENITH] geometric zenith
  ///
  /// return the `DateTime` representing _alos_. If the calculation can't be computed such as northern
  ///         and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
  ///         may not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [ZENITH_19_POINT_8]_
  /// _see [getAlos90Minutes]_
  DateTime? getAlos19Point8Degrees() =>
      getSunriseOffsetByDegrees(ZENITH_19_POINT_8);


  /// This method returns _misheyakir_ based on the position of the sun when it is [ZENITH_11_DEGREES]
  /// 11.5° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for calculating
  /// _misheyakir_ according to some opinions. This calculation is based on the position of the sun 52 minutes
  /// before [getSunrise sunrise in Jerusalem during the equinox (on March 16, about 4 days before the
  /// astronomical equinox, the day that a solar hour is 60 minutes) which calculates to 11.5° below
  /// [GEOMETRIC_ZENITH] geometric zenith
  ///
  /// return the `DateTime` of _misheyakir_. If the calculation can't be computed such as northern and
  ///         southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may
  ///         not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [ZENITH_11_POINT_5]_
  DateTime? getMisheyakir11Point5Degrees() =>
      getSunriseOffsetByDegrees(ZENITH_11_POINT_5);

  /// This method returns _misheyakir_ based on the position of the sun when it is [ZENITH_11_DEGREES]
  /// 11° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for calculating
  /// _misheyakir_ according to some opinions. This calculation is based on the position of the sun 48 minutes
  /// before [getSunrise sunrise in Jerusalem during the equinox (on March 16, about 4 days before the
  /// astronomical equinox, the day that a solar hour is 60 minutes) which calculates to 11° below
  /// [GEOMETRIC_ZENITH] geometric zenith
  ///
  /// return If the calculation can't be computed such as northern and southern locations even south of the Arctic
  ///         Circle and north of the Antarctic Circle where the sun may not reach low enough below the horizon for
  ///         this calculation, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [ZENITH_11_DEGREES]_
  DateTime? getMisheyakir11Degrees() =>
      getSunriseOffsetByDegrees(ZENITH_11_DEGREES);

  /// This method returns _misheyakir_ based on the position of the sun when it is [ZENITH_10_POINT_2]
  /// 10.2° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for calculating
  /// _misheyakir_ according to some opinions. This calculation is based on the position of the sun 45 minutes
  /// before [getSunrise sunrise in Jerusalem during the equinox (on March 16, about 4 days before the
  /// astronomical equinox, the day that a solar hour is 60 minutes) which calculates to 10.2° below
  /// [GEOMETRIC_ZENITH] geometric zenith
  ///
  /// return the `DateTime` of _misheyakir_. If the calculation can't be computed such as
  ///         northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle where
  ///         the sun may not reach low enough below the horizon for this calculation, a null will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [ZENITH_10_POINT_2]_
  DateTime? getMisheyakir10Point2Degrees() =>
      getSunriseOffsetByDegrees(ZENITH_10_POINT_2);

  /// This method returns _misheyakir_ based on the position of the sun when it is [ZENITH_7_POINT_65]
  /// 7.65° below [GEOMETRIC_ZENITH] geometric zenith (90°). The degrees are based on a 35/36 minute zman
  /// during the equinox (on March 16, about 4 days before the astronomical equinox, the day that a solar hour is 60
  /// minutes) when the _neshef_ (twilight) is the shortest. This time is based on
  /// [Rabbi Moshe Feinstein](https://en.wikipedia.org/wiki/Moshe_Feinstein) who writes in
  /// [Ohr Hachaim Vol. 4, Ch. 6](http://www.hebrewbooks.org/pdfpager.aspx?req=14677&pgnum=7)
  /// that misheyakir in New York is 35-40 minutes before sunset, something that is a drop less than 8°.
  /// [Rabbi Yisroel Taplin](https://en.wikipedia.org/wiki/Yisroel_Taplin) in
  /// [Zmanei Yisrael](http://www.worldcat.org/oclc/889556744) (page 117) notes that
  /// [Rabbi Yaakov Kamenetsky](https://en.wikipedia.org/wiki/Yaakov_Kamenetsky) stated that it is not less than 36
  /// minutes before sunrise (maybe it is 40 minutes). Sefer Yisrael Vehazmanim (p. 7) quotes the Tamar Yifrach
  /// in the name of the [Satmar Rov](https://en.wikipedia.org/wiki/Joel_Teitelbaum) that one should be stringent
  /// not consider misheyakir before 36 minutes. This is also the accepted [minhag](https://en.wikipedia.org/wiki/Minhag)
  /// in [Lakewood](https://en.wikipedia.org/wiki/Lakewood_Township,_New_Jersey) that is used in the
  /// [Yeshiva](https://en.wikipedia.org/wiki/Beth_Medrash_Govoha). This follows the opinion of
  /// [Rabbi Shmuel Kamenetsky](https://en.wikipedia.org/wiki/Shmuel_Kamenetsky) who provided the time of 35/36 minutes,
  /// but did not provide a degree based time. Since this zman depends on the level of light, Rabbi Yaakov Shakow presented
  /// this degree based calculations to Rabbi Kamenetsky who agreed to them.
  ///
  /// return the `DateTime` of _misheyakir_. If the calculation can't be computed such as
  ///         northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle where
  ///         the sun may not reach low enough below the horizon for this calculation, a null will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [ZENITH_7_POINT_65]_
  /// _see [getMisheyakir9Point5Degrees]_
  DateTime? getMisheyakir7Point65Degrees() =>
      getSunriseOffsetByDegrees(ZENITH_7_POINT_65);

  /// This method returns _misheyakir_ based on the position of the sun when it is [ZENITH_9_POINT_5]
  /// 9.5° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is based on Rabbi Dovid Kronglass's
  /// Calculation of 45 minutes in Baltimore as mentioned in <a href= [Divrei Chachamim No. 24](http://www.hebrewbooks.org/pdfpager.aspx?req=20287&pgnum=29) brought down by the [Birur Halacha, Tinyana, Ch. 18](http://www.hebrewbooks.org/pdfpager.aspx?req=50535&pgnum=87). This calculates to 9.5°. Also see [Rabbi Yaakov Yitzchok Neiman](https://en.wikipedia.org/wiki/Jacob_Isaac_Neiman) in Kovetz Eitz Chaim Vol. 9, p. 202 that the Vyaan Yosef did not want to rely on times earlier than 45 minutes in New York. This _zman_ is also used in the calendars published by Rabbi Hershel Edelstein. As mentioned in the _Yisroel Vehazmanim_,  Rabbi Edelstein who was given the 45 minute zman by Rabbi Bick. The calendars published by the _[Edot Hamizrach](https://en.wikipedia.org/wiki/Mizrahi_Jews)_ communities also use this zman. This also follows the opinion of [Rabbi Shmuel Kamenetsky](https://en.wikipedia.org/wiki/Shmuel_Kamenetsky) who provided the time of 36 and 45 minutes, but did not provide a degree based time. Since this zman depends on the level of light, Rabbi Yaakov Shakow presented these degree based times to Rabbi Shmuel Kamenetsky who agreed to them. /// return the `DateTime` of _misheyakir_. If the calculation can't be computed such as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation. /// _see [ZENITH_9_POINT_5]_ _see [getMisheyakir7Point65Degrees]_
  DateTime? getMisheyakir9Point5Degrees() =>
      getSunriseOffsetByDegrees(ZENITH_9_POINT_5);

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based
  /// on _alos_ being [getAlos19Point8Degrees] 19.8° before [getSunrise] sunrise. This
  /// time is 3 _[getShaahZmanis19Point8Degrees] shaos zmaniyos_ (solar hours) after [getAlos19Point8Degrees]
  /// dawn based on the opinion of the _MGA_ that the day is calculated from dawn to
  /// nightfall with both being 19.8° below sunrise or sunset. This returns the time of 3 *
  /// [getShaahZmanis19Point8Degrees] after [getAlos19Point8Degrees] dawn.
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  ///         See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis19Point8Degrees]_
  /// _see [getAlos19Point8Degrees]_
  DateTime? getSofZmanShmaMGA19Point8Degrees() =>
      getSofZmanShma(getAlos19Point8Degrees(), getTzais19Point8Degrees(), true);

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based
  /// on _alos_ being [getAlos16Point1Degrees] 16.1° before [getSunrise] sunrise. This time
  /// is 3 _[getShaahZmanis16Point1Degrees] shaos zmaniyos_ (solar hours) after
  /// [getAlos16Point1Degrees] dawn based on the opinion of the _MGA_ that the day is calculated from
  /// dawn to nightfall with both being 16.1° below sunrise or sunset. This returns the time of
  /// 3 * [getShaahZmanis16Point1Degrees] after [getAlos16Point1Degrees] dawn.
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  ///         See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis16Point1Degrees]
  /// _see [getAlos16Point1Degrees]
  DateTime? getSofZmanShmaMGA16Point1Degrees() =>
      getSofZmanShma(getAlos16Point1Degrees(), getTzais16Point1Degrees(), true);

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based
  /// on _alos_ being [getAlos18Degrees] 18° before [getSunrise] sunrise. This time is 3
  /// _[getShaahZmanis18Degrees] shaos zmaniyos_ (solar hours) after [getAlos18Degrees] dawn
  /// based on the opinion of the _MGA_ that the day is calculated from dawn to nightfall with both being 18°
  /// below sunrise or sunset. This returns the time of 3 * [getShaahZmanis18Degrees] after
  /// [getAlos18Degrees] dawn.
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  ///         See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis18Degrees]
  /// _see [getAlos18Degrees]
  DateTime? getSofZmanShmaMGA18Degrees() =>
      getSofZmanShma(getAlos18Degrees(), getTzais18Degrees(), true);


  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based
  /// on _alos_ being [getAlos72Zmanis] 72 minutes _zmaniyos_, or 1/10th of the day before
  /// [getSunrise] sunrise. This time is 3 _[getShaahZmanis90MinutesZmanis] shaos zmaniyos_
  /// (solar hours) after [getAlos72Zmanis] dawn based on the opinion of the _MGA_ that the day is
  /// calculated from a [getAlos72Zmanis] dawn of 72 minutes _zmaniyos_, or 1/10th of the day before
  /// [getSeaLevelSunrise] sea level sunrise to [getTzais72Zmanis] nightfall of 72 minutes
  /// _zmaniyos_ after [getSeaLevelSunset] sea level sunset. This returns the time of 3 *
  /// [getShaahZmanis72MinutesZmanis] after [getAlos72Zmanis] dawn.
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see #getShaahZmanis72MinutesZmanis]_
  /// _see #getAlos72Zmanis]_
  DateTime? getSofZmanShmaMGA72MinutesZmanis() =>
      getSofZmanShma(getAlos72Zmanis(), getTzais72Zmanis(), true);

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on
  /// _alos_ being [getAlos90Minutes] 90 minutes before [getSunrise] sunrise. This time is 3
  /// _[getShaahZmanis90Minutes] shaos zmaniyos_ (solar hours) after [getAlos90Minutes] dawn based on
  /// the opinion of the _MGA_ that the day is calculated from a [getAlos90Minutes] dawn of 90 minutes before
  /// sunrise to [getTzais90Minutes] nightfall of 90 minutes after sunset. This returns the time of 3 *
  /// [getShaahZmanis90Minutes] after [getAlos90Minutes] dawn.
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis90Minutes]
  /// _see [getAlos90Minutes]
  DateTime? getSofZmanShmaMGA90Minutes() =>
      getSofZmanShma(getAlos90Minutes(), getTzais90Minutes(), true);

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) according to the
  /// opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based
  /// on _alos_ being [getAlos90Zmanis] minutes _zmaniyos_ before [getSunrise]. This time is 3 _[getShaahZmanis90MinutesZmanis]_ (solar hours) after
  /// [getAlos90Zmanis] based on the opinion of the _MGA_ that the day is calculated from a {@link
  /// #getAlos90Zmanis() dawn} of 90 minutes _zmaniyos_ before sunrise to [getTzais90Zmanis]
  /// of 90 minutes _zmaniyos_ after sunset. This returns the time of 3 * [getShaahZmanis90MinutesZmanis]
  /// after [getAlos90Zmanis].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis90MinutesZmanis]_
  /// _see [getAlos90Zmanis]_
  DateTime? getSofZmanShmaMGA90MinutesZmanis() =>
      getSofZmanShma(getAlos90Zmanis(), getTzais90Zmanis(), true);

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) according to the
  /// opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based
  /// on _alos_ being [getAlos96Minutes] minutes before [getSunrise]. This time is 3 <em>
  /// [getShaahZmanis96Minutes]</em> (solar hours) after [getAlos96Minutes] based on
  /// the opinion of the _MGA_ that the day is calculated from a [getAlos96Minutes] of 96 minutes before
  /// sunrise to [getTzais96Minutes] of 96 minutes after sunset. This returns the time of 3 * {@link
  /// #getShaahZmanis96Minutes()} after [getAlos96Minutes].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis96Minutes]_
  /// _see [getAlos96Minutes]_
  DateTime? getSofZmanShmaMGA96Minutes() =>
      getSofZmanShma(getAlos96Minutes(), getTzais96Minutes(), true);

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based
  /// on _alos_ being [getAlos90Zmanis] minutes _zmaniyos_ before [getSunrise]. This time is 3 _[getShaahZmanis96MinutesZmanis]_ (solar hours) after
  /// [getAlos96Zmanis] based on the opinion of the _MGA_ that the day is calculated from a {@link
  /// #getAlos96Zmanis() dawn} of 96 minutes _zmaniyos_ before sunrise to [getTzais90Zmanis]
  /// of 96 minutes _zmaniyos_ after sunset. This returns the time of 3 * [getShaahZmanis96MinutesZmanis]
  /// after [getAlos96Zmanis].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis96MinutesZmanis]_
  /// _see [getAlos96Zmanis]_
  DateTime? getSofZmanShmaMGA96MinutesZmanis() =>
      getSofZmanShma(getAlos96Zmanis(), getTzais96Zmanis(), true);

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) calculated as 3
  /// hours (regular and not zmaniyos) before [ZmanimCalendar.getChatzos]. This is the opinion of the
  /// _Shach_ in the _Nekudas Hakesef (Yora Deah 184), Shevus Yaakov, Chasan Sofer_ and others. This
  /// returns the time of 3 hours before [ZmanimCalendar.getChatzos].
  /// todo Add hyperlinks to documentation
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// see [ZmanimCalendar.getChatzos]_
  /// see [getSofZmanTfila2HoursBeforeChatzos]_
  DateTime? getSofZmanShma3HoursBeforeChatzos() =>
      AstronomicalCalendar.getTimeOffset(getChatzosHayom(), const Duration(minutes: -180));

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based
  ///  on _alos_ being [getAlos120Minutes] minutes or 1/6th of the day before [getSunrise].
  ///  This time is 3 _[getShaahZmanis120Minutes]_ (solar hours) after [getAlos120Minutes] based on the opinion of the _MGA_ that the day is calculated from a [getAlos120Minutes] of 120
  ///  minutes before sunrise to [getTzais120Minutes] of 120 minutes after sunset. This returns the time of 3
  ///  [getShaahZmanis120Minutes] after [getAlos120Minutes].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis120Minutes]_
  /// _see [getAlos120Minutes]_
  DateTime? getSofZmanShmaMGA120Minutes() =>
      getSofZmanShma(getAlos120Minutes(), getTzais120Minutes(), true);

  /// This method returns the latest _zman krias shema_ (time to recite _Shema_ in the morning) based
  /// on the opinion that the day starts at _[getAlos16Point1Degrees]_ and ends at
  /// [getSeaLevelSunset]. This is the opinion of the [\u05D7\u05D9\u05D3\u05D5\u05E9\u05D9 \u05D5\u05DB\u05DC\u05DC\u05D5\u05EA \u05D4\u05E8\u05D6\u05F4\u05D4](https://hebrewbooks.org/40357) and the [\u05DE\u05E0\u05D5\u05E8\u05D4 \u05D4\u05D8\u05D4\u05D5\u05E8\u05D4](https://hebrewbooks.org/14799) as
  /// mentioned by Yisrael Vehazmanim [vol 1, sec. 7, ch. 3 no. 16](https://hebrewbooks.org/pdfpager.aspx?req=9765&pgnum=81). Three _shaos zmaniyos_ are calculated based on this day and added to <em>{@link
  /// #getAlos16Point1Degrees() alos}</em> to reach this time. This time is 3 _shaos zmaniyos_ (solar hours) after
  /// [getAlos16Point1Degrees] based on the opinion that the day is calculated from a <em>{@link
  /// #getAlos16Point1Degrees() alos 16.1°}</em> to [getSeaLevelSunset].
  /// **Note:** Based on this calculation _chatzos_ will not be at midday.
  ///
  /// return the `DateTime` of the latest _zman krias shema_ based on this day. If the calculation can't
  ///         be computed such as northern and southern locations even south of the Arctic Circle and north of the
  ///         Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, a null
  ///         will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getAlos16Point1Degrees]_
  /// _see [getSeaLevelSunset]_
  DateTime? getSofZmanShmaAlos16Point1ToSunset() =>
      getSofZmanShma(getAlos16Point1Degrees(), getSunsetBasedOnElevationSetting());

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) based on the
  /// opinion that the day starts at _[getAlos16Point1Degrees] alos 16.1°_ and ends at
  /// _ [getTzaisGeonim7Point083Degrees] tzais 7.083°_. 3 _shaos zmaniyos_ are calculated
  /// based on this day and added to _[getAlos16Point1Degrees] alos_ to reach this time. This time is 3
  /// _shaos zmaniyos_ (temporal hours) after _[getAlos16Point1Degrees] alos 16.1°_ based on
  /// the opinion that the day is calculated from a _[getAlos16Point1Degrees] alos 16.1°_ to
  /// _[getTzaisGeonim7Point083Degrees] tzais 7.083°_.
  /// **Note: ** Based on this calculation _chatzos_ will not be at midday.
  ///
  /// return the `DateTime` of the latest _zman krias shema_ based on this calculation. If the
  ///         calculation can't be computed such as northern and southern locations even south of the Arctic Circle and
  ///         north of the Antarctic Circle where the sun may not reach low enough below the horizon for this
  ///         calculation, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getAlos16Point1Degrees]_
  /// _see [getTzaisGeonim7Point083Degrees]_

  DateTime? getSofZmanShmaAlos16Point1DegreesToTzaisGeonim7Point083Degrees() =>
      getSofZmanShma(
          getAlos16Point1Degrees(), getTzaisGeonim7Point083Degrees());


  /// This method returns the latest _zman tfila_ (time to recite the morning prayers) according to the opinion
  /// of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on
  /// _alos_ being [getAlos19Point8Degrees] before [getSunrise]. This time
  /// is 4 _[getShaahZmanis19Point8Degrees]_ (solar hours) after {@link
  /// #getAlos19Point8Degrees() dawn} based on the opinion of the _MGA_ that the day is calculated from dawn to
  /// nightfall with both being 19.8° below sunrise or sunset. This returns the time of 4 * {@link
  /// #getShaahZmanis19Point8Degrees()} after [getAlos19Point8Degrees].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  ///         See detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getShaahZmanis19Point8Degrees]_
  /// _see [getAlos19Point8Degrees]_
  DateTime? getSofZmanTfilaMGA19Point8Degrees() =>
      getSofZmanTfila(getAlos19Point8Degrees(), getTzais19Point8Degrees(), true);

  /// This method returns the latest _zman tfila_ (time to recite the morning prayers) according to the opinion
  /// of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on
  /// _alos_ being [getAlos16Point1Degrees] before [getSunrise]. This time
  /// is 4 _[getShaahZmanis16Point1Degrees]_ (solar hours) after {@link
  /// #getAlos16Point1Degrees() dawn} based on the opinion of the _MGA_ that the day is calculated from dawn to
  /// nightfall with both being 16.1° below sunrise or sunset. This returns the time of 4 * {@link
  /// #getShaahZmanis16Point1Degrees()} after [getAlos16Point1Degrees].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  ///         See detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see #getShaahZmanis16Point1Degrees]_
  /// _see #getAlos16Point1Degrees]_
  DateTime? getSofZmanTfilaMGA16Point1Degrees() =>
      getSofZmanTfila(getAlos16Point1Degrees(), getTzais16Point1Degrees(), true);

  /// This method returns the latest _zman tfila_ (time to recite the morning prayers) according to the opinion
  /// of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on
  /// _alos_ being [getAlos18Degrees] before [getSunrise]. This time is 4
  /// _[getShaahZmanis18Degrees]_ (solar hours) after [getAlos18Degrees]
  /// based on the opinion of the _MGA_ that the day is calculated from dawn to nightfall with both being 18°
  /// below sunrise or sunset. This returns the time of 4 * [getShaahZmanis18Degrees] after
  /// [getAlos18Degrees].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  ///         where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  ///         See detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// see [getShaahZmanis18Degrees]_
  /// see [getAlos18Degrees]_
  DateTime? getSofZmanTfilaMGA18Degrees() =>
      getSofZmanTfila(getAlos18Degrees(), getTzais18Degrees(), true);


  /// This method returns the latest _zman tfila_ (time to the morning prayers) according to the opinion of the
  /// _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on _alos_
  /// being [getAlos72Zmanis] minutes _zmaniyos_ before [getSunrise]. This time is 4
  /// _[getShaahZmanis72MinutesZmanis]_ (solar hours) after [getAlos72Zmanis]
  /// based on the opinion of the _MGA_ that the day is calculated from a [getAlos72Zmanis] of 72
  /// minutes _zmaniyos_ before sunrise to [getTzais72Zmanis] of 72 minutes _zmaniyos_
  /// after sunset. This returns the time of 4 * [getShaahZmanis72MinutesZmanis] after [getAlos72Zmanis].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis72MinutesZmanis]_
  /// _see [getAlos72Zmanis]_
  DateTime? getSofZmanTfilaMGA72MinutesZmanis() =>
      getSofZmanTfila(getAlos72Zmanis(), getTzais72Zmanis(), true);

  /// This method returns the latest _zman tfila_ (time to recite the morning prayers) according to the opinion
  /// of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on
  /// _alos_ being [getAlos90Minutes] minutes before [getSunrise]. This time is 4
  /// _[getShaahZmanis90Minutes]_ (solar hours) after [getAlos90Minutes] based on
  /// the opinion of the _MGA_ that the day is calculated from a [getAlos90Minutes] of 90 minutes before
  /// sunrise to [getTzais90Minutes] of 90 minutes after sunset. This returns the time of 4 *
  /// [getShaahZmanis90Minutes] after [getAlos90Minutes].
  ///
  /// return the `DateTime` of the latest _zman tfila_. If the calculation can't be computed such as in
  ///         the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis90Minutes]_
  /// _see [getAlos90Minutes]_
  DateTime? getSofZmanTfilaMGA90Minutes() =>
      getSofZmanTfila(getAlos90Minutes(), getTzais90Minutes(), true);

  /// This method returns the latest _zman tfila_ (time to the morning prayers) according to the opinion of the
  /// _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on _alos_
  /// being [getAlos90Zmanis] minutes _zmaniyos_ before [getSunrise]. This time is
  /// 4 _[getShaahZmanis90MinutesZmanis]_ (solar hours) after [getAlos90Zmanis] based on the opinion of the _MGA_ that the day is calculated from a [getAlos90Zmanis]
  /// of 90 minutes _zmaniyos_ before sunrise to [getTzais90Zmanis] of 90 minutes
  /// _zmaniyos_ after sunset. This returns the time of 4 * [getShaahZmanis90MinutesZmanis] after
  /// [getAlos90Zmanis].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis90MinutesZmanis]_
  /// _see [getAlos90Zmanis]_
  DateTime? getSofZmanTfilaMGA90MinutesZmanis() =>
      getSofZmanTfila(getAlos90Zmanis(), getTzais90Zmanis(), true);

  /// This method returns the latest _zman tfila_ (time to recite the morning prayers) according to the opinion
  ///  of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on
  /// _alos_ being [getAlos96Minutes] minutes before [getSunrise]. This time is 4
  /// _[getShaahZmanis96Minutes]_ (solar hours) after [getAlos96Minutes] based on
  /// the opinion of the _MGA_ that the day is calculated from a [getAlos96Minutes] of 96 minutes before
  /// sunrise to [getTzais96Minutes] of 96 minutes after sunset. This returns the time of 4 *
  /// [getShaahZmanis96Minutes] after [getAlos96Minutes].
  ///
  /// return the `DateTime` of the latest _zman tfila_. If the calculation can't be computed such as in
  ///         the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis96Minutes]_
  /// _see [getAlos96Minutes]_
  DateTime? getSofZmanTfilaMGA96Minutes() =>
      getSofZmanTfila(getAlos96Minutes(), getTzais96Minutes(), true);

  /// This method returns the latest _zman tfila_ (time to the morning prayers) according to the opinion of the
  ///  _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on _alos_
  /// being [getAlos96Zmanis] minutes _zmaniyos_ before [getSunrise]. This time is
  /// 4 _[getShaahZmanis96MinutesZmanis]_ (solar hours) after [getAlos96Zmanis] based on the opinion of the _MGA_ that the day is calculated from a [getAlos96Zmanis]
  /// of 96 minutes _zmaniyos_ before sunrise to [getTzais96Zmanis] of 96 minutes
  /// _zmaniyos_ after sunset. This returns the time of 4 * [getShaahZmanis96MinutesZmanis] after
  /// [getAlos96Zmanis].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis90MinutesZmanis]_
  /// _see [getAlos90Zmanis]_
  DateTime? getSofZmanTfilaMGA96MinutesZmanis() =>
      getSofZmanTfila(getAlos96Zmanis(), getTzais96Zmanis(), true);

  /// This method returns the latest _zman tfila_ (time to recite the morning prayers) according to the opinion
  ///  of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on
  /// _alos_ being [getAlos120Minutes] minutes before [getSunrise] . This time is 4
  /// _[getShaahZmanis120Minutes]_ (solar hours) after [getAlos120Minutes]
  /// based on the opinion of the _MGA_ that the day is calculated from a [getAlos120Minutes] of 120
  /// minutes before sunrise to [getTzais120Minutes] of 120 minutes after sunset. This returns the time of
  /// 4 * [getShaahZmanis120Minutes] after [getAlos120Minutes].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis120Minutes]_
  /// _see [getAlos120Minutes]_
  DateTime? getSofZmanTfilaMGA120Minutes() =>
      getSofZmanTfila(getAlos120Minutes(), getTzais120Minutes(), true);

  /// This method returns the latest _zman tfila_ (time to recite the morning prayers) calculated as 2 hours
  /// before [ZmanimCalendar.getChatzos]. This is based on the opinions that calculate
  /// _sof zman krias shema_ as [getSofZmanShma3HoursBeforeChatzos]. This returns the time of 2 hours
  /// before [ZmanimCalendar.getChatzos].
  ///
  /// return the `DateTime` of the latest _zman krias shema_. If the calculation can't be computed such
  ///         as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
  ///         it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// see [ZmanimCalendar.getChatzos]
  /// see [getSofZmanShma3HoursBeforeChatzos]
  DateTime? getSofZmanTfila2HoursBeforeChatzos() =>
      AstronomicalCalendar.getTimeOffset(getChatzosHayom(), const Duration(minutes: -120));

  /// This method returns mincha gedola calculated as 30 minutes after _[getChatzos] chatzos_ and not
  /// 1/2 of a _[getShaahZmanisGRA] shaah zmanis_ after _[getChatzos] chatzos_ as
  /// calculated by [getMinchaGedola. Some use this time to delay the start of mincha in the winter when 1/2 of
  /// a _[getShaahZmanisGRA] shaah zmanis_ is less than 30 minutes. See
  /// [getMinchaGedolaGreaterThan30]for a convenience method that returns the later of the 2 calculations. One
  /// should not use this time to start _mincha_ before the standard
  /// _[getMinchaGedola] mincha gedola_. See _Shulchan Aruch
  /// Orach Chayim Siman Raish Lamed Gimel seif alef_ and the _Shaar Hatziyon seif katan ches_.
  /// todo Add hyperlinks to documentation.
  ///
  /// return the `DateTime` of 30 minutes after _chatzos_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getMinchaGedola]_
  /// _see [getMinchaGedolaGreaterThan30]_
  DateTime? getMinchaGedola30Minutes() => AstronomicalCalendar.getTimeOffset(getChatzosHayom(), const Duration(minutes: 30));

  /// This method returns the time of _mincha gedola_ according to the Magen Avraham with the day starting 72
  /// minutes before sunrise and ending 72 minutes after sunset. This is the earliest time to pray _mincha_. For
  /// more information on this see the documentation on _[getMinchaGedola] mincha gedola_. This is
  /// calculated as 6.5 [getTemporalHour] solar hours after alos. The calculation used is 6.5 *
  /// [getShaahZmanis72Minutes] after [getAlos72Minutes] alos.
  ///
  /// _see [getAlos72Minutes]_
  /// _see [getMinchaGedola]_
  /// _see [getMinchaKetana]_
  /// _see [ZmanimCalendar.getMinchaGedola]_
  /// return the `DateTime` of the time of mincha gedola. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getMinchaGedola72Minutes() =>
      getMinchaGedola(getAlos72Minutes(), getTzais72Minutes(), true);

  /// This method returns the time of _mincha gedola_ according to the Magen Avraham with the day starting and
  /// ending 16.1° below the horizon. This is the earliest time to pray _mincha_. For more information on
  /// this see the documentation on _[getMinchaGedola] mincha gedola_. This is calculated as 6.5
  /// [getTemporalHour] solar hours after alos. The calculation used is 6.5 *
  /// [getShaahZmanis16Point1Degrees] after [getAlos16Point1Degrees] alos.
  ///
  /// _see [getShaahZmanis16Point1Degrees]_
  /// _see [getMinchaGedola]_
  /// _see [getMinchaKetana]_
  /// return the `DateTime` of the time of mincha gedola. If the calculation can't be computed such as northern
  ///         and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
  ///         may not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getMinchaGedola16Point1Degrees() =>
      getMinchaGedola(getAlos16Point1Degrees(), getTzais16Point1Degrees(), true);

  /// This is a convenience method that returns the later of [getMinchaGedola] and
  /// [getMinchaGedola30Minutes]. In the winter when 1/2 of a _[getShaahZmanisGRA] shaah zmanis_ is
  /// less than 30 minutes [getMinchaGedola30Minutes] will be returned, otherwise [getMinchaGedola]
  /// will be returned.
  ///
  /// return the `DateTime` of the later of [getMinchaGedola] and [getMinchaGedola30Minutes].
  ///         If the calculation can't be computed such as in the Arctic Circle where there is at least one day a year
  ///         where the sun does not rise, and one where it does not set, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getMinchaGedolaGreaterThan30(DateTime? minchaGedola) {
    final DateTime? minchaGedola30 = getMinchaGedola30Minutes();
    if (minchaGedola30 == null || minchaGedola == null) {
      return null;
    }
    return minchaGedola30.compareTo(minchaGedola) > 0 ? minchaGedola30 : minchaGedola;
  }

  DateTime? getMinchaGedolaGRAGreaterThan30() => getMinchaGedolaGreaterThan30(getMinchaGedolaGRA());

  /// This method returns the time of _mincha ketana_ according to the _Magen Avraham_ with the day
  /// starting and ending 16.1° below the horizon. This is the preferred earliest time to pray _mincha_
  /// according to the opinion of the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_ and others.
  /// For more information on this see the documentation on _[getMinchaGedola] mincha gedola_. This is
  /// calculated as 9.5 [getTemporalHour] solar hours after alos. The calculation used is 9.5 *
  /// [getShaahZmanis16Point1Degrees] after [getAlos16Point1Degrees] alos.
  ///
  /// _see [getShaahZmanis16Point1Degrees]_
  /// _see [getMinchaGedola]_
  /// _see [getMinchaKetana]_
  /// return the `DateTime` of the time of mincha ketana. If the calculation can't be computed such as northern
  ///         and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
  ///         may not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getMinchaKetana16Point1Degrees() =>
      getMinchaKetana(getAlos16Point1Degrees(), getTzais16Point1Degrees(), true);

  /// This method returns the time of _mincha ketana_ according to the _Magen Avraham_ with the day
  /// starting 72 minutes before sunrise and ending 72 minutes after sunset. This is the preferred earliest time to pray
  /// _mincha_ according to the opinion of the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_
  /// and others. For more information on this see the documentation on _[getMinchaGedola] mincha gedola_.
  /// This is calculated as 9.5 [getShaahZmanis72Minutes] after _alos_. The calculation used is 9.5 *
  /// [getShaahZmanis72Minutes] after _[getAlos72Minutes] alos_.
  ///
  /// _see [getShaahZmanis16Point1Degrees]_
  /// _see [getMinchaGedola]_
  /// _see [getMinchaKetana]_
  /// return the `DateTime` of the time of mincha ketana. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getMinchaKetana72Minutes() =>
      getMinchaKetana(getAlos72Minutes(), getTzais72Minutes(), true);

  /// This method returns the time of _plag hamincha_ according to the _Magen Avraham_ with the day
  /// starting 60 minutes before sunrise and ending 60 minutes after sunset. This is calculated as 10.75 hours after
  /// [getAlos60Minutes] dawn. The formula used is
  /// 10.75 [getShaahZmanis60Minutes] after [getAlos60Minutes].
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  ///
  /// _see [getShaahZmanis60Minutes]_
  DateTime? getPlagHamincha60Minutes() =>
      getPlagHamincha(getAlos60Minutes(), getTzais60Minutes(), true);

  /// This method returns the time of _plag hamincha_ according to the _Magen Avraham_ with the day
  /// starting 72 minutes before sunrise and ending 72 minutes after sunset. This is calculated as 10.75 hours after
  /// [getAlos72Minutes] dawn. The formula used is
  /// 10.75 [getShaahZmanis72Minutes] after [getAlos72Minutes].
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  ///
  /// _see [getShaahZmanis72Minutes]_
  DateTime? getPlagHamincha72Minutes() =>
      getPlagHamincha(getAlos72Minutes(), getTzais72Minutes(), true);

  /// This method returns the time of _plag hamincha_ according to the _Magen Avraham_ with the day
  /// starting 90 minutes before sunrise and ending 90 minutes after sunset. This is calculated as 10.75 hours after
  /// [getAlos90Minutes] dawn. The formula used is
  /// 10.75 [getShaahZmanis90Minutes] after [getAlos90Minutes].
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getShaahZmanis90Minutes]_
  DateTime? getPlagHamincha90Minutes() =>
      getPlagHamincha(getAlos90Minutes(), getTzais90Minutes(), true);

  /// This method returns the time of _plag hamincha_ according to the _Magen Avraham_ with the day
  /// starting 96 minutes before sunrise and ending 96 minutes after sunset. This is calculated as 10.75 hours after
  /// [getAlos96Minutes] dawn. The formula used is
  /// 10.75 [getShaahZmanis96Minutes] after [getAlos96Minutes].
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis96Minutes]_
  DateTime? getPlagHamincha96Minutes() =>
      getPlagHamincha(getAlos96Minutes(), getTzais96Minutes(), true);

  /// This method returns the time of _plag hamincha_. This is calculated as 10.75 hours after
  /// [getAlos96Zmanis] dawn. The formula used is
  /// 10.75 * [getShaahZmanis96MinutesZmanis] after [getAlos96Zmanis] dawn.
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getPlagHamincha96MinutesZmanis() =>
      getPlagHamincha(getAlos96Zmanis(), getTzais96Zmanis(), true);

  /// This method returns the time of _plag hamincha_. This is calculated as 10.75 hours after
  /// [getAlos90Zmanis] dawn. The formula used is
  /// 10.75 * [getShaahZmanis90MinutesZmanis] after [getAlos90Zmanis] dawn.
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getPlagHamincha90MinutesZmanis() =>
      getPlagHamincha(getAlos90Zmanis(), getTzais90Zmanis(), true);

  /// This method returns the time of _plag hamincha_. This is calculated as 10.75 hours after
  /// [getAlos72Zmanis] dawn. The formula used is
  /// 10.75 * [getShaahZmanis72MinutesZmanis] after [getAlos72Zmanis] dawn.
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getPlagHamincha72MinutesZmanis() =>
      getPlagHamincha(getAlos72Zmanis(), getTzais72Zmanis(), true);

  /// This method returns the time of _plag hamincha_ based on the opinion that the day starts at
  /// _[getAlos16Point1Degrees] alos 16.1°_ and ends at
  /// _[getTzais16Point1Degrees] tzais 16.1°_. This is calculated as 10.75 hours _zmaniyos_
  /// after [getAlos16Point1Degrees] dawn. The formula used is
  /// 10.75 * [getShaahZmanis16Point1Degrees] after [getAlos16Point1Degrees].
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle where
  ///         the sun may not reach low enough below the horizon for this calculation, a null will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see _getShaahZmanis16Point1Degrees]
  DateTime? getPlagHamincha16Point1Degrees() =>
      getPlagHamincha(getAlos16Point1Degrees(), getTzais16Point1Degrees(), true);

  /// This method returns the time of _plag hamincha_ based on the opinion that the day starts at
  /// _[getAlos19Point8Degrees] alos 19.8°_ and ends at
  /// _[getTzais19Point8Degrees] tzais 19.8°_. This is calculated as 10.75 hours _zmaniyos_
  /// after [getAlos19Point8Degrees] dawn. The formula used is
  /// 10.75 * [getShaahZmanis19Point8Degrees] after [getAlos19Point8Degrees].
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle where
  ///         the sun may not reach low enough below the horizon for this calculation, a null will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getShaahZmanis19Point8Degrees]_
  DateTime? getPlagHamincha19Point8Degrees() =>
      getPlagHamincha(getAlos19Point8Degrees(), getTzais19Point8Degrees(), true);

  /// This method returns the time of _plag hamincha_ based on the opinion that the day starts at
  /// _[getAlos26Degrees] alos 26°_ and ends at _[getTzais26Degrees] tzais 26°_
  /// . This is calculated as 10.75 hours _zmaniyos_ after [getAlos26Degrees] dawn. The formula used is
  /// 10.75 * [getShaahZmanis26Degrees] after [getAlos26Degrees].
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle where
  ///         the sun may not reach low enough below the horizon for this calculation, a null will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getShaahZmanis26Degrees]_
  DateTime? getPlagHamincha26Degrees() =>
      getPlagHamincha(getAlos26Degrees(), getTzais26Degrees(), true);

  /// This method returns the time of _plag hamincha_ based on the opinion that the day starts at
  /// _[getAlos18Degrees] alos 18°_ and ends at _[getTzais18Degrees] tzais 18°_
  /// . This is calculated as 10.75 hours _zmaniyos_ after [getAlos18Degrees] dawn. The formula used is
  /// 10.75 * [getShaahZmanis18Degrees] after [getAlos18Degrees].
  ///
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle where
  ///         the sun may not reach low enough below the horizon for this calculation, a null will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getShaahZmanis18Degrees]_
  DateTime? getPlagHamincha18Degrees() =>
      getPlagHamincha(getAlos18Degrees(), getTzais18Degrees(), true);

  /// This method returns the time of _plag hamincha_ based on the opinion that the day starts at
  /// _[getAlos16Point1Degrees] alos 16.1°_ and ends at [getSunset] sunset. 10.75 shaos
  /// zmaniyos are calculated based on this day and added to [getAlos16Point1Degrees] alos to reach this time.
  /// This time is 10.75 _shaos zmaniyos_ (temporal hours) after [getAlos16Point1Degrees] dawn based on
  /// the opinion that the day is calculated from a [getAlos16Point1Degrees] dawn of 16.1 degrees before
  /// sunrise to [getSeaLevelSunset] sea level sunset. This returns the time of 10.75 * the calculated
  /// _shaah zmanis_ after [getAlos16Point1Degrees] dawn.
  ///
  /// return the `DateTime` of the plag. If the calculation can't be computed such as northern and southern
  ///         locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach
  ///         low enough below the horizon for this calculation, a null will be returned. See detailed explanation on
  ///         top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getAlos16Point1Degrees]_
  /// _see [getSeaLevelSunset]_
  DateTime? getPlagAlosToSunset() =>
      getPlagHamincha(getAlos16Point1Degrees(), getSunsetBasedOnElevationSetting());

  /// This method returns the time of _plag hamincha_ based on the opinion that the day starts at
  /// _[getAlos16Point1Degrees] alos 16.1°_ and ends at [getTzaisGeonim7Point083Degrees]
  /// tzais. 10.75 shaos zmaniyos are calculated based on this day and added to [getAlos16Point1Degrees] alos
  /// to reach this time. This time is 10.75 _shaos zmaniyos_ (temporal hours) after
  /// [getAlos16Point1Degrees] dawn based on the opinion that the day is calculated from a
  /// [getAlos16Point1Degrees] dawn of 16.1 degrees before sunrise to
  /// [getTzaisGeonim7Point083Degrees] tzais . This returns the time of 10.75 * the calculated
  /// _shaah zmanis_ after [getAlos16Point1Degrees] dawn.
  ///
  /// return the `DateTime` of the plag. If the calculation can't be computed such as northern and southern
  ///         locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach
  ///         low enough below the horizon for this calculation, a null will be returned. See detailed explanation on
  ///         top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getAlos16Point1Degrees]_
  /// _see [getTzaisGeonim7Point083Degrees]_
  DateTime? getPlagAlos16Point1DegreesToTzaisGeonim7Point083Degrees() =>
      getPlagHamincha(
          getAlos16Point1Degrees(), getTzaisGeonim7Point083Degrees());

  /// Method to return the beginning of _bain hashmashos_ of _Rabbeinu Tam_ calculated when the sun is
  /// [ZENITH_13_POINT_24] 13.24° below the western [GEOMETRIC_ZENITH] geometric horizon (90°)
  /// after sunset. This calculation is based on the same calculation of [getBainHashmashosRT58Point5Minutes]
  /// _bain hashmashos_ Rabbeinu Tam 58.5 minutes} but uses a degree based calculation instead of 58.5 exact
  /// minutes. This calculation is based on the position of the sun 58.5 minutes after sunset in Jerusalem during the
  /// equinox (on March 16, about 4 days before the astronomical equinox, the day that a solar hour is 60 minutes)
  /// which calculates to 13.24° below [GEOMETRIC_ZENITH].
  /// NOTE: As per Yisrael Vehazmanim Vol. III page 1028 No 50, a dip of slightly less than 13° should be used.
  /// Calculations show that the proper dip to be 13.2456° (truncated to 13.24 that provides about 1.5 second
  /// earlier (_lechumra_) time) below the horizon at that time. This makes a difference of 1 minute and 10
  /// seconds in Jerusalem during the Equinox, and 1 minute 29 seconds during the solstice as compared to the proper
  /// 13.24° versus 13°. For NY during the solstice, the difference is 1 minute 56 seconds.
  ///
  /// return the `DateTime` of the sun being 13.24° below [GEOMETRIC_ZENITH] geometric zenith
  ///         (90°). If the calculation can't be computed such as northern and southern locations even south of the
  ///         Arctic Circle and north of the Antarctic Circle where the sun may not reach low enough below the horizon
  ///         for this calculation, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  ///
  /// _see [ZENITH_13_POINT_24]_
  /// _see [getBainHashmashosRT58Point5Minutes]_
  DateTime? getBainHashmashosRT13Point24Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_13_POINT_24);

  /// This method returns the beginning of _Bain hashmashos_ of _Rabbeinu Tam_ calculated as a 58.5
  /// minute offset after sunset. _bain hashmashos_ is 3/4 of a _Mil_ before _tzais_ or 3 1/4
  /// _Mil_ after sunset. With a _Mil_ calculated as 18 minutes, 3.25 * 18 = 58.5 minutes.
  ///
  /// return the `DateTime` of 58.5 minutes after sunset. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  ///
  DateTime? getBainHashmashosRT58Point5Minutes() =>
      AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), durationOfNanos((58.5 * AstronomicalCalendar.MINUTE_NANOS).truncate()));

  /// This method returns the beginning of _bain hashmashos_ based on the calculation of 13.5 minutes (3/4 of an
  /// 18 minute _Mil_) before _shkiah_ calculated as [getTzaisGeonim7Point083Degrees].
  ///
  /// return the `DateTime` of the _bain hashmashos_ of _Rabbeinu Tam_ in this calculation. If the
  ///         calculation can't be computed such as northern and southern locations even south of the Arctic Circle and
  ///         north of the Antarctic Circle where the sun may not reach low enough below the horizon for this
  ///         calculation, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getTzaisGeonim7Point083Degrees]_
  DateTime? getBainHashmashosRT13Point5MinutesBefore7Point083Degrees() =>
      AstronomicalCalendar.getTimeOffset(getSunsetOffsetByDegrees(ZENITH_7_POINT_083), durationOfNanos((-13.5 * AstronomicalCalendar.MINUTE_NANOS).truncate()));

  /// This method returns the beginning of _bain hashmashos_ of _Rabbeinu Tam_ calculated according to the
  /// opinion of the _Divrei Yosef_ (see Yisrael Vehazmanim) calculated 5/18th (27.77%) of the time between
  /// _alos_ (calculated as 19.8° before sunrise) and sunrise. This is added to sunset to arrive at the time
  /// for _bain hashmashos_ of _Rabbeinu Tam_).
  ///
  /// return the `DateTime` of _bain hashmashos_ of _Rabbeinu Tam_ for this calculation. If the
  ///         calculation can't be computed such as northern and southern locations even south of the Arctic Circle and
  ///         north of the Antarctic Circle where the sun may not reach low enough below the horizon for this
  ///         calculation, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getBainHashmashosRT2Stars() {
    final DateTime? alos19Point8 = getAlos19Point8Degrees();
    final DateTime? sunrise = getSunriseBasedOnElevationSetting();
    if (alos19Point8 == null || sunrise == null) {
      return null;
    }
    final int alosToSunrise = (sunrise.microsecondsSinceEpoch - alos19Point8.microsecondsSinceEpoch) * 1000;
    return AstronomicalCalendar.getTimeOffset(
        getSunsetBasedOnElevationSetting(), durationOfNanos((alosToSunrise * (5 / 18)).truncate()));
  }

  /// This method returns the beginning of _bain hashmashos_ (twilight) according to the [Yereim (Rabbi Eliezer of Metz)]
  /// (https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as 18 minutes or 3/4 of a 24 minute _Mil_
  /// before sunset. According to the Yereim, _bain hashmashos_ starts 3/4 of a _Mil_ before sunset and
  /// _tzais_ or nightfall starts at sunset.
  ///
  /// Returns the `Date` of 18 minutes before sunset. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  /// documentation.
  /// See also [getBainHashmashosYereim3Point05Degrees].
  DateTime? getBainHashmashosYereim18Minutes() {
    return AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), const Duration(minutes: -18));
  }

  /// This method returns the beginning of _hain hashmashos_ (twilight) according to the [Yereim (Rabbi Eliezer of Metz)]
  /// (https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as the sun's position 3.05° above the horizon during the
  /// equinox (on March 16, about 4 days before the astronomical equinox, the day that a solar hour is 60 minutes) in
  /// Yerushalayim, its position 18 minutes or 3/4 of an 24 minute _Mil_ before sunset. According to the Yereim,
  /// bain hashmashos starts 3/4 of a _Mil_ before sunset and _tzais_ or nightfall starts at sunset.
  ///
  /// Returns the `Date` of the sun's position 3.05° minutes before sunset. If the calculation can't
  /// be computed such as in the Arctic Circle where there is at least one day a year where the sun does not
  /// rise, and one where it does not set, a null will be returned. See detailed explanation on top of the
  /// [AstronomicalCalendar] documentation.
  ///
  /// See also [ZENITH_MINUS_3_POINT_05].
  /// See also [getBainHashmashosYereim18Minutes].
  ///
  DateTime? getBainHashmashosYereim3Point05Degrees() {
    return getSunsetOffsetByDegrees(ZENITH_MINUS_3_POINT_05);
  }

  /// This method returns the beginning of _bain hashmashos_ (twilight) according to the [Yereim (Rabbi Eliezer of Metz)]
  /// (https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as 16.875 minutes or 3/4 of a 22.5 minute _Mil_
  /// before sunset. According to the Yereim, bain hashmashos starts 3/4 of a _Mil_ before sunset and _tzais_ or
  /// nightfall starts at sunset.
  ///
  /// Returns the `Date` of 16.875 minutes before sunset. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  /// documentation.
  ///
  /// See also [getBainHashmashosYereim2Point8Degrees].
  DateTime? getBainHashmashosYereim16Point875Minutes() {
    return AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), durationOfNanos((-16.875 * AstronomicalCalendar.MINUTE_NANOS).truncate()));
  }

  /// This method returns the beginning of _bain hashmashos_ (twilight) according to the [Yereim (Rabbi Eliezer of Metz)]
  /// (https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as the sun's position 2.8° above the horizon during
  /// the equinox (on March 16, about 4 days before the astronomical equinox, the day that a solar hour is 60 minutes) in Yerushalayim,
  /// its position 16.875 minutes or 3/4 of an 18 minute _Mil_ before sunset. According to the Yereim, bain hashmashos starts
  /// 3/4 of a _Mil_ before sunset and _tzais_ or nightfall starts at sunset.
  ///
  /// Returns the `Date` of the sun's position 2.8° minutes before sunset. If the calculation can't
  /// be computed such as in the Arctic Circle where there is at least one day a year where the sun does not
  /// rise, and one where it does not set, a null will be returned. See detailed explanation on top of the
  /// [AstronomicalCalendar] documentation.
  ///
  /// See also [ZENITH_MINUS_2_POINT_8].
  /// See also [getBainHashmashosYereim16Point875Minutes].
  DateTime? getBainHashmashosYereim2Point8Degrees() {
    return getSunsetOffsetByDegrees(ZENITH_MINUS_2_POINT_8);
  }

  /// This method returns the beginning of _bain hashmashos_ (twilight) according to the [Yereim (Rabbi Eliezer of Metz)]
  /// (https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as 13.5 minutes or 3/4 of an 18 minute _Mil_
  /// before sunset. According to the Yereim, bain hashmashos starts 3/4 of a _Mil_ before sunset and _tzais_ or
  /// nightfall starts at sunset.
  ///
  /// Returns the `Date` of 13.5 minutes before sunset. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  /// documentation.
  ///
  /// See also [getBainHashmashosYereim2Point1Degrees].
  DateTime? getBainHashmashosYereim13Point5Minutes() {
    return AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), durationOfNanos((-13.5 * AstronomicalCalendar.MINUTE_NANOS).truncate()));
  }

  /// This method returns the beginning of _bain hashmashos_ according to the [Yereim (Rabbi Eliezer of Metz)]
  /// (https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as the sun's position 2.1° above the horizon
  /// during the equinox (on March 16, about 4 days before the astronomical equinox, the day that a solar hour is 60 minutes)
  /// in Yerushalayim, its position 13.5 minutes or 3/4 of an 18 minute _Mil_ before sunset. According to the Yereim,
  /// bain hashmashos starts 3/4 of a _Mil_ before sunset and _tzais_ or nightfall starts at sunset.
  ///
  /// Returns the `Date` of the sun's position 2.1° minutes before sunset. If the calculation can't
  /// be computed such as in the Arctic Circle where there is at least one day a year where the sun does not
  /// rise, and one where it does not set, a null will be returned. See detailed explanation on top of the
  /// [AstronomicalCalendar] documentation.
  ///
  /// See also [ZENITH_MINUS_2_POINT_1].
  /// See also [getBainHashmashosYereim13Point5Minutes].
  DateTime? getBainHashmashosYereim2Point1Degrees() {
    return getSunsetOffsetByDegrees(ZENITH_MINUS_2_POINT_1);
  }

  /// This method returns the _tzais_ (nightfall) based on the opinion of the _Geonim_ calculated at the
  /// sun's position at [ZENITH_3_POINT_7] 3.7° below the western horizon.
  ///
  /// return the `DateTime` representing the time when the sun is 3.7° below sea level.
  /// _see [ZENITH_3_POINT_7]_
  DateTime? getTzaisGeonim3Point7Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_3_POINT_7);

  /// This method returns the _tzais_ (nightfall) based on the opinion of the _Geonim_ calculated at the
  /// sun's position at [ZENITH_3_POINT_8] 3.8° below the western horizon.
  ///
  /// return the `DateTime` representing the time when the sun is 3.8° below sea level.
  /// _see [ZENITH_3_POINT_8]_
  DateTime? getTzaisGeonim3Point8Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_3_POINT_8);

  /// This method returns the _tzais_ (nightfall) based on the opinion of the _Geonim_ calculated at the
  /// sun's position at [ZENITH_5_POINT_95] 5.95° below the western horizon.
  ///
  /// return the `DateTime` representing the time when the sun is 5.95° below sea level. If the calculation
  ///         can't be computed such as northern and southern locations even south of the Arctic Circle and north of
  ///         the Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, a
  ///         null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [ZENITH_5_POINT_95]_
  DateTime? getTzaisGeonim5Point95Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_5_POINT_95);






  /// This method returns the _tzais_ (nightfall) based on the opinion of the _Geonim_ calculated as 3/4
  /// of a [Mil](http://en.wikipedia.org/wiki/Biblical_and_Talmudic_units_of_measurement) based on the
  /// sun's position at [ZENITH_4_POINT_8] 4.8° below the western horizon. This is based on Rabbi Leo Levi's
  /// calculations. This is the This is a very early _zman_ and should not be relied on without Rabbinical guidance.
  /// todo Additional documentation needed.
  ///
  /// return the `DateTime` representing the time when the sun is 4.8° below sea level. If the calculation
  ///         can't be computed such as northern and southern locations even south of the Arctic Circle and north of
  ///         the Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, a
  ///         null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [ZENITH_4_POINT_8]_
  DateTime? getTzaisGeonim4Point8Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_4_POINT_8);

  /// This method returns the _tzais_ (nightfall) based on the opinion of the _Geonim_ as calculated by
  /// [Rabbi Yechiel Michel Tucazinsky](https://en.wikipedia.org/wiki/Yechiel_Michel_Tucazinsky). It is
  /// based on of the position of the sun no later than [getTzaisGeonim6Point45Degrees] 31 minutes after sunset
  /// in Jerusalem the height of the summer solstice and is 28 minutes after _shkiah_ at the equinox. This
  /// computes to 6.45° below the western horizon.
  /// todo Additional documentation details needed.
  ///
  /// return the `DateTime` representing the time when the sun is 6.45° below sea level. If the
  ///         calculation can't be computed such as northern and southern locations even south of the Arctic Circle and
  ///         north of the Antarctic Circle where the sun may not reach low enough below the horizon for this
  ///         calculation, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [ZENITH_6_POINT_45]_
  DateTime? getTzaisGeonim6Point45Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_6_POINT_45);

  /// This method returns the _tzais_ (nightfall) based on the opinion of the _Geonim_ calculated as 30
  /// minutes after sunset during the equinox (on March 16, about 4 days before the astronomical equinox, the day that
  /// a solar hour is 60 minutes) in Yerushalayim. The sun's position at this time computes to
  /// [ZENITH_7_POINT_083] 7.083° (or 7° 5\u2032 below the western horizon. Note that this is a common
  /// and rounded number. Computation shows the accurate number is 7.2°
  ///
  /// return the `DateTime` representing the time when the sun is 7.083° below sea level. If the
  ///         calculation can't be computed such as northern and southern locations even south of the Arctic Circle and
  ///         north of the Antarctic Circle where the sun may not reach low enough below the horizon for this
  ///         calculation, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [ZENITH_7_POINT_083]_
  DateTime? getTzaisGeonim7Point083Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_7_POINT_083);

  /// This method returns _tzais_ (nightfall) based on the opinion of the _Geonim_ calculated as 45 minutes
  /// after sunset during the summer solstice in New York, when the _neshef_ (twilight) is the longest. The sun's
  /// position at this time computes to [ZENITH_7_POINT_67] 7.75° below the western horizon. See
  /// [Igros Moshe Even Haezer 4, Ch. 4](http://www.hebrewbooks.org/pdfpager.aspx?req=921&pgnum=149) (regarding
  /// tzais for _krias Shema_). It is also mentioned in Rabbi Heber's [Shaarei Zmanim](http://www.hebrewbooks.org/53000)
  /// on in [chapter 10 (page 87)](http://www.hebrewbooks.org/pdfpager.aspx?req=53055&pgnum=101) and
  /// [chapter 12 (page 108)](http://www.hebrewbooks.org/pdfpager.aspx?req=53055&pgnum=122). Also see the
  /// time of 45 minutes in [Rabbi Simcha Bunim Cohen's](https://en.wikipedia.org/wiki/Simcha_Bunim_Cohen)
  /// [The radiance of Shabbos](https://www.worldcat.org/oclc/179728985) as the earliest zman for New York. This
  /// zman is also listed in the [Divrei Shalom Vol. III, chapter 75](http://www.hebrewbooks.org/pdfpager.aspx?req=1927&pgnum=90),
  /// and [Bais Av"i Vol. III, chapter 117](http://www.hebrewbooks.org/pdfpager.aspx?req=892&pgnum=431).
  /// This zman is also listed in the Divrei Shalom etc. chapter 177. Since this
  /// zman depends on the level of light, Rabbi Yaakov Shakow presented this degree based calculation to Rabbi
  /// Rabbi Shmuel Kamenetsky(https://en.wikipedia.org/wiki/Shmuel_Kamenetsky) who agreed to it.
  /// todo add hyperlinks to source of Divrei Shalom.
  /// return the `DateTime` representing the time when the sun is 7.67° below sea level. If the
  ///         calculation can't be computed such as northern and southern locations even south of the Arctic Circle and
  ///         north of the Antarctic Circle where the sun may not reach low enough below the horizon for this
  ///         calculation, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [ZENITH_7_POINT_67]_
  DateTime? getTzaisGeonim7Point67Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_7_POINT_67);


  /// This method returns the _tzais_ (nightfall) based on the calculations used in the
  /// [Luach Itim Lebinah](http://www.worldcat.org/oclc/243303103) as the stringent time for tzais.  It is calculated
  /// at the sun's position at [ZENITH_9_POINT_3] 9.3° below the western horizon.
  ///
  /// return the `DateTime` representing the time when the sun is 9.3° below sea level. If the calculation
  ///         can't be computed such as northern and southern locations even south of the Arctic Circle and north of
  ///         the Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, a
  ///         null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getTzaisGeonim9Point3Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_9_POINT_3);

  /// This method returns the _tzais_ (nightfall) based on the opinion of the _Geonim_ calculated as 60
  /// minutes after sunset during the equinox (on March 16, about 4 days before the astronomical equinox, the day that
  /// a solar hour is 60 minutes) in New York. The sun's position at this time computes to
  /// [ZENITH_9_POINT_75] 9.75° below the western horizon. This is the opinion of
  /// [Rabbi Eliyahu Henkin](https://en.wikipedia.org/wiki/Yosef_Eliyahu_Henkin).  This also follows the opinion of
  /// [Rabbi Shmuel Kamenetsky](https://en.wikipedia.org/wiki/Shmuel_Kamenetsky). Rabbi Yaakov Shakow presented
  /// these degree based times to Rabbi Shmuel Kamenetsky who agreed to them.
  ///
  /// return the `DateTime` representing the time when the sun is 9.75° below sea level. If the calculation
  ///         can't be computed such as northern and southern locations even south of the Arctic Circle and north of
  ///         the Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, a
  ///         null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getTzais60Minutes]_
  DateTime? getTzaisGeonim9Point75Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_9_POINT_75);

  /// This method returns the _tzais_ (nightfall) based on the opinion of the _
  /// [Chavas Yair](https://en.wikipedia.org/wiki/Yair_Bacharach)_ and _Divrei Malkiel_ that the time
  /// to walk the distance of a _Mil_ is 15 minutes for a total of 60 minutes for 4 _Mil_ after
  /// [getSeaLevelSunset] sea level sunset.
  ///
  /// return the `DateTime` representing 60 minutes after sea level sunset. If the calculation can't be
  ///         computed such as in the Arctic Circle where there is at least one day a year where the sun does not rise,
  ///         and one where it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getAlos60Minutes]_
  DateTime? getTzais60Minutes() => AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), const Duration(minutes: 60));

  /// This method returns _tzais_ usually calculated as 40 minutes (configurable to any offset via
  /// [setAteretTorahSunsetOffset]) after sunset. Please note that _Chacham Yosef Harari-Raful_
  /// of _Yeshivat Ateret Torah_ who uses this time, does so only for calculating various other
  /// _zmanai hayom_ such as _Sof Zman Krias Shema_ and _Plag Hamincha_. His calendars do not
  /// publish a _zman_ for _Tzais_. It should also be noted that _Chacham Harari-Raful_ provided a
  /// 25 minute _zman_ for Israel. This API uses 40 minutes year round in any place on the globe by default.
  /// This offset can be changed by calling [setAteretTorahSunsetOffset].
  ///
  /// return the `DateTime` representing 40 minutes (configurable via [setAteretTorahSunsetOffset)
  ///         after sea level sunset. If the calculation can't be computed such as in the Arctic Circle where there is
  ///         at least one day a year where the sun does not rise, and one where it does not set, a null will be
  ///         returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getAteretTorahSunsetOffset]_
  /// _see [setAteretTorahSunsetOffset]_
  DateTime? getTzaisAteretTorah() => AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(),
      durationOfNanos((getAteretTorahSunsetOffset() * AstronomicalCalendar.MINUTE_NANOS).truncate()));

  /// Returns the offset in minutes after sunset used to calculate sunset for the Ateret Torah _zmanim_. The
  /// default value is 40 minutes. This affects most _zmanim_, since almost all zmanim use subset as part of
  /// their calculation.
  ///
  /// return the number of minutes after sunset for _Tzait_.
  /// _see [setAteretTorahSunsetOffset]_
  double getAteretTorahSunsetOffset() => _ateretTorahSunsetOffset;

  /// Allows setting the offset in minutes after sunset for the Ateret Torah zmanim. The default if unset is 40
  /// minutes. Chacham Yosef Harari-Raful of Yeshivat Ateret Torah uses 40 minutes globally with the exception of
  /// Israel where a 25 minute offset is used. This 40 minute (or any other) offset can be overridden by this method.
  /// This offset impacts all Ateret Torah zmanim.
  ///
  /// param ateretTorahSunsetOffset
  ///            the number of minutes after sunset to use as an offset for the Ateret Torah _tzais_
  /// _see [getAteretTorahSunsetOffset]_
  void setAteretTorahSunsetOffset(double ateretTorahSunsetOffset) =>
      _ateretTorahSunsetOffset = ateretTorahSunsetOffset;

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning) based on the
  /// calculation of Chacham Yosef Harari-Raful of Yeshivat Ateret Torah, that the day starts
  /// [getAlos72Zmanis] 1/10th of the day before sunrise and is usually calculated as ending
  /// [getTzaisAteretTorah] 40 minutes after sunset (configurable to any offset via
  /// [setAteretTorahSunsetOffset]). _shaos zmaniyos_ are calculated based on this day and added
  /// to [getAlos72Zmanis] alos to reach this time. This time is 3
  /// _ [getShaahZmanisAteretTorah] shaos zmaniyos_ (temporal hours) after _[getAlos72Zmanis]_
  /// alos 72 zmaniyos_. **Note: ** Based on this calculation _chatzos_ will not be at midday.
  ///
  /// return the `DateTime` of the latest _zman krias shema_ based on this calculation. If the
  ///         calculation can't be computed such as in the Arctic Circle where there is at least one day a year where
  ///         the sun does not rise, and one where it does not set, a null will be returned. See detailed explanation
  ///         on top of the [AstronomicalCalendar] documentation.
  /// _see [getAlos72Zmanis]_
  /// _see [getTzaisAteretTorah]_
  /// _see [getAteretTorahSunsetOffset]_
  /// _see [setAteretTorahSunsetOffset]_
  /// _see [getShaahZmanisAteretTorah]_
  DateTime? getSofZmanShmaAteretTorah() =>
      getSofZmanShma(getAlos72Zmanis(), getTzaisAteretTorah());

  /// This method returns the latest _zman tfila_ (time to recite the morning prayers) based on the calculation
  /// of Chacham Yosef Harari-Raful of Yeshivat Ateret Torah, that the day starts [getAlos72Zmanis] 1/10th of
  /// the day before sunrise and is usually calculated as ending [getTzaisAteretTorah] 40 minutes after
  /// sunset (configurable to any offset via [setAteretTorahSunsetOffset(double)). _shaos zmaniyos_ are
  /// calculated based on this day and added to [getAlos72Zmanis] alos to reach this time. This time is 4 *
  /// _[getShaahZmanisAteretTorah] shaos zmaniyos_ (temporal hours) after
  /// _[getAlos72Zmanis] alos 72 zmaniyos_.
  /// **Note: ** Based on this calculation _chatzos_ will not be at midday.
  ///
  /// return the `DateTime` of the latest _zman krias shema_ based on this calculation. If the
  ///         calculation can't be computed such as in the Arctic Circle where there is at least one day a year where
  ///         the sun does not rise, and one where it does not set, a null will be returned. See detailed explanation
  ///         on top of the [AstronomicalCalendar] documentation.
  /// _see [getAlos72Zmanis]_
  /// _see [getTzaisAteretTorah]_
  /// _see [getShaahZmanisAteretTorah]_
  /// _see [setAteretTorahSunsetOffset_
  DateTime? getSofZmanTfilaAteretTorah() =>
      getSofZmanTfila(getAlos72Zmanis(), getTzaisAteretTorah());

  /// This method returns the time of _mincha gedola_ based on the calculation of _Chacham Yosef
  /// Harari-Raful_ of _Yeshivat Ateret Torah_, that the day starts [getAlos72Zmanis]
  /// 1/10th of the day before sunrise and is usually calculated as ending
  /// [getTzaisAteretTorah] 40 minutes after sunset (configurable to any offset via
  /// [setAteretTorahSunsetOffset(double)). This is the preferred earliest time to pray _mincha_
  /// according to the opinion of the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_ and others.
  /// For more information on this see the documentation on _[getMinchaGedola] mincha gedola_. This is
  /// calculated as 6.5 [getShaahZmanisAteretTorah]  solar hours after alos. The calculation used is 6.5 *
  /// [getShaahZmanisAteretTorah] after _[getAlos72Zmanis] alos_.
  ///
  /// _see [getAlos72Zmanis]_
  /// _see [getTzaisAteretTorah]_
  /// _see [getShaahZmanisAteretTorah]_
  /// _see [getMinchaGedola]_
  /// _see [getMinchaKetanaAteretTorah]_
  /// _see [ZmanimCalendar#getMinchaGedola]_
  /// _see [getAteretTorahSunsetOffset]_
  /// _see [setAteretTorahSunsetOffset]_
  ///
  /// return the `DateTime` of the time of mincha gedola. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getMinchaGedolaAteretTorah() =>
      getMinchaGedola(getAlos72Zmanis(), getTzaisAteretTorah());

  /// This method returns the time of _mincha ketana_ based on the calculation of
  /// _Chacham Yosef Harari-Raful_ of _Yeshivat Ateret Torah_, that the day starts
  /// [getAlos72Zmanis] 1/10th of the day before sunrise and is usually calculated as ending
  /// [getTzaisAteretTorah] 40 minutes after sunset (configurable to any offset via
  /// [setAteretTorahSunsetOffset(double)). This is the preferred earliest time to pray _mincha_
  /// according to the opinion of the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_ and others.
  /// For more information on this see the documentation on _[getMinchaGedola] mincha gedola_. This is
  /// calculated as 9.5 [getShaahZmanisAteretTorah] solar hours after [getAlos72Zmanis] alos. The
  /// calculation used is 9.5 * [getShaahZmanisAteretTorah] after [getAlos72Zmanis] alos.
  ///
  /// _see [getAlos72Zmanis]_
  /// _see [getTzaisAteretTorah]_
  /// _see [getShaahZmanisAteretTorah]_
  /// _see [getAteretTorahSunsetOffset]_
  /// _see [setAteretTorahSunsetOffset]_
  /// _see [getMinchaGedola]_
  /// _see [getMinchaKetana]_
  /// return the `DateTime` of the time of mincha ketana. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getMinchaKetanaAteretTorah() =>
      getMinchaKetana(getAlos72Zmanis(), getTzaisAteretTorah());

  /// This method returns the time of _plag hamincha_ based on the calculation of Chacham Yosef Harari-Raful of
  /// Yeshivat Ateret Torah, that the day starts [getAlos72Zmanis] 1/10th of the day before sunrise and is
  /// usually calculated as ending [getTzaisAteretTorah] 40 minutes after sunset (configurable to any offset
  /// via [setAteretTorahSunsetOffset(double)). _shaos zmaniyos_ are calculated based on this day and
  /// added to [getAlos72Zmanis] alos to reach this time. This time is 10.75
  /// _[getShaahZmanisAteretTorah] shaos zmaniyos_ (temporal hours) after [getAlos72Zmanis]
  /// dawn.
  ///
  /// return the `DateTime` of the plag. If the calculation can't be computed such as in the Arctic Circle
  ///         where there is at least one day a year where the sun does not rise, and one where it does not set, a null
  ///         will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getAlos72Zmanis]_
  /// _see [getTzaisAteretTorah]_
  /// _see [getShaahZmanisAteretTorah]_
  /// _see [setAteretTorahSunsetOffset_
  /// _see [getAteretTorahSunsetOffset]_
  DateTime? getPlagHaminchaAteretTorah() =>
      getPlagHamincha(getAlos72Zmanis(), getTzaisAteretTorah());

  /// Method to return _tzais_ (dusk) calculated as 72 minutes zmaniyos, or 1/10th of the day after
  /// [getSeaLevelSunset].This is the way that the [Minchas Cohen]
  /// (https://en.wikipedia.org/wiki/Abraham_Cohen_Pimentel) in Ma'amar 2:4 calculates Rebbeinu Tam's
  /// time of _tzeis_. It should be noted that this calculation results in the shortest time from sunset to
  /// [tzais] being during the winter solstice, the longest at the summer solstice and 72 clock minutes at the
  /// equinox. This does not match reality, since there is no direct relationship between the length of the day and
  /// twilight. The shortest twilight is during the equinox, the longest is during the the summer solstice, and in the
  /// winter with the shortest daylight, the twilight period is longer than during the equinoxes.
  ///
  /// return the [DateTime] representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getAlos72Zmanis]_
  DateTime? getTzais72Zmanis() {
    return getZmanisBasedOffset(1.2);
  }

  /// Method to return _tzais_ (dusk) calculated using 90 minutes zmaniyos after [getSeaLevelSunset] sea level sunset.
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getAlos90Zmanis]_
  DateTime? getTzais90Zmanis() {
    return getZmanisBasedOffset(1.5);
  }

  ///  Method to return _tzais_ (dusk) calculated using 96 minutes _zmaniyos_ or 1/7.5 of the day after
  ///  [getSeaLevelSunset].
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getAlos96Zmanis]_
  DateTime? getTzais96Zmanis() {
    return getZmanisBasedOffset(1.6);
  }

  /// Method to return _tzais_ (dusk) calculated as 90 minutes after sea level sunset. This method returns
  /// _tzais_ (nightfall) based on the opinion of the Magen Avraham that the time to walk the distance of a
  /// _Mil_ according to the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_'s opinion
  /// is 18 minutes for a total of 90 minutes based on the opinion of _Ula_ who calculated _tzais_ as 5
  /// _Mil_ after sea level shkiah (sunset). A similar calculation [getTzais19Point8Degrees]uses solar
  /// position calculations based on this time.
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getTzais19Point8Degrees]_
  /// _see [getAlos90Minutes]_
  DateTime? getTzais90Minutes() => AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), const Duration(minutes: 90));

  /// This method returns _tzais_ (nightfall) based on the opinion of the _Magen Avraham_ that the time
  /// to walk the distance of a _Mil_ according to the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_'s
  /// opinion is 2/5 of an hour (24 minutes) for a total of 120 minutes based on the opinion of
  /// _Ula_ who calculated _tzais_ as 5 _Mil_ after sea level _shkiah_ (sunset). A similar
  /// calculation [getTzais26Degrees] uses temporal calculations based on this time.
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getTzais26Degrees]_
  /// _see [getAlos120Minutes]_
  DateTime? getTzais120Minutes() => AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), const Duration(minutes: 120));

  /// Method to return _tzais_ (dusk) calculated using 120 minutes _zmaniyos_ after
  /// [getSeaLevelSunset].
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getAlos120Zmanis]_
  DateTime? getTzais120Zmanis() {
    return getZmanisBasedOffset(2.0);
  }

  /// This calculates the time of _tzais_ at the point when the sun is 16.1° below the horizon. This is
  /// the sun's dip below the horizon 72 minutes after sunset according Rabbeinu Tam's calculation of _tzais_
  /// around the equinox in Jerusalem. This is the opinion of Rabbi Meir Posen in the  [Ohr Meir]
  /// (https://www.worldcat.org/oclc/956316270) and others. See Yisrael Vehazmanim vol I, 34:1:4.
  /// For information on how this is calculated see the comments on [getAlos16Point1Degrees]
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as northern and
  ///         southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may
  ///         not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getTzais72Minutes]_
  /// _see [getAlos16Point1Degrees] for more information on this calculation._
  DateTime? getTzais16Point1Degrees() =>
      getSunsetOffsetByDegrees(ZmanimCalendar.ZENITH_16_POINT_1);

  /// For information on how this is calculated see the comments on [getAlos26Degrees]
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as northern and
  ///         southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may
  ///         not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getTzais120Minutes]_
  /// _see [getAlos26Degrees]_
  DateTime? getTzais26Degrees() => getSunsetOffsetByDegrees(ZENITH_26_DEGREES);

  /// For information on how this is calculated see the comments on [getAlos18Degrees]
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as northern and
  ///         southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may
  ///         not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getAlos18Degrees]_
  DateTime? getTzais18Degrees() =>
      getSunsetOffsetByDegrees(AstronomicalCalendar.ASTRONOMICAL_ZENITH);

  /// For information on how this is calculated see the comments on [getAlos19Point8Degrees]
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as northern and
  ///         southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may
  ///         not reach low enough below the horizon for this calculation, a null will be returned. See detailed
  ///         explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getTzais90Minutes]_
  /// _see [getAlos19Point8Degrees]_
  DateTime? getTzais19Point8Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_19_POINT_8);

  /// A method to return _tzais_ (dusk) calculated as 96 minutes after sea level sunset. For information on how
  /// this is calculated see the comments on [getAlos96Minutes].
  ///
  /// return the `DateTime` representing the time. If the calculation can't be computed such as in the Arctic
  ///         Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  ///         a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  /// _see [getAlos96Minutes]_
  DateTime? getTzais96Minutes() => AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), const Duration(minutes: 96));

  /// A method that returns the local time for fixed _chatzos_. This time is noon and midnight adjusted from
  /// standard time to account for the local latitude. The 360° of the globe divided by 24 calculates to 15°
  /// per hour with 4 minutes per degree, so at a longitude of 0 , 15, 30 etc... _Chatzos_ is at exactly 12:00
  /// noon. This is the time of _chatzos_ according to the [Aruch Hashulchan](https://en.wikipedia.org/wiki/Aruch_HaShulchan) in [Orach Chaim 233:14](https://hebrewbooks.org/pdfpager.aspx?req=7705&pgnum=426) and [Rabbi Moshe Feinstein](https://en.wikipedia.org/wiki/Moshe_Feinstein) in Igros Moshe [Orach Chaim 1:24](https://hebrewbooks.org/pdfpager.aspx?req=916&st=&pgnum=67) and [2:20](https://hebrewbooks.org/pdfpager.aspx?req=14675&pgnum=191).
  /// Lakewood, N.J., with a longitude of -74.2094, is 0.7906 away from the closest multiple of 15 at -75°. This
  /// is multiplied by 4 to yield 3 minutes and 10 seconds for a _chatzos_ of 11:56:50. This method is not tied
  /// to the theoretical 15° timezones, but will adjust to the actual timezone and [Daylight saving time](http://en.wikipedia.org/wiki/Daylight_saving_time).
  ///
  /// return the Date representing the local _chatzos_
  /// _see [GeoLocation#getLocalMeanTimeOffset]_
  DateTime? getFixedLocalChatzosHayom() => getLocalMeanTime(const Duration(hours: 12));



  /// Returns the latest time of Kidush Levana according to the <a [Maharil's](http://en.wikipedia.org/wiki/Yaakov_ben_Moshe_Levi_Moelin) opinion that it is calculated as halfway between _molad_ and _molad_. This adds half the 29 days, 12 hours and 793 chalakim time between _molad_ and _molad_ (14 days, 18 hours, 22 minutes and 666 milliseconds) to the month's _molad_. The _sof zman Kiddush Levana_ will be returned even if it occurs during the day. To limit the time to between _tzais_ and _alos_, see [getSofZmanKidushLevanaBetweenMoldos]. /// [alos] the beginning of the Jewish day. If Kidush Levana occurs during the day (starting at alos and ending at tzais), the time returned will be alos. If either the alos or tzais parameters are null, no daytime adjustment will be made. [tzais] the end of the Jewish day. If Kidush Levana occurs during the day (starting at alos and ending at tzais), the time returned will be alos. If either the alos or tzais parameters are null, no daytime adjustment will be made. return the Date representing the moment halfway between molad and molad. If the time occurs between _alos_ and _tzais_, _alos_ will be returned _see [getSofZmanKidushLevanaBetweenMoldos]_ _see [getSofZmanKidushLevana15Days(Date, Date)_ _see [JewishCalendar.getSofZmanKidushLevanaBetweenMoldos]_
  DateTime? getSofZmanKidushLevanaBetweenMoldos(
      [DateTime? alos, DateTime? tzais]) {
    JewishCalendar jewishCalendar = JewishCalendar();
    jewishCalendar.setGregorianDate(
        getLocalDate().year, getLocalDate().month, getLocalDate().day);

    // Do not calculate for impossible dates, but account for extreme cases. In the extreme case of Rapa Iti in French
    // Polynesia on Dec 2027 when kiddush Levana 3 days can be said on _Rosh Chodesh_, the sof zman Kiddush Levana
    // will be on the 12th of the Teves. In the case of Anadyr, Russia on Jan, 2071, sof zman Kiddush Levana between the
    // moldos will occur is on the night of 17th of Shevat. See Rabbi Dovid Heber's Shaarei Zmanim chapter 4 (pages 28 and 32).
    if (jewishCalendar.getJewishDayOfMonth() < 11 ||
        jewishCalendar.getJewishDayOfMonth() > 16) {
      return null;
    }
    return _getMoladBasedTime(
        jewishCalendar.getSofZmanKidushLevanaBetweenMoldos(),
        alos,
        tzais,
        false);
  }

  /// Returns the Date of the molad based time if it occurs on the current date. Since Kiddush Levana can only be said
  /// during the day, there are parameters to limit it to between _alos_ and _tzais_. If the time occurs
  /// between alos and tzais, tzais will be returned
  ///
  /// param moladBasedTime
  ///            the molad based time such as molad, tchilas and sof zman Kiddush Levana
  /// [alos]
  ///            optional start of day to limit molad times to the end of the night before or beginning of the next night. Ignored if
  ///            either this or tzais are null.
  /// [tzais]
  ///            optional end of day to limit molad times to the end of the night before or beginning of the next night. Ignored if
  ///            either this or alos are null
  /// [techila]
  ///            is it the start of _Kiddush Levana_ time or the end? If it is start roll it to the next _tzais_, and
  ///             and if it is the end, return the end of the previous night (_alos_ passed in). Ignored if either
  ///             _alos_ or _tzais_ are null.
  ///  return the _molad_ based time. If the _zman_ does not occur during the current date, null will be returned.
  DateTime? _getMoladBasedTime(
      DateTime moladBasedTime, DateTime? alos, DateTime? tzais, bool techila) {
    if (moladBasedTime.isBefore(getMidnightLastNight()) ||
        moladBasedTime.isAfter(getMidnightTonight())) {
      return null;
    }
    if (alos == null || tzais == null) {
      return moladBasedTime;
    }
    if (moladBasedTime.isAfter(alos) && moladBasedTime.isBefore(tzais)) {
      return techila ? tzais : alos;
    }
    return moladBasedTime;
  }

  /// Returns the latest time of _Kiddush Levana_ calculated as 15 days after the _molad_. This is the
  /// opinion brought down in the Shulchan Aruch (Orach Chaim 426). It should be noted that some opinions hold that the
  /// [Rema](http://en.wikipedia.org/wiki/Moses_Isserles) who brings down the opinion of the <a [Maharil's](http://en.wikipedia.org/wiki/Yaakov_ben_Moshe_Levi_Moelin) of calculating [getSofZmanKidushLevanaBetweenMoldos] is of the opinion that the Mechaber agrees to his opinion. Also see the Aruch Hashulchan. For additional details on the subject, see Rabbi Dovid Heber's very detailed write-up in _Siman Daled_ (chapter 4) of [Shaarei Zmanim](http://www.hebrewbooks.org/53000). If the time of _sof zman Kiddush Levana_ occurs during the day (between the _alos_ and _tzais_ passed in as parameters), it returns the _alos_ passed in. If a null _alos_ or _tzais_ are passed to this method, the non-daytime adjusted time will be returned. /// [alos] the beginning of the Jewish day. If Kidush Levana occurs during the day (starting at alos and ending at tzais), the time returned will be alos. If either the alos or tzais parameters are null, no daytime adjustment will be made. [tzais] the end of the Jewish day. If Kidush Levana occurs during the day (starting at alos and ending at tzais), the time returned will be alos. If either the alos or tzais parameters are null, no daytime adjustment will be made. /// return the Date representing the moment 15 days after the molad. If the time occurs between _alos_ and _tzais_, _alos_ will be returned /// _see [getSofZmanKidushLevanaBetweenMoldos]_ _see [JewishCalendar.getSofZmanKidushLevana15Days]_
  DateTime? getSofZmanKidushLevana15Days([DateTime? alos, DateTime? tzais]) {
    JewishCalendar jewishCalendar = JewishCalendar();
    jewishCalendar.setGregorianDate(
        getLocalDate().year, getLocalDate().month, getLocalDate().day);

    // Do not calculate for impossible dates, but account for extreme cases. In the extreme case of Rapa Iti in
    // French Polynesia on Dec 2027 when kiddush Levana 3 days can be said on _Rosh Chodesh_, the sof zman Kiddush
    // Levana will be on the 12th of the Teves. in the case of Anadyr, Russia on Jan, 2071, sof zman kiddush levana will
    // occur after midnight on the 17th of Shevat. See Rabbi Dovid Heber's Shaarei Zmanim chapter 4 (pages 28 and 32).
    if (jewishCalendar.getJewishDayOfMonth() < 11 ||
        jewishCalendar.getJewishDayOfMonth() > 17) {
      return null;
    }
    return _getMoladBasedTime(
        jewishCalendar.getSofZmanKidushLevana15Days(), alos, tzais, false);
  }

  /// Returns the earliest time of _Kiddush Levana_ according to _Rabbeinu Yonah_'s opinion that it can
  /// be said 3 days after the molad. If the time of _tchilas zman Kiddush Levana_ occurs during the day (between
  /// _alos_ and _tzais_ passed to this method) it will return the following _tzais_. If null is passed
  /// for either alos or tzais, the actual _tchilas zman Kiddush Levana_ will be returned, regardless of if it is
  /// during the day or not.
  /// This method is available in the current release of the API but may change or be
  /// removed in the future since it depends on the still changing {link JewishCalendar and related classes.
  ///
  /// [alos]
  ///            the beginning of the Jewish day. If Kidush Levana occurs during the day (starting at alos and ending
  ///            at tzais), the time returned will be tzais. If either the alos or tzais parameters are null, no daytime
  ///            adjustment will be made.
  /// [tzais]
  ///            the end of the Jewish day. If Kidush Levana occurs during the day (starting at alos and ending at
  ///            tzais), the time returned will be tzais. If either the alos or tzais parameters are null, no daytime
  ///            adjustment will be made.
  ///
  /// return the Date representing the moment 3 days after the molad. If the time occurs between _alos_ and
  ///         _tzais_, _tzais_ will be returned
  /// _see [getTchilasZmanKidushLevana3Days]_
  /// _see [getTchilasZmanKidushLevana7Days]_
  /// _see [JewishCalendar.getTchilasZmanKidushLevana3Days]_
  DateTime? getTchilasZmanKidushLevana3Days([DateTime? alos, DateTime? tzais]) {
    JewishCalendar jewishCalendar = JewishCalendar();
    jewishCalendar.setGregorianDate(
        getLocalDate().year, getLocalDate().month, getLocalDate().day);

    // Do not calculate for impossible dates, but account for extreme cases. Tchilas zman kiddush Levana 3 days for
    // the extreme case of Rapa Iti in French Polynesia on Dec 2027 when kiddush Levana 3 days can be said on the evening
    // of the 30th, the second night of Rosh Chodesh. The 3rd day after the _molad_ will be on the 4th of the month.
    // In the case of Anadyr, Russia on Jan, 2071, when sof zman kiddush levana is on the 17th of the month, the 3rd day
    // from the molad will be on the 5th day of Shevat. See Rabbi Dovid Heber's Shaarei Zmanim chapter 4 (pages 28 and 32).
    if (jewishCalendar.getJewishDayOfMonth() > 5 &&
        jewishCalendar.getJewishDayOfMonth() < 30) {
      return null;
    }

    DateTime? zman = _getMoladBasedTime(
        jewishCalendar.getTchilasZmanKidushLevana3Days(), alos, tzais, true);

    //Get the following month's zman kiddush Levana for the extreme case of Rapa Iti in French Polynesia on Dec 2027 when
    // kiddush Levana can be said on Rosh Chodesh (the evening of the 30th). See Rabbi Dovid Heber's Shaarei Zmanim chapter 4 (page 32)
    if (zman == null && jewishCalendar.getJewishDayOfMonth() == 30) {
      jewishCalendar.forward(Calendar.MONTH, 1);
      zman = _getMoladBasedTime(
          jewishCalendar.getTchilasZmanKidushLevana3Days(), null, null, true);
    }

    return zman;
  }

  ///Returns the earliest time of _Kiddush Levana_ according to [Rabbeinu Yonah](https://en.wikipedia.org/wiki/Yonah_Gerondi)'s opinion that it can be said 3 days after the _molad_.
  /// If the time of _tchilas zman Kiddush Levana_ occurs during the day (between _alos_ and _tzais_ passed to
  /// this method) it will return the following _tzais_. If null is passed for either _alos_ or _tzais_, the actual
  /// _tchilas zman Kiddush Levana_ will be returned, regardless of if it is during the day or not.
  ///
  /// return the Date representing the moment of the molad. If the molad does not occur on this day, a null will be returned.
  ///
  /// _see [getTchilasZmanKidushLevana3Days]_
  /// _see [getTchilasZmanKidushLevana7Days]_
  /// _see [JewishCalendar#getMoladAsDate]_
  DateTime? getZmanMolad() {
    JewishCalendar jewishCalendar = JewishCalendar();
    jewishCalendar.setGregorianDate(
        getLocalDate().year, getLocalDate().month, getLocalDate().day);

    // Optimize to not calculate for impossible dates, but account for extreme cases. The molad in the extreme case of Rapa
    // Iti in French Polynesia on Dec 2027 occurs on the night of the 27th of Kislev. In the case of Anadyr, Russia on
    // Jan 2071, the molad will be on the 2nd day of Shevat. See Rabbi Dovid Heber's Shaarei Zmanim chapter 4 (pages 28 and 32).
    if (jewishCalendar.getJewishDayOfMonth() > 2 &&
        jewishCalendar.getJewishDayOfMonth() < 27) {
      return null;
    }
    DateTime? molad = _getMoladBasedTime(
        jewishCalendar.getMoladAsDateTime(), null, null, true);

    // deal with molad that happens on the end of the previous month
    if (molad == null && jewishCalendar.getJewishDayOfMonth() > 26) {
      jewishCalendar.forward(Calendar.MONTH, 1);
      molad = _getMoladBasedTime(
          jewishCalendar.getMoladAsDateTime(), null, null, true);
    }
    return molad;
  }



  /// Returns the earliest time of _Kiddush Levana_ according to the opinions that it should not be said until 7
  /// days after the _molad_. The time will be returned even if it occurs during the day when _Kiddush Levana_
  /// can't be recited. Use [getTchilasZmanKidushLevana7Days] if you want to limit the time to night hours.
  /// [alos]
  ///            the beginning of the Jewish day. If Kidush Levana occurs during the day (starting at alos and ending
  ///            at tzais), the time returned will be tzais. If either the alos or tzais parameters are null, no daytime
  ///            adjustment will be made.
  /// [tzais]
  ///            the end of the Jewish day. If Kidush Levana occurs during the day (starting at alos and ending at
  ///            tzais), the time returned will be tzais. If either the alos or tzais parameters are null, no daytime
  ///            adjustment will be made.
  ///
  /// return the Date representing the moment 7 days after the molad. If the time occurs between _alos_ and
  ///         _tzais_, _tzais_ will be returned
  /// _see [getTchilasZmanKidushLevana3Days]
  /// _see [getTchilasZmanKidushLevana7Days]_
  /// _see [JewishCalendar#getTchilasZmanKidushLevana7Days]_
  DateTime? getTchilasZmanKidushLevana7Days([DateTime? alos, DateTime? tzais]) {
    JewishCalendar jewishCalendar = JewishCalendar();
    jewishCalendar.setGregorianDate(
        getLocalDate().year, getLocalDate().month, getLocalDate().day);

    // Optimize to not calculate for impossible dates, but account for extreme cases. Tchilas zman kiddush Levana 7 days for
    // the extreme case of Rapa Iti in French Polynesia on Jan 2028 (when kiddush Levana 3 days can be said on the evening
    // of the 30th, the second night of Rosh Chodesh), the 7th day after the molad will be on the 4th of the month.
    // In the case of Anadyr, Russia on Jan, 2071, when sof zman kiddush levana is on the 17th of the month, the 7th day
    // from the molad will be on the 9th day of Shevat. See Rabbi Dovid Heber's Shaarei Zmanim chapter 4 (pages 28 and 32).
    if (jewishCalendar.getJewishDayOfMonth() < 4 ||
        jewishCalendar.getJewishDayOfMonth() > 9) {
      return null;
    }

    return _getMoladBasedTime(
        jewishCalendar.getTchilasZmanKidushLevana7Days(), alos, tzais, true);
  }

  /// This method returns the latest time one is allowed eating chametz on Erev Pesach according to the opinion of the
  /// _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_. This time is identical to the
  /// [getSofZmanTfilaGRA] Sof zman tfilah GRA and is provided as a convenience method for those who are unaware how
  /// this zman is calculated. This time is 4 hours into the day based on the opinion of the
  /// _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_ that the day is calculated from sunrise to sunset. This
  /// returns the time 4 * [getShaahZmanisGRA] after [getSeaLevelSunrise] sea level sunrise.
  ///
  /// _see [ZmanimCalendar.getShaahZmanisGRA]_
  /// _see [ZmanimCalendar.getSofZmanTfilaGRA]_
  /// return the `DateTime` one is allowed eating chametz on Erev Pesach. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getSofZmanAchilasChametzGRA() => getSofZmanAchilasChametz(
      getSunriseBasedOnElevationSetting(), getSunsetBasedOnElevationSetting(), true);

  /// This method returns the latest time one is allowed eating chametz on Erev Pesach according to the opinion of the
  /// _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on _alos_
  /// being [getAlos72Minutes] minutes before [getSunrise]. This time is identical to the
  /// [getSofZmanTfilaMGA72Minutes]. This time is 4 _[getShaahZmanis72Minutes]_ (temporal hours) after [getAlos72Minutes] based on the opinion of the _MGA_ that
  /// the day is calculated from a [getAlos72Minutes] of 72 minutes before sunrise to [getTzais72Minutes]
  /// of 72 minutes after sunset. This returns the time of 4 * [getShaahZmanis72Minutes] after [getAlos72Minutes].
  /// return the `DateTime` of the latest time of eating chametz. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set), a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis72Minutes]_
  /// _see [getAlos72Minutes]_
  /// _see [getSofZmanTfilaMGA72Minutes]_
  DateTime? getSofZmanAchilasChametzMGA72Minutes() =>
      getSofZmanAchilasChametz(getAlos72Minutes(), getTzais72Minutes(), true);

  /// This method returns the latest time one is allowed eating chametz on Erev Pesach according to the opinion of the
  ///  _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on _alos_
  /// being [getAlos16Point1Degrees] before [getSunrise]. This time is 4 <em>{@link
  /// #getShaahZmanis16Point1Degrees() shaos zmaniyos}</em> (solar hours) after [getAlos16Point1Degrees]
  /// based on the opinion of the _MGA_ that the day is calculated from dawn to nightfall with both being 16.1°
  /// below sunrise or sunset. This returns the time of 4 [getShaahZmanis16Point1Degrees] after
  /// [getAlos16Point1Degrees].
  ///
  /// return the `DateTime` of the latest time of eating chametz. If the calculation can't be computed such as
  ///         northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle where
  ///         the sun may not reach low enough below the horizon for this calculation, a null will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getShaahZmanis16Point1Degrees]_
  /// _see [getAlos16Point1Degrees]_
  /// _see [getSofZmanTfilaMGA16Point1Degrees]_
  DateTime? getSofZmanAchilasChametzMGA16Point1Degrees() =>
      getSofZmanAchilasChametz(
          getAlos16Point1Degrees(), getTzais16Point1Degrees(), true);

  /// This method returns the latest time for burning chametz on Erev Pesach according to the opinion of the
  /// _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_ This time is 5 hours into the day based on the
  /// opinion of the _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_ that the day is calculated from
  /// sunrise to sunset. This returns the time 5 * [getShaahZmanisGRA] after [getSeaLevelSunrise].
  ///
  /// _see [ZmanimCalendar.getShaahZmanisGRA]
  /// return the `DateTime` of the latest time for burning chametz on Erev Pesach. If the calculation can't be
  ///         computed such as in the Arctic Circle where there is at least one day a year where the sun does not rise,
  ///         and one where it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getSofZmanBiurChametzGRA() => getSofZmanBiurChametz(
      getSunriseBasedOnElevationSetting(), getSunsetBasedOnElevationSetting(), true);

  /// This method returns the latest time for burning chametz on Erev Pesach according to the opinion of the
  /// _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on _alos_
  /// being [getAlos72Minutes] minutes before [getSunrise]. This time is 5 <em>{@link
  /// #getShaahZmanis72Minutes() shaos zmaniyos}</em> (temporal hours) after [getAlos72Minutes] based on the opinion of
  /// the _MGA_ that the day is calculated from a [getAlos72Minutes] of 72 minutes before sunrise to {@link
  /// #getTzais72Minutes() nightfall} of 72 minutes after sunset. This returns the time of 5 * [getShaahZmanis72Minutes] after
  /// [getAlos72Minutes].
  ///
  /// return the `DateTime` of the latest time for burning chametz on Erev Pesach. If the calculation can't be
  ///         computed such as in the Arctic Circle where there is at least one day a year where the sun does not rise,
  ///         and one where it does not set), a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getShaahZmanis72Minutes]_
  /// _see [getAlos72Minutes]_
  DateTime? getSofZmanBiurChametzMGA72Minutes() =>
      getSofZmanBiurChametz(getAlos72Minutes(), getTzais72Minutes(), true);

  /// This method returns the latest time for burning _chametz_ on _Erev Pesach_ according to the opinion
  /// of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on _alos_
  /// being [getAlos16Point1Degrees] before [getSunrise]. This time is 5
  /// _[getShaahZmanis16Point1Degrees]_ (solar hours) after [getAlos16Point1Degrees] based on the opinion of the _MGA_ that the day is calculated from dawn to nightfall with both being 16.1°
  /// below sunrise or sunset. This returns the time of 5 [getShaahZmanis16Point1Degrees] after
  /// [getAlos16Point1Degrees].
  ///
  /// return the `DateTime` of the latest time for burning chametz on Erev Pesach. If the calculation can't be
  ///         computed such as northern and southern locations even south of the Arctic Circle and north of the
  ///         Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, a null
  ///         will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getShaahZmanis16Point1Degrees]_
  /// _see [getAlos16Point1Degrees]_
  DateTime? getSofZmanBiurChametzMGA16Point1Degrees() =>
      getSofZmanBiurChametz(getAlos16Point1Degrees(), getTzais16Point1Degrees(), true);



  /// A method that returns the _[Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)_'s
  /// a _shaah zmanis_ ([getTemporalHour] temporal hour). This forms the base for the
  /// _Baal Hatanya_'s  day  based calculations that are calculated
  /// as a 1.583° dip below the horizon after sunset.
  ///
  /// According to the _Baal Hatanya_, _shkiah amiti_, true (halachic) sunset, is when the top of the
  /// sun's disk disappears from view at an elevation similar to the mountains of Eretz Yisrael.
  /// This time is calculated as the point at which the center of the sun's disk is 1.583 degrees below the horizon.
  ///
  ///
  ///
  /// A method that returns a _shaah zmanis_ ( [getTemporalHour] temporal hour) calculated
  /// based on the _[Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)_'s _netz
  /// amiti_ and _shkiah amiti_ using a dip of 1.583° below the sea level horizon. This calculation divides
  /// the day based on the opinion of the _Baal Hatanya_ that the day runs from [getSunriseBaalHatanya]
  /// netz amiti to [getSunsetBaalHatanya] shkiah amiti. The calculations are based on a day from {link
  /// #getSunriseBaalHatanya] sea level netz amiti to [getSunsetBaalHatanya] sea level shkiah amiti. The day
  /// is split into 12 equal parts with each one being a _shaah zmanis_. This method is similar to {link
  /// #getTemporalHour, but all calculations are based on a sea level sunrise and sunset.
  /// todo Copy sunrise and sunset comments here as applicable.
  /// return the `double` millisecond length of a _shaah zmanis_ calculated from
  ///         [getSunriseBaalHatanya] _netz amiti_ (sunrise) to [getSunsetBaalHatanya] _shkiah amiti_
  ///         ("real" sunset). If the calculation can't be computed such as in the Arctic Circle where there is at least one day a
  ///         year where the sun does not rise, and one where it does not set, double.minPositive will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  /// _see [getTemporalHour]_
  /// _see [getSunriseBaalHatanya]_
  /// _see [getSunsetBaalHatanya]_
  /// _see [ZENITH_1_POINT_583]_
  ///
  Duration? getShaahZmanisBaalHatanya() =>
      getTemporalHour(getSunriseBaalHatanya(), getSunsetBaalHatanya());

  /// Returns the _[Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)_'s _alos_
  /// (dawn) calculated as the time when the sun is 16.9° below the eastern [GEOMETRIC_ZENITH]
  /// before [getSunrise]. For more information the source of 16.9° see [ZENITH_16_POINT_9].
  ///
  /// _see [ZENITH_16_POINT_9]_
  /// return The `DateTime` of dawn. If the calculation can't be computed such as northern and southern
  ///         locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach
  ///         low enough below the horizon for this calculation, a null will be returned. See detailed explanation on
  ///         top of the [AstronomicalCalendar] documentation.
  DateTime? getAlosBaalHatanya() =>
      getSunriseOffsetByDegrees(ZENITH_16_POINT_9);

  /// This method returns the latest _zman krias shema_ (time to recite Shema in the morning). This time is 3
  /// _[getShaahZmanisBaalHatanya] shaos zmaniyos_ (solar hours) after [getSunriseBaalHatanya]
  /// _netz amiti_ (sunrise) based on the opinion of the _Baal Hatanya_ that the day is calculated from
  /// sunrise to sunset. This returns the time 3 * [getShaahZmanisBaalHatanya] after [getSunriseBaalHatanya]
  /// _netz amiti_ (sunrise).
  ///
  /// _see [ZmanimCalendar#getSofZmanShma]_
  /// _see [getShaahZmanisBaalHatanya]_
  /// return the `DateTime` of the latest zman shema according to the Baal Hatanya. If the calculation
  ///         can't be computed such as in the Arctic Circle where there is at least one day a year where the sun does
  ///         not rise, and one where it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getSofZmanShmaBaalHatanya() =>
      getSofZmanShma(getSunriseBaalHatanya(), getSunsetBaalHatanya(), true);

  /// This method returns the latest _zman tfilah_ (time to recite the morning prayers). This time is 4
  /// hours into the day based on the opinion of the _Baal Hatanya_ that the day is
  /// calculated from sunrise to sunset. This returns the time 4 * [getShaahZmanisBaalHatanya] after
  /// [getSunriseBaalHatanya] _netz amiti_ (sunrise).
  ///
  /// _see [ZmanimCalendar.getSofZmanTfila]_
  /// _see [getShaahZmanisBaalHatanya]_
  /// return the `DateTime` of the latest zman tfilah. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getSofZmanTfilaBaalHatanya() =>
      getSofZmanTfila(getSunriseBaalHatanya(), getSunsetBaalHatanya(), true);

  /// This method returns the latest time one is allowed eating chametz on Erev Pesach according to the opinion of the
  /// _Baal Hatanya_. This time is identical to the [getSofZmanTfilaBaalHatanya] Sof zman
  /// tfilah Baal Hatanya. This time is 4 hours into the day based on the opinion of the _Baal
  /// Hatanya_ that the day is calculated from sunrise to sunset. This returns the time 4 *
  /// [getShaahZmanisBaalHatanya] after [getSunriseBaalHatanya] _netz amiti_ (sunrise).
  ///
  /// see [getShaahZmanisBaalHatanya]
  /// see [getSofZmanTfilaBaalHatanya]
  /// return the `DateTime` one is allowed eating chametz on Erev Pesach. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getSofZmanAchilasChametzBaalHatanya() =>
      getSofZmanAchilasChametz(getSunriseBaalHatanya(), getSunsetBaalHatanya(), true);

  /// This method returns the latest time for burning chametz on Erev Pesach according to the opinion of the
  /// _Baal Hatanya_. This time is 5 hours into the day based on the opinion of the
  /// _Baal Hatanya_ that the day is calculated from sunrise to sunset. This returns the
  /// time 5 * [getShaahZmanisBaalHatanya] after [getSunriseBaalHatanya] _netz amiti_ (sunrise).
  ///
  /// _see [getShaahZmanisBaalHatanya]_
  /// return the `DateTime` of the latest time for burning chametz on Erev Pesach. If the calculation can't be
  ///         computed such as in the Arctic Circle where there is at least one day a year where the sun does not rise,
  ///         and one where it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getSofZmanBiurChametzBaalHatanya() =>
      getSofZmanBiurChametz(getSunriseBaalHatanya(), getSunsetBaalHatanya(), true);

  /// This method returns the time of _mincha gedola_. _Mincha gedola_ is the earliest time one can pray
  /// mincha. The _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_ is of the opinion that it is
  /// better to delay _mincha_ until _[getMinchaKetanaBaalHatanya] mincha ketana_ while the
  /// _[Ra"sh](https://en.wikipedia.org/wiki/Asher_ben_Jehiel)_,
  /// _[Tur](https://en.wikipedia.org/wiki/Jacob_ben_Asher)_, _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_
  /// and others are of the opinion that _mincha_ can be prayed
  /// _lechatchila_ starting at _mincha gedola_. This is calculated as 6.5 [getShaahZmanisBaalHatanya]
  /// sea level solar hours after [getSunriseBaalHatanya] _netz amiti_ (sunrise). This calculation is based
  /// on the opinion of the _Baal Hatanya_ that the day is calculated from sunrise to sunset. This returns the time 6.5 *
  /// [getShaahZmanisBaalHatanya] after [getSunriseBaalHatanya] _netz amiti_ ("real" sunrise).
  ///
  /// _see [getMinchaGedola]_
  /// _see [getShaahZmanisBaalHatanya]_
  /// _see [getMinchaKetanaBaalHatanya]_
  /// return the `DateTime` of the time of mincha gedola. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getMinchaGedolaBaalHatanya() =>
      getMinchaGedola(getSunriseBaalHatanya(), getSunsetBaalHatanya(), true);


  /// This method returns the time of _mincha ketana_. This is the preferred earliest time to pray
  /// _mincha_ in the opinion of the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_ and others.
  /// For more information on this see the documentation on _[getMinchaGedolaBaalHatanya] mincha gedola_.
  /// This is calculated as 9.5 [getShaahZmanisBaalHatanya]  sea level solar hours after [getSunriseBaalHatanya]
  /// _netz amiti_ (sunrise). This calculation is calculated based on the opinion of the _Baal Hatanya_ that the
  /// day is calculated from sunrise to sunset. This returns the time 9.5 * [getShaahZmanisBaalHatanya] after
  /// [getSunriseBaalHatanya] _netz amiti_ (sunrise).
  ///
  /// _see [getMinchaKetana]_
  /// _see [getShaahZmanisBaalHatanya]_
  /// _see [getMinchaGedolaBaalHatanya]_
  /// return the `DateTime` of the time of mincha ketana. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  ///         documentation.
  DateTime? getMinchaKetanaBaalHatanya() =>
      getMinchaKetana(getSunriseBaalHatanya(), getSunsetBaalHatanya(), true);

  /// This method returns the time of _plag hamincha_. This is calculated as 10.75 hours after sunrise. This
  /// calculation is based on the opinion of the _Baal Hatanya_ that the day is calculated
  /// from sunrise to sunset. This returns the time 10.75 * [getShaahZmanisBaalHatanya] after
  /// [getSunriseBaalHatanya] _netz amiti_ (sunrise).
  ///
  /// _see [getPlagHamincha]_
  /// return the `DateTime` of the time of _plag hamincha_. If the calculation can't be computed such as
  ///         in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getPlagHaminchaBaalHatanya() =>
      getPlagHamincha(getSunriseBaalHatanya(), getSunsetBaalHatanya(), true);

  /// A method that returns _tzais_ (nightfall) when the sun is 6° below the western geometric horizon
  /// (90°) after [getSunset sunset. For information on the source of this calculation see
  /// [ZENITH_6_DEGREES].
  ///
  /// return The `DateTime` of nightfall. If the calculation can't be computed such as northern and southern
  ///         locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach
  ///         low enough below the horizon for this calculation, a null will be returned. See detailed explanation on
  ///         top of the [AstronomicalCalendar] documentation.
  /// _see [ZENITH_6_DEGREES]_
  DateTime? getTzaisBaalHatanya() => getSunsetOffsetByDegrees(ZENITH_6_DEGREES);


  /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
  /// claculation of _sof zman krias shema_ (latest time to recite _Shema_ in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ that the
  /// day is calculated from dawn to nightfall, but calculated using the first half of the day only. The half a day starts
  /// at _alos_ defined as [getAlos18Degrees] and ends at [getFixedLocalChatzosHayom]. _Sof Zman Shema_ is 3 _shaos zmaniyos_ (solar hours) after _alos_ or half of this half-day.
  ///
  /// Returns the `Date` of the latest _zman krias shema_. If the calculation can't be computed such
  /// as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  /// where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  /// See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// See also [getAlos18Degrees].
  /// See also [getFixedLocalChatzosHayom].
  /// See also [getFixedLocalChatzosBasedZmanim].
  DateTime? getSofZmanShmaMGA18DegreesToFixedLocalChatzos() {
    return getHalfDayBasedZman(
        getAlos18Degrees(), getFixedLocalChatzosHayom(), 3);
  }

  /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
  /// claculation of _sof zman krias shema_ (latest time to recite _Shema_ in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ that the
  /// day is calculated from dawn to nightfall, but calculated using the first half of the day only. The half a day starts
  /// at _alos_ defined as [getAlos16Point1Degrees] and ends at [getFixedLocalChatzosHayom]. _Sof Zman Shema_ is 3 _shaos zmaniyos_ (solar hours) after this _alos_ or half of this half-day.
  ///
  /// Returns the `Date` of the latest _zman krias shema_. If the calculation can't be computed such
  /// as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  /// where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  /// See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// See also [getAlos16Point1Degrees].
  /// See also [getFixedLocalChatzosHayom].
  /// See also [getFixedLocalChatzosBasedZmanim].

  DateTime? getSofZmanShmaMGA16Point1DegreesToFixedLocalChatzos() {
    return getHalfDayBasedZman(
        getAlos16Point1Degrees(), getFixedLocalChatzosHayom(), 3);
  }

  /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
  /// claculation of _sof zman krias shema_ (latest time to recite _Shema_ in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ that the
  /// day is calculated from dawn to nightfall, but calculated using the first half of the day only. The half a day starts
  /// at _alos_ defined as [getAlos90Minutes] and ends at [getFixedLocalChatzosHayom]. _Sof Zman Shema_ is 3 _shaos zmaniyos_ (solar hours) after this _alos_ or
  /// half of this half-day.
  ///
  /// Returns the `Date` of the latest _zman krias shema_. If the calculation can't be computed such
  /// as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  /// where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  /// See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// See also [getAlos90Minutes].
  /// See also [getFixedLocalChatzosHayom].
  /// See also [getFixedLocalChatzosBasedZmanim].
  DateTime? getSofZmanShmaMGA90MinutesToFixedLocalChatzos() {
    return getHalfDayBasedZman(
        getAlos90Minutes(), getFixedLocalChatzosHayom(), 3);
  }

  /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
  /// claculation of _sof zman krias shema_ (latest time to recite _Shema_ in the morning) according to the
  /// opinion of the _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ that the
  /// day is calculated from dawn to nightfall, but calculated using the first half of the day only. The half a day starts
  /// at _alos_ defined as [getAlos72Minutes] and ends at [getFixedLocalChatzosHayom]. _Sof Zman Shema_ is 3 _shaos zmaniyos_ (solar hours) after this _alos_ or
  /// half of this half-day.
  ///
  /// Returns the `Date` of the latest _zman krias shema_. If the calculation can't be computed such
  /// as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  /// where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  /// See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// See also [getAlos72Minutes].
  /// See also [getFixedLocalChatzosHayom].
  /// See also [getFixedLocalChatzosBasedZmanim].
  DateTime? getSofZmanShmaMGA72MinutesToFixedLocalChatzos() {
    return getHalfDayBasedZman(
        getAlos72Minutes(), getFixedLocalChatzosHayom(), 3);
  }

  /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
  /// claculation of _sof zman krias shema_ (latest time to recite _Shema_ in the morning) according to the
  /// opinion of the _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_ that the day is calculated from
  /// sunrise to sunset, but calculated using the first half of the day only. The half a day starts at [getSunrise] and ends at [getFixedLocalChatzosHayom]. _Sof Zman Shema_ is 3 <em>shaos
  /// zmaniyos</em> (solar hours) after sunrise or half of this half-day.
  ///
  /// Returns the `Date` of the latest _zman krias shema_. If the calculation can't be computed such
  /// as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  /// where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  /// See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// See also [getSunrise].
  /// See also [getFixedLocalChatzosHayom].
  /// See also [getFixedLocalChatzosBasedZmanim].
  DateTime? getSofZmanShmaGRASunriseToFixedLocalChatzos() {
    return getHalfDayBasedZman(
        getSunriseBasedOnElevationSetting(), getFixedLocalChatzosHayom(), 3);
  }

  /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
  /// claculation of _sof zman tfila_ (_zman tfilah_ (the latest time to recite the morning prayers))
  /// according to the opinion of the _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_ that the day is
  /// calculated from sunrise to sunset, but calculated using the first half of the day only. The half a day starts at
  /// [getSunrise] and ends at [getFixedLocalChatzosHayom]. _Sof zman tefila_
  /// is 4 _shaos zmaniyos_ (solar hours) after sunrise or 2/3 of this half-day.
  ///
  /// Returns the `Date` of the latest _zman krias shema_. If the calculation can't be computed such
  /// as northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
  /// where the sun may not reach low enough below the horizon for this calculation, a null will be returned.
  /// See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// See also [getSunrise].
  /// See also [getFixedLocalChatzosHayom].
  /// See also [getFixedLocalChatzosBasedZmanim].
  DateTime? getSofZmanTfilaGRASunriseToFixedLocalChatzos() {
    return getHalfDayBasedZman(
        getSunriseBasedOnElevationSetting(), getFixedLocalChatzosHayom(), 4);
  }

  /// This method returns returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion
  /// of the calculation of _mincha gedola_,the earliest time one can pray _mincha_ _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_that is 30 minutes after[getFixedLocalChatzosHayom].
  ///
  /// Returns the `Date` of the time of mincha gedola. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  /// documentation.
  ///
  /// See also [getMinchaGedola].
  /// See also [getFixedLocalChatzosHayom].
  /// See also [getMinchaKetanaGRAFixedLocalChatzosToSunset].
  DateTime? getMinchaGedolaGRAFixedLocalChatzos30Minutes() {
    return AstronomicalCalendar.getTimeOffset(getFixedLocalChatzosHayom(), const Duration(minutes: 30));
  }

  /// This method returns returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion
  /// of the calculation of _mincha ketana_ (the preferred time to recite the mincha prayers according to the
  /// opinion of the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_ and others) calculated according
  /// to the _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_that is 3.5 _shaos zmaniyos_ (solar
  /// hours) after [getFixedLocalChatzosHayom].
  ///
  /// Returns the `Date` of the time of mincha gedola. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  /// documentation.
  ///
  /// See also [getMinchaGedola].
  /// See also [getFixedLocalChatzosHayom].
  /// See also [getMinchaGedolaGRAFixedLocalChatzos30Minutes].
  DateTime? getMinchaKetanaGRAFixedLocalChatzosToSunset() {
    return getHalfDayBasedZman(
        getFixedLocalChatzosHayom(), getSunsetBasedOnElevationSetting(), 3.5);
  }

  /// This method returns returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion
  /// of the calculation of This method returns _plag hamincha_ calculated according to the
  /// _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_that is 4.75 _shaos zmaniyos_ (solar
  /// hours) after [getFixedLocalChatzosHayom].
  ///
  /// Returns the `Date` of the time of mincha gedola. If the calculation can't be computed such as in the
  /// Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  /// not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  /// documentation.
  ///
  /// See also [getPlagHamincha].
  /// See also [getFixedLocalChatzosHayom].
  /// See also [getMinchaKetanaGRAFixedLocalChatzosToSunset].
  /// See also [getMinchaGedolaGRAFixedLocalChatzos30Minutes].
  DateTime? getPlagHaminchaGRAFixedLocalChatzosToSunset() {
    return getHalfDayBasedZman(
        getFixedLocalChatzosHayom(), getSunsetBasedOnElevationSetting(), 4.75);
  }

  /// Method to return _tzais_ (dusk) calculated as 50 minutes after sea level sunset. This method returns
  /// _tzais_ (nightfall) based on the opinion of Rabbi Moshe Feinstein for the New York area. This time should
  /// not be used for latitudes different than the NY area.
  ///
  /// Returns the `Date` representing the time. If the calculation can't be computed such as in the Arctic
  /// Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  /// a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  /// documentation.
  DateTime? getTzais50Minutes() {
    return AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), const Duration(minutes: 50));
  }










  @override
  ComprehensiveZmanimCalendar clone() =>
      copyZmanimSettings(this, ComprehensiveZmanimCalendar.withGeoLocation(getGeoLocation()))
        .._ateretTorahSunsetOffset = _ateretTorahSunsetOffset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ComprehensiveZmanimCalendar || !(super == other)) {
      return false;
    }
    return _ateretTorahSunsetOffset == other._ateretTorahSunsetOffset;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, _ateretTorahSunsetOffset);

  /// This method returns _mincha gedola_ according to the _Ahavat Shalom_ calculation:
  /// half a _shaah zmanis_ after [getChatzos], where the _shaah zmanis_ is measured from
  /// [getAlos16Point1Degrees] to [getTzaisGeonim3Point7Degrees], or 30 minutes after
  /// _chatzos_ where that is later.
  ///
  /// return the `DateTime` of _mincha gedola_, or null if it cannot be computed.
  DateTime? getMinchaGedolaAhavatShalom() {
    final DateTime? chatzos = getChatzosHayom();
    final DateTime? minchaGedola30 = getMinchaGedola30Minutes();
    final DateTime? alos = getAlos16Point1Degrees();
    final DateTime? tzais = getTzaisGeonim3Point7Degrees();
    if (chatzos == null || minchaGedola30 == null || alos == null || tzais == null) {
      return null;
    }
    final DateTime minchaGedolaAhavatShalom = offsetByParts(chatzos, alos, tzais, 12, 0.5);
    return minchaGedola30.compareTo(minchaGedolaAhavatShalom) > 0 ? minchaGedola30 : minchaGedolaAhavatShalom;
  }

  /// This method returns _mincha ketana_ according to the _Ahavat Shalom_ calculation:
  /// 2.5 _shaos zmaniyos_ before [getTzaisGeonim3Point8Degrees], where the _shaah
  /// zmanis_ is measured from [getAlos16Point1Degrees] to that _tzais_.
  ///
  /// return the `DateTime` of _mincha ketana_, or null if it cannot be computed.
  DateTime? getMinchaKetanaAhavatShalom() {
    final DateTime? alos = getAlos16Point1Degrees();
    final DateTime? tzais = getTzaisGeonim3Point8Degrees();
    if (alos == null || tzais == null) {
      return null;
    }
    return offsetByParts(tzais, alos, tzais, 12, -2.5);
  }

  /// This method returns _plag hamincha_ according to the _Ahavat Shalom_ calculation:
  /// 1.25 _shaos zmaniyos_ before [getTzaisGeonim3Point8Degrees], where the _shaah
  /// zmanis_ is measured from [getAlos16Point1Degrees] to that _tzais_.
  ///
  /// return the `DateTime` of _plag hamincha_, or null if it cannot be computed.
  DateTime? getPlagAhavatShalom() {
    final DateTime? alos = getAlos16Point1Degrees();
    final DateTime? tzais = getTzaisGeonim3Point8Degrees();
    if (alos == null || tzais == null) {
      return null;
    }
    return offsetByParts(tzais, alos, tzais, 12, -1.25);
  }

  /// This method returns _misheyakir_ based on the sun being [ZENITH_12_POINT_85]
  /// 12.85° below the eastern horizon before sunrise.
  ///
  /// return the `DateTime` of _misheyakir_, or null if it cannot be computed.
  DateTime? getMisheyakir12Point85Degrees() =>
      getSunriseOffsetByDegrees(ZENITH_12_POINT_85);

  /// This method returns _tzais_ based on the sun being [ZENITH_4_POINT_42] 4.42°
  /// below the western horizon after sunset.
  ///
  /// return the `DateTime` of _tzais_, or null if it cannot be computed.
  DateTime? getTzaisGeonim4Point42Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_4_POINT_42);

  /// This method returns _tzais_ based on the sun being [ZENITH_4_POINT_66] 4.66°
  /// below the western horizon after sunset.
  ///
  /// return the `DateTime` of _tzais_, or null if it cannot be computed.
  DateTime? getTzaisGeonim4Point66Degrees() =>
      getSunsetOffsetByDegrees(ZENITH_4_POINT_66);

  /// This method returns _samuch lemincha ketana_ with the day measured from
  /// [getSunrise] to [getSunset] (depending on the [isUseElevation] setting).
  ///
  /// return the `DateTime` of _samuch lemincha ketana_, or null if it cannot be computed.
  DateTime? getSamuchLeMinchaKetanaGRA() => getSamuchLeMinchaKetana(
      getSunriseBasedOnElevationSetting(), getSunsetBasedOnElevationSetting(), true);

  /// This method returns _samuch lemincha ketana_ with the day measured from
  /// [getAlos16Point1Degrees] to [getTzais16Point1Degrees].
  ///
  /// return the `DateTime` of _samuch lemincha ketana_, or null if it cannot be computed.
  DateTime? getSamuchLeMinchaKetana16Point1Degrees() =>
      getSamuchLeMinchaKetana(
          getAlos16Point1Degrees(), getTzais16Point1Degrees(), true);

  /// This method returns _samuch lemincha ketana_ with the day measured from [getAlos72Minutes]
  /// to [getTzais72Minutes].
  ///
  /// return the `DateTime` of _samuch lemincha ketana_, or null if it cannot be computed.
  DateTime? getSamuchLeMinchaKetana72Minutes() =>
      getSamuchLeMinchaKetana(getAlos72Minutes(), getTzais72Minutes(), true);

  /// This method returns the latest time one may eat _chametz_ on _erev Pesach_
  /// according to the opinion of the _MGA_ with the day measured from [getAlos72Zmanis]
  /// to [getTzais72Zmanis].
  ///
  /// return the `DateTime` of _sof zman achilas chametz_, or null if it cannot be computed.
  DateTime? getSofZmanAchilasChametzMGA72MinutesZmanis() =>
      getSofZmanAchilasChametz(getAlos72Zmanis(), getTzais72Zmanis(), true);

  /// This method returns the latest time for burning _chametz_ on _erev Pesach_
  /// according to the opinion of the _MGA_ with the day measured from [getAlos72Zmanis]
  /// to [getTzais72Zmanis].
  ///
  /// return the `DateTime` of _sof zman biur chametz_, or null if it cannot be computed.
  DateTime? getSofZmanBiurChametzMGA72MinutesZmanis() =>
      getSofZmanBiurChametz(getAlos72Zmanis(), getTzais72Zmanis(), true);

  /// This method returns the _Ben Ish Chai_'s sunrise for a day on which the sun does
  /// not rise or set: the moment it is due east. It answers null on any day that has a
  /// real sunrise, which is the only day this substitute is for.
  ///
  /// return the `DateTime` the sun is due east, or null where the day has a sunrise.
  DateTime? getPolarSunriseBenIshChai() {
    if (getSunriseBasedOnElevationSetting() != null) {
      return null;
    }
    return getTimeAtAzimuth90Or270(90);
  }

  /// This method returns the _Ben Ish Chai_'s sunset for a day on which the sun does not
  /// rise or set: the moment it is due west. It answers null on any day that has a real
  /// sunset, which is the only day this substitute is for.
  ///
  /// return the `DateTime` the sun is due west, or null where the day has a sunset.
  DateTime? getPolarSunsetBenIshChai() {
    if (getSunsetBasedOnElevationSetting() != null) {
      return null;
    }
    return getTimeAtAzimuth90Or270(270);
  }

  DateTime? getPolarPlagHaminchaBenIshChai() => getPlagHamincha(
      getPolarSunriseBenIshChai(), getPolarSunsetBenIshChai(), true);

  DateTime? getPolarStartOfDayTeshuvosVehanhagos() {
    if (getSunriseBasedOnElevationSetting() != null ||
        getSunsetBasedOnElevationSetting() != null) {
      return null;
    }
    final DateTime? chatzosHayom = getChatzosHayom();
    final DateTime? chatzosHalayla = getChatzosHalayla();
    final AstronomicalCalculator calculator = getAstronomicalCalculator();
    final double chatzosHayomElevation =
        calculator.getSolarElevation(chatzosHayom!, getGeoLocation());
    final double chatzosHalaylaElevation =
        calculator.getSolarElevation(chatzosHalayla!, getGeoLocation());
    final double sunriseElevation =
        calculator.getSolarRadius() + calculator.getRefraction();
    if (chatzosHayomElevation < -sunriseElevation &&
        chatzosHalaylaElevation < -sunriseElevation &&
        getAlos16Point1Degrees() == null &&
        getSunriseBasedOnElevationSetting() == null) {
      return chatzosHayom;
    }
    if (chatzosHayomElevation > -sunriseElevation &&
        chatzosHalaylaElevation > -sunriseElevation) {
      return chatzosHalayla;
    }
    return null;
  }

  DateTime? getPolarPlagHaminchaTeshuvosVehanhagos() {
    final DateTime? polarStartOfDay = getPolarStartOfDayTeshuvosVehanhagos();
    if (polarStartOfDay == null) {
      return null;
    }
    return getPlagHamincha(
        polarStartOfDay.subtract(const Duration(days: 1)), polarStartOfDay, true);
  }
}
