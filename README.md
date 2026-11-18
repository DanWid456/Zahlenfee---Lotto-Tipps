# Zahlenfee – Lotto-Tipps

Flutter-App (Android, iOS möglich) für Zahlenvorschläge zu Swiss Lotto, LOTTO 6aus49,
Lotto 6 aus 45 (AT), EuroMillions und Eurojackpot.

## Funktionen
- Startseite: Lotterien des gewählten Landes untereinander, letzte Ziehung, Knopf «Neue Vorschläge» (beliebig oft)
- Drei Vorschlagsarten: seltene Zahlen bevorzugen (Standard), reiner Zufall, unbeliebte Kombinationen
- Filter: Zahlenfolgen, Zahlenreihen, bereits gezogene Kombinationen (optional inkl. Zusatzzahlen),
  nur gerade, nur ungerade, nur ≤ 31, eine Zehnergruppe, gleiche Endziffern, ungewöhnliche Summe
- Einstellungen: Sprache (DE/FR/IT/EN, Standard DE), Land (CH/DE/AT/alle), Anzahl Serien (Standard 5),
  Auswertungszeitraum pro Lotterie (Standard: Beginn der aktuellen Spielregel)
- Meine Tipps: speichern, automatischer Vergleich mit den Ziehungen seit dem Speichern
- Statistik: Häufigkeit und «seit X Ziehungen nicht gezogen»
- Offline: alle Ziehungen sind in `assets/data/` mitgeliefert (~600 KB)

## Datenupdate
1. Die GitHub Action `update-data.yml` läuft täglich und hängt neue Ziehungen an `assets/data/*.json` an.
2. Die App prüft beim Öffnen, ob seit einer Ziehung mehr als 24 h vergangen sind, und lädt dann
   die JSON-Dateien von `kDataBaseUrl` (`lib/config.dart`).

**Wichtig:** Die Standardquelle lottochaos.com (CC BY 4.0) wird nur etwa monatlich aktualisiert.
`--allow-noncommercial` nimmt zusätzlich daowa89/lottery-archive dazu (tagesaktuell für DE/AT/EM),
ist aber nur für private Nutzung erlaubt.

## Einrichten
```bash
flutter create --platforms=android,ios --org ch.dwidmer --project-name lotto_vorschlag .
rm test/widget_test.dart          # Vorlage von flutter create, passt nicht zur App
flutter pub get
flutter test
flutter run
```
Danach in `lib/config.dart` die `kDataBaseUrl` auf das eigene Repo setzen. Den Namen unter dem
App-Symbol («Zahlenfee») setzt der Build-Workflow automatisch in `AndroidManifest.xml`.

Play-Store-Titel: **Zahlenfee – Lotto-Tipps** (FR: «Zahlenfee – Grilles Loto», IT: «Zahlenfee – Numeri Lotto»).

Bei jedem Push baut `build.yml` die App, führt `flutter analyze` und die Tests aus und legt die APK als Artefakt ab.

## Jackpot-Anzeige
`tools/update_jackpots.py` (Workflow `update-jackpots.yml`, alle 3 Stunden) schreibt
`assets/data/jackpot.json`. Quellen sind die Daten, die die offiziellen Websites selbst laden:
- Swisslos: Gewinnzahlen-Seiten (Swiss Lotto, EuroMillions in CHF), Zeile «Jackpot nächste Ziehung»
- Österreichische Lotterien: `https://www.lotterien.at/api/jackpot/all` (Lotto 6 aus 45, EuroMillionen in EUR)
- LOTTO.de: `/api/stats/entities.lotto/last` und `/api/stats/entities.eurojackpot/last`, Feld `jackpotNew` (Mio. €)

Ist ein Wert älter als 4 Tage, blendet die App ihn aus. Ändert eine Website ihr Format, meldet
der Workflow das im Log, und die App zeigt bis zur Anpassung keinen Jackpot für diese Lotterie.
Vor dem Release: Nutzungsbedingungen der drei Websites prüfen bzw. die Lotteriegesellschaften fragen.

## App-Symbol
Vorlage: `branding/icon.svg` (Zauberstab mit Lotto-Kugel). Nach Änderungen neu erzeugen:
```bash
pip install cairosvg pillow   # Schrift "Inter" muss installiert sein
python tools/build_icons.py
```
Ergebnis in `branding/`: Android (klassisch, rund, adaptiv), iOS (alle Grössen), `play_store_512.png`
für die Store-Seite. Der Build-Workflow kopiert die Symbole automatisch ins Projekt; lokal nach
`flutter create` dasselbe mit:
```bash
cp -r branding/android/res/. android/app/src/main/res/
cp branding/ios/AppIcon.appiconset/*.png ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

## Lizenzhinweis
Ziehungsdaten: lottochaos.com, eurolottospielen.org – CC BY 4.0. Die Quellenangabe steht in der App unter «Info».
