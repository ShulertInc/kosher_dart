import 'package:kosher_dart/kosher_dart.dart';
import 'package:test/test.dart';

JewishCalendar _on(int year, int month, int day) =>
    JewishCalendar.fromDateTime(DateTime(year, month, day));

String _unpointed(String text) =>
    text.replaceAll(RegExp('[֑-ׇ]'), '');

void main() {
  group('formatOmer', () {
    final formatter = HebrewDateFormatter()
      ..hebrewFormat = true
      ..longOmerFormat = true;

    test('the first day says one day, not two', () {
      expect(_on(2026, 4, 3).getDayOfOmer(), 1);
      expect(
        _unpointed(formatter.formatOmer(_on(2026, 4, 3))),
        'היום יום אחד לעמר:',
      );
    });

    test('the thirty-third day says thirty-three', () {
      expect(_on(2026, 5, 5).getDayOfOmer(), 33);
      expect(
        _unpointed(formatter.formatOmer(_on(2026, 5, 5))),
        'היום שלשה ושלשים יום לעמר, שהם ארבעה שבועות וחמשה ימים:',
      );
    });

    test('the last day is reachable', () {
      expect(_on(2026, 5, 21).getDayOfOmer(), 49);
      expect(
        _unpointed(formatter.formatOmer(_on(2026, 5, 21))),
        'היום תשעה וארבעים יום לעמר, שהם שבעה שבועות:',
      );
    });

    test('a day outside the omer says nothing', () {
      expect(formatter.formatOmer(_on(2026, 6, 15)), isEmpty);
    });
  });
}
