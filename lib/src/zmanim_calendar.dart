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
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA,
 * or connect to: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
 */

import 'package:kosher_dart/src/hebrewcalendar/jewish_calendar.dart';
import 'package:kosher_dart/src/hebrewcalendar/jewish_date.dart';
import 'package:kosher_dart/src/util/geo_location.dart';
import 'package:kosher_dart/src/astronomical_calendar.dart';
import 'package:meta/meta.dart';

/// The ZmanimCalendar is arrow_expand specialized calendar that can calculate sunrise and sunset and Jewish _zmanim_
/// (religious times) for prayers and other Jewish religious duties. This class contains the main functionality of the
///  _Zmanim_ library. For a much more extensive list of _zmanim_, use the [ComprehensiveZmanimCalendar] that
/// extends this class. See documentation for the [ComprehensiveZmanimCalendar] and [AstronomicalCalendar] for
/// simple examples on using the API. According to Rabbi Dovid Yehudah Bursztyn in his
/// [Zmanim Kehilchasam (second edition published in 2007)](http://www.worldcat.org/oclc/659793988) chapter 2
/// (pages 186-187) no _zmanim_ besides sunrise and sunset should use elevation. However, Rabbi Yechiel Avrahom
/// Zilber in the [Birur Halacha Vol. 6](http://hebrewbooks.org/51654) Ch. 58 Pages
/// [34](http://hebrewbooks.org/pdfpager.aspx?req=51654&pgnum=42) and
/// [42](http://hebrewbooks.org/pdfpager.aspx?req=51654&pgnum=50) is of the opinion that elevation should be
/// accounted for in _zmanim_ calculations. Related to this, Rabbi Yaakov Karp in [Shimush Zekeinim](http://www.worldcat.org/oclc/919472094), Ch. 1, page 17 states that obstructing horizons should
///  be factored into _zmanim_ calculations. The setting defaults to false (elevation will not be used for
/// _zmanim_ calculations besides sunrise and sunset), unless the setting is changed to true in {@link
/// #setUseElevation(boolean)}. This will impact sunrise and sunset-based <em>zmanim<em> such as [getSunrise],
/// [getSunset], [getSofZmanShmaGRA], _alos_-based _zmanim_ such as [getSofZmanShmaMGA72Minutes]
/// that are based on a fixed offset of sunrise or sunset and _zmanim_ based on a percentage of the day such as
/// [ComprehensiveZmanimCalendar.getSofZmanShmaMGA90MinutesZmanis] that are based on sunrise and sunset. Even when set to
/// true it will not impact _zmanim_ that are a degree-based offset of sunrise and sunset, such as {@link
/// ComprehensiveZmanimCalendar#getSofZmanShmaMGA16Point1Degrees()} or [ComprehensiveZmanimCalendar.getSofZmanShmaBaalHatanya].
///
///  **Note:** It is important to read the technical notes on top of the [AstronomicalCalculator] documentation
///  before using this code.
/// I would like to thank [Rabbi Yaakov Shakow](https://www.worldcat.org/search?q=au%3AShakow%2C+Yaakov), the
/// author of Luach Ikvei Hayom who spent a considerable amount of time reviewing, correcting and making suggestions on the
/// documentation in this library.
/// ## Disclaimer: I did my best to get accurate results, but please double-check before relying on these
/// _zmanim_ for _halacha lemaaseh_.
///
/// © Eliyahu Hershfeld 2004 - 2020
///
class ZmanimCalendar extends AstronomicalCalendar {
  /// Is elevation factored in for some zmanim (see [isUseElevation] for additional information).
  /// * see [isUseElevation]
  /// * see [setUseElevation]
  bool _useElevation = false;

  /// Is elevation above sea level calculated for times besides sunrise and sunset. According to Rabbi Dovid Yehuda
  /// Bursztyn in his [Zmanim Kehilchasam (second edition published in 2007)](http://www.worldcat.org/oclc/659793988)
  /// chapter 2 (pages 186-187) no zmanim besides sunrise and sunset should use elevation. However Rabbi
  /// Yechiel Avrahom Zilber in the [Birur Halacha Vol. 6](http://hebrewbooks.org/51654) Ch. 58 Pages
  /// [34](http://hebrewbooks.org/pdfpager.aspx?req=51654&pgnum=42) and
  /// [42](http://hebrewbooks.org/pdfpager.aspx?req=51654&pgnum=50) is of the opinion that elevation should be
  /// accounted for in zmanim calculations. Related to this, Rabbi Yaakov Karp in <a href= [Shimush Zekeinim](http://www.worldcat.org/oclc/919472094), Ch. 1, page 17 states that obstructing horizons should be factored into zmanim calculations.The setting defaults to false (elevation will not be used for zmanim calculations), unless the setting is changed to true in _[setUseElevation]_. This will impact sunrise and sunset based zmanim such as _[getSunrise()]_, _[getSunset]_, _[getSofZmanShmaGRA]_, alos based zmanim such as _[getSofZmanShmaMGA72Minutes] that are based on a fixed offset of sunrise or sunset and zmanim based on a percentage of the day such as _[ComprehensiveZmanimCalendar.getSofZmanShmaMGA90MinutesZmanis]_ that are based on sunrise and sunset. It will not impact zmanim that are a degree based offset of sunrise and sunset, such as _[ComprehensiveZmanimCalendar.getSofZmanShmaMGA16Point1Degrees]_ or _[ComprehensiveZmanimCalendar.getSofZmanShmaBaalHatanya]_. ///  __return if the use of elevation is active__ /// see [setUseElevation]
  bool isUseElevation() => _useElevation;

  /// Sets whether elevation above sea level is factored into _zmanim_ calculations for times besides sunrise and sunset.
  /// See [isUseElevation] for more details.
  ///
  /// [useElevation] set to true to use elevation in zmanim calculations
  void setUseElevation(bool useElevation) => _useElevation = useElevation;

