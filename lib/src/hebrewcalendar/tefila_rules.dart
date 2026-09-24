/*
 * Zmanim Dart API
 *
 * Copyright (C) 2019 - 2022 Eliyahu Hershfeld
 * Copyright (C) 2019 - 2021 Y Paritcher
 * 
 * This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General
 * License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General License for more
 * details.
 * You should have received a copy of the GNU Lesser General License along with this library; if not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA,
 * or connect to: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
 * 
 * Port Author: Daniel Smith (https://github.com/DanielSmith1239)
 */

import 'package:kosher_dart/kosher_dart.dart';

/// Tefila Rules is a utility class that covers the various _halachos_ and _minhagim_ regarding
/// changes to daily _tefila_ / prayers,
/// based on the Jewish calendar. This is mostly useful for use in
/// developing _siddur_ type applications,
/// but it is also valuable for _shul_ calendars that set
/// _tefila_ times based on if [_tachanun_](https://en.wikipedia.org/wiki/Tachanun) is
/// recited that day. There are many settings in this class to cover the vast majority of _minhagim_,
/// but
/// there are likely some not covered here. The source for many of the _chasidishe minhagim_ can be found
/// in the [Minhag Yisrael Torah](https://www.nli.org.il/he/books/NNL_ALEPH001141272/NLI) on Orach
/// Chaim 131.
/// Dates used in specific communities such as specific _yahrzeits_ or a holidays like Purim Mezhbizh
/// (Medzhybizh) celebrated on 11 [JewishDate.TEVES] or [Purim Saragossa](https://en.wikipedia.org/wiki/Second_Purim#Purim_Saragossa_(18_Shevat)) celebrated on
/// the (17th or) 18th of [JewishDate.SHEVAT] are not (and likely will not be) supported by
/// this class.
/// Sample code:
///
/// ```dart
///  TefilaRules tr = new TefilaRules();
///  JewishCalendar jewishCalendar = new JewishCalendar();
///  HebrewDateFormatter hdf = new HebrewDateFormatter();
///  jewishCalendar.setJewishDate(5783,
///  JewishDate.TISHREI,
///  1); // Rosh Hashana
///  System.out.println(hdf.format(jewishCalendar) + ": " + tr.isTachanunRecitedShacharis(jd));
///  jewishCalendar.setJewishDate(5783,
///  JewishDate.ADAR,
///  17);
///  System.out.println(hdf.format(jewishCalendar) + ": " + tr.isTachanunRecitedShacharis(jewishCalendar));
///  tr.setTachanunRecitedWeekOfPurim(false);
/// System.out.println(hdf.format(jewishCalendar) + ": " + tr.isTachanunRecitedShacharis(jewishCalendar));
/// ```
///
/// ### Authors
/// - © Y. Paritcher 2019 - 2021
/// - © Eliyahu Hershfeld 2019 - 2022
///
///
/// TODO The following items may be added at a future date.
/// - *Lamnatzaiach*
/// - ...
class TefilaRules {
  bool _tachanunRecitedEndOfTishrei = true;

  bool _tachanunRecitedWeekAfterShavuos = false;

  bool _tachanunRecited13SivanOutOfIsrael = true;

  bool _tachanunRecitedPesachSheni = false;

  bool _tachanunRecited15IyarOutOfIsrael = true;

  bool _tachanunRecitedMinchaErevLagBaomer = false;

  bool _tachanunRecitedShivasYemeiHamiluim = true;

  bool _tachanunRecitedWeekOfHod = true;

  bool _tachanunRecitedWeekOfPurim = true;

  bool _tachanunRecitedFridays = true;

  bool _tachanunRecitedSundays = true;

  bool _tachanunRecitedMinchaAllYear = true;

  bool _mizmorLesodaRecitedErevYomKippurAndPesach = false;

  bool _selichosRecitedAllElul = false;

  TefilaRules();

