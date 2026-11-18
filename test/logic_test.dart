import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotto_vorschlag/data/repository.dart';
import 'package:lotto_vorschlag/logic/filters.dart';
import 'package:lotto_vorschlag/logic/generator.dart';
import 'package:lotto_vorschlag/logic/stats.dart';
import 'package:lotto_vorschlag/models/lottery.dart';

List<Draw> loadDraws(String code) => DrawRepository.parse(File('assets/data/$code.json').readAsStringSync());

void main() {
  group('Filter', () {
    test('Zahlenfolge', () {
      expect(hasConsecutive([1, 12, 13, 14, 30, 40]), isTrue);
      expect(hasConsecutive([1, 12, 13, 20, 30, 40]), isFalse);
    });
    test('Zahlenreihe', () {
      expect(hasProgression([5, 10, 15, 20, 33, 41]), isTrue);
      expect(hasProgression([3, 10, 17, 24, 30, 41]), isTrue); // Spalte im 7er-Raster
      expect(hasProgression([5, 10, 15, 21, 33, 41]), isFalse);
    });
    test('gerade/ungerade/tief/Zehner/Endziffer', () {
      expect(allEven([2, 4, 6, 8, 10, 12]), isTrue);
      expect(allOdd([1, 3, 5, 7, 9, 12]), isFalse);
      expect(allLow([1, 5, 12, 20, 28, 31]), isTrue);
      expect(sameDecade([30, 31, 34, 36, 38, 39]), isTrue);
      expect(sameEnding([1, 11, 21, 31, 5, 6]), isTrue);
    });
  });

  group('Daten', () {
    for (final lot in kLotteries) {
      test('${lot.code}: gültig und sortiert', () {
        final draws = loadDraws(lot.code);
        expect(draws, isNotEmpty);
        for (var i = 0; i < draws.length; i++) {
          final d = draws[i];
          expect(d.main.length, lot.mainCount, reason: d.date);
          expect(d.main.toSet().length, lot.mainCount, reason: d.date);
          expect(d.main.every((n) => n >= 1 && n <= lot.mainMax), isTrue, reason: d.date);
          if (i > 0) expect(d.date.compareTo(draws[i - 1].date) >= 0, isTrue);
        }
      });
    }
  });

  group('Generator', () {
    for (final lot in kLotteries) {
      test('${lot.code}: alle Modi liefern gültige, gefilterte, neue Tipps', () {
        final draws = loadDraws(lot.code);
        final stats = NumberStats.compute(lot, draws, lot.currentRuleStart);
        final (lo, hi) = sumRange(draws, lot.mainCount);
        final ctx = FilterContext(
          drawnMainKeys: {for (final d in draws) d.mainKey},
          drawnFullKeys: const {},
          compareWithExtras: false,
          sumMin: lo,
          sumMax: hi,
        );
        final gen = Generator(lot, random: Random(42));
        for (final mode in GenMode.values) {
          final r = gen.generate(count: 20, mode: mode, stats: stats, filters: FilterId.values.toSet(), ctx: ctx);
          expect(r.tips.length, 20, reason: mode.name);
          expect(r.tips.map((t) => t.mainKey).toSet().length, 20);
          for (final t in r.tips) {
            expect(t.main.length, lot.mainCount);
            expect(t.main.every((n) => n >= 1 && n <= lot.mainMax), isTrue);
            expect(t.extras.length, lot.extraCount);
            expect(t.extras.every((e) => e >= lot.extraMin && e <= lot.extraMax), isTrue);
            expect(rejectedBy(t.main, t.extras, FilterId.values.toSet(), ctx), isNull);
          }
        }
      });
    }

    test('Modus "selten" bevorzugt selten gezogene Zahlen', () {
      final lot = lotteryByCode('DE');
      final draws = loadDraws('DE');
      final stats = NumberStats.compute(lot, draws, '1955-01-01');
      final ranked = [for (var n = 1; n <= 49; n++) n]..sort((a, b) => stats.mainFreq[a].compareTo(stats.mainFreq[b]));
      final rare = ranked.take(10).toSet();
      final common = ranked.reversed.take(10).toSet();
      final ctx = FilterContext(drawnMainKeys: const {}, drawnFullKeys: const {}, compareWithExtras: false, sumMin: 0, sumMax: 999);
      final r = Generator(lot, random: Random(1))
          .generate(count: 500, mode: GenMode.rare, stats: stats, filters: const {}, ctx: ctx);
      final all = r.tips.expand((t) => t.main).toList();
      expect(all.where(rare.contains).length, greaterThan(all.where(common.contains).length * 3));
    });

    test('Modus "unbeliebt" bevorzugt Zahlen über 31', () {
      final lot = lotteryByCode('CH');
      final draws = loadDraws('CH');
      final stats = NumberStats.compute(lot, draws, lot.currentRuleStart);
      final ctx = FilterContext(drawnMainKeys: const {}, drawnFullKeys: const {}, compareWithExtras: false, sumMin: 0, sumMax: 999);
      final r = Generator(lot, random: Random(2))
          .generate(count: 300, mode: GenMode.unpopular, stats: stats, filters: const {}, ctx: ctx);
      final all = r.tips.expand((t) => t.main).toList();
      // ohne Gewichtung wären 11/42 ≈ 26 % über 31
      expect(all.where((n) => n > 31).length / all.length, greaterThan(0.35));
    });
  });

  test('Nächster Ziehungstag', () {
    final em = lotteryByCode('EM');
    expect(DrawRepository.nextDrawDate(em, DateTime(2026, 11, 17)), DateTime(2026, 11, 20)); // Di -> Fr
    expect(DrawRepository.nextDrawDate(em, DateTime(2026, 11, 20)), DateTime(2026, 11, 24)); // Fr -> Di
  });

  group('Annahmeschluss', () {
    test('Swiss Lotto: Mi 19:00, danach Sa 17:00', () {
      final ch = lotteryByCode('CH');
      expect(ch.nextDeadline('CH', DateTime(2026, 11, 18, 18, 0)), DateTime(2026, 11, 18, 19, 0));
      expect(ch.nextDeadline('CH', DateTime(2026, 11, 18, 19, 0)), DateTime(2026, 11, 21, 17, 0));
      expect(ch.nextDeadline('CH', DateTime(2026, 11, 21, 17, 1)), DateTime(2026, 11, 25, 19, 0));
    });
    test('EuroMillions je nach Land', () {
      final em = lotteryByCode('EM');
      expect(em.nextDeadline('CH', DateTime(2026, 11, 17, 19, 45)), DateTime(2026, 11, 20, 19, 30));
      expect(em.nextDeadline('AT', DateTime(2026, 11, 17, 19, 45)), DateTime(2026, 11, 17, 20, 0));
      expect(em.deadlinesFor('ALL').length, 2);
      expect(em.deadlinesFor('AT').single.$1, '');
    });
    test('Deutschland: ohne Bundesland frühester Termin, sonst exakt', () {
      final de = lotteryByCode('DE');
      final ej = lotteryByCode('EJ');
      final mi = DateTime(2026, 11, 18, 12, 0); // Mittwoch
      expect(de.nextDeadline('DE', mi), DateTime(2026, 11, 18, 17, 55)); // Brandenburg
      expect(de.nextDeadline('DE', mi, 'BW'), DateTime(2026, 11, 18, 18, 0));
      expect(de.nextDeadline('DE', DateTime(2026, 11, 19)), DateTime(2026, 11, 21, 18, 30)); // Niedersachsen
      expect(ej.nextDeadline('DE', mi), DateTime(2026, 11, 20, 18, 15)); // Sachsen
      expect(ej.nextDeadline('DE', mi, 'BY'), DateTime(2026, 11, 20, 19, 0));
      expect(ej.nextDeadline('ALL', mi, 'SN'), DateTime(2026, 11, 20, 18, 15));
      expect(kRegionsDE.keys.toSet(), de.regionDeadlines.keys.toSet());
      expect(kRegionsDE.keys.toSet(), ej.regionDeadlines.keys.toSet());
    });
    test('Lotto 6 aus 45: So 19:00 über Monatswechsel', () {
      final at = lotteryByCode('AT');
      expect(at.nextDeadline('AT', DateTime(2026, 11, 26, 9, 0)), DateTime(2026, 11, 29, 19, 0));
      expect(at.nextDeadline('AT', DateTime(2026, 11, 29, 20, 0)), DateTime(2026, 12, 2, 18, 30));
    });
  });

  test('JSON-Format bleibt kompatibel', () {
    const d = Draw('2026-11-17', '', [5, 29, 35, 37, 38], [1, 2]);
    expect(Draw.fromJson(jsonDecode(jsonEncode(d.toJson())) as List).mainKey, '5-29-35-37-38');
  });
}
