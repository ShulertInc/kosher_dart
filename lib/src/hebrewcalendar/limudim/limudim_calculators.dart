import 'package:kosher_dart/src/hebrewcalendar/daf.dart';
import 'package:kosher_dart/src/hebrewcalendar/jewish_calendar.dart';
import 'package:kosher_dart/src/hebrewcalendar/jewish_date.dart';
import 'package:kosher_dart/src/hebrewcalendar/limudim/amud.dart';
import 'package:kosher_dart/src/hebrewcalendar/limudim/limudim_data.dart';
import 'package:kosher_dart/src/hebrewcalendar/limudim/mishna.dart';
import 'package:kosher_dart/src/hebrewcalendar/limudim/pirkei_avos_unit.dart';
import 'package:kosher_dart/src/hebrewcalendar/limudim/tehillim_unit.dart';

int _absDateOf(int year, int month, int day) =>
    JewishCalendar.initDate(year, month, day).getAbsDate();

int _absDateOfGregorian(int year, int month, int day) =>
    JewishCalendar.fromDateTime(DateTime(year, month, day)).getAbsDate();

/// Sunday is 1 and Shabbos is 7, as [JewishDate.getDayOfWeek] counts them.
int _dayOfWeek(int absDate) => (absDate % 7).abs() + 1;

/// Absolute date 1 is January 1, 1 on the proleptic Gregorian calendar, which is also
/// where Dart's `DateTime` starts counting.
JewishCalendar _calendarOfAbsDate(int absDate) => JewishCalendar.fromDateTime(
    DateTime.utc(1, 1, 1).add(Duration(days: absDate - 1)));

/// Calculates the [Daf Hashavua](https://en.wikipedia.org/wiki/Daf_Yomi) Bavli - one
/// daf a week, learned from Sunday through Shabbos.
///
/// The first cycle began on 6 March 2005.
class DafHashavuaBavliCalculator {
  /// The first day of the first cycle, 6 March 2005.
  static final DateTime cycleStartDay = DateTime(2005, 3, 6);

  /// The number of dafim in the Bavli as the schedule counts them.
  static const int WHOLE_SHAS_DAFIM = 2711;

  static final int _cycleStartAbsDate = _absDateOfGregorian(2005, 3, 6);

  /// Returns the daf of the week [calendar] falls in, or null before the first cycle.
  static Daf? getDafHashavuaBavli(JewishCalendar calendar) {
    final int offset = calendar.getAbsDate() - _cycleStartAbsDate;
    if (offset < 0) {
      return null;
    }
    // Every cycle begins on a Sunday, so the week a day falls in is its offset over
    // seven whatever cycle it is in.
    final int week = (offset % (WHOLE_SHAS_DAFIM * 7)) ~/ 7;
    return _dafAtOffset(week);
  }

  static Daf? _dafAtOffset(int offset) {
    int remaining = offset;
    for (int masechta = 0; masechta < dafRangePerMasechta.length; masechta++) {
      final List<int> range = dafRangePerMasechta[masechta];
      final int dafim = range[1] - range[0] + 1;
      if (remaining < dafim) {
        return Daf(masechta, range[0] + remaining);
      }
      remaining -= dafim;
    }
    return null;
  }
}

/// Calculates the Dirshu Amud Yomi Bavli - one amud a day.
///
/// The first cycle began on 16 October 2023.
class AmudYomiBavliDirshuCalculator {
  /// The first day of the first cycle, 16 October 2023.
  static final DateTime cycleStartDay = DateTime(2023, 10, 16);

  /// The number of amudim in the Bavli as the schedule counts them.
  static const int WHOLE_SHAS_AMUDIM = 5407;

  static final int _cycleStartAbsDate = _absDateOfGregorian(2023, 10, 16);

