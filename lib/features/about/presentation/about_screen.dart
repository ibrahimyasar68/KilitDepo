import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/presentation/settings_screen.dart'
    show appVersionProvider;

/// Hakkında sayfası. Kasa verisine ERİŞMEZ; kasa kilitliyken de açılabilir.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const Key producerKey = Key('about_producer');
  static const Key licensesKey = Key('about_licenses');
  static const Key copyrightKey = Key('about_copyright');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final version = ref.watch(appVersionProvider).value;
    final year = DateTime.now().year;

    Widget section(String title, IconData icon, List<String> items) => Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle_outline, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const Center(child: AppLogo(size: 48)),
          const SizedBox(height: 8),
          if (version != null)
            Text(
              l10n.aboutVersion(version),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 4),
          // Hakkında sayfasında etiket belirgin gösterilir.
          Text(
            AppInfo.producerLabel,
            key: producerKey,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.aboutDescription, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          section(l10n.aboutPrivacyTitle, Icons.privacy_tip_outlined, [
            l10n.aboutPrivacy1,
            l10n.aboutPrivacy2,
            l10n.aboutPrivacy3,
          ]),
          const SizedBox(height: 12),
          section(l10n.aboutSecurityTitle, Icons.shield_outlined, [
            l10n.aboutSecurity1,
            l10n.aboutSecurity2,
            l10n.aboutSecurity3,
            l10n.aboutSecurity4,
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: licensesKey,
            icon: const Icon(Icons.description_outlined),
            label: Text(l10n.aboutLicenses),
            onPressed: () => showLicensePage(
              context: context,
              applicationName: AppInfo.appName,
              applicationVersion: version,
              applicationLegalese: AppInfo.legalese(year),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppInfo.copyright(year),
            key: copyrightKey,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
