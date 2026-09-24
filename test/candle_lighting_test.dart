import 'package:intl/intl.dart';
import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:timezone/timezone.dart' as tz;

GeoLocation _location(String name, double latitude, double longitude) =>
    GeoLocation.withZoneId(name, latitude, longitude, tz.UTC);

void main() {
  final ComprehensiveZmanimCalendar calendar =
      ComprehensiveZmanimCalendar.withGeoLocation(_location('Jerusalem', 31.7964453, 35.2453987));

  test('testWeekend', () {
    calendar.setLocalDate(DateTime.utc(2021, 12, 24));
    expect(_getCandleLighting(calendar), '14:22');
    calendar.setLocalDate(DateTime.utc(2021, 12, 25));
    expect(_getCandleLighting(calendar), null);
  });

  test('getCandleLighting answers every day, before sea level sunset', () {
    calendar.setLocalDate(DateTime.utc(2021, 12, 25));
    expect(calendar.getCandleLighting(), calendar.getSeaLevelSunset()!.subtract(const Duration(minutes: 18)));
  });

  test('testYomTov', () {
    calendar.setLocalDate(DateTime.utc(2021, 9, 6));
    expect(_getCandleLighting(calendar), '15:38');
    calendar.setLocalDate(DateTime.utc(2021, 9, 7));
    expect(_getCandleLighting(calendar), '16:11');
    calendar.setLocalDate(DateTime.utc(2020, 9, 19));
    expect(_getCandleLighting(calendar), '15:55');

    calendar.setGeoLocation(_location('NY', 40.7127, -74.0059));
    calendar.setLocalDate(DateTime.utc(2023, 4, 6));
    expect(_getCandleLighting(calendar), '23:46');
  });

  test('testChanukah', () {
    calendar.setGeoLocation(_location('Jerusalem', 31.7964453, 35.2453987));
    calendar.setLocalDate(DateTime.utc(2021, 11, 30));
    expect(_getCandleLighting(calendar), '14:53');
  });

  test('testCholHamoed', () {
    calendar.setLocalDate(DateTime.utc(2021, 9, 23));
    expect(_getCandleLighting(calendar), null);
  });

  test('testFirstDayOfShavuosOnFriday', () {
    calendar.setGeoLocation(_location('NY', 40.7128, -74.0060));

    for (final date in [DateTime.utc(2026, 5, 22), DateTime.utc(2027, 6, 11)]) {
      calendar.setLocalDate(date);

      final JewishCalendar jewishCalendar = JewishCalendar.fromLocalDate(date);
      expect(jewishCalendar.getDayOfWeek(), 6, reason: 'test date is a Friday');
      expect(jewishCalendar.isErevYomTovSheni(), isTrue, reason: 'and the first day of Shavuos');

      final DateTime? candleLighting = calendar.getCandleLightingTonight();
      final DateTime sunset = calendar.getSeaLevelSunset()!;

      expect(candleLighting!.isBefore(sunset), isTrue, reason: 'candles must be lit before sunset on erev Shabbos');
      expect(candleLighting, sunset.subtract(const Duration(minutes: 18)));
    }
  });

  test('testErevYomTovSheniMidweekStillUsesTzais', () {
    final DateTime date = DateTime.utc(2026, 4, 2);
    calendar.setGeoLocation(_location('NY', 40.7128, -74.0060));
    calendar.setLocalDate(date);

    expect(JewishCalendar.fromLocalDate(date).isErevYomTovSheni(), isTrue);
    expect(calendar.getCandleLightingTonight()!.isAfter(calendar.getSeaLevelSunset()!), isTrue,
        reason: 'lit from an existing flame once the stars are out');
  });

  test('in Israel the first day of yom tov has no lighting, Rosh Hashana aside', () {
    calendar.setGeoLocation(_location('Jerusalem', 31.7964453, 35.2453987));

    calendar.setLocalDate(DateTime.utc(2026, 4, 2));
    expect(calendar.getCandleLightingTonight(), isNotNull);
    expect(calendar.getCandleLightingTonight(inIsrael: true), isNull);

    calendar.setLocalDate(DateTime.utc(2026, 4, 3));
    final DateTime sunset = calendar.getSeaLevelSunset()!;
    expect(calendar.getCandleLightingTonight(inIsrael: true), sunset.subtract(const Duration(minutes: 18)));

    calendar.setLocalDate(DateTime.utc(2021, 9, 7));
    expect(calendar.getCandleLightingTonight(inIsrael: true), calendar.getCandleLightingTonight());
  });
}

String? _getCandleLighting(ComprehensiveZmanimCalendar calendar) {
  final DateTime? candleLighting = calendar.getCandleLightingTonight();
  return candleLighting != null ? DateFormat('HH:mm').format(candleLighting.toUtc()) : null;
}
