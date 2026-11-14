import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/motion.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../core/widgets/copy_feedback.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../core/widgets/spring_swap.dart';
import '../../../core/widgets/entry_avatar.dart';
import '../../../core/widgets/depth_card.dart';
import '../../../domain/entities/entry_category.dart';
import '../../../domain/entities/password_entry.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../home/home_shell.dart';
import '../application/security_report.dart';
import '../application/vault_providers.dart';
import '../application/vault_query.dart';
import 'entry_detail_screen.dart';
import 'widgets/vault_ui.dart';

/// Kasa ana ekranı: arama, filtre, sıralama ve kayıt listesi.
class VaultListScreen extends ConsumerStatefulWidget {
  const VaultListScreen({super.key});

  static const Key lockButtonKey = Key('vault_lock');
  static const Key addButtonKey = Key('vault_add');
  static const Key searchFieldKey = Key('vault_search');
  static const Key sortButtonKey = Key('vault_sort');
  static const Key favoritesChipKey = Key('vault_favorites');
  static const Key filterChipsKey = Key('vault_filter_chips');
  static const Key guidePromptKey = Key('vault_guide_prompt');
  static const Key securityBannerKey = Key('vault_security_banner');
  static const Key detailPlaceholderKey = Key('vault_detail_placeholder');
  static const Key actionsSheetKey = Key('vault_actions_sheet');
  static const Key favoritesStripKey = Key('vault_favorites_strip');

