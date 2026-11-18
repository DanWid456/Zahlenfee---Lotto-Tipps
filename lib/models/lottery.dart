/// Stammdaten der Lotterien und Datenmodell einer Ziehung.
library;

/// Zahlenbereiche, die ab einem Datum gelten (Regeländerungen).
class RulePeriod {
  const RulePeriod(this.from, {required this.mainMax, this.extraMin = 0, this.extraMax = 0});

  final String from; // ISO-Datum JJJJ-MM-TT
  final int mainMax;
  final int extraMin;
  final int extraMax;
}

/// Annahmeschluss an einem Wochentag (Ortszeit CH/DE/AT, MEZ/MESZ).
class Deadline {
  const Deadline(this.weekday, this.hour, this.minute);
  final int weekday; // DateTime.weekday
  final int hour;
  final int minute;

  String get time => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class LotteryDef {
  const LotteryDef({
    required this.code,
    required this.name,
    required this.countries,
    required this.mainCount,
    required this.extraCount,
    required this.drawWeekdays,
    required this.periods,
    required this.deadlines,
    this.regionDeadlines = const {},
  });

  /// Annahmeschluss pro Land (Schlüssel = Ländercode). Stand 11/2026.
  final Map<String, List<Deadline>> deadlines;

  /// Abweichende Zeiten pro Bundesland (nur DE). Schlüssel = Kürzel (BW, BY …).
  final Map<String, List<Deadline>> regionDeadlines;

  bool get hasRegions => regionDeadlines.isNotEmpty;

  /// Ohne gewähltes Bundesland: pro Wochentag der früheste Termin aller
  /// Bundesländer – so wird der Schluss nie verpasst.
  List<Deadline> get earliestRegionDeadlines {
    final byDay = <int, Deadline>{};
    for (final list in regionDeadlines.values) {
      for (final d in list) {
        final cur = byDay[d.weekday];
        if (cur == null || d.hour * 60 + d.minute < cur.hour * 60 + cur.minute) byDay[d.weekday] = d;
      }
    }
    return byDay.values.toList()..sort((a, b) => a.weekday.compareTo(b.weekday));
  }

  /// Gültige Zeiten für Land und (optional) Bundesland.
  List<Deadline> _effective(String country, String? region) {
    if (hasRegions && deadlines.containsKey(country)) {
      return region != null && regionDeadlines.containsKey(region) ? regionDeadlines[region]! : earliestRegionDeadlines;
    }
    return deadlines[country] ?? deadlines.values.first;
  }

  /// Annahmeschlusszeiten zur Anzeige; bei unbekanntem Land (z. B. "alle")
  /// alle Länder-Varianten mit Länderkürzel.
  List<(String, List<Deadline>)> deadlinesFor(String country, [String? region]) {
    if (deadlines.containsKey(country)) return [('', _effective(country, region))];
    return [
      for (final c in deadlines.keys) (deadlines.length > 1 ? c : '', _effective(c, region)),
    ];
  }

  /// Nächster Annahmeschluss nach [now].
  DateTime? nextDeadline(String country, DateTime now, [String? region]) {
    final list = _effective(deadlines.containsKey(country) ? country : deadlines.keys.first, region);
    DateTime? best;
    for (final d in list) {
      final diff = (d.weekday - now.weekday) % 7; // Dart: Ergebnis immer ≥ 0
      var t = DateTime(now.year, now.month, now.day + diff, d.hour, d.minute);
      if (!t.isAfter(now)) t = DateTime(t.year, t.month, t.day + 7, d.hour, d.minute);
      if (best == null || t.isBefore(best)) best = t;
    }
    return best;
  }

  final String code;
  final String name;

  /// Länder, in denen die Lotterie gespielt wird (ISO-Code).
  final Set<String> countries;

  /// Anzahl Hauptzahlen auf dem Tipp.
  final int mainCount;

  /// Anzahl Zusatzzahlen, die der Spieler selbst wählt (Glückszahl, Sterne,
  /// Eurozahlen). 0 bei 6aus49 (Superzahl = Losnummer) und Lotto 6 aus 45.
  final int extraCount;

  /// Ziehungstage (DateTime.weekday: 1 = Montag … 7 = Sonntag).
  final List<int> drawWeekdays;

  /// Regelperioden, aufsteigend nach Datum.
  final List<RulePeriod> periods;

  RulePeriod get current => periods.last;
  int get mainMax => current.mainMax;
  int get extraMin => current.extraMin;
  int get extraMax => current.extraMax;
  bool get hasExtras => extraCount > 0;

  /// Beginn der aktuell gültigen Regel – Standard für den Auswertungszeitraum.
  String get currentRuleStart => current.from;
}

const List<LotteryDef> kLotteries = [
  LotteryDef(
    code: 'CH',
    name: 'Swiss Lotto',
    countries: {'CH'},
    mainCount: 6,
    extraCount: 1,
    drawWeekdays: [DateTime.wednesday, DateTime.saturday],
    periods: [RulePeriod('2013-01-12', mainMax: 42, extraMin: 1, extraMax: 6)],
    // Swisslos: Mi 19:00, Sa 17:00
    deadlines: {'CH': [Deadline(DateTime.wednesday, 19, 0), Deadline(DateTime.saturday, 17, 0)]},
  ),
  LotteryDef(
    code: 'DE',
    name: 'LOTTO 6aus49',
    countries: {'DE'},
    mainCount: 6,
    extraCount: 0,
    drawWeekdays: [DateTime.wednesday, DateTime.saturday],
    periods: [RulePeriod('1955-10-09', mainMax: 49)],
    // in den meisten Bundesländern Mi 18:00 / Sa 19:00 (NRW, Hamburg 1 Min. früher)
    deadlines: {'DE': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)]},
    // pro Bundesland, Quelle: news.de (Stand 10/2026) – vor Release bei den Landeslotterien prüfen
    regionDeadlines: _lottoDE,
  ),
  LotteryDef(
    code: 'AT',
    name: 'Lotto 6 aus 45',
    countries: {'AT'},
    mainCount: 6,
    extraCount: 0,
    drawWeekdays: [DateTime.wednesday, DateTime.sunday],
    periods: [RulePeriod('1986-09-07', mainMax: 45)],
    // Österreichische Lotterien: Mi 18:30, So 19:00 (Bonus-Ziehungen Fr 18:30)
    deadlines: {'AT': [Deadline(DateTime.wednesday, 18, 30), Deadline(DateTime.sunday, 19, 0)]},
  ),
  LotteryDef(
    code: 'EM',
    name: 'EuroMillions',
    countries: {'CH', 'AT'},
    mainCount: 5,
    extraCount: 2,
    drawWeekdays: [DateTime.tuesday, DateTime.friday],
    periods: [
      RulePeriod('2004-02-13', mainMax: 50, extraMin: 1, extraMax: 9),
      RulePeriod('2011-05-10', mainMax: 50, extraMin: 1, extraMax: 11),
      RulePeriod('2016-09-24', mainMax: 50, extraMin: 1, extraMax: 12),
    ],
    // Swisslos: Di/Fr 19:30 · Österreichische Lotterien: Di/Fr 20:00
    deadlines: {'CH': [Deadline(DateTime.tuesday, 19, 30), Deadline(DateTime.friday, 19, 30)], 'AT': [Deadline(DateTime.tuesday, 20, 0), Deadline(DateTime.friday, 20, 0)]},
  ),
  LotteryDef(
    code: 'EJ',
    name: 'Eurojackpot',
    countries: {'DE'},
    mainCount: 5,
    extraCount: 2,
    drawWeekdays: [DateTime.tuesday, DateTime.friday],
    periods: [
      RulePeriod('2012-03-23', mainMax: 50, extraMin: 1, extraMax: 8),
      RulePeriod('2014-10-10', mainMax: 50, extraMin: 1, extraMax: 10),
      RulePeriod('2022-03-25', mainMax: 50, extraMin: 1, extraMax: 12),
    ],
    // je nach Bundesland 18:15–19:00, z. B. BW/BY/HE/NRW 19:00, Berlin 18:45
    deadlines: {'DE': [Deadline(DateTime.tuesday, 19, 0), Deadline(DateTime.friday, 19, 0)]},
    regionDeadlines: _eurojackpotDE,
  ),
];

