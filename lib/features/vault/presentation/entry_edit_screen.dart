import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/entry_appearance.dart';
import '../../../core/widgets/entry_avatar.dart';
import '../../../core/widgets/password_field.dart';
import '../../../domain/entities/entry_category.dart';
import '../../auth/presentation/widgets/password_strength_meter.dart';
import '../../generator/presentation/generator_screen.dart';
import '../../../domain/entities/password_entry.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/save_error.dart';
import '../application/vault_providers.dart';
import 'widgets/appearance_sheet.dart';
import 'widgets/vault_ui.dart';

/// Kayıt ekleme ([entryId] null) veya düzenleme ekranı.
class EntryEditScreen extends ConsumerStatefulWidget {
  const EntryEditScreen({super.key, this.entryId});

  final int? entryId;

  static const Key titleKey = Key('edit_title');
  static const Key usernameKey = Key('edit_username');
  static const Key passwordKey = Key('edit_password');
  static const Key urlKey = Key('edit_url');
  static const Key notesKey = Key('edit_notes');
  static const Key categoryKey = Key('edit_category');
  static const Key favoriteKey = Key('edit_favorite');
  static const Key saveKey = Key('edit_save');
  static const Key generateKey = Key('edit_generate');
  static const Key appearanceKey = Key('edit_appearance');

  @override
  ConsumerState<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends ConsumerState<EntryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _url = TextEditingController();
  final _notes = TextEditingController();
  EntryCategory _category = EntryCategory.other;
  bool _favorite = false;
  String? _iconKey;
  String? _colorKey;

  bool _loading = false;
  bool _saving = false;
  bool _loadFailed = false;
  bool _saved = false;
  String _initialSignature = '';

