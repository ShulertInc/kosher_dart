import 'report.dart';
import 'zones.dart';

abstract class Area {
  Area(this.zones);

  final Zones zones;

  String get name;

  void run(int seed, Iterable<int> indexes, Report report);
}
