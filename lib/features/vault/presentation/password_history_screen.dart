import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/security_params.dart';
import '../../../core/widgets/colored_password_text.dart';
import '../../../domain/entities/password_entry.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/vault_providers.dart';
import 'widgets/vault_ui.dart';

/// Bir kaydın eski şifreleri, en yeniden eskiye zaman çizelgesi olarak.
/// Şifreler yalnızca göster/kopyala anında çözülür.
class PasswordHistoryScreen extends ConsumerWidget {
  const PasswordHistoryScreen({super.key, required this.entryId});

  final int entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(entryHistoryProvider(entryId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => StatusView(
          icon: Icons.error_outline,
          title: l10n.commonUnexpectedError,
        ),
        data: (items) => items.isEmpty
            ? StatusView(icon: Icons.history, title: l10n.historyEmpty)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                    child: Text(
                      l10n.historyInfo(SecurityParams.passwordHistoryLimit),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  for (var i = 0; i < items.length; i++)
                    _TimelineItem(
                      item: items[i],
                      isFirst: i == 0,
                      isLast: i == items.length - 1,
                    ),
                ],
              ),
      ),
    );
  }
}

/// Zaman çizelgesinde tek bir eski şifre: solda nokta ve çizgi, sağda kart.
class _TimelineItem extends ConsumerStatefulWidget {
  const _TimelineItem({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final PasswordHistoryItem item;
  final bool isFirst;
  final bool isLast;

  @override
  ConsumerState<_TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends ConsumerState<_TimelineItem> {
  String? _revealed;

  @override
  void dispose() {
    _revealed = null;
    super.dispose();
  }

  Future<String> _reveal() =>
      requireVaultRepository(ref).revealHistoryPassword(widget.item.id);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // En yeni değişiklik vurgulu, eskiler sönük.
    final dotColor = widget.isFirst ? scheme.primary : scheme.outline;

    return IntrinsicHeight(
      key: Key('history_${widget.item.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 18,
                  color: widget.isFirst
                      ? Colors.transparent
                      : scheme.outlineVariant,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: widget.isFirst ? dotColor : scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2.5),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: widget.isLast
                        ? Colors.transparent
                        : scheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.historyChangedAt(
                                formatDateTime(context, widget.item.changedAt),
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _revealed == null
                                ? const Text(
                                    '••••••••••••',
                                    style: TextStyle(
                                      fontSize: 16,
                                      letterSpacing: 2,
                                    ),
                                  )
                                : ColoredPasswordText(_revealed!),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _revealed == null
                            ? l10n.entryShowPassword
                            : l10n.entryHidePassword,
                        icon: Icon(
                          _revealed == null
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () async {
                          if (_revealed != null) {
                            setState(() => _revealed = null);
                            return;
                          }
                          final pw = await _reveal();
                          if (mounted) setState(() => _revealed = pw);
                        },
                      ),
                      IconButton(
                        tooltip: l10n.entryCopyPassword,
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          final pw = await _reveal();
                          if (context.mounted) {
                            await copySecret(context, ref, pw);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
