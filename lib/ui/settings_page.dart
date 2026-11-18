import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../l10n/strings.dart';
import '../logic/filters.dart';
import '../logic/generator.dart';
import '../models/lottery.dart';
import '../settings/settings.dart';
import 'widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings, required this.repo});
  final AppSettings settings;
  final DrawRepository repo;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _updating = false;

  Future<void> _update(S s) async {
    setState(() => _updating = true);
    final n = await widget.repo.update();
    await widget.repo.updateJackpots();
    widget.settings.lastJackpotCheck = DateTime.now();
    widget.settings.lastUpdateCheck = DateTime.now();
    if (!mounted) return;
    setState(() => _updating = false);
    final msg = n < 0
        ? '${s.t('updateFailed')}\n${widget.repo.lastError ?? ''}'
        : (n == 0 ? s.t('upToDate') : s.t('updated', {'n': n}));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: n < 0 ? 8 : 4)));
  }

  Future<void> _pickFrom(LotteryDef lot) async {
    final st = widget.settings;
    final draws = widget.repo.draws(lot.code);
    final first = DateTime.parse(draws.isEmpty ? lot.periods.first.from : draws.first.date);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(st.analysisFrom(lot)),
      firstDate: first,
      lastDate: DateTime.now(),
    );
    if (picked != null) st.setAnalysisFrom(lot, isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final st = widget.settings;
    final theme = Theme.of(context);
    Widget header(String key) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(s.t(key), style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings'))),
      body: ListenableBuilder(
        listenable: Listenable.merge([st, widget.repo]),
        builder: (context, _) {
          final filters = st.filters;
          return ListView(
            children: [
              header('general'),
              ListTile(
                title: Text(s.t('language')),
                trailing: DropdownButton<String>(
                  value: st.language,
                  onChanged: (v) => st.language = v!,
                  items: [
                    for (final l in S.supported) DropdownMenuItem(value: l, child: Text(S.languageNames[l]!)),
                  ],
                ),
              ),
              ListTile(
                title: Text(s.t('country')),
                trailing: DropdownButton<String>(
                  value: st.country,
                  onChanged: (v) => st.country = v!,
                  items: [
                    for (final c in ['CH', 'DE', 'AT']) DropdownMenuItem(value: c, child: Text(s.t(c))),
                    DropdownMenuItem(value: 'ALL', child: Text(s.t('countryAll'))),
                  ],
                ),
              ),
              if (st.country == 'DE' || st.country == 'ALL')
                ListTile(
                  title: Text(s.t('region')),
                  subtitle: st.region == null ? Text(s.t('deadlineEarliest')) : null,
                  trailing: DropdownButton<String?>(
                    value: st.region,
                    onChanged: (v) => st.region = v,
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text(s.t('regionNone'))),
                      for (final e in kRegionsDE.entries) DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
                    ],
                  ),
                ),
              ListTile(
                title: Text(s.t('seriesCount')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: st.seriesCount > 1 ? () => st.seriesCount = st.seriesCount - 1 : null,
                    ),
                    Text('${st.seriesCount}', style: theme.textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: st.seriesCount < 20 ? () => st.seriesCount = st.seriesCount + 1 : null,
                    ),
                  ],
                ),
              ),
              header('mode'),
              for (final m in GenMode.values)
                RadioListTile<GenMode>(
                  value: m,
                  groupValue: st.mode,
                  onChanged: (v) => st.mode = v!,
                  title: Text(s.t('mode_${m.name}')),
                  subtitle: m == GenMode.unpopular ? Text(s.t('mode_unpopular_hint')) : null,
                ),
              header('filters'),
              for (final f in FilterId.values) ...[
                SwitchListTile(
                  value: filters.contains(f),
                  onChanged: (v) => st.setFilter(f, v),
                  title: Text(s.t('f_${f.name}')),
                ),
                if (f == FilterId.alreadyDrawn)
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    value: st.compareWithExtras,
                    onChanged: filters.contains(FilterId.alreadyDrawn) ? (v) => st.compareWithExtras = v! : null,
                    title: Text(s.t('f_compareExtras'), style: theme.textTheme.bodyMedium),
                  ),
              ],
              header('analysisFrom'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(s.t('analysisFromHint'), style: theme.textTheme.bodySmall),
              ),
              for (final lot in kLotteries)
                ListTile(
                  title: Text(lot.name),
                  subtitle: Text(fmtDate(st.analysisFrom(lot))),
                  onTap: () => _pickFrom(lot),
                  trailing: st.analysisFrom(lot) != lot.currentRuleStart
                      ? IconButton(
                          tooltip: s.t('reset'),
                          icon: const Icon(Icons.restart_alt),
                          onPressed: () => st.setAnalysisFrom(lot, null),
                        )
                      : const Icon(Icons.edit_calendar_outlined),
                ),
              header('data'),
              for (final lot in kLotteries)
                ListTile(
                  dense: true,
                  title: Text(lot.name),
                  subtitle: Text(
                    '${s.t('draws', {'n': widget.repo.draws(lot.code).length})} · '
                    '${s.t('lastDraw', {'date': fmtDate(widget.repo.lastDraw(lot.code)?.date ?? '-')})}',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: _updating ? null : () => _update(s),
                  icon: _updating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                  label: Text(s.t('updateNow')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
