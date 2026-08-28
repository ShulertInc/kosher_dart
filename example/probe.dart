import 'package:kosher_dart/kosher_dart.dart';

void main() {
  final c = JewishCalendar()..inIsrael = false;
  for (var d = 14; d <= 24; d++) {
    c.setJewishDate(5784, JewishDate.TISHREI, d);
    print('$d Tishrei dow=${c.getDayOfWeek()} assur=${c.isAssurBemelacha()} mutar=${c.isTonightMutarBemelacha()}');
  }
  for (var d = 10; d <= 16; d++) {
    c.setJewishDate(5784, JewishDate.CHESHVAN, d);
    print('$d Cheshvan dow=${c.getDayOfWeek()} assur=${c.isAssurBemelacha()} mutar=${c.isTonightMutarBemelacha()}');
  }
}
