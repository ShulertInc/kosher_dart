/// The Tehillim said on one day of the monthly cycle.
///
/// Most days are a run of whole kapitlach. The twenty fifth and twenty sixth of the
/// month split kapitel 119 between them, so those two name a range of pesukim instead.
class TehillimUnit {
  /// A run of whole kapitlach, from [start] through [end].
  TehillimUnit.psalms(this.start, this.end)
      : psalm = null,
        startVerse = null,
        endVerse = null;

  /// Part of one kapitel, from [startVerse] through [endVerse].
  TehillimUnit.psalmVerses(int this.psalm, int this.startVerse, int this.endVerse)
      : start = psalm,
        end = psalm;

  /// The first kapitel said.
  final int start;

  /// The last kapitel said.
  final int end;

  /// The kapitel the pesukim are taken from, or null where whole kapitlach are said.
  final int? psalm;

  /// The first posuk said, or null where whole kapitlach are said.
  final int? startVerse;

  /// The last posuk said, or null where whole kapitlach are said.
  final int? endVerse;

  /// Whether this is part of a kapitel rather than a run of whole ones.
  bool get isPartialPsalm => psalm != null;

  @override
  bool operator ==(Object other) =>
      other is TehillimUnit &&
      other.start == start &&
      other.end == end &&
      other.psalm == psalm &&
      other.startVerse == startVerse &&
      other.endVerse == endVerse;

  @override
  int get hashCode => Object.hash(start, end, psalm, startVerse, endVerse);

  @override
  String toString() => psalm == null
      ? (start == end ? '$start' : '$start - $end')
      : '$psalm:$startVerse - $endVerse';
}