  /// Returns the amud of [calendar], or null before the first cycle.
  static Amud? getAmudYomiBavliDirshu(JewishCalendar calendar) {
    final int offset = calendar.getAbsDate() - _cycleStartAbsDate;
    if (offset < 0) {
      return null;
    }

    int remaining = offset % WHOLE_SHAS_AMUDIM;
    for (int masechta = 0; masechta < amudRangePerMasechta.length; masechta++) {
      final List<int> range = amudRangePerMasechta[masechta];
      final int start = range[0] * 2 + range[1];
      final int end = range[2] * 2 + range[3];
      final int amudim = end - start + 1;
      if (remaining < amudim) {
        final int index = start + remaining;
        return Amud(masechta, index ~/ 2,
            index.isEven ? AmudSide.ALEPH : AmudSide.BEIS);
      }
      remaining -= amudim;
    }
    return null;
  }
}

/// Calculates [Mishna Yomis](https://en.wikipedia.org/wiki/Mishnah_Yomit) - two
/// mishnayos a day, through all 4192 of them.
///
/// The first cycle began on 20 May 1947.
class MishnaYomisCalculator {
  /// The first day of the first cycle, 20 May 1947.
  static final DateTime cycleStartDay = DateTime(1947, 5, 20);

  /// The number of days a cycle runs for, two mishnayos a day.
  static const int CYCLE_DAYS = 2096;

  static final int _cycleStartAbsDate = _absDateOfGregorian(1947, 5, 20);

  /// Returns the two mishnayos of [calendar], or null before the first cycle.
  static Mishnas? getMishnaYomis(JewishCalendar calendar) {
    final int offset = calendar.getAbsDate() - _cycleStartAbsDate;
    if (offset < 0) {
      return null;
    }

    final int day = offset % CYCLE_DAYS;
    final Mishna? first = _mishnaAtOffset(day * 2);
    final Mishna? second = _mishnaAtOffset(day * 2 + 1);
    if (first == null || second == null) {
      return null;
    }
    return Mishnas(first, second);
  }

  static Mishna? _mishnaAtOffset(int offset) {
    int remaining = offset;
    for (int masechta = 0; masechta < mishnayosPerChapter.length; masechta++) {
      final List<int> chapters = mishnayosPerChapter[masechta];
      int inMasechta = 0;
      for (final int length in chapters) {
        inMasechta += length;
      }
      if (remaining < inMasechta) {
        for (int chapter = 0; chapter < chapters.length; chapter++) {
          if (remaining < chapters[chapter]) {
            return Mishna(masechta, chapter + 1, remaining + 1);
          }
          remaining -= chapters[chapter];
        }
        return null;
      }
      remaining -= inMasechta;
    }
    return null;
  }
}

/// Calculates the perek of _Pirkei Avos_ said on the Shabbos afternoons between Pesach
/// and Rosh Hashana.
///
/// The cycle runs from the day after Pesach to the last Shabbos before Rosh Hashana.
/// The six perakim are said in order three times over, and the weeks the season leaves
/// over at the end double up. No perek is said on the Shabbos of erev Tisha B'Av or of
/// Tisha B'Av, nor outside Israel on the second day of Shavuos.
class PirkeiAvosCalculator {
  /// Returns the perek or perakim of [calendar], or null on a day of the year the
  /// cycle does not cover.
  static PirkeiAvosUnit? getPirkeiAvos(JewishCalendar calendar) {
    final int date = calendar.getAbsDate();
    final int year = calendar.getJewishYear();
    // The cycle opens the day after Pesach, which is a day earlier in Israel.
    final int anchorDay = calendar.inIsrael ? 22 : 23;

    int cycleYear = year;
    int cycleStart = _absDateOf(year, JewishDate.NISSAN, anchorDay);
    if (date < cycleStart) {
      cycleYear = year - 1;
      cycleStart = _absDateOf(cycleYear, JewishDate.NISSAN, anchorDay);
    }

    // The cycle closes on the last Shabbos before Rosh Hashana.
    final int roshHashana = _absDateOf(cycleYear + 1, JewishDate.TISHREI, 1);
    final int cycleEnd = roshHashana - _dayOfWeek(roshHashana);
    if (date > cycleEnd) {
      return null;
    }

    // Each week of the cycle ends on its Shabbos. A week whose Shabbos is skipped does
    // not consume a perek, so the count only moves on for the weeks that say one.
    int weekStart = cycleStart;
    int week = 1;
    while (true) {
      final int weekEnd = weekStart + (7 - _dayOfWeek(weekStart));
      final bool skipped = _isSkipped(weekEnd, calendar.inIsrael);
      if (date <= weekEnd) {
        return skipped ? null : _unitForWeek(week, weekEnd, cycleEnd);
      }
      if (weekEnd >= cycleEnd) {
        return null;
      }
      weekStart = weekEnd + 1;
      if (!skipped) {
        week++;
      }
    }
  }