  /// Returns if _tachanun_ is recited during _shacharis_ on the day in question. See the many
  /// _minhag_ based settings that are available in this class.
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns if _tachanun_ is recited during _shacharis_.
  /// See also [isTachanunRecitedMincha].
  bool isTachanunRecitedShacharis(JewishCalendar jewishCalendar) {
    final int holidayIndex = jewishCalendar.getYomTovIndex();
    final int day = jewishCalendar.getJewishDayOfMonth();
    final int month = jewishCalendar.getJewishMonth();
    final bool leapYear = jewishCalendar.isJewishLeapYear();
    final bool lastAdar = (!leapYear && month == JewishDate.ADAR) ||
        (leapYear && month == JewishDate.ADAR_II);

    return jewishCalendar.getDayOfWeek() != _SATURDAY &&
        (_tachanunRecitedSundays ||
            jewishCalendar.getDayOfWeek() != _SUNDAY) &&
        (_tachanunRecitedFridays ||
            jewishCalendar.getDayOfWeek() != _FRIDAY) &&
        month != JewishDate.NISSAN &&
        (month != JewishDate.TISHREI ||
            ((_tachanunRecitedEndOfTishrei || day <= 8) &&
                (!_tachanunRecitedEndOfTishrei || (day <= 8 || day >= 22)))) &&
        (month != JewishDate.SIVAN ||
            ((!_tachanunRecitedWeekAfterShavuos || day >= 7) &&
                (_tachanunRecitedWeekAfterShavuos ||
                    day >=
                        (!jewishCalendar.getInIsrael() &&
                                !_tachanunRecited13SivanOutOfIsrael
                            ? 14
                            : 13)))) &&
        !jewishCalendar.isErevYomTov() &&
        (!jewishCalendar.isYomTov() ||
            (jewishCalendar.isTaanis() &&
                (_tachanunRecitedPesachSheni ||
                    holidayIndex != JewishCalendar.PESACH_SHENI))) &&
        (jewishCalendar.getInIsrael() ||
            _tachanunRecitedPesachSheni ||
            _tachanunRecited15IyarOutOfIsrael ||
            month != JewishDate.IYAR ||
            day != 15) &&
        holidayIndex != JewishCalendar.TISHA_BEAV &&
        !jewishCalendar.isIsruChag() &&
        !jewishCalendar.isRoshChodesh() &&
        (_tachanunRecitedShivasYemeiHamiluim || !lastAdar || day <= 22) &&
        (_tachanunRecitedWeekOfPurim || !lastAdar || day <= 10 || day >= 18) &&
        (!jewishCalendar.isUseModernHolidays() ||
            (holidayIndex != JewishCalendar.YOM_HAATZMAUT &&
                holidayIndex != JewishCalendar.YOM_YERUSHALAYIM)) &&
        (_tachanunRecitedWeekOfHod ||
            month != JewishDate.IYAR ||
            day <= 13 ||
            day >= 21);
  }

  /// Returns if _tachanun_ is recited during _mincha_ on the day in question.
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns if _tachanun_ is recited during _mincha_.
  /// See also [isTachanunRecitedShacharis].
  bool isTachanunRecitedMincha(JewishCalendar jewishCalendar) {
    final JewishCalendar tomorrow = jewishCalendar.clone();
    tomorrow.plusDays(1);

    return _tachanunRecitedMinchaAllYear &&
        jewishCalendar.getDayOfWeek() != _FRIDAY &&
        isTachanunRecitedShacharis(jewishCalendar) &&
        (isTachanunRecitedShacharis(tomorrow) ||
            tomorrow.getYomTovIndex() == JewishCalendar.EREV_ROSH_HASHANA ||
            tomorrow.getYomTovIndex() == JewishCalendar.EREV_YOM_KIPPUR ||
            tomorrow.getYomTovIndex() == JewishCalendar.PESACH_SHENI) &&
        (_tachanunRecitedMinchaErevLagBaomer ||
            tomorrow.getYomTovIndex() != JewishCalendar.LAG_BAOMER);
  }

  /// Returns if it is the Jewish day (starting the evening before) to start reciting _Vesein Tal Umatar Livracha_
  /// (_Sheailas Geshamim_). In Israel this is the 7th day of [JewishDate.CHESHVAN].
  /// Outside Israel recitation starts on the evening of December 4th (or 5th if it is the year before a civil leap year)
  /// in the 21st century and shifts a day forward every century not evenly divisible by 400. This method will return true
  /// if _vesein tal umatar_ on the current Jewish date that starts on the previous night, so Dec 5/6 will be
  /// returned by this method in the 21st century. _vesein tal umatar_ is not recited on _Shabbos_ and the
  /// start date will be delayed a day when the start day is on a _Shabbos_ (this can only occur out of Israel).
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  ///
  /// Returns true if it is the first Jewish day (starting the prior evening of reciting _Vesein Tal Umatar Livracha_
  /// (_Sheailas Geshamim_).
  ///
  /// See also [isVeseinTalUmatarStartingTonight].
  /// See also [isVeseinTalUmatarRecited].
  bool isVeseinTalUmatarStartDate(JewishCalendar jewishCalendar) {
    if (jewishCalendar.getInIsrael()) {
      return jewishCalendar.getJewishMonth() == JewishDate.CHESHVAN &&
          jewishCalendar.getJewishDayOfMonth() == 7;
    }
    if (jewishCalendar.getDayOfWeek() == _SATURDAY) {
      return false;
    }
    if (jewishCalendar.getDayOfWeek() == _SUNDAY) {
      return jewishCalendar.getTekufasTishreiElapsedDays() == 48 ||
          jewishCalendar.getTekufasTishreiElapsedDays() == 47;
    }
    return jewishCalendar.getTekufasTishreiElapsedDays() == 47;
  }