LotteryDef lotteryByCode(String code) => kLotteries.firstWhere((l) => l.code == code);

class Draw {
  const Draw(this.date, this.label, this.main, this.extras);

  final String date; // ISO JJJJ-MM-TT
  final String label; // 'A'/'B' bei Doppelziehungen, sonst ''
  final List<int> main; // aufsteigend
  final List<int> extras; // gezogene Zusatzzahlen (Glückszahl, Sterne, Superzahl …)

  factory Draw.fromJson(List<dynamic> j) => Draw(
        j[0] as String,
        j[1] as String,
        (j[2] as List).cast<int>(),
        (j[3] as List).cast<int>(),
      );

  List<dynamic> toJson() => [date, label, main, extras];

  String get mainKey => main.join('-');
}

/// Ein generierter oder gespeicherter Tipp.
class Tip {
  const Tip(this.main, this.extras);

  final List<int> main; // aufsteigend
  final List<int> extras; // aufsteigend

  String get mainKey => main.join('-');
  String get fullKey => '$mainKey|${extras.join('-')}';

  Map<String, dynamic> toJson() => {'m': main, 'e': extras};
  factory Tip.fromJson(Map<String, dynamic> j) =>
      Tip((j['m'] as List).cast<int>(), (j['e'] as List).cast<int>());
}

const Map<String, List<Deadline>> _lottoDE = {
      'BW': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'BY': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'BE': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'BB': [Deadline(DateTime.wednesday, 17, 55), Deadline(DateTime.saturday, 18, 55)],
      'HB': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'HH': [Deadline(DateTime.wednesday, 17, 59), Deadline(DateTime.saturday, 18, 59)],
      'HE': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'MV': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'NI': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 18, 30)],
      'NW': [Deadline(DateTime.wednesday, 17, 59), Deadline(DateTime.saturday, 18, 59)],
      'RP': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'SL': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'SN': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'ST': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'SH': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
      'TH': [Deadline(DateTime.wednesday, 18, 0), Deadline(DateTime.saturday, 19, 0)],
    };

