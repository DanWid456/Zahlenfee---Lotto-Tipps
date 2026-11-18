import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/lottery.dart';

/// TT.MM.JJJJ aus ISO-Datum.
String fmtDate(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}.${p[1]}.${p[0]}' : iso;
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _weekdays = {
  'de': ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
  'fr': ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'],
  'it': ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
  'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
};

String fmtDay(S s, DateTime d) =>
    '${(_weekdays[s.lang] ?? _weekdays['de']!)[d.weekday - 1]} ${fmtDate(isoDate(d))}';

String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Annahmeschluss einer Lotterie: feste Zeiten + nächster Termin mit Countdown.
class DeadlineInfo extends StatefulWidget {
  const DeadlineInfo({super.key, required this.lot, required this.country, this.region});
  final LotteryDef lot;
  final String country;
  final String? region;

  @override
  State<DeadlineInfo> createState() => _DeadlineInfoState();
}

class _DeadlineInfoState extends State<DeadlineInfo> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _left(S s, Duration d) {
    if (d.inDays > 0) return s.t('leftDays', {'d': d.inDays, 'h': d.inHours % 24});
    if (d.inHours > 0) return s.t('leftHours', {'h': d.inHours, 'm': d.inMinutes % 60});
    return s.t('leftMinutes', {'m': d.inMinutes + 1});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final lot = widget.lot;
    final now = DateTime.now();
    final next = lot.nextDeadline(widget.country, now, widget.region);
    final short = (_weekdays[s.lang] ?? _weekdays['de']!);
    final fixed = [
      for (final (label, list) in lot.deadlinesFor(widget.country, widget.region))
        '${label.isEmpty ? '' : '$label: '}${list.map((d) => '${short[d.weekday - 1]} ${d.time}').join(' · ')}',
    ].join('  |  ');
    final note = !lot.hasRegions
        ? ''
        : widget.region == null
            ? ' (${s.t('deadlineEarliest')})'
            : ' (${kRegionsDE[widget.region] ?? widget.region})';
    final soon = next != null && next.difference(now).inHours < 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (next != null)
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: soon ? theme.colorScheme.error : theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${s.t('tipUntil', {'day': fmtDay(s, next), 'time': _hhmm(next)})} · ${_left(s, next.difference(now))}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: soon ? theme.colorScheme.error : null,
                  ),
                ),
              ),
            ],
          ),
        Text('${s.t('deadline')}: $fixed$note', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Runde Zahlenkugel. [extra] = Zusatzzahl (Glückszahl, Stern, Eurozahl).
class Ball extends StatelessWidget {
  const Ball(this.n, {super.key, this.extra = false, this.highlight = false, this.size = 34});
  final int n;
  final bool extra;
  final bool highlight;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = highlight
        ? cs.tertiary
        : extra
            ? cs.secondaryContainer
            : cs.primaryContainer;
    final fg = highlight
        ? cs.onTertiary
        : extra
            ? cs.onSecondaryContainer
            : cs.onPrimaryContainer;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: extra ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: extra ? BorderRadius.circular(size / 4) : null,
      ),
      child: Text('$n', style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: size * 0.42)),
    );
  }
}

class NumberRow extends StatelessWidget {
  const NumberRow({super.key, required this.main, required this.extras, this.hitMain, this.hitExtras, this.size = 34});
  final List<int> main;
  final List<int> extras;
  final List<int>? hitMain;
  final List<int>? hitExtras;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final n in main) Ball(n, size: size, highlight: hitMain?.contains(n) ?? false),
        if (extras.isNotEmpty) SizedBox(width: size / 4),
        for (final e in extras) Ball(e, extra: true, size: size, highlight: hitExtras?.contains(e) ?? false),
      ],
    );
  }
}