  @override
  ConsumerState<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends ConsumerState<VaultListScreen> {
  bool _twoPane = false;

  /// Dar ekranda ayrıntı sayfasını açar; geniş ekranda sağda gösterir.
  void _openEntry(int id) {
    if (_twoPane) {
      setState(() => _selectedId = id);
    } else {
      context.push(AppRoutes.entryDetail(id));
    }
  }

  late final TextEditingController _search;

  /// Geniş ekranda (iki sütun) sağda gösterilen kayıt.
  int? _selectedId;

  /// Bu genişlikten itibaren liste ve detay yan yana gösterilir.
  static const double twoPaneMinWidth = 840;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(vaultQueryProvider).search);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowGuidePrompt(),
    );
  }

  /// İlk kurulumdan sonra bir kez: "Kullanma talimatına göz atmak ister
  /// misiniz?" Kapatılabilir ve bir daha sorulmaz.
  Future<void> _maybeShowGuidePrompt() async {
    final settings = ref.read(appSettingsProvider);
    try {
      if (await settings.guidePromptShown()) return;
      await settings.setGuidePromptShown();
    } on Object {
      return; // Ayar okunamazsa sormaktan vazgeç.
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: VaultListScreen.guidePromptKey,
        icon: const Icon(Icons.menu_book_outlined),
        title: Text(l10n.guidePromptTitle),
        content: Text(l10n.guidePromptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.guidePromptLater),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.guidePromptOpen),
          ),
        ],
      ),
    );
    if (open == true && mounted) context.push(AppRoutes.guide);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    ref.read(vaultQueryProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(vaultQueryProvider);
    final notifier = ref.read(vaultQueryProvider.notifier);
    final all = ref.watch(entriesProvider);
    final filtered = ref.watch(filteredEntriesProvider);
    final isEmptyVault = all.value?.isEmpty ?? false;

    // Kaydırınca küçülen büyük başlık.
    final appBar = SliverAppBar.large(
      title: Text(l10n.vaultTitle),
      actions: [
        PopupMenuButton<EntrySort>(
          key: VaultListScreen.sortButtonKey,
          tooltip: l10n.vaultSort,
          icon: const Icon(Icons.sort),
          initialValue: query.sort,
          onSelected: notifier.setSort,
          itemBuilder: (_) => [
            for (final sort in EntrySort.values)
              CheckedPopupMenuItem(
                value: sort,
                checked: sort == query.sort,
                child: Text(sort.label(l10n)),
              ),
          ],
        ),
        IconButton(
          key: VaultListScreen.lockButtonKey,
          tooltip: l10n.vaultLock,
          icon: const Icon(Icons.lock_outline),
          onPressed: () => ref.read(authControllerProvider.notifier).lock(),
        ),
      ],
    );

    // Boş / hata durumları alt çubuğun (buzlu cam, içeriğin üstünde)
    // arkasında kalmasın.
    Widget fill(Widget child) => SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: child,
      ),
    );

    final List<Widget> content = all.when(
      loading: () => [fill(const Center(child: CircularProgressIndicator()))],
      error: (_, _) => [
        fill(
          StatusView(
            icon: Icons.error_outline,
            title: l10n.vaultLoadError,
            action: OutlinedButton(
              onPressed: () => ref.invalidate(storedEntriesProvider),
              child: Text(l10n.commonRetry),
            ),
          ),
        ),
      ],
      data: (entries) {
        if (entries.isEmpty) {
          return [
            fill(
              StatusView(
                icon: Icons.inventory_2_outlined,
                title: l10n.vaultEmptyTitle,
                body: l10n.vaultEmptyBody,
                action: FilledButton.icon(
                  key: VaultListScreen.addButtonKey,
                  onPressed: () => context.push(AppRoutes.entryNew),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.vaultAddFirst),
                ),
              ),
            ),
          ];
        }
        final visible = filtered.value ?? const <EntrySummary>[];
        return [
          const SliverToBoxAdapter(child: _SecurityBanner()),
          // Hızlı erişim: arama / filtre yokken favoriler şeridi.
          if (query.search.isEmpty &&
              query.category == null &&
              !query.favoritesOnly &&
              entries.any((e) => e.isFavorite))
            SliverToBoxAdapter(
              child: _FavoritesStrip(
                favorites: [
                  for (final e in entries)
                    if (e.isFavorite) e,
                ]..sort((a, b) => TurkishText.compare(a.title, b.title)),
                onOpen: _openEntry,
              ),
            ),
          // Arama ve filtreler kaydırınca kaybolmaz; üstte sabit kalır.
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedHeader(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: SearchBar(
                      key: VaultListScreen.searchFieldKey,
                      controller: _search,
                      hintText: l10n.vaultSearchHint,
                      leading: const Icon(Icons.search),
                      elevation: const WidgetStatePropertyAll(0),
                      onChanged: notifier.setSearch,
                      trailing: [
                        if (query.search.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              notifier.setSearch('');
                            },
                          ),
                      ],
                    ),
                  ),
                  _FilterChips(query: query, entries: entries),
                ],
              ),
            ),
          ),
          if (visible.isEmpty)
            fill(
              StatusView(
                icon: Icons.search_off,
                title: l10n.vaultNoResultsTitle,
                body: l10n.vaultNoResultsBody,
                action: TextButton(
                  onPressed: _clearFilters,
                  child: Text(l10n.vaultClearFilters),
                ),
              ),
            )
          else
            SliverPadding(
              // Alt çubuk içeriğin üstünde (buzlu cam): son kayıt + butonu
              // ve çubuğun üstünde kalsın.
              padding: EdgeInsets.only(
                bottom: 96 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: _entryList(
                visible,
                selectedId: _twoPane ? _selectedId : null,
                onOpen: _openEntry,
              ),
            ),
        ];
      },
    );

    return Scaffold(
      floatingActionButton: isEmptyVault
          ? null
          // Ana eylem: çevresinde yumuşak marka rengi parıltısı. Buzlu cam
          // alt çubuk içeriğin üstünde durduğu için buton, çubuğun eklediği
          // boşluk kadar yukarı alınır (Scaffold bunu kendisi hesaba katmaz).
          : Padding(
              padding: EdgeInsets.only(
                bottom: math.max(
                  0,
                  MediaQuery.paddingOf(context).bottom -
                      MediaQuery.viewPaddingOf(context).bottom,
                ),
              ),
              // Aşağı kaydırınca (alt çubukla birlikte) yalnızca "+"
              // simgesine küçülür; yay eğrisiyle.
              child: GlowBox(child: _AddButton(label: l10n.vaultAdd)),
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final list = CustomScrollView(slivers: [appBar, ...content]);
          _twoPane = constraints.maxWidth >= twoPaneMinWidth;
          if (!_twoPane) return list;
          // Geniş ekran: solda liste, sağda seçili kaydın ayrıntısı.
          final selected = _selectedId;
          return Row(
            children: [
              SizedBox(width: 400, child: list),
              const VerticalDivider(width: 1),
              Expanded(
                child: selected == null
                    ? StatusView(
                        key: VaultListScreen.detailPlaceholderKey,
                        icon: Icons.touch_app_outlined,
                        title: l10n.vaultSelectEntry,
                      )
                    : EntryDetailScreen(
                        key: ValueKey('embedded_$selected'),
                        entryId: selected,
                        embedded: true,
                        onDeleted: () => setState(() => _selectedId = null),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Zayıf / tekrar kullanılan şifre varsa küçük uyarı şeridi.
class _SecurityBanner extends ConsumerWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final count = ref.watch(securityReportProvider).value?.issueCount ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          key: VaultListScreen.securityBannerKey,
          dense: true,
          leading: Icon(
            Icons.gpp_maybe_outlined,
            color: scheme.onErrorContainer,
          ),
          title: Text(
            l10n.reportBanner(count),
            style: TextStyle(color: scheme.onErrorContainer),
          ),
          trailing: Text(
            l10n.reportBannerAction,
            style: TextStyle(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Rapor bir sekme: üzerine sayfa açmak yerine sekmeye geç.
          onTap: () => context.go(AppRoutes.securityReport),
        ),
      ),
    );
  }
}

/// Arama çubuğu + filtre çiplerini kaydırınca üstte sabit tutar.
class _PinnedHeader extends SliverPersistentHeaderDelegate {
  const _PinnedHeader({required this.child});

  final Widget child;

  static const double height = 124;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      // Altından içerik geçerken buzlu cam; aksi hâlde zemin görünür.
      GlassSurface(enabled: overlaps, edge: GlassEdge.bottom, child: child);

  @override
  bool shouldRebuild(_PinnedHeader old) => old.child != child;
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.query, required this.entries});

  final VaultQuery query;

  /// Kasadaki tüm kayıtlar (çiplerdeki sayılar için).
  final List<EntrySummary> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(vaultQueryProvider.notifier);
    final counts = <EntryCategory, int>{};
    var favorites = 0;
    for (final e in entries) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
      if (e.isFavorite) favorites++;
    }

    Widget label(String text, int count) => Text.rich(
      TextSpan(
        text: text,
        children: [
          TextSpan(
            text: '  $count',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      height: 52,
      child: ListView(
        key: VaultListScreen.filterChipsKey,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          FilterChip(
            key: VaultListScreen.favoritesChipKey,
            showCheckmark: false,
            avatar: Icon(
              query.favoritesOnly ? Icons.star : Icons.star_outline,
              size: 18,
            ),
            label: label(l10n.vaultFilterFavorites, favorites),
            selected: query.favoritesOnly,
            onSelected: (_) => notifier.toggleFavoritesOnly(),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            showCheckmark: false,
            label: label(l10n.vaultFilterAll, entries.length),
            selected: query.category == null,
            onSelected: (_) => notifier.setCategory(null),
          ),
          for (final c in EntryCategory.values) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              key: Key('vault_category_${c.key}'),
              showCheckmark: false,
              avatar: Icon(c.icon, size: 18),
              label: label(c.label(l10n), counts[c] ?? 0),
              selected: query.category == c,
              onSelected: (_) => notifier.setCategory(c),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kayıt kartlarının listesi.
///
/// Satır widget'ları tembel (lazy) oluşturulur: yalnızca ekranda görünenler
/// kurulur; aramada her harfte tüm liste yeniden oluşturulmaz. Satırlar ilk
/// görünüşte sırayla, hafifçe belirir.
Widget _entryList(
  List<EntrySummary> entries, {
  required void Function(int id) onOpen,
  int? selectedId,
}) {
  final indexOf = {
    for (var i = 0; i < entries.length; i++) _fadeKey(entries[i].id): i,
  };
  return SliverList.builder(
    itemCount: entries.length,
    // Filtre/sıralama değişince var olan satırların durumu (ör. belirme
    // animasyonu) anahtarla eşleştirilerek korunur.
    findChildIndexCallback: (key) => indexOf[key],
    itemBuilder: (context, i) {
      final entry = entries[i];
      return StaggeredFadeIn(
        key: _fadeKey(entry.id),
        index: i,
        child: _EntryTile(
          entry: entry,
          selected: entry.id == selectedId,
          onOpen: () => onOpen(entry.id),
        ),
      );
    },
  );
}

Key _fadeKey(int id) => ValueKey('fade_$id');

/// Liste öğesini ilk görünüşte, sırasına göre gecikmeli olarak aşağıdan
/// yukarı kaydırıp belirginleştirir. Zamanlayıcı kullanmaz (tek animasyon,
/// gecikme eğri aralığıyla verilir). Sistemde "animasyonları kapat" açıksa
/// animasyon yapılmaz.
class StaggeredFadeIn extends StatelessWidget {
  const StaggeredFadeIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  static const Duration _step = Duration(milliseconds: 40);
  static const Duration _base = Duration(milliseconds: 380);
  static const int _maxStaggered = 10;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delaySteps = index.clamp(0, _maxStaggered);
    final total = _base + _step * delaySteps;
    final start = (_step * delaySteps).inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1),
      child: child,
      // Saydamlık düz (yay saydamlığı 1'in üstüne taşır), kayma yayla.
      builder: (context, t, child) => Opacity(
        opacity: Curves.easeOut.transform(t),
        child: Transform.translate(
          offset: Offset(0, (1 - AppMotion.spring.transform(t)) * 16),
          child: child,
        ),
      ),
    );
  }
}

/// Kayıt kartı. Sağdaki düğme şifreyi tek dokunuşla kopyalar; uzun basınca
/// işlem menüsü açılır. Sağa kaydırınca şifre kopyalanır, sola kaydırınca
/// favori durumu değişir; kart yerinde kalır.
class _EntryTile extends ConsumerWidget {
  const _EntryTile({
    required this.entry,
    required this.onOpen,
    this.selected = false,
  });

  final EntrySummary entry;
  final VoidCallback onOpen;
  final bool selected;

  Future<void> _copyPassword(BuildContext context, WidgetRef ref) async {
    final password = await requireVaultRepository(ref).revealPassword(entry.id);
    if (context.mounted) await copySecret(context, ref, password);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget swipeBackground({
      required Alignment alignment,
      required IconData icon,
      required String label,
      required Color color,
      required Color onColor,
    }) => Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: onColor)),
        ],
      ),
    );

    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final issues = ref.watch(entryIssuesProvider)[entry.id];

    // Kaydırma arka planı kartın yuvarlak köşelerine göre kırpılır.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // Derinlikli kart: basınca küçülür, gölgesi içeri çekilir; seçili
      // kartın (iki sütun) çevresinde parıltı.
      child: DepthCard(
        pressable: true,
        color: selected ? scheme.secondaryContainer : null,
        glow: selected ? scheme.primary : null,
        child: Dismissible(
          key: Key('entry_swipe_${entry.id}'),
          background: swipeBackground(
            alignment: Alignment.centerLeft,
            icon: Icons.copy,
            label: l10n.swipeCopy,
            color: scheme.primary,
            onColor: scheme.onPrimary,
          ),
          secondaryBackground: swipeBackground(
            alignment: Alignment.centerRight,
            icon: entry.isFavorite ? Icons.star_outline : Icons.star,
            label: l10n.swipeFavorite,
            color: scheme.tertiaryContainer,
            onColor: scheme.onTertiaryContainer,
          ),
          // Kayıt hiçbir zaman listeden silinmez; yalnızca eylem tetiklenir.
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _copyPassword(context, ref);
            } else {
              unawaited(HapticFeedback.selectionClick());
              await requireVaultRepository(
                ref,
              ).setFavorite(entry.id, isFavorite: !entry.isFavorite);
            }
            return false;
          },
          child: ListTile(
            key: Key('entry_tile_${entry.id}'),
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            leading: Hero(
              tag: 'avatar_${entry.id}',
              child: EntryAvatar.of(entry),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                // Favoriye eklenince yıldız yayla zıplar.
                SpringSwap(
                  child: entry.isFavorite
                      ? Padding(
                          key: const ValueKey(true),
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.star_rounded,
                            key: Key('entry_star_${entry.id}'),
                            size: 18,
                            color: Colors.amber.shade600,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey(false)),
                ),
                // Güvenlik uyarıları görüldüğü yerde (rapordan; şifre
                // çözülmez).
                if (issues?.weak ?? false) ...[
                  const SizedBox(width: 6),
                  IssueBadge(
                    key: Key('entry_weak_${entry.id}'),
                    label: l10n.issueWeakBadge,
                    color: scheme.errorContainer,
                    onColor: scheme.onErrorContainer,
                  ),
                ],
                if (issues?.reused ?? false) ...[
                  const SizedBox(width: 6),
                  IssueBadge(
                    key: Key('entry_reused_${entry.id}'),
                    label: l10n.issueReusedBadge,
                    color: scheme.tertiaryContainer,
                    onColor: scheme.onTertiaryContainer,
                  ),
                ],
              ],
            ),
            // Alt satır: kategori simgesi + kullanıcı adı (yoksa kategori).
            subtitle: Row(
              children: [
                Icon(
                  entry.category.icon,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.username.isEmpty
                        ? entry.category.label(l10n)
                        : entry.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
              ],
            ),
            trailing: CopyFeedback(
              onCopy: () => _copyPassword(context, ref),
              builder: (context, icon, onPressed) => IconButton(
                key: Key('entry_copy_${entry.id}'),
                tooltip: l10n.entryCopyPassword,
                icon: icon,
                onPressed: onPressed,
              ),
            ),
            selected: selected,
            onTap: onOpen,
            onLongPress: () {
              unawaited(HapticFeedback.mediumImpact());
              showEntryActions(context, ref, entry);
            },
          ),
        ),
      ),
    );
  }
}

