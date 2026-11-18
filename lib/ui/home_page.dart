import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repository.dart';
import '../l10n/strings.dart';
import '../logic/filters.dart';
import '../logic/generator.dart';
import '../logic/stats.dart';
import '../models/lottery.dart';
import '../settings/settings.dart';
import 'info_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'tips_page.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.settings, required this.repo});
  final AppSettings settings;
  final DrawRepository repo;

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appTitle')),
        actions: [
          IconButton(
            tooltip: s.t('myTips'),
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => _open(context, TipsPage(settings: settings, repo: repo)),
          ),
          IconButton(
            tooltip: s.t('stats'),
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _open(context, StatsPage(settings: settings, repo: repo)),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'settings'
                ? _open(context, SettingsPage(settings: settings, repo: repo))
                : _open(context, const InfoPage()),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'settings', child: Text(s.t('settings'))),
              PopupMenuItem(value: 'info', child: Text(s.t('info'))),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, repo]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            if (settings.region == null && settings.visibleLotteries.any((l) => l.hasRegions))
              _RegionBanner(settings: settings),
            for (final lot in settings.visibleLotteries)
              LotteryCard(key: ValueKey(lot.code), lot: lot, settings: settings, repo: repo),
          ],
        ),
      ),
    );
  }
}

/// Hinweis, solange in Deutschland kein Bundesland gewählt ist.
class _RegionBanner extends StatelessWidget {
  const _RegionBanner({required this.settings});
  final AppSettings settings;

  Future<void> _pick(BuildContext context) async {
    final s = S.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.t('chooseRegion')),
        children: [
          for (final e in kRegionsDE.entries)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, e.key), child: Text(e.value)),
        ],
      ),
    );
    if (picked != null) settings.region = picked;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.secondaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: cs.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(child: Text(s.t('regionBanner'), style: TextStyle(color: cs.onSecondaryContainer))),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => _pick(context), child: Text(s.t('chooseRegion'))),
            ),
          ],
        ),
      ),
    );
  }
}

class LotteryCard extends StatefulWidget {
  const LotteryCard({super.key, required this.lot, required this.settings, required this.repo});
  final LotteryDef lot;
  final AppSettings settings;
  final DrawRepository repo;

  @override
  State<LotteryCard> createState() => _LotteryCardState();
}

class _LotteryCardState extends State<LotteryCard> {
  GenResult? _result;
  late final Generator _gen = Generator(widget.lot);

  void _generate() {
    final lot = widget.lot;
    final st = widget.settings;
    final draws = widget.repo.draws(lot.code);
    final from = st.analysisFrom(lot);
    final stats = NumberStats.compute(lot, draws, from);
    final (sumMin, sumMax) = sumRange(draws.where((d) => d.date.compareTo(from) >= 0).toList(), lot.mainCount);
    final ctx = FilterContext(
      drawnMainKeys: widget.repo.drawnMainKeys(lot.code),
      drawnFullKeys: widget.repo.drawnFullKeys(lot.code),
      compareWithExtras: st.compareWithExtras,
      sumMin: sumMin,
      sumMax: sumMax,
    );
    setState(() {
      _result = _gen.generate(count: st.seriesCount, mode: st.mode, stats: stats, filters: st.filters, ctx: ctx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lot = widget.lot;
    final last = widget.repo.lastDraw(lot.code);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lot.name, style: theme.textTheme.titleLarge),
            if (last != null) ...[
              const SizedBox(height: 4),
              Text(s.t('lastDraw', {'date': fmtDate(last.date)}), style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              NumberRow(main: last.main, extras: lot.hasExtras ? last.extras : const [], size: 28),
            ],
            for (final j in widget.repo.jackpots(lot.code, widget.settings.country, DateTime.now()))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 18, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${s.t(j.guaranteed ? 'guaranteedNext' : 'jackpotNext')}: '),
                          TextSpan(
                            text: formatAmount(j.amount, j.currency, s.lang),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (widget.settings.country == 'ALL' && lot.deadlines.length > 1)
                            TextSpan(text: ' (${j.country})'),
                        ]),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            DeadlineInfo(lot: lot, country: widget.settings.country, region: widget.settings.region),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.casino_outlined),
                label: Text(s.t('generate')),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              for (final tip in _result!.tips) _TipRow(lot: lot, tip: tip, settings: widget.settings),
              if (_result!.incomplete)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(s.t('incomplete', {'n': _result!.tips.length}),
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.lot, required this.tip, required this.settings});
  final LotteryDef lot;
  final Tip tip;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final text = tip.extras.isEmpty ? tip.main.join(' ') : '${tip.main.join(' ')} + ${tip.extras.join(' ')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: NumberRow(main: tip.main, extras: tip.extras)),
          IconButton(
            tooltip: s.t('copied'),
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${lot.name}: $text'));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('copied'))));
            },
          ),
          IconButton(
            tooltip: s.t('saved'),
            icon: const Icon(Icons.bookmark_add_outlined, size: 20),
            onPressed: () {
              settings.addTip(SavedTip(lot.code, tip, isoDate(DateTime.now())));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('saved'))));
            },
          ),
        ],
      ),
    );
  }
}
