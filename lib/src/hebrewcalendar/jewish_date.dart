/*
 * Zmanim Java API
 * Copyright (C) 2011 - 2019 Eliyahu Hershfeld
 * Copyright (C) September 2002 Avrom Finkelstien
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
import 'dart:math';
import 'package:kosher_dart/src/hebrewcalendar/hebrew_date_formatter.dart';

/// The JewishDate is the base calendar class, that supports a Gregorian date along with the corresponding
/// Jewish date. This class does not have a concept of a time. Please note that the calendar does not currently support dates
/// prior to 1/1/1 Gregorian. Also keep in mind that the Gregorian calendar started on October 15, 1582,
/// so any calculations prior to that are suspect (at least from a Gregorian perspective). While 1/1/1
/// Gregorian and forward are technically supported, any calculations prior to
/// [Hillel II (Hakatan)](http://en.wikipedia.org/wiki/Hillel_II)'s calendar (4119 in the Jewish
/// Calendar / 359 CE Julian as recorded by [Rav Hai Gaon](http://en.wikipedia.org/wiki/Hai_Gaon))
/// would be just an approximation.
///
/// This open source Dart code was ported from the KosherJava Zmanim library originally written by
/// [Avrom Finkelstien](http://www.facebook.com/avromf) in C++ and refactored to Java by Eliyahu
/// Hershfeld, with simplification of the code, enhancements and some bug fixing.
///
/// Some of Avrom's original C++ code was translated from
/// [C/C++ code](https://web.archive.org/web/20120124134148/http://emr.cs.uiuc.edu/~reingold/calendar.C) in
/// [Calendrical Calculations](http://www.calendarists.com) by Nachum Dershowitz and Edward M.
/// Reingold, Software-- Practice & Experience, vol. 20, no. 9 (September, 1990), pp. 899-928. Any
/// method marked "ND+ER" indicates that the method was taken from this source with minor modifications.
///
/// If you are looking for a class that implements a Jewish calendar version of the calendar, one is
/// available from the ICU (International Components for Unicode) project, formerly part of
/// IBM's DeveloperWorks.
///
/// See also [JewishCalendar].
/// See also [HebrewDateFormatter].
/// See also [DateTime].
/// © Avrom Finkelstien 2002
/// © Eliyahu Hershfeld 2011 - 2019
class JewishDate implements Comparable<JewishDate> {
  /// Value of the month field indicating Nissan, the first numeric month of the year in the Jewish calendar. With the
  /// year starting at [TISHREI], it would actually be the 7th (or 8th in a [isJewishLeapYear]) month of the year.
  static const int NISSAN = 1;

  /// Value of the month field indicating Iyar, the second numeric month of the year in the Jewish calendar. With the
  /// year starting at [TISHREI], it would actually be the 8th (or 9th in a [isJewishLeapYear]) month of the year.
  static const int IYAR = 2;

  /// Value of the month field indicating Sivan, the third numeric month of the year in the Jewish calendar. With the
  /// year starting at [TISHREI], it would actually be the 9th (or 10th in a [isJewishLeapYear]) month of the year.
  static const int SIVAN = 3;

  /// Value of the month field indicating Tammuz, the fourth numeric month of the year in the Jewish calendar. With the
  /// year starting at [TISHREI], it would actually be the 10th (or 11th in a [isJewishLeapYear]) month of the year.
  static const int TAMMUZ = 4;

  /// Value of the month field indicating Av, the fifth numeric month of the year in the Jewish calendar. With the year
  /// starting at [TISHREI], it would actually be the 11th (or 12th in a [isJewishLeapYear])
  /// month of the year.
  static const int AV = 5;

  /// Value of the month field indicating Elul, the sixth numeric month of the year in the Jewish calendar. With the
  /// year starting at [TISHREI], it would actually be the 12th (or 13th in a [isJewishLeapYear]) month of the year.
  static const int ELUL = 6;

  /// Value of the month field indicating Tishrei, the seventh numeric month of the year in the Jewish calendar. With
  /// the year starting at this month, it would actually be the 1st month of the year.
  static const int TISHREI = 7;

  /// Value of the month field indicating Cheshvan/marcheshvan, the eighth numeric month of the year in the Jewish
  /// calendar. With the year starting at [TISHREI], it would actually be the 2nd month of the year.
  static const int CHESHVAN = 8;

  /// Value of the month field indicating Kislev, the ninth numeric month of the year in the Jewish calendar. With the
  /// year starting at [TISHREI], it would actually be the 3rd month of the year.
  static const int KISLEV = 9;

  /// Value of the month field indicating Teves, the tenth numeric month of the year in the Jewish calendar. With the
  /// year starting at [TISHREI], it would actually be the 4th month of the year.
  static const int TEVES = 10;

  /// Value of the month field indicating Shevat, the eleventh numeric month of the year in the Jewish calendar. With
  /// the year starting at [TISHREI], it would actually be the 5th month of the year.
  static const int SHEVAT = 11;

  /// Value of the month field indicating Adar (or Adar I in a [isJewishLeapYear]), the twelfth
  /// numeric month of the year in the Jewish calendar. With the year starting at [TISHREI], it would actually
  /// be the 6th month of the year.
  static const int ADAR = 12;

  /// Value of the month field indicating Adar II, the leap (intercalary or embolismic) thirteenth (Undecimber) numeric
  /// month of the year added in Jewish [isJewishLeapYear]). The leap years are years 3, 6, 8, 11,
  /// 14, 17 and 19 of a 19 year cycle. With the year starting at [TISHREI], it would actually be the 7th month
  /// of the year.
  static const int ADAR_II = 13;

  /// the Jewish epoch using the RD (Rata Die/Fixed Date or Reingold Dershowitz) day used in Calendrical Calculations.
  /// Day 1 is January 1, 0001 Gregorian
  static const int _JEWISH_EPOCH = -1373429;

  /// The number  of _chalakim_ (18) in a minute.
  static const int _CHALAKIM_PER_MINUTE = 18;

  /// The number  of _chalakim_ (1080) in an hour.
  static const int _CHALAKIM_PER_HOUR = 1080;

  /// The number of _chalakim_ (25,920) in a 24 hour day.
  static const int _CHALAKIM_PER_DAY = 25920; // 24 * 1080
  /// The number  of _chalakim_ in an average Jewish month. A month has 29 days, 12 hours and 793
  /// _chalakim_ (44 minutes and 3.3 seconds) for a total of 765,433 _chalakim_
  static const int _CHALAKIM_PER_MONTH = 765433; // (29 * 24 + 12) * 1080 + 793
  /// Days from the beginning of Sunday till molad BaHaRaD. Calculated as 1 day, 5 hours and 204 chalakim = (24 + 5) *
  /// 1080 + 204 = 31524
  static const int _CHALAKIM_MOLAD_TOHU = 31524;

  /// A short year where both [CHESHVAN] and [KISLEV] are 29 days.
  ///
  /// See also [getCheshvanKislevKviah].
  /// See also [HebrewDateFormatter.getFormattedKviah].
  static const int CHASERIM = 0;

  /// An ordered year where [CHESHVAN] is 29 days and [KISLEV] is 30 days.
  ///
  /// See also [getCheshvanKislevKviah].
  /// See also [HebrewDateFormatter.getFormattedKviah].
  static const int KESIDRAN = 1;

  /// A long year where both [CHESHVAN] and [KISLEV] are 30 days.
  ///
  /// See also [getCheshvanKislevKviah].
  /// See also [HebrewDateFormatter.getFormattedKviah].
  static const int SHELAIMIM = 2;

  /// the internal Jewish month.
  late int _jewishMonth;

  /// the internal Jewish day.
  late int _jewishDay;

  /// the internal Jewish year.
  late int _jewishYear;

  /// the internal count of _molad_ hours.
  int _moladHours = 0;

  /// the internal count of _molad_ minutes.
  int _moladMinutes = 0;

  /// the internal count of _molad_ _chalakim_.
  int _moladChalakim = 0;

  /// 1 == Sunday, 2 == Monday, etc...
  late int _dayOfWeek;

  /// Returns the absolute date (days since January 1, 0001 on the Gregorian calendar).
  /// See also [getAbsDate].
  late int _gregorianAbsDate;

  /// Default constructor will set a default date to the current system date.
  JewishDate() {
    resetDate();
  }

  /// Creates a Jewish date based on a Jewish year, month and day of month.
  ///
  /// - [jewishYear]:
  ///   the Jewish year
  /// - [jewishMonth]:
  ///   the Jewish month. The method expects a 1 for Nissan ... 12 for Adar and 13 for Adar II. Use the
  ///   constants [NISSAN] ... [ADAR] (or [ADAR_II] for a leap year Adar II) to avoid any
  ///   confusion.
  /// - [jewishDayOfMonth]:
  ///   the Jewish day of month. If 30 is passed in for a month with only 29 days (for example [IYAR],
  ///   or [KISLEV] in a year that [isKislevShort]), the 29th (last valid date of the month)
  ///   will be set
  /// Throws [ArgumentError]
  ///             if the day of month is < 1 or > 30, or a year of < 0 is passed in.
  JewishDate.fromJewishDate(
      int jewishYear, int jewishMonth, int jewishDayOfMonth) {
    setJewishDate(jewishYear, jewishMonth, jewishDayOfMonth);
  }

  /// A constructor that initializes the date to the date of the zoned [DateTime] parameter, read in its own zone.
  ///
  /// - [zonedDateTime]:
  ///   the [DateTime] to set the calendar to
  JewishDate.fromZonedDateTime(DateTime zonedDateTime) {
    setGregorianDate(zonedDateTime);
  }

  /// A constructor that initializes the date to the [DateTime] parameter's date.
  ///
  /// - [localDate]:
  ///   the date to set the calendar to
  JewishDate.fromLocalDate(DateTime localDate) {
    setGregorianDate(localDate);
  }

  /// Constructor that creates a JewishDate based on a molad passed in. The molad would be the number of chalakim/parts
  /// starting at the beginning of Sunday prior to the molad Tohu BeHaRaD (Be = Monday, Ha= 5 hours and Rad =204
  /// chalakim/parts) - prior to the start of the Jewish calendar. BeHaRaD is 23:11:20 on Sunday night(5 hours 204/1080
  /// chalakim after sunset on Sunday evening).
  ///
  /// - [molad]: the number of chalakim since the beginning of Sunday prior to BaHaRaD
  JewishDate.fromMolad(int molad) {
    _setAbsDate(_moladToAbsDate(molad));
    int conjunctionDay = molad ~/ _CHALAKIM_PER_DAY;
    int conjunctionParts = molad - conjunctionDay * _CHALAKIM_PER_DAY;
    _setMoladTime(conjunctionParts);
  }

  /// Returns the molad hours. Only a JewishDate object populated with [getMolad],
  /// [setJewishDate] or [setMoladHours] will have this field
  /// populated. A regular JewishDate object will have this field set to 0.
  ///
  /// Returns the molad hours
  /// See also [setMoladHours].
  /// See also [getMolad].
  /// See also [setJewishDate].
  int getMoladHours() {
    return _moladHours;
  }

  /// Sets the molad hours.
  ///
  /// - [moladHours]:
  ///   the molad hours to set
  /// See also [getMoladHours].
  /// See also [getMolad].
  /// See also [setJewishDate].
  ///
  void setMoladHours(int moladHours) {
    _moladHours = moladHours;
  }

  /// Returns the molad minutes. Only an object populated with [getMolad],
  /// [setJewishDate] or or [setMoladMinutes] will have these fields
  /// populated. A regular JewishDate object will have this field set to 0.
  ///
  /// Returns the molad minutes
  /// See also [setMoladMinutes].
  /// See also [getMolad].
  /// See also [setJewishDate].
  int getMoladMinutes() {
    return _moladMinutes;
  }

  /// Sets the molad minutes. The expectation is that the traditional minute-less chalakim will be broken out to
  /// minutes and [setMoladChalakim] , so 793 (TaShTZaG) parts would have the minutes set to
  /// 44 and chalakim to 1.
  ///
  /// - [moladMinutes]:
  ///   the molad minutes to set
  /// See also [getMoladMinutes].
  /// See also [setMoladChalakim].
  /// See also [getMolad].
  /// See also [setJewishDate].
  ///
  void setMoladMinutes(int moladMinutes) {
    _moladMinutes = moladMinutes;
  }

  /// Sets the molad chalakim/parts. The expectation is that the traditional minute-less chalakim will be broken out to
  /// [setMoladMinutes] and chalakim, so 793 (TaShTZaG) parts would have the minutes set to 44 and
  /// chalakim to 1.
  ///
  /// - [moladChalakim]:
  ///   the molad chalakim/parts to set
  /// See also [getMoladChalakim].
  /// See also [setMoladMinutes].
  /// See also [getMolad].
  /// See also [setJewishDate].
  ///
  void setMoladChalakim(int moladChalakim) {
    _moladChalakim = moladChalakim;
  }

  /// Returns the molad chalakim/parts. Only an object populated with [getMolad],
  /// [setJewishDate] or or [setMoladChalakim] will have these fields
  /// populated. A regular JewishDate object will have this field set to 0.
  ///
  /// Returns the molad chalakim/parts
  /// See also [setMoladChalakim].
  /// See also [getMolad].
  /// See also [setJewishDate].
  int getMoladChalakim() {
    return _moladChalakim;
  }

  /// Returns the number of days in a given month in a given month and year.
  ///
  /// - [month]:
  ///   the month. As with other cases in this class, this is 1-based, not zero-based.
  /// - [year]:
  ///   the year (only impacts February)
  /// Returns the number of days in the month in the given year
  static int _getLastDayOfGregorianMonth(int month, int year) {
    switch (month) {
      case 2:
        if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
          return 29;
        } else {
          return 28;
        }
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      default:
        return 31;
    }
  }

  /// Computes the Gregorian date from the absolute date. ND+ER
  /// - [absDate]: the absolute date
  static DateTime _absDateToDate(int absDate) {
    int year =
        absDate ~/ 366; // Search forward year by year from approximate year
    while (absDate >= _gregorianDateToAbsDate(year + 1, 1, 1)) {
      year++;
    }

    int month = 1; // Search forward month by month from January
    while (absDate >
        _gregorianDateToAbsDate(
            year, month, _getLastDayOfGregorianMonth(month, year))) {
      month++;
    }

    int dayOfMonth = absDate - _gregorianDateToAbsDate(year, month, 1) + 1;
    return DateTime.utc(year, month, dayOfMonth);
  }

  /// Returns the absolute date (days since January 1, 0001 on the Gregorian calendar).
  ///
  /// Returns the number of days since January 1, 1
  int getAbsDate() {
    return _gregorianAbsDate;
  }

  /// Computes the absolute date from a Gregorian date. ND+ER
  ///
  /// - [year]:
  ///   the Gregorian year
  /// - [month]:
  ///   the Gregorian month. Unlike the Java Calendar where January has the value of 0,This expects a 1 for
  ///   January
  /// - [dayOfMonth]:
  ///   the day of the month (1st, 2nd, etc...)
  /// Returns the absolute Gregorian day
  static int _gregorianDateToAbsDate(int year, int month, int dayOfMonth) {
    int absDate = dayOfMonth;
    for (int m = month - 1; m > 0; m--) {
      absDate += _getLastDayOfGregorianMonth(
          m, year); // days in prior months of the year
    }
    return absDate // days this year
        +
        365 * (year - 1) // days in previous years ignoring leap days
        +
        (year - 1) ~/ 4 // Julian leap days before this year
        -
        (year - 1) ~/ 100 // minus prior century years
        +
        (year - 1) ~/ 400; // plus prior years divisible by 400
  }

  /// Returns if the year is a Jewish leap year. Years 3, 6, 8, 11, 14, 17 and 19 in the 19 year cycle are leap years.
  ///
  /// - [year]:
  ///   the Jewish year.
  /// Returns true if it is a leap year
  /// See also [isJewishLeapYear].
  static bool _isJewishLeapYear(int year) {
    return ((7 * year) + 1).remainder(19) < 7;
  }

  /// Returns if the year the calendar is set to, or the [year] passed in, is a Jewish leap year. Years 3, 6, 8, 11,
  /// 14, 17 and 19 in the 19 year cycle are leap years.
  ///
  /// Returns true if it is a leap year
  bool isJewishLeapYear([int? year]) {
    return _isJewishLeapYear(year ?? getJewishYear());
  }

  /// Returns the last month of a given Jewish year. This will be 12 on a non [isJewishLeapYear]
  /// or 13 on a leap year.
  ///
  /// - [year]:
  ///   the Jewish year.
  /// Returns 12 on a non leap year or 13 on a leap year
  /// See also [isJewishLeapYear].
  static int _getLastMonthOfJewishYear(int year) {
    return _isJewishLeapYear(year) ? ADAR_II : ADAR;
  }

  /// Returns the number of days elapsed from the Sunday prior to the start of the Jewish calendar to the mean
  /// conjunction of Tishri of the Jewish year.
  ///
  /// - [year]:
  ///   the Jewish year
  /// Returns the number of days elapsed from prior to the molad Tohu BaHaRaD (Be = Monday, Ha= 5 hours and Rad =204
  /// chalakim/parts) prior to the start of the Jewish calendar, to the mean conjunction of Tishri of the
  /// Jewish year. BeHaRaD is 23:11:20 on Sunday night(5 hours 204/1080 chalakim after sunset on Sunday
  /// evening).
  static int getJewishCalendarElapsedDays(int year) {
    int chalakimSince = _getChalakimSinceMoladTohu(year, TISHREI);
    int moladDay = chalakimSince ~/ _CHALAKIM_PER_DAY;
    int moladParts = chalakimSince - moladDay * _CHALAKIM_PER_DAY;
    // delay Rosh Hashana for the 4 dechiyos
    return _addDechiyos(year, moladDay, moladParts);
  }

  /// Adds the 4 dechiyos for molad Tishrei. These are:
  ///
  /// - Lo ADU Rosh - Rosh Hashana can't fall on a Sunday, Wednesday or Friday. If the molad fell on one of these
  ///   days, Rosh Hashana is delayed to the following day.
  /// - Molad Zaken - If the molad of Tishrei falls after 12 noon, Rosh Hashana is delayed to the following day. If
  ///   the following day is ADU, it will be delayed an additional day.
  /// - GaTRaD - If on a non leap year the molad of Tishrei falls on a Tuesday (Ga) on or after 9 hours (T) and 204
  ///   chalakim (TRaD) it is delayed till Thursday (one day delay, plus one day for Lo ADU Rosh).
  /// - BeTuTaKFoT - if the year following a leap year falls on a Monday (Be) on or after 15 hours (Tu) and 589
  ///   chalakim (TaKFoT) it is delayed till Tuesday.
  ///
  ///
  /// - [year]: the year
  /// - [moladDay]: the molad day
  /// - [moladParts]: the molad parts
  /// Returns the number of elapsed days in the JewishCalendar adjusted for the 4 dechiyos.
  static int _addDechiyos(int year, int moladDay, int moladParts) {
    int roshHashanaDay = moladDay; // if no dechiyos
    // delay Rosh Hashana for the dechiyos of the Molad - new moon 1 - Molad Zaken, 2- GaTRaD 3- BeTuTaKFoT
    if ((moladParts >=
            19440) // Dechiya of Molad Zaken - molad is >= midday (18 hours * 1080 chalakim)
        ||
        (((moladDay % 7) == 2) // start Dechiya of GaTRaD - Ga = is a Tuesday
            &&
            (moladParts >=
                9924) // TRaD = 9 hours, 204 parts or later (9 * 1080 + 204)
            &&
            !_isJewishLeapYear(
                year)) // of a non-leap year - end Dechiya of GaTRaD
        ||
        (((moladDay % 7) ==
                1) // start Dechiya of BeTuTaKFoT - Be = is on a Monday
            &&
            (moladParts >=
                16789) // TRaD = 15 hours, 589 parts or later (15 * 1080 + 589)
            &&
            (_isJewishLeapYear(year - 1)))) {
      // in a year following a leap year - end Dechiya of BeTuTaKFoT
      roshHashanaDay += 1; // Then postpone Rosh HaShanah one day
    }
    // start 4th Dechiya - Lo ADU Rosh - Rosh Hashana can't occur on A- sunday, D- Wednesday, U - Friday
    if (((roshHashanaDay % 7) == 0) // If Rosh HaShanah would occur on Sunday,
        ||
        ((roshHashanaDay % 7) == 3) // or Wednesday,
        ||
        ((roshHashanaDay % 7) == 5)) {
      // or Friday - end 4th Dechiya - Lo ADU Rosh
      roshHashanaDay = roshHashanaDay + 1; // Then postpone it one (more) day
    }
    return roshHashanaDay;
  }

  /// Returns the number of chalakim (parts - 1080 to the hour) from the original hypothetical Molad Tohu to the year
  /// and month passed in.
  ///
  /// - [year]:
  ///   the Jewish year
  /// - [month]:
  ///   the Jewish month the Jewish month, with the month numbers starting from Nisan. Use the JewishDate
  ///   constants such as [JewishDate.TISHREI].
  /// Returns the number of chalakim (parts - 1080 to the hour) from the original hypothetical Molad Tohu
  static int _getChalakimSinceMoladTohu(int year, int month) {
    int y = year - 1;
    int monthOfYear = _getJewishMonthOfYear(year, month);
    int monthsElapsed = (235 * (y ~/ 19)) +
        (12 * y.remainder(19)) +
        ((7 * y.remainder(19) + 1) ~/ 19) +
        (monthOfYear - 1);
    return _CHALAKIM_MOLAD_TOHU + (_CHALAKIM_PER_MONTH * monthsElapsed);
  }

  /// Returns the number of chalakim (parts - 1080 to the hour) from the original hypothetical Molad Tohu to the Jewish
  /// year and month that this Object is set to.
  ///
  /// Returns the number of chalakim (parts - 1080 to the hour) from the original hypothetical Molad Tohu
  int getChalakimSinceMoladTohu() {
    return _getChalakimSinceMoladTohu(_jewishYear, _jewishMonth);
  }

  /// Converts the [JewishDate.NISSAN] based constants used by this class to numeric month starting from
  /// [JewishDate.TISHREI]. This is required for Molad claculations.
  ///
  /// - [year]:
  ///   The Jewish year
  /// - [month]:
  ///   The Jewish Month
  /// Returns the Jewish month of the year starting with Tishrei
  static int _getJewishMonthOfYear(int year, int month) {
    bool isLeapYear = _isJewishLeapYear(year);
    return (month + (isLeapYear ? 6 : 5)) % (isLeapYear ? 13 : 12) + 1;
  }

  /// Validates the components of a Jewish date for validity. It will throw an [ArgumentError] if the
  /// Jewish date is earlier than 18 Teves, 3761 (1/1/1 Gregorian), a month < 1 or > 12 (or 13 on a
  /// [isJewishLeapYear]), the day of month is < 1 or > 30, an hour < 0 or > 23, a minute < 0
  /// or > 59 or chalakim < 0 or > 17. For a larger number of chalakim such as 793 (TaShTzaG) break the chalakim into
  /// minutes (18 chalakim per minute, so it would be 44 minutes and 1 chelek in the case of 793/TaShTzaG).
  ///
  /// - [year]:
  ///   the Jewish year to validate. It will reject any year <= 3761 (lower than the year 1 Gregorian).
  /// - [month]:
  ///   the Jewish month to validate. It will reject a month < 1 or > 12 (or 13 on a leap year) .
  /// - [dayOfMonth]:
  ///   the day of the Jewish month to validate. It will reject any value < 1 or > 30 TODO: check calling
  ///   methods to see if there is any reason that the class can validate that 30 is invalid for some months.
  /// - [hours]:
  ///   the hours (for molad calculations). It will reject an hour < 0 or > 23
  /// - [minutes]:
  ///   the minutes (for molad calculations). It will reject a minute < 0 or > 59
  /// - [chalakim]:
  ///   the chalakim/parts (for molad calculations). It will reject a chalakim < 0 or > 17. For larger numbers
  ///   such as 793 (TaShTzaG) break the chalakim into minutes (18 chalakim per minutes, so it would be 44
  ///   minutes and 1 chelek in the case of 793/TaShTzaG)
  ///
  /// Throws [ArgumentError]
  ///             if a A Jewish date earlier than 18 Teves, 3761 (1/1/1 Gregorian), a month < 1 or > 12 (or 13 on a
  ///             leap year), the day of month is < 1 or > 30, an hour < 0 or > 23, a minute < 0 or > 59 or
  ///             chalakim < 0 or > 17. For larger a larger number of chalakim such as 793 (TaShTzaG) break the chalakim
  ///             into minutes (18 chalakim per minutes, so it would be 44 minutes and 1 chelek in the case of 793 (TaShTzaG).
  static void _validateJewishDate(int year, int month, int dayOfMonth,
      int hours, int minutes, int chalakim) {
    if (month < NISSAN || month > _getLastMonthOfJewishYear(year)) {
      throw ArgumentError(
          "The Jewish month has to be between 1 and 12 (or 13 on a leap year). $month is invalid for the year $year.");
    }
    final int monthLength = _getDaysInJewishMonth(month, year);
    if (dayOfMonth < 1 || dayOfMonth > monthLength) {
      throw ArgumentError(
          "The Jewish day of month can't be < 1 or > $monthLength for month $month. $dayOfMonth is invalid.");
    }
    // reject dates prior to 18 Teves, 3761 (1/1/1 AD). This restriction can be relaxed if the date coding is
    // changed/corrected
    if ((year < 3761) ||
        (year == 3761 && (month >= TISHREI && month < TEVES)) ||
        (year == 3761 && month == TEVES && dayOfMonth < 18)) {
      throw ArgumentError(
          "A Jewish date earlier than 18 Teves, 3761 (1/1/1 Gregorian) can't be set. $year , $month, $dayOfMonth  is invalid.");
    }
    if (hours < 0 || hours > 23) {
      throw ArgumentError("Hours < 0 or > 23 can't be set. $hours is invalid.");
    }

    if (minutes < 0 || minutes > 59) {
      throw ArgumentError(
          "Minutes < 0 or > 59 can't be set. $minutes is invalid.");
    }

    if (chalakim < 0 || chalakim > 17) {
      throw ArgumentError(
          "Chalakim/parts < 0 or > 17 can't be set. $chalakim is invalid. For larger numbers such as "
          "793 (TaShTzaG) break the chalakim into minutes (18 chalakim per minutes, so it would be "
          "44 minutes and 1 chelek in the case of 793 (TaShTzaG)");
    }
  }

  /// Returns the number of days for a given Jewish year. ND+ER
  ///
  /// - [year]:
  ///   the Jewish year
  /// Returns the number of days for a given Jewish year.
  /// See also [isCheshvanLong].
  /// See also [isKislevShort].
  static int _getDaysInJewishYear(int year) {
    return getJewishCalendarElapsedDays(year + 1) -
        getJewishCalendarElapsedDays(year);
  }

  /// Returns the number of days for the current year that the calendar is set to, or for the [year] passed in.
  ///
  /// Returns the number of days for the Jewish year.
  /// See also [isCheshvanLong].
  /// See also [isKislevShort].
  /// See also [isJewishLeapYear].
  int getDaysInJewishYear([int? year]) {
    return _getDaysInJewishYear(year ?? getJewishYear());
  }

  /// Returns if Cheshvan is long in a given Jewish year. The method name isLong is done since in a Kesidran (ordered)
  /// year Cheshvan is short. ND+ER
  ///
  /// - [year]:
  ///   the year
  /// Returns true if Cheshvan is long in Jewish year.
  /// See also [isCheshvanLong].
  /// See also [getCheshvanKislevKviah].
  static bool _isCheshvanLong(int year) {
    return _getDaysInJewishYear(year) % 10 == 5;
  }

  /// Returns if Cheshvan is long (30 days VS 29 days) for the current year that the calendar is set to. The method
  /// name isLong is done since in a Kesidran (ordered) year Cheshvan is short.
  ///
  /// Returns true if Cheshvan is long for the current year that the calendar is set to
  /// See also [isCheshvanLong].
  bool isCheshvanLong() {
    return _isCheshvanLong(getJewishYear());
  }

  /// Returns if Kislev is short (29 days VS 30 days) in a given Jewish year. The method name isShort is done since in
  /// a Kesidran (ordered) year Kislev is long. ND+ER
  ///
  /// - [year]:
  ///   the Jewish year
  /// Returns true if Kislev is short for the given Jewish year.
  /// See also [isKislevShort].
  /// See also [getCheshvanKislevKviah].
  static bool _isKislevShort(int year) {
    return _getDaysInJewishYear(year) % 10 == 3;
  }

  /// Returns if the Kislev is short for the year that this class is set to. The method name isShort is done since in a
  /// Kesidran (ordered) year Kislev is long.
  ///
  /// Returns true if Kislev is short for the year that this class is set to
  bool isKislevShort() {
    return _isKislevShort(getJewishYear());
  }

  /// Returns the Cheshvan and Kislev kviah (whether a Jewish year is short, regular or long). It will return
  /// [SHELAIMIM] if both cheshvan and kislev are 30 days, [KESIDRAN] if Cheshvan is 29 days and Kislev
  /// is 30 days and [CHASERIM] if both are 29 days.
  ///
  /// Returns [SHELAIMIM] if both cheshvan and kislev are 30 days, [KESIDRAN] if Cheshvan is 29 days and
  /// Kislev is 30 days and [CHASERIM] if both are 29 days.
  /// See also [isCheshvanLong].
  /// See also [isKislevShort].
  int getCheshvanKislevKviah() {
    int daysInYear = _getDaysInJewishYear(getJewishYear());
    bool cheshvanLong = daysInYear % 10 == 5;
    bool kislevShort = daysInYear % 10 == 3;
    if (cheshvanLong && !kislevShort) {
      return SHELAIMIM;
    } else if (!cheshvanLong && kislevShort) {
      return CHASERIM;
    } else {
      return KESIDRAN;
    }
  }

  /// Returns the number of days of a Jewish month for a given month and year.
  ///
  /// - [month]:
  ///   the Jewish month
  /// - [year]:
  ///   the Jewish Year
  /// Returns the number of days for a given Jewish month
  static int _getDaysInJewishMonth(int month, int year) {
    if ((month == IYAR) ||
        (month == TAMMUZ) ||
        (month == ELUL) ||
        ((month == CHESHVAN) && !(_isCheshvanLong(year))) ||
        ((month == KISLEV) && _isKislevShort(year)) ||
        (month == TEVES) ||
        ((month == ADAR) && !(_isJewishLeapYear(year))) ||
        (month == ADAR_II)) {
      return 29;
    } else {
      return 30;
    }
  }

  /// Returns the number of days of the Jewish month that the calendar is currently set to.
  ///
  /// Returns the number of days for the Jewish month that the calendar is currently set to.
  int getDaysInJewishMonth() {
    return _getDaysInJewishMonth(getJewishMonth(), getJewishYear());
  }

  /// Computes and sets the Jewish date fields based on the provided absolute (Gregorian) date.
  void _setAbsDate(int gregorianAbsDate) {
    if (gregorianAbsDate <= 0) {
      throw ArgumentError("Dates in the BC era are not supported");
    }
    _gregorianAbsDate = gregorianAbsDate;
    // Approximation from below
    _jewishYear = (gregorianAbsDate - _JEWISH_EPOCH) ~/ 366;
    // Search forward for year from the approximation
    while (
        gregorianAbsDate >= _jewishDateToAbsDate(_jewishYear + 1, TISHREI, 1)) {
      _jewishYear++;
    }
    // Search forward for month from either Tishri or Nisan.
    if (gregorianAbsDate < _jewishDateToAbsDate(_jewishYear, NISSAN, 1)) {
      _jewishMonth = TISHREI; // Start at Tishri
    } else {
      _jewishMonth = NISSAN; // Start at Nisan
    }
    while (gregorianAbsDate >
        _jewishDateToAbsDate(_jewishYear, _jewishMonth,
            _getDaysInJewishMonth(_jewishMonth, _jewishYear))) {
      _jewishMonth++;
    }
    // Calculate the day by subtraction
    _jewishDay = gregorianAbsDate -
        _jewishDateToAbsDate(_jewishYear, _jewishMonth, 1) +
        1;

    _dayOfWeek = (gregorianAbsDate % 7).abs() + 1;
  }

  /// Returns the absolute date of Jewish date. ND+ER
  ///
  /// - [year]:
  ///   the Jewish year. The year can't be negative
  /// - [month]:
  ///   the Jewish month starting with Nisan. Nisan expects a value of 1 etc till Adar with a value of 12. For
  ///   a leap year, 13 will be the expected value for Adar II. Use the constants [JewishDate.NISSAN]
  ///   etc.
  /// - [dayOfMonth]:
  ///   the Jewish day of month. valid values are 1-30. If the day of month is set to 30 for a month that only
  ///   has 29 days, the day will be set as 29.
  /// Returns the absolute date of the Jewish date.
  static int _jewishDateToAbsDate(int year, int month, int dayOfMonth) {
    int elapsed = _getDaysSinceStartOfJewishYear(year, month, dayOfMonth);
    // add elapsed days this year + Days in prior years + Days elapsed before absolute year 1
    return elapsed + getJewishCalendarElapsedDays(year) + _JEWISH_EPOCH;
  }

  /// Returns the molad for a given year and month. Returns a JewishDate [Object] set to the date of the molad
  /// with the [getMoladHours], [getMoladMinutes] and [getMoladChalakim] set. In the current implementation, it sets the molad time based on a midnight date rollover. This
  /// means that Rosh Chodesh Adar II, 5771 with a molad of 7 chalakim past midnight on Shabbos 29 Adar I / March 5,
  /// 2011 12:00 AM and 7 chalakim, will have the following values: hours: 0, minutes: 0, Chalakim: 7.
  ///
  /// Returns a JewishDate [Object] set to the date of the molad with the [getMoladHours],
  /// [getMoladMinutes] and [getMoladChalakim] set.
  JewishDate getMolad() {
    JewishDate moladDate = JewishDate.fromMolad(getChalakimSinceMoladTohu());
    if (moladDate.getMoladHours() >= 6) {
      moladDate.plusDays(1);
    }
    moladDate.setMoladHours((moladDate.getMoladHours() + 18) % 24);
    return moladDate;
  }

  /// Returns the number of days from the Jewish epoch from the number of chalakim from the epoch passed in.
  ///
  /// - [chalakim]:
  ///   the number of chalakim since the beginning of Sunday prior to BaHaRaD
  /// Returns the number of days from the Jewish epoch
  static int _moladToAbsDate(int chalakim) {
    return chalakim ~/ _CHALAKIM_PER_DAY + _JEWISH_EPOCH;
  }

  /// Sets the molad time (hours minutes and chalakim) based on the number of chalakim since the start of the day.
  ///
  /// - [chalakim]:
  ///   the number of chalakim since the start of the day.
  void _setMoladTime(int chalakim) {
    int adjustedChalakim = chalakim;
    setMoladHours(adjustedChalakim ~/ _CHALAKIM_PER_HOUR);
    adjustedChalakim =
        adjustedChalakim - (getMoladHours() * _CHALAKIM_PER_HOUR);
    setMoladMinutes(adjustedChalakim ~/ _CHALAKIM_PER_MINUTE);
    setMoladChalakim(adjustedChalakim - _moladMinutes * _CHALAKIM_PER_MINUTE);
  }

  /// returns the number of days from Rosh Hashana of the date passed in, to the full date passed in.
  ///
  /// - [year]:
  ///   the Jewish year
  /// - [month]:
  ///   the Jewish month
  /// - [dayOfMonth]:
  ///   the day in the Jewish month
  /// Returns the number of days
  static int _getDaysSinceStartOfJewishYear(
      int year, int month, int dayOfMonth) {
    int elapsedDays = dayOfMonth;
    // Before Tishrei (from Nissan to Tishrei), add days in prior months
    if (month < TISHREI) {
      // this year before and after Nisan.
      for (int m = TISHREI; m <= _getLastMonthOfJewishYear(year); m++) {
        elapsedDays += _getDaysInJewishMonth(m, year);
      }
      for (int m = NISSAN; m < month; m++) {
        elapsedDays += _getDaysInJewishMonth(m, year);
      }
    } else {
      // Add days in prior months this year
      for (int m = TISHREI; m < month; m++) {
        elapsedDays += _getDaysInJewishMonth(m, year);
      }
    }
    return elapsedDays;
  }

  /// returns the number of days from Rosh Hashana of the date passed in, to the full date passed in.
  ///
  /// Returns the number of days
  int getDaysSinceStartOfJewishYear() {
    return _getDaysSinceStartOfJewishYear(
        getJewishYear(), getJewishMonth(), getJewishDayOfMonth());
  }

  /// Sets the date based on a [DateTime] object's year, month and day. Modifies the Jewish date as well.
  ///
  /// - [localDate]:
  ///   the [DateTime] to set the calendar to
  /// Throws [ArgumentError]
  ///             if the date is in the BC era
  void setGregorianDate(DateTime localDate) {
    _setAbsDate(_gregorianDateToAbsDate(
        localDate.year, localDate.month, localDate.day));
  }

  /// Sets the Jewish Date and updates the Gregorian date accordingly.
  ///
  /// - [year]:
  ///   the Jewish year. The year can't be negative
  /// - [month]:
  ///   the Jewish month starting with Nisan. A value of 1 is expected for Nissan ... 12 for Adar and 13 for
  ///   Adar II. Use the constants [NISSAN] ... [ADAR] (or [ADAR_II] for a leap year Adar
  ///   II) to avoid any confusion.
  /// - [dayOfMonth]:
  ///   the Jewish day of month. valid values are 1-30. If the day of month is set to 30 for a month that only
  ///   has 29 days, the day will be set as 29.
  ///
  /// - [hours]:
  ///   the hour of the day. Used for Molad calculations
  /// - [minutes]:
  ///   the minutes. Used for Molad calculations
  /// - [chalakim]:
  ///   the chalakim/parts. Used for Molad calculations. The chalakim should not exceed 17. Minutes should be
  ///   used for larger numbers.
  ///
  /// Throws [ArgumentError]
  ///             if a A Jewish date earlier than 18 Teves, 3761 (1/1/1 Gregorian), a month < 1 or > 12 (or 13 on a
  ///             leap year), the day of month is < 1 or > 30, an hour < 0 or > 23, a minute < 0 > 59 or chalakim < 0 >
  ///             17. For larger a larger number of chalakim such as 793 (TaShTzaG) break the chalakim into minutes (18
  ///             chalakim per minutes, so it would be 44 minutes and 1 chelek in the case of 793 (TaShTzaG).
  void setJewishDate(int year, int month, int dayOfMonth,
      [int? hours, int? minutes, int? chalakim]) {
    hours ??= getMoladHours();
    minutes ??= getMoladMinutes();
    chalakim ??= getMoladChalakim();
    _validateJewishDate(year, month, dayOfMonth, hours, minutes, chalakim);

    _jewishYear = year;
    _jewishMonth = month;
    _jewishDay = dayOfMonth;
    _moladHours = hours;
    _moladMinutes = minutes;
    _moladChalakim = chalakim;

    _gregorianAbsDate = _jewishDateToAbsDate(
        _jewishYear, _jewishMonth, _jewishDay); // reset Gregorian date

    _dayOfWeek = (_gregorianAbsDate % 7).abs() + 1; // reset day of week
  }

  /// Setter for the Jewish day of the month.
  ///
  /// - [dayOfMonth]:
  ///   the Jewish day of month
  /// Throws [ArgumentError]
  ///             if the day of month is < 1 or > 30 is passed in
  void setJewishDayOfMonth(int dayOfMonth) {
    setJewishDate(getJewishYear(), getJewishMonth(), dayOfMonth);
  }

  /// Setter for the Jewish month that is passed in. If the day of month is currently the 30th and the month is
  /// being set to a month that only has 29 days, the day of month will be clamped to the 29th of the month.
  ///
  /// - [month]:
  ///   the Jewish month from 1 to 12 (or 13 years in a leap year). The month count starts with 1 for Nisan
  ///   and goes to 13 for Adar II
  /// Throws [ArgumentError]
  ///             if a month < 1 or > 12 (or 13 on a leap year) is passed in
  void setJewishMonth(int month) {
    int year = getJewishYear();
    int day = min(_getDaysInJewishMonth(month, year), getJewishDayOfMonth());
    setJewishDate(year, month, day);
  }

  /// Setter for the Jewish year that will clamp the day to the month to the lesser of the current day and the max
  /// number of days in the month (if set to the 30th).
  ///
  /// - [year]:
  ///   the Jewish year
  /// Throws [ArgumentError]
  ///             if a year of < 3761 is passed in. The same will happen if the year is 3761 and the month and day
  ///             previously set are < 18 Teves (prior to Jan 1, 1 AD)
  void setJewishYear(int year) {
    int month = min(getJewishMonth(), _getLastMonthOfJewishYear(year));
    int day = min(getJewishDayOfMonth(), _getDaysInJewishMonth(month, year));
    setJewishDate(year, month, day);
  }

  /// Returns this object's date as a UTC midnight [DateTime].
  DateTime getLocalDate() {
    return _absDateToDate(getAbsDate());
  }

  /// Resets this date to the current system date.
  void resetDate() {
    setGregorianDate(DateTime.now());
  }

  void minusDays(int days) {
    if (days < 1) {
      throw ArgumentError(
          "The number of days to subtract must be greater than zero.");
    }
    _setAbsDate(getAbsDate() - days);
  }

  void plusDays(int days) {
    if (days < 1) {
      throw ArgumentError(
          "The number of days to add must be greater than zero. Use minusDays(int) to subtract days.");
    }
    _setAbsDate(getAbsDate() + days);
  }

  void plusMonths(int months) {
    if (months < 1) {
      throw ArgumentError(
          "The number of months to add must be greater than zero. Use minusMonths(int) to subtract months.");
    }
    int year = getJewishYear();
    int month = getJewishMonth();
    for (int i = 0; i < months; i++) {
      if (month == ELUL) {
        month = TISHREI;
        year++;
      } else if ((!_isJewishLeapYear(year) && month == ADAR) ||
          (_isJewishLeapYear(year) && month == ADAR_II)) {
        month = NISSAN;
      } else {
        month++;
      }
    }
    int day = min(getJewishDayOfMonth(), _getDaysInJewishMonth(month, year));
    setJewishDate(year, month, day);
  }

  void minusMonths(int months) {
    if (months < 1) {
      throw ArgumentError(
          "The number of months to subtract must be greater than zero.");
    }
    int year = getJewishYear();
    int month = getJewishMonth();
    for (int i = 0; i < months; i++) {
      if (month == TISHREI) {
        month = ELUL;
        year--;
      } else if (month == NISSAN) {
        month = _getLastMonthOfJewishYear(year);
      } else if (!_isJewishLeapYear(year) && month == ADAR) {
        month = SHEVAT;
      } else {
        month--;
      }
    }
    int day = min(getJewishDayOfMonth(), _getDaysInJewishMonth(month, year));
    setJewishDate(year, month, day);
  }

  void plusYears(int years, bool useAdarAlephForLeapYear) {
    if (years < 1) {
      throw ArgumentError(
          "The number of years to add has to be greater than zero. Use minusYears(int, boolean) to subtract years.");
    }
    _moveToYear(getJewishYear() + years, useAdarAlephForLeapYear);
  }

  void minusYears(int years, bool useAdarAlephForLeapYear) {
    if (years < 1) {
      throw ArgumentError(
          "The number of years to subtract has to be greater than zero.");
    }
    _moveToYear(getJewishYear() - years, useAdarAlephForLeapYear);
  }

  void _moveToYear(int targetYear, bool useAdarAlephForLeapYear) {
    final int month;
    if (getJewishMonth() == ADAR &&
        !_isJewishLeapYear(getJewishYear()) &&
        _isJewishLeapYear(targetYear)) {
      month = useAdarAlephForLeapYear ? ADAR : ADAR_II;
    } else {
      month = min(getJewishMonth(), _getLastMonthOfJewishYear(targetYear));
    }
    int day =
        min(getJewishDayOfMonth(), _getDaysInJewishMonth(month, targetYear));
    setJewishDate(targetYear, month, day);
  }

  /// Returns a string containing the Jewish date in the form, "day Month, year" e.g. "21 Shevat, 5729". For more
  /// complex formatting, use the formatter classes.
  ///
  /// Returns the Jewish date in the form "day Month, year" e.g. "21 Shevat, 5729"
  /// See also [HebrewDateFormatter.format].
  @override
  String toString() {
    return HebrewDateFormatter().format(this);
  }

  /// Indicates whether some other object is "equal to" this one: an object of the same class set to the same
  /// absolute date.
  @override
  bool operator ==(Object object) {
    if (identical(this, object)) {
      return true;
    }
    if (object.runtimeType != runtimeType) {
      return false;
    }
    JewishDate jewishDate = object as JewishDate;
    return _gregorianAbsDate == jewishDate.getAbsDate();
  }

  /// Compares two dates as per the compareTo() method in the Comparable interface. Returns a value less than 0 if this
  /// date is "less than" (before) the date, greater than 0 if this date is "greater than" (after) the date, or 0 if
  /// they are equal.
  @override
  int compareTo(JewishDate jewishDate) {
    return _gregorianAbsDate.compareTo(jewishDate.getAbsDate());
  }

  /// Returns the Jewish month 1-12 (or 13 years in a leap year). The month count starts with 1 for Nisan and goes to
  /// 13 for Adar II
  ///
  /// Returns the Jewish month from 1 to 12 (or 13 years in a leap year). The month count starts with 1 for Nisan and
  /// goes to 13 for Adar II
  int getJewishMonth() {
    return _jewishMonth;
  }

  /// Returns the Jewish day of month.
  ///
  /// Returns the Jewish day of the month
  int getJewishDayOfMonth() {
    return _jewishDay;
  }

  /// Returns the Jewish year.
  ///
  /// Returns the Jewish year
  int getJewishYear() {
    return _jewishYear;
  }

  /// Returns the day of the week as a number between 1-7.
  ///
  /// Returns the day of the week as a number between 1-7.
  int getDayOfWeek() {
    return _dayOfWeek;
  }

  /// Creates a [deep copy](http://en.wikipedia.org/wiki/Object_copy#Deep_copy) of this object.
  JewishDate clone() {
    return JewishDate.fromLocalDate(getLocalDate())
      ..setMoladHours(getMoladHours())
      ..setMoladMinutes(getMoladMinutes())
      ..setMoladChalakim(getMoladChalakim());
  }

  /// Returns a hash code based on the absolute Gregorian date.
  @override
  int get hashCode => _gregorianAbsDate.hashCode;
}
