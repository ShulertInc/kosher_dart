/*
 * Zmanim Java API
 * Copyright (C) 2004-2020 Eliyahu Hershfeld
 *
 * This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General
 * Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 * You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA,
 * or connect to: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
 */

import 'package:timezone/timezone.dart';

import 'date_time_formatter.dart';
import 'geo_location.dart';

class Zman {
  Zman(DateTime? zman, String? label) : this.withGeoLocation(zman, null, label);

  Zman.withGeoLocation(this._zman, this._geoLocation, this._label);

  Zman.duration(this._duration, this._label);

  String? _label;

  DateTime? _zman;

  Duration? _duration;

  String? _description;

  GeoLocation? _geoLocation;

  DateTime? getZman() => _zman;

  void setZman(DateTime? zman) => _zman = zman;

  GeoLocation? getGeoLocation() => _geoLocation;

  void setGeoLocation(GeoLocation? geoLocation) => _geoLocation = geoLocation;

  Duration? getDuration() => _duration;

  void setDuration(Duration? duration) => _duration = duration;

  String? getLabel() => _label;

  void setLabel(String? label) => _label = label;

  String? getDescription() => _description;

  void setDescription(String? description) => _description = description;

  static const Comparator<Zman?> DATE_ORDER = _dateOrder;

  static const Comparator<Zman?> NAME_ORDER = _nameOrder;

  static const Comparator<Zman?> DURATION_ORDER = _durationOrder;

  static int _dateOrder(Zman? first, Zman? second) {
    if (first == null || second == null) return _nullsLast(first, second)!;
    return _byZman(first, second) ?? _byDuration(first, second) ?? 0;
  }

  static int _durationOrder(Zman? first, Zman? second) {
    if (first == null || second == null) return _nullsLast(first, second)!;
    return _byDuration(first, second) ?? _byZman(first, second) ?? 0;
  }

  static int _nameOrder(Zman? first, Zman? second) {
    if (first == null || second == null) return first == null ? (second == null ? 0 : -1) : 1;
    final firstLabel = first.getLabel();
    final secondLabel = second.getLabel();
    if (firstLabel == null || secondLabel == null) {
      return firstLabel == null ? (secondLabel == null ? 0 : -1) : 1;
    }
    return firstLabel.compareTo(secondLabel);
  }

  static int? _nullsLast(Zman? first, Zman? second) {
    if (first == null) return second == null ? 0 : 1;
    if (second == null) return -1;
    return null;
  }

  static int? _byZman(Zman first, Zman second) {
    final firstZman = first.getZman();
    final secondZman = second.getZman();
    if (firstZman != null && secondZman != null) return firstZman.compareTo(secondZman);
    if (firstZman != null) return -1;
    if (secondZman != null) return 1;
    return null;
  }

  static int? _byDuration(Zman first, Zman second) {
    final firstDuration = first.getDuration();
    final secondDuration = second.getDuration();
    if (firstDuration != null && secondDuration != null) return firstDuration.compareTo(secondDuration);
    if (firstDuration != null) return -1;
    if (secondDuration != null) return 1;
    return null;
  }

  String toXML() {
    final geoLocation = getGeoLocation();
    final formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS")
        .withZone(geoLocation == null ? UTC : geoLocation.getZoneId());
    final zman = getZman();
    final sb = StringBuffer('<Zman>\n');
    sb.write('\t<Label>${getLabel()}</Label>\n');
    sb.write('\t<Zman>${zman == null ? '' : formatter.format(zman)}</Zman>\n');
    if (geoLocation != null) sb.write('\t${geoLocation.toXML().replaceAll('\n', '\n\t')}');
    sb.write('\n\t<Duration>${_durationText()}</Duration>\n');
    sb.write('\t<Description>${getDescription()}</Description>\n');
    sb.write('</Zman>');
    return sb.toString();
  }

  @override
  String toString() {
    final zman = getZman();
    final geoLocation = getGeoLocation();
    return '\nLabel:\t${getLabel()}'
        '\nZman:\t${zman == null ? 'null' : instantText(zman)}'
        '\nGeoLocation:\t${geoLocation == null ? 'null' : geoLocation.toString().replaceAll('\n', '\n\t')}'
        '\nDuration:\t${_durationText()}'
        '\nDescription:\t${getDescription()}';
  }

  String _durationText() {
    final duration = getDuration();
    if (duration == null) return 'null';
    final (seconds, nanos) = spanOfMicros(duration.inMicroseconds);
    return javaDurationText(seconds, nanos);
  }
}