  /// Returns if true if tonight is the first night to start reciting _Vesein Tal Umatar Livracha_ (
  /// _Sheailas Geshamim_). In Israel this is the 7th day of [JewishDate.CHESHVAN] (so the 6th will return true). Outside Israel recitation starts on the evening
  /// of December 4th (or 5th if it is the year before a civil leap year) in the 21st century and shifts a
  /// day forward every century not evenly divisible by 400. _Vesein tal umatar_ is not recited on
  /// _Shabbos_ and the start date will be delayed a day when the start day is on a _Shabbos_
  /// (this can only occur out of Israel).
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  ///
  /// Returns true if it is the first Jewish day (starting the prior evening of reciting <em>Vesein Tal Umatar
  /// Livracha</em> (_Sheailas Geshamim_).
  ///
  /// See also [isVeseinTalUmatarStartDate].
  /// See also [isVeseinTalUmatarRecited].
  bool isVeseinTalUmatarStartingTonight(JewishCalendar jewishCalendar) {
    if (jewishCalendar.getInIsrael()) {
      return jewishCalendar.getJewishMonth() == JewishDate.CHESHVAN &&
          jewishCalendar.getJewishDayOfMonth() == 6;
    }
    if (jewishCalendar.getDayOfWeek() == _FRIDAY) {
      return false;
    }
    if (jewishCalendar.getDayOfWeek() == _SATURDAY) {
      return jewishCalendar.getTekufasTishreiElapsedDays() == 47 ||
          jewishCalendar.getTekufasTishreiElapsedDays() == 46;
    }
    return jewishCalendar.getTekufasTishreiElapsedDays() == 46;
  }

  /// Returns if _Vesein Tal Umatar Livracha_ (_Sheailas Geshamim_) is recited. This will return
  /// true for the entire season, even on _Shabbos_ when it is not recited.
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  ///
  /// Returns true if _Vesein Tal Umatar Livracha_ (_Sheailas Geshamim_) is recited.
  ///
  /// See also [isVeseinTalUmatarStartDate].
  /// See also [isVeseinTalUmatarStartingTonight].
  bool isVeseinTalUmatarRecited(JewishCalendar jewishCalendar) {
    final int month = jewishCalendar.getJewishMonth();
    final int day = jewishCalendar.getJewishDayOfMonth();

    if (month == JewishDate.NISSAN && day >= 15) {
      return false;
    }
    if (month > JewishDate.NISSAN && month < JewishDate.CHESHVAN) {
      return false;
    }
    if (jewishCalendar.getInIsrael()) {
      return month != JewishDate.CHESHVAN || day >= 7;
    }
    return jewishCalendar.getTekufasTishreiElapsedDays() >= 47;
  }

  /// Returns if _Vesein Beracha_ is recited. It is recited from 15 [JewishDate.NISSAN] to the
  /// point that [isVeseinTalUmatarRecited].
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns true if _Vesein Beracha_ is recited.
  /// See also [isVeseinTalUmatarRecited].
  bool isVeseinBerachaRecited(JewishCalendar jewishCalendar) {
    return !isVeseinTalUmatarRecited(jewishCalendar);
  }

  /// Returns if the date is the start date for reciting _Mashiv Haruach Umorid Hageshem_. The date is 22
  /// [JewishDate.TISHREI].
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns true if the date is the start date for reciting _Mashiv Haruach Umorid Hageshem_.
  /// See also [isMashivHaruachEndDate].
  /// See also [isMashivHaruachRecited].
  bool isMashivHaruachStartDate(JewishCalendar jewishCalendar) {
    return jewishCalendar.getJewishMonth() == JewishDate.TISHREI &&
        jewishCalendar.getJewishDayOfMonth() == 22;
  }

  /// Returns if the date is the end date for reciting _Mashiv Haruach Umorid Hageshem_. The date is 15
  /// [JewishDate.NISSAN].
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns true if the date is the end date for reciting _Mashiv Haruach Umorid Hageshem_.
  /// See also [isMashivHaruachStartDate].
  /// See also [isMashivHaruachRecited].
  bool isMashivHaruachEndDate(JewishCalendar jewishCalendar) {
    return jewishCalendar.getJewishMonth() == JewishDate.NISSAN &&
        jewishCalendar.getJewishDayOfMonth() == 15;
  }

