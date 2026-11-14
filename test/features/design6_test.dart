import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/core/widgets/entry_appearance.dart';
import 'package:kilitdepo/core/widgets/entry_avatar.dart';
import 'package:kilitdepo/core/widgets/letter_avatar.dart';
import 'package:kilitdepo/data/backup/backup_codec.dart';
import 'package:kilitdepo/data/database/app_database.dart';
import 'package:kilitdepo/data/database/vault_database_opener.dart';
import 'package:kilitdepo/data/repositories/vault_repository_impl.dart';
import 'package:kilitdepo/domain/entities/backup_entry.dart';
import 'package:kilitdepo/domain/entities/entry_category.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/vault/presentation/entry_detail_screen.dart';
import 'package:kilitdepo/features/vault/presentation/entry_edit_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';

import '../helpers/fake_vault_repository.dart';
import '../helpers/in_memory_store.dart';
import '../helpers/test_app.dart';
import 'design_test.dart' show seeded;

const unlocked = AuthState(status: AuthStatus.unlocked);

void main() {
  final crypto = CryptoService();

  group('Veritabanı şema 1 → 2 (SQLCipher)', () {
    late Directory tmp;
    late File file;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('kilitdepo_migration');
      file = File('${tmp.path}/vault.db');
    });

    tearDown(() async => tmp.delete(recursive: true));

    test('eski kasa açılınca sütunlar eklenir, kayıtlar korunur', () async {
      final key = crypto.generateDek();
      // Şema 1 kasasını taklit et: yeni sütunları kaldır, sürümü 1 yap.
      final v1 = await openVaultDatabaseFile(file, key);
      await v1.customStatement(
        "INSERT INTO entries (uuid, title, username, password_enc, category, "
        "is_favorite, created_at, updated_at) VALUES ('u1', 'Eski Kayıt', "
        "'', 'x', 'bank', 1, '2026-01-01T00:00:00.000', "
        "'2026-01-01T00:00:00.000')",
      );
      await v1.customStatement('ALTER TABLE entries DROP COLUMN icon_key');
      await v1.customStatement('ALTER TABLE entries DROP COLUMN color_key');
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      final v2 = await openVaultDatabaseFile(
        file,
        SecretKeyData(List.of(key.bytes)),
      );
      final version = await v2.customSelect('PRAGMA user_version').get();
      expect(version.single.data.values.single, 2);
      final row = (await v2.entriesDao.getAll()).single;
      expect(row.title, 'Eski Kayıt');
      expect(row.isFavorite, isTrue);
      expect(row.iconKey, isNull);
      expect(row.colorKey, isNull);
      await v2.customStatement(
        "UPDATE entries SET icon_key = 'bank', color_key = 'blue'",
      );
      expect((await v2.entriesDao.getAll()).single.iconKey, 'bank');
      await v2.close();
    });
  });

  group('Görünüm verisi', () {
    late AppDatabase db;
    late VaultRepositoryImpl repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = VaultRepositoryImpl(
        db: db,
        fieldKey: crypto.generateDek(),
        crypto: crypto,
      );
    });

    tearDown(() => db.close());

    test(
      'simge ve renk kaydedilir, güncellenir; geçersiz anahtar atılır',
      () async {
        final id = await repo.addEntry(
          const EntryDraft(
            title: 'Banka',
            username: '',
            password: 'x',
            iconKey: 'bank',
            colorKey: 'blue',
          ),
        );
        var s = (await repo.watchEntries().first).single;
        expect((s.iconKey, s.colorKey), ('bank', 'blue'));

        await repo.updateEntry(
          id,
          const EntryDraft(
            title: 'Banka',
            username: '',
            password: 'x',
            iconKey: 'DROP TABLE; --',
          ),
        );
        s = (await repo.watchEntries().first).single;
        expect((s.iconKey, s.colorKey), (null, null));
      },
    );

    test('yedekte taşınır; eski yedek (alansız) sorunsuz açılır', () async {
      await repo.addEntry(
        const EntryDraft(
          title: 'Oyun',
          username: '',
          password: 'x',
          iconKey: 'game',
          colorKey: 'purple',
        ),
      );
      final codec = BackupCodec(crypto, kdf: fastTestKdf);
      final file = await codec.encode(
        await repo.exportEntries(),
        'Yedek-Şifresi-123',
      );
      final back = (await codec.decode(file, 'Yedek-Şifresi-123')).single;
      expect((back.iconKey, back.colorKey), ('game', 'purple'));

      final old = BackupEntry(
        uuid: 'eski-1',
        title: 'Eski',
        username: '',
        password: 'y',
        url: null,
        notes: null,
        category: EntryCategory.other,
        isFavorite: false,
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      );
      final oldFile = await codec.encode([old], 'Yedek-Şifresi-123');
      final oldBack = (await codec.decode(oldFile, 'Yedek-Şifresi-123')).single;
      expect((oldBack.iconKey, oldBack.colorKey), (null, null));
      await repo.importEntries([oldBack]);
      expect(await repo.watchEntries().first, hasLength(2));
    });

    test('katalog anahtarları benzersiz', () {
      final icons = EntryAppearanceCatalog.icons.map((o) => o.key).toList();
      final colors = EntryAppearanceCatalog.colors.map((o) => o.key).toList();
      expect(icons.toSet(), hasLength(icons.length));
      expect(colors.toSet(), hasLength(colors.length));
      expect(EntryAppearanceCatalog.icon('yok'), isNull);
    });
  });

  group('Rozet ve seçici', () {
    testWidgets('varsayılan görünüm eskisiyle aynı (harf rozeti)', (
      tester,
    ) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      expect(find.byType(LetterAvatar), findsWidgets);
    });

    testWidgets('formdan simge + renk seçilir ve kaydedilir', (tester) async {
      final repo = FakeVaultRepository();
      final id = await repo.addEntry(
        const EntryDraft(title: 'Banka', username: '', password: 'x'),
      );
      await pumpApp(tester, unlocked, repository: repo);
      await tapEntry(tester, 'Banka');
      await tester.tap(find.byKey(EntryDetailScreen.editKey));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(EntryEditScreen.appearanceKey));
      expect(find.byKey(const Key('appearance_sheet')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('appearance_icon_bank')));
      await tapVisible(tester, find.byKey(const Key('appearance_color_blue')));
      await tapVisible(tester, find.byKey(const Key('appearance_done')));
      await tapVisible(tester, find.byKey(EntryEditScreen.saveKey));
      final s = (await repo.getEntry(id)).summary;
      expect((s.iconKey, s.colorKey), ('bank', 'blue'));
      // Liste rozeti simgeyi gösterir.
      expect(
        find.descendant(
          of: find.byType(EntryAvatar),
          matching: find.byIcon(Icons.account_balance),
        ),
        findsWidgets,
      );
    });
  });

  group('Favoriler şeridi', () {
    Future<FakeVaultRepository> withFavorite() async {
      final repo = await seeded();
      await repo.setFavorite(2, isFavorite: true); // Gmail
      return repo;
    }

    testWidgets('dokununca şifre kopyalanır, ayrıntı açılmaz', (tester) async {
      await pumpApp(tester, unlocked, repository: await withFavorite());
      expect(find.byKey(VaultListScreen.favoritesStripKey), findsOneWidget);
      await tester.tap(find.byKey(const Key('favorite_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(clipboardWrites, ['Kx9#mQ2!vL7@pR4z']);
      expect(find.byType(EntryDetailScreen), findsNothing);
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
    });

    testWidgets('uzun basınca "Ayrıntıları aç"', (tester) async {
      await pumpApp(tester, unlocked, repository: await withFavorite());
      await tester.longPress(find.byKey(const Key('favorite_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('action_open')));
      await tester.pumpAndSettle();
      expect(find.byType(EntryDetailScreen), findsOneWidget);
    });

    testWidgets('favori yoksa veya arama yapılırken gizli', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      expect(find.byKey(VaultListScreen.favoritesStripKey), findsNothing);
    });

    testWidgets('arama yapılırken gizlenir', (tester) async {
      await pumpApp(tester, unlocked, repository: await withFavorite());
      await tester.enterText(find.byKey(VaultListScreen.searchFieldKey), 'g');
      await tester.pumpAndSettle();
      expect(find.byKey(VaultListScreen.favoritesStripKey), findsNothing);
    });
  });

  group('Uyarılar görüldüğü yerde', () {
    testWidgets('tekrar kullanılan kayıtlarda rozet; diğerinde yok', (
      tester,
    ) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.pumpAndSettle();
      // ziraat (1) ve Gmail (2) aynı şifre; gitHub (3) farklı.
      expect(find.byKey(const Key('entry_reused_1')), findsOneWidget);
      expect(find.byKey(const Key('entry_reused_2')), findsOneWidget);
      expect(find.byKey(const Key('entry_reused_3')), findsNothing);
      expect(find.byKey(const Key('entry_weak_1')), findsNothing);
    });

    testWidgets('detayda uyarı kartı: hangi kayıtla aynı + değiştir', (
      tester,
    ) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tapEntry(tester, 'Gmail');
      expect(find.byKey(EntryDetailScreen.issueCardKey), findsOneWidget);
      expect(find.text(l10n.detailIssueReused('ziraat')), findsOneWidget);
      await tapVisible(tester, find.byKey(EntryDetailScreen.issueChangeKey));
      expect(find.byType(EntryEditScreen), findsOneWidget);
    });

    testWidgets('sorunsuz kayıtta uyarı kartı yok', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tapEntry(tester, 'gitHub');
      expect(find.byKey(EntryDetailScreen.issueCardKey), findsNothing);
    });

    testWidgets('zayıf şifrede "Zayıf" rozeti', (tester) async {
      final repo = FakeVaultRepository();
      await repo.addEntry(
        const EntryDraft(title: 'Eski', username: '', password: '1234'),
      );
      await pumpApp(
        tester,
        unlocked,
        repository: repo,
        store: InMemorySecureStore(),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('entry_weak_1')), findsOneWidget);
    });
  });
}
