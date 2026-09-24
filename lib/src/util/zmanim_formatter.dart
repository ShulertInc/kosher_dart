import 'package:timezone/timezone.dart';

import '../astronomical_calendar.dart';
import '../comprehensive_zmanim_calendar.dart';
import '../zmanim_calendar.dart';
import 'date_time_formatter.dart';
import 'java_double.dart';
import 'zman.dart';

typedef _Getter = (String, Object? Function(AstronomicalCalendar));

class ZmanimFormatter {
  static const int SEXAGESIMAL_XSD_FORMAT = 0;

  static const int SEXAGESIMAL_FORMAT = 1;

  static const int SEXAGESIMAL_SECONDS_FORMAT = 2;

  static const int SEXAGESIMAL_MILLIS_FORMAT = 3;

  static const int XSD_DURATION_FORMAT = 4;

  ZmanimFormatter(Location? zoneId)
      : this.withFormat(SEXAGESIMAL_SECONDS_FORMAT, DateTimeFormatter.ofPattern('h:mm:ss'), zoneId);

  ZmanimFormatter.withFormat(int timeFormat, DateTimeFormatter dateTimeFormatter, Location? zoneId) {
    setZoneId(zoneId);
    setTimeFormat(timeFormat);
    setDateTimeFormatter(dateTimeFormatter.withZone(zoneId));
  }

  bool _prependZeroHours = false;

  bool _useSeconds = false;

  bool _useMillis = false;

  int _timeFormat = SEXAGESIMAL_SECONDS_FORMAT;

  late DateTimeFormatter _dateTimeFormatter;

  Location? _zoneId;

  Location? getZoneId() => _zoneId;

  void setZoneId(Location? zoneId) => _zoneId = zoneId;

  void setTimeFormat(int format) {
    _timeFormat = format;
    switch (format) {
      case SEXAGESIMAL_XSD_FORMAT:
        _setSettings(true, true, true);
      case SEXAGESIMAL_FORMAT:
        _setSettings(false, false, false);
      case SEXAGESIMAL_SECONDS_FORMAT:
        _setSettings(false, true, false);
      case SEXAGESIMAL_MILLIS_FORMAT:
        _setSettings(false, true, true);
      case XSD_DURATION_FORMAT:
        break;
      default:
        throw ArgumentError('An invalid time format of $format was set. '
            'Please see the documentation for the list of valid formats.');
    }
  }

  void setDateTimeFormatter(DateTimeFormatter dateTimeFormatter) => _dateTimeFormatter = dateTimeFormatter;

  DateTimeFormatter getDateTimeFormatter() => _dateTimeFormatter;

  void _setSettings(bool prependZeroHours, bool useSeconds, bool useMillis) {
    _prependZeroHours = prependZeroHours;
    _useSeconds = useSeconds;
    _useMillis = useMillis;
  }

  String format(Duration? duration) {
    final (seconds, nanos) = spanOfMicros(duration?.inMicroseconds ?? 0);
    return _format(seconds, nanos);
  }

  String _format(int seconds, int nanos) {
    if (_timeFormat == XSD_DURATION_FORMAT) return javaDurationText(seconds, nanos);
    final negative = seconds < 0;
    var absSeconds = seconds;
    var absNanos = nanos;
    if (negative) {
      absSeconds = nanos > 0 ? -seconds - 1 : -seconds;
      absNanos = nanos > 0 ? 1000000000 - nanos : 0;
    }
    if (absSeconds > 9223372036854775) throw ArgumentError('The duration is too long to format');
    final sb = StringBuffer(negative ? '-' : '');
    final hours = (absSeconds ~/ 3600).toString();
    sb.write(_prependZeroHours ? hours.padLeft(2, '0') : hours);
    sb.write(':');
    sb.write((absSeconds ~/ 60 % 60).toString().padLeft(2, '0'));
    if (_useSeconds) {
      sb.write(':');
      sb.write((absSeconds % 60).toString().padLeft(2, '0'));
    }
    if (_useMillis) {
      sb.write('.');
      sb.write((absNanos ~/ 1000000).toString().padLeft(3, '0'));
    }
    return sb.toString();
  }