  /// Returns if _Mashiv Haruach Umorid Hageshem_ is recited. This period starts on 22
  /// [JewishDate.TISHREI] and ends on the 15th day of [JewishDate.NISSAN].
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns true if _Mashiv Haruach Umorid Hageshem_ is recited.
  /// See also [isMashivHaruachStartDate].
  /// See also [isMashivHaruachEndDate].
  bool isMashivHaruachRecited(JewishCalendar jewishCalendar) {
    final JewishDate startDate = JewishDate.fromJewishDate(
        jewishCalendar.getJewishYear(), JewishDate.TISHREI, 22);
    final JewishDate endDate = JewishDate.fromJewishDate(
        jewishCalendar.getJewishYear(), JewishDate.NISSAN, 15);
    return jewishCalendar.compareTo(startDate) > 0 &&
        jewishCalendar.compareTo(endDate) < 0;
  }

  /// Returns if _Morid Hatal_ (or the lack of reciting _Mashiv Haruach_ following _nussach Ashkenaz_) is
  /// recited. This period starts on the 15th day of [JewishDate.NISSAN] and ends on 22
  /// [JewishDate.TISHREI].
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  ///
  /// Returns true if _Morid Hatal_ (or the lack of reciting _Mashiv Haruach_ following _nussach Ashkenaz_) is recited.
  bool isMoridHatalRecited(JewishCalendar jewishCalendar) {
    return !isMashivHaruachRecited(jewishCalendar) ||
        isMashivHaruachStartDate(jewishCalendar) ||
        isMashivHaruachEndDate(jewishCalendar);
  }

  /// Returns if _hallel_ is recited on the day in question. This will return true for both _hallel shalem_
  /// and _chatzi hallel_. See [isHallelShalemRecited] to know if the complete _hallel_
  /// is recited.
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns if _hallel_ is recited.
  /// See also [isHallelShalemRecited].
  bool isHallelRecited(JewishCalendar jewishCalendar) {
    final int day = jewishCalendar.getJewishDayOfMonth();
    final int month = jewishCalendar.getJewishMonth();
    final int holidayIndex = jewishCalendar.getYomTovIndex();
    final bool inIsrael = jewishCalendar.getInIsrael();

    if (jewishCalendar.isRoshChodesh()) {
      return true;
    }
    if (jewishCalendar.isChanukah()) {
      return true;
    }
    switch (month) {
      case JewishDate.NISSAN:
        if (day >= 15 &&
            ((inIsrael && day <= 21) || (!inIsrael && day <= 22))) {
          return true;
        }
        break;
      case JewishDate.IYAR:
        if (jewishCalendar.isUseModernHolidays() &&
            (holidayIndex == JewishCalendar.YOM_HAATZMAUT ||
                holidayIndex == JewishCalendar.YOM_YERUSHALAYIM)) {
          return true;
        }
        break;
      case JewishDate.SIVAN:
        if (day == 6 || (!inIsrael && (day == 7))) {
          return true;
        }
        break;
      case JewishDate.TISHREI:
        if (day >= 15 && (day <= 22 || (!inIsrael && (day <= 23)))) {
          return true;
        }
    }
    return false;
  }

  /// Returns if _hallel shalem_ is recited on the day in question. This will always return false if
  /// [isHallelRecited] returns false.
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns if _hallel shalem_ is recited.
  /// See also [isHallelRecited].
  bool isHallelShalemRecited(JewishCalendar jewishCalendar) {
    final int day = jewishCalendar.getJewishDayOfMonth();
    final int month = jewishCalendar.getJewishMonth();
    final bool inIsrael = jewishCalendar.getInIsrael();
    if (isHallelRecited(jewishCalendar)) {
      return (!jewishCalendar.isRoshChodesh() || jewishCalendar.isChanukah()) &&
          (month != JewishDate.NISSAN ||
              ((!inIsrael || day <= 15) && (inIsrael || day <= 16)));
    }
    return false;
  }

  /// Returns if _al hanissim_ is recited on the day in question.
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns if _al hanissim_ is recited.
  /// See also [JewishCalendar.isPurim].
  /// See also [JewishCalendar.isChanukah].
  bool isAlHanissimRecited(JewishCalendar jewishCalendar) {
    return jewishCalendar.isPurim() || jewishCalendar.isChanukah();
  }

  /// Returns if _ya'aleh v'yavo_ is recited on the day in question.
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns if _ya'aleh v'yavo_ is recited.
  bool isYaalehVeyavoRecited(JewishCalendar jewishCalendar) {
    return jewishCalendar.isPesach() ||
        jewishCalendar.isShavuos() ||
        jewishCalendar.isRoshHashana() ||
        jewishCalendar.isYomKippur() ||
        jewishCalendar.isSuccos() ||
        jewishCalendar.isShminiAtzeres() ||
        jewishCalendar.isSimchasTorah() ||
        jewishCalendar.isRoshChodesh();
  }