/// Favoriler şeridi (hızlı erişim). Dokununca şifre kopyalanır (en sık
/// yapılan iş); uzun basınca işlem menüsü ("Ayrıntıları aç" dahil).
class _FavoritesStrip extends ConsumerWidget {
  const _FavoritesStrip({required this.favorites, required this.onOpen});

  final List<EntrySummary> favorites;
  final void Function(int id) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      key: VaultListScreen.favoritesStripKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade600),
              const SizedBox(width: 6),
              Text(l10n.vaultQuickAccess, style: theme.textTheme.titleSmall),
            ],
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // Kart gölgeleri şeridin kenarında kesilip çizgi oluşturmasın.
            clipBehavior: Clip.none,
            // Gölgeler kırpılmasın diye dikeyde de boşluk.
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            itemCount: favorites.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final e = favorites[i];
              return _FavoriteTile(
                key: Key('favorite_${e.id}'),
                entry: e,
                onOpen: () => onOpen(e.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({super.key, required this.entry, required this.onOpen});

  final EntrySummary entry;
  final VoidCallback onOpen;

  Future<void> _copy(BuildContext context, WidgetRef ref) async {
    final password = await requireVaultRepository(ref).revealPassword(entry.id);
    if (context.mounted) await copySecret(context, ref, password);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Küçük, hap biçimli kutu: açıklayıcı simge (kayda seçilen simge, yoksa
    // kategorinin simgesi) + başlık + küçük kopyala simgesi.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: CopyFeedback(
        onCopy: () => _copy(context, ref),
        builder: (context, icon, onPressed) => Semantics(
          button: true,
          label: '${entry.title}, ${l10n.entryCopyPassword}',
          excludeSemantics: true,
          child: DepthCard(
            pressable: true,
            child: InkWell(
              onTap: onPressed,
              onLongPress: () {
                unawaited(HapticFeedback.mediumImpact());
                showEntryActions(context, ref, entry, onOpen: onOpen);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EntryAvatar.of(
                      entry,
                      size: 32,
                      fallbackIcon: entry.category.icon,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Kopyalama simgesi (kopyalanınca ✓ olur).
                    IconTheme(
                      data: IconThemeData(
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      child: icon,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uzun basınca açılan işlem menüsü (alt panel). Kaydırma hareketini
/// bilmeyen kullanıcı da tüm hızlı işlemlere buradan ulaşır.
Future<void> showEntryActions(
  BuildContext context,
  WidgetRef ref,
  EntrySummary entry, {
  VoidCallback? onOpen,
}) {
  final l10n = AppLocalizations.of(context);
  final repo = requireVaultRepository(ref);

  // Kopyalama, alt panel kapandıktan sonra ana ekranın bağlamıyla yapılır
  // (pano geri sayım bildirimi orada gösterilir).
  Future<void> copy(
    Future<String> Function() read, {
    bool isPassword = false,
  }) async {
    final value = await read();
    if (context.mounted) {
      await copySecret(context, ref, value, isPassword: isPassword);
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // İçerik kadar yükseklik; küçük ekranda kaydırılabilir.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) {
      void run(Future<void> Function() action) {
        Navigator.pop(sheet);
        unawaited(action());
      }

      return SingleChildScrollView(
        // Alt sistem çubuğunun (hareket çubuğu) üstünde kalsın.
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(sheet).bottom),
        child: Column(
          key: VaultListScreen.actionsSheetKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: EntryAvatar.of(entry),
              title: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
              subtitle: entry.username.isEmpty ? null : Text(entry.username),
            ),
            const Divider(),
            if (onOpen != null)
              ListTile(
                key: const Key('action_open'),
                leading: const Icon(Icons.open_in_new),
                title: Text(l10n.entryOpenDetails),
                onTap: () {
                  Navigator.pop(sheet);
                  onOpen();
                },
              ),
            if (entry.username.isNotEmpty)
              ListTile(
                key: const Key('action_copy_username'),
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.entryCopyUsername),
                onTap: () => run(() => copy(() async => entry.username)),
              ),
            ListTile(
              key: const Key('action_copy_password'),
              leading: const Icon(Icons.key_outlined),
              title: Text(l10n.entryCopyPassword),
              onTap: () => run(
                () =>
                    copy(() => repo.revealPassword(entry.id), isPassword: true),
              ),
            ),
            if (entry.url != null)
              ListTile(
                key: const Key('action_copy_url'),
                leading: const Icon(Icons.link),
                title: Text(l10n.entryCopyUrl),
                onTap: () => run(() => copy(() async => entry.url!)),
              ),
            ListTile(
              key: const Key('action_favorite'),
              leading: Icon(
                entry.isFavorite ? Icons.star_outline : Icons.star_rounded,
              ),
              title: Text(
                entry.isFavorite
                    ? l10n.entryFavoriteRemove
                    : l10n.entryFavoriteAdd,
              ),
              onTap: () => run(
                () => repo.setFavorite(entry.id, isFavorite: !entry.isFavorite),
              ),
            ),
            ListTile(
              key: const Key('action_edit'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.commonEdit),
              onTap: () => run(() async {
                if (context.mounted) {
                  unawaited(context.push(AppRoutes.entryEdit(entry.id)));
                }
              }),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// "+ Yeni kayıt": alt çubuk kompakt olunca yalnızca "+" simgesine küçülür
/// (yay eğrisiyle). "Animasyonları kapat" açıksa anında değişir
/// (sıfır süreli AnimatedSize kullanılmaz; Flutter'da düzen hatası verir).
class _AddButton extends StatelessWidget {
  const _AddButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton.extended(
      key: VaultListScreen.addButtonKey,
      tooltip: label,
      isExtended: !ShellChrome.compactOf(context),
      onPressed: () => context.push(AppRoutes.entryNew),
      icon: const Icon(Icons.add),
      label: Text(label),
    );
    final duration = AppMotion.of(context);
    if (duration == Duration.zero) return fab;
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.spring,
      child: fab,
    );
  }
}
