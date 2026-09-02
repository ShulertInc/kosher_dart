/*
 * Zmanim Java API
 * Copyright (C) 2017 - 2018 Eliyahu Hershfeld
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

import 'package:kosher_dart/src/hebrewcalendar/daf.dart';
import 'package:kosher_dart/src/hebrewcalendar/jewish_calendar.dart';
import 'package:kosher_dart/src/hebrewcalendar/jewish_date.dart';

/// This class calculates the [Talmud Yerusalmi](https://en.wikipedia.org/wiki/Jerusalem_Talmud) [Daf Yomi]
/// (https://en.wikipedia.org/wiki/Daf_Yomi) page ([Daf]) for the a given date.
///
/// © elihaidv
/// © Eliyahu Hershfeld 2017 - 2018
class YerushalmiYomiCalculator {
  /// The start date of the first Daf Yomi Yerushalmi cycle of February 2, 1980 / 15 Shevat, 5740.

  static final DateTime dafYomiStartDay = DateTime(1980, 2, 2);

  /// The number of milliseconds in a day.
  static const int DAY_MILIS = 1000 * 60 * 60 * 24;

  /// he number of pages in the Talmud Yerushalmi.
  static const int WHOLE_SHAS_DAFS = 1554;

  /// The number of pages per _masechta_ (tractate).
  static const List<int> BLATT_PER_MASSECTA = [
    68,
    37,
    34,
    44,
    31,
    59,
    26,
    33,
    28,
    20,
    13,
    92,
    65,
    71,
    22,
    22,
    42,
    26,
    26,
    33,
    34,
    22,
    19,
    85,
    72,
    47,
    40,
    47,
    54,
    48,
    44,
    37,
    34,
    44,
    9,
    57,
    37,
    19,
    13
  ];

  /// Returns the [Daf Yomi](https://en.wikipedia.org/wiki/Daf_Yomi)
  /// [Yerusalmi](https://en.wikipedia.org/wiki/Jerusalem_Talmud) page ([Daf]) for a given date.
  /// The first Daf Yomi cycle started on 15 Shevat (Tu Bishvat), 5740 (February, 2, 1980) and calculations
  /// prior to this date will result in an IllegalArgumentException thrown.
  ///
  /// - [calendar]: 
  ///   the calendar date for calculation
  /// Returns the [Daf].
  ///
  /// Throws [ArgumentError] 
  ///             if the date is prior to the September 11, 1923 start date of the first Daf Yomi cycle
  static Daf getDafYomiYerushalmi(JewishCalendar calendar) {
    int masechta = 0;
    Daf dafYomi = Daf(0, 0);

    // There isn't Daf Yomi in Yom Kippur and Tisha Beav.
    if (calendar.getYomTovIndex() == JewishCalendar.YOM_KIPPUR ||
        calendar.getYomTovIndex() == JewishCalendar.TISHA_BEAV) {
      return Daf(39, 0);
    }

    // Counting in absolute days rather than in DateTime keeps the answer off the
    // machine's own time zone, which used to shift the whole count by a day.
    final int requested = calendar.getAbsDate();
    if (requested < _dafYomiStartAbsDate) {
      // TODO: should we return a null or throw an IllegalArgumentException?
      throw ArgumentError(
          "$requested is prior to organized Daf Yomi Yerushlmi cycles that started on $dafYomiStartDay");
    }

    // Go cycle by cycle, until we get the cycle the requested day falls in
    int cycleStart = _dafYomiStartAbsDate;
    int nextCycle = _cycleEnd(cycleStart) + 1;
    while (requested >= nextCycle) {
      cycleStart = nextCycle;
      nextCycle = _cycleEnd(cycleStart) + 1;
    }

    // Get the number of days from cycle start until request, less the days with no daf.
    int total = requested - cycleStart - _getNumOfSpecialDays(cycleStart, requested);

    // Finally find the daf. The count is zero based, so a masechta of n blatt
    // holds offsets 0 through n - 1; offset n is the first daf of the next one.
    for (int j = 0; j < BLATT_PER_MASSECTA.length; j++) {
      if (total < BLATT_PER_MASSECTA[j]) {
        dafYomi = Daf(masechta, total + 1);
        break;
      }
      total -= BLATT_PER_MASSECTA[j];
      masechta++;
    }

    return dafYomi;
  }

  /// The last day of the cycle that began on [cycleStart]. A cycle runs for as many
  /// days as the Shas has blatt, plus one day for every day in that span with no daf -
  /// and those extra days can themselves land on a day with no daf, so the span grows
  /// until it stops picking up new ones.
  static int _cycleEnd(int cycleStart) {
    int end = cycleStart + WHOLE_SHAS_DAFS - 1;
    int found = _getNumOfSpecialDays(cycleStart, end);
    while (found > 0) {
      final int extensionStart = end + 1;
      end += found;
      found = _getNumOfSpecialDays(extensionStart, end);
    }
    return end;
  }

  /// Return the number of special days (Yom Kippur and Tisha Beav) That there is no Daf in this days.
  /// From the last given number of days until given date
  ///
  /// - [start]: start date to calculate, exclusive
  /// - [end]: end date to calculate, inclusive
  /// Returns the number of special days
  static int _getNumOfSpecialDays(int start, int end) {
    // Find the start and end Jewish years
    int startYear = _jewishYearOfAbsDate(start);
    int endYear = _jewishYearOfAbsDate(end);

    // Value to return
    int specialDays = 0;

    //Instant of special Dates
    JewishCalendar yomKippur = JewishCalendar.initDate(5770, 7, 10);
    JewishCalendar tishaBeav = JewishCalendar.initDate(5770, 5, 9);

    // Go over the years and find special dates
    for (int i = startYear; i <= endYear; i++) {
      yomKippur.setJewishYear(i);
      tishaBeav.setJewishYear(i);

      // A Tisha B'Av on Shabbos is fasted, and skipped, on the Sunday.
      final int tishaBeavAbsDate = tishaBeav.getAbsDate() +
          (tishaBeav.getDayOfWeek() == JewishDate.saturday ? 1 : 0);

      if (_isBetween(start, yomKippur.getAbsDate(), end)) {
        specialDays++;
      }
      if (_isBetween(start, tishaBeavAbsDate, end)) {
        specialDays++;
      }
    }

    return specialDays;
  }

  /// The absolute date of the first day of the first cycle.
  static final int _dafYomiStartAbsDate =
      JewishCalendar.fromDateTime(dafYomiStartDay).getAbsDate();

  static int _jewishYearOfAbsDate(int absDate) =>
      JewishCalendar.fromDateTime(_gregorianOfAbsDate(absDate)).getJewishYear();

  /// Absolute date 1 is January 1, 1 on the proleptic Gregorian calendar, which is
  /// also where Dart's `DateTime` starts counting.
  static DateTime _gregorianOfAbsDate(int absDate) =>
      DateTime.utc(1, 1, 1).add(Duration(days: absDate - 1));

  /// Return if the date is between two dates
  ///
  /// - [start]: the start date
  /// - [date]: the date being compared
  /// - [end]: the end date
  /// Returns if the date is after the start date and on or before the end date
  static bool _isBetween(int start, int date, int end) {
    return start < date && date <= end;
  }
}
