/// GitHub-Repo der App (öffentlich): Datendateien, Jackpots und App-Updates.
const String kGitHubRepo = 'DanWid456/Zahlenfee---Lotto-Tipps';

/// Adresse, unter der die GitHub Actions die aktuellen Ziehungsdaten ablegen.
const String kDataBaseUrl = 'https://raw.githubusercontent.com/$kGitHubRepo/main/assets/data';

/// Frühestens so viele Stunden nach einer Ziehung wird nach Updates gesucht
/// ("1 Tag nach Veröffentlichung").
const int kUpdateDelayHours = 24;

/// Mindestabstand zwischen zwei automatischen Update-Prüfungen.
const int kMinCheckIntervalHours = 6;