  /// Returns if _mizmor lesoda_ is recited on the day in question. It is not recited on a
  /// day with a prohibition of work, and by default not on _erev Yom Kippur_, _erev
  /// Pesach_ or _chol hamoed Pesach_ either.
  ///
  /// - [jewishCalendar]: the Jewish calendar day.
  /// Returns if _mizmor lesoda_ is recited.
  /// See also [isMizmorLesodaRecitedErevYomKippurAndPesach].
  bool isMizmorLesodaRecited(JewishCalendar jewishCalendar) {
    if (jewishCalendar.isAssurBemelacha()) {
      return false;
    }

    final int holidayIndex = jewishCalendar.getYomTovIndex();
    return isMizmorLesodaRecitedErevYomKippurAndPesach() ||
        (holidayIndex != JewishCalendar.EREV_YOM_KIPPUR &&
            holidayIndex != JewishCalendar.EREV_PESACH &&
            !jewishCalendar.isCholHamoedPesach());
  }

  /// Is _tachanun_ set to be recited during the week of Purim, from the 11th through the 17th of
  /// [JewishDate.ADAR] (on a non-leap year, or [JewishDate.ADAR_II] on a leap year). Some
  /// _chasidishe_ communities do not recite _tachanun_ during this period.
  /// See also [setTachanunRecitedWeekOfPurim].
  bool isTachanunRecitedWeekOfPurim() {
    return _tachanunRecitedWeekOfPurim;
  }

  void setTachanunRecitedWeekOfPurim(bool tachanunRecitedWeekOfPurim) {
    _tachanunRecitedWeekOfPurim = tachanunRecitedWeekOfPurim;
  }

  /// Is _tachanun_ set to be recited during the _sefira_ week of _Hod_ (14 - 20 [JewishDate.IYAR],
  /// or the 29th - 35th of the [JewishCalendar.getDayOfOmer]). Some _chasidishe_ communities
  /// do not recite _tachanun_ during this week. See Minhag Yisrael Torah 131:Iyar.
  /// See also [setTachanunRecitedWeekOfHod].
  bool isTachanunRecitedWeekOfHod() {
    return _tachanunRecitedWeekOfHod;
  }

  void setTachanunRecitedWeekOfHod(bool tachanunRecitedWeekOfHod) {
    _tachanunRecitedWeekOfHod = tachanunRecitedWeekOfHod;
  }

  /// Is _tachanun_ set to be recited at the end of [JewishDate.TISHREI]. The Magen Avraham 669:1 and the
  /// Pri Chadash 131:7 state that some places to not recite _tachanun_ during this period. The Sh"UT Chasam
  /// Sofer on Choshen Mishpat 77 writes that this is the _minhag_ in Ashkenaz. The Shaarei Teshuva 131:19 quotes
  /// the Sheyarie Kneses Hagdola who also states that it should not be recited. The Aderes wanted to institute
  /// saying _tachanun_ during this period, but was dissuaded from this by Rav Shmuel Salant who did not want to
  /// change the _minhag_ in Yerushalayim. The Aruch Hashulchan is of the opinion that this _minhag_ is
  /// incorrect, and it should be recited, and The Chazon Ish also recited _tachanun_ during this period. See the
  /// Dirshu edition of the Mishna Berurah for details.
  /// See also [setTachanunRecitedEndOfTishrei].
  bool isTachanunRecitedEndOfTishrei() {
    return _tachanunRecitedEndOfTishrei;
  }

  void setTachanunRecitedEndOfTishrei(bool tachanunRecitedEndOfTishrei) {
    _tachanunRecitedEndOfTishrei = tachanunRecitedEndOfTishrei;
  }

  /// Is _tachanun_ set to be recited during the week after _Shavuos_. This is the opinion of the Pri Megadim
  /// quoted by the Mishna Berurah. This is since _karbanos_ of _Shavuos_ have _tashlumim_ for
  /// 7 days, it is still considered like a Yom Tov. The Chazon Ish quoted in the Orchos Rabainu vol. 1 page 68
  /// recited _tachanun_ during this week.
  /// See also [setTachanunRecitedWeekAfterShavuos].
  bool isTachanunRecitedWeekAfterShavuos() {
    return _tachanunRecitedWeekAfterShavuos;
  }

  void setTachanunRecitedWeekAfterShavuos(bool tachanunRecitedWeekAfterShavuos) {
    _tachanunRecitedWeekAfterShavuos = tachanunRecitedWeekAfterShavuos;
  }

