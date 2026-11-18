import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import '../models/lottery.dart';

/// Lädt die Ziehungen (mitgelieferte Daten oder lokal aktualisierte Kopie)
/// und holt neue Ziehungen vom Datenserver.
class DrawRepository extends ChangeNotifier {
  final Map<String, List<Draw>> _draws = {};
  final Map<String, Set<String>> _mainKeys = {};
  final Map<String, Set<String>> _fullKeys = {};
  List<Jackpot> _jackpots = const [];

  /// Gültige Jackpots einer Lotterie für das Land (bei "ALL" alle Länder).
  List<Jackpot> jackpots(String lottery, String country, DateTime now) => [
        for (final j in _jackpots)
          if (j.lottery == lottery && (country == 'ALL' || j.country == country) && j.isFresh(now)) j,
      ];

  static List<Jackpot> parseJackpots(String json) =>
      ((jsonDecode(json) as Map<String, dynamic>)['jackpots'] as List)
          .map((e) => Jackpot.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Lädt jackpot.json (mitgeliefert, lokal oder vom Server) – der neueste Stand gewinnt.
  Future<bool> updateJackpots({bool remote = true}) async {
    final dir = await _dir();
    final local = File('${dir.path}/jackpot.json');
    var list = <Jackpot>[];
    try {
      list = parseJackpots(await rootBundle.loadString('assets/data/jackpot.json'));
    } catch (_) {}
    void takeNewer(List<Jackpot> other) {
      final m = {for (final j in list) '${j.lottery}/${j.country}': j};
      for (final j in other) {
        final k = '${j.lottery}/${j.country}';
        if (m[k] == null || j.fetched.isAfter(m[k]!.fetched)) m[k] = j;
      }
      list = m.values.toList();
    }
    if (local.existsSync()) {
      try {
        takeNewer(parseJackpots(await local.readAsString()));
      } catch (_) {}
    }
    var ok = true;
    if (remote) {
      try {
        final res = await http.get(Uri.parse('$kDataBaseUrl/jackpot.json')).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final body = utf8.decode(res.bodyBytes);
          takeNewer(parseJackpots(body));
          await local.writeAsString(body);
        } else {
          ok = false;
        }
      } catch (_) {
        ok = false;
      }
    }
    _jackpots = list;
    notifyListeners();
    return ok;
  }

  List<Draw> draws(String code) => _draws[code] ?? const [];
  Set<String> drawnMainKeys(String code) => _mainKeys[code] ?? const {};
  Set<String> drawnFullKeys(String code) => _fullKeys[code] ?? const {};
  Draw? lastDraw(String code) => draws(code).isEmpty ? null : draws(code).last;

  Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationDocumentsDirectory()).path}/data');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  static List<Draw> parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    return (j['draws'] as List).map((e) => Draw.fromJson(e as List)).toList()
      ..sort((a, b) => a.date == b.date ? a.label.compareTo(b.label) : a.date.compareTo(b.date));
  }

  Future<void> loadAll() async {
    final dir = await _dir();
    for (final lot in kLotteries) {
      var list = parse(await rootBundle.loadString('assets/data/${lot.code}.json'));
      final local = File('${dir.path}/${lot.code}.json');
      if (local.existsSync()) {
        try {
          final l = parse(await local.readAsString());
          if (l.isNotEmpty && l.last.date.compareTo(list.last.date) > 0) list = _merge(list, l);
        } catch (_) {/* defekte lokale Datei ignorieren */}
      }
      _set(lot.code, list);
    }
    await updateJackpots(remote: false);
  }

  void _set(String code, List<Draw> list) {
    _draws[code] = list;
    _mainKeys[code] = {for (final d in list) d.mainKey};
    _fullKeys[code] = {for (final d in list) '${d.mainKey}|${([...d.extras]..sort()).join('-')}'};
  }

  static List<Draw> _merge(List<Draw> a, List<Draw> b) {
    final m = {for (final d in a) '${d.date}${d.label}': d};
    for (final d in b) {
      m['${d.date}${d.label}'] = d;
    }
    return m.values.toList()
      ..sort((x, y) => x.date == y.date ? x.label.compareTo(y.label) : x.date.compareTo(y.date));
  }

  /// Nächster Ziehungstag nach [after] (Datum ohne Uhrzeit).
  static DateTime nextDrawDate(LotteryDef lot, DateTime after) {
    var d = DateTime(after.year, after.month, after.day).add(const Duration(days: 1));
    while (!lot.drawWeekdays.contains(d.weekday)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  /// true, wenn bei mindestens einer Lotterie eine Ziehung fällig ist, die
  /// seit mehr als [kUpdateDelayHours] veröffentlicht sein sollte.
  bool updateDue(DateTime now, DateTime? lastCheck) {
    if (lastCheck != null && now.difference(lastCheck).inHours < kMinCheckIntervalHours) return false;
    for (final lot in kLotteries) {
      final last = lastDraw(lot.code);
      if (last == null) return true;
      final next = nextDrawDate(lot, DateTime.parse(last.date));
      if (now.isAfter(next.add(const Duration(hours: 20 + kUpdateDelayHours)))) return true;
    }
    return false;
  }

  /// Lädt neue Ziehungen. Rückgabe: Anzahl neuer Ziehungen, -1 bei Fehler.
  Future<int> update() async {
    var added = 0;
    var failed = false;
    final dir = await _dir();
    for (final lot in kLotteries) {
      try {
        final res = await http
            .get(Uri.parse('$kDataBaseUrl/${lot.code}.json'))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) {
          failed = true;
          continue;
        }
        final body = utf8.decode(res.bodyBytes);
        final remote = parse(body);
        final before = draws(lot.code).length;
        final merged = _merge(draws(lot.code), remote);
        if (merged.length > before) {
          _set(lot.code, merged);
          added += merged.length - before;
          await File('${dir.path}/${lot.code}.json').writeAsString(jsonEncode({
            'code': lot.code,
            'draws': merged.map((d) => d.toJson()).toList(),
          }));
        }
      } catch (_) {
        failed = true;
      }
    }
    notifyListeners();
    return failed && added == 0 ? -1 : added;
  }
}
