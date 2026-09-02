import 'package:kosher_dart/src/hebrewcalendar/limudim/limudim_data.dart';

/// The Hebrew names of the masechtos of the Mishna, in the order
/// [mishnaMasechtosTransliterated] lists them.
const List<String> _masechtosHebrew = [
  "ברכות", "פאה", "דמאי", "כלאים", "שביעית", "תרומות", "מעשרות",
  "מעשר שני", "חלה", "ערלה", "ביכורים", "שבת", "עירובין", "פסחים",
  "שקלים", "יומא", "סוכה", "ביצה", "ראש השנה", "תענית", "מגילה",
  "מועד קטן", "חגיגה", "יבמות", "כתובות", "נדרים", "נזיר", "סוטה",
  "גיטין", "קידושין", "בבא קמא", "בבא מציעא", "בבא בתרא", "סנהדרין",
  "מכות", "שבועות", "עדיות", "עבודה זרה", "אבות", "הוריות", "זבחים",
  "מנחות", "חולין", "בכורות", "ערכין", "תמורה", "כריתות", "מעילה",
  "תמיד", "מידות", "קינים", "כלים", "אהלות", "נגעים", "פרה", "טהרות",
  "מקואות", "נדה", "מכשירין", "זבים", "טבול יום", "ידים", "עוקצים",
];

/// A single mishna, the unit Mishna Yomis is counted in.
class Mishna {
  Mishna(this._masechtaNumber, this._chapter, this._mishna);

  final int _masechtaNumber;
  final int _chapter;
  final int _mishna;

  /// Returns the masechta number, indexed as [mishnaMasechtosTransliterated].
  int getMasechtaNumber() => _masechtaNumber;

  /// Returns the perek this mishna is in, counting from 1.
  int getChapter() => _chapter;

  /// Returns the mishna within its perek, counting from 1.
  int getMishna() => _mishna;

  /// Returns the transliterated name of the masechta, such as "Berachos".
  String getMasechtaTransliterated() =>
      mishnaMasechtosTransliterated[_masechtaNumber];

  /// Returns the Hebrew name of the masechta, such as "ברכות".
  String getMasechta() => _masechtosHebrew[_masechtaNumber];

  @override
  bool operator ==(Object other) =>
      other is Mishna &&
      other._masechtaNumber == _masechtaNumber &&
      other._chapter == _chapter &&
      other._mishna == _mishna;

  @override
  int get hashCode => Object.hash(_masechtaNumber, _chapter, _mishna);

  @override
  String toString() => '${getMasechtaTransliterated()} $_chapter:$_mishna';
}

/// The two mishnayos of one day of Mishna Yomis.
class Mishnas {
  Mishnas(this.first, this.second);

  /// The first mishna of the day.
  final Mishna first;

  /// The second mishna of the day.
  final Mishna second;

  @override
  bool operator ==(Object other) =>
      other is Mishnas && other.first == first && other.second == second;

  @override
  int get hashCode => Object.hash(first, second);

  @override
  String toString() => '$first - $second';
}
