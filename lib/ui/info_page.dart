import 'package:flutter/material.dart';

import '../l10n/strings.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('info'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${s.t('appTitle')} – ${s.t('appSubtitle')}', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(s.t('disclaimer'), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text(s.t('attribution'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('Version 0.1.0', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
