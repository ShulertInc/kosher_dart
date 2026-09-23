import 'package:timezone/timezone.dart';

import '../astronomical_calendar.dart';
import '../complex_zmanim_calendar.dart';
import '../zmanim_calendar.dart';
import 'date_time_formatter.dart';
import 'java_double.dart';
import 'time.dart';
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

  String formatMillis(double millis) {
    if (millis.isNaN) return format(null);
    final (seconds, nanos) = spanOfMillis(millis);
    return _format(seconds, nanos);
  }

  String formatTime(Time time) => formatMillis(time.isNegative() ? -time.getTime() : time.getTime());

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

  String formatXSDDurationMillis(double millis) => millis.isNaN ? '' : javaDurationTextOfMillis(millis);

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
      sb.write('\t<${zman.getLabel()}>${javaDurationTextOfMillis(zman.getDuration()!)}</${zman.getLabel()}>\n');
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
      sb.write('\t"${zman.getLabel()}":"${javaDurationTextOfMillis(zman.getDuration()!)}",\n');
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
      if (calendar is ComplexZmanimCalendar) ..._complexGetters,
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
    ('Alos16Point1Degrees', (calendar) => (calendar as ZmanimCalendar).getAlosHashachar()),
    ('Alos72Minutes', (calendar) => (calendar as ZmanimCalendar).getAlos72()),
    ('CandleLighting', (calendar) => (calendar as ZmanimCalendar).getCandleLighting()),
    ('ChatzosHalayla', (calendar) => (calendar as ZmanimCalendar).getChatzosHalayla()),
    ('ChatzosHayom', (calendar) => (calendar as ZmanimCalendar).getChatzos()),
    ('ChatzosHayomAsHalfDay', (calendar) => (calendar as ZmanimCalendar).getChatzosAsHalfDay()),
    ('MinchaGedolaGRA', (calendar) => (calendar as ZmanimCalendar).getMinchaGedola()),
    ('MinchaKetanaGRA', (calendar) => (calendar as ZmanimCalendar).getMinchaKetana()),
    ('PlagHaminchaGRA', (calendar) => (calendar as ZmanimCalendar).getPlagHamincha()),
    ('ShaahZmanis72Minutes', (calendar) => (calendar as ZmanimCalendar).getShaahZmanisMGA()),
    ('ShaahZmanisGRA', (calendar) => (calendar as ZmanimCalendar).getShaahZmanisGra()),
    ('SofZmanShmaGRA', (calendar) => (calendar as ZmanimCalendar).getSofZmanShmaGRA()),
    ('SofZmanShmaMGA72Minutes', (calendar) => (calendar as ZmanimCalendar).getSofZmanShmaMGA()),
    ('SofZmanTfilaGRA', (calendar) => (calendar as ZmanimCalendar).getSofZmanTfilaGRA()),
    ('SofZmanTfilaMGA72Minutes', (calendar) => (calendar as ZmanimCalendar).getSofZmanTfilaMGA()),
    ('Tzais72Minutes', (calendar) => (calendar as ZmanimCalendar).getTzais72()),
    ('TzaisGeonim8Point5Degrees', (calendar) => (calendar as ZmanimCalendar).getTzais()),
  ];

  static final List<_Getter> _complexGetters = [
    ('Alos120Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getAlos120()),
    ('Alos120Zmanis', (calendar) => (calendar as ComplexZmanimCalendar).getAlos120Zmanis()),
    ('Alos18Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getAlos18Degrees()),
    ('Alos19Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getAlos19Degrees()),
    ('Alos19Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getAlos19Point8Degrees()),
    ('Alos26Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getAlos26Degrees()),
    ('Alos60Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getAlos60()),
    ('Alos72Zmanis', (calendar) => (calendar as ComplexZmanimCalendar).getAlos72Zmanis()),
    ('Alos90Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getAlos90()),
    ('Alos90Zmanis', (calendar) => (calendar as ComplexZmanimCalendar).getAlos90Zmanis()),
    ('Alos96Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getAlos96()),
    ('Alos96Zmanis', (calendar) => (calendar as ComplexZmanimCalendar).getAlos96Zmanis()),
    ('AlosBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getAlosBaalHatanya()),
    ('BainHashmashosRT13Point24Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosRT13Point24Degrees()),
    ('BainHashmashosRT13Point5MinutesBefore7Point083Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosRT13Point5MinutesBefore7Point083Degrees()),
    ('BainHashmashosRT2Stars', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosRT2Stars()),
    ('BainHashmashosRT58Point5Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosRT58Point5Minutes()),
    ('BainHashmashosYereim13Point5Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosYereim13Point5Minutes()),
    ('BainHashmashosYereim16Point875Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosYereim16Point875Minutes()),
    ('BainHashmashosYereim18Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosYereim18Minutes()),
    ('BainHashmashosYereim2Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosYereim2Point1Degrees()),
    ('BainHashmashosYereim2Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosYereim2Point8Degrees()),
    ('BainHashmashosYereim3Point05Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getBainHasmashosYereim3Point5Degrees()),
    ('FixedLocalChatzosHayom', (calendar) => (calendar as ComplexZmanimCalendar).getFixedLocalChatzos()),
    ('MinchaGedola16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaGedola16Point1Degrees()),
    ('MinchaGedola30Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaGedola30Minutes()),
    ('MinchaGedola72Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaGedola72Minutes()),
    ('MinchaGedolaAhavatShalom', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaGedolaAhavatShalom()),
    ('MinchaGedolaAteretTorah', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaGedolaAteretTorah()),
    ('MinchaGedolaBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaGedolaBaalHatanya()),
    ('MinchaGedolaGRAFixedLocalChatzos30Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaGedolaGRAFixedLocalChatzos30Minutes()),
    ('MinchaGedolaGRAGreaterThan30', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaGedolaGreaterThan30()),
    ('MinchaKetana16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaKetana16Point1Degrees()),
    ('MinchaKetana72Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaKetana72Minutes()),
    ('MinchaKetanaAhavatShalom', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaKetanaAhavatShalom()),
    ('MinchaKetanaAteretTorah', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaKetanaAteretTorah()),
    ('MinchaKetanaBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaKetanaBaalHatanya()),
    ('MinchaKetanaGRAFixedLocalChatzosToSunset', (calendar) => (calendar as ComplexZmanimCalendar).getMinchaKetanaGRAFixedLocalChatzosToSunset()),
    ('Misheyakir10Point2Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getMisheyakir10Point2Degrees()),
    ('Misheyakir11Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getMisheyakir11Degrees()),
    ('Misheyakir11Point5Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getMisheyakir11Point5Degrees()),
    ('Misheyakir12Point85Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getMisheyakir12Point85Degrees()),
    ('Misheyakir7Point65Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getMisheyakir7Point65Degrees()),
    ('Misheyakir9Point5Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getMisheyakir9Point5Degrees()),
    ('PlagAhavatShalom', (calendar) => (calendar as ComplexZmanimCalendar).getPlagAhavatShalom()),
    ('PlagAlos16Point1DegreesToTzaisGeonim7Point083Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getPlagAlos16Point1ToTzaisGeonim7Point083Degrees()),
    ('PlagAlosToSunset', (calendar) => (calendar as ComplexZmanimCalendar).getPlagAlosToSunset()),
    ('PlagHamincha120Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha120Minutes()),
    ('PlagHamincha120MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha120MinutesZmanis()),
    ('PlagHamincha16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha16Point1Degrees()),
    ('PlagHamincha18Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha18Degrees()),
    ('PlagHamincha19Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha19Point8Degrees()),
    ('PlagHamincha26Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha26Degrees()),
    ('PlagHamincha60Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha60Minutes()),
    ('PlagHamincha72Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha72Minutes()),
    ('PlagHamincha72MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha72MinutesZmanis()),
    ('PlagHamincha90Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha90Minutes()),
    ('PlagHamincha90MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha90MinutesZmanis()),
    ('PlagHamincha96Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha96Minutes()),
    ('PlagHamincha96MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHamincha96MinutesZmanis()),
    ('PlagHaminchaAteretTorah', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHaminchaAteretTorah()),
    ('PlagHaminchaBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHaminchaBaalHatanya()),
    ('PlagHaminchaGRAFixedLocalChatzosToSunset', (calendar) => (calendar as ComplexZmanimCalendar).getPlagHaminchaGRAFixedLocalChatzosToSunset()),
    ('PolarPlagHaminchaBenIshChai', (calendar) => (calendar as ComplexZmanimCalendar).getPolarPlagHaminchaBenIshChai()),
    ('PolarPlagHaminchaTeshuvosVehanhagos', (calendar) => (calendar as ComplexZmanimCalendar).getPolarPlagHaminchaTeshuvosVehanhagos()),
    ('PolarStartOfDayTeshuvosVehanhagos', (calendar) => (calendar as ComplexZmanimCalendar).getPolarStartOfDayTeshuvosVehanhagos()),
    ('PolarSunriseBenIshChai', (calendar) => (calendar as ComplexZmanimCalendar).getPolarSunriseBenIshChai()),
    ('PolarSunsetBenIshChai', (calendar) => (calendar as ComplexZmanimCalendar).getPolarSunsetBenIshChai()),
    ('SamuchLeMinchaKetana16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSamuchLeMinchaKetana16Point1Degrees()),
    ('SamuchLeMinchaKetana72Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getSamuchLeMinchaKetana72Minutes()),
    ('SamuchLeMinchaKetanaGRA', (calendar) => (calendar as ComplexZmanimCalendar).getSamuchLeMinchaKetanaGRA()),
    ('ShaahZmanis120Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis120Minutes()),
    ('ShaahZmanis120MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis120MinutesZmanis()),
    ('ShaahZmanis16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis16Point1Degrees()),
    ('ShaahZmanis18Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis18Degrees()),
    ('ShaahZmanis19Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis19Point8Degrees()),
    ('ShaahZmanis26Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis26Degrees()),
    ('ShaahZmanis60Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis60Minutes()),
    ('ShaahZmanis72MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis72MinutesZmanis()),
    ('ShaahZmanis90Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis90Minutes()),
    ('ShaahZmanis90MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis90MinutesZmanis()),
    ('ShaahZmanis96Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis96Minutes()),
    ('ShaahZmanis96MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanis96MinutesZmanis()),
    ('ShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point7Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point7Degrees()),
    ('ShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanisAlos16Point1DegreesToTzaisGeonim3Point8Degrees()),
    ('ShaahZmanisAlos16Point1DegreesToTzaisGeonim7Point083Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanisAlos16Point1DegreesToTzaisGeonim7Point083Degrees()),
    ('ShaahZmanisAteretTorah', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanisAteretTorah()),
    ('ShaahZmanisBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getShaahZmanisBaalHatanya()),
    ('SofZmanAchilasChametzBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanAchilasChametzBaalHatanya()),
    ('SofZmanAchilasChametzGRA', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanAchilasChametzGRA()),
    ('SofZmanAchilasChametzMGA16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanAchilasChametzMGA16Point1Degrees()),
    ('SofZmanAchilasChametzMGA72Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanAchilasChametzMGA72Minutes()),
    ('SofZmanAchilasChametzMGA72MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanAchilasChametzMGA72MinutesZmanis()),
    ('SofZmanBiurChametzBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanBiurChametzBaalHatanya()),
    ('SofZmanBiurChametzGRA', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanBiurChametzGRA()),
    ('SofZmanBiurChametzMGA16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanBiurChametzMGA16Point1Degrees()),
    ('SofZmanBiurChametzMGA72Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanBiurChametzMGA72Minutes()),
    ('SofZmanBiurChametzMGA72MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanBiurChametzMGA72MinutesZmanis()),
    ('SofZmanKidushLevana15Days', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanKidushLevana15Days()),
    ('SofZmanKidushLevanaBetweenMoldos', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanKidushLevanaBetweenMoldos()),
    ('SofZmanShma3HoursBeforeChatzos', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShma3HoursBeforeChatzos()),
    ('SofZmanShmaAlos16Point1DegreesToTzaisGeonim7Point083Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaAlos16Point1ToTzaisGeonim7Point083Degrees()),
    ('SofZmanShmaAlos16Point1ToSunset', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaAlos16Point1ToSunset()),
    ('SofZmanShmaAteretTorah', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaAteretTorah()),
    ('SofZmanShmaBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaBaalHatanya()),
    ('SofZmanShmaGRASunriseToFixedLocalChatzos', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaGRASunriseToFixedLocalChatzos()),
    ('SofZmanShmaMGA120Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA120Minutes()),
    ('SofZmanShmaMGA16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA16Point1Degrees()),
    ('SofZmanShmaMGA16Point1DegreesToFixedLocalChatzos', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA16Point1DegreesToFixedLocalChatzos()),
    ('SofZmanShmaMGA18Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA18Degrees()),
    ('SofZmanShmaMGA18DegreesToFixedLocalChatzos', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA18DegreesToFixedLocalChatzos()),
    ('SofZmanShmaMGA19Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA19Point8Degrees()),
    ('SofZmanShmaMGA72MinutesToFixedLocalChatzos', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA72MinutesToFixedLocalChatzos()),
    ('SofZmanShmaMGA72MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA72MinutesZmanis()),
    ('SofZmanShmaMGA90Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA90Minutes()),
    ('SofZmanShmaMGA90MinutesToFixedLocalChatzos', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA90MinutesToFixedLocalChatzos()),
    ('SofZmanShmaMGA90MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA90MinutesZmanis()),
    ('SofZmanShmaMGA96Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA96Minutes()),
    ('SofZmanShmaMGA96MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanShmaMGA96MinutesZmanis()),
    ('SofZmanTfila2HoursBeforeChatzos', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfila2HoursBeforeChatzos()),
    ('SofZmanTfilaAteretTorah', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilahAteretTorah()),
    ('SofZmanTfilaBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaBaalHatanya()),
    ('SofZmanTfilaGRASunriseToFixedLocalChatzos', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaGRASunriseToFixedLocalChatzos()),
    ('SofZmanTfilaMGA120Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaMGA120Minutes()),
    ('SofZmanTfilaMGA16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaMGA16Point1Degrees()),
    ('SofZmanTfilaMGA18Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaMGA18Degrees()),
    ('SofZmanTfilaMGA19Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaMGA19Point8Degrees()),
    ('SofZmanTfilaMGA72MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaMGA72MinutesZmanis()),
    ('SofZmanTfilaMGA90Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaMGA90Minutes()),
    ('SofZmanTfilaMGA90MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaMGA90MinutesZmanis()),
    ('SofZmanTfilaMGA96Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaMGA96Minutes()),
    ('SofZmanTfilaMGA96MinutesZmanis', (calendar) => (calendar as ComplexZmanimCalendar).getSofZmanTfilaMGA96MinutesZmanis()),
    ('TchilasZmanKidushLevana3Days', (calendar) => (calendar as ComplexZmanimCalendar).getTchilasZmanKidushLevana3Days()),
    ('TchilasZmanKidushLevana7Days', (calendar) => (calendar as ComplexZmanimCalendar).getTchilasZmanKidushLevana7Days()),
    ('Tzais120Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getTzais120()),
    ('Tzais120Zmanis', (calendar) => (calendar as ComplexZmanimCalendar).getTzais120Zmanis()),
    ('Tzais16Point1Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzais16Point1Degrees()),
    ('Tzais18Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzais18Degrees()),
    ('Tzais19Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzais19Point8Degrees()),
    ('Tzais26Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzais26Degrees()),
    ('Tzais50Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getTzais50()),
    ('Tzais60Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getTzais60()),
    ('Tzais72Zmanis', (calendar) => (calendar as ComplexZmanimCalendar).getTzais72Zmanis()),
    ('Tzais90Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getTzais90()),
    ('Tzais90Zmanis', (calendar) => (calendar as ComplexZmanimCalendar).getTzais90Zmanis()),
    ('Tzais96Minutes', (calendar) => (calendar as ComplexZmanimCalendar).getTzais96()),
    ('Tzais96Zmanis', (calendar) => (calendar as ComplexZmanimCalendar).getTzais96Zmanis()),
    ('TzaisAteretTorah', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisAteretTorah()),
    ('TzaisBaalHatanya', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisBaalHatanya()),
    ('TzaisGeonim3Point7Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim3Point7Degrees()),
    ('TzaisGeonim3Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim3Point8Degrees()),
    ('TzaisGeonim4Point42Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim4Point42Degrees()),
    ('TzaisGeonim4Point66Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim4Point66Degrees()),
    ('TzaisGeonim4Point8Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim4Point8Degrees()),
    ('TzaisGeonim5Point95Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim5Point95Degrees()),
    ('TzaisGeonim6Point45Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim6Point45Degrees()),
    ('TzaisGeonim7Point083Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim7Point083Degrees()),
    ('TzaisGeonim7Point67Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim7Point67Degrees()),
    ('TzaisGeonim9Point3Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim9Point3Degrees()),
    ('TzaisGeonim9Point75Degrees', (calendar) => (calendar as ComplexZmanimCalendar).getTzaisGeonim9Point75Degrees()),
    ('ZmanMolad', (calendar) => (calendar as ComplexZmanimCalendar).getZmanMolad()),
  ];
}

class _Metadata {
  _Metadata(AstronomicalCalendar calendar) {
    final geoLocation = calendar.getGeoLocation();
    zone = geoLocation.getZoneId();
    _instantFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ssXXX").withZone(zone);
    final localDate = calendar.getCalendar();
    date = DateTimeFormatter.ofPattern('yyyy-MM-dd')
        .format(DateTime.utc(localDate.year, localDate.month, localDate.day));
    final (javaType, javaTag) = switch (calendar.runtimeType) {
      const (AstronomicalCalendar) => ('com.kosherjava.zmanim.AstronomicalCalendar', 'AstronomicalTimes'),
      const (ComplexZmanimCalendar) => ('com.kosherjava.zmanim.ComprehensiveZmanimCalendar', 'Zmanim'),
      const (ZmanimCalendar) => ('com.kosherjava.zmanim.ZmanimCalendar', 'BasicZmanim'),
      _ => (calendar.runtimeType.toString(), ''),
    };
    type = javaType;
    tag = javaTag;
    algorithm = calendar.getAstronomicalCalculator().getCalculatorName();
    location = geoLocation.getLocationName();
    latitude = javaDouble(geoLocation.getLatitude());
    longitude = javaDouble(geoLocation.getLongitude());
    elevation = javaDouble(geoLocation.getElevation() ?? 0);
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
      } else if (value is double && !value.isNaN) {
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
