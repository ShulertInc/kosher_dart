import 'package:kosherjava_parity/src/area.dart';
import 'package:kosherjava_parity/src/cli.dart';
import 'package:kosherjava_parity/src/areas/calculators.dart';
import 'package:kosherjava_parity/src/areas/calendar.dart';
import 'package:kosherjava_parity/src/areas/formatter.dart';
import 'package:kosherjava_parity/src/areas/geo.dart';
import 'package:kosherjava_parity/src/areas/tefila.dart';
import 'package:kosherjava_parity/src/areas/zmanim.dart';
import 'package:kosherjava_parity/src/areas/zmanim_formatter.dart';
import 'package:kosherjava_parity/src/zones.dart';

final areaFactories = <String, Area Function(Zones)>{
  'zmanim': ZmanimArea.new,
  'calendar': CalendarArea.new,
  'tefila': TefilaArea.new,
  'formatter': FormatterArea.new,
  'geo': GeoArea.new,
  'calculators': CalculatorsArea.new,
  'zmanim-formatter': ZmanimFormatterArea.new,
};

void main(List<String> arguments) => runParity(arguments, areaFactories);
