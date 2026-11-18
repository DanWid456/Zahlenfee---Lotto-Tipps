import 'dart:math';

import '../models/lottery.dart';
import 'filters.dart';
import 'stats.dart';

enum GenMode {
  /// Reiner Zufall, jede Zahl gleich wahrscheinlich.
  random,

  /// Selten gezogene Zahlen werden bevorzugt (nach Rang gewichtet).
  rare,

  /// Zahlen über 31 werden bevorzugt, Muster vermieden – Kombinationen, die
  /// wenige andere Leute tippen (im Gewinnfall muss seltener geteilt werden).
  unpopular,
}

/// Filter, die im Modus "unbeliebte Kombinationen" immer aktiv sind.
const Set<FilterId> kUnpopularFilters = {
  FilterId.consecutive,
  FilterId.progression,
  FilterId.allLow,
  FilterId.sameEnding,
};

class GenResult {
  const GenResult(this.tips, {this.requested = 0});
  final List<Tip> tips;
  final int requested;
  bool get incomplete => tips.length < requested;
}

class Generator {
  Generator(this.lot, {Random? random}) : _rnd = random ?? Random.secure();

  final LotteryDef lot;
  final Random _rnd;

  /// Gewichtung nach Rang: seltenste Zahl Gewicht 1.0, häufigste ≈ e^-k.
  /// Die Häufigkeiten liegen nahe beieinander; ein Rang-Gewicht macht die
  /// Bevorzugung spürbar, ohne dass immer dieselbe Serie herauskommt.
  static List<double> rankWeights(List<int> freq, int minN, int maxN, {double k = 2.5}) {
    final nums = [for (var n = minN; n <= maxN; n++) n]..sort((a, b) => freq[a].compareTo(freq[b]));
    final w = List<double>.filled(maxN + 1, 0);
    final span = max(nums.length - 1, 1);
    for (var r = 0; r < nums.length; r++) {
      w[nums[r]] = exp(-k * r / span);
    }
    return w;
  }

  List<int> _pick(int count, int min, int maxN, List<double>? weights) {
    final pool = [for (var n = min; n <= maxN; n++) n];
    final out = <int>[];
    while (out.length < count) {
      int idx;
      if (weights == null) {
        idx = _rnd.nextInt(pool.length);
      } else {
        final total = pool.fold<double>(0, (s, n) => s + weights[n]);
        var x = _rnd.nextDouble() * total;
        idx = 0;
        for (; idx < pool.length - 1; idx++) {
          x -= weights[pool[idx]];
          if (x <= 0) break;
        }
      }
      out.add(pool.removeAt(idx));
    }
    return out..sort();
  }

  GenResult generate({
    required int count,
    required GenMode mode,
    required NumberStats stats,
    required Set<FilterId> filters,
    required FilterContext ctx,
    int maxAttemptsPerTip = 20000,
  }) {
    List<double>? mainW;
    List<double>? extraW;
    switch (mode) {
      case GenMode.random:
        break;
      case GenMode.rare:
        mainW = rankWeights(stats.mainFreq, 1, lot.mainMax);
        if (lot.hasExtras) extraW = rankWeights(stats.extraFreq, lot.extraMin, lot.extraMax);
      case GenMode.unpopular:
        mainW = [for (var n = 0; n <= lot.mainMax; n++) n > 31 ? 2.0 : 1.0];
    }
    final active = {...filters, if (mode == GenMode.unpopular) ...kUnpopularFilters};
    final tips = <Tip>[];
    final seen = <String>{};
    for (var t = 0; t < count; t++) {
      for (var a = 0; a < maxAttemptsPerTip; a++) {
        final main = _pick(lot.mainCount, 1, lot.mainMax, mainW);
        final extras = lot.hasExtras ? _pick(lot.extraCount, lot.extraMin, lot.extraMax, extraW) : <int>[];
        final tip = Tip(main, extras);
        if (seen.contains(tip.mainKey)) continue;
        if (rejectedBy(main, extras, active, ctx) != null) continue;
        seen.add(tip.mainKey);
        tips.add(tip);
        break;
      }
    }
    return GenResult(tips, requested: count);
  }
}

/// Anzahl Treffer eines Tipps in einer Ziehung.
(int, int) matches(Tip tip, Draw d) {
  final m = tip.main.where(d.main.contains).length;
  final e = tip.extras.where(d.extras.contains).length;
  return (m, e);
}
