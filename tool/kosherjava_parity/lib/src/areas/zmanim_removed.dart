import '../kosherjava.g.dart' as kj;
import 'zman_getters.dart';

kj.Instant? instantAt(int? millis) => millis == null ? null : kj.Instant.ofEpochMilli(millis);

int? millisOrNull(kj.Instant? instant) {
  if (instant == null) return null;
  final millis = instant.toEpochMilli();
  instant.release();
  return millis;
}

kj.Instant? offsetMinutes(kj.Instant? instant, int minutes) {
  final millis = millisOrNull(instant);
  return millis == null ? null : instantAt(millis + minutes * 60000);
}

kj.Instant? sunriseBasedOnElevationSetting(JavaCalendar java) =>
    java.isUseElevation ? java.sunrise : java.seaLevelSunrise;

kj.Instant? sunsetBasedOnElevationSetting(JavaCalendar java) =>
    java.isUseElevation ? java.sunset : java.seaLevelSunset;

kj.Instant? kolEliyahu(JavaCalendar java) {
  final chatzos = millisOrNull(java.fixedLocalChatzosHayom);
  if (chatzos == null || millisOrNull(java.sunrise) == null) return null;
  final sunrise = millisOrNull(sunriseBasedOnElevationSetting(java));
  if (sunrise == null) return null;
  return instantAt(chatzos - (chatzos - sunrise) ~/ 2);
}

final removedZmanGetters = <ZmanGetter>[
  InstantZman('2.x getTzaisGeonim3Point65Degrees', (j) => j.getSunsetOffsetByDegrees(90 + 3.65),
      (d) => d.getTzaisGeonim3Point65Degrees()),
  InstantZman('2.x getTzaisGeonim3Point676Degrees', (j) => j.getSunsetOffsetByDegrees(90 + 3.676),
      (d) => d.getTzaisGeonim3Point676Degrees()),
  InstantZman('2.x getTzaisGeonim4Point37Degrees', (j) => j.getSunsetOffsetByDegrees(90 + 4.37),
      (d) => d.getTzaisGeonim4Point37Degrees()),
  InstantZman('2.x getTzaisGeonim4Point61Degrees', (j) => j.getSunsetOffsetByDegrees(90 + 4.61),
      (d) => d.getTzaisGeonim4Point61Degrees()),
  InstantZman('2.x getTzaisGeonim5Point88Degrees', (j) => j.getSunsetOffsetByDegrees(90 + 5.88),
      (d) => d.getTzaisGeonim5Point88Degrees()),
  InstantZman('2.x getSofZmanShmaFixedLocal', (j) => offsetMinutes(j.fixedLocalChatzosHayom, -180),
      (d) => d.getSofZmanShmaFixedLocal()),
  InstantZman('2.x getSofZmanTfilaFixedLocal', (j) => offsetMinutes(j.fixedLocalChatzosHayom, -120),
      (d) => d.getSofZmanTfilaFixedLocal()),
  InstantZman('2.x getSofZmanShmaKolEliyahu', kolEliyahu, (d) => d.getSofZmanShmaKolEliyahu()),
  InstantZman('2.x getMinchaGedolaBaalHatanyaGreaterThan30',
      (j) => j.getMinchaGedolaGreaterThan30(j.minchaGedolaBaalHatanya), (d) => d.getMinchaGedolaBaalHatanyaGreaterThan30()),
  InstantZman('getSunriseBaalHatanya', (j) => j.getSunriseOffsetByDegrees(90 + 1.583), (d) => d.getSunriseBaalHatanya()),
  InstantZman('getSunsetBaalHatanya', (j) => j.getSunsetOffsetByDegrees(90 + 1.583), (d) => d.getSunsetBaalHatanya()),
  InstantZman('getSunriseBasedOnElevationSetting / getElevationAdjustedSunrise', sunriseBasedOnElevationSetting,
      (d) => d.getElevationAdjustedSunrise()),
  InstantZman('getSunsetBasedOnElevationSetting / getElevationAdjustedSunset', sunsetBasedOnElevationSetting,
      (d) => d.getElevationAdjustedSunset()),
];
