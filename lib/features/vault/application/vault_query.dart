import 'package:flutter/foundation.dart';

import '../../../core/utils/turkish_text.dart';
import '../../../domain/entities/entry_category.dart';
import '../../../domain/entities/password_entry.dart';

enum EntrySort { alphabetical, recentlyAdded, recentlyUpdated, category }

/// Liste ekranının arama / filtre / sıralama durumu.
@immutable
class VaultQuery {
  const VaultQuery({
    this.search = '',
    this.sort = EntrySort.alphabetical,
    this.category,
    this.favoritesOnly = false,
  });

  final String search;
  final EntrySort sort;

  /// null → tüm kategoriler.
  final EntryCategory? category;
  final bool favoritesOnly;

  VaultQuery copyWith({
    String? search,
    EntrySort? sort,
    EntryCategory? category,
    bool clearCategory = false,
    bool? favoritesOnly,
  }) => VaultQuery(
    search: search ?? this.search,
    sort: sort ?? this.sort,
    category: clearCategory ? null : (category ?? this.category),
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
  );
}

/// Arama (başlık, kullanıcı adı, URL), filtre ve sıralamayı uygular.
///
/// Bellekte yapılır: kişisel bir kasa için birkaç yüz kayıt sorun değildir
/// ve Türkçe harf kuralları SQLite'ta doğru işlenmez.
List<EntrySummary> applyVaultQuery(
  List<EntrySummary> entries,
  VaultQuery query,
) {
  final needle = TurkishText.fold(query.search.trim());
  final result = entries.where((e) {
    if (query.favoritesOnly && !e.isFavorite) return false;
    if (query.category != null && e.category != query.category) return false;
    if (needle.isEmpty) return true;
    return _keysOf(e).searchText.contains(needle);
  }).toList();

  int byTitle(EntrySummary a, EntrySummary b) => TurkishText.compareLowered(
    _keysOf(a).loweredTitle,
    _keysOf(b).loweredTitle,
    a.title,
    b.title,
  );

  result.sort(switch (query.sort) {
    EntrySort.alphabetical => byTitle,
    EntrySort.recentlyAdded => (a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      return c != 0 ? c : b.id.compareTo(a.id);
    },
    EntrySort.recentlyUpdated => (a, b) {
      final c = b.updatedAt.compareTo(a.updatedAt);
      return c != 0 ? c : b.id.compareTo(a.id);
    },
    EntrySort.category => (a, b) {
      final c = a.category.index.compareTo(b.category.index);
      return c != 0 ? c : byTitle(a, b);
    },
  });
  return result;
}

/// Kayıt başına önceden hesaplanmış arama/sıralama anahtarları.
///
/// Liste akışı aynı [EntrySummary] nesnelerini koruduğu için anahtarlar
/// her kayıt için bir kez hesaplanır; aramada her harfte ve sıralamada her
/// karşılaştırmada yeniden çevirme yapılmaz. Nesne bırakılınca anahtarları
/// da çöp toplayıcıya bırakılır. (Yalnızca başlık / kullanıcı adı / URL;
/// gizli alan içermez.)
final Expando<({String searchText, String loweredTitle})> _keyCache = Expando();

({String searchText, String loweredTitle}) _keysOf(EntrySummary e) =>
    _keyCache[e] ??= (
      // Alanlar arasında ayırıcı (\n): bir alanın sonu ile diğerinin başı
      // birleşip yanlış eşleşme oluşturmasın.
      searchText: TurkishText.fold('${e.title}\n${e.username}\n${e.url ?? ''}'),
      loweredTitle: TurkishText.lower(e.title),
    );