  String formatInstant(DateTime instant, Location zoneId) => getDateTimeFormatter().format(instant, zoneId);

  String formatXSDateTime(DateTime instant) {
    final zoneId = getZoneId();
    if (zoneId == null) throw ArgumentError('Unable to format an instant without a zone');
    return DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ssXXX").withZone(zoneId).format(instant);
  }

  String formatXSDDurationTime(Duration? duration) {
    if (duration == null) return '';
    final (seconds, nanos) = spanOfMicros(duration.inMicroseconds);
    return javaDurationText(seconds, nanos);
  }

  static String toXML(AstronomicalCalendar astronomicalCalendar) {
    final metadata = _Metadata(astronomicalCalendar);
    final sb = StringBuffer('<${metadata.tag}');
    sb.write(' date="${metadata.date}"');
    sb.write(' type="${metadata.type}"');
    sb.write(' algorithm="${metadata.algorithm}"');
    sb.write(' location="${metadata.location}"');
    sb.write(' latitude="${metadata.latitude}"');
    sb.write(' longitude="${metadata.longitude}"');
    sb.write(' elevation="${metadata.elevation}"');
    sb.write(' timeZoneName="${metadata.timeZoneName}"');
    sb.write(' timeZoneID="${metadata.timeZoneId}"');
    sb.write(' timeZoneOffset="${metadata.timeZoneOffset}"');
    sb.write('>\n');
    final values = _Values(astronomicalCalendar);
    for (final zman in values.dates) {
      sb.write('\t<${zman.getLabel()}>${metadata.instantText(zman.getZman()!)}</${zman.getLabel()}>\n');
    }
    for (final zman in values.durations) {
      sb.write('\t<${zman.getLabel()}>${_durationText(zman.getDuration()!)}</${zman.getLabel()}>\n');
    }
    for (final label in values.missing) {
      sb.write('\t<$label>N/A</$label>\n');
    }
    if (metadata.tag.isNotEmpty) sb.write('</${metadata.tag}>');
    return sb.toString();
  }

  static String toJSON(AstronomicalCalendar astronomicalCalendar) {
    final metadata = _Metadata(astronomicalCalendar);
    final sb = StringBuffer('{\n"metadata":{\n');
    sb.write('\t"date":"${metadata.date}",\n');
    sb.write('\t"type":"${metadata.type}",\n');
    sb.write('\t"algorithm":"${metadata.algorithm}",\n');
    sb.write('\t"location":"${metadata.location}",\n');
    sb.write('\t"latitude":"${metadata.latitude}",\n');
    sb.write('\t"longitude":"${metadata.longitude}",\n');
    sb.write('\t"elevation":"${metadata.elevation}",\n');
    sb.write('\t"timeZoneName":"${metadata.timeZoneName}",\n');
    sb.write('\t"timeZoneID":"${metadata.timeZoneId}",\n');
    sb.write('\t"timeZoneOffset":"${metadata.timeZoneOffset}"');
    sb.write('},\n"${metadata.tag}":{\n');
    final values = _Values(astronomicalCalendar);
    for (final zman in values.dates) {
      sb.write('\t"${zman.getLabel()}":"${metadata.instantText(zman.getZman()!)}",\n');
    }
    for (final zman in values.durations) {
      sb.write('\t"${zman.getLabel()}":"${_durationText(zman.getDuration()!)}",\n');
    }
    for (final label in values.missing) {
      sb.write('\t"$label":"N/A",\n');
    }
    final text = sb.toString();
    return '${text.substring(0, text.length - 2)}}\n}';
  }

  static List<_Getter> _gettersOf(AstronomicalCalendar calendar) {
    final getters = [
      ..._astronomicalGetters,
      if (calendar is ZmanimCalendar) ..._zmanimGetters,
      if (calendar is ComprehensiveZmanimCalendar) ..._complexGetters,
    ];
    return getters..sort((first, second) => first.$1.compareTo(second.$1));
  }