  bool _useAstronomicalChatzos = true;

  bool isUseAstronomicalChatzos() => _useAstronomicalChatzos;

  void setUseAstronomicalChatzos(bool useAstronomicalChatzos) => _useAstronomicalChatzos = useAstronomicalChatzos;

  bool _useAstronomicalChatzosForOtherZmanim = false;

  bool isUseAstronomicalChatzosForOtherZmanim() => _useAstronomicalChatzosForOtherZmanim;

  void setUseAstronomicalChatzosForOtherZmanim(bool useAstronomicalChatzosForOtherZmanim) =>
      _useAstronomicalChatzosForOtherZmanim = useAstronomicalChatzosForOtherZmanim;

  /// The zenith of 16.1° below geometric zenith (90°). This calculation is used for determining _alos_
  /// (dawn) and _tzais_ (nightfall) in some opinions. It is based on the calculation that the time between dawn
  /// and sunrise (and sunset to nightfall) is 72 minutes, the time that is takes to walk 4 _mil_ at 18 minutes
  /// a mil (_[Rambam](https://en.wikipedia.org/wiki/Maimonides)_ and others). The sun's position at
  /// 72 minutes before [sunrise](getSunrise) in Jerusalem on the equinox (on March 16, about 4 days before the
  /// astronomical equinox, the day that a solar hour is 60 minutes) is 16.1° below
  /// [geometric zenith](GEOMETRIC_ZENITH).
  ///
  /// _see [getAlos16Point1Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getAlos16Point1Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getTzais16Point1Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getSofZmanShmaMGA16Point1Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getSofZmanTfilaMGA16Point1Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getMinchaGedola16Point1Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getMinchaKetana16Point1Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getPlagHamincha16Point1Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getPlagAlos16Point1DegreesToTzaisGeonim7Point083Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getSofZmanShmaAlos16Point1ToSunset]_
  @protected
  static const double ZENITH_16_POINT_1 = AstronomicalCalendar.GEOMETRIC_ZENITH + 16.1;

  /// The zenith of 8.5° below geometric zenith (90°). This calculation is used for calculating _alos_
  /// (dawn) and _tzais_ (nightfall) in some opinions. This calculation is based on the position of the sun 36
  /// minutes after [getSunset] in Jerusalem on March 16, about 4 days before the equinox, the day that a
  /// solar hour is 60 minutes, which is 8.5° below [GEOMETRIC_ZENITH].
  /// The _[Ohr Meir](http://www.worldcat.org/oclc/29283612)_ considers this the time that 3 small stars are visible,
  /// which is later than the required 3 medium stars.
  ///
  /// _see [getTzaisGeonim8Point5Degrees]_
  /// _see [ComprehensiveZmanimCalendar.getTzaisGeonim8Point5Degrees]_
  @protected
  static const double ZENITH_8_POINT_5 = AstronomicalCalendar.GEOMETRIC_ZENITH + 8.5;

  /// The zenith of 1.583° below [GEOMETRIC_ZENITH] geometric zenith (90°). This calculation is used for
  /// calculating _netz amiti_ (sunrise) and _shkiah amiti_ (sunset) based on the opinion of the
  /// _[Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)_.
  ///
  /// _see [getSunriseBaalHatanya]_
  /// _see [getSunsetBaalHatanya]_
  @protected
  static const double ZENITH_1_POINT_583 = AstronomicalCalendar.GEOMETRIC_ZENITH + 1.583;

  /// The default _Shabbos_ candle lighting offset is 18 minutes. This can be changed via the
  /// [setCandleLightingOffset] and retrieved by the [getCandleLightingOffset].
  double _candleLightingOffset = 18;

  /// This method will return [getSeaLevelSunrise] sea level sunrise if [isUseElevation] is false
  /// (the default), or elevation adjusted [AstronomicalCalendar.getSunrise] if it is true. This allows relevant zmanim
  /// in this and extending classes (such as the [ComprehensiveZmanimCalendar] to automatically adjust to the elevation setting.
  ///
  /// return [getSeaLevelSunrise] if [isUseElevation] is false (the default), or elevation adjusted
  ///          [AstronomicalCalendar.getSunrise] if it is true.
  /// _see [AstronomicalCalendar.getSunrise]_
  @protected
  DateTime? getSunriseBasedOnElevationSetting() {
    if (isUseElevation()) {
      return super.getSunrise();
    }
    return getSeaLevelSunrise();
  }

  /// This method will return [getSeaLevelSunrise] sea level sunrise} if [isUseElevation] is false
  /// (the default), or elevation adjusted [AstronomicalCalendar.getSunrise] if it is true. This allows relevant zmanim
  /// in this and extending classes (such as the [ComprehensiveZmanimCalendar] to automatically adjust to the elevation setting.
  ///
  /// return [getSeaLevelSunset] if [isUseElevation] is false (the default), or elevation adjusted
  ///          [AstronomicalCalendar.getSunset] if it is true.
  /// _see [AstronomicalCalendar.getSunset]_
  @protected
  DateTime? getSunsetBasedOnElevationSetting() {
    if (isUseElevation()) {
      return super.getSunset();
    }
    return getSeaLevelSunset();
  }

  /// A method that returns _tzais_ (nightfall) when the sun is [ZENITH_8_POINT_5] 8.5° below the
  /// [GEOMETRIC_ZENITH] geometric horizon (90°) after [getSunset sunset], a time that Rabbi Meir
  /// Posen in his the _[Ohr Meir](http://www.worldcat.org/oclc/29283612)_ calculated that 3 small
  /// stars are visible, which is later than the required 3 medium stars. See the [ZENITH_8_POINT_5] constant.
  ///
  /// see [ZENITH_8_POINT_5]
  ///
  /// return The `Date` of nightfall. If the calculation can't be computed such as northern and southern
  ///         locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach
  ///         low enough below the horizon for this calculation, a null will be returned. See detailed explanation on
  ///         top of the [AstronomicalCalendar] documentation.
  /// _see [ZENITH_8_POINT_5]_
  /// [ComprehensiveZmanimCalendar.getTzaisGeonim8Point5Degrees] that returns an identical time to this generic _tzais_
  DateTime? getTzaisGeonim8Point5Degrees() => getSunsetOffsetByDegrees(ZENITH_8_POINT_5);

