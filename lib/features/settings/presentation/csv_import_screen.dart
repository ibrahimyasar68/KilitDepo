import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/entry_avatar.dart';
import '../../../data/import/csv_import.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auto_lock_guard.dart';
import '../../vault/application/vault_providers.dart';
import '../application/csv_import_service.dart';

/// Başka bir uygulamanın CSV dışa aktarımından kayıt ekleme.
///
/// Akış: bilgi → dosya seç → önizleme (şifreler gösterilmez) → içe aktar →
/// "orijinal dosyayı silin" hatırlatması. Düz metin içerik yalnızca bu
/// ekran açıkken bellekte tutulur.
class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  static const Key pickKey = Key('csv_pick');
  static const Key confirmKey = Key('csv_confirm');
  static const Key previewKey = Key('csv_preview');
  static const Key doneKey = Key('csv_done');
  static const Key errorKey = Key('csv_error');
  static const Key finishKey = Key('csv_finish');

  /// Önizlemede en fazla bu kadar başlık listelenir.
  static const int previewLimit = 50;

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

enum _Phase { intro, reading, preview, importing, done }

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  _Phase _phase = _Phase.intro;
  CsvImportPreview? _preview;
  int _added = 0;
  String? _error;

  @override
  void dispose() {
    // Düz metin içerik bellekten bırakılır.
    _preview = null;
    super.dispose();
  }

  String _errorText(AppLocalizations l10n, CsvImportError e) => switch (e) {
    CsvImportError.empty => l10n.csvImportErrorEmpty,
    CsvImportError.encoding => l10n.csvImportErrorEncoding,
    CsvImportError.tooLarge => l10n.csvImportErrorTooLarge,
    CsvImportError.missingColumns => l10n.csvImportErrorColumns,
  };

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _preview = null;
    });
    try {
      // Dosya seçici açıkken arka plan kilidi askıya alınır (yedekteki gibi).
      final bytes = await runWithAutoLockSuspended(
        ref,
        () => ref.read(csvFileReaderProvider).read(),
      );
      if (bytes == null || !mounted) return;
      setState(() => _phase = _Phase.reading);
      final parsed = CsvImporter.parseBytes(bytes);
      bytes.fillRange(0, bytes.length, 0); // en iyi çaba: ham baytları sil
      final preview = await CsvImportService(
        requireVaultRepository(ref),
      ).preview(parsed);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _phase = _Phase.preview;
      });
    } on CsvImportException catch (e) {
      if (mounted) {
        setState(() {
          _error = _errorText(l10n, e.reason);
          _phase = _Phase.intro;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _error = l10n.commonUnexpectedError;
          _phase = _Phase.intro;
        });
      }
    }
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _phase = _Phase.importing);
    try {
      final added = await CsvImportService(
        requireVaultRepository(ref),
      ).commit(preview.toAdd);
      if (!mounted) return;
      setState(() {
        _added = added;
        _preview = null;
        _phase = _Phase.done;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _error = l10n.commonUnexpectedError;
          _phase = _Phase.preview;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.csvImportScreenTitle)),
      body: switch (_phase) {
        _Phase.reading || _Phase.importing => _Busy(
          text: _phase == _Phase.reading
              ? l10n.csvImportReading
              : l10n.csvImportImporting,
        ),
        _Phase.preview => _buildPreview(context, l10n, _preview!),
        _Phase.done => _buildDone(context, l10n),
        _Phase.intro => _buildIntro(context, l10n),
      },
    );
  }

  Widget _errorBanner(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Card(
      key: CsvImportScreen.errorKey,
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: TextStyle(color: theme.colorScheme.onErrorContainer),
        ),
      ),
    ),
  );

  Widget _buildIntro(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) _errorBanner(theme),
        Icon(Icons.file_upload_outlined, size: 48, color: scheme.primary),
        const SizedBox(height: 16),
        Text(l10n.csvImportIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Card(
          color: scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.csvImportPlainWarning,
                    style: TextStyle(color: scheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.csvImportHowTo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: CsvImportScreen.pickKey,
          onPressed: _pick,
          icon: const Icon(Icons.folder_open),
          label: Text(l10n.csvImportPick),
        ),
      ],
    );
  }

  String _formatName(AppLocalizations l10n, CsvImportFormat f) => switch (f) {
    CsvImportFormat.chrome => l10n.csvFormatChrome,
    CsvImportFormat.firefox => l10n.csvFormatFirefox,
    CsvImportFormat.apple => l10n.csvFormatApple,
    CsvImportFormat.bitwarden => l10n.csvFormatBitwarden,
    CsvImportFormat.onePassword => l10n.csvFormatOnePassword,
    CsvImportFormat.protonPass => l10n.csvFormatProtonPass,
    CsvImportFormat.keePass => l10n.csvFormatKeePass,
    CsvImportFormat.generic => l10n.csvFormatGeneric,
  };

  Widget _buildPreview(
    BuildContext context,
    AppLocalizations l10n,
    CsvImportPreview p,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = p.toAdd.take(CsvImportScreen.previewLimit).toList();

    Widget line(IconData icon, String text, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    return Column(
      key: CsvImportScreen.previewKey,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              if (_error != null) _errorBanner(theme),
              Text(
                l10n.csvImportFormatLabel(_formatName(l10n, p.format)),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.toAdd.isEmpty)
                        line(
                          Icons.info_outline,
                          l10n.csvImportNothing,
                          scheme.onSurfaceVariant,
                        )
                      else
                        line(
                          Icons.add_circle_outline,
                          l10n.csvImportToAdd(p.toAdd.length),
                          scheme.primary,
                        ),
                      if (p.duplicates > 0)
                        line(
                          Icons.content_copy_outlined,
                          l10n.csvImportDuplicates(p.duplicates),
                          scheme.onSurfaceVariant,
                        ),
                      if (p.skippedNoPassword > 0)
                        line(
                          Icons.remove_circle_outline,
                          l10n.csvImportNoPassword(p.skippedNoPassword),
                          scheme.onSurfaceVariant,
                        ),
                      if (p.totpDropped > 0)
                        line(
                          Icons.gpp_maybe_outlined,
                          l10n.csvImportTotp(p.totpDropped),
                          scheme.tertiary,
                        ),
                    ],
                  ),
                ),
              ),
              if (shown.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.csvImportPreviewList,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                // Yalnızca başlık ve kullanıcı adı; şifre gösterilmez.
                for (final c in shown)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: EntryAvatar(title: c.title, size: 36),
                    title: Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: c.username.isEmpty
                        ? null
                        : Text(
                            c.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                if (p.toAdd.length > shown.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.csvImportMore(p.toAdd.length - shown.length),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _pick,
                    child: Text(
                      l10n.csvImportOtherFile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: CsvImportScreen.confirmKey,
                    onPressed: p.toAdd.isEmpty ? null : _import,
                    child: Text(l10n.csvImportConfirm),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDone(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      key: CsvImportScreen.doneKey,
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.check_circle_outline, size: 56, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
          l10n.csvImportDone(_added),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        // Uygulama orijinal dosyayı silemez: kullanıcıya açıkça hatırlat.
        Card(
          color: scheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.delete_forever_outlined,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.csvImportDeleteReminder,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: CsvImportScreen.finishKey,
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.csvImportFinish),
        ),
      ],
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(text),
      ],
    ),
  );
}
