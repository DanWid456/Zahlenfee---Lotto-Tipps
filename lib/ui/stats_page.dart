import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../l10n/strings.dart';
import '../logic/stats.dart';
import '../models/lottery.dart';
import '../settings/settings.dart';
import 'widgets.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.settings, required this.repo});
  final AppSettings settings;
  final DrawRepository repo;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late LotteryDef _lot = widget.settings.visibleLotteries.first;
  bool _byFreq = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final from = widget.settings.analysisFrom(_lot);
    final stats = NumberStats.compute(_lot, widget.repo.draws(_lot.code), from);

    List<Widget> bars(List<int> freq, int minN, int maxN, {required bool extra}) {
      final nums = [for (var n = minN; n <= maxN; n++) n];
      if (_byFreq) nums.sort((a, b) => freq[a].compareTo(freq[b]));
      final top = freq.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
      return [
        for (final n in nums)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: Row(
              children: [
                Ball(n, extra: extra, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: freq[n] / top, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                      if (!extra)
                        Text(s.t('notSince', {'n': stats.mainLastSeen[n]}), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 44, child: Text('${freq[n]}', textAlign: TextAlign.end)),
              ],
            ),
          ),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('stats')),
        actions: [
          TextButton(
            onPressed: () => setState(() => _byFreq = !_byFreq),
            child: Text(_byFreq ? s.t('sortByNumber') : s.t('sortByFreq')),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DropdownButton<LotteryDef>(
              isExpanded: true,
              value: _lot,
              onChanged: (v) => setState(() => _lot = v!),
              items: [for (final l in kLotteries) DropdownMenuItem(value: l, child: Text(l.name))],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              '${s.t('analysisFrom')} ${fmtDate(from)} · ${s.t('draws', {'n': stats.drawCount})}\n${s.t('statsNote')}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          ...bars(stats.mainFreq, 1, _lot.mainMax, extra: false),
          if (_lot.hasExtras) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(s.t('extras'), style: theme.textTheme.titleSmall),
            ),
            ...bars(stats.extraFreq, _lot.extraMin, _lot.extraMax, extra: true),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
