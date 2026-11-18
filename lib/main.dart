import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/repository.dart';
import 'l10n/strings.dart';
import 'settings/settings.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  final repo = DrawRepository();
  await repo.loadAll();
  runApp(LottoApp(settings: settings, repo: repo));
}

class LottoApp extends StatefulWidget {
  const LottoApp({super.key, required this.settings, required this.repo});
  final AppSettings settings;
  final DrawRepository repo;

  @override
  State<LottoApp> createState() => _LottoAppState();
}

class _LottoAppState extends State<LottoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoUpdate();
  }

  /// Automatisches Update: einen Tag nach jeder fälligen Ziehung.
  Future<void> _autoUpdate() async {
    final s = widget.settings;
    if (!widget.repo.updateDue(DateTime.now(), s.lastUpdateCheck)) return;
    s.lastUpdateCheck = DateTime.now();
    await widget.repo.update();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) => MaterialApp(
        title: 'Zahlenfee',
        debugShowCheckedModeBanner: false,
        locale: Locale(widget.settings.language),
        supportedLocales: [for (final l in S.supported) Locale(l)],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(colorSchemeSeed: const Color(0xFF1B6E4A), useMaterial3: true),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF1B6E4A),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: HomePage(settings: widget.settings, repo: widget.repo),
      ),
    );
  }
}
