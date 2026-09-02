import 'package:kosher_dart/src/hebrewcalendar/daf.dart';

/// Which side of a daf an [Amud] is.
enum AmudSide {
  /// The first side of the daf, amud aleph.
  ALEPH,

  /// The second side of the daf, amud beis.
  BEIS,
}

/// A single amud - one side of one daf - as the schedules that learn half a daf a day
/// assign it.
class Amud {
  Amud(this._masechtaNumber, this._daf, this._side);

  final int _masechtaNumber;
  final int _daf;
  final AmudSide _side;

  /// Returns the masechta number, numbered as [Daf] numbers the masechtos of the Bavli.
  int getMasechtaNumber() => _masechtaNumber;

  /// Returns the daf this amud is on.
  int getDaf() => _daf;

  /// Returns which side of the daf this is.
  AmudSide getSide() => _side;

  /// Returns the transliterated name of the masechta, such as "Berachos".
  String getMasechtaTransliterated() =>
      Daf(_masechtaNumber, _daf).getMasechtaTransliterated();

  /// Returns the Hebrew name of the masechta, such as "ברכות".
  String getMasechta() => Daf(_masechtaNumber, _daf).getMasechta();

  @override
  bool operator ==(Object other) =>
      other is Amud &&
      other._masechtaNumber == _masechtaNumber &&
      other._daf == _daf &&
      other._side == _side;

  @override
  int get hashCode => Object.hash(_masechtaNumber, _daf, _side);

  @override
  String toString() =>
      '${getMasechtaTransliterated()} $_daf${_side == AmudSide.ALEPH ? 'a' : 'b'}';
}
