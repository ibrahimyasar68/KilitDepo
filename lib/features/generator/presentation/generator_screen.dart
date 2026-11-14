import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/copy_feedback.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../vault/presentation/widgets/vault_ui.dart';
import 'generator_panel.dart';

/// Tam ekran şifre üretici.
class GeneratorScreen extends ConsumerWidget {
  const GeneratorScreen({super.key});

  static const Key copyKey = Key('gen_copy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.generatorTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          GeneratorPanel(
            actions: (context, password) => CopyFeedback(
              onCopy: () => copySecret(context, ref, password),
              builder: (context, icon, onPressed) => FilledButton.icon(
                key: copyKey,
                icon: icon,
                label: Text(l10n.commonCopy),
                onPressed: onPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kayıt formundan açılan alt panel. "Kullan" denirse şifreyi döndürür.
Future<String?> showGeneratorSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: GeneratorPanel(
          actions: (context, password) => FilledButton.icon(
            key: const Key('gen_use'),
            icon: const Icon(Icons.check),
            label: Text(l10n.generatorUse),
            onPressed: () => Navigator.pop(context, password),
          ),
        ),
      ),
    ),
  );
}