const Map<String, List<Deadline>> _eurojackpotDE = {
      'BW': [Deadline(DateTime.tuesday, 19, 0), Deadline(DateTime.friday, 19, 0)],
      'BY': [Deadline(DateTime.tuesday, 19, 0), Deadline(DateTime.friday, 19, 0)],
      'BE': [Deadline(DateTime.tuesday, 18, 45), Deadline(DateTime.friday, 18, 45)],
      'BB': [Deadline(DateTime.tuesday, 18, 40), Deadline(DateTime.friday, 18, 40)],
      'HB': [Deadline(DateTime.tuesday, 18, 45), Deadline(DateTime.friday, 18, 45)],
      'HH': [Deadline(DateTime.tuesday, 18, 44), Deadline(DateTime.friday, 18, 44)],
      'HE': [Deadline(DateTime.tuesday, 19, 0), Deadline(DateTime.friday, 19, 0)],
      'MV': [Deadline(DateTime.tuesday, 18, 30), Deadline(DateTime.friday, 18, 30)],
      'NI': [Deadline(DateTime.tuesday, 18, 50), Deadline(DateTime.friday, 18, 50)],
      'NW': [Deadline(DateTime.tuesday, 19, 0), Deadline(DateTime.friday, 19, 0)],
      'RP': [Deadline(DateTime.tuesday, 19, 0), Deadline(DateTime.friday, 19, 0)],
      'SL': [Deadline(DateTime.tuesday, 18, 45), Deadline(DateTime.friday, 18, 45)],
      'SN': [Deadline(DateTime.tuesday, 18, 15), Deadline(DateTime.friday, 18, 15)],
      'ST': [Deadline(DateTime.tuesday, 19, 0), Deadline(DateTime.friday, 19, 0)],
      'SH': [Deadline(DateTime.tuesday, 18, 45), Deadline(DateTime.friday, 18, 45)],
      'TH': [Deadline(DateTime.tuesday, 19, 0), Deadline(DateTime.friday, 19, 0)],
    };

/// Bundesländer (Kürzel → Name).
const Map<String, String> kRegionsDE = {
  'BW': 'Baden-Württemberg',
  'BY': 'Bayern',
  'BE': 'Berlin',
  'BB': 'Brandenburg',
  'HB': 'Bremen',
  'HH': 'Hamburg',
  'HE': 'Hessen',
  'MV': 'Mecklenburg-Vorpommern',
  'NI': 'Niedersachsen',
  'NW': 'Nordrhein-Westfalen',
  'RP': 'Rheinland-Pfalz',
  'SL': 'Saarland',
  'SN': 'Sachsen',
  'ST': 'Sachsen-Anhalt',
  'SH': 'Schleswig-Holstein',
  'TH': 'Thüringen',
};

/// Jackpot der nächsten Ziehung (aus jackpot.json).
class Jackpot {
  const Jackpot({
    required this.lottery,
    required this.country,
    required this.amount,
    required this.currency,
    required this.kind,
    required this.fetched,
  });

  final String lottery;
  final String country;
  final int amount;
  final String currency; // CHF | EUR
  final String kind; // jackpot | guaranteed
  final DateTime fetched;

  bool get guaranteed => kind == 'guaranteed';

  factory Jackpot.fromJson(Map<String, dynamic> j) => Jackpot(
        lottery: j['lottery'] as String,
        country: j['country'] as String,
        amount: (j['amount'] as num).round(),
        currency: j['currency'] as String,
        kind: j['kind'] as String? ?? 'jackpot',
        fetched: DateTime.parse(j['fetched'] as String),
      );

  /// Ältere Werte gelten als veraltet und werden nicht angezeigt.
  bool isFresh(DateTime now) => now.difference(fetched).inDays < 4;
}

/// "CHF 45,8 Mio." / "€ 37 Mio." / "€ 1,2 Mio." – Dezimalkomma ausser Englisch.
String formatAmount(int amount, String currency, String lang) {
  final sym = currency == 'EUR' ? '€' : currency;
  final sep = lang == 'en' ? '.' : ',';
  if (amount >= 1000000) {
    final m = amount / 1000000;
    var s = m >= 100 || m == m.roundToDouble() ? m.round().toString() : m.toStringAsFixed(1);
    s = s.replaceAll('.', sep);
    final unit = {'de': 'Mio.', 'fr': 'mio', 'it': 'mln', 'en': 'm'}[lang] ?? 'Mio.';
    return '$sym $s $unit';
  }
  final digits = amount.toString();
  final group = lang == 'en' ? ',' : (lang == 'de' ? "'" : ' ');
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write(group);
    b.write(digits[i]);
  }
  return '$sym $b';
}
