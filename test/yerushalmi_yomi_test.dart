/// Tests for Daf Yomi Yerushalmi, whose count used to be a day out everywhere west of
/// Greenwich: it measured the days since the cycle began by subtracting a local
/// `DateTime` from a UTC one, and truncated the fractional day that left behind.
library;

import 'package:kosher_dart/kosher_dart.dart';
import 'package:test/test.dart';

Daf dafOn(int year, int month, int day) =>
    JewishCalendar.fromDateTime(DateTime(year, month, day)).getDafYomiYerushalmi();

void expectDaf(Daf daf, String masechta, int page) {
  expect(daf.getYerushlmiMasechtaTransliterated(), masechta);
  expect(daf.getDaf(), page);
}

void main() {
  test('the first cycle opens on its first day rather than throwing', () {
    expectDaf(dafOn(1980, 2, 2), 'Berachos', 1);
    expectDaf(dafOn(1980, 2, 3), 'Berachos', 2);
  });

  test('a day before the first cycle is an error', () {
    expect(() => dafOn(1980, 2, 1), throwsArgumentError);
  });

  test('a masechta ends on its last daf and the next one starts the day after', () {
    // Berachos has 68 blatt, Peah 37, Demai 34. The count is zero based, so the day
    // whose offset equals the blatt count belongs to the next masechta - it used to
    // report a Demai 35 that does not exist.
    expectDaf(dafOn(1980, 6, 19), 'Demai', 34);
    expectDaf(dafOn(1980, 6, 20), 'Kilayim', 1);
  });

  test('a new cycle starts the day after the old one ends', () {
    expectDaf(dafOn(2022, 11, 13), 'Nidah', 13);
    expectDaf(dafOn(2022, 11, 14), 'Berachos', 1);
  });

  test('Shevuos comes before Sanhedrin, as their blatt counts always said', () {
    // The transliterated names had these two the wrong way round, so the daf number
    // was right and the masechta printed with it was not.
    expectDaf(dafOn(1983, 11, 29), 'Shevuos', 14);
    expectDaf(dafOn(1984, 1, 14), 'Sanhedrin', 7);
  });

  test('there is no daf on Yom Kippur or Tisha B Av', () {
    // Yom Kippur 5785 and the Tisha B'Av of 5785, which is fasted on the Sunday.
    expect(dafOn(2024, 10, 12).getDaf(), 0);
    expect(dafOn(2025, 8, 3).getDaf(), 0);
  });

  test('the days with no daf do not advance the count', () {
    final Daf before = dafOn(2024, 10, 11);
    final Daf after = dafOn(2024, 10, 13);

    expect(after.getDaf(), before.getDaf() + 1);
    expect(after.getYerushlmiMasechtaTransliterated(),
        before.getYerushlmiMasechtaTransliterated());
  });
}
