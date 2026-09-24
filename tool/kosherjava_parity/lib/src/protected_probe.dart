import 'package:kosher_dart/kosher_dart.dart' as kd;

class ProtectedProbe extends kd.ComprehensiveZmanimCalendar {
  ProtectedProbe() : super();

  DateTime midnightLastNight(kd.AstronomicalCalendar calendar) => calendar.getMidnightLastNight();

  DateTime midnightTonight(kd.AstronomicalCalendar calendar) => calendar.getMidnightTonight();

  DateTime adjustedLocalDate(kd.AstronomicalCalendar calendar) => calendar.getAdjustedLocalDate();

  DateTime? sunriseBasedOnElevationSetting(kd.ZmanimCalendar calendar) => calendar.getSunriseBasedOnElevationSetting();

  DateTime? sunsetBasedOnElevationSetting(kd.ZmanimCalendar calendar) => calendar.getSunsetBasedOnElevationSetting();

  DateTime? sunriseBaalHatanya(kd.ZmanimCalendar calendar) => calendar.getSunriseBaalHatanya();

  DateTime? sunsetBaalHatanya(kd.ZmanimCalendar calendar) => calendar.getSunsetBaalHatanya();
}
