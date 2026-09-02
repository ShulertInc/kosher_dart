/// The perek or perakim of Pirkei Avos said on one Shabbos.
class PirkeiAvosUnit {
  /// A single perek.
  PirkeiAvosUnit.single(int perek)
      : first = perek,
        second = null;

  /// Two perakim said together, as they are at the end of a short cycle.
  PirkeiAvosUnit.combined(this.first, this.second);

  /// The perek, or the first of the two.
  final int first;

  /// The second perek where two are said together, and null where one is.
  final int? second;

  /// Whether two perakim are said.
  bool get isCombined => second != null;

  @override
  bool operator ==(Object other) =>
      other is PirkeiAvosUnit && other.first == first && other.second == second;

  @override
  int get hashCode => Object.hash(first, second);

  @override
  String toString() => second == null ? '$first' : '$first - $second';
}
