import 'package:kosher_dart/kosher_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:test/test.dart';

/// Longyearbyen. The sun neither rises nor sets there for months at a time, which every
/// zman getter's doc comment says returns null.
ZmanimCalendar polarCalendar(DateTime date) =>
    ZmanimCalendar.withGeoLocation(GeoLocation.withZoneId('Longyearbyen', 78.22, 15.63, tz.UTC))..setLocalDate(date);

void main() {
  group('where the sun does not rise or set', () {
    // Midsummer, when it does not set, and midwinter, when it does not rise.
    final dates = [DateTime.utc(2026, 6, 21), DateTime.utc(2026, 12, 21)];

    test('the day-proportion zmanim return null instead of recursing', () {
      // Each of these used to call itself with sunrise and sunset, so where the sun did
      // neither it recursed on two nulls until the stack went.
      for (final date in dates) {
        final calendar = polarCalendar(date);

        expect(calendar.getSofZmanShma(null, null), isNull, reason: '$date');
        expect(calendar.getMinchaGedolaGRA(), isNull, reason: '$date');
        expect(calendar.getMinchaKetanaGRA(), isNull, reason: '$date');
        expect(calendar.getPlagHaminchaGRA(), isNull, reason: '$date');
      }
    });

    test('sunrise and sunset are both null, which makes the day undividable', () {
      for (final date in dates) {
        expect(polarCalendar(date).getSunrise(), isNull, reason: '$date');
        expect(polarCalendar(date).getSunset(), isNull, reason: '$date');
      }
    });
  });

  group('where the sun does rise and set', () {
    // Lakewood, on an ordinary day.
    final calendar = ZmanimCalendar.withGeoLocation(GeoLocation.withZoneId('Lakewood', 40.096, -74.222, tz.UTC))
      ..setLocalDate(DateTime.utc(2026, 9, 12));

    test('the day-proportion zmanim still answer, and in order', () {
      final minchaGedola = calendar.getMinchaGedolaGRA()!;
      final minchaKetana = calendar.getMinchaKetanaGRA()!;
      final plag = calendar.getPlagHaminchaGRA()!;
      final sunrise = calendar.getSunrise()!;
      final sunset = calendar.getSunset()!;

      expect(minchaGedola.isAfter(sunrise), isTrue);
      expect(minchaKetana.isAfter(minchaGedola), isTrue);
      expect(plag.isAfter(minchaKetana), isTrue);
      expect(plag.isBefore(sunset), isTrue);
    });

    test('passing the day explicitly gives the same answer as omitting it', () {
      final sunrise = calendar.getSunrise();
      final sunset = calendar.getSunset();

      expect(
        calendar.getPlagHamincha(sunrise, sunset),
        calendar.getPlagHaminchaGRA(),
      );
      expect(
        calendar.getMinchaGedola(sunrise, sunset),
        calendar.getMinchaGedolaGRA(),
      );
    });
  });
}