  /// Is _tachanun_ set to be recited on the 13th of [JewishDate.SIVAN] ([_Yom Tov Sheni shel Galuyos_](https://en.wikipedia.org/wiki/Yom_tov_sheni_shel_galuyot) of the 7th
  /// day) outside Israel. This is brought down by the Shaarie Teshuva 131:19 quoting the [Sheyarei Kneses Hagedola 131:12](https://hebrewbooks.org/pdfpager.aspx?req=41295&st=&pgnum=39) that
  /// _tachanun_ should not be recited on this day. Rav Shlomo Zalman Orbach in Halichos Shlomo on
  /// Shavuos 12:16:25 is of the opinion that even in _chutz laaretz_ it should be recited since the _yemei
  /// Tashlumin_ are counted based on Israel since that is where the _karbanos_ are brought. Both
  /// [isTachanunRecitedShacharis] and [isTachanunRecitedMincha] only return false if the location is not set to
  /// [JewishCalendar.getInIsrael] and both [isTachanunRecitedWeekAfterShavuos] and this are set to false.
  /// See also [setTachanunRecited13SivanOutOfIsrael].
  bool isTachanunRecited13SivanOutOfIsrael() {
    return _tachanunRecited13SivanOutOfIsrael;
  }

  void setTachanunRecited13SivanOutOfIsrael(
      bool tachanunRecitedThirteenSivanOutOfIsrael) {
    _tachanunRecited13SivanOutOfIsrael = tachanunRecitedThirteenSivanOutOfIsrael;
  }

  /// Is _tachanun_ set to be recited on [JewishCalendar.PESACH_SHENI]. The Pri Chadash 131:7 states
  /// that _tachanun_ should not be recited. The Aruch Hashulchan states that this is the minhag of the _sephardim_.
  /// the Shaarei Efraim 10:27 also mentions that it is not recited, as does the Siddur Yaavetz (Shaar Hayesod, Chodesh Iyar).
  /// The Pri Megadim (Mishbetzes Hazahav 131:15) and the Chazon Ish (Erev Pesach Shechal Beshabbos, page 203 in [Rav Sheraya Devlitzky's](https://he.wikipedia.org/wiki/%D7%A9%D7%A8%D7%99%D7%94_%D7%93%D7%91%D7%9C%D7%99%D7%A6%D7%A7%D7%99) comments).
  /// See also [setTachanunRecitedPesachSheni].
  bool isTachanunRecitedPesachSheni() {
    return _tachanunRecitedPesachSheni;
  }

  void setTachanunRecitedPesachSheni(bool tachanunRecitedPesachSheni) {
    _tachanunRecitedPesachSheni = tachanunRecitedPesachSheni;
  }

  /// Is _tachanun_ set to be recited on 15 [JewishDate.IYAR] (_sfaika deyoma_ of [JewishCalendar.PESACH_SHENI])
  /// out of Israel. If [isTachanunRecitedPesachSheni] is `true` this will be ignored even if `false`.
  /// See also [setTachanunRecited15IyarOutOfIsrael].
  /// See also [setTachanunRecitedPesachSheni].
  bool isTachanunRecited15IyarOutOfIsrael() {
    return _tachanunRecited15IyarOutOfIsrael;
  }

  void setTachanunRecited15IyarOutOfIsrael(
      bool tachanunRecited15IyarOutOfIsrael) {
    _tachanunRecited15IyarOutOfIsrael = tachanunRecited15IyarOutOfIsrael;
  }

  /// Is _tachanun_ set to be recited on _mincha_ on _erev [JewishCalendar.LAG_BAOMER]_.
  /// See also [setTachanunRecitedMinchaErevLagBaomer].
  bool isTachanunRecitedMinchaErevLagBaomer() {
    return _tachanunRecitedMinchaErevLagBaomer;
  }

  void setTachanunRecitedMinchaErevLagBaomer(
      bool tachanunRecitedMinchaErevLagBaomer) {
    _tachanunRecitedMinchaErevLagBaomer = tachanunRecitedMinchaErevLagBaomer;
  }

  /// Is _tachanun_ set to be recited during the _Shivas Yemei Hamiluim_, from the 23 of [JewishDate.ADAR]
  /// on a non-leap-year or [JewishDate.ADAR_II] on a leap year to the end of the month. Some _chasidishe_
  /// communities do not say _tachanun_ during this week. See [Darkei Chaim Veshalom 191](https://hebrewbooks.org/pdfpager.aspx?req=4692&st=&pgnum=70).
  /// See also [setTachanunRecitedShivasYemeiHamiluim].
  bool isTachanunRecitedShivasYemeiHamiluim() {
    return _tachanunRecitedShivasYemeiHamiluim;
  }