  static final List<_Getter> _astronomicalGetters = [
    ('BeginAstronomicalTwilight', (calendar) => calendar.getBeginAstronomicalTwilight()),
    ('BeginCivilTwilight', (calendar) => calendar.getBeginCivilTwilight()),
    ('BeginNauticalTwilight', (calendar) => calendar.getBeginNauticalTwilight()),
    ('EndAstronomicalTwilight', (calendar) => calendar.getEndAstronomicalTwilight()),
    ('EndCivilTwilight', (calendar) => calendar.getEndCivilTwilight()),
    ('EndNauticalTwilight', (calendar) => calendar.getEndNauticalTwilight()),
    ('SeaLevelSunrise', (calendar) => calendar.getSeaLevelSunrise()),
    ('SeaLevelSunset', (calendar) => calendar.getSeaLevelSunset()),
    ('SolarMidnight', (calendar) => calendar.getSolarMidnight()),
    ('SunTransit', (calendar) => calendar.getSunTransit()),
    ('Sunrise', (calendar) => calendar.getSunrise()),
    ('Sunset', (calendar) => calendar.getSunset()),
    ('TemporalHour', (calendar) => calendar.getTemporalHour()),
  ];

  static final List<_Getter> _zmanimGetters = [
    ('Alos16Point1Degrees', (calendar) => (calendar as ZmanimCalendar).getAlos16Point1Degrees()),
    ('Alos72Minutes', (calendar) => (calendar as ZmanimCalendar).getAlos72Minutes()),
    ('CandleLighting', (calendar) => (calendar as ZmanimCalendar).getCandleLighting()),
    ('ChatzosHalayla', (calendar) => (calendar as ZmanimCalendar).getChatzosHalayla()),
    ('ChatzosHayom', (calendar) => (calendar as ZmanimCalendar).getChatzosHayom()),
    ('ChatzosHayomAsHalfDay', (calendar) => (calendar as ZmanimCalendar).getChatzosHayomAsHalfDay()),
    ('MinchaGedolaGRA', (calendar) => (calendar as ZmanimCalendar).getMinchaGedolaGRA()),
    ('MinchaKetanaGRA', (calendar) => (calendar as ZmanimCalendar).getMinchaKetanaGRA()),
    ('PlagHaminchaGRA', (calendar) => (calendar as ZmanimCalendar).getPlagHaminchaGRA()),
    ('ShaahZmanis72Minutes', (calendar) => (calendar as ZmanimCalendar).getShaahZmanis72Minutes()),
    ('ShaahZmanisGRA', (calendar) => (calendar as ZmanimCalendar).getShaahZmanisGRA()),
    ('SofZmanShmaGRA', (calendar) => (calendar as ZmanimCalendar).getSofZmanShmaGRA()),
    ('SofZmanShmaMGA72Minutes', (calendar) => (calendar as ZmanimCalendar).getSofZmanShmaMGA72Minutes()),
    ('SofZmanTfilaGRA', (calendar) => (calendar as ZmanimCalendar).getSofZmanTfilaGRA()),
    ('SofZmanTfilaMGA72Minutes', (calendar) => (calendar as ZmanimCalendar).getSofZmanTfilaMGA72Minutes()),
    ('Tzais72Minutes', (calendar) => (calendar as ZmanimCalendar).getTzais72Minutes()),
    ('TzaisGeonim8Point5Degrees', (calendar) => (calendar as ZmanimCalendar).getTzaisGeonim8Point5Degrees()),
  ];