  /// Returns _alos_ (dawn) based on the time when the sun is [ZENITH_16_POINT_1] 16.1° below the
  /// eastern [GEOMETRIC_ZENITH] geometric horizon before [getSunrise]. This is based on the
  /// calculation that the time between dawn and sunrise (and sunset to nightfall) is 72 minutes, the time that is
  /// takes to walk 4 _mil_ at 18 minutes a mil (_[Rambam](https://en.wikipedia.org/wiki/Maimonides)_
  /// and others). The sun's position at 72 minutes before [getSunrise sunrise] in Jerusalem
  /// on the equinox (on March 16, about 4 days before the astronomical equinox, the day that a solar hour is 60
  /// minutes) is 16.1° below. See the [GEOMETRIC_ZENITH] constant.
  ///
  /// see [ZENITH_16_POINT_1]
  /// see [ComprehensiveZmanimCalendar.getAlos16Point1Degrees]
  ///
  /// return The `Date` of dawn. If the calculation can't be computed such as northern and southern
  ///         locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach
  ///         low enough below the horizon for this calculation, a null will be returned. See detailed explanation on
  ///         top of the [AstronomicalCalendar] documentation.
  DateTime? getAlos16Point1Degrees() => getSunriseOffsetByDegrees(ZENITH_16_POINT_1);

  /// Method to return _alos_ (dawn) calculated using 72 minutes before [getSunrise] sunrise or
  /// [getSeaLevelSunrise] sea level sunrise (depending on the [isUseElevation] setting). This time
  /// is based on the time to walk the distance of 4 _Mil_ at 18 minutes a _Mil_. The 72 minute time (but
  /// not the concept of fixed minutes) is based on the opinion that the time of the _Neshef_ (twilight between
  /// dawn and sunrise) does not vary by the time of year or location but depends on the time it takes to walk the
  /// distance of 4 _Mil_.
  ///
  /// Returns the `Date` representing the time. If the calculation can't be computed such as in the Arctic
  /// Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  /// a null will be returned. See detailed explanation on top of the [AstronomicalCalendar]
  /// documentation.
  DateTime? getAlos72Minutes() =>
      AstronomicalCalendar.getTimeOffset(getSunriseBasedOnElevationSetting(), const Duration(minutes: -72));

