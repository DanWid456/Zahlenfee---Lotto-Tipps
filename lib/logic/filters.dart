/// Filter, mit denen unerwünschte Kombinationen ausgeblendet werden.
library;

enum FilterId {
  consecutive, // ≥3 aufeinanderfolgende Zahlen (12-13-14)
  progression, // ≥4 Zahlen mit gleichem Abstand ≥2 (5-10-15-20, Spalten/Diagonalen)
  alreadyDrawn, // Kombination wurde schon einmal gezogen
  allEven, // nur gerade Zahlen
  allOdd, // nur ungerade Zahlen
  allLow, // alle Zahlen ≤ 31 ("Geburtstagstipp")
  sameDecade, // alle Zahlen aus derselben Zehnergruppe
  sameEnding, // ≥4 Zahlen mit gleicher Endziffer
  sumOutlier, // Summe ausserhalb des üblichen Bereichs (5.–95. Perzentil)
}

const Set<FilterId> kDefaultFilters = {
  FilterId.consecutive,
  FilterId.alreadyDrawn,
  FilterId.allEven,
  FilterId.allOdd,
};

bool hasConsecutive(List<int> s, {int run = 3}) {
  var len = 1;
  for (var i = 1; i < s.length; i++) {
    len = s[i] == s[i - 1] + 1 ? len + 1 : 1;
    if (len >= run) return true;
  }
  return false;
}

bool hasProgression(List<int> s, {int length = 4}) {
  final set = s.toSet();
  for (var i = 0; i < s.length; i++) {
    for (var j = i + 1; j < s.length; j++) {
      final step = s[j] - s[i];
      if (step < 2) continue;
      var n = 2;
      var next = s[j] + step;
      while (set.contains(next)) {
        n++;
        next += step;
      }
      if (n >= length) return true;
    }
  }
  return false;
}

bool allEven(List<int> s) => s.every((n) => n.isEven);
bool allOdd(List<int> s) => s.every((n) => n.isOdd);
bool allLow(List<int> s) => s.every((n) => n <= 31);
bool sameDecade(List<int> s) => s.map((n) => n ~/ 10).toSet().length == 1;

bool sameEnding(List<int> s, {int count = 4}) {
  final c = <int, int>{};
  for (final n in s) {
    c[n % 10] = (c[n % 10] ?? 0) + 1;
  }
  return c.values.any((v) => v >= count);
}

/// Kontext, den die Filter brauchen.
class FilterContext {
  const FilterContext({
    required this.drawnMainKeys,
    required this.drawnFullKeys,
    required this.compareWithExtras,
    required this.sumMin,
    required this.sumMax,
  });

  final Set<String> drawnMainKeys;
  final Set<String> drawnFullKeys;

  /// true: "schon gezogen" nur, wenn auch die Zusatzzahlen gleich sind.
  final bool compareWithExtras;
  final int sumMin;
  final int sumMax;
}

/// Liefert den ersten Filter, der den Tipp ausschliesst, oder null.
FilterId? rejectedBy(List<int> main, List<int> extras, Set<FilterId> active, FilterContext ctx) {
  for (final f in active) {
    final hit = switch (f) {
      FilterId.consecutive => hasConsecutive(main),
      FilterId.progression => hasProgression(main),
      FilterId.alreadyDrawn => ctx.compareWithExtras && extras.isNotEmpty
          ? ctx.drawnFullKeys.contains('${main.join('-')}|${extras.join('-')}')
          : ctx.drawnMainKeys.contains(main.join('-')),
      FilterId.allEven => allEven(main),
      FilterId.allOdd => allOdd(main),
      FilterId.allLow => allLow(main),
      FilterId.sameDecade => sameDecade(main),
      FilterId.sameEnding => sameEnding(main),
      FilterId.sumOutlier => () {
          final sum = main.reduce((a, b) => a + b);
          return sum < ctx.sumMin || sum > ctx.sumMax;
        }(),
    };
    if (hit) return f;
  }
  return null;
}
