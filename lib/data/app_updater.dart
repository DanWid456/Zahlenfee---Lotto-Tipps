import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';

/// Eine neuere App-Version auf GitHub Releases.
class AppUpdate {
  const AppUpdate(this.version, this.buildNumber, this.downloadUrl);
  final String version; // z. B. 0.1.12
  final int buildNumber;
  final String downloadUrl; // direkter APK-Download
}

/// Neueste verfügbare Version (null = aktuell oder unbekannt).
final ValueNotifier<AppUpdate?> availableUpdate = ValueNotifier<AppUpdate?>(null);

/// Prüft GitHub Releases auf eine neuere APK (nur für die Verteilung ausserhalb
/// des Play Stores; dort übernimmt Google die Updates).
class AppUpdater {
  /// Liefert die neuere Version oder null. Wirft bei Netzwerkfehlern.
  static Future<AppUpdate?> check() async {
    final info = await PackageInfo.fromPlatform();
    final current = int.tryParse(info.buildNumber) ?? 0;
    final res = await http
        .get(Uri.parse('https://api.github.com/repos/$kGitHubRepo/releases/latest'),
            headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 404) return null; // noch kein Release
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return parseRelease(j, current);
  }

  /// Ausgelagert für Tests. Tag-Format: v0.1.<Buildnummer>.
  static AppUpdate? parseRelease(Map<String, dynamic> j, int currentBuild) {
    final tag = (j['tag_name'] as String? ?? '').replaceFirst('v', '');
    final build = int.tryParse(tag.split('.').last) ?? 0;
    if (build <= currentBuild) return null;
    final assets = (j['assets'] as List? ?? []).cast<Map<String, dynamic>>();
    final apk = assets.where((a) => (a['name'] as String? ?? '').endsWith('.apk'));
    final url = apk.isNotEmpty
        ? apk.first['browser_download_url'] as String
        : (j['html_url'] as String? ?? 'https://github.com/$kGitHubRepo/releases/latest');
    return AppUpdate(tag, build, url);
  }

  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
