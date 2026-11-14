import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/utils/turkish_text.dart';
import 'package:kilitdepo/domain/entities/entry_category.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/vault/application/vault_query.dart';

EntrySummary e(
  int id,
  String title, {
  String username = '',
  String? url,
  EntryCategory category = EntryCategory.other,
  bool fav = false,
  int created = 0,
  int updated = 0,
}) => EntrySummary(
  id: id,
  uuid: 'u$id',
  title: title,
  username: username,
  url: url,
  category: category,
  isFavorite: fav,
  createdAt: DateTime(2026).add(Duration(minutes: created)),
  updatedAt: DateTime(2026).add(Duration(minutes: updated)),
);

List<String> titles(List<EntrySummary> l) => l.map((x) => x.title).toList();

void main() {
  group('TurkishText', () {
    test('Türkçe küçük harf: I → ı, İ → i', () {
      expect(TurkishText.lower('IŞIK İZMİR'), 'ışık izmir');
    });

    test('aksan duyarsız arama', () {
      expect(TurkishText.containsFolded('Şifre Yöneticisi', 'sifre'), isTrue);
      expect(TurkishText.containsFolded('İstanbul', 'istanbul'), isTrue);
      expect(TurkishText.containsFolded('ISPARTA', 'isparta'), isTrue);
      expect(TurkishText.containsFolded('Gmail', 'yahoo'), isFalse);
    });

    test('Türkçe alfabe sırası', () {
      final words = [
        'Zeytin',
        'çiçek',
        'Cam',
        'ılık',
        'iğne',
        'Şeker',
        'su',
        'Öykü',
        'otel',
        'Üzüm',
        'uçak',
        'Ğ',
        'g',
        '1Password',
      ];
      words.sort(TurkishText.compare);
      expect(words, [
        '1Password',
        'Cam',
        'çiçek',
        'g',
        'Ğ',
        'ılık',
        'iğne',
        'otel',
        'Öykü',
        'su',
        'Şeker',
        'uçak',
        'Üzüm',
        'Zeytin',
      ]);
    });
  });

  group('applyVaultQuery', () {
    final entries = [
      e(
        1,
        'Twitter',
        username: 'kus',
        category: EntryCategory.socialMedia,
        created: 1,
        updated: 5,
      ),
      e(
        2,
        'Ziraat Bankası',
        url: 'https://ziraat.com.tr',
        category: EntryCategory.bank,
        fav: true,
        created: 2,
        updated: 2,
      ),
      e(
        3,
        'Çalışma Maili',
        username: 'ibrahim@is.com',
        category: EntryCategory.work,
        created: 3,
        updated: 3,
      ),
      e(
        4,
        'Gmail',
        username: 'ibrahim@gmail.com',
        category: EntryCategory.email,
        fav: true,
        created: 4,
        updated: 1,
      ),
    ];

    test('alfabetik (Türkçe)', () {
      expect(titles(applyVaultQuery(entries, const VaultQuery())), [
        'Çalışma Maili',
        'Gmail',
        'Twitter',
        'Ziraat Bankası',
      ]);
    });

    test('son eklenen', () {
      expect(
        titles(
          applyVaultQuery(
            entries,
            const VaultQuery(sort: EntrySort.recentlyAdded),
          ),
        ),
        ['Gmail', 'Çalışma Maili', 'Ziraat Bankası', 'Twitter'],
      );
    });

    test('son güncellenen', () {
      expect(
        titles(
          applyVaultQuery(
            entries,
            const VaultQuery(sort: EntrySort.recentlyUpdated),
          ),
        ),
        ['Twitter', 'Çalışma Maili', 'Ziraat Bankası', 'Gmail'],
      );
    });

    test('kategoriye göre (sabit kategori sırası, sonra başlık)', () {
      expect(
        titles(
          applyVaultQuery(entries, const VaultQuery(sort: EntrySort.category)),
        ),
        ['Twitter', 'Ziraat Bankası', 'Gmail', 'Çalışma Maili'],
      );
    });

    test('arama: başlık, kullanıcı adı ve URL içinde', () {
      expect(
        titles(applyVaultQuery(entries, const VaultQuery(search: 'ibrahim'))),
        ['Çalışma Maili', 'Gmail'],
      );
      expect(
        titles(
          applyVaultQuery(entries, const VaultQuery(search: 'ziraat.com')),
        ),
        ['Ziraat Bankası'],
      );
      expect(
        titles(applyVaultQuery(entries, const VaultQuery(search: 'CALISMA'))),
        ['Çalışma Maili'],
      );
    });

    test('kategori filtresi ve favoriler', () {
      expect(
        titles(
          applyVaultQuery(
            entries,
            const VaultQuery(category: EntryCategory.bank),
          ),
        ),
        ['Ziraat Bankası'],
      );
      expect(
        titles(applyVaultQuery(entries, const VaultQuery(favoritesOnly: true))),
        ['Gmail', 'Ziraat Bankası'],
      );
    });

    test('filtreler birleşir', () {
      expect(
        applyVaultQuery(
          entries,
          const VaultQuery(favoritesOnly: true, search: 'twitter'),
        ),
        isEmpty,
      );
    });

    test('arama alanların sınırını aşan eşleşme üretmez', () {
      final l = [e(1, 'abc', username: 'def')];
      expect(applyVaultQuery(l, const VaultQuery(search: 'cd')), isEmpty);
      expect(applyVaultQuery(l, const VaultQuery(search: 'DEF')), hasLength(1));
    });
  });
}
