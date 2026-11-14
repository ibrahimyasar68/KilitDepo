import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/copy_feedback.dart';
import '../../../core/widgets/depth_card.dart';
import '../../../core/widgets/colored_password_text.dart';
import '../../../core/widgets/entry_avatar.dart';
import '../../../core/widgets/spring_swap.dart';
import '../../auth/presentation/widgets/password_strength_meter.dart';
import '../../../domain/entities/password_entry.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/pending_deletions.dart';
import '../application/security_report.dart';
import '../application/vault_providers.dart';
import 'widgets/vault_ui.dart';

/// Kayıt detayı. Şifre yalnızca göster/kopyala anında çözülür.
class EntryDetailScreen extends ConsumerStatefulWidget {
  const EntryDetailScreen({
    super.key,
    required this.entryId,
    this.embedded = false,
    this.onDeleted,
  });

  final int entryId;

  /// Geniş ekranda listenin yanında gömülü gösterim: geri butonu ve
  /// paylaşılan geçiş (Hero) animasyonu yoktur.
  final bool embedded;

  /// Gömülüyken kayıt silinince çağrılır (seçimi temizlemek için).
  final VoidCallback? onDeleted;

  static const Key revealKey = Key('detail_reveal');
  static const Key copyPasswordKey = Key('detail_copy_password');
  static const Key passwordTextKey = Key('detail_password');
  static const Key deleteKey = Key('detail_delete');
  static const Key moreKey = Key('detail_more');
  static const Key copyUsernameKey = Key('detail_copy_username');
  static const Key editKey = Key('detail_edit');
  static const Key favoriteKey = Key('detail_favorite');
  static const Key historyKey = Key('detail_history');
  static const Key undoKey = Key('detail_undo');
  static const Key issueCardKey = Key('detail_issue_card');
  static const Key issueChangeKey = Key('detail_issue_change');
  static const Key undoSnackKey = Key('detail_undo_snack');

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  /// Görünür hâldeki şifre. Gizlenince / ekrandan çıkınca bırakılır.
  String? _revealed;

  @override
  void dispose() {
    _revealed = null;
    super.dispose();
  }

  Future<void> _toggleReveal() async {
    if (_revealed != null) {
      setState(() => _revealed = null);
      return;
    }
    final pw = await requireVaultRepository(ref).revealPassword(widget.entryId);
    if (mounted) setState(() => _revealed = pw);
  }

  Future<void> _copyPassword() async {
    final pw = await requireVaultRepository(ref).revealPassword(widget.entryId);
    if (mounted) await copySecret(context, ref, pw);
  }

