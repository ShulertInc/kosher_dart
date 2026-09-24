/// Tests for Gregorian date navigation with corresponding Jewish date tracking.
///
/// Each test walks through every Gregorian month boundary in a given year,
/// stepping one day forward or backward across the boundary, and asserts that
/// both the resulting Gregorian fields and the corresponding Jewish calendar
/// fields are correct. This ensures that the dual-calendar state machine in
/// [JewishDate] stays consistent across month and year rollovers.
library;

import 'package:test/test.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() {
  // Steps forward one day across each Gregorian month boundary in 2011
  // (a non-leap year) and verifies the paired Jewish date values.
  test('gregorianForwardMonthToMonth', () async {
    DateTime dateTime = DateTime.utc(2011, DateTime.january, 31);

    JewishDate hebrewDate = JewishDate.fromLocalDate(dateTime);
    expect(hebrewDate.getJewishYear(), 5771);
    expect(hebrewDate.getJewishMonth(), 11);
    expect(hebrewDate.getJewishDayOfMonth(), 26);

    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 2);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 11);
    expect(hebrewDate.getJewishDayOfMonth(), 27);

    dateTime = DateTime.utc(2011, DateTime.february, 28);
    hebrewDate.setGregorianDate(dateTime);
    expect(hebrewDate.getLocalDate().month, 2);
    expect(hebrewDate.getLocalDate().day, 28);
    expect(hebrewDate.getJewishMonth(), 12);
    expect(hebrewDate.getJewishDayOfMonth(), 24);

    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 3);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 12);
    expect(hebrewDate.getJewishDayOfMonth(), 25);

    dateTime = DateTime.utc(2011, DateTime.march, 31);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 4);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 13);
    expect(hebrewDate.getJewishDayOfMonth(), 26);

    dateTime = DateTime.utc(2011, DateTime.april, 30);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 5);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 1);
    expect(hebrewDate.getJewishDayOfMonth(), 27);

    dateTime = DateTime.utc(2011, DateTime.may, 31);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 6);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 2);
    expect(hebrewDate.getJewishDayOfMonth(), 28);

    dateTime = DateTime.utc(2011, DateTime.june, 30);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 7);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 3);
    expect(hebrewDate.getJewishDayOfMonth(), 29);

    dateTime = DateTime.utc(2011, DateTime.july, 31);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 8);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 5);
    expect(hebrewDate.getJewishDayOfMonth(), 1);

    dateTime = DateTime.utc(2011, DateTime.august, 31);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 9);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 6);
    expect(hebrewDate.getJewishDayOfMonth(), 2);

    dateTime = DateTime.utc(2011, DateTime.september, 30);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 10);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 7);
    expect(hebrewDate.getJewishDayOfMonth(), 3);

    dateTime = DateTime.utc(2011, DateTime.october, 31);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 11);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishYear(), 5772);
    expect(hebrewDate.getJewishMonth(), 8);
    expect(hebrewDate.getJewishDayOfMonth(), 4);

    dateTime = DateTime.utc(2011, DateTime.november, 30);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().month, 12);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 9);
    expect(hebrewDate.getJewishDayOfMonth(), 5);

    dateTime = DateTime.utc(2011, DateTime.december, 31);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.plusDays(1);
    expect(hebrewDate.getLocalDate().year, 2012);
    expect(hebrewDate.getLocalDate().month, 1);
    expect(hebrewDate.getLocalDate().day, 1);
    expect(hebrewDate.getJewishMonth(), 10);
    expect(hebrewDate.getJewishDayOfMonth(), 6);
  });

  // Steps backward one day across each Gregorian month boundary in 2010/2011
  // and verifies the paired Jewish date values.
  test('gregorianBackwardMonthToMonth', () async {
    DateTime dateTime = DateTime.utc(2011, DateTime.january, 1);

    JewishDate hebrewDate = JewishDate.fromLocalDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().year, 2010);
    expect(hebrewDate.getLocalDate().month, 12);
    expect(hebrewDate.getLocalDate().day, 31);
    expect(hebrewDate.getJewishMonth(), 10);
    expect(hebrewDate.getJewishDayOfMonth(), 24);

    dateTime = DateTime.utc(2010, DateTime.december, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 11);
    expect(hebrewDate.getLocalDate().day, 30);
    expect(hebrewDate.getJewishMonth(), 9);
    expect(hebrewDate.getJewishDayOfMonth(), 23);

    dateTime = DateTime.utc(2010, DateTime.november, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 10);
    expect(hebrewDate.getLocalDate().day, 31);
    expect(hebrewDate.getJewishMonth(), 8);
    expect(hebrewDate.getJewishDayOfMonth(), 23);

    dateTime = DateTime.utc(2010, DateTime.october, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 9);
    expect(hebrewDate.getLocalDate().day, 30);
    expect(hebrewDate.getJewishMonth(), 7);
    expect(hebrewDate.getJewishDayOfMonth(), 22);

    dateTime = DateTime.utc(2010, DateTime.september, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 8);
    expect(hebrewDate.getLocalDate().day, 31);
    expect(hebrewDate.getJewishYear(), 5770);
    expect(hebrewDate.getJewishMonth(), 6);
    expect(hebrewDate.getJewishDayOfMonth(), 21);

    dateTime = DateTime.utc(2010, DateTime.august, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 7);
    expect(hebrewDate.getLocalDate().day, 31);
    expect(hebrewDate.getJewishMonth(), 5);
    expect(hebrewDate.getJewishDayOfMonth(), 20);

    dateTime = DateTime.utc(2010, DateTime.july, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 6);
    expect(hebrewDate.getLocalDate().day, 30);
    expect(hebrewDate.getJewishMonth(), 4);
    expect(hebrewDate.getJewishDayOfMonth(), 18);

    dateTime = DateTime.utc(2010, DateTime.june, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 5);
    expect(hebrewDate.getLocalDate().day, 31);
    expect(hebrewDate.getJewishMonth(), 3);
    expect(hebrewDate.getJewishDayOfMonth(), 18);

    dateTime = DateTime.utc(2010, DateTime.may, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 4);
    expect(hebrewDate.getLocalDate().day, 30);
    expect(hebrewDate.getJewishMonth(), 2);
    expect(hebrewDate.getJewishDayOfMonth(), 16);

    dateTime = DateTime.utc(2010, DateTime.april, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 3);
    expect(hebrewDate.getLocalDate().day, 31);
    expect(hebrewDate.getJewishMonth(), 1);
    expect(hebrewDate.getJewishDayOfMonth(), 16);

    dateTime = DateTime.utc(2010, DateTime.march, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 2);
    expect(hebrewDate.getLocalDate().day, 28);
    expect(hebrewDate.getJewishMonth(), 12);
    expect(hebrewDate.getJewishDayOfMonth(), 14);

    dateTime = DateTime.utc(2010, DateTime.february, 1);
    hebrewDate.setGregorianDate(dateTime);
    hebrewDate.minusDays(1);
    expect(hebrewDate.getLocalDate().month, 1);
    expect(hebrewDate.getLocalDate().day, 31);
    expect(hebrewDate.getJewishMonth(), 11);
    expect(hebrewDate.getJewishDayOfMonth(), 16);
  });
}