  /// This method returns _chatzos_ (midday) following most opinions that _chatzos_ is the midpoint
  /// between [getSeaLevelSunrise] sea level sunrise and [getSeaLevelSunset] sea level sunset. A day
  /// starting at _alos_ and ending at _tzais_ using the same time or degree offset will also return
  /// the same time. The returned value is identical to [getSunTransit]. In reality due to lengthening or
  /// shortening of day, this is not necessarily the exact midpoint of the day, but it is very close.
  ///
  /// _see [AstronomicalCalendar.getSunTransit]_
  /// return the `Date` of chatzos. If the calculation can't be computed such as in the Arctic Circle
  ///         where there is at least one day where the sun does not rise, and one where it does not set, a null will
  ///         be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getChatzosHayom() {
    if (isUseAstronomicalChatzos()) {
      return getSunTransit();
    }
    return getChatzosHayomAsHalfDay() ?? getSunTransit();
  }

  DateTime? getChatzosHalayla() {
    if (isUseAstronomicalChatzos()) {
      return getSolarMidnight();
    }
    final ZmanimCalendar clonedCalendar = clone();
    final DateTime localDate = getLocalDate();
    clonedCalendar.setLocalDate(DateTime.utc(localDate.year, localDate.month, localDate.day + 1));
    return getChatzos(getSeaLevelSunset(), clonedCalendar.getSeaLevelSunrise()) ?? getSolarMidnight();
  }

  DateTime? getChatzos(DateTime? begin, DateTime? end) => getSunTransit(begin, end);

  DateTime? getChatzosHayomAsHalfDay() => getChatzos(getSeaLevelSunrise(), getSeaLevelSunset());

  DateTime? _zmanOfDay(DateTime? startOfDay, DateTime? endOfDay, double hours, bool synchronous) {
    if (isUseAstronomicalChatzosForOtherZmanim() && synchronous) {
      return hours < 6
          ? getHalfDayBasedZman(startOfDay, getChatzosHayom(), hours)
          : getHalfDayBasedZman(getChatzosHayom(), endOfDay, hours - 6);
    }
    return getShaahZmanisBasedZman(startOfDay, endOfDay, hours);
  }

  DateTime? getSofZmanShma(DateTime? startOfDay, DateTime? endOfDay, [bool synchronous = false]) =>
      _zmanOfDay(startOfDay, endOfDay, 3, synchronous);

  /// This method returns the latest _zman krias shema_ (time to recite shema in the morning) that is 3 *
  /// _[getShaahZmanisGRA] shaos zmaniyos_ (solar hours) after [getSunrise] sunrise or
  /// [getSeaLevelSunrise] sea level sunrise (depending on the [isUseElevation] setting), according
  /// to the _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_.
  ///  The day is calculated from [getSeaLevelSunrise] sea level sunrise to [getSeaLevelSunrise] sea level
  ///  sunset or [getSunrise] sunrise to [getSunset] sunset (depending on the [isUseElevation] setting).
  ///
  /// _see [getSofZmanShma]_
  /// _see #[getShaahZmanisGRA]_
  /// _see #[isUseElevation]_
  /// _see [ComprehensiveZmanimCalendar.getSofZmanShmaBaalHatanya]_
  /// return the `Date` of the latest zman shema according to the GRA. If the calculation can't be computed
  /// such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  /// does not set, a null will be returned. See the detailed explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getSofZmanShmaGRA() =>
      getSofZmanShma(getSunriseBasedOnElevationSetting(), getSunsetBasedOnElevationSetting(), true);

  /// This method returns the latest _zman krias shema_ (time to recite shema in the morning) that is 3 *
  /// _[getShaahZmanis72Minutes] shaos zmaniyos_ (solar hours) after [getAlos72Minutes], according to the
  /// _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_. The day is calculated
  /// from 72 minutes before [getSeaLevelSunrise] sea level sunrise} to 72 minutes after [getSeaLevelSunrise]
  /// sea level sunset or from 72 minutes before [getSunrise] sunrise to [getSunset] sunset
  /// (depending on the [isUseElevation] setting).
  ///
  /// return the `Date` of the latest _zman shema_. If the calculation can't be computed such as in
  ///         the Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
  ///         does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  /// _see [getSofZmanShma]_
  /// _see [ComprehensiveZmanimCalendar.getShaahZmanis72Minutes]_
  /// _see [getAlos72Minutes]_
  /// _see [ComprehensiveZmanimCalendar.getSofZmanShmaMGA72Minutes]_
  DateTime? getSofZmanShmaMGA72Minutes() => getSofZmanShma(getAlos72Minutes(), getTzais72Minutes(), true);

  /// This method returns the _tzais_ (nightfall) based on the opinion of _Rabbeinu Tam_ that
  /// _tzais hakochavim_ is calculated as 72 minutes, the time it takes to walk 4 _Mil_ at 18 minutes
  /// a _Mil_. According to the [Machtzis Hashekel](https://en.wikipedia.org/wiki/Samuel_Loew) in
  /// Orach Chaim 235:3, the [Pri Megadim](https://en.wikipedia.org/wiki/Joseph_ben_Meir_Teomim) in Orach
  /// Chaim 261:2 (see the Biur Halacha) and others (see Hazmanim Bahalacha 17:3 and 17:5) the 72 minutes are standard
  /// clock minutes any time of the year in any location. Depending on the [isUseElevation] setting) a 72
  /// minute offset from  either [getSunset] or [getSeaLevelSunset] is used.
  ///
  /// see [ComprehensiveZmanimCalendar.getTzais16Point1Degrees]
  /// return the `Date` representing 72 minutes after sunset. If the calculation can't be
  ///         computed such as in the Arctic Circle where there is at least one day a year where the sun does not rise,
  ///         and one where it does not set, a null will be returned See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  DateTime? getTzais72Minutes() =>
      AstronomicalCalendar.getTimeOffset(getSunsetBasedOnElevationSetting(), const Duration(minutes: 72));

  /// [getCandleLightingOffset] minutes before sea level sunset, for any day. Whether candles are lit that day is
  /// the caller's to check, with [JewishCalendar.hasCandleLighting].
  DateTime? getCandleLighting() => AstronomicalCalendar.getTimeOffset(
      getSeaLevelSunset(), durationOfNanos((-getCandleLightingOffset() * AstronomicalCalendar.MINUTE_NANOS).truncate()));

  /// A generic method for calculating the latest _zman tfilah_ (time to recite the morning prayers)
  /// that is 4 * _shaos zmaniyos_ (temporal hours) after the start of the day, calculated using the start and
  /// end of the day passed to this method.
  /// The time from the start of day to the end of day are divided into 12 _shaos zmaniyos_ (temporal hours),
  /// and _sof zman tfila_ is calculated as 4 of those _shaos zmaniyos_ after the beginning of the day.
  /// As an example, passing [getSunrise] sunrise and [getSunset sunset] or [getSeaLevelSunrise]
  /// sea level sunrise and [getSeaLevelSunset] sea level sunset (depending on the [isUseElevation]
  /// elevation setting) to this method will return _zman tfilah_ according to the opinion of the
  /// _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_.
  ///
  /// [startOfDay]
  ///            the start of day for calculating _zman tfilah_. This can be sunrise or any alos passed to
  ///            this method.
  /// [endOfDay]
  ///            the start of day for calculating _zman tfilah_. This can be sunset or any tzais passed to this
  ///            method.
  /// return the `Date` of the latest _zman tfilah_ based on the start and end of day times passed
  ///         to this method. If the calculation can't be computed such as in the Arctic Circle where there is at least
  ///         one day a year where the sun does not rise, and one where it does not set, a null will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getSofZmanTfila(DateTime? startOfDay, DateTime? endOfDay, [bool synchronous = false]) =>
      _zmanOfDay(startOfDay, endOfDay, 4, synchronous);

  /// Five _shaos zmaniyos_ into the day, on _Erev Pesach_ only. Null on any other day.
  DateTime? getSofZmanBiurChametz(DateTime? startOfDay, DateTime? endOfDay, bool synchronous) =>
      _isErevPesach() ? _zmanOfDay(startOfDay, endOfDay, 5, synchronous) : null;

  /// Four _shaos zmaniyos_ into the day, on _Erev Pesach_ only. Null on any other day.
  DateTime? getSofZmanAchilasChametz(DateTime? startOfDay, DateTime? endOfDay, bool synchronous) =>
      _isErevPesach() ? getSofZmanTfila(startOfDay, endOfDay, synchronous) : null;

  bool _isErevPesach() {
    final DateTime day = getLocalDate();
    final JewishCalendar jewishCalendar = JewishCalendar()..setGregorianDate(day.year, day.month, day.day);
    return jewishCalendar.getJewishMonth() == JewishDate.NISSAN && jewishCalendar.getJewishDayOfMonth() == 14;
  }

  /// This method returns the latest _zman tfila_ (time to recite shema in the morning) that is 4 *
  /// _[getShaahZmanisGRA] shaos zmaniyos_ (solar hours) after [getSunrise] sunrise or
  /// [getSeaLevelSunrise] sea level sunrise (depending on the [isUseElevation] setting), according
  /// to the _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_.
  /// The day is calculated from [getSeaLevelSunrise] sea level sunrise to [getSeaLevelSunrise] sea level
  /// sunset or [getSunrise] sunrise to [getSunset] sunset (depending on the [isUseElevation] setting).
  ///
  /// _see [getSofZmanTfila]_
  /// _see [getShaahZmanisGRA]_
  /// _see [ComprehensiveZmanimCalendar.getSofZmanTfilaBaalHatanya]_
  /// return the `Date` of the latest zman tfilah. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set, a null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getSofZmanTfilaGRA() =>
      getSofZmanTfila(getSunriseBasedOnElevationSetting(), getSunsetBasedOnElevationSetting(), true);

  /// This method returns the latest _zman tfila_ (time to recite shema in the morning) that is 4 *
  /// [getShaahZmanis72Minutes] shaos zmaniyos_ (solar hours) after [getAlos72Minutes] according to the
  /// _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_. The day is calculated
  /// from 72 minutes before [getSeaLevelSunrise] sea level sunrise to 72 minutes after
  /// [getSeaLevelSunrise] sea level sunset or from 72 minutes before [getSunrise] sunrise to [getSunset]
  /// sunset (depending on the [isUseElevation] setting).
  ///
  /// return the `Date` of the latest zman tfila. If the calculation can't be computed such as in the
  ///         Arctic Circle where there is at least one day a year where the sun does not rise, and one where it does
  ///         not set), a null will be returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getSofZmanTfila]_
  /// _see [getShaahZmanis72Minutes]_
  /// _see [getAlos72Minutes]_
  DateTime? getSofZmanTfilaMGA72Minutes() => getSofZmanTfila(getAlos72Minutes(), getTzais72Minutes(), true);

  DateTime? getMinchaGedola(DateTime? startOfDay, DateTime? endOfDay, [bool synchronous = false]) =>
      _zmanOfDay(startOfDay, endOfDay, 6.5, synchronous);

  /// A generic method for calculating the latest _mincha gedola_ (the earliest time to recite the mincha  prayers)
  /// that is 6.5 * _shaos zmaniyos_ (temporal hours) after the start of the day, calculated using the start and end
  /// of the day passed to this method.
  /// The time from the start of day to the end of day are divided into 12 _shaos zmaniyos_ (temporal hours), and
  /// _mincha gedola_ is calculated as 6.5 of those _shaos zmaniyos_ after the beginning of the day. As an
  /// example, passing [getSunrise] sunrise and [getSunset] sunset or [getSeaLevelSunrise] sea level
  /// sunrise and [getSeaLevelSunset] sea level sunset (depending on the [isUseElevation] elevation
  /// setting) to this method will return _mincha gedola_ according to the opinion of the
  /// _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_.
  ///
  /// [startOfDay]
  ///            the start of day for calculating _Mincha gedola_. This can be sunrise or any alos passed to
  ///            this method.
  /// [endOfDay]
  ///            the end of day for calculating _Mincha gedola_. This can be sunrise or any alos passed to
  ///            this method.
  /// return the `Date` of the time of _Mincha gedola_ based on the start and end of day times
  ///         passed to this method. If the calculation can't be computed such as in the Arctic Circle where there is
  ///         at least one day a year where the sun does not rise, and one where it does not set, a null will be
  ///         returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getMinchaGedolaGRA() =>
      getMinchaGedola(getSunriseBasedOnElevationSetting(), getSunsetBasedOnElevationSetting(), true);

  DateTime? getSamuchLeMinchaKetana(DateTime? startOfDay, DateTime? endOfDay, [bool synchronous = false]) =>
      _zmanOfDay(startOfDay, endOfDay, 9, synchronous);

  DateTime? getMinchaKetana(DateTime? startOfDay, DateTime? endOfDay, [bool synchronous = false]) =>
      _zmanOfDay(startOfDay, endOfDay, 9.5, synchronous);

  /// A generic method for calculating _mincha ketana_, (the preferred time to recite the mincha prayers in
  /// the opinion of the _[Rambam](https://en.wikipedia.org/wiki/Maimonides)_ and others) that is
  /// 9.5 * _shaos zmaniyos_ (temporal hours) after the start of the day, calculated using the start and end
  /// of the day passed to this method.
  /// The time from the start of day to the end of day are divided into 12 _shaos zmaniyos_ (temporal hours), and
  /// _mincha ketana_ is calculated as 9.5 of those _shaos zmaniyos_ after the beginning of the day. As an
  /// example, passing [getSunrise] sunrise and [getSunset] sunset or [getSeaLevelSunrise] sea level
  /// sunrise and [getSeaLevelSunset] sea level sunset (depending on the [isUseElevation] elevation
  /// setting) to this method will return _mincha ketana_ according to the opinion of the
  /// _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_.
  ///
  /// [startOfDay] the start of day for calculating _Mincha ketana_. This can be sunrise or any alos passed to this method.
  /// [endOfDay] the end of day for calculating _Mincha ketana_. This can be sunrise or any alos passed to this method.
  /// return the `Date` of the time of _Mincha ketana_ based on the start and end of day times
  ///         passed to this method. If the calculation can't be computed such as in the Arctic Circle where there is
  ///         at least one day a year where the sun does not rise, and one where it does not set, a null will be
  ///         returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  ///
  DateTime? getMinchaKetanaGRA() =>
      getMinchaKetana(getSunriseBasedOnElevationSetting(), getSunsetBasedOnElevationSetting(), true);

  DateTime? getPlagHamincha(DateTime? startOfDay, DateTime? endOfDay, [bool synchronous = false]) =>
      _zmanOfDay(startOfDay, endOfDay, 10.75, synchronous);

  /// A generic method for calculating _plag hamincha_ (the earliest time that Shabbos can be started) that is
  /// 10.75 hours after the start of the day, (or 1.25 hours before the end of the day) based on the start and end of
  /// the day passed to the method.
  /// The time from the start of day to the end of day are divided into 12 _shaos zmaniyos_ (temporal hours), and
  /// _plag hamincha_ is calculated as 10.75 of those _shaos zmaniyos_ after the beginning of the day. As an
  /// example, passing [getSunrise] sunrise and [getSunset] sunset or [getSeaLevelSunrise] sea level
  /// sunrise and [getSeaLevelSunset] sea level sunset (depending on the [isUseElevation] elevation
  /// setting) to this method will return _plag mincha_ according to the opinion of the
  /// _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_.
  ///
  /// [startOfDay] the start of day for calculating plag. This can be sunrise or any alos passed to this method.
  /// [endOfDay] the end of day for calculating plag. This can be sunrise or any alos passed to this method.
  /// return the `Date` of the time of _plag hamincha_ based on the start and end of day times
  ///         passed to this method. If the calculation can't be computed such as in the Arctic Circle where there is
  ///         at least one day a year where the sun does not rise, and one where it does not set, a null will be
  ///         returned. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getPlagHaminchaGRA() =>
      getPlagHamincha(getSunriseBasedOnElevationSetting(), getSunsetBasedOnElevationSetting(), true);

  /// A method that returns a _shaah zmanis_ ([getTemporalHour] temporal hour) according to
  /// the opinion of the _[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)_. This calculation divides
  /// the day based on the opinion of the _GRA_ that the day runs from from [getSeaLevelSunrise] sea
  /// level sunrise to [getSeaLevelSunrise] sea level sunset or [getSunrise] sunrise to
  /// [getSunset] sunset (depending on the [isUseElevation] setting). The day is split into 12 equal
  /// parts with each one being a _shaah zmanis_. This method is similar to [getTemporalHour], but can
  /// account for elevation.
  ///
  /// return the `long` millisecond length of a _shaah zmanis_ calculated from sunrise to sunset.
  ///         If the calculation can't be computed such as in the Arctic Circle where there is at least one day a year
  ///         where the sun does not rise, and one where it does not set, double.minPositive will be returned. See
  ///         detailed explanation on top of the [AstronomicalCalendar] documentation.
  /// _see [getTemporalHour]_
  /// _see [getSeaLevelSunrise]_
  /// _see [getSeaLevelSunset]_
  /// _see [ComprehensiveZmanimCalendar.getShaahZmanisBaalHatanya]_
  Duration? getShaahZmanisGRA() =>
      getTemporalHour(getSunriseBasedOnElevationSetting(), getSunsetBasedOnElevationSetting());

  /// Utility method to return _alos_ (dawn) or _tzais_ (dusk) based on a fractional day offset.
  /// - [hours]: the number of _shaaos zmaniyos_ (temporal hours) before sunrise or after sunset that defines dawn
  ///   or dusk. If a negative number is passed in, it will return the time of _alos_ (dawn) (subrtacting the
  ///   time from sunrise) and if a positive number is passed in, it will return the time of _tzais_ (dusk)
  ///   (adding the time to sunset). If 0 is passed in, a null will be returned (since we can't tell if it is sunrise
  ///   or sunset based).
  /// Returns the `Date` representing the time. If the calculation can't be computed such as in the Arctic
  /// Circle where there is at least one day a year where the sun does not rise, and one where it does not set,
  /// a null will be returned. A null will also be returned if 0 is passed in, since we can't tell if it is sunrise
  /// or sunset based. See detailed explanation on top of the [AstronomicalCalendar] documentation.
  DateTime? getZmanisBasedOffset(double hours) {
    final DateTime? sunrise = getSunriseBasedOnElevationSetting();
    final DateTime? sunset = getSunsetBasedOnElevationSetting();
    if (sunrise == null || sunset == null || hours == 0) {
      return null;
    }
    return offsetByParts(hours > 0 ? sunset : sunrise, sunrise, sunset, 12, hours);
  }

  /// A method that returns a _shaah zmanis_ (temporal hour) according to the opinion of the
  /// _[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)_ based on a 72 minutes _alos_
  /// and _tzais_. This calculation divides the day that runs from dawn to dusk (for sof zman krias shema and tfila).
  /// Dawn for this calculation is 72 minutes before [getSunrise] sunrise or [getSeaLevelSunrise] sea level
  /// sunrise (depending on the [isUseElevation] elevation setting) and dusk is 72 minutes after [getSunset]
  /// sunset or [getSeaLevelSunset] sea level sunset (depending on the [isUseElevation] elevation setting).
  /// This day is split into 12 equal parts with each part being a _shaah zmanis_. Alternate methods of calculating a
  /// _shaah zmanis_ according to the Magen Avraham (MGA) are available in the subclass [ComprehensiveZmanimCalendar].
  ///
  /// return the `long` millisecond length of a _shaah zmanis_. If the calculation can't be computed
  ///         such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, double.nan will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  Duration? getShaahZmanis72Minutes() => getTemporalHour(getAlos72Minutes(), getTzais72Minutes());

  /// Default constructor will set a default [GeoLocation.GeoLocation], a default
  /// [AstronomicalCalculator.getDefault] AstronomicalCalculator and default the calendar to the current date.
  ///
  /// _see [AstronomicalCalendar.AstronomicalCalendar]_
  ZmanimCalendar() : this.withGeoLocation(GeoLocation());

  ZmanimCalendar.withGeoLocation(super.location) : super.withGeoLocation();

  /// A method to get the offset in minutes before [AstronomicalCalendar.getSeaLevelSunset] sea level sunset which
  /// is used in calculating candle lighting time. The default time used is 18 minutes before sea level sunset. Some
  /// calendars use 15 minutes, while the custom in Jerusalem is to use a 40 minute offset. Please check the local custom
  /// for candle lighting time.
  ///
  /// return Returns the currently set candle lighting offset in minutes.
  /// _see [getCandleLighting]_
  /// _see [setCandleLightingOffset]_
  double getCandleLightingOffset() => _candleLightingOffset;

  /// A method to set the offset in minutes before [AstronomicalCalendar.getSeaLevelSunset] sea level sunset that is
  /// used in calculating candle lighting time. The default time used is 18 minutes before sunset. Some calendars use 15
  /// minutes, while the custom in Jerusalem is to use a 40 minute offset.
  ///
  /// [candleLightingOffset] The candle lighting offset to set in minutes.
  /// _see [getCandleLighting]_
  /// _see [getCandleLightingOffset]_
  void setCandleLightingOffset(double candleLightingOffset) => _candleLightingOffset = candleLightingOffset;

  /// This is a utility method to determine if the current Date (date-time) passed in has a _melacha_ (work) prohibition.
  /// Since there are many opinions on the time of _tzais_, the _tzais_ for the current day has to be passed to this
  /// class. Sunset is the classes current day's [getSunsetBasedOnElevationSetting] elevation adjusted sunset that observes the
  /// [isUseElevation] settings. The [JewishCalendar#getInIsrael] will be set by the inIsrael parameter.
  ///
  /// [currentTime] the current time
  /// [tzais] the time of tzais
  /// [inIsrael] whether to use Israel holiday scheme or not
  ///
  /// return true if _melacha_ is prohibited or false if it is not.
  ///
  /// _see [JewishCalendar.isAssurBemelacha]_
  /// _see [JewishCalendar.hasCandleLighting]_
  /// _see [JewishCalendar.setInIsrael]_
  bool isAssurBemelacha(DateTime currentTime, DateTime tzais, bool inIsrael) {
    final DateTime day = getLocalDate();
    final JewishCalendar jewishCalendar = JewishCalendar()..setGregorianDate(day.year, day.month, day.day);
    jewishCalendar.inIsrael = inIsrael;
    if (jewishCalendar.hasCandleLighting() && currentTime.compareTo(getSunsetBasedOnElevationSetting()!) >= 0) {
      return true;
    }
    return jewishCalendar.isAssurBemelacha() && currentTime.compareTo(tzais) <= 0;
  }

  /// A method that returns the _[Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)_'s
  /// _netz amiti_ (sunrise) without [AstronomicalCalculator.getElevationAdjustment]
  /// elevation adjustment. This forms the base for the _Baal Hatanya_'s dawn based calculations that are
  /// calculated as a dip below the horizon before sunrise.
  ///
  /// According to the _Baal Hatanya_, _netz amiti_, or true (halachic) sunrise, is when the top of the sun's
  /// disk is visible at an elevation similar to the mountains of Eretz Yisrael. The time is calculated as the point at which
  /// the center of the sun's disk is 1.583° below the horizon. This degree based calculation can be found in Rabbi Shalom
  /// DovBer Levine's commentary on The [Baal Hatanya's Seder Hachnasas Shabbos](http://www.chabadlibrary.org/books/pdf/Seder-Hachnosas-Shabbos.pdf).
  /// From an elevation of 546 meters, the top of [Har Hacarmel](https://en.wikipedia.org/wiki/Mount_Carmel),
  /// the sun disappears when it is 1° 35' or 1.583° below the sea level horizon. This in turn is based on the Gemara
  /// [Shabbos 35a](http://www.hebrewbooks.org/shas.aspx?mesechta=2&daf=35). There are other opinions brought down by
  /// Rabbi Levine, including Rabbi Yosef Yitzchok
  /// Feigelstock who calculates it as the degrees below the horizon 4 minutes after sunset in Yerushalaym (on the equinox). That
  /// is brought down as 1.583°. This is identical to the 1° 35' zman and is probably a typo and should be 1.683°.
  /// These calculations are used by most [Chabad](https://en.wikipedia.org/wiki/Chabad) calendars that use the
  /// _Baal Hatanya_'s Zmanim.
  /// See [About Our Zmanim Calculations  Chabad.org](https://www.chabad.org/library/article_cdo/aid/3209349/jewish/About-Our-Zmanim-Calculations.htm).
  ///
  /// Note: _netz amiti_ is used only for calculating certain zmanim, and is intentionally unpublished. For practical purposes,
  /// daytime mitzvos like shofar and lulav should not be done until after the published time for netz-sunrise.
  ///
  /// return the `DateTime` representing the exact sea-level _netz amiti_ (sunrise) time. If the calculation can't be
  ///         computed such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  ///         where it does not set, a null will be returned. See detailed explanation on top of the page.
  ///
  /// _see [getSunrise]_
  /// _see [getSeaLevelSunrise]_
  /// _see [getSunsetBaalHatanya]_
  /// _see [ZENITH_1_POINT_583]_
  @protected
  DateTime? getSunriseBaalHatanya() => getSunriseOffsetByDegrees(ZENITH_1_POINT_583);

  /// A method that returns the _[Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)_'s
  /// _shkiah amiti_ (sunset) without {link AstronomicalCalculator#getElevationAdjustment(double)
  /// elevation adjustment. This forms the base for the _Baal Hatanya_'s  dusk based calculations that are calculated
  /// as a dip below the horizon after sunset.
  ///
  /// According to the _Baal Hatanya_, _shkiah amiti_, true (halachic) sunset, is when the top of the
  /// sun's disk disappears from view at an elevation similar to the mountains of Eretz Yisrael.
  /// This time is calculated as the point at which the center of the sun's disk is 1.583 degrees below the horizon.
  ///
  /// Note: _shkiah amiti_ is used only for calculating certain zmanim, and is intentionally unpublished. For practical
  /// purposes, all daytime mitzvos should be completed before the published time for shkiah-sunset.
  ///
  /// For further explanation of the calculations used for the _Baal Hatanya_'s Zmanim in this library, see
  /// [About Our Zmanim Calculations  Chabad.org](https://www.chabad.org/library/article_cdo/aid/3209349/jewish/About-Our-Zmanim-Calculations.htm).
  ///
  /// return the `DateTime` representing the exact sea-level _shkiah amiti_ (sunset) time. If the calculation
  ///         can't be computed such as in the Arctic Circle where there is at least one day a year where the sun does not
  ///         rise, and one where it does not set, a null will be returned. See detailed explanation on top of the
  ///         [AstronomicalCalendar] documentation.
  ///
  /// _see [getSunset]_
  /// _see [getSeaLevelSunset]_
  /// _see [getSunriseBaalHatanya]_
  /// _see [#ZENITH_1_POINT_583]_
  @protected
  DateTime? getSunsetBaalHatanya() => getSunsetOffsetByDegrees(ZENITH_1_POINT_583);

  /// A generic utility method for calculating any _shaah zmanis_ (temporal hour) based _zman_ with the
  /// day defined as the start and end of day (or night) and the number of _shaahos zmaniyos_ passed to the
  /// method. This simplifies the code in other methods such as [getPlagHamincha] and cuts down on
  /// code replication. As an example, passing [getSunrise] and [getSunset] or {@link
  /// #getSeaLevelSunrise() sea level sunrise} and [getSeaLevelSunset] (depending on the
  /// [isUseElevation] elevation setting) and 10.75 hours to this method will return _plag mincha_
  /// according to the opinion of the [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon).
  ///
  /// - [startOfDay]: 
  ///   the start of day for calculating the _zman_. This can be sunrise or any _alos_ passed
  ///   to this method.
  /// - [endOfDay]: 
  ///   the end of day for calculating the _zman_. This can be sunrise or any _alos_ passed to
  ///   this method.
  /// - [hours]: 
  ///   the number of _shaahos zmaniyos_ (temporal hours) to offset from the start of day
  /// Returns the `Date` of the time of _zman_ with the _shaahos zmaniyos_ (temporal hours)
  /// in the day offset from the start of day passed to this method. If the calculation can't be computed such
  /// as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
  /// where it does not set, a null will be  returned. See detailed explanation on top of the {@link
  /// AstronomicalCalendar} documentation.
  DateTime? getShaahZmanisBasedZman(DateTime? startOfDay, DateTime? endOfDay, double hours) {
    if (startOfDay == null || endOfDay == null) {
      return null;
    }
    return offsetByParts(startOfDay, startOfDay, endOfDay, 12, hours);
  }

  double getPercentOfShaahZmanisFromDegrees(double degrees, bool sunset) {
    final DateTime? seaLevelSunrise = getSeaLevelSunrise();
    final DateTime? seaLevelSunset = getSeaLevelSunset();
    final DateTime? twilight = sunset
        ? getSunsetOffsetByDegrees(AstronomicalCalendar.GEOMETRIC_ZENITH + degrees)
        : getSunriseOffsetByDegrees(AstronomicalCalendar.GEOMETRIC_ZENITH + degrees);
    if (seaLevelSunrise == null || seaLevelSunset == null || twilight == null) {
      return double.minPositive;
    }
    int millis(DateTime time) {
      final int micros = time.microsecondsSinceEpoch;
      return (micros - micros % 1000) ~/ 1000;
    }

    final double shaahZmanis = (millis(seaLevelSunset) - millis(seaLevelSunrise)) / 12.0;
    final int riseSetToTwilight =
        sunset ? millis(twilight) - millis(seaLevelSunset) : millis(seaLevelSunrise) - millis(twilight);
    return riseSetToTwilight / shaahZmanis;
  }

  /// Negative [hours] count back from [endOfHalfDay].
  DateTime? getHalfDayBasedZman(DateTime? startOfHalfDay, DateTime? endOfHalfDay, double hours) {
    if (startOfHalfDay == null || endOfHalfDay == null) {
      return null;
    }
    return offsetByParts(hours >= 0 ? startOfHalfDay : endOfHalfDay, startOfHalfDay, endOfHalfDay, 6, hours);
  }

  Duration? getHalfDayBasedShaahZmanis(DateTime? startOfHalfDay, DateTime? endOfHalfDay) {
    if (startOfHalfDay == null || endOfHalfDay == null) {
      return null;
    }
    return Duration(
        microseconds: ((endOfHalfDay.microsecondsSinceEpoch - startOfHalfDay.microsecondsSinceEpoch) / 6).round());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ZmanimCalendar || !(super == other)) {
      return false;
    }
    return _useElevation == other._useElevation &&
        _useAstronomicalChatzos == other._useAstronomicalChatzos &&
        _useAstronomicalChatzosForOtherZmanim == other._useAstronomicalChatzosForOtherZmanim &&
        _candleLightingOffset == other._candleLightingOffset;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, _useElevation, _useAstronomicalChatzos,
      _useAstronomicalChatzosForOtherZmanim, _candleLightingOffset);

  @override
  ZmanimCalendar clone() => copyZmanimSettings(this, ZmanimCalendar.withGeoLocation(getGeoLocation()));
}

T copyZmanimSettings<T extends ZmanimCalendar>(ZmanimCalendar from, T to) => copyCalendarSettings(from, to)
  .._useElevation = from._useElevation
  .._useAstronomicalChatzos = from._useAstronomicalChatzos
  .._useAstronomicalChatzosForOtherZmanim = from._useAstronomicalChatzosForOtherZmanim
  .._candleLightingOffset = from._candleLightingOffset;
