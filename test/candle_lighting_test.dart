import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('getCandleLighting answers every day, before sea level sunset', () {
    final ComprehensiveZmanimCalendar calendar = ComprehensiveZmanimCalendar.withGeoLocation(
        GeoLocation.withZoneId('Jerusalem', 31.7964453, 35.2453987, tz.UTC));
    calendar.setLocalDate(DateTime.utc(2021, 12, 25));
    expect(calendar.getCandleLighting(), calendar.getSeaLevelSunset()!.subtract(const Duration(minutes: 18)));
  });
}
