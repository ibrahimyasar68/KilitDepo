import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/vault_repository_impl.dart';
import '../../../domain/entities/entry_category.dart';
import '../../../domain/entities/password_entry.dart';
import '../../../domain/repositories/vault_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import 'pending_deletions.dart';
import 'vault_query.dart';

/// Kasa açıkken repository, kilitliyken null.
///
/// Kilitlenince bu sağlayıcı yeniden hesaplanır; böylece kapatılmış
/// veritabanına referans tutan nesne kalmaz.
final vaultRepositoryProvider = Provider<VaultRepository?>((ref) {
  final status = ref.watch(authControllerProvider.select((s) => s.status));
  if (status != AuthStatus.unlocked) return null;
  final session = ref.watch(vaultSessionProvider);
  if (!session.isOpen) return null;
  return VaultRepositoryImpl(
    db: session.database,
    fieldKey: session.fieldKey,
    crypto: ref.watch(cryptoServiceProvider),
  );
});

/// İşlem (ekle/güncelle/sil) için repository. Kilitliyse hata.
VaultRepository requireVaultRepository(WidgetRef ref) =>
    ref.read(vaultRepositoryProvider) ?? (throw StateError('Kasa kilitli.'));

/// Veritabanındaki kayıtlar (ham akış). Ekranlar [entriesProvider] kullanır.
final storedEntriesProvider = StreamProvider<List<EntrySummary>>((ref) {
  final repo = ref.watch(vaultRepositoryProvider);
  return repo == null ? Stream.value(const []) : repo.watchEntries();
});

/// Kasadaki kayıtlar; silinmesi beklenen ("Geri al" süresindeki) kayıtlar
/// hariç. Liste, rapor ve sayılar bunu kullanır.
final entriesProvider = Provider<AsyncValue<List<EntrySummary>>>((ref) {
  final hidden = ref.watch(pendingDeletionsProvider);
  final stored = ref.watch(storedEntriesProvider);
  if (hidden.isEmpty) return stored;
  return stored.whenData(
    (entries) => [
      for (final e in entries)
        if (!hidden.contains(e.id)) e,
    ],
  );
});

class VaultQueryNotifier extends Notifier<VaultQuery> {
  @override
  VaultQuery build() => const VaultQuery();

  void setSearch(String value) => state = state.copyWith(search: value);
  void setSort(EntrySort sort) => state = state.copyWith(sort: sort);
  void toggleFavoritesOnly() =>
      state = state.copyWith(favoritesOnly: !state.favoritesOnly);
  void setCategory(EntryCategory? category) => state = category == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: category);
  void clearFilters() => state = VaultQuery(sort: state.sort);
}

final vaultQueryProvider = NotifierProvider<VaultQueryNotifier, VaultQuery>(
  VaultQueryNotifier.new,
);

/// Arama/filtre/sıralama uygulanmış liste.
final filteredEntriesProvider = Provider<AsyncValue<List<EntrySummary>>>((ref) {
  final query = ref.watch(vaultQueryProvider);
  return ref
      .watch(entriesProvider)
      .whenData((entries) => applyVaultQuery(entries, query));
});

final entryDetailsProvider = StreamProvider.autoDispose
    .family<EntryDetails?, int>((ref, id) {
      final repo = ref.watch(vaultRepositoryProvider);
      return repo == null ? Stream.value(null) : repo.watchEntry(id);
    });

final entryHistoryProvider = StreamProvider.autoDispose
    .family<List<PasswordHistoryItem>, int>((ref, entryId) {
      final repo = ref.watch(vaultRepositoryProvider);
      return repo == null ? Stream.value(const []) : repo.watchHistory(entryId);
    });
