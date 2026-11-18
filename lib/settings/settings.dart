import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../logic/filters.dart';
import '../logic/generator.dart';
import '../models/lottery.dart';

class SavedTip {
  SavedTip(this.lottery, this.tip, this.savedOn);
  final String lottery;
  final Tip tip;
  final String savedOn; // ISO-Datum

  Map<String, dynamic> toJson() => {'l': lottery, 't': tip.toJson(), 'd': savedOn};
  factory SavedTip.fromJson(Map<String, dynamic> j) =>
      SavedTip(j['l'] as String, Tip.fromJson(j['t'] as Map<String, dynamic>), j['d'] as String);
}

class AppSettings extends ChangeNotifier {
  AppSettings._(this._p);
  final SharedPreferences _p;

  static Future<AppSettings> load() async => AppSettings._(await SharedPreferences.getInstance());

  // --- Sprache: Standard Deutsch
  String get language => _p.getString('language') ?? 'de';
  set language(String v) => _set(() => _p.setString('language', v));

  // --- Land: Standard aus Geräteeinstellung (CH/DE/AT), sonst CH
  String get country {
    final stored = _p.getString('country');
    if (stored != null) return stored;
    final c = ui.PlatformDispatcher.instance.locale.countryCode;
    return const {'CH', 'DE', 'AT', 'LI'}.contains(c) ? (c == 'LI' ? 'CH' : c!) : 'CH';
  }

  set country(String v) => _set(() => _p.setString('country', v));

  /// Bundesland (nur DE), null = noch nicht gewählt.
  String? get region => _p.getString('region');
  set region(String? v) => _set(() => v == null ? _p.remove('region') : _p.setString('region', v));

  List<LotteryDef> get visibleLotteries =>
      country == 'ALL' ? kLotteries : kLotteries.where((l) => l.countries.contains(country)).toList();

  // --- Serien pro Knopfdruck: Standard 5
  int get seriesCount => _p.getInt('seriesCount') ?? 5;
  set seriesCount(int v) => _set(() => _p.setInt('seriesCount', v.clamp(1, 20).toInt()));

  GenMode get mode => GenMode.values.byName(_p.getString('mode') ?? GenMode.rare.name);
  set mode(GenMode v) => _set(() => _p.setString('mode', v.name));

  // --- Auswertungszeitraum pro Lotterie
  String analysisFrom(LotteryDef lot) => _p.getString('from_${lot.code}') ?? lot.currentRuleStart;
  void setAnalysisFrom(LotteryDef lot, String? isoDate) => _set(() =>
      isoDate == null ? _p.remove('from_${lot.code}') : _p.setString('from_${lot.code}', isoDate));

  // --- Filter
  Set<FilterId> get filters {
    final l = _p.getStringList('filters');
    if (l == null) return {...kDefaultFilters};
    return {for (final n in l) ...FilterId.values.where((f) => f.name == n)};
  }

  void setFilter(FilterId f, bool on) {
    final s = filters;
    on ? s.add(f) : s.remove(f);
    _set(() => _p.setStringList('filters', s.map((e) => e.name).toList()));
  }

  bool get compareWithExtras => _p.getBool('compareWithExtras') ?? false;
  set compareWithExtras(bool v) => _set(() => _p.setBool('compareWithExtras', v));

  // --- Gespeicherte Tipps
  List<SavedTip> get savedTips {
    final raw = _p.getString('savedTips');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => SavedTip.fromJson(e as Map<String, dynamic>)).toList();
  }

  void addTip(SavedTip t) => _saveTips([t, ...savedTips]);
  void removeTip(int index) {
    final l = savedTips..removeAt(index);
    _saveTips(l);
  }

  void _saveTips(List<SavedTip> l) =>
      _set(() => _p.setString('savedTips', jsonEncode(l.map((e) => e.toJson()).toList())));

  // --- Zeitpunkt der letzten Update-Prüfung
  DateTime? get lastUpdateCheck {
    final ms = _p.getInt('lastUpdateCheck');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  set lastUpdateCheck(DateTime? v) =>
      _p.setInt('lastUpdateCheck', (v ?? DateTime.now()).millisecondsSinceEpoch);

  DateTime? get lastJackpotCheck {
    final ms = _p.getInt('lastJackpotCheck');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  set lastJackpotCheck(DateTime? v) =>
      _p.setInt('lastJackpotCheck', (v ?? DateTime.now()).millisecondsSinceEpoch);

  void _set(Future<bool> Function() write) {
    write();
    notifyListeners();
  }

  static bool isSupportedLanguage(String l) => S.supported.contains(l);
}