  static bool _isSkipped(int shabbos, bool inIsrael) {
    final JewishCalendar calendar = _calendarOfAbsDate(shabbos);
    final int month = calendar.getJewishMonth();
    final int day = calendar.getJewishDayOfMonth();

    // Erev Tisha B'Av and Tisha B'Av, wherever one is.
    if (month == JewishDate.AV && (day == 8 || day == 9)) {
      return true;
    }
    // The second day of Shavuos, which only the diaspora keeps.
    return !inIsrael && month == JewishDate.SIVAN && day == 7;
  }

  static PirkeiAvosUnit _unitForWeek(int week, int weekEnd, int cycleEnd) {
    // The first three times through, the six perakim are said one a week in order.
    if (week < 19) {
      return PirkeiAvosUnit.single((week - 1) % 6 + 1);
    }

    // The fourth time through has to fit whatever weeks are left, so the perakim
    // double up from the end backwards.
    final int weeksRemaining = ((cycleEnd - weekEnd) + 6) ~/ 7;
    switch (weeksRemaining) {
      case 0:
        return PirkeiAvosUnit.combined(5, 6);
      case 1:
        return PirkeiAvosUnit.combined(3, 4);
      case 2:
        return (week - 1) % 6 == 0
            ? PirkeiAvosUnit.combined(1, 2)
            : PirkeiAvosUnit.single((week - 1) % 6 + 1);
      case 3:
        return PirkeiAvosUnit.single(1);
      default:
        return PirkeiAvosUnit.single((week - 1) % 6 + 1);
    }
  }
}

/// Calculates the monthly Tehillim cycle, which divides the sefer across the days of
/// the Hebrew month.
class TehillimMonthlyCalculator {
  /// The last kapitel said on each day of the month.
  static const List<int> _lastPsalmOfDay = [
    9, 17, 22, 28, 34, 38, 43, 48, 54, 59, //
    65, 68, 71, 76, 78, 82, 87, 89, 96, 103,
    105, 107, 112, 118, 119, 119, 134, 139, 144, 150,
  ];

  /// Returns the Tehillim of [calendar]. Never null: every day of the month has some.
  static TehillimUnit getTehillimMonthly(JewishCalendar calendar) {
    final int day = calendar.getJewishDayOfMonth();

    // Kapitel 119 is long enough to take the two days to itself.
    if (day == 25) {
      return TehillimUnit.psalmVerses(119, 1, 96);
    }
    if (day == 26) {
      return TehillimUnit.psalmVerses(119, 97, 176);
    }

    final int start = day == 1 ? 1 : _lastPsalmOfDay[day - 2] + 1;
    int end = _lastPsalmOfDay[day - 1];

    // A month of 29 days has no thirtieth day to say the last of it on.
    if (day == 29 && calendar.getDaysInJewishMonth() == 29) {
      end = _lastPsalmOfDay[day];
    }
    return TehillimUnit.psalms(start, end);
  }
}