  void setTachanunRecitedShivasYemeiHamiluim(
      bool tachanunRecitedShivasYemeiHamiluim) {
    _tachanunRecitedShivasYemeiHamiluim = tachanunRecitedShivasYemeiHamiluim;
  }

  /// Is _tachanun_ set to be recited on Fridays. Some _chasidishe_ communities do not recite
  /// _tachanun_ on Fridays. See [Likutei Maharich Vol 2 Seder Hanhagos Erev Shabbos](https://hebrewbooks.org/pdfpager.aspx?req=41190&st=&pgnum=10). This is also the _minhag_ in Satmar.
  /// See also [setTachanunRecitedFridays].
  bool isTachanunRecitedFridays() {
    return _tachanunRecitedFridays;
  }

  void setTachanunRecitedFridays(bool tachanunRecitedFridays) {
    _tachanunRecitedFridays = tachanunRecitedFridays;
  }

  /// Is _tachanun_ set to be recited on Sundays. Some _chasidishe_ communities do not recite
  /// _tachanun_ on Sundays. See [Likutei Maharich Vol 2 Seder Hanhagos Erev Shabbos](https://hebrewbooks.org/pdfpager.aspx?req=41190&st=&pgnum=10).
  /// See also [setTachanunRecitedSundays].
  bool isTachanunRecitedSundays() {
    return _tachanunRecitedSundays;
  }

  void setTachanunRecitedSundays(bool tachanunRecitedSundays) {
    _tachanunRecitedSundays = tachanunRecitedSundays;
  }

  /// Is _tachanun_ set to be recited in _Mincha_ the entire year. Some _chasidishe_ communities do not recite
  /// _tachanun_ by _Mincha_ all year round. See [Nemukei Orach Chaim 131:3](https://hebrewbooks.org/pdfpager.aspx?req=4751&st=&pgnum=105).
  /// See also [setTachanunRecitedMinchaAllYear].
  bool isTachanunRecitedMinchaAllYear() {
    return _tachanunRecitedMinchaAllYear;
  }

  void setTachanunRecitedMinchaAllYear(bool tachanunRecitedMinchaAllYear) {
    _tachanunRecitedMinchaAllYear = tachanunRecitedMinchaAllYear;
  }

  void setMizmorLesodaRecitedErevYomKippurAndPesach(
      bool mizmorLesodaRecitedErevYomKippurAndPesach) {
    _mizmorLesodaRecitedErevYomKippurAndPesach =
        mizmorLesodaRecitedErevYomKippurAndPesach;
  }

  /// Is _Mizmor Lesoda_ set to be recited on _Erev Yom Kippur_, _Erev Pesach_ and _Chol Hamoed Pesach_.
  /// Ashkenazi congregations do not recite it on these days, while Sephardi congregations do. The default value is
  /// `false`.
  /// See also [isMizmorLesodaRecited].
  bool isMizmorLesodaRecitedErevYomKippurAndPesach() {
    return _mizmorLesodaRecitedErevYomKippurAndPesach;
  }

  bool isSelichosRecitedAllElul() {
    return _selichosRecitedAllElul;
  }

  void setSelichosRecitedAllElul(bool selichosRecitedAllElul) {
    _selichosRecitedAllElul = selichosRecitedAllElul;
  }

  bool isSuccosKorbanRecited(JewishCalendar jewishCalendar, int dayOfSuccos) {
    if (dayOfSuccos < 2 || dayOfSuccos > 7) {
      throw ArgumentError.value(dayOfSuccos, 'dayOfSuccos',
          'chol hamoed Succos reads the korbanos of days 2 through 7');
    }

    if (!jewishCalendar.isCholHamoedSuccos()) {
      return false;
    }

    const int daysOfTishreiBeforeSuccos = 14;
    final int today = jewishCalendar.getJewishDayOfMonth();
    if (jewishCalendar.getInIsrael()) {
      return today == dayOfSuccos + daysOfTishreiBeforeSuccos;
    }
    return today == dayOfSuccos + daysOfTishreiBeforeSuccos ||
        today == dayOfSuccos + daysOfTishreiBeforeSuccos + 1;
  }

  bool isAtaChonantanuRecited(JewishCalendar jewishCalendar) {
    return jewishCalendar.isMotzeiShabbos() || jewishCalendar.isMotzeiYomTov();
  }

  bool isHavdalahRecited(JewishCalendar jewishCalendar) {
    if (jewishCalendar.isAssurBemelacha() || jewishCalendar.isTishaBav()) {
      return false;
    }

    if (jewishCalendar.isMotzeiShabbos() || jewishCalendar.isMotzeiYomTov()) {
      return true;
    }

    final JewishCalendar yesterday = jewishCalendar.clone()..minusDays(1);

    return yesterday.isTishaBav() && yesterday.isMotzeiShabbos();
  }

