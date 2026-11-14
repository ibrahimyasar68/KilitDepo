import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/crypto_params.dart';
import '../../../core/widgets/password_field.dart';
import '../../../data/backup/backup_codec.dart';
import '../../../domain/entities/backup_entry.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auto_lock_guard.dart';
import '../../auth/presentation/widgets/password_strength_meter.dart';
import '../../vault/application/vault_providers.dart';
import '../application/backup_providers.dart';
import '../application/settings_providers.dart';

/// Şifreli yedek: dışa aktarma ve içe aktarma (birleştirme).
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.backupIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const _ExportCard(),
          const SizedBox(height: 16),
          const _ImportCard(),
        ],
      ),
    );
  }
}

class _ExportCard extends ConsumerStatefulWidget {
  const _ExportCard();

  @override
  ConsumerState<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends ConsumerState<_ExportCard> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_password, _confirm]) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _export() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    void show(String text) =>
        messenger.showSnackBar(SnackBar(content: Text(text)));

    setState(() => _busy = true);
    try {
      final entries = await requireVaultRepository(ref).exportEntries();
      if (entries.isEmpty) {
        show(l10n.backupEmptyVault);
        return;
      }
      final bytes = await ref
          .read(backupCodecProvider)
          .encode(entries, _password.text);
      final saved = await runWithAutoLockSuspended(
        ref,
        () => ref
            .read(backupFileGatewayProvider)
            .save(BackupCodec.suggestedFileName(DateTime.now()), bytes),
      );
      if (saved) {
        _password.clear();
        _confirm.clear();
        // Yedek hatırlatması için yalnızca tarih saklanır.
        await ref.read(appSettingsProvider).setLastBackupAt(DateTime.now());
        ref.invalidate(lastBackupAtProvider);
        show(l10n.backupExported(entries.length));
      } else {
        show(l10n.backupExportCancelled);
      }
    } on Object {
      show(l10n.commonUnexpectedError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file),
                title: Text(
                  l10n.backupExportTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.backupPasswordWarning,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                key: const Key('backup_password'),
                controller: _password,
                label: l10n.backupPasswordLabel,
                enabled: !_busy,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.setupPasswordRequired;
                  if (v.length < CryptoParams.minBackupPasswordLength) {
                    return l10n.setupPasswordTooShort(
                      CryptoParams.minBackupPasswordLength,
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              PasswordStrengthMeter(password: _password.text),
              const SizedBox(height: 16),
              PasswordField(
                key: const Key('backup_confirm'),
                controller: _confirm,
                label: l10n.backupPasswordConfirm,
                enabled: !_busy,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    v != _password.text ? l10n.setupPasswordMismatch : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('backup_export'),
                onPressed: _busy ? null : _export,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(
                  _busy ? l10n.backupExporting : l10n.backupExportButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportCard extends ConsumerStatefulWidget {
  const _ImportCard();

  @override
  ConsumerState<_ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends ConsumerState<_ImportCard> {
  final _password = TextEditingController();
  String? _fileName;
  Uint8List? _file;

  /// Çözülmüş yedek: yalnızca önizleme ile aktarma arasında bellekte.
  List<BackupEntry>? _entries;
  ImportSummary? _preview;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    _entries = null;
    super.dispose();
  }

  void _reset() {
    _password.clear();
    _file = null;
    _fileName = null;
    _entries = null;
    _preview = null;
    _error = null;
  }

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    try {
      final picked = await runWithAutoLockSuspended(
        ref,
        () => ref.read(backupFileGatewayProvider).pick(),
      );
      if (picked == null || !mounted) return;
      setState(() {
        _reset();
        _file = picked.bytes;
        _fileName = picked.name;
      });
    } on BackupFormatException {
      setState(() => _error = l10n.backupInvalidFile);
    } on Object {
      setState(() => _error = l10n.commonUnexpectedError);
    }
  }

  Future<void> _decrypt() async {
    final file = _file;
    if (file == null || _password.text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final entries = await ref
          .read(backupCodecProvider)
          .decode(file, _password.text);
      final preview = await requireVaultRepository(ref).previewImport(entries);
      _password.clear();
      setState(() {
        _entries = entries;
        _preview = preview;
      });
    } on BackupWrongPasswordException {
      setState(() => _error = l10n.backupWrongPassword);
    } on BackupFormatException {
      setState(() => _error = l10n.backupInvalidFile);
    } on Object {
      setState(() => _error = l10n.commonUnexpectedError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final entries = _entries;
    if (entries == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final result = await requireVaultRepository(ref).importEntries(entries);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.backupImported(result.added, result.updated)),
        ),
      );
      setState(_reset);
    } on Object {
      setState(() => _error = l10n.commonUnexpectedError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final preview = _preview;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore),
              title: Text(
                l10n.backupImportTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(l10n.backupImportBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('backup_pick'),
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.folder_open),
              label: Text(l10n.backupChooseFile),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Text(l10n.backupSelectedFile(_fileName!)),
            ],
            if (_file != null && preview == null) ...[
              const SizedBox(height: 16),
              PasswordField(
                key: const Key('backup_import_password'),
                controller: _password,
                label: l10n.backupPasswordLabel,
                enabled: !_busy,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _decrypt(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('backup_decrypt'),
                onPressed: _busy ? null : _decrypt,
                child: Text(
                  _busy ? l10n.backupDecrypting : l10n.backupDecryptButton,
                ),
              ),
            ],
            if (preview != null) ...[
              const SizedBox(height: 16),
              Text(
                l10n.backupPreview(
                  preview.total,
                  preview.added,
                  preview.updated,
                  preview.skipped,
                ),
                key: const Key('backup_preview'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('backup_import'),
                onPressed: _busy ? null : _import,
                icon: const Icon(Icons.download_done),
                label: Text(l10n.backupImportButton),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const Key('backup_error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
