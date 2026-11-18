import '../models/lottery.dart';

/// Häufigkeiten innerhalb eines Auswertungszeitraums.
class NumberStats {
  NumberStats._(this.mainFreq, this.extraFreq, this.mainLastSeen, this.drawCount);

  /// Index = Zahl (Index 0 unbenutzt).
  final List<int> mainFreq;
  final List<int> extraFreq;

  /// Anzahl Ziehungen seit dem letzten Auftreten (Index = Zahl).
  final List<int> mainLastSeen;
  final int drawCount;

  /// [from]: ISO-Datum, ab dem ausgewertet wird. Für die Zusatzzahlen zählt
  /// zusätzlich nur die aktuelle Regelperiode, sonst wirken neu eingeführte
  /// Zahlen (z. B. Eurozahl 11/12) künstlich selten.
  factory NumberStats.compute(LotteryDef lot, List<Draw> draws, String from) {
    final mainFreq = List<int>.filled(lot.mainMax + 1, 0);
    final extraFreq = List<int>.filled(lot.extraMax + 1, 0);
    final lastSeen = List<int>.filled(lot.mainMax + 1, -1);
    final extraFrom = from.compareTo(lot.currentRuleStart) > 0 ? from : lot.currentRuleStart;
    var count = 0;
    for (final d in draws) {
      if (d.date.compareTo(from) < 0) continue;
      count++;
      for (final n in d.main) {
        if (n <= lot.mainMax) mainFreq[n]++;
      }
      if (lot.hasExtras && d.date.compareTo(extraFrom) >= 0) {
        for (final e in d.extras) {
          if (e >= lot.extraMin && e <= lot.extraMax) extraFreq[e]++;
        }
      }
    }
    // "seit X Ziehungen nicht gezogen" – über die gesamte Historie
    var age = 0;
    for (var i = draws.length - 1; i >= 0; i--) {
      for (final n in draws[i].main) {
        if (n <= lot.mainMax && lastSeen[n] < 0) lastSeen[n] = age;
      }
      age++;
    }
    for (var n = 1; n <= lot.mainMax; n++) {
      if (lastSeen[n] < 0) lastSeen[n] = age;
    }
    return NumberStats._(mainFreq, extraFreq, lastSeen, count);
  }
}

/// Perzentile der Summe der Hauptzahlen (für den Summenfilter).
(int, int) sumRange(List<Draw> draws, int mainCount, {double lo = 0.05, double hi = 0.95}) {
  final sums = draws.where((d) => d.main.length == mainCount).map((d) => d.main.reduce((a, b) => a + b)).toList()
    ..sort();
  if (sums.isEmpty) return (0, 1 << 30);
  int at(double p) => sums[((sums.length - 1) * p).round()];
  return (at(lo), at(hi));
}