  /// Onay penceresi yok: kayıt listeden hemen kalkar, birkaç saniye
  /// "Geri al" ile geri getirilebilir, sonra kalıcı olarak silinir.
  void _delete(EntrySummary entry) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final pending = ref.read(pendingDeletionsProvider.notifier);
    pending.schedule(entry.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: EntryDetailScreen.undoSnackKey,
          duration: PendingDeletions.undoWindow,
          // Süre dolunca kayıt silinir; bildirim de kapanmalı (düğmeli
          // bildirimler varsayılan olarak açık kalır).
          persist: false,
          content: Text(l10n.entryDeletedUndo(entry.title)),
          action: SnackBarAction(
            key: EntryDetailScreen.undoKey,
            label: l10n.commonUndo,
            onPressed: () => pending.undo(entry.id),
          ),
        ),
      );
    if (widget.embedded) {
      widget.onDeleted?.call();
    } else {
      context.go(AppRoutes.vault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = ref.watch(entryDetailsProvider(widget.entryId));

    return details.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: StatusView(
          icon: Icons.error_outline,
          title: l10n.commonUnexpectedError,
        ),
      ),
      data: (d) {
        if (d == null) {
          return Scaffold(
            appBar: AppBar(),
            body: StatusView(icon: Icons.search_off, title: l10n.entryNotFound),
          );
        }
        return _buildDetails(context, d);
      },
    );
  }

  Widget _buildDetails(BuildContext context, EntryDetails d) {
    final l10n = AppLocalizations.of(context);
    final e = d.summary;
    final history = ref.watch(entryHistoryProvider(e.id)).value ?? const [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            key: EntryDetailScreen.favoriteKey,
            tooltip: e.isFavorite
                ? l10n.entryFavoriteRemove
                : l10n.entryFavoriteAdd,
            // Favoriye eklenince yıldız yayla zıplar.
            icon: SpringSwap(
              child: Icon(
                e.isFavorite ? Icons.star : Icons.star_outline,
                key: ValueKey(e.isFavorite),
                color: e.isFavorite ? Colors.amber.shade600 : null,
              ),
            ),
            onPressed: () => requireVaultRepository(
              ref,
            ).setFavorite(e.id, isFavorite: !e.isFavorite),
          ),
          IconButton(
            key: EntryDetailScreen.editKey,
            tooltip: l10n.commonEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.entryEdit(e.id)),
          ),
          // Silme, yanlışlıkla basılmasın diye "Düzenle"nin yanında değil,
          // üç nokta menüsünde.
          PopupMenuButton<String>(
            key: EntryDetailScreen.moreKey,
            tooltip: l10n.entryMoreActions,
            onSelected: (_) => _delete(e),
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                key: EntryDetailScreen.deleteKey,
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    l10n.commonDelete,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Başlık: listedeki rozet buraya büyüyerek taşınır (Hero).
          Center(
            child: HeroMode(
              // Gömülüyken listedeki rozetle aynı ekranda olduğu için
              // geçiş animasyonu kapalı (aynı etiketli iki Hero olamaz).
              enabled: !widget.embedded,
              child: Hero(
                tag: 'avatar_${e.id}',
                child: EntryAvatar.of(e, size: 72),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            e.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              avatar: Icon(e.category.icon, size: 18),
              label: Text(e.category.label(l10n)),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 20),
          // En sık yapılan iş: büyük, belirgin kopyalama düğmeleri.
          Row(
            children: [
              if (e.username.isNotEmpty) ...[
                Expanded(
                  child: CopyFeedback(
                    onCopy: () =>
                        copySecret(context, ref, e.username, isPassword: false),
                    builder: (context, icon, onPressed) =>
                        FilledButton.tonalIcon(
                          key: EntryDetailScreen.copyUsernameKey,
                          onPressed: onPressed,
                          icon: icon,
                          label: Text(l10n.detailCopyUsernameShort),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: CopyFeedback(
                  onCopy: _copyPassword,
                  builder: (context, icon, onPressed) => FilledButton.icon(
                    key: EntryDetailScreen.copyPasswordKey,
                    onPressed: onPressed,
                    icon: icon,
                    label: Text(l10n.detailCopyPasswordShort),
                  ),
                ),
              ),
            ],
          ),
          _IssueCard(entryId: e.id),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  if (e.username.isNotEmpty)
                    _FieldRow(
                      label: l10n.entryUsernameLabel,
                      value: SelectableText(e.username),
                    ),
                  _FieldRow(
                    label: l10n.entryPasswordLabel,
                    value: _revealed == null
                        ? const Text(
                            '••••••••••••',
                            key: EntryDetailScreen.passwordTextKey,
                            style: TextStyle(fontSize: 16, letterSpacing: 2),
                          )
                        : ColoredPasswordText(
                            _revealed!,
                            key: EntryDetailScreen.passwordTextKey,
                          ),
                    below: _revealed == null
                        ? null
                        : PasswordStrengthMeter(password: _revealed!),
                    actions: [
                      IconButton(
                        key: EntryDetailScreen.revealKey,
                        tooltip: _revealed == null
                            ? l10n.entryShowPassword
                            : l10n.entryHidePassword,
                        icon: Icon(
                          _revealed == null
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: _toggleReveal,
                      ),
                    ],
                  ),
                  if (e.url != null)
                    _FieldRow(
                      label: l10n.entryUrlLabel,
                      // Uygulama çevrimdışıdır: URL açılmaz, yalnızca kopyalanır.
                      value: SelectableText(e.url!),
                      actions: [
                        IconButton(
                          tooltip: l10n.entryCopyUrl,
                          icon: const Icon(Icons.copy),
                          onPressed: () => copySecret(
                            context,
                            ref,
                            e.url!,
                            isPassword: false,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (d.notes != null) ...[
            const SizedBox(height: 12),
            Card(
              child: _FieldRow(
                label: l10n.entryNotesLabel,
                value: SelectableText(d.notes!),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              key: EntryDetailScreen.historyKey,
              leading: const Icon(Icons.history),
              title: Text(l10n.entryHistory),
              subtitle: Text(l10n.entryHistoryCount(history.length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.entryHistory(e.id)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.entryCreatedAt}: ${formatDateTime(context, e.createdAt)}\n'
            '${l10n.entryUpdatedAt}: ${formatDateTime(context, e.updatedAt)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detay kartındaki etiket + değer + eylemler satırı.
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    this.actions = const [],
    this.below,
  });

  final String label;
  final Widget value;
  final List<Widget> actions;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                value,
                if (below != null) ...[const SizedBox(height: 8), below!],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Kaydın güvenlik sorunu varsa kısa açıklama ve "Şifreyi değiştir".
/// Bilgi güvenlik raporundan gelir; burada şifre çözülmez.
class _IssueCard extends ConsumerWidget {
  const _IssueCard({required this.entryId});

  final int entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(entryIssuesProvider)[entryId];
    if (issues == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titles = {
      for (final e in ref.watch(entriesProvider).value ?? <EntrySummary>[])
        e.id: e.title,
    };
    final (bg, fg) = issues.weak
        ? (scheme.errorContainer, scheme.onErrorContainer)
        : (scheme.tertiaryContainer, scheme.onTertiaryContainer);
    final style = theme.textTheme.bodyMedium?.copyWith(color: fg);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DepthCard(
        key: EntryDetailScreen.issueCardKey,
        color: bg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.gpp_maybe_outlined, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (issues.weak)
                          Text(l10n.detailIssueWeak, style: style),
                        if (issues.weak && issues.reused)
                          const SizedBox(height: 6),
                        if (issues.reused)
                          Text(
                            l10n.detailIssueReused(
                              [
                                for (final id in issues.reusedWith)
                                  if (titles[id] != null) titles[id]!,
                              ].join(', '),
                            ),
                            style: style,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: EntryDetailScreen.issueChangeKey,
                  style: TextButton.styleFrom(foregroundColor: fg),
                  onPressed: () => context.push(AppRoutes.entryEdit(entryId)),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.detailIssueChange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
