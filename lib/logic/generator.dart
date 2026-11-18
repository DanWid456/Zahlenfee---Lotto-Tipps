import 'dart:math';

import '../models/lottery.dart';
import 'filters.dart';
import 'stats.dart';

/// Vorschlagsart – die Optionen sind frei kombinierbar. Ist keine aktiv,
/// wird reiner Zufall verwendet.
class GenOptions {
  const GenOptions({this.preferRare = true, this.preferOverdue = false, this.unpopular = false});

  /// Selten gezogene Zahlen (Häufigkeit im Auswertungszeitraum) bevorzugen.
  final bool preferRare;

  /// Am längsten nicht mehr gezogene Zahlen bevorzugen.
  final bool preferOverdue;

  /// Zahlen über 31 bevorzugen und Muster vermeiden – Kombinationen, die wenige
  /// andere Leute tippen (im Gewinnfall muss seltener geteilt werden).
  final bool unpopular;

  bool get pureRandom => !preferRare && !preferOverdue && !unpopular;
}

/// Filter, die bei "unbeliebte Kombinationen" immer aktiv sind.
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

  /// Gewichtung nach Rang: bevorzugteste Zahl Gewicht 1.0, letzte ≈ e^-k.
  /// Die Häufigkeiten liegen nahe beieinander; ein Rang-Gewicht macht die
  /// Bevorzugung spürbar, ohne dass immer dieselbe Serie herauskommt.
  /// [freq]: selten zuerst; [lastSeen]: lange nicht gezogen zuerst; beide
  /// angegeben: Mittel der beiden Ränge.
  static List<double>? rankWeights(int minN, int maxN, {List<int>? freq, List<int>? lastSeen, double k = 2.5}) {
    if (freq == null && lastSeen == null) return null;
    final nums = [for (var n = minN; n <= maxN; n++) n];
    final score = <int, double>{for (final n in nums) n: 0};
    void addRanks(List<int> order) {
      for (var r = 0; r < order.length; r++) {
        score[order[r]] = score[order[r]]! + r;
      }
    }
    if (freq != null) addRanks([...nums]..sort((a, b) => freq[a].compareTo(freq[b])));
    if (lastSeen != null) addRanks([...nums]..sort((a, b) => lastSeen[b].compareTo(lastSeen[a])));
    final order = [...nums]..sort((a, b) => score[a]!.compareTo(score[b]!));
    final w = List<double>.filled(maxN + 1, 0);
    final span = max(order.length - 1, 1);
    for (var r = 0; r < order.length; r++) {
      w[order[r]] = exp(-k * r / span);
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
    required GenOptions options,
    required NumberStats stats,
    required Set<FilterId> filters,
    required FilterContext ctx,
    int maxAttemptsPerTip = 20000,
  }) {
    var mainW = rankWeights(1, lot.mainMax,
        freq: options.preferRare ? stats.mainFreq : null,
        lastSeen: options.preferOverdue ? stats.mainLastSeen : null);
    final extraW = lot.hasExtras
        ? rankWeights(lot.extraMin, lot.extraMax,
            freq: options.preferRare ? stats.extraFreq : null,
            lastSeen: options.preferOverdue ? stats.extraLastSeen : null)
        : null;
    if (options.unpopular) {
      final base = mainW ?? List<double>.filled(lot.mainMax + 1, 1);
      mainW = [for (var n = 0; n <= lot.mainMax; n++) n > 31 ? base[n] * 2 : base[n]];
    }
    final active = {...filters, if (options.unpopular) ...kUnpopularFilters};
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
