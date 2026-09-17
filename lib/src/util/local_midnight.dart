DateTime startOfLocalDay(DateTime day) {
  final DateTime target = DateTime.utc(day.year, day.month, day.day);
  Duration wallClockPastMidnight(DateTime instant) => DateTime.utc(instant.year,
          instant.month, instant.day, instant.hour, instant.minute,
          instant.second, instant.millisecond, instant.microsecond)
      .difference(target);
  DateTime midnight = day.subtract(wallClockPastMidnight(day));
  for (var attempt = 0; attempt < 3; attempt++) {
    final Duration drift = wallClockPastMidnight(midnight);
    if (drift == Duration.zero) break;
    final DateTime corrected = midnight.subtract(drift);
    if (drift.isNegative && wallClockPastMidnight(corrected) > Duration.zero) {
      return corrected;
    }
    midnight = corrected;
  }
  final DateTime earlier = midnight.subtract(const Duration(hours: 3));
  final Duration fallBack = earlier.timeZoneOffset - midnight.timeZoneOffset;
  if (fallBack > Duration.zero &&
      wallClockPastMidnight(midnight.subtract(fallBack)) == Duration.zero) {
    return midnight.subtract(fallBack);
  }
  return midnight;
}
