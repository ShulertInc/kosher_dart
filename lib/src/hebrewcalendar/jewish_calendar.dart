/*
 * Zmanim Java API
 * Copyright (C) 2011 - 2019 Eliyahu Hershfeld
 * Copyright (C) September 2002 Avrom Finkelstien
 * Copyright (C) 2019 Y Paritcher
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

import 'package:kosher_dart/src/hebrewcalendar/jewish_date.dart';
import 'package:kosher_dart/src/hebrewcalendar/daf.dart';
import 'package:kosher_dart/src/hebrewcalendar/yerushalmi_yomi_calculator.dart';
import 'package:kosher_dart/src/hebrewcalendar/yomi_calculator.dart';

/// List of _parshiyos_ or special _Shabasos_. [NONE] indicates a week without a _parshah_, while the enum for
/// the _parshah_ of [VZOS_HABERACHA] exists for consistency, but is not currently used. The special _Shabasos_ of
/// Shekalim, Zachor, Para, Hachodesh, as well as Shabbos Shuva, Shira, Hagadol, Chazon and Nachamu are also
/// represented in this collection of _parshiyos_.
enum Parshah {
  NONE,
  BERESHIS,
  NOACH,
  LECH_LECHA,
  VAYERA,
  CHAYEI_SARA,
  TOLDOS,
  VAYETZEI,
  VAYISHLACH,
  VAYESHEV,
  MIKETZ,
  VAYIGASH,
  VAYECHI,
  SHEMOS,
  VAERA,
  BO,
  BESHALACH,
  YISRO,
  MISHPATIM,
  TERUMAH,
  TETZAVEH,
  KI_SISA,
  VAYAKHEL,
  PEKUDEI,
  VAYIKRA,
  TZAV,
  SHMINI,
  TAZRIA,
  METZORA,
  ACHREI_MOS,
  KEDOSHIM,
  EMOR,
  BEHAR,
  BECHUKOSAI,
  BAMIDBAR,
  NASSO,
  BEHAALOSCHA,
  SHLACH,
  KORACH,
  CHUKAS,
  BALAK,
  PINCHAS,
  MATOS,
  MASEI,
  DEVARIM,
  VAESCHANAN,
  EIKEV,
  REEH,
  SHOFTIM,
  KI_SEITZEI,
  KI_SAVO,
  NITZAVIM,
  VAYEILECH,
  HAAZINU,
  VZOS_HABERACHA,
  VAYAKHEL_PEKUDEI,
  TAZRIA_METZORA,
  ACHREI_MOS_KEDOSHIM,
  BEHAR_BECHUKOSAI,
  CHUKAS_BALAK,
  MATOS_MASEI,
  NITZAVIM_VAYEILECH,
  SHKALIM,
  ZACHOR,
  PARA,
  HACHODESH,
  SHUVA,
  SHIRA,
  HAGADOL,
  CHAZON,
  NACHAMU
}

/// The JewishCalendar extends the [JewishDate] class and adds calendar methods.
///
/// This open source Dart code was originally ported by [Avrom Finkelstien](http://www.facebook.com/avromf)
/// from his C++ code. It was refactored to fit the KosherJava Zmanim API with simplification of the code,
/// enhancements and some bug fixing. The class allows setting whether the holiday and parsha scheme follows
/// the Israel scheme or outside Israel scheme. The default is the outside Israel scheme.
/// The parsha code was ported by Y. Paritcher from his [libzmanim](https://github.com/yparitcher/libzmanim) code.
///
/// See also [JewishDate].
/// See also [HebrewDateFormatter].
/// © Y Paritcher 2019
/// © Avrom Finkelstien 2002
/// © Eliyahu Hershfeld 2011 - 2019
class JewishCalendar extends JewishDate {
  /// The 14th day of Nisan, the day before of Pesach (Passover).
  static const int EREV_PESACH = 0;

  /// The holiday of Pesach (Passover) on the 15th (and 16th out of Israel) day of Nisan.
  static const int PESACH = 1;

  /// Chol Hamoed (interim days) of Pesach (Passover)
  static const int CHOL_HAMOED_PESACH = 2;

  /// Pesach Sheni, the 14th day of Iyar, a minor holiday.
  static const int PESACH_SHENI = 3;

  /// Erev Shavuos (the day before Shavuos), the 5th of Sivan
  static const int EREV_SHAVUOS = 4;

  /// Shavuos (Pentecost), the 6th of Sivan
  static const int SHAVUOS = 5;

  /// The fast of the 17th day of Tamuz
  static const int SEVENTEEN_OF_TAMMUZ = 6;

  /// The fast of the 9th of Av
  static const int TISHA_BEAV = 7;

  /// The 15th day of Av, a minor holiday
  static const int TU_BEAV = 8;

  /// Erev Rosh Hashana (the day before Rosh Hashana), the 29th of Elul
  static const int EREV_ROSH_HASHANA = 9;

  /// Rosh Hashana, the first of Tishrei.
  static const int ROSH_HASHANA = 10;

  /// The fast of Gedalyah, the 3rd of Tishrei.
  static const int FAST_OF_GEDALYAH = 11;

  /// The 9th day of Tishrei, the day before of Yom Kippur.
  static const int EREV_YOM_KIPPUR = 12;

  /// The holiday of Yom Kippur, the 10th day of Tishrei
  static const int YOM_KIPPUR = 13;

  /// The 14th day of Tishrei, the day before of Succos/Sukkos (Tabernacles).
  static const int EREV_SUCCOS = 14;

  /// The holiday of Succos/Sukkos (Tabernacles), the 15th (and 16th out of Israel) day of Tishrei
  static const int SUCCOS = 15;

  /// Chol Hamoed (interim days) of Succos/Sukkos (Tabernacles)
  static const int CHOL_HAMOED_SUCCOS = 16;

  /// Hoshana Rabba, the 7th day of Succos/Sukkos that occurs on the 21st of Tishrei.
  static const int HOSHANA_RABBA = 17;

  /// Shmini Atzeres, the 8th day of Succos/Sukkos is an independent holiday that occurs on the 22nd of Tishrei.
  static const int SHEMINI_ATZERES = 18;

  /// Simchas Torah, the 9th day of Succos/Sukkos, or the second day of Shmini Atzeres that is celebrated
  /// 	 [getInIsrael] on the 23rd of Tishrei.
  static const int SIMCHAS_TORAH = 19;

  // static const int EREV_CHANUKAH = 20;// probably remove this
  /// The holiday of Chanukah. 8 days starting on the 25th day Kislev.
  static const int CHANUKAH = 21;

  /// The fast of the 10th day of Teves.
  static const int TENTH_OF_TEVES = 22;

  /// Tu Bishvat on the 15th day of Shevat, a minor holiday.
  static const int TU_BESHVAT = 23;

  /// The fast of Esther, usually on the 13th day of Adar (or Adar II on leap years). It is earlier on some years.
  static const int FAST_OF_ESTHER = 24;

  /// The holiday of Purim on the 14th day of Adar (or Adar II on leap years).
  static const int PURIM = 25;

  /// The holiday of Shushan Purim on the 15th day of Adar (or Adar II on leap years).
  static const int SHUSHAN_PURIM = 26;

  /// The holiday of Purim Katan on the 14th day of Adar I on a leap year when Purim is on Adar II, a minor holiday.
  static const int PURIM_KATAN = 27;

  /// Rosh Chodesh, the new moon on the first day of the Jewish month, and the 30th day of the previous month in the
  /// case of a month with 30 days.
  static const int ROSH_CHODESH = 28;

  /// Yom HaShoah, Holocaust Remembrance Day, usually held on the 27th of Nisan. If it falls on a Friday, it is moved
  /// to the 26th, and if it falls on a Sunday it is moved to the 28th. A [isUseModernHolidays].
  static const int YOM_HASHOAH = 29;

  /// Yom HaZikaron, Israeli Memorial Day, held a day before Yom Ha'atzmaut.  A [isUseModernHolidays].
  static const int YOM_HAZIKARON = 30;

  /// Yom Ha'atzmaut, Israel Independence Day, the 5th of Iyar, but if it occurs on a Friday or Saturday, the holiday is
  /// moved back to Thursday, the 3rd of 4th of Iyar, and if it falls on a Monday, it is moved forward to Tuesday the
  /// 6th of Iyar.  A [isUseModernHolidays].
  static const int YOM_HAATZMAUT = 31;

  /// Yom Yerushalayim or Jerusalem Day, on 28 Iyar. A [isUseModernHolidays].
  static const int YOM_YERUSHALAYIM = 32;

  ///  The 33rd day of the Omer, the 18th of Iyar, a minor holiday.
  static const int LAG_BAOMER = 33;

  /// The holiday of Shushan Purim Katan on the 15th day of Adar I on a leap year when Purim is on Adar II, a minor
  /// holiday.
  static const int SHUSHAN_PURIM_KATAN = 34;

  /// The day following the last day of _Pesach_, _Shavuos_ and _Succos_.
  static const int ISRU_CHAG = 35;

  static const int YOM_KIPPUR_KATAN = 36;

  static const int BEHAB = 37;

  static const int _SUNDAY = 1;
  static const int _MONDAY = 2;
  static const int _TUESDAY = 3;
  static const int _WEDNESDAY = 4;
  static const int _THURSDAY = 5;
  static const int _FRIDAY = 6;
  static const int _SATURDAY = 7;

  /// Is the calendar set to Israel, where some holidays have different rules.
  /// See also [getInIsrael].
  /// See also [setInIsrael].
  bool _inIsrael = false;

  /// Is the calendar set to have Purim _demukafim_, where Purim is celebrated on Shushan Purim.
  /// See also [getIsMukafChoma].
  /// See also [setIsMukafChoma].
  bool _isMukafChoma = false;

  ///Is the calendar set to use modern Israeli holidays such as Yom Haatzmaut.
  ///See also [isUseModernHolidays].
  ///See also [setUseModernHolidays].
  bool _useModernHolidays = false;

  /// An array of _parshiyos_ in the 17 possible combinations.
  static const List<List<Parshah>> parshahList = [
    [
      Parshah.NONE,
      Parshah.VAYEILECH,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL_PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.NONE,
      Parshah.SHMINI,
      Parshah.TAZRIA_METZORA,
      Parshah.ACHREI_MOS_KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR_BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ],
    [
      Parshah.NONE,
      Parshah.VAYEILECH,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL_PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.NONE,
      Parshah.SHMINI,
      Parshah.TAZRIA_METZORA,
      Parshah.ACHREI_MOS_KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR_BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NONE,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS_BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ],
    [
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL_PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.SHMINI,
      Parshah.TAZRIA_METZORA,
      Parshah.ACHREI_MOS_KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR_BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM
    ],
    [
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.NONE,
      Parshah.SHMINI,
      Parshah.TAZRIA_METZORA,
      Parshah.ACHREI_MOS_KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR_BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM
    ],
    [
      Parshah.NONE,
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL_PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.NONE,
      Parshah.SHMINI,
      Parshah.TAZRIA_METZORA,
      Parshah.ACHREI_MOS_KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR_BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM
    ],
    [
      Parshah.NONE,
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL_PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.NONE,
      Parshah.SHMINI,
      Parshah.TAZRIA_METZORA,
      Parshah.ACHREI_MOS_KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR_BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ],
    [
      Parshah.NONE,
      Parshah.VAYEILECH,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.SHMINI,
      Parshah.TAZRIA,
      Parshah.METZORA,
      Parshah.NONE,
      Parshah.ACHREI_MOS,
      Parshah.KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NONE,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS_BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ],
    [
      Parshah.NONE,
      Parshah.VAYEILECH,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.SHMINI,
      Parshah.TAZRIA,
      Parshah.METZORA,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.ACHREI_MOS,
      Parshah.KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM
    ],
    [
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.SHMINI,
      Parshah.TAZRIA,
      Parshah.METZORA,
      Parshah.ACHREI_MOS,
      Parshah.NONE,
      Parshah.KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS,
      Parshah.MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM
    ],
    [
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.SHMINI,
      Parshah.TAZRIA,
      Parshah.METZORA,
      Parshah.ACHREI_MOS,
      Parshah.NONE,
      Parshah.KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS,
      Parshah.MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ],
    [
      Parshah.NONE,
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.SHMINI,
      Parshah.TAZRIA,
      Parshah.METZORA,
      Parshah.NONE,
      Parshah.ACHREI_MOS,
      Parshah.KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ],
    [
      Parshah.NONE,
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.SHMINI,
      Parshah.TAZRIA,
      Parshah.METZORA,
      Parshah.NONE,
      Parshah.ACHREI_MOS,
      Parshah.KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NONE,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS_BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ],
    [
      Parshah.NONE,
      Parshah.VAYEILECH,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL_PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.NONE,
      Parshah.SHMINI,
      Parshah.TAZRIA_METZORA,
      Parshah.ACHREI_MOS_KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR_BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ],
    [
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL_PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.NONE,
      Parshah.SHMINI,
      Parshah.TAZRIA_METZORA,
      Parshah.ACHREI_MOS_KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM
    ],
    [
      Parshah.NONE,
      Parshah.VAYEILECH,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.SHMINI,
      Parshah.TAZRIA,
      Parshah.METZORA,
      Parshah.NONE,
      Parshah.ACHREI_MOS,
      Parshah.KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ],
    [
      Parshah.NONE,
      Parshah.VAYEILECH,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.SHMINI,
      Parshah.TAZRIA,
      Parshah.METZORA,
      Parshah.NONE,
      Parshah.ACHREI_MOS,
      Parshah.KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS,
      Parshah.MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM
    ],
    [
      Parshah.NONE,
      Parshah.NONE,
      Parshah.HAAZINU,
      Parshah.NONE,
      Parshah.NONE,
      Parshah.BERESHIS,
      Parshah.NOACH,
      Parshah.LECH_LECHA,
      Parshah.VAYERA,
      Parshah.CHAYEI_SARA,
      Parshah.TOLDOS,
      Parshah.VAYETZEI,
      Parshah.VAYISHLACH,
      Parshah.VAYESHEV,
      Parshah.MIKETZ,
      Parshah.VAYIGASH,
      Parshah.VAYECHI,
      Parshah.SHEMOS,
      Parshah.VAERA,
      Parshah.BO,
      Parshah.BESHALACH,
      Parshah.YISRO,
      Parshah.MISHPATIM,
      Parshah.TERUMAH,
      Parshah.TETZAVEH,
      Parshah.KI_SISA,
      Parshah.VAYAKHEL,
      Parshah.PEKUDEI,
      Parshah.VAYIKRA,
      Parshah.TZAV,
      Parshah.SHMINI,
      Parshah.TAZRIA,
      Parshah.METZORA,
      Parshah.NONE,
      Parshah.ACHREI_MOS,
      Parshah.KEDOSHIM,
      Parshah.EMOR,
      Parshah.BEHAR,
      Parshah.BECHUKOSAI,
      Parshah.BAMIDBAR,
      Parshah.NASSO,
      Parshah.BEHAALOSCHA,
      Parshah.SHLACH,
      Parshah.KORACH,
      Parshah.CHUKAS,
      Parshah.BALAK,
      Parshah.PINCHAS,
      Parshah.MATOS_MASEI,
      Parshah.DEVARIM,
      Parshah.VAESCHANAN,
      Parshah.EIKEV,
      Parshah.REEH,
      Parshah.SHOFTIM,
      Parshah.KI_SEITZEI,
      Parshah.KI_SAVO,
      Parshah.NITZAVIM_VAYEILECH
    ]
  ];

  /// Is this calendar set to return modern Israeli national holidays. By default this value is false. The holidays
  /// are: "Yom HaShoah", "Yom Hazikaron", "Yom Ha'atzmaut" and "Yom Yerushalayim"
  ///
  /// Returns the useModernHolidays true if set to return modern Israeli national holidays
  bool isUseModernHolidays() {
    return _useModernHolidays;
  }

  /// Seth the calendar to return modern Israeli national holidays. By default this value is false. The holidays are:
  /// "Yom HaShoah", "Yom Hazikaron", "Yom Ha'atzmaut" and "Yom Yerushalayim"
  ///
  /// - [useModernHolidays]:
  ///   the useModernHolidays to set
  void setUseModernHolidays(bool useModernHolidays) {
    _useModernHolidays = useModernHolidays;
  }

  /// Default constructor will set a default date to the current system date.
  JewishCalendar() : super();

  /// A constructor that initializes the date to the date of the zoned [DateTime] parameter, read in its own zone.
  ///
  /// - [zonedDateTime]:
  ///   the [DateTime] to set the calendar to
  JewishCalendar.fromZonedDateTime(super.zonedDateTime)
      : super.fromZonedDateTime();

  /// A constructor that initializes the date to the [DateTime] parameter's date.
  ///
  /// - [localDate]:
  ///   the date to set the calendar to
  JewishCalendar.fromLocalDate(super.localDate) : super.fromLocalDate();

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
  JewishCalendar.fromJewishDate(
      super.jewishYear, super.jewishMonth, super.jewishDayOfMonth)
      : super.fromJewishDate();

  /// Creates a Jewish date based on a Jewish date and whether in Israel
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
  /// - [inIsrael]:
  ///   whether in Israel. This affects Yom Tov calculations
  JewishCalendar.fromJewishDateInIsrael(
      super.jewishYear, super.jewishMonth, super.jewishDayOfMonth, bool inIsrael)
      : super.fromJewishDate() {
    setInIsrael(inIsrael);
  }

  /// Sets whether to use Israel holiday scheme or not. Default is false.
  ///
  /// - [inIsrael]:
  ///   set to true for calculations for Israel
  ///
  /// See also [getInIsrael].
  void setInIsrael(bool inIsrael) {
    _inIsrael = inIsrael;
  }

  /// Gets whether Israel holiday scheme is used or not. The default (if not set) is false.
  ///
  /// Returns if the calendar is set to Israel
  ///
  /// See also [setInIsrael].
  bool getInIsrael() {
    return _inIsrael;
  }

  /// Returns if the city is set as a city surrounded by a wall from the time of Yehoshua, and Shushan Purim
  /// should be celebrated as opposed to regular Purim.
  ///
  /// See also [setIsMukafChoma].
  bool getIsMukafChoma() {
    return _isMukafChoma;
  }

  /// Sets if the location is surrounded by a wall from the time of Yehoshua, and Shushan Purim should be
  /// celebrated as opposed to regular Purim. This should be set for Yerushalayim, Shushan and other cities.
  ///
  /// - [isMukafChoma]: is the city surrounded by a wall from the time of Yehoshua.
  ///
  /// See also [getIsMukafChoma].
  void setIsMukafChoma(bool isMukafChoma) {
    _isMukafChoma = isMukafChoma;
  }

  /// [Birkas Hachamah](https://en.wikipedia.org/wiki/Birkat_Hachama) is recited every 28 years based on
  /// Tekufas Shmulel (Julian years) that a year is 365.25 days. The [Rambam](https://en.wikipedia.org/wiki/Maimonides)
  /// in [Hilchos Kiddush Hachodesh 9:3](http://hebrewbooks.org/pdfpager.aspx?req=14278&st=&pgnum=323) states that
  /// tekufas Nisan of year 1 was 7 days + 9 hours before molad Nisan. This is calculated as every 10,227 days (28 * 365.25).
  /// Returns true for a day that Birkas Hachamah is recited.
  bool isBirkasHachamah() {
    int elapsedDays = JewishDate.getJewishCalendarElapsedDays(
        getJewishYear()); //elapsed days since molad ToHu
    elapsedDays = elapsedDays +
        getDaysSinceStartOfJewishYear(); //elapsed days to the current calendar date

    /* Molad Nisan year 1 was 177 days after molad tohu of Tishrei. We multiply 29.5 day months * 6 months from Tishrei
		 * to Nisan = 177. Subtract 7 days since tekufas Nisan was 7 days and 9 hours before the molad as stated in the Rambam
		 * and we are now at 170 days. Because getJewishCalendarElapsedDays and getDaysSinceStartOfJewishYear use the value for
		 * Rosh Hashana as 1, we have to add 1 day days for a total of 171. To this add a day since the tekufah is on a Tuesday
		 * night and we push off the bracha to Wednesday AM resulting in the 172 used in the calculation.
		 */
    return elapsedDays % 10227 == 172; // 28 years of 365.25 days + the offset from molad tohu mentioned above
  }

  /// Returns the elapsed days since _Tekufas Tishrei_. This uses _Tekufas Shmuel_ (identical to the [Julian Year](https://en.wikipedia.org/wiki/Julian_year_(astronomy)) with a solar year length of 365.25 days.
  /// The notation used below is D = days, H = hours and C = chalakim. _Molad BaHaRad_ was 2D,5H,204C or 5H,204C from the start of _Rosh Hashana_ year 1. For <em>molad
  /// Nissan</em> add 177D, 4H and 438C (6 * 29D, 12H and 793C), or 177D,9H,642C after _Rosh Hashana_ year 1.
  /// _Tekufas Nissan_ was 7D, 9H and 642C before _molad Nissan_ according to the Rambam, or 170D, 0H and
  /// 0C after _Rosh Hashana_ year 1. _Tekufas Tishrei_ was 182D and 3H (365.25 / 2) before <em>tekufas
  /// Nissan</em>, or 12D and 15H before _Rosh Hashana_ of year 1. Outside of Israel we start reciting <em>Tal
  /// Umatar</em> in _Birkas Hashanim_ from 60 days after _tekufas Tishrei_. The 60 days include the day of
  /// the _tekufah_ and the day we start reciting _Tal Umatar_. 60 days from the tekufah == 47D and 9H
  /// from _Rosh Hashana_ year 1.
  ///
  /// Returns the number of elapsed days since _tekufas Tishrei_

  int getTekufasTishreiElapsedDays() {
    // days since Rosh Hashana year 1
    // add 1/2 day as the first tekufas tishrei was 9 hours into the day
    // this allows all 4 years of the secular leap year cycle to share 47 days
    // make from 47D,9H to 47D for simplicity
    double days = JewishDate.getJewishCalendarElapsedDays(getJewishYear()) +
        (getDaysSinceStartOfJewishYear() - 1) +
        .5;
    // days of completed solar years
    double solar = (getJewishYear() - 1) * 365.25;
    return (days - solar).floor();
  }

  double? _getTekufa() {
    const double initialTekufaOffset = 12.625;
    final double days = JewishDate.getJewishCalendarElapsedDays(getJewishYear()) +
        getDaysSinceStartOfJewishYear() +
        initialTekufaOffset -
        1;
    final double tekufaDaysElapsed = days % 365.25 % 91.3125;
    if (tekufaDaysElapsed > 0 && tekufaDaysElapsed <= 1) {
      return ((1.0 - tekufaDaysElapsed) * 24.0) % 24;
    }
    return null;
  }

  DateTime? getTekufaAsInstant(bool useLocalMeanTime) {
    double? hours = _getTekufa();
    if (hours == null) {
      return null;
    }
    hours -= 6;
    int dayShift = 0;
    if (hours < 0) {
      hours += 24;
      dayShift = -1;
    }
    final int wholeHours = hours.toInt();
    final int minutes = ((hours - wholeHours) * 60).toInt();
    final DateTime date = getLocalDate();
    final DateTime tekufa = DateTime.utc(
            date.year, date.month, date.day + dayShift, wholeHours, minutes)
        .subtract(const Duration(hours: 2));
    if (useLocalMeanTime) {
      return tekufa.subtract(
          const Duration(minutes: 20, seconds: 56, milliseconds: 496));
    }
    return tekufa;
  }

  /// Return the type of year for parsha calculations. The algorithm follows the
  /// [Luach Arba'ah Shearim](http://hebrewbooks.org/pdfpager.aspx?req=14268&st=&pgnum=222) in the Tur Ohr Hachaim.
  /// Returns the type of year for parsha calculations.
  int _getParshahYearType() {
    int roshHashanaDayOfWeek = (JewishDate.getJewishCalendarElapsedDays(
                getJewishYear()) +
            1) %
        7; // plus one to the original Rosh Hashana of year 1 to get a week starting on Sunday
    if (roshHashanaDayOfWeek == 0) {
      roshHashanaDayOfWeek = 7; // convert 0 to 7 for Shabbos for readability
    }
    if (isJewishLeapYear()) {
      switch (roshHashanaDayOfWeek) {
        case _MONDAY:
          if (isKislevShort()) {
            //BaCh
            if (getInIsrael()) {
              return 14;
            }
            return 6;
          }
          if (isCheshvanLong()) {
            //BaSh
            if (getInIsrael()) {
              return 15;
            }
            return 7;
          }
          break;
        case _TUESDAY: //Gak
          if (getInIsrael()) {
            return 15;
          }
          return 7;
        case _THURSDAY:
          if (isKislevShort()) {
            //HaCh
            return 8;
          }
          if (isCheshvanLong()) {
            //HaSh
            return 9;
          }
          break;
        case _SATURDAY:
          if (isKislevShort()) {
            //ZaCh
            return 10;
          }
          if (isCheshvanLong()) {
            //ZaSh
            if (getInIsrael()) {
              return 16;
            }
            return 11;
          }
          break;
        default:
          return -1;
      }
    } else {
      //not a leap year
      switch (roshHashanaDayOfWeek) {
        case _MONDAY:
          if (isKislevShort()) {
            //BaCh
            return 0;
          }
          if (isCheshvanLong()) {
            //BaSh
            if (getInIsrael()) {
              return 12;
            }
            return 1;
          }
          break;
        case _TUESDAY: //GaK
          if (getInIsrael()) {
            return 12;
          }
          return 1;
        case _THURSDAY:
          if (isCheshvanLong()) {
            //HaSh
            return 3;
          }
          if (!isKislevShort()) {
            //Hak
            if (getInIsrael()) {
              return 13;
            }
            return 2;
          }
          break;
        case _SATURDAY:
          if (isKislevShort()) {
            //ZaCh
            return 4;
          }
          if (isCheshvanLong()) {
            //ZaSh
            return 5;
          }
          break;
        default:
          return -1;
      }
    }
    return -1; //keep the compiler happy
  }

  /// Returns this week's [Parshah] if it is _Shabbos_.
  /// returns Parshah.NONE if a weekday or if there is no _parsha_ that week (for example _Yomtov_ is on _Shabbos_).
  ///
  /// Returns the current _parsha_.
  Parshah getParshah() {
    if (getDayOfWeek() != _SATURDAY) {
      return Parshah.NONE;
    }

    int yearType = _getParshahYearType();
    int roshHashanaDayOfWeek =
        JewishDate.getJewishCalendarElapsedDays(getJewishYear()) % 7;
    int day = roshHashanaDayOfWeek + getDaysSinceStartOfJewishYear();

    if (yearType >= 0) {
      // negative year should be impossible, but lets cover all bases
      return parshahList[yearType][day ~/ 7];
    }
    return Parshah.NONE; //keep the compiler happy
  }

  /// Returns a _parsha_ enum if the _Shabbos_ is one of the named ones - the four
  /// _parshiyos_ of Parshah.SHKALIM, Parshah.ZACHOR, Parshah.PARA and Parshah.HACHODESH, or
  /// Parshah.SHUVA, Parshah.SHIRA, Parshah.HAGADOL, Parshah.CHAZON and Parshah.NACHAMU - or
  /// Parshah.NONE for a regular _Shabbos_ (or any weekday).
  ///
  /// Returns the named _Shabbos_ or Parshah.NONE.
  Parshah getSpecialShabbos() {
    if (getDayOfWeek() == _SATURDAY) {
      if ((getJewishMonth() == JewishDate.SHEVAT && !isJewishLeapYear()) ||
          (getJewishMonth() == JewishDate.ADAR && isJewishLeapYear())) {
        if (getJewishDayOfMonth() == 25 ||
            getJewishDayOfMonth() == 27 ||
            getJewishDayOfMonth() == 29) {
          return Parshah.SHKALIM;
        }
      }
      if ((getJewishMonth() == JewishDate.ADAR && !isJewishLeapYear()) ||
          getJewishMonth() == JewishDate.ADAR_II) {
        if (getJewishDayOfMonth() == 1) {
          return Parshah.SHKALIM;
        }
        if (getJewishDayOfMonth() == 8 ||
            getJewishDayOfMonth() == 9 ||
            getJewishDayOfMonth() == 11 ||
            getJewishDayOfMonth() == 13) {
          return Parshah.ZACHOR;
        }
        if (getJewishDayOfMonth() == 18 ||
            getJewishDayOfMonth() == 20 ||
            getJewishDayOfMonth() == 22 ||
            getJewishDayOfMonth() == 23) {
          return Parshah.PARA;
        }
        if (getJewishDayOfMonth() == 25 ||
            getJewishDayOfMonth() == 27 ||
            getJewishDayOfMonth() == 29) {
          return Parshah.HACHODESH;
        }
      }
      if (getJewishMonth() == JewishDate.NISSAN) {
        if (getJewishDayOfMonth() == 1) {
          return Parshah.HACHODESH;
        }
        // The Shabbos before Pesach.
        if (getJewishDayOfMonth() >= 8 && getJewishDayOfMonth() <= 14) {
          return Parshah.HAGADOL;
        }
      }
      if (getJewishMonth() == JewishDate.AV) {
        // The Shabbos before Tisha B'Av, when the haftara is Yeshaya's chazon.
        if (getJewishDayOfMonth() >= 4 && getJewishDayOfMonth() <= 9) {
          return Parshah.CHAZON;
        }
        // The Shabbos after it, when the haftara opens nachamu nachamu ami.
        if (getJewishDayOfMonth() >= 10 && getJewishDayOfMonth() <= 16) {
          return Parshah.NACHAMU;
        }
      }
      // The Shabbos of the Aseres Yemei Teshuva, whose haftara opens shuva Yisrael.
      if (getJewishMonth() == JewishDate.TISHREI &&
          getJewishDayOfMonth() >= 3 &&
          getJewishDayOfMonth() <= 8) {
        return Parshah.SHUVA;
      }
      // The Shabbos the shiras hayam is read.
      if (getParshah() == Parshah.BESHALACH) {
        return Parshah.SHIRA;
      }
    }
    return Parshah.NONE;
  }

  /// Returns the _parsha_ of the next _Shabbos_, skipping the _Shabbosos_ whose reading a
  /// _yom tov_ displaces. On a _Shabbos_ this answers the following week's, not today's;
  /// use [getParshah] for today's.
  ///
  /// Returns the _parsha_ of the coming _Shabbos_.
  Parshah getUpcomingParshah() {
    final JewishCalendar clone = this.clone();
    final int daysToShabbos = (_SATURDAY - getDayOfWeek() + 7) % 7;
    if (getDayOfWeek() != _SATURDAY) {
      clone.plusDays(daysToShabbos);
    } else {
      clone.plusDays(7);
    }
    while (clone.getParshah() == Parshah.NONE) {
      clone.plusDays(7);
    }
    return clone.getParshah();
  }

  /// Returns an index of the Jewish holiday or fast day for the current day, or a -1 if there is no holiday for this
  /// day. There are constants in this class representing each Yom Tov. Formatting of the Yomim tovim is done in the
  /// ZmanimFormatter#
  /// TODO: consider using enums instead of the constant ints.
  /// Returns the index of the holiday such as the constant [LAG_BAOMER] or [YOM_KIPPUR] or a -1 if it is not a holiday.
  /// See also [HebreDateFormatter].
  int getYomTovIndex() {
    final int day = getJewishDayOfMonth();
    final int dayOfWeek = getDayOfWeek();

    // check by month (starting from Nissan)
    switch (getJewishMonth()) {
      case JewishDate.NISSAN:
        if (day == 14) {
          return EREV_PESACH;
        }
        if (day == 15 || day == 21 || (!getInIsrael() && (day == 16 || day == 22))) {
          return PESACH;
        }
        if (day >= 17 && day <= 20 || (day == 16 && getInIsrael())) {
          return CHOL_HAMOED_PESACH;
        }
        if ((day == 22 && getInIsrael()) || (day == 23 && !getInIsrael())) {
          return ISRU_CHAG;
        }
        if (isUseModernHolidays() &&
            ((day == 26 && dayOfWeek == _THURSDAY) ||
                (day == 28 && dayOfWeek == _MONDAY) ||
                (day == 27 &&
                    dayOfWeek != _SUNDAY &&
                    dayOfWeek != _FRIDAY))) {
          return YOM_HASHOAH;
        }
        break;
      case JewishDate.IYAR:
        if (isUseModernHolidays() &&
            ((day == 4 && dayOfWeek == _TUESDAY) ||
                ((day == 3 || day == 2) && dayOfWeek == _WEDNESDAY) ||
                ((day == 5 || day == 6) && dayOfWeek == _MONDAY))) {
          return YOM_HAZIKARON;
        }
        // if 5 Iyar falls on Tue, Wed or Thu, Yom Haatzmaut is that day.
        // If it falls on Friday or Shabbos it is moved back to Thursday.
        // If it falls on Sunday it is moved forward to Tuesday.
        // If it falls on Monday it is moved to Tuesday.
        if (isUseModernHolidays() &&
            ((day == 5 &&
                    dayOfWeek != _FRIDAY &&
                    dayOfWeek != _SATURDAY &&
                    dayOfWeek != _SUNDAY &&
                    dayOfWeek != _MONDAY) ||
                ((day == 4 || day == 3) && dayOfWeek == _THURSDAY) ||
                ((day == 6 || day == 7) && dayOfWeek == _TUESDAY))) {
          return YOM_HAATZMAUT;
        }
        if (day == 14) {
          return PESACH_SHENI;
        }
        if (day == 18) {
          return LAG_BAOMER;
        }
        if (isUseModernHolidays() && day == 28) {
          return YOM_YERUSHALAYIM;
        }
        break;
      case JewishDate.SIVAN:
        if (day == 5) {
          return EREV_SHAVUOS;
        }
        if (day == 6 || (day == 7 && !getInIsrael())) {
          return SHAVUOS;
        }
        if ((day == 7 && getInIsrael()) || (day == 8 && !getInIsrael())) {
          return ISRU_CHAG;
        }
        break;
      case JewishDate.TAMMUZ:
        // push off the fast day if it falls on Shabbos
        if ((day == 17 && dayOfWeek != _SATURDAY) ||
            (day == 18 && dayOfWeek == _SUNDAY)) {
          return SEVENTEEN_OF_TAMMUZ;
        }
        break;
      case JewishDate.AV:
        // if Tisha B'av falls on Shabbos, push off until Sunday
        if ((dayOfWeek == _SUNDAY && day == 10) ||
            (dayOfWeek != _SATURDAY && day == 9)) {
          return TISHA_BEAV;
        }
        if (day == 15) {
          return TU_BEAV;
        }
        break;
      case JewishDate.ELUL:
        if (day == 29) {
          return EREV_ROSH_HASHANA;
        }
        break;
      case JewishDate.TISHREI:
        if (day == 1 || day == 2) {
          return ROSH_HASHANA;
        }
        if ((day == 3 && dayOfWeek != _SATURDAY) ||
            (day == 4 && dayOfWeek == _SUNDAY)) {
          // push off Tzom Gedalia if it falls on Shabbos
          return FAST_OF_GEDALYAH;
        }
        if (day == 9) {
          return EREV_YOM_KIPPUR;
        }
        if (day == 10) {
          return YOM_KIPPUR;
        }
        if (day == 14) {
          return EREV_SUCCOS;
        }
        if (day == 15 || (day == 16 && !getInIsrael())) {
          return SUCCOS;
        }
        if (day >= 17 && day <= 20 || (day == 16 && getInIsrael())) {
          return CHOL_HAMOED_SUCCOS;
        }
        if (day == 21) {
          return HOSHANA_RABBA;
        }
        if (day == 22) {
          return SHEMINI_ATZERES;
        }
        if (day == 23 && !getInIsrael()) {
          return SIMCHAS_TORAH;
        }
        if ((day == 23 && getInIsrael()) || (day == 24 && !getInIsrael())) {
          return ISRU_CHAG;
        }
        break;
      case JewishDate.KISLEV: // no yomtov in CHESHVAN
        // if (day == 24) {
        // return EREV_CHANUKAH;
        // } else
        if (day >= 25) {
          return CHANUKAH;
        }
        break;
      case JewishDate.TEVES:
        if (day == 1 || day == 2 || (day == 3 && isKislevShort())) {
          return CHANUKAH;
        }
        if (day == 10) {
          return TENTH_OF_TEVES;
        }
        break;
      case JewishDate.SHEVAT:
        if (day == 15) {
          return TU_BESHVAT;
        }
        break;
      case JewishDate.ADAR:
        if (!isJewishLeapYear()) {
          // if 13th Adar falls on Friday or Shabbos, push back to Thursday
          if (((day == 11 || day == 12) && dayOfWeek == _THURSDAY) ||
              (day == 13 &&
                  !(dayOfWeek == _FRIDAY ||
                      dayOfWeek == _SATURDAY))) {
            return FAST_OF_ESTHER;
          }
          if (day == 14) {
            return PURIM;
          }
          if (day == 15) {
            return SHUSHAN_PURIM;
          }
        } else {
          // else if a leap year
          if (day == 14) {
            return PURIM_KATAN;
          }
          if (day == 15) {
            return SHUSHAN_PURIM_KATAN;
          }
        }
        break;
      case JewishDate.ADAR_II:
        // if 13th Adar falls on Friday or Shabbos, push back to Thursday
        if (((day == 11 || day == 12) && dayOfWeek == _THURSDAY) ||
            (day == 13 &&
                !(dayOfWeek == _FRIDAY ||
                    dayOfWeek == _SATURDAY))) {
          return FAST_OF_ESTHER;
        }
        if (day == 14) {
          return PURIM;
        }
        if (day == 15) {
          return SHUSHAN_PURIM;
        }
        break;
    }
    // if we get to this stage, then there are no holidays for the given date return -1
    return -1;
  }

  /// Returns true if the current day is _Yom Tov_. The method returns true even for holidays such as [CHANUKAH]
  /// and minor ones such as [TU_BEAV] and [PESACH_SHENI]. _Erev Yom Tov_ (with the exception of
  /// [HOSHANA_RABBA] and _erev_ the last day of _Pesach_) returns false, as do [isTaanis] besides
  /// [YOM_KIPPUR] and [ISRU_CHAG]. Use [isAssurBemelacha] to find the days that have a prohibition of work.
  ///
  ///  See also [getYomTovIndex].
  /// Returns true if the current day is a Yom Tov
  /// See also [isErevYomTov].
  /// See also [isErevYomTovSheni].
  /// See also [isTaanis].
  /// See also [isAssurBemelacha].
  /// See also [isCholHamoed].
  bool isYomTov() {
    int holidayIndex = getYomTovIndex();
    if ((isErevYomTov() &&
            !(holidayIndex == HOSHANA_RABBA ||
                holidayIndex == CHOL_HAMOED_PESACH)) ||
        (isTaanis() && holidayIndex != YOM_KIPPUR) ||
        holidayIndex == ISRU_CHAG) {
      return false;
    }
    return holidayIndex != -1;
  }

  /// Returns true if the _Yom Tov_ day has a _melacha_ (work)  prohibition. This method will return false for a
  /// non-_Yom Tov_ day, even if it is _Shabbos_.
  ///
  /// Returns if the _Yom Tov_ day has a _melacha_ (work)  prohibition.
  bool isYomTovAssurBemelacha() {
    int holidayIndex = getYomTovIndex();
    return holidayIndex == PESACH ||
        holidayIndex == SHAVUOS ||
        holidayIndex == SUCCOS ||
        holidayIndex == SHEMINI_ATZERES ||
        holidayIndex == SIMCHAS_TORAH ||
        holidayIndex == ROSH_HASHANA ||
        holidayIndex == YOM_KIPPUR;
  }

  /// Returns true if it is _Shabbos_ or if it is a _Yom Tov_ day that has a _melacha_ (work)  prohibition.
  /// This method will return false for a.
  /// Returns if the day is a _Yom Tov_ that is _assur bemlacha_ or _Shabbos_
  bool isAssurBemelacha() {
    return getDayOfWeek() == _SATURDAY ||
        isYomTovAssurBemelacha();
  }

  /// Returns true if tomorrow is _Shabbos_ or _Yom Tov_. This will return true on erev _Shabbos_,
  /// _erev Yom Tov_, the first day of _Rosh Hashana_ and _erev_ the first days of _Yom Tov_
  /// out of Israel. It is identical to calling [hasCandleLighting].
  ///
  /// Returns will return if the next day is _Shabbos_ or _Yom Tov_.
  ///
  /// See also [hasCandleLighting].
  bool hasCandleLighting() {
    return isTomorrowShabbosOrYomTov();
  }

  /// Returns true if tomorrow is _Shabbos_ or _Yom Tov_. This will return true on erev _Shabbos_, erev
  /// _Yom Tov_, the first day of _Rosh Hashana_ and _erev_ the first days of _Yom Tov_ out of
  /// Israel. It is identical to calling [hasCandleLighting].
  /// Returns will return if the next day is _Shabbos_ or _Yom Tov_
  bool isTomorrowShabbosOrYomTov() {
    return getDayOfWeek() == _FRIDAY ||
        isErevYomTov() ||
        isErevYomTovSheni();
  }

  /// Returns true if the day is the second day of _Yom Tov_. This impacts the second day of _Rosh Hashana_ everywhere and
  /// the second days of Yom Tov in _chutz laaretz_ (out of Israel).
  ///
  /// Returns if the day is the second day of _Yom Tov_.
  bool isErevYomTovSheni() {
    return (getJewishMonth() == JewishDate.TISHREI &&
            (getJewishDayOfMonth() == 1)) ||
        (!getInIsrael() &&
            ((getJewishMonth() == JewishDate.NISSAN &&
                    (getJewishDayOfMonth() == 15 ||
                        getJewishDayOfMonth() == 21)) ||
                (getJewishMonth() == JewishDate.TISHREI &&
                    (getJewishDayOfMonth() == 15 ||
                        getJewishDayOfMonth() == 22)) ||
                (getJewishMonth() == JewishDate.SIVAN &&
                    getJewishDayOfMonth() == 6)));
  }

  /// Returns true if the current day is _Aseret Yemei Teshuva_.
  ///
  /// Returns if the current day is _Aseret Yemei Teshuvah_
  bool isAseresYemeiTeshuva() {
    return getJewishMonth() == JewishDate.TISHREI &&
        getJewishDayOfMonth() <= 10;
  }

  /// Returns true if the current day is _Chol Hamoed_ of _Pesach_ or _Succos_.
  ///
  /// Returns true if the current day is _Chol Hamoed_ of _Pesach_ or _Succos_
  /// See also [isYomTov].
  /// See also [CHOL_HAMOED_PESACH].
  /// See also [CHOL_HAMOED_SUCCOS].
  bool isCholHamoed() {
    return isCholHamoedPesach() || isCholHamoedSuccos();
  }

  /// Returns true if the current day is _Chol Hamoed_ of _Pesach_.
  ///
  /// Returns true if the current day is _Chol Hamoed_ of _Pesach_
  /// See also [isYomTov].
  /// See also [CHOL_HAMOED_PESACH].
  bool isCholHamoedPesach() {
    int holidayIndex = getYomTovIndex();
    return holidayIndex == CHOL_HAMOED_PESACH;
  }

  /// Returns true if the current day is _Chol Hamoed_ of _Succos_.
  ///
  /// Returns true if the current day is _Chol Hamoed_ of _Succos_
  /// See also [isYomTov].
  /// See also [CHOL_HAMOED_SUCCOS].
  bool isCholHamoedSuccos() {
    int holidayIndex = getYomTovIndex();
    return holidayIndex == CHOL_HAMOED_SUCCOS || holidayIndex == HOSHANA_RABBA;
  }

  /// Returns true if the current day is erev Yom Tov. The method returns true for Erev - Pesach (first and last days),
  /// Shavuos, Rosh Hashana, Yom Kippur and Succos and Hoshana Rabba.
  ///
  /// Returns true if the current day is Erev - Pesach, Shavuos, Rosh Hashana, Yom Kippur and Succos
  /// See also [isYomTov].
  /// See also [isErevYomTovSheni].
  bool isErevYomTov() {
    int holidayIndex = getYomTovIndex();
    return holidayIndex == EREV_PESACH ||
        holidayIndex == EREV_SHAVUOS ||
        holidayIndex == EREV_ROSH_HASHANA ||
        holidayIndex == EREV_YOM_KIPPUR ||
        holidayIndex == EREV_SUCCOS ||
        holidayIndex == HOSHANA_RABBA ||
        (holidayIndex == CHOL_HAMOED_PESACH && getJewishDayOfMonth() == 20);
  }

  /// Returns true if the current day is Erev Rosh Chodesh. Returns false for Erev Rosh Hashana
  ///
  /// Returns true if the current day is Erev Rosh Chodesh. Returns false for Erev Rosh Hashana
  /// See also [isRoshChodesh].
  bool isErevRoshChodesh() {
    // Erev Rosh Hashana is not Erev Rosh Chodesh.
    return (getJewishDayOfMonth() == 29 && getJewishMonth() != JewishDate.ELUL);
  }

  /// Return true if the day is a Taanis (fast day). Return true for 17 of Tammuz, Tisha B'Av, Yom Kippur, Fast of
  /// Gedalyah, 10 of Teves and the Fast of Esther
  ///
  /// Returns true if today is a fast day
  bool isTaanis() {
    int holidayIndex = getYomTovIndex();
    return holidayIndex == SEVENTEEN_OF_TAMMUZ ||
        holidayIndex == TISHA_BEAV ||
        holidayIndex == YOM_KIPPUR ||
        holidayIndex == FAST_OF_GEDALYAH ||
        holidayIndex == TENTH_OF_TEVES ||
        holidayIndex == FAST_OF_ESTHER;
  }

  /// Return true if the day is Taanis Bechoros (on erev Pesach). It will return true for the 14th of Nissan if it is not
  /// on Shabbos, or if the 12th of Nissan occurs on a Thursday
  ///
  /// Returns true if today is the fast of Bechoros
  bool isTaanisBechoros() {
    final int day = getJewishDayOfMonth();
    final int dayOfWeek = getDayOfWeek();
    // on 14 Nisan unless that is Shabbos where the fast is moved back to Thursday
    return getJewishMonth() == JewishDate.NISSAN &&
        ((day == 14 && dayOfWeek != _SATURDAY) ||
            (day == 12 && dayOfWeek == _THURSDAY));
  }

  /// Returns true if the day is _BeHaB_ - the Monday, Thursday and Monday after the first
  /// _Shabbos_ of _Cheshvan_ and _Iyar_, on which _selichos_ are said and some fast.
  bool isBeHaB() {
    final int dayOfWeek = getDayOfWeek();
    final int month = getJewishMonth();
    final int day = getJewishDayOfMonth();

    if (month == JewishDate.CHESHVAN || month == JewishDate.IYAR) {
      return (dayOfWeek == _MONDAY && day > 4 && day < 18) ||
          (dayOfWeek == _THURSDAY && day > 7 && day < 14);
    }
    return false;
  }

  /// Returns true if the day is _Yom Kippur Katan_, said on _erev Rosh Chodesh_ and moved
  /// back to the Thursday when that falls on Friday or _Shabbos_. It is not said before
  /// _Rosh Chodesh_ Cheshvan, Teves, Iyar or Sivan, so Elul, Tishrei, Kislev and Nissan
  /// answer false.
  bool isYomKippurKatan() {
    final int dayOfWeek = getDayOfWeek();
    final int month = getJewishMonth();
    final int day = getJewishDayOfMonth();

    if (month == JewishDate.ELUL ||
        month == JewishDate.TISHREI ||
        month == JewishDate.KISLEV ||
        month == JewishDate.NISSAN) {
      return false;
    }

    if (day == 29 &&
        dayOfWeek != _FRIDAY &&
        dayOfWeek != _SATURDAY) {
      return true;
    }
    return (day == 27 || day == 28) && dayOfWeek == _THURSDAY;
  }

  /// Returns true if today is _assur bemelacha_ and tomorrow is not, which is the night
  /// melacha becomes permitted again. False on the first day of a two-day yom tov, and on
  /// a _Shabbos_ that runs into one.
  ///
  /// See also [isAssurBemelacha].
  bool isTonightMutarBemelacha() {
    if (!isAssurBemelacha()) {
      return false;
    }

    final JewishCalendar tomorrow = clone();
    tomorrow.plusDays(1);
    return !tomorrow.isAssurBemelacha();
  }

  /// Returns the day of Chanukah or -1 if it is not Chanukah.
  ///
  /// Returns the day of Chanukah or -1 if it is not Chanukah.
  int getDayOfChanukah() {
    final int day = getJewishDayOfMonth();
    if (isChanukah()) {
      if (getJewishMonth() == JewishDate.KISLEV) {
        return day - 24;
      } else {
        // teves
        return isKislevShort() ? day + 5 : day + 6;
      }
    } else {
      return -1;
    }
  }

  /// Returns true if the current day is one of the 8 days of [CHANUKAH].
  /// Returns if the current day is one of the 8 days of [CHANUKAH].
  /// See also [getDayOfChanukah].
  bool isChanukah() {
    return getYomTovIndex() == CHANUKAH;
  }

  /// Returns if the day is _Pesach_, the yom tov days and _chol hamoed_ alike.
  bool isPesach() {
    int holidayIndex = getYomTovIndex();
    return holidayIndex == PESACH || holidayIndex == CHOL_HAMOED_PESACH;
  }

  /// Returns if the day is _Shavuos_.
  bool isShavuos() {
    return getYomTovIndex() == SHAVUOS;
  }

  /// Returns if the day is _Rosh Hashana_.
  bool isRoshHashana() {
    return getYomTovIndex() == ROSH_HASHANA;
  }

  /// Returns if the day is _Yom Kippur_.
  bool isYomKippur() {
    return getYomTovIndex() == YOM_KIPPUR;
  }

  /// Returns if the day is _Succos_, the yom tov days, _chol hamoed_ and _Hoshana Rabba_
  /// alike. _Shemini Atzeres_ is not included; see [isShminiAtzeres].
  bool isSuccos() {
    int holidayIndex = getYomTovIndex();
    return holidayIndex == SUCCOS ||
        holidayIndex == CHOL_HAMOED_SUCCOS ||
        holidayIndex == HOSHANA_RABBA;
  }

  /// Returns if the day is _Shemini Atzeres_.
  bool isShminiAtzeres() {
    return getYomTovIndex() == SHEMINI_ATZERES;
  }

  /// Returns if the day is _Simchas Torah_. In Israel this is never true: _Simchas Torah_
  /// is the same day as [SHEMINI_ATZERES] there, and [getYomTovIndex] returns that.
  bool isSimchasTorah() {
    return getYomTovIndex() == SIMCHAS_TORAH;
  }

  /// Returns if the day is _Tisha B'Av_, moved to the 10th when the 9th is _Shabbos_.
  bool isTishaBav() {
    return getYomTovIndex() == TISHA_BEAV;
  }

  /// Returns if the day is _Purim_, which in a walled city is _Shushan Purim_ instead.
  ///
  /// See also [getIsMukafChoma].
  bool isPurim() {
    if (_isMukafChoma) {
      return getYomTovIndex() == SHUSHAN_PURIM;
    } else {
      return getYomTovIndex() == PURIM;
    }
  }

  /// Returns if the day is _Hoshana Rabba_.
  bool isHoshanaRabba() {
    return getYomTovIndex() == HOSHANA_RABBA;
  }

  /// Returns if the day is Rosh Chodesh. Rosh Hashana will return false
  ///
  /// Returns true if it is Rosh Chodesh. Rosh Hashana will return false
  bool isRoshChodesh() {
    // Rosh Hashana is not rosh chodesh. Elul never has 30 days
    return (getJewishDayOfMonth() == 1 &&
            getJewishMonth() != JewishDate.TISHREI) ||
        getJewishDayOfMonth() == 30;
  }

  /// Returns if the day is Shabbos and sunday is Rosh Chodesh.
  ///
  /// Returns true if it is Shabbos and sunday is Rosh Chodesh.
  bool isMacharChodesh() {
    return (getDayOfWeek() == _SATURDAY &&
        (getJewishDayOfMonth() == 30 || getJewishDayOfMonth() == 29));
  }

  /// Returns if the day is Shabbos Mevorchim.
  ///
  /// Returns true if it is Shabbos Mevorchim.
  bool isShabbosMevorchim() {
    return (getDayOfWeek() == _SATURDAY &&
        getJewishDayOfMonth() >= 23 &&
        getJewishDayOfMonth() <= 29 &&
        getJewishMonth() != JewishDate.ELUL);
  }

  /// Returns the int value of the Omer day or -1 if the day is not in the omer
  ///
  /// Returns The Omer count as an int or -1 if it is not a day of the Omer.
  int getDayOfOmer() {
    int omer = -1; // not a day of the Omer
    int month = getJewishMonth();
    int day = getJewishDayOfMonth();

    // if Nissan and second day of Pesach and on
    if (month == JewishDate.NISSAN && day >= 16) {
      omer = day - 15;
      // if Iyar
    } else if (month == JewishDate.IYAR) {
      omer = day + 15;
      // if Sivan and before Shavuos
    } else if (month == JewishDate.SIVAN && day < 6) {
      omer = day + 44;
    }
    return omer;
  }

  /// Returns the molad in Standard Time in Yerushalayim as a Date. The traditional calculation uses local time. This
  /// method subtracts 20.94 minutes (20 minutes and 56.496 seconds) from the local time (Har Habayis with a longitude
  /// of 35.2354° is 5.2354° away from the %15 timezone longitude) to get to standard time. This method
  /// intentionally uses standard time and not daylight savings time; formatting the
  /// result for a timezone is the caller's job.
  ///
  /// Returns the Date representing the moment of the molad in Yerushalayim standard time (GMT + 2)
  DateTime getMoladAsInstant() {
    JewishDate molad = getMolad();
    double moladSeconds = molad.getMoladChalakim() * 10.0 / 3.0;
    int seconds = moladSeconds.toInt();
    int microseconds = ((moladSeconds - seconds) * 1000000).toInt();
    final DateTime moladDate = molad.getLocalDate();
    DateTime moladTime = DateTime.utc(moladDate.year, moladDate.month,
            moladDate.day, molad.getMoladHours(), molad.getMoladMinutes(), seconds, 0, microseconds)
        .subtract(_yerushalayimStandardTimeOffset);
    return moladTime.subtract(_jerusalemLocalMeanTimeOffset);
  }

  /// Yerushalayim standard time, which the molad is reckoned in, is GMT+2 the year round.
  static const Duration _yerushalayimStandardTimeOffset = Duration(hours: 2);

  /// How far ahead of Yerushalayim standard time local mean time at Har Habayis runs.
  static const Duration _jerusalemLocalMeanTimeOffset =
      Duration(minutes: 20, seconds: 56, milliseconds: 496);

  /// Returns the earliest time of _Kiddush Levana_ calculated as 3 days after the molad. This method returns the time
  /// even if it is during the day when _Kiddush Levana_ can't be said. Callers of this method should consider
  /// displaying the next _tzais_ if the zman is between _alos_ and _tzais_.
  ///
  /// Returns the Date representing the moment 3 days after the molad.
  ///
  /// See also [ComplexZmanimCalendar.getTchilasZmanKidushLevana3Days].
  /// See also [ComplexZmanimCalendar.getTchilasZmanKidushLevana3Days].
  DateTime getTchilasZmanKidushLevana3Days() {
    return getMoladAsInstant()
        .add(const Duration(days: 3)); // 3 days after the molad
  }

  /// Returns the earliest time of Kiddush Levana calculated as 7 days after the molad as mentioned by the [Mechaber](http://en.wikipedia.org/wiki/Yosef_Karo). See the [Bach's](http://en.wikipedia.org/wiki/Yoel_Sirkis) opinion on this time. This method returns the time
  /// even if it is during the day when _Kiddush Levana_ can't be said. Callers of this method should consider
  /// displaying the next _tzais_ if the zman is between _alos_ and _tzais_.
  ///
  /// Returns the Date representing the moment 7 days after the molad.
  ///
  /// See also [ComplexZmanimCalendar.getTchilasZmanKidushLevana7Days].
  /// See also [ComplexZmanimCalendar.getTchilasZmanKidushLevana7Days].
  DateTime getTchilasZmanKidushLevana7Days() {
    return getMoladAsInstant()
        .add(const Duration(days: 7)); // 7 days after the molad
  }

  /// Returns the latest time of Kiddush Levana according to the [Maharil's](http://en.wikipedia.org/wiki/Yaakov_ben_Moshe_Levi_Moelin) opinion that it is calculated as
  /// halfway between molad and molad. This adds half the 29 days, 12 hours and 793 chalakim time between molad and
  /// molad (14 days, 18 hours, 22 minutes and 666 milliseconds) to the month's molad. This method returns the time
  /// even if it is during the day when _Kiddush Levana_ can't be said. Callers of this method should consider
  /// displaying _alos_ before this time if the zman is between _alos_ and _tzais_.
  ///
  /// Returns the Date representing the moment halfway between molad and molad.
  /// See also [getSofZmanKidushLevana15Days].
  /// See also [ComplexZmanimCalendar.getSofZmanKidushLevanaBetweenMoldos].
  /// See also [ComplexZmanimCalendar.getSofZmanKidushLevanaBetweenMoldos].
  DateTime getSofZmanKidushLevanaBetweenMoldos() {
    // add half the time between molad and molad (half of 29 days, 12 hours and 793 chalakim (44 minutes, 3.3
    // seconds), or 14 days, 18 hours, 22 minutes and 666 milliseconds)
    return getMoladAsInstant().add(const Duration(
        days: 14, hours: 18, minutes: 22, seconds: 1, milliseconds: 666));
  }

  /// Returns the latest time of Kiddush Levana calculated as 15 days after the molad. This is the opinion brought down
  /// in the Shulchan Aruch (Orach Chaim 426). It should be noted that some opinions hold that the
  /// [Rema](http://en.wikipedia.org/wiki/Moses_Isserles) who brings down the opinion of the [Maharil's](http://en.wikipedia.org/wiki/Yaakov_ben_Moshe_Levi_Moelin) of calculating
  /// [getSofZmanKidushLevanaBetweenMoldos] is of the opinion that Mechaber
  /// agrees to his opinion. Also see the Aruch Hashulchan. For additional details on the subject, See Rabbi Dovid
  /// Heber's very detailed writeup in Siman Daled (chapter 4) of [Shaarei Zmanim](http://www.worldcat.org/oclc/461326125). This method returns the time even if it is during
  /// the day when _Kiddush Levana_ can't be said. Callers of this method should consider displaying _alos_
  /// before this time if the zman is between _alos_ and _tzais_.
  ///
  /// Returns the Date representing the moment 15 days after the molad.
  /// See also [getSofZmanKidushLevanaBetweenMoldos].
  /// See also [ComplexZmanimCalendar.getSofZmanKidushLevana15Days].
  /// See also [ComplexZmanimCalendar.getSofZmanKidushLevana15Days].
  DateTime getSofZmanKidushLevana15Days() {
    return getMoladAsInstant()
        .add(const Duration(days: 15)); // 15 days after the molad
  }

  /// Returns the Daf Yomi (Bavli) for the date that the calendar is set to. See the
  /// [HebrewDateFormatter.formatDafYomiBavli] for the ability to format the daf in Hebrew or transliterated
  /// masechta names.
  ///
  /// Returns the daf as a [Daf]
  Daf getDafYomiBavli() {
    return YomiCalculator.getDafYomiBavli(this);
  }

  /// Returns the Daf Yomi (Yerushalmi) for the date that the calendar is set to. See the
  /// [HebrewDateFormatter.formatDafYomiYerushalmi] for the ability to format the daf in Hebrew or transliterated
  /// masechta names.
  ///
  /// Returns the daf as a [Daf]
  Daf? getDafYomiYerushalmi() {
    return YerushalmiYomiCalculator.getDafYomiYerushalmi(this);
  }

  /// Returns true if the current day is _Isru Chag_. The method returns true for the day following _Pesach_
  /// _Shavuos_ and _Succos_. It utilizes {@see #getInIsrael()} to return the proper date.
  ///
  /// Returns true if the current day is _Isru Chag_. The method returns true for the day following _Pesach_
  /// _Shavuos_ and _Succos_. It utilizes {@see #getInIsrael()} to return the proper date.
  bool isIsruChag() {
    int holidayIndex = getYomTovIndex();
    return holidayIndex == ISRU_CHAG;
  }

  /// Indicates whether some other object is "equal to" this one: an object of the same class set to the same
  /// absolute date and the same Israel setting.
  @override
  bool operator ==(Object object) {
    if (identical(this, object)) {
      return true;
    }
    if (object.runtimeType != runtimeType) {
      return false;
    }
    JewishCalendar jewishCalendar = object as JewishCalendar;
    return getAbsDate() == jewishCalendar.getAbsDate() &&
        getInIsrael() == jewishCalendar.getInIsrael();
  }

  /// Returns a hash code based on the absolute Gregorian date and the Israel setting.
  @override
  int get hashCode => 31 * getAbsDate().hashCode + getInIsrael().hashCode;

  /// A method that creates a [deep copy](http://en.wikipedia.org/wiki/Object_copy#Deep_copy) of the object.
  @override
  JewishCalendar clone() {
    return JewishCalendar.fromLocalDate(getLocalDate())
      ..setMoladHours(getMoladHours())
      ..setMoladMinutes(getMoladMinutes())
      ..setMoladChalakim(getMoladChalakim())
      ..setInIsrael(getInIsrael())
      ..setIsMukafChoma(getIsMukafChoma())
      ..setUseModernHolidays(isUseModernHolidays());
  }
}
