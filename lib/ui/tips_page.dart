import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../l10n/strings.dart';
import '../logic/generator.dart';
import '../models/lottery.dart';
import '../settings/settings.dart';
import 'widgets.dart';

/// Gespeicherte Tipps, automatisch mit den Ziehungen seit dem Speichern verglichen.
class TipsPage extends StatelessWidget {
  const TipsPage({super.key, required this.settings, required this.repo});
  final AppSettings settings;
  final DrawRepository repo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('myTips'))),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, repo]),
        builder: (context, _) {
          final tips = settings.savedTips;
          if (tips.isEmpty) {
            return Center(
              child: Padding(padding: const EdgeInsets.all(32), child: Text(s.t('noTips'), textAlign: TextAlign.center)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tips.length,
            itemBuilder: (context, i) {
              final st = tips[i];
              final lot = lotteryByCode(st.lottery);
              // Ziehungen am oder nach dem Speichertag
              final since = repo.draws(lot.code).where((d) => d.date.compareTo(st.savedOn) >= 0).toList();
              final last = since.isEmpty ? null : since.last;
              Draw? best;
              var bestScore = -1;
              for (final d in since) {
                final (m, e) = matches(st.tip, d);
                if (m * 10 + e > bestScore) {
                  bestScore = m * 10 + e;
                  best = d;
                }
              }
              String result;
              if (last == null) {
                result = s.t('noDrawYet');
              } else {
                final (m, e) = matches(st.tip, last);
                result = lot.hasExtras ? s.t('latestResultExtra', {'m': m, 'e': e}) : s.t('latestResult', {'m': m});
                if (best != null && best != last) {
                  result += '\n${s.t('bestSince', {'m': matches(st.tip, best).$1, 'date': fmtDate(best.date)})}';
                }
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(lot.name, style: theme.textTheme.titleMedium)),
                          IconButton(
                            tooltip: s.t('delete'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => settings.removeTip(i),
                          ),
                        ],
                      ),
                      NumberRow(
                        main: st.tip.main,
                        extras: st.tip.extras,
                        hitMain: last?.main,
                        hitExtras: last?.extras,
                      ),
                      const SizedBox(height: 8),
                      Text(s.t('savedOn', {'date': fmtDate(st.savedOn)}), style: theme.textTheme.bodySmall),
                      Text(result, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