  bool get _isEdit => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    _initialSignature = _signature();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entry = await requireVaultRepository(ref).getEntry(widget.entryId!);
      _title.text = entry.summary.title;
      _username.text = entry.summary.username;
      _password.text = entry.password;
      _url.text = entry.summary.url ?? '';
      _notes.text = entry.notes ?? '';
      _category = entry.summary.category;
      _favorite = entry.summary.isFavorite;
      _iconKey = entry.summary.iconKey;
      _colorKey = entry.summary.colorKey;
      _initialSignature = _signature();
    } on Object {
      _loadFailed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Değişiklik tespiti için alanların özeti (yalnızca bellekte).
  String _signature() => [
    _title.text,
    _username.text,
    _password.text,
    _url.text,
    _notes.text,
    _category.key,
    '$_favorite',
    '$_iconKey',
    '$_colorKey',
  ].join('\u0000');

  bool get _dirty => !_saved && _signature() != _initialSignature;

  String _saveErrorText(AppLocalizations l10n, Object error) {
    final f = classifySaveError(error);
    return switch (f.kind) {
      SaveFailureKind.locked => l10n.entrySaveErrorLocked,
      SaveFailureKind.invalid => l10n.entrySaveErrorInvalid,
      SaveFailureKind.storageFull => l10n.entrySaveErrorStorageFull,
      SaveFailureKind.busy => l10n.entrySaveErrorBusy,
      SaveFailureKind.database => l10n.entrySaveErrorDatabase(f.detail),
      SaveFailureKind.crypto => l10n.entrySaveErrorCrypto,
      SaveFailureKind.unknown => l10n.entrySaveErrorUnknown(f.detail),
    };
  }

  @override
  void dispose() {
    // En iyi çaba: hassas alanları boşalt.
    for (final c in [_title, _username, _password, _url, _notes]) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final draft = EntryDraft(
      title: _title.text,
      username: _username.text,
      password: _password.text,
      url: _url.text,
      notes: _notes.text,
      category: _category,
      isFavorite: _favorite,
      iconKey: _iconKey,
      colorKey: _colorKey,
    );
    try {
      final repo = requireVaultRepository(ref);
      if (_isEdit) {
        await repo.updateEntry(widget.entryId!, draft);
      } else {
        await repo.addEntry(draft);
      }
      _saved = true;
    } on Object catch (e) {
      // Nedeni kısaca söyle (gizli veri içermez).
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(_saveErrorText(l10n, e)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    // Kapatma, kaydetme hatası yakalayıcısının DIŞINDA: kayıt yapıldıktan
    // sonra bir gezinme sorunu "kaydedilemedi" diye gösterilmesin.
    if (_saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.entrySaved)));
      if (mounted) context.pop();
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.entryDiscardTitle),
        content: Text(l10n.entryDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.entryKeepEditing),
          ),
          TextButton(
            key: const Key('edit_discard_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.entryDiscardConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          _saved = true; // Uyarıyı tekrar gösterme.
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? l10n.entryEditTitle : l10n.entryNewTitle),
          actions: [
            TextButton(
              key: EntryEditScreen.saveKey,
              onPressed: (_saving || _loading || _loadFailed) ? null : _save,
              child: Text(l10n.commonSave),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
            ? StatusView(icon: Icons.search_off, title: l10n.entryNotFound)
            : _buildForm(l10n),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    final theme = Theme.of(context);

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );

    return Form(
      key: _formKey,
      onChanged: () => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          section(l10n.entrySectionAccount, [
            TextFormField(
              key: EntryEditScreen.titleKey,
              controller: _title,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: '${l10n.entryTitleLabel} *',
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.entryTitleRequired
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: EntryEditScreen.usernameKey,
              controller: _username,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.entryUsernameLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: EntryEditScreen.urlKey,
              controller: _url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.entryUrlLabel,
                prefixIcon: const Icon(Icons.link),
              ),
            ),
          ]),
          section(l10n.entrySectionPassword, [
            PasswordField(
              key: EntryEditScreen.passwordKey,
              controller: _password,
              label: '${l10n.entryPasswordLabel} *',
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.entryPasswordRequired : null,
            ),
            const SizedBox(height: 8),
            // Yazarken canlı güç göstergesi.
            PasswordStrengthMeter(password: _password.text),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: EntryEditScreen.generateKey,
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.generatorGenerateButton),
                onPressed: () async {
                  final generated = await showGeneratorSheet(context);
                  if (generated != null) {
                    setState(() => _password.text = generated);
                  }
                },
              ),
            ),
          ]),
          section(l10n.entrySectionOther, [
            // Rozet görünümü: başlık yazıldıkça önizleme güncellenir.
            ListenableBuilder(
              listenable: _title,
              builder: (context, _) {
                final title = _title.text.trim().isEmpty
                    ? '?'
                    : _title.text.trim();
                final icon = EntryAppearanceCatalog.icon(_iconKey);
                final color = EntryAppearanceCatalog.color(_colorKey);
                final parts = [
                  if (icon != null) icon.label(l10n),
                  if (color != null) color.label(l10n),
                ];
                return ListTile(
                  key: EntryEditScreen.appearanceKey,
                  contentPadding: EdgeInsets.zero,
                  leading: EntryAvatar(
                    title: title,
                    iconKey: _iconKey,
                    colorKey: _colorKey,
                  ),
                  title: Text(l10n.entryAppearance),
                  subtitle: Text(
                    parts.isEmpty
                        ? l10n.entryAppearanceDefault
                        : parts.join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showAppearanceSheet(
                      context,
                      title: title,
                      initial: (icon: _iconKey, color: _colorKey),
                    );
                    if (picked == null) return;
                    setState(() {
                      _iconKey = picked.icon;
                      _colorKey = picked.color;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Text(l10n.entryCategoryLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              key: EntryEditScreen.categoryKey,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in EntryCategory.values)
                  ChoiceChip(
                    key: Key('category_${c.key}'),
                    avatar: Icon(c.icon, size: 18),
                    label: Text(c.label(l10n)),
                    selected: _category == c,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: EntryEditScreen.notesKey,
              controller: _notes,
              minLines: 3,
              maxLines: 8,
              enableIMEPersonalizedLearning: false,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.entryNotesLabel,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: EntryEditScreen.favoriteKey,
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.star_outline),
              title: Text(l10n.entryFavoriteLabel),
              value: _favorite,
              onChanged: (v) => setState(() => _favorite = v),
            ),
          ]),
        ],
      ),
    );
  }
}
