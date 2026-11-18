/// Adresse, unter der die GitHub Action die aktuellen Ziehungsdaten ablegt
/// (Ordner `data/` dieses Repos). Nach dem ersten Push anpassen.
const String kDataBaseUrl = 'https://raw.githubusercontent.com/DanWid456/Zahlenfee---Lotto-Tipps/assets/data';

/// Frühestens so viele Stunden nach einer Ziehung wird nach Updates gesucht
/// ("1 Tag nach Veröffentlichung").
const int kUpdateDelayHours = 24;

/// Mindestabstand zwischen zwei automatischen Update-Prüfungen.
const int kMinCheckIntervalHours = 6;
