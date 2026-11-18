import 'package:flutter/widgets.dart';

/// Einfache Übersetzungen ohne Codegenerierung. Standard: Deutsch.
class S {
  S(this.lang);
  final String lang;

  static const supported = ['de', 'fr', 'it', 'en'];
  static const languageNames = {'de': 'Deutsch', 'fr': 'Français', 'it': 'Italiano', 'en': 'English'};

  static S of(BuildContext context) => S(Localizations.localeOf(context).languageCode);

  String t(String key, [Map<String, Object>? args]) {
    var s = _t[key]?[lang] ?? _t[key]?['de'] ?? key;
    args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  static const Map<String, Map<String, String>> _t = {
    'appTitle': {'de': 'Zahlenfee', 'fr': 'Zahlenfee', 'it': 'Zahlenfee', 'en': 'Zahlenfee'},
    'appSubtitle': {'de': 'Lotto-Tipps', 'fr': 'Grilles Loto', 'it': 'Numeri Lotto', 'en': 'Lotto picks'},
    'generate': {'de': 'Neue Vorschläge', 'fr': 'Nouvelles suggestions', 'it': 'Nuove proposte', 'en': 'New picks'},
    'lastDraw': {'de': 'Letzte Ziehung {date}', 'fr': 'Dernier tirage {date}', 'it': 'Ultima estrazione {date}', 'en': 'Last draw {date}'},
    'nextDraw': {'de': 'Nächste Ziehung {day}', 'fr': 'Prochain tirage {day}', 'it': 'Prossima estrazione {day}', 'en': 'Next draw {day}'},
    'updateAvailable': {
      'de': 'Neue Version {v} verfügbar',
      'fr': 'Nouvelle version {v} disponible',
      'it': 'Nuova versione {v} disponibile',
      'en': 'New version {v} available'
    },
    'download': {'de': 'Herunterladen', 'fr': 'Télécharger', 'it': 'Scarica', 'en': 'Download'},
    'appVersion': {'de': 'App-Version', 'fr': 'Version de l\'app', 'it': 'Versione app', 'en': 'App version'},
    'checkAppUpdate': {'de': 'Nach App-Update suchen', 'fr': 'Rechercher une mise à jour', 'it': 'Cerca aggiornamento app', 'en': 'Check for app update'},
    'appUpToDate': {'de': 'Die App ist aktuell', 'fr': 'L\'app est à jour', 'it': 'L\'app è aggiornata', 'en': 'The app is up to date'},
    'installHint': {
      'de': 'Nach dem Download die Datei öffnen. Beim ersten Mal fragt Android, ob der Browser Apps installieren darf.',
      'fr': 'Ouvrez le fichier après le téléchargement. La première fois, Android demande d\'autoriser le navigateur à installer des apps.',
      'it': 'Apri il file dopo il download. La prima volta Android chiede di consentire al browser di installare app.',
      'en': 'Open the file after downloading. The first time, Android asks whether the browser may install apps.'
    },
    'jackpotNext': {'de': 'Jackpot nächste Ziehung', 'fr': 'Jackpot du prochain tirage', 'it': 'Jackpot prossima estrazione', 'en': 'Next jackpot'},
    'guaranteedNext': {
      'de': 'Garantiert im Sechser-Rang',
      'fr': 'Garanti au 1er rang',
      'it': 'Garantito al 1° premio',
      'en': 'Guaranteed top prize'
    },
    'deadline': {'de': 'Annahmeschluss', 'fr': 'Clôture des mises', 'it': 'Chiusura giocate', 'en': 'Entry deadline'},
    'tipUntil': {'de': 'Tippen bis {day}, {time} Uhr', 'fr': 'Jouer jusqu\'au {day}, {time}', 'it': 'Giocare entro {day}, ore {time}', 'en': 'Play until {day}, {time}'},
    'leftDays': {'de': 'noch {d} T {h} Std', 'fr': 'encore {d} j {h} h', 'it': 'ancora {d} g {h} h', 'en': '{d} d {h} h left'},
    'leftHours': {'de': 'noch {h} Std {m} Min', 'fr': 'encore {h} h {m} min', 'it': 'ancora {h} h {m} min', 'en': '{h} h {m} min left'},
    'leftMinutes': {'de': 'noch {m} Min', 'fr': 'encore {m} min', 'it': 'ancora {m} min', 'en': '{m} min left'},
    'deadlineEarliest': {
      'de': 'frühester Termin aller Bundesländer',
      'fr': 'heure la plus précoce de tous les Länder',
      'it': 'orario più anticipato di tutti i Länder',
      'en': 'earliest time of all states'
    },
    'region': {'de': 'Bundesland', 'fr': 'Land (Allemagne)', 'it': 'Land (Germania)', 'en': 'German state'},
    'regionNone': {'de': 'Nicht gewählt', 'fr': 'Non choisi', 'it': 'Non scelto', 'en': 'Not set'},
    'regionBanner': {
      'de': 'Der Annahmeschluss ist je nach Bundesland unterschiedlich. Bis du eines wählst, zeigen wir den frühesten.',
      'fr': 'La clôture varie selon le Land. Tant que vous n\'en choisissez pas, nous affichons la plus précoce.',
      'it': 'La chiusura varia a seconda del Land. Finché non ne scegli uno, mostriamo la più anticipata.',
      'en': 'The entry deadline differs by state. Until you pick one, we show the earliest.'
    },
    'chooseRegion': {'de': 'Bundesland wählen', 'fr': 'Choisir le Land', 'it': 'Scegli il Land', 'en': 'Choose state'},
    'incomplete': {
      'de': 'Mit diesen Filtern wurden nur {n} Serien gefunden.',
      'fr': 'Seulement {n} séries trouvées avec ces filtres.',
      'it': 'Con questi filtri sono state trovate solo {n} serie.',
      'en': 'Only {n} series found with these filters.'
    },
    'saved': {'de': 'Tipp gespeichert', 'fr': 'Grille enregistrée', 'it': 'Schedina salvata', 'en': 'Pick saved'},
    'copied': {'de': 'Kopiert', 'fr': 'Copié', 'it': 'Copiato', 'en': 'Copied'},
    'settings': {'de': 'Einstellungen', 'fr': 'Paramètres', 'it': 'Impostazioni', 'en': 'Settings'},
    'stats': {'de': 'Statistik', 'fr': 'Statistiques', 'it': 'Statistiche', 'en': 'Statistics'},
    'myTips': {'de': 'Meine Tipps', 'fr': 'Mes grilles', 'it': 'Le mie schedine', 'en': 'My picks'},
    'info': {'de': 'Info', 'fr': 'Info', 'it': 'Info', 'en': 'Info'},
    // Einstellungen
    'general': {'de': 'Allgemein', 'fr': 'Général', 'it': 'Generale', 'en': 'General'},
    'language': {'de': 'Sprache', 'fr': 'Langue', 'it': 'Lingua', 'en': 'Language'},
    'country': {'de': 'Land', 'fr': 'Pays', 'it': 'Paese', 'en': 'Country'},
    'countryAll': {'de': 'Alle Lotterien', 'fr': 'Toutes les loteries', 'it': 'Tutte le lotterie', 'en': 'All lotteries'},
    'CH': {'de': 'Schweiz', 'fr': 'Suisse', 'it': 'Svizzera', 'en': 'Switzerland'},
    'DE': {'de': 'Deutschland', 'fr': 'Allemagne', 'it': 'Germania', 'en': 'Germany'},
    'AT': {'de': 'Österreich', 'fr': 'Autriche', 'it': 'Austria', 'en': 'Austria'},
    'seriesCount': {'de': 'Anzahl Serien', 'fr': 'Nombre de séries', 'it': 'Numero di serie', 'en': 'Number of series'},
    'mode': {'de': 'Vorschlagsart', 'fr': 'Type de suggestion', 'it': 'Tipo di proposta', 'en': 'Pick mode'},
    'opt_rare': {'de': 'Seltene Zahlen bevorzugen', 'fr': 'Privilégier les numéros rares', 'it': 'Preferire i numeri rari', 'en': 'Prefer rare numbers'},
    'opt_rare_hint': {
      'de': 'Zahlen, die im Auswertungszeitraum am seltensten gezogen wurden',
      'fr': 'Numéros les moins tirés sur la période analysée',
      'it': 'Numeri estratti più raramente nel periodo analizzato',
      'en': 'Numbers drawn least often in the analysis period'
    },
    'opt_overdue': {
      'de': 'Am längsten nicht gezogene Zahlen bevorzugen',
      'fr': 'Privilégier les numéros absents depuis longtemps',
      'it': 'Preferire i numeri ritardatari',
      'en': 'Prefer numbers not drawn for longest'
    },
    'opt_overdue_hint': {
      'de': 'Zahlen, die seit den meisten Ziehungen nicht mehr gekommen sind',
      'fr': 'Numéros non sortis depuis le plus grand nombre de tirages',
      'it': 'Numeri non usciti da più estrazioni',
      'en': 'Numbers absent for the most draws'
    },
    'opt_none': {
      'de': 'Nichts gewählt: reiner Zufall.',
      'fr': 'Rien de choisi : pur hasard.',
      'it': 'Nessuna scelta: puro caso.',
      'en': 'Nothing selected: pure random.'
    },
    'opt_note': {
      'de': 'Kombinierbar. Keine Option verändert die Gewinnchance – jede Kombination ist gleich wahrscheinlich.',
      'fr': 'Combinables. Aucune option ne change les chances : chaque combinaison est également probable.',
      'it': 'Combinabili. Nessuna opzione cambia le probabilità: ogni combinazione è ugualmente probabile.',
      'en': 'Can be combined. No option changes your odds – every combination is equally likely.'
    },
    'mode_unpopular': {'de': 'Unbeliebte Kombinationen', 'fr': 'Combinaisons peu jouées', 'it': 'Combinazioni poco giocate', 'en': 'Unpopular combinations'},
    'mode_unpopular_hint': {
      'de': 'Bevorzugt Zahlen über 31 und vermeidet Muster. Erhöht nicht die Gewinnchance, aber im Gewinnfall muss seltener geteilt werden.',
      'fr': 'Privilégie les numéros au-dessus de 31 et évite les motifs. N\'augmente pas les chances, mais en cas de gain, le partage est moins fréquent.',
      'it': 'Preferisce i numeri sopra il 31 ed evita gli schemi. Non aumenta le probabilità, ma in caso di vincita si divide meno spesso.',
      'en': 'Prefers numbers above 31 and avoids patterns. Does not raise your odds, but a win is shared less often.'
    },
    'analysisFrom': {'de': 'Auswerten ab', 'fr': 'Analyser à partir du', 'it': 'Analizzare dal', 'en': 'Analyse from'},
    'analysisFromHint': {
      'de': 'Standard: Beginn der aktuellen Spielregel',
      'fr': 'Par défaut : début de la règle actuelle',
      'it': 'Predefinito: inizio della regola attuale',
      'en': 'Default: start of the current rules'
    },
    'reset': {'de': 'Zurücksetzen', 'fr': 'Réinitialiser', 'it': 'Ripristina', 'en': 'Reset'},
    'filters': {'de': 'Ausblenden', 'fr': 'Exclure', 'it': 'Escludere', 'en': 'Exclude'},
    'f_consecutive': {'de': 'Zahlenfolgen (z. B. 12-13-14)', 'fr': 'Suites (p. ex. 12-13-14)', 'it': 'Sequenze (es. 12-13-14)', 'en': 'Runs (e.g. 12-13-14)'},
    'f_progression': {
      'de': 'Zahlenreihen (z. B. 5-10-15-20)',
      'fr': 'Progressions (p. ex. 5-10-15-20)',
      'it': 'Progressioni (es. 5-10-15-20)',
      'en': 'Progressions (e.g. 5-10-15-20)'
    },
    'f_alreadyDrawn': {'de': 'Bereits gezogene Kombinationen', 'fr': 'Combinaisons déjà tirées', 'it': 'Combinazioni già estratte', 'en': 'Already drawn combinations'},
    'f_compareExtras': {
      'de': '… nur wenn auch die Zusatzzahlen gleich sind',
      'fr': '… seulement si les numéros complémentaires sont identiques',
      'it': '… solo se anche i numeri aggiuntivi coincidono',
      'en': '… only if the extra numbers match too'
    },
    'f_allEven': {'de': 'Nur gerade Zahlen', 'fr': 'Uniquement des numéros pairs', 'it': 'Solo numeri pari', 'en': 'Only even numbers'},
    'f_allOdd': {'de': 'Nur ungerade Zahlen', 'fr': 'Uniquement des numéros impairs', 'it': 'Solo numeri dispari', 'en': 'Only odd numbers'},
    'f_allLow': {'de': 'Nur Zahlen bis 31 (Geburtstage)', 'fr': 'Uniquement jusqu\'à 31 (anniversaires)', 'it': 'Solo numeri fino a 31 (compleanni)', 'en': 'Only numbers up to 31 (birthdays)'},
    'f_sameDecade': {'de': 'Alle aus einer Zehnergruppe', 'fr': 'Tous dans la même dizaine', 'it': 'Tutti nella stessa decina', 'en': 'All from one decade'},
    'f_sameEnding': {'de': '4 oder mehr gleiche Endziffern', 'fr': '4 chiffres finaux identiques ou plus', 'it': '4 o più cifre finali uguali', 'en': '4 or more same last digits'},
    'f_sumOutlier': {'de': 'Ungewöhnliche Summe', 'fr': 'Somme inhabituelle', 'it': 'Somma insolita', 'en': 'Unusual sum'},
    'data': {'de': 'Daten', 'fr': 'Données', 'it': 'Dati', 'en': 'Data'},
    'updateNow': {'de': 'Jetzt aktualisieren', 'fr': 'Mettre à jour', 'it': 'Aggiorna ora', 'en': 'Update now'},
    'updated': {'de': '{n} neue Ziehungen geladen', 'fr': '{n} nouveaux tirages chargés', 'it': '{n} nuove estrazioni caricate', 'en': '{n} new draws loaded'},
    'upToDate': {'de': 'Daten sind aktuell', 'fr': 'Les données sont à jour', 'it': 'Dati aggiornati', 'en': 'Data is up to date'},
    'updateFailed': {'de': 'Aktualisierung fehlgeschlagen', 'fr': 'Échec de la mise à jour', 'it': 'Aggiornamento non riuscito', 'en': 'Update failed'},
    'draws': {'de': '{n} Ziehungen', 'fr': '{n} tirages', 'it': '{n} estrazioni', 'en': '{n} draws'},
    // Statistik
    'freq': {'de': 'Häufigkeit', 'fr': 'Fréquence', 'it': 'Frequenza', 'en': 'Frequency'},
    'notSince': {'de': 'Seit {n} Ziehungen nicht gezogen', 'fr': 'Pas tiré depuis {n} tirages', 'it': 'Non estratto da {n} estrazioni', 'en': 'Not drawn for {n} draws'},
    'sortByNumber': {'de': 'Nach Zahl', 'fr': 'Par numéro', 'it': 'Per numero', 'en': 'By number'},
    'sortByFreq': {'de': 'Nach Häufigkeit', 'fr': 'Par fréquence', 'it': 'Per frequenza', 'en': 'By frequency'},
    'extras': {'de': 'Zusatzzahlen', 'fr': 'Numéros complémentaires', 'it': 'Numeri aggiuntivi', 'en': 'Extra numbers'},
    'statsNote': {
      'de': 'Vergangene Ziehungen sagen nichts über künftige aus – jede Kombination ist bei jeder Ziehung gleich wahrscheinlich.',
      'fr': 'Les tirages passés ne prédisent rien : chaque combinaison a la même probabilité à chaque tirage.',
      'it': 'Le estrazioni passate non predicono nulla: ogni combinazione ha la stessa probabilità a ogni estrazione.',
      'en': 'Past draws say nothing about future ones – every combination is equally likely in every draw.'
    },
    // Meine Tipps
    'noTips': {
      'de': 'Noch keine Tipps gespeichert. Tippe bei einem Vorschlag auf das Lesezeichen.',
      'fr': 'Aucune grille enregistrée. Touchez le signet d\'une suggestion.',
      'it': 'Nessuna schedina salvata. Tocca il segnalibro di una proposta.',
      'en': 'No picks saved yet. Tap the bookmark on a pick.'
    },
    'savedOn': {'de': 'Gespeichert am {date}', 'fr': 'Enregistrée le {date}', 'it': 'Salvata il {date}', 'en': 'Saved on {date}'},
    'noDrawYet': {'de': 'Noch keine Ziehung seither', 'fr': 'Pas encore de tirage depuis', 'it': 'Nessuna estrazione da allora', 'en': 'No draw since'},
    'latestResult': {'de': 'Letzte Ziehung: {m} Richtige', 'fr': 'Dernier tirage : {m} bons numéros', 'it': 'Ultima estrazione: {m} numeri esatti', 'en': 'Last draw: {m} correct'},
    'latestResultExtra': {
      'de': 'Letzte Ziehung: {m} Richtige + {e}',
      'fr': 'Dernier tirage : {m} bons numéros + {e}',
      'it': 'Ultima estrazione: {m} esatti + {e}',
      'en': 'Last draw: {m} correct + {e}'
    },
    'bestSince': {'de': 'Bestes Ergebnis seither: {m} Richtige ({date})', 'fr': 'Meilleur résultat : {m} bons numéros ({date})', 'it': 'Miglior risultato: {m} esatti ({date})', 'en': 'Best since: {m} correct ({date})'},
    'delete': {'de': 'Löschen', 'fr': 'Supprimer', 'it': 'Elimina', 'en': 'Delete'},
    // Info
    'disclaimer': {
      'de': 'Lotto ist reiner Zufall. Diese App erstellt Zahlenvorschläge, sie kann keine Ziehung vorhersagen und erhöht die Gewinnchance nicht. Spiele nur mit Geld, auf das du verzichten kannst. Hilfe bei Spielsucht: SOS Spielsucht (CH), check-dein-spiel.de (DE), Spielsuchthilfe (AT).',
      'fr': 'Le loto est un pur hasard. Cette application propose des numéros, elle ne peut prédire aucun tirage et n\'augmente pas les chances de gain. Ne jouez qu\'avec de l\'argent dont vous pouvez vous passer. Aide en cas de dépendance : SOS Jeu (CH).',
      'it': 'Il lotto è puro caso. Questa app propone numeri, non può prevedere alcuna estrazione e non aumenta le probabilità di vincita. Gioca solo con denaro a cui puoi rinunciare. Aiuto per la dipendenza dal gioco: SOS Gioco d\'azzardo (CH).',
      'en': 'Lotto is pure chance. This app suggests numbers; it cannot predict any draw and does not improve your odds. Only play with money you can afford to lose. Help with gambling problems: SOS Spielsucht (CH), check-dein-spiel.de (DE), Spielsuchthilfe (AT).'
    },
    'attribution': {
      'de': 'Ziehungsdaten: lottochaos.com, eurolottospielen.org (CC BY 4.0). Alle Angaben ohne Gewähr.',
      'fr': 'Données des tirages : lottochaos.com, eurolottospielen.org (CC BY 4.0). Sans garantie.',
      'it': 'Dati delle estrazioni: lottochaos.com, eurolottospielen.org (CC BY 4.0). Senza garanzia.',
      'en': 'Draw data: lottochaos.com, eurolottospielen.org (CC BY 4.0). No warranty.'
    },
  };
}
