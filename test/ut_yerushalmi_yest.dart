/// Tests for [YerushalmiYomiCalculator] via [JewishCalendar.getDafYomiYerushalmi].
///
/// The Yerushalmi (Jerusalem Talmud) Daf Yomi cycle is a daily schedule for
/// studying the Jerusalem Talmud. Each test picks a known Jewish date and
/// verifies that the returned [Daf] (tractate number + page number) matches
/// the expected value for that day in the cycle.
///
/// The [HebrewDateFormatter] is used only for printing; it does not affect
/// the assertions.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  HebrewDateFormatter hdf = HebrewDateFormatter();
  hdf.setHebrewFormat(true);

  // 10 Elul 5777 → tractate 29 (Horayot), daf 8.
  test('testCorrectDaf1', () async {
    JewishCalendar jewishCalendar = JewishCalendar.fromJewishDate(5777, 6, 10);
    expect(jewishCalendar.getDafYomiYerushalmi()!.getDaf(), 8);
    expect(jewishCalendar.getDafYomiYerushalmi()!.getMasechtaNumber(), 29);
    print(hdf.formatDafYomiYerushalmi(jewishCalendar.getDafYomiYerushalmi()));
  });

  // 1 Kislev 5744 → tractate 32 (Niddah), daf 26.
  test('testCorrectDaf2', () async {
    JewishCalendar jewishCalendar = JewishCalendar.fromJewishDate(5744, 9, 1);
    expect(jewishCalendar.getDafYomiYerushalmi()!.getDaf(), 26);
    expect(jewishCalendar.getDafYomiYerushalmi()!.getMasechtaNumber(), 32);
    print(hdf.formatDafYomiYerushalmi(jewishCalendar.getDafYomiYerushalmi()));
  });

  // 1 Sivan 5782 → tractate 33 (Kinnim), daf 15.
  test('testCorrectDaf3', () async {
    JewishCalendar jewishCalendar = JewishCalendar.fromJewishDate(5782, 3, 1);
    expect(jewishCalendar.getDafYomiYerushalmi()!.getDaf(), 15);
    expect(jewishCalendar.getDafYomiYerushalmi()!.getMasechtaNumber(), 33);
    print(hdf.formatDafYomiYerushalmi(jewishCalendar.getDafYomiYerushalmi()));
  });

  test('testCorrectSpecialDate', () async {
    JewishCalendar jewishCalendar = JewishCalendar.fromJewishDate(5775, 7, 10);
    expect(jewishCalendar.getDafYomiYerushalmi(), isNull);
    expect(hdf.formatDafYomiYerushalmi(jewishCalendar.getDafYomiYerushalmi()),
        Daf(39, 0).getYerushalmiMasechta());
  });
}