  static final List<_Getter> _complexGetters = [
    ('Alos120Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos120Minutes()),
    ('Alos120Zmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos120Zmanis()),
    ('Alos18Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos18Degrees()),
    ('Alos19Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos19Degrees()),
    ('Alos19Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos19Point8Degrees()),
    ('Alos26Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos26Degrees()),
    ('Alos60Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos60Minutes()),
    ('Alos72Zmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos72Zmanis()),
    ('Alos90Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos90Minutes()),
    ('Alos90Zmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos90Zmanis()),
    ('Alos96Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos96Minutes()),
    ('Alos96Zmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlos96Zmanis()),
    ('AlosBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getAlosBaalHatanya()),
    ('BainHashmashosRT13Point24Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosRT13Point24Degrees()),
    ('BainHashmashosRT13Point5MinutesBefore7Point083Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosRT13Point5MinutesBefore7Point083Degrees()),
    ('BainHashmashosRT2Stars', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosRT2Stars()),
    ('BainHashmashosRT58Point5Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosRT58Point5Minutes()),
    ('BainHashmashosYereim13Point5Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosYereim13Point5Minutes()),
    ('BainHashmashosYereim16Point875Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosYereim16Point875Minutes()),
    ('BainHashmashosYereim18Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosYereim18Minutes()),
    ('BainHashmashosYereim2Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosYereim2Point1Degrees()),
    ('BainHashmashosYereim2Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosYereim2Point8Degrees()),
    ('BainHashmashosYereim3Point05Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getBainHashmashosYereim3Point05Degrees()),
    ('FixedLocalChatzosHayom', (calendar) => (calendar as ComprehensiveZmanimCalendar).getFixedLocalChatzosHayom()),
    ('MinchaGedola16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaGedola16Point1Degrees()),
    ('MinchaGedola30Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaGedola30Minutes()),
    ('MinchaGedola72Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaGedola72Minutes()),
    ('MinchaGedolaAhavatShalom', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaGedolaAhavatShalom()),
    ('MinchaGedolaAteretTorah', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaGedolaAteretTorah()),
    ('MinchaGedolaBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaGedolaBaalHatanya()),
    ('MinchaGedolaGRAFixedLocalChatzos30Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaGedolaGRAFixedLocalChatzos30Minutes()),
    ('MinchaGedolaGRAGreaterThan30', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaGedolaGRAGreaterThan30()),
    ('MinchaKetana16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaKetana16Point1Degrees()),
    ('MinchaKetana72Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaKetana72Minutes()),
    ('MinchaKetanaAhavatShalom', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaKetanaAhavatShalom()),
    ('MinchaKetanaAteretTorah', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaKetanaAteretTorah()),
    ('MinchaKetanaBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaKetanaBaalHatanya()),
    ('MinchaKetanaGRAFixedLocalChatzosToSunset', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMinchaKetanaGRAFixedLocalChatzosToSunset()),
    ('Misheyakir10Point2Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMisheyakir10Point2Degrees()),
    ('Misheyakir11Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMisheyakir11Degrees()),
    ('Misheyakir11Point5Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMisheyakir11Point5Degrees()),
    ('Misheyakir12Point85Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMisheyakir12Point85Degrees()),
    ('Misheyakir7Point65Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMisheyakir7Point65Degrees()),
    ('Misheyakir9Point5Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getMisheyakir9Point5Degrees()),
    ('PlagAhavatShalom', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagAhavatShalom()),
    ('PlagAlos16Point1DegreesToTzaisGeonim7Point083Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagAlos16Point1DegreesToTzaisGeonim7Point083Degrees()),
    ('PlagAlosToSunset', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagAlosToSunset()),
    ('PlagHamincha120Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha120Minutes()),
    ('PlagHamincha120MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha120MinutesZmanis()),
    ('PlagHamincha16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha16Point1Degrees()),
    ('PlagHamincha18Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha18Degrees()),
    ('PlagHamincha19Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha19Point8Degrees()),
    ('PlagHamincha26Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha26Degrees()),
    ('PlagHamincha60Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha60Minutes()),
    ('PlagHamincha72Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha72Minutes()),
    ('PlagHamincha72MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha72MinutesZmanis()),
    ('PlagHamincha90Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha90Minutes()),
    ('PlagHamincha90MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha90MinutesZmanis()),
    ('PlagHamincha96Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha96Minutes()),
    ('PlagHamincha96MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHamincha96MinutesZmanis()),
    ('PlagHaminchaAteretTorah', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHaminchaAteretTorah()),
    ('PlagHaminchaBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHaminchaBaalHatanya()),
    ('PlagHaminchaGRAFixedLocalChatzosToSunset', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPlagHaminchaGRAFixedLocalChatzosToSunset()),
    ('PolarPlagHaminchaBenIshChai', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPolarPlagHaminchaBenIshChai()),
    ('PolarPlagHaminchaTeshuvosVehanhagos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPolarPlagHaminchaTeshuvosVehanhagos()),
    ('PolarStartOfDayTeshuvosVehanhagos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPolarStartOfDayTeshuvosVehanhagos()),
    ('PolarSunriseBenIshChai', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPolarSunriseBenIshChai()),
    ('PolarSunsetBenIshChai', (calendar) => (calendar as ComprehensiveZmanimCalendar).getPolarSunsetBenIshChai()),
    ('SamuchLeMinchaKetana16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSamuchLeMinchaKetana16Point1Degrees()),
    ('SamuchLeMinchaKetana72Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSamuchLeMinchaKetana72Minutes()),
    ('SamuchLeMinchaKetanaGRA', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSamuchLeMinchaKetanaGRA()),
    ('ShaahZmanis120Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis120Minutes()),
    ('ShaahZmanis120MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis120MinutesZmanis()),
    ('ShaahZmanis16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis16Point1Degrees()),
    ('ShaahZmanis18Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis18Degrees()),
    ('ShaahZmanis19Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis19Point8Degrees()),
    ('ShaahZmanis26Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis26Degrees()),
    ('ShaahZmanis60Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis60Minutes()),
    ('ShaahZmanis72MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis72MinutesZmanis()),
    ('ShaahZmanis90Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis90Minutes()),
    ('ShaahZmanis90MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis90MinutesZmanis()),
    ('ShaahZmanis96Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis96Minutes()),
    ('ShaahZmanis96MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanis96MinutesZmanis()),
    ('ShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point7Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point7Degrees()),
    ('ShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point8Degrees()),
    ('ShaahZmanisAlos16Point1DegreesToTzaisGeonim7Point083Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanisAlos16Point1DegreesToTzaisGeonim7Point083Degrees()),
    ('ShaahZmanisAteretTorah', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanisAteretTorah()),
    ('ShaahZmanisBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getShaahZmanisBaalHatanya()),
    ('SofZmanAchilasChametzBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanAchilasChametzBaalHatanya()),
    ('SofZmanAchilasChametzGRA', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanAchilasChametzGRA()),
    ('SofZmanAchilasChametzMGA16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanAchilasChametzMGA16Point1Degrees()),
    ('SofZmanAchilasChametzMGA72Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanAchilasChametzMGA72Minutes()),
    ('SofZmanAchilasChametzMGA72MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanAchilasChametzMGA72MinutesZmanis()),
    ('SofZmanBiurChametzBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanBiurChametzBaalHatanya()),
    ('SofZmanBiurChametzGRA', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanBiurChametzGRA()),
    ('SofZmanBiurChametzMGA16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanBiurChametzMGA16Point1Degrees()),
    ('SofZmanBiurChametzMGA72Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanBiurChametzMGA72Minutes()),
    ('SofZmanBiurChametzMGA72MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanBiurChametzMGA72MinutesZmanis()),
    ('SofZmanKidushLevana15Days', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanKidushLevana15Days()),
    ('SofZmanKidushLevanaBetweenMoldos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanKidushLevanaBetweenMoldos()),
    ('SofZmanShma3HoursBeforeChatzos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShma3HoursBeforeChatzos()),
    ('SofZmanShmaAlos16Point1DegreesToTzaisGeonim7Point083Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaAlos16Point1DegreesToTzaisGeonim7Point083Degrees()),
    ('SofZmanShmaAlos16Point1ToSunset', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaAlos16Point1ToSunset()),
    ('SofZmanShmaAteretTorah', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaAteretTorah()),
    ('SofZmanShmaBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaBaalHatanya()),
    ('SofZmanShmaGRASunriseToFixedLocalChatzos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaGRASunriseToFixedLocalChatzos()),
    ('SofZmanShmaMGA120Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA120Minutes()),
    ('SofZmanShmaMGA16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA16Point1Degrees()),
    ('SofZmanShmaMGA16Point1DegreesToFixedLocalChatzos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA16Point1DegreesToFixedLocalChatzos()),
    ('SofZmanShmaMGA18Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA18Degrees()),
    ('SofZmanShmaMGA18DegreesToFixedLocalChatzos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA18DegreesToFixedLocalChatzos()),
    ('SofZmanShmaMGA19Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA19Point8Degrees()),
    ('SofZmanShmaMGA72MinutesToFixedLocalChatzos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA72MinutesToFixedLocalChatzos()),
    ('SofZmanShmaMGA72MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA72MinutesZmanis()),
    ('SofZmanShmaMGA90Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA90Minutes()),
    ('SofZmanShmaMGA90MinutesToFixedLocalChatzos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA90MinutesToFixedLocalChatzos()),
    ('SofZmanShmaMGA90MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA90MinutesZmanis()),
    ('SofZmanShmaMGA96Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA96Minutes()),
    ('SofZmanShmaMGA96MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanShmaMGA96MinutesZmanis()),
    ('SofZmanTfila2HoursBeforeChatzos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfila2HoursBeforeChatzos()),
    ('SofZmanTfilaAteretTorah', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaAteretTorah()),
    ('SofZmanTfilaBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaBaalHatanya()),
    ('SofZmanTfilaGRASunriseToFixedLocalChatzos', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaGRASunriseToFixedLocalChatzos()),
    ('SofZmanTfilaMGA120Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaMGA120Minutes()),
    ('SofZmanTfilaMGA16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaMGA16Point1Degrees()),
    ('SofZmanTfilaMGA18Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaMGA18Degrees()),
    ('SofZmanTfilaMGA19Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaMGA19Point8Degrees()),
    ('SofZmanTfilaMGA72MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaMGA72MinutesZmanis()),
    ('SofZmanTfilaMGA90Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaMGA90Minutes()),
    ('SofZmanTfilaMGA90MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaMGA90MinutesZmanis()),
    ('SofZmanTfilaMGA96Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaMGA96Minutes()),
    ('SofZmanTfilaMGA96MinutesZmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getSofZmanTfilaMGA96MinutesZmanis()),
    ('TchilasZmanKidushLevana3Days', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTchilasZmanKidushLevana3Days()),
    ('TchilasZmanKidushLevana7Days', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTchilasZmanKidushLevana7Days()),
    ('Tzais120Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais120Minutes()),
    ('Tzais120Zmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais120Zmanis()),
    ('Tzais16Point1Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais16Point1Degrees()),
    ('Tzais18Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais18Degrees()),
    ('Tzais19Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais19Point8Degrees()),
    ('Tzais26Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais26Degrees()),
    ('Tzais50Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais50Minutes()),
    ('Tzais60Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais60Minutes()),
    ('Tzais72Zmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais72Zmanis()),
    ('Tzais90Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais90Minutes()),
    ('Tzais90Zmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais90Zmanis()),
    ('Tzais96Minutes', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais96Minutes()),
    ('Tzais96Zmanis', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzais96Zmanis()),
    ('TzaisAteretTorah', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisAteretTorah()),
    ('TzaisBaalHatanya', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisBaalHatanya()),
    ('TzaisGeonim3Point7Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim3Point7Degrees()),
    ('TzaisGeonim3Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim3Point8Degrees()),
    ('TzaisGeonim4Point42Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim4Point42Degrees()),
    ('TzaisGeonim4Point66Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim4Point66Degrees()),
    ('TzaisGeonim4Point8Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim4Point8Degrees()),
    ('TzaisGeonim5Point95Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim5Point95Degrees()),
    ('TzaisGeonim6Point45Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim6Point45Degrees()),
    ('TzaisGeonim7Point083Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim7Point083Degrees()),
    ('TzaisGeonim7Point67Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim7Point67Degrees()),
    ('TzaisGeonim9Point3Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim9Point3Degrees()),
    ('TzaisGeonim9Point75Degrees', (calendar) => (calendar as ComprehensiveZmanimCalendar).getTzaisGeonim9Point75Degrees()),
    ('ZmanMolad', (calendar) => (calendar as ComprehensiveZmanimCalendar).getZmanMolad()),
  ];
}

String _durationText(Duration duration) {
  final (seconds, nanos) = spanOfMicros(duration.inMicroseconds);
  return javaDurationText(seconds, nanos);
}

class _Metadata {
  _Metadata(AstronomicalCalendar calendar) {
    final geoLocation = calendar.getGeoLocation();
    zone = geoLocation.getZoneId();
    _instantFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ssXXX").withZone(zone);
    final localDate = calendar.getLocalDate();
    date = DateTimeFormatter.ofPattern('yyyy-MM-dd')
        .format(DateTime.utc(localDate.year, localDate.month, localDate.day));
    final (javaType, javaTag) = switch (calendar.runtimeType) {
      const (AstronomicalCalendar) => ('com.kosherjava.zmanim.AstronomicalCalendar', 'AstronomicalTimes'),
      const (ComprehensiveZmanimCalendar) => ('com.kosherjava.zmanim.ComprehensiveZmanimCalendar', 'Zmanim'),
      const (ZmanimCalendar) => ('com.kosherjava.zmanim.ZmanimCalendar', 'BasicZmanim'),
      _ => (calendar.runtimeType.toString(), ''),
    };
    type = javaType;
    tag = javaTag;
    algorithm = calendar.getAstronomicalCalculator().getCalculatorName();
    location = geoLocation.getLocationName();
    latitude = javaDouble(geoLocation.getLatitude());
    longitude = javaDouble(geoLocation.getLongitude());
    elevation = javaDouble(geoLocation.getElevation());
    final lastMidnight = startOfDay(zone, localDate.year, localDate.month, localDate.day);
    timeZoneName = zoneName(zone, lastMidnight.timeZone.isDst);
    timeZoneId = zone.name;
    timeZoneOffset = javaDouble(lastMidnight.timeZoneOffset.inSeconds / 3600.0);
  }

  late final Location zone;
  late final DateTimeFormatter _instantFormatter;
  late final String date;
  late final String type;
  late final String tag;
  late final String algorithm;
  late final String location;
  late final String latitude;
  late final String longitude;
  late final String elevation;
  late final String timeZoneName;
  late final String timeZoneId;
  late final String timeZoneOffset;

  String instantText(DateTime instant) => _instantFormatter.format(instant);
}

class _Values {
  _Values(AstronomicalCalendar calendar) {
    for (final (label, getter) in ZmanimFormatter._gettersOf(calendar)) {
      final Object? value;
      try {
        value = getter(calendar);
      } catch (_) {
        continue;
      }
      if (value is DateTime) {
        dates.add(Zman(value, label));
      } else if (value is Duration) {
        durations.add(Zman.duration(value, label));
      } else {
        missing.add(label);
      }
    }
    _stableSort(dates, Zman.DATE_ORDER);
    _stableSort(durations, Zman.DURATION_ORDER);
  }

  final List<Zman> dates = [];
  final List<Zman> durations = [];
  final List<String> missing = [];
}

void _stableSort<T>(List<T> list, Comparator<T> compare) {
  for (var index = 1; index < list.length; index++) {
    final item = list[index];
    var position = index;
    while (position > 0 && compare(list[position - 1], item) > 0) {
      list[position] = list[position - 1];
      position--;
    }
    list[position] = item;
  }
}