  bool isHavdalahBesamimRecited(JewishCalendar jewishCalendar) {
    return jewishCalendar.isMotzeiShabbos() &&
        !jewishCalendar.isTishaBav() &&
        !jewishCalendar.isAssurBemelacha();
  }

  bool isHavdalahNerRecited(JewishCalendar jewishCalendar) {
    if (jewishCalendar.isAssurBemelacha()) {
      return false;
    }

    final JewishCalendar yesterday = jewishCalendar.clone()..minusDays(1);

    return jewishCalendar.isMotzeiShabbos() || yesterday.isYomKippur();
  }

  bool isKiddushLevanaRecited(JewishCalendar jewishCalendar) {
    final int month = jewishCalendar.getJewishMonth();
    final int day = jewishCalendar.getJewishDayOfMonth();

    final bool beforeTishaBav =
        month == JewishDate.AV && (day <= 9 || jewishCalendar.isTishaBav());
    final bool beforeYomKippur = month == JewishDate.TISHREI && day <= 10;

    if (beforeTishaBav || beforeYomKippur) {
      return false;
    }

    final DateTime date = jewishCalendar.getLocalDate();
    final DateTime noonBeforeTonight =
        DateTime(date.year, date.month, date.day - 1, 12);
    final DateTime noonAfterTonight =
        DateTime(date.year, date.month, date.day, 12);

    return jewishCalendar
            .getTchilasZmanKidushLevana7Days()
            .isBefore(noonAfterTonight) &&
        jewishCalendar
            .getSofZmanKidushLevana15Days()
            .isAfter(noonBeforeTonight);
  }

  bool isTashlichRecited(JewishCalendar jewishCalendar) {
    return jewishCalendar.getJewishMonth() == JewishDate.TISHREI &&
        jewishCalendar.getJewishDayOfMonth() <= 21;
  }

  bool isAvinuMalkeinuRecited(JewishCalendar jewishCalendar) {
    if (jewishCalendar.isShabbos()) {
      return false;
    }
    return jewishCalendar.isAseresYemeiTeshuva() ||
        (jewishCalendar.isTaanis() && !jewishCalendar.isTishaBav());
  }

  bool isLongTachanunRecited(JewishCalendar jewishCalendar) {
    return jewishCalendar.isMondayOrThursday() &&
        isTachanunRecitedShacharis(jewishCalendar);
  }

  bool isMussafRecited(JewishCalendar jewishCalendar) {
    return jewishCalendar.isShabbos() ||
        jewishCalendar.isRoshChodesh() ||
        jewishCalendar.isYomTovAssurBemelacha() ||
        jewishCalendar.isCholHamoed();
  }

  bool isVihiNoamRecited(JewishCalendar jewishCalendar) {
    if (!jewishCalendar.isMotzeiShabbos() || jewishCalendar.isTishaBav()) {
      return false;
    }

    final JewishCalendar week = jewishCalendar.clone();

    for (int day = 0; day < 6; day++) {
      if (week.isYomTovAssurBemelacha()) {
        return false;
      }
      week.plusDays(1);
    }

    return true;
  }

  bool isSelichosRecited(JewishCalendar jewishCalendar) {
    final bool inElul = _selichosRecitedAllElul
        ? jewishCalendar.getJewishMonth() == JewishDate.ELUL &&
            !jewishCalendar.isShabbos()
        : jewishCalendar.getDayOfSelichos() != -1 ||
            jewishCalendar.isErevRoshHashana();

    return inElul ||
        jewishCalendar.getDayOfSelichosOfTeshuva() != -1 ||
        jewishCalendar.isErevYomKippur();
  }

  bool isSelichosDayRecited(JewishCalendar jewishCalendar, int dayOfSelichos) {
    if (dayOfSelichos < 1 || dayOfSelichos > 7) {
      throw ArgumentError.value(dayOfSelichos, 'dayOfSelichos',
          'the Elul selichos run to at most seven numbered days');
    }

    return jewishCalendar.getDayOfSelichos() == dayOfSelichos;
  }

  bool isSelichosDayOfTeshuvaRecited(
      JewishCalendar jewishCalendar, int dayOfSelichos) {
    if (dayOfSelichos < 1 || dayOfSelichos > 5) {
      throw ArgumentError.value(dayOfSelichos, 'dayOfSelichos',
          'the Aseres Yemei Teshuva hold five days of selichos');
    }

    return jewishCalendar.getDayOfSelichosOfTeshuva() == dayOfSelichos;
  }

  static const int _SUNDAY = 1;
  static const int _FRIDAY = 6;
  static const int _SATURDAY = 7;
}
