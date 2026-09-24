/*
 * Zmanim Java API
 * Copyright (C) 2011 - 2020 Eliyahu Hershfeld
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

import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';

/// The HebrewDateFormatter class formats a [JewishDate].
///
/// The class formats Jewish dates, numbers, Daf Yomi (Bavli and Yerushalmi), the Omer, Parshas Hashavua (including special parshiyos
/// such as Shekalim, Zachor, Parah, Hachodesh), Yomim Tovim and the Molad (experimental) in Hebrew or Latin chars, and has various
/// settings. Sample full date output includes
/// (using various options):
/// 
/// - 21 Shevat, 5729
/// - כא שבט תשכט
/// - כ״א שבט ה׳ תשכ״ט
/// - כ״א שבט תש״פ or כ״א שבט תש״ף
/// - כ׳ שבט ו׳ אלפים
/// 
/// © Eliyahu Hershfeld 2011 - 2020
class HebrewDateFormatter {
  ///Sets the formatter to format in Hebrew in the various formatting methods.
  bool _hebrewFormat = false;

  /// When formatting a Hebrew Year, traditionally the thousands digit is omitted and output for a year such as 5729
  /// (1969 Gregorian) would be calculated for 729 and format as תשכ״ט. This method
  /// allows setting this to true to return the long format year such as ה׳ תשכ״ט for 5729/1969.
  bool _useLongHebrewYears = false;

  /// Sets whether to use the Geresh ׳ and Gershayim ״ in formatting Hebrew dates and numbers. The default
  /// value is true and output would look like כ״א שבט תש״כ
  /// (or כ״א שבט תש״ך). When set to false, this output would display as כא שבט תשכ (or כא שבט תשך).
  /// Single digit days or month or years such as כ׳ שבט ו׳ אלפים show the use of the Geresh.
  bool _useGershGershayim = true;

  /// Setting to control if the [formatDayOfWeek] will use the long format such as ראשון
  /// or short such as א when formatting the day of week in Hebrew.
  bool _longWeekFormat = true;

  /// Returns whether the class is set to use the מנצפ״ך letters when
  /// formatting years ending in 20, 40, 50, 80 and 90 to produce תש״פ if false or
  /// or תש״ף if true. Traditionally non-final form letters are used, so the year
  /// 5780 would be formatted as תש״פ if the default false is used here. If this returns
  /// true, the format תש״ף would be used.
  bool _useFinalFormLetters = false;

  /// The [gersh](https://en.wikipedia.org/wiki/Geresh#Punctuation_mark) character is the ׳; char
  /// that is similar to a single quote and is used in formatting Hebrew numbers.
  static const String _GERESH = "׳";

  /// The [gersh](https://en.wikipedia.org/wiki/Geresh#Punctuation_mark) character is the "; char
  /// that is similar to a single quote and is used in formatting Hebrew numbers.
  static const String _GERSHAYIM = "״";

  /// Hebrew Omer prefix. By default it is the letter ב, but can be set to ל (or any other prefix).
  String _hebrewOmerPrefix = "ב";

  ///day of Shabbos transliterated into Latin chars. The default uses Ashkenazi pronunciation "Shabbos".
  String _transliteratedShabbosDayOfWeek = "Shabbos";

  static const List<String> _hebrewDaysOfWeek = [
    "ראשון",
    "שני",
    "שלישי",
    "רביעי",
    "חמישי",
    "ששי",
    "שבת"
  ];

  /// List of months transliterated into Latin chars. The default list of months uses Ashkenazi
  /// pronunciation in typical American English spelling. This list has a length of 14 with 3 variations for Adar -
  /// "Adar", "Adar II", "Adar I"
  List<String> _transliteratedMonths = [
    "Nissan",
    "Iyar",
    "Sivan",
    "Tammuz",
    "Av",
    "Elul",
    "Tishrei",
    "Marcheshvan",
    "Kislev",
    "Teves",
    "Shevat",
    "Adar",
    "Adar II",
    "Adar I"
  ];

  List<String> _hebrewMonths = [
    "ניסן",
    "אייר",
    "סיון",
    "תמוז",
    "אב",
    "אלול",
    "תשרי",
    "מרחשון",
    "כסלו",
    "טבת",
    "שבט",
    "אדר",
    "אדר ב",
    "אדר א"
  ];

  /// List of transliterated parshiyos using the default Ashkenazi pronounciation.  The formatParshah method uses this
  /// for transliterated parsha formatting.  This list can be overridden (for Sephardi English transliteration for
  /// example) by setting the [setTransliteratedParshiyosList]. The list includes double and special
  /// parshiyos is set as "Bereshis, Noach, Lech Lecha, Vayera, Chayei Sara, Toldos, Vayetzei, Vayishlach, Vayeshev, Miketz,
  /// Vayigash, Vayechi, Shemos, Vaera, Bo, Beshalach, Yisro, Mishpatim, Terumah, Tetzaveh, Ki Sisa, Vayakhel, Pekudei,
  /// Vayikra, Tzav, Shmini, Tazria, Metzora, Achrei Mos, Kedoshim, Emor, Behar, Bechukosai, Bamidbar, Nasso, Beha'aloscha,
  /// Sh'lach, Korach, Chukas, Balak, Pinchas, Matos, Masei, Devarim, Vaeschanan, Eikev, Re'eh, Shoftim, Ki Seitzei, Ki Savo,
  /// Nitzavim, Vayeilech, Ha'Azinu, Vezos Habracha, Vayakhel Pekudei, Tazria Metzora, Achrei Mos Kedoshim, Behar Bechukosai,
  /// Chukas Balak, Matos Masei, Nitzavim Vayeilech, Shekalim, Zachor, Parah, Hachodesh".
  ///
  /// See also [formatParshah].
  Map<Parshah, String> _transliteratedParshahMap = {
    Parshah.NONE: "",
    Parshah.BERESHIS: "Bereshis",
    Parshah.NOACH: "Noach",
    Parshah.LECH_LECHA: "Lech Lecha",
    Parshah.VAYERA: "Vayera",
    Parshah.CHAYEI_SARA: "Chayei Sara",
    Parshah.TOLDOS: "Toldos",
    Parshah.VAYETZEI: "Vayetzei",
    Parshah.VAYISHLACH: "Vayishlach",
    Parshah.VAYESHEV: "Vayeshev",
    Parshah.MIKETZ: "Miketz",
    Parshah.VAYIGASH: "Vayigash",
    Parshah.VAYECHI: "Vayechi",
    Parshah.SHEMOS: "Shemos",
    Parshah.VAERA: "Vaera",
    Parshah.BO: "Bo",
    Parshah.BESHALACH: "Beshalach",
    Parshah.YISRO: "Yisro",
    Parshah.MISHPATIM: "Mishpatim",
    Parshah.TERUMAH: "Terumah",
    Parshah.TETZAVEH: "Tetzaveh",
    Parshah.KI_SISA: "Ki Sisa",
    Parshah.VAYAKHEL: "Vayakhel",
    Parshah.PEKUDEI: "Pekudei",
    Parshah.VAYIKRA: "Vayikra",
    Parshah.TZAV: "Tzav",
    Parshah.SHMINI: "Shmini",
    Parshah.TAZRIA: "Tazria",
    Parshah.METZORA: "Metzora",
    Parshah.ACHREI_MOS: "Achrei Mos",
    Parshah.KEDOSHIM: "Kedoshim",
    Parshah.EMOR: "Emor",
    Parshah.BEHAR: "Behar",
    Parshah.BECHUKOSAI: "Bechukosai",
    Parshah.BAMIDBAR: "Bamidbar",
    Parshah.NASSO: "Nasso",
    Parshah.BEHAALOSCHA: "Beha'aloscha",
    Parshah.SHLACH: "Sh'lach",
    Parshah.KORACH: "Korach",
    Parshah.CHUKAS: "Chukas",
    Parshah.BALAK: "Balak",
    Parshah.PINCHAS: "Pinchas",
    Parshah.MATOS: "Matos",
    Parshah.MASEI: "Masei",
    Parshah.DEVARIM: "Devarim",
    Parshah.VAESCHANAN: "Vaeschanan",
    Parshah.EIKEV: "Eikev",
    Parshah.REEH: "Re'eh",
    Parshah.SHOFTIM: "Shoftim",
    Parshah.KI_SEITZEI: "Ki Seitzei",
    Parshah.KI_SAVO: "Ki Savo",
    Parshah.NITZAVIM: "Nitzavim",
    Parshah.VAYEILECH: "Vayeilech",
    Parshah.HAAZINU: "Ha'Azinu",
    Parshah.VZOS_HABERACHA: "Vezos Habracha",
    Parshah.VAYAKHEL_PEKUDEI: "Vayakhel Pekudei",
    Parshah.TAZRIA_METZORA: "Tazria Metzora",
    Parshah.ACHREI_MOS_KEDOSHIM: "Achrei Mos Kedoshim",
    Parshah.BEHAR_BECHUKOSAI: "Behar Bechukosai",
    Parshah.CHUKAS_BALAK: "Chukas Balak",
    Parshah.MATOS_MASEI: "Matos Masei",
    Parshah.NITZAVIM_VAYEILECH: "Nitzavim Vayeilech",
    Parshah.SHKALIM: "Shekalim",
    Parshah.ZACHOR: "Zachor",
    Parshah.PARA: "Parah",
    Parshah.HACHODESH: "Hachodesh",
    Parshah.SHUVA: "Shuva",
    Parshah.SHIRA: "Shira",
    Parshah.HAGADOL: "Hagadol",
    Parshah.CHAZON: "Chazon",
    Parshah.NACHAMU: "Nachamu",
  };

  /// list of Hebrew parshiyos.
  final Map<Parshah, String> _hebrewParshahMap = {
    Parshah.NONE: "",
    Parshah.BERESHIS: "בראשית",
    Parshah.NOACH: "נח",
    Parshah.LECH_LECHA: "לך לך",
    Parshah.VAYERA: "וירא",
    Parshah.CHAYEI_SARA: "חיי שרה",
    Parshah.TOLDOS: "תולדות",
    Parshah.VAYETZEI: "ויצא",
    Parshah.VAYISHLACH: "וישלח",
    Parshah.VAYESHEV: "וישב",
    Parshah.MIKETZ: "מקץ",
    Parshah.VAYIGASH: "ויגש",
    Parshah.VAYECHI: "ויחי",
    Parshah.SHEMOS: "שמות",
    Parshah.VAERA: "וארא",
    Parshah.BO: "בא",
    Parshah.BESHALACH: "בשלח",
    Parshah.YISRO: "יתרו",
    Parshah.MISHPATIM: "משפטים",
    Parshah.TERUMAH: "תרומה",
    Parshah.TETZAVEH: "תצוה",
    Parshah.KI_SISA: "כי תשא",
    Parshah.VAYAKHEL: "ויקהל",
    Parshah.PEKUDEI: "פקודי",
    Parshah.VAYIKRA: "ויקרא",
    Parshah.TZAV: "צו",
    Parshah.SHMINI: "שמיני",
    Parshah.TAZRIA: "תזריע",
    Parshah.METZORA: "מצרע",
    Parshah.ACHREI_MOS: "אחרי מות",
    Parshah.KEDOSHIM: "קדושים",
    Parshah.EMOR: "אמור",
    Parshah.BEHAR: "בהר",
    Parshah.BECHUKOSAI: "בחקתי",
    Parshah.BAMIDBAR: "במדבר",
    Parshah.NASSO: "נשא",
    Parshah.BEHAALOSCHA: "בהעלתך",
    Parshah.SHLACH: "שלח לך",
    Parshah.KORACH: "קרח",
    Parshah.CHUKAS: "חוקת",
    Parshah.BALAK: "בלק",
    Parshah.PINCHAS: "פינחס",
    Parshah.MATOS: "מטות",
    Parshah.MASEI: "מסעי",
    Parshah.DEVARIM: "דברים",
    Parshah.VAESCHANAN: "ואתחנן",
    Parshah.EIKEV: "עקב",
    Parshah.REEH: "ראה",
    Parshah.SHOFTIM: "שופטים",
    Parshah.KI_SEITZEI: "כי תצא",
    Parshah.KI_SAVO: "כי תבוא",
    Parshah.NITZAVIM: "נצבים",
    Parshah.VAYEILECH: "וילך",
    Parshah.HAAZINU: "האזינו",
    Parshah.VZOS_HABERACHA: "וזאת הברכה",
    Parshah.VAYAKHEL_PEKUDEI: "ויקהל פקודי",
    Parshah.TAZRIA_METZORA: "תזריע מצרע",
    Parshah.ACHREI_MOS_KEDOSHIM: "אחרי מות קדושים",
    Parshah.BEHAR_BECHUKOSAI: "בהר בחקתי",
    Parshah.CHUKAS_BALAK: "חוקת בלק",
    Parshah.MATOS_MASEI: "מטות מסעי",
    Parshah.NITZAVIM_VAYEILECH: "נצבים וילך",
    Parshah.SHKALIM: "שקלים",
    Parshah.ZACHOR: "זכור",
    Parshah.PARA: "פרה",
    Parshah.HACHODESH: "החדש",
    Parshah.SHUVA: "שובה",
    Parshah.SHIRA: "שירה",
    Parshah.HAGADOL: "הגדול",
    Parshah.CHAZON: "חזון",
    Parshah.NACHAMU: "נחמו",
  };

  /// List of holidays transliterated into Latin chars. This is used by the
  /// [formatYomTov] when formatting the Yom Tov String. The default list of months uses
  /// Ashkenazi pronunciation in typical American English spelling.
  List<String> _transliteratedHolidays = [
    "Erev Pesach",
    "Pesach",
    "Chol Hamoed Pesach",
    "Pesach Sheni",
    "Erev Shavuos",
    "Shavuos",
    "Seventeenth of Tammuz",
    "Tishah B'Av",
    "Tu B'Av",
    "Erev Rosh Hashana",
    "Rosh Hashana",
    "Fast of Gedalyah",
    "Erev Yom Kippur",
    "Yom Kippur",
    "Erev Succos",
    "Succos",
    "Chol Hamoed Succos",
    "Hoshana Rabbah",
    "Shemini Atzeres",
    "Simchas Torah",
    "Erev Chanukah",
    "Chanukah",
    "Tenth of Teves",
    "Tu B'Shvat",
    "Fast of Esther",
    "Purim",
    "Shushan Purim",
    "Purim Katan",
    "Rosh Chodesh",
    "Yom HaShoah",
    "Yom Hazikaron",
    "Yom Ha'atzmaut",
    "Yom Yerushalayim",
    "Lag B'Omer",
    "Shushan Purim Katan",
    "Isru Chag"
  ];

  /// Hebrew holiday list
  final List<String> _hebrewHolidays = [
    'ערב פסח',
    'פסח',
    'חול המועד פסח',
    'פסח שני',
    'ערב שבועות',
    'שבועות',
    'שבעה עשר בתמוז',
    'תשעה באב',
    'ט״ו באב',
    'ערב ראש השנה',
    'ראש השנה',
    'צום גדליה',
    'ערב יום כיפור',
    'יום כיפור',
    'ערב סוכות',
    'סוכות',
    'חול המועד סוכות',
    'הושענא רבה',
    'שמיני עצרת',
    'שמחת תורה',
    'ערב חנוכה',
    'חנוכה',
    'עשרה בטבת',
    'ט״ו בשבט',
    'תענית אסתר',
    'פורים',
    'שושן פורים',
    'פורים קטן',
    'ראש חודש',
    'יום השואה',
    'יום הזיכרון',
    'יום העצמאות',
    'יום ירושלים',
    'ל״ג בעומר',
    'שושן פורים קטן',
    'אסרו חג'
  ];

  /// Formats the Yom Tov (holiday) in Hebrew or transliterated Latin characters.
  ///
  /// - [jewishCalendar]: the JewishCalendar
  /// Returns the formatted holiday or an empty String if the day is not a holiday.
  /// See also [isHebrewFormat].
  String formatYomTov(JewishCalendar jewishCalendar) {
    int index = jewishCalendar.getYomTovIndex();
    if (index == JewishCalendar.CHANUKAH) {
      int dayOfChanukah = jewishCalendar.getDayOfChanukah();
      return _hebrewFormat
          ? ("${formatHebrewNumber(dayOfChanukah)} ${_hebrewHolidays[index]}")
          : ("${_transliteratedHolidays[index]} $dayOfChanukah");
    }
    return index == -1
        ? ""
        : _hebrewFormat
            ? _hebrewHolidays[index]
            : _transliteratedHolidays[index];
  }

  /// Formats a day as Rosh Chodesh in the format of in the format of ראש חודש שבט
  /// or Rosh Chodesh Shevat. If it is not Rosh Chodesh, an empty `String` will be returned.
  /// - [jewishCalendar]: the JewishCalendar
  /// Returns The formatted `String` in the format of ראש חודש שבט
  /// or Rosh Chodesh Shevat. If it is not Rosh Chodesh, an empty `String` will be returned.
  String formatRoshChodesh(JewishCalendar jewishCalendar) {
    if (!jewishCalendar.isRoshChodesh()) {
      return "";
    }
    String formattedRoshChodesh = "";
    int month = jewishCalendar.getJewishMonth();
    if (jewishCalendar.getJewishDayOfMonth() == 30) {
      if (month < JewishDate.ADAR ||
          (month == JewishDate.ADAR && jewishCalendar.isJewishLeapYear())) {
        month++;
      } else {
        // roll to Nissan
        month = JewishDate.NISSAN;
      }
    }

    // This method is only about formatting, so we shouldn't make any changes to the params passed in...
    jewishCalendar = jewishCalendar.clone();
    jewishCalendar.setJewishMonth(month);
    formattedRoshChodesh = _hebrewFormat
        ? _hebrewHolidays[JewishCalendar.ROSH_CHODESH]
        : _transliteratedHolidays[JewishCalendar.ROSH_CHODESH];
    formattedRoshChodesh += " ${formatMonth(jewishCalendar)}";
    return formattedRoshChodesh;
  }

  /// Formats the day of week. If [isHebrewFormat] is set, it will display in the format ראשון etc.
  /// If Hebrew formatting is not in use it will return it in the format
  /// of Sunday etc. There are various formatting options that will affect the output.
  ///
  /// - [jewishDate]: the JewishDate Object
  /// Returns the formatted day of week
  /// See also [isHebrewFormat].
  /// See also [isLongWeekFormat].
  String formatDayOfWeek(JewishDate jewishDate) {
    if (_hebrewFormat) {
      if (_longWeekFormat) {
        return _hebrewDaysOfWeek[jewishDate.getDayOfWeek() - 1];
      } else {
        if (jewishDate.getDayOfWeek() == 7) {
          return formatHebrewNumber(300);
        } else {
          return formatHebrewNumber(jewishDate.getDayOfWeek());
        }
      }
    } else {
      if (jewishDate.getDayOfWeek() == 7) {
        if (_longWeekFormat) {
          return _transliteratedShabbosDayOfWeek;
        } else {
          return _transliteratedShabbosDayOfWeek.substring(0, 3);
        }
      } else {
        return DateFormat(_longWeekFormat ? "EEEE" : "EEE")
            .format(jewishDate.getLocalDate());
      }
    }
  }

  /// Formats the Jewish date. If the formatter is set to Hebrew, it will format in the form "day Month year" with
  /// Hebrew numbers, and in the form "21 Shevat, 5729" if not.
  ///
  /// - [jewishDate]:
  ///   the JewishDate to be formatted
  /// Returns the formatted date.
  String format(JewishDate jewishDate) {
    if (isHebrewFormat()) {
      return "${formatHebrewNumber(jewishDate.getJewishDayOfMonth())} ${formatMonth(jewishDate)} ${formatHebrewNumber(jewishDate.getJewishYear())}";
    } else {
      return "${jewishDate.getJewishDayOfMonth()} ${formatMonth(jewishDate)}, ${jewishDate.getJewishYear()}";
    }
  }

  /// Returns a string of the current Hebrew month such as "Tishrei".
  /// Returns a string of the current Hebrew month such as "אדר ב׳".
  ///
  /// - [jewishDate]: 
  ///   the JewishDate to format
  /// Returns the formatted month name
  /// See also [isHebrewFormat].
  /// See also [setHebrewFormat].
  /// See also [getTransliteratedMonthList].
  /// See also [setTransliteratedMonthList].
  String formatMonth(JewishDate jewishDate) {
    final int month = jewishDate.getJewishMonth();
    if (_hebrewFormat) {
      if (jewishDate.isJewishLeapYear() && month == JewishDate.ADAR) {
        return _hebrewMonths[13] +
            (_useGershGershayim
                ? _GERESH
                : ""); // return Adar I, not Adar in a leap year
      } else if (jewishDate.isJewishLeapYear() && month == JewishDate.ADAR_II) {
        return _hebrewMonths[12] + (_useGershGershayim ? _GERESH : "");
      } else {
        return _hebrewMonths[month - 1];
      }
    } else {
      if (jewishDate.isJewishLeapYear() && month == JewishDate.ADAR) {
        return _transliteratedMonths[
            13]; // return Adar I, not Adar in a leap year
      } else {
        return _transliteratedMonths[month - 1];
      }
    }
  }

  /// Returns a String of the Omer day in the form ל״ג בעומר if Hebrew Format is set,
  /// or "Omer X" or "Lag BaOmer" if not. An empty string if there is no Omer this day.
  ///
  /// - [jewishCalendar]: 
  ///   the JewishCalendar to be formatted
  ///
  /// Returns a String of the Omer day in the form or an empty string if there is no Omer this day. The default
  /// formatting has a ב׳ prefix that would output בעומר, but this
  /// can be set via [setHebrewOmerPrefix] to use a ל and output ל״ג לעומר.
  /// See also [isHebrewFormat].
  /// See also [getHebrewOmerPrefix].
  /// See also [setHebrewOmerPrefix].
  String formatOmer(JewishCalendar jewishCalendar) {
    int omer = jewishCalendar.getDayOfOmer();
    if (omer == -1) {
      return "";
    }
    if (_hebrewFormat) {
      return "${formatHebrewNumber(omer)} $_hebrewOmerPrefixעומר";
    } else {
      if (omer == 33) {
        // if lag b'omer
        return _transliteratedHolidays[33];
      } else {
        return "Omer $omer";
      }
    }
  }

  ///Experimental and incomplete
  ///
  ///- [moladChalakim]: 
  ///Returns the formatted molad. FIXME: define proper format in English and Hebrew.

  /// Returns the kviah in the traditional 3 letter Hebrew format where the first letter represents the day of week of
  /// Rosh Hashana, the second letter represents the lengths of Cheshvan and Kislev ([JewishDate.SHELAIMIM] , [JewishDate.KESIDRAN] or [JewishDate.CHASERIM]) and the 3rd letter
  /// represents the day of week of Pesach. For example 5729 (1969) would return בשה (Rosh Hashana on
  /// Monday, Shelaimim, and Pesach on Thursday), while 5771 (2011) would return השג (Rosh Hashana on
  /// Thursday, Shelaimim, and Pesach on Tuesday).
  ///
  /// - [jewishYear]: 
  ///   the Jewish year
  /// Returns the Hebrew String such as בשה for 5729 (1969) and השג for 5771 (2011).
  String getFormattedKviah(int jewishYear) {
    JewishDate jewishDate = JewishDate.fromJewishDate(
        jewishYear, JewishDate.TISHREI, 1); // set date to Rosh Hashana
    int kviah = jewishDate.getCheshvanKislevKviah();
    int roshHashanaDayOfweek = jewishDate.getDayOfWeek();
    String returnValue = formatHebrewNumber(roshHashanaDayOfweek);
    returnValue += (kviah == JewishDate.CHASERIM
        ? "ח"
        : kviah == JewishDate.SHELAIMIM
            ? "ש"
            : "כ");
    jewishDate.setJewishDate(
        jewishYear, JewishDate.NISSAN, 15); // set to Pesach of the given year
    int pesachDayOfweek = jewishDate.getDayOfWeek();
    returnValue += formatHebrewNumber(pesachDayOfweek);
    returnValue = returnValue.replaceAll(
        _GERESH, ""); // geresh is never used in the kviah format
    // boolean isLeapYear = JewishDate.isJewishLeapYear(jewishYear);
    // for efficiency we can avoid the expensive recalculation of the pesach day of week by adding 1 day to Rosh
    // Hashana for a 353 day year, 2 for a 354 day year, 3 for a 355 or 383 day year, 4 for a 384 day year and 5 for
    // a 385 day year
    return returnValue;
  }

  ///
  /// Formats the [Daf Yomi](https://en.wikipedia.org/wiki/Daf_Yomi) Bavli in the format of
  /// "&#x05E2;&#x05D9;&#x05E8;&#x05D5;&#x05D1;&#x05D9;&#x05DF; &#x05E0;&#x05F4;&#x05D1;" in [isHebrewFormat],
  /// or the transliterated format of "Eruvin 52".
  ///
  /// - [daf]: the Daf to be formatted.
  /// Returns the formatted daf.
  ///
  String formatDafYomiBavli(Daf daf) {
    if (_hebrewFormat) {
      return "${daf.getMasechta()} ${formatHebrewNumber(daf.getDaf())}";
    } else {
      return "${daf.getMasechtaTransliterated()} ${daf.getDaf()}";
    }
  }

  ///
  /// Formats the [Daf Yomi Yerushalmi](https://en.wikipedia.org/wiki/Jerusalem_Talmud#Daf_Yomi_Yerushalmi) in the format
  /// of "&#x05E2;&#x05D9;&#x05E8;&#x05D5;&#x05D1;&#x05D9;&#x05DF; &#x05E0;&#x05F4;&#x05D1;" in [isHebrewFormat], or
  /// the transliterated format of "Eruvin 52".
  ///
  /// - [daf]: the Daf to be formatted.
  /// Returns the formatted daf.
  ///
  String formatDafYomiYerushalmi(Daf? daf) {
    if (daf == null) {
      if (_hebrewFormat) {
        return Daf.getYerushalmiMasechtos()[39];
      } else {
        return Daf.getYerushalmiMasechtosTransliterated()[39];
      }
    }
    if (_hebrewFormat) {
      return "${daf.getYerushalmiMasechta()} ${formatHebrewNumber(daf.getDaf())}";
    } else {
      return "${daf.getYerushalmiMasechtaTransliterated()} ${daf.getDaf()}";
    }
  }

  /// Returns a Hebrew formatted string of a number. The method can calculate from 0 - 9999.
  /// 
  /// - Single digit numbers such as 3, 30 and 100 will be returned with a ׳ ([Geresh](http://en.wikipedia.org/wiki/Geresh)) appended as at the end. For example ג׳, and ק׳
  /// - multi digit numbers such as 21 and 769 will be returned with a ״ ([Gershayim](http://en.wikipedia.org/wiki/Gershayim))
  /// between the second to last and last letters. For example כ״א, תשכ״ט</li>
  /// - 15 and 16 will be returned as ט״ו and ט״ז
  /// - Single digit numbers (years assumed) such as 6000 (%1000=0) will be returned as ו׳ אלפים
  /// - 0 will return אפס
  /// 
  ///
  /// - [number]: 
  ///   the number to be formatted. It will trow an IllegalArgumentException if the number is < 0 or > 9999.
  /// Returns the Hebrew formatted number such as תשכ״ט;
  /// See also [isUseFinalFormLetters].
  /// See also [isUseGershGershayim].
  /// See also [isHebrewFormat].
  ///
  String formatHebrewNumber(int number) {
    if (number < 0) {
      throw ArgumentError("negative numbers can't be formatted");
    } else if (number > 9999) {
      throw ArgumentError("numbers > 9999 can't be formatted");
    }

    const String ALAFIM = "אלפים";
    const String EFES = "אפס";

    List<String> jHundreds = [
      "",
      "ק",
      "ר",
      "ש",
      "ת",
      "תק",
      "תר",
      "תש",
      "תת",
      "תתק"
    ];
    List<String> jTens = ["", "י", "כ", "ל", "מ", "נ", "ס", "ע", "פ", "צ"];
    List<String> jTenEnds = ["", "י", "ך", "ל", "ם", "ן", "ס", "ע", "ף", "ץ"];
    List<String> tavTaz = ["טו", "טז"];
    List<String> jOnes = ["", "א", "ב", "ג", "ד", "ה", "ו", "ז", "ח", "ט"];

    if (number == 0) {
      // do we really need this? Should it be applicable to a date?
      return EFES;
    }
    int shortNumber = number % 1000; // discard thousands
    // next check for all possible single Hebrew digit years
    bool singleDigitNumber = (shortNumber < 11 ||
        (shortNumber < 100 && shortNumber % 10 == 0) ||
        (shortNumber <= 400 && shortNumber % 100 == 0));
    int thousands = number ~/ 1000; // get # thousands
    StringBuffer sb = StringBuffer();
    // append thousands to String
    if (number % 1000 == 0) {
      // in year is 5000, 4000 etc
      sb.write(jOnes[thousands]);
      if (_useGershGershayim) {
        sb.write(_GERESH);
      }
      sb.write(" ");
      sb.write(
          ALAFIM); // add # of thousands plus word thousand (overide alafim boolean)
      return sb.toString();
    } else if (_useLongHebrewYears && number >= 1000) {
      // if alafim boolean display thousands
      sb.write(jOnes[thousands]);
      if (_useGershGershayim) {
        sb.write(_GERESH); // write thousands quote
      }
      sb.write(" ");
    }
    number = number % 1000; // remove 1000s
    int hundreds = number ~/ 100; // # of hundreds
    sb.write(jHundreds[hundreds]); // add hundreds to String
    number = number % 100; // remove 100s
    if (number == 15) {
      // special case 15
      sb.write(tavTaz[0]);
    } else if (number == 16) {
      // special case 16
      sb.write(tavTaz[1]);
    } else {
      int tens = number ~/ 10;
      if (number % 10 == 0) {
        // if evenly divisable by 10
        if (!singleDigitNumber) {
          if (_useFinalFormLetters) {
            sb.write(jTenEnds[
                tens]); // years like 5780 will end with a final form &#x05E3;
          } else {
            sb.write(jTens[
                tens]); // years like 5780 will end with a regular &#x05E4;
          }
        } else {
          sb.write(jTens[
              tens]); // standard letters so years like 5050 will end with a regular nun
        }
      } else {
        sb.write(jTens[tens]);
        number = number % 10;
        sb.write(jOnes[number]);
      }
    }
    if (_useGershGershayim) {
      if (singleDigitNumber) {
        sb.write(_GERESH); // write single quote
      } else {
        // write double quote before last digit
        String str = sb.toString();
        return '${str.substring(0, str.length - 1)}$_GERSHAYIM${str.substring(str.length - 1, str.length)}';
      }
    }
    return sb.toString();
  }

  static const List<String> _transliteratedTekufaNames = [
    "Tishrei",
    "Teves",
    "Nissan",
    "Tammuz"
  ];

  static const List<String> _tekufaNames = ["תשרי", "טבת", "ניסן", "תמוז"];

  String formatTekufaName(JewishCalendar jewishCalendar) {
    const double initialTekufaOffset = 12.625;
    final double days =
        JewishDate.getJewishCalendarElapsedDays(jewishCalendar.getJewishYear()) +
            jewishCalendar.getDaysSinceStartOfJewishYear() +
            initialTekufaOffset -
            1;
    final double solarDaysElapsed = days % 365.25;
    final int currentTekufaNumber = solarDaysElapsed ~/ 91.3125;
    final double tekufaDaysElapsed = solarDaysElapsed % 91.3125;
    if (tekufaDaysElapsed > 0 && tekufaDaysElapsed <= 1) {
      return _hebrewFormat
          ? "תקופת ${_tekufaNames[currentTekufaNumber]}"
          : "Tekufas ${_transliteratedTekufaNames[currentTekufaNumber]}";
    }
    return "";
  }

  /// Returns if the [formatDayOfWeek] will use the long format such as ראשון or short such as א when formatting
  /// the day of week in Hebrew.
  /// See also [setLongWeekFormat].
  bool isLongWeekFormat() {
    return _longWeekFormat;
  }

  void setLongWeekFormat(bool longWeekFormat) {
    _longWeekFormat = longWeekFormat;
  }

  /// Returns the day of Shabbos transliterated into Latin chars. The default uses Ashkenazi pronunciation "Shabbos".
  /// See also [setTransliteratedShabbosDayOfWeek].
  String getTransliteratedShabbosDayOfWeek() {
    return _transliteratedShabbosDayOfWeek;
  }

  void setTransliteratedShabbosDayOfWeek(String transliteratedShabbos) {
    _transliteratedShabbosDayOfWeek = transliteratedShabbos;
  }

  /// Returns the list of holidays transliterated into Latin chars. This is used by [formatYomTov] when formatting
  /// the Yom Tov String.
  /// See also [setTransliteratedHolidayList].
  List<String> getTransliteratedHolidayList() {
    return _transliteratedHolidays;
  }

  void setTransliteratedHolidayList(List<String> transliteratedHolidays) {
    _transliteratedHolidays = transliteratedHolidays;
  }

  /// Returns if the formatter is set to use Hebrew formatting in the various formatting methods.
  /// See also [setHebrewFormat].
  bool isHebrewFormat() {
    return _hebrewFormat;
  }

  void setHebrewFormat(bool hebrewFormat) {
    _hebrewFormat = hebrewFormat;
  }

  /// Returns the Hebrew Omer prefix. By default it is the letter ב producing בעומר, but it can be set to ל to
  /// produce לעומר (or any other prefix).
  /// See also [setHebrewOmerPrefix].
  String getHebrewOmerPrefix() {
    return _hebrewOmerPrefix;
  }

  void setHebrewOmerPrefix(String hebrewOmerPrefix) {
    _hebrewOmerPrefix = hebrewOmerPrefix;
  }

  /// Returns the list of Hebrew months. This list has a length of 14 with 3 variations for Adar.
  /// See also [setHebrewMonthList].
  List<String> getHebrewMonthList() {
    return _hebrewMonths;
  }

  void setHebrewMonthList(List<String> hebrewMonths) {
    if (hebrewMonths.length != 14) {
      throw ArgumentError("The Hebrew month array must have a length of 14.");
    }
    _hebrewMonths = hebrewMonths;
  }

  /// Returns the list of months transliterated into Latin chars. The default list of months uses Ashkenazi
  /// pronunciation in typical American English spelling. This list has a length of 14 with 3 variations for Adar -
  /// "Adar", "Adar II", "Adar I".
  /// See also [setTransliteratedMonthList].
  List<String> getTransliteratedMonthList() {
    return _transliteratedMonths;
  }

  void setTransliteratedMonthList(List<String> transliteratedMonths) {
    if (transliteratedMonths.length != 14) {
      throw ArgumentError(
          "The transliterated month array must have a length of 14.");
    }
    _transliteratedMonths = transliteratedMonths;
  }

  /// Returns whether the class is set to use the Geresh and Gershayim in formatting Hebrew dates and numbers.
  /// See also [setUseGershGershayim].
  bool isUseGershGershayim() {
    return _useGershGershayim;
  }

  void setUseGershGershayim(bool useGershGershayim) {
    _useGershGershayim = useGershGershayim;
  }

  /// Returns whether the class is set to use the final form letters when formatting years ending in 20, 40, 50, 80
  /// and 90.
  /// See also [setUseFinalFormLetters].
  bool isUseFinalFormLetters() {
    return _useFinalFormLetters;
  }

  void setUseFinalFormLetters(bool useFinalFormLetters) {
    _useFinalFormLetters = useFinalFormLetters;
  }

  /// Returns whether the class is set to use the thousands digit when formatting a Hebrew year.
  /// See also [setUseLongHebrewYears].
  bool isUseLongHebrewYears() {
    return _useLongHebrewYears;
  }

  void setUseLongHebrewYears(bool useLongHebrewYears) {
    _useLongHebrewYears = useLongHebrewYears;
  }

  /// Returns the map of transliterated parshiyos used by [formatParshah].
  /// See also [setTransliteratedParshiyosList].
  Map<Parshah, String> getTransliteratedParshiyosList() {
    return _transliteratedParshahMap;
  }

  void setTransliteratedParshiyosList(
      Map<Parshah, String> transliteratedParshahMap) {
    _transliteratedParshahMap = transliteratedParshahMap;
  }

  /// Returns a String with the name of the _parshah_ of a [JewishCalendar] passed in (that day's [JewishCalendar.getParshah])
  /// or of a [Parshah] passed in. If the formatter is set to format in Hebrew, it returns the _parshah_ in Hebrew,
  /// otherwise transliterated into Latin chars, using Ashkenazi pronunciation in typical American English spelling.
  /// An empty string is returned for [Parshah.NONE].
  String formatParshah(Object jewishCalendarOrParshah) {
    final Parshah parshah = switch (jewishCalendarOrParshah) {
      JewishCalendar jewishCalendar => jewishCalendar.getParshah(),
      Parshah parshah => parshah,
      _ => throw ArgumentError.value(jewishCalendarOrParshah,
          'jewishCalendarOrParshah', 'must be a JewishCalendar or a Parshah'),
    };
    return (_hebrewFormat
        ? _hebrewParshahMap[parshah]
        : _transliteratedParshahMap[parshah])!;
  }

  /// Returns a String with the name of the current special _parshah_ of Shekalim, Zachor, Parah or Hachodesh, or of
  /// Shabbos Shuva, Shira, Hagadol, Chazon or Nachamu, or an empty String for a non-special _parshah_.
  String formatSpecialParshah(JewishCalendar jewishCalendar) {
    Parshah specialParshah = jewishCalendar.getSpecialShabbos();
    return (_hebrewFormat
        ? _hebrewParshahMap[specialParshah]
        : _transliteratedParshahMap[specialParshah])!;
  }
}
