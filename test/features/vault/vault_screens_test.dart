import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/domain/entities/entry_category.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/presentation/login_screen.dart';
import 'package:kilitdepo/features/vault/application/vault_query.dart';
import 'package:kilitdepo/features/vault/presentation/entry_detail_screen.dart';
import 'package:kilitdepo/features/vault/presentation/entry_edit_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';

import '../../helpers/fake_vault_repository.dart';
import '../../helpers/test_app.dart';

const unlocked = AuthState(status: AuthStatus.unlocked);

Future<FakeVaultRepository> seeded() async {
  final repo = FakeVaultRepository();
  await repo.addEntry(
    const EntryDraft(
      title: 'Gmail',
      username: 'ibrahim@gmail.com',
      password: 'Gmail-Şifre-1',
      category: EntryCategory.email,
    ),
  );
  await repo.addEntry(
    const EntryDraft(
      title: 'Ziraat Bankası',
      username: 'musteri42',
      password: 'Banka-Şifre-2',
      url: 'https://ziraat.ornek',
      notes: 'Müşteri no: 42',
      category: EntryCategory.bank,
      isFavorite: true,
    ),
  );
  await repo.addEntry(
    const EntryDraft(
      title: 'Çalışma',
      username: 'ibrahim@is.com',
      password: 'Is-Şifre-3',
      category: EntryCategory.work,
    ),
  );
  return repo;
}

void main() {
  group('Kasa listesi', () {
    testWidgets('boş kasa durumu ve ekle butonu', (tester) async {
      await pumpApp(tester, unlocked);
      expect(find.text(l10n.vaultEmptyTitle), findsOneWidget);
      expect(find.byKey(VaultListScreen.addButtonKey), findsOneWidget);
    });

    testWidgets('kayıtlar Türkçe alfabetik sırayla listelenir', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      final y = [
        'Çalışma',
        'Gmail',
        'Ziraat Bankası',
      ].map((t) => tester.getTopLeft(entryText(t)).dy).toList();
      expect(y, orderedEquals([...y]..sort()));
      // Liste ekranında şifre çözülmez.
      expect(find.textContaining('Şifre-'), findsNothing);
    });

    testWidgets('arama kullanıcı adında da çalışır', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.enterText(
        find.byKey(VaultListScreen.searchFieldKey),
        'IBRAHIM',
      );
      await tester.pumpAndSettle();
      expect(entryText('Gmail'), findsOneWidget);
      expect(find.text('Çalışma'), findsOneWidget);
      expect(entryText('Ziraat Bankası'), findsNothing);
    });

    testWidgets('sonuç yoksa boş arama durumu ve filtre temizleme', (
      tester,
    ) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.enterText(
        find.byKey(VaultListScreen.searchFieldKey),
        'yokyok',
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.vaultNoResultsTitle), findsOneWidget);
      await tester.tap(find.text(l10n.vaultClearFilters));
      await tester.pumpAndSettle();
      expect(entryText('Gmail'), findsOneWidget);
    });

    testWidgets('favoriler ve kategori filtresi', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.tap(find.byKey(VaultListScreen.favoritesChipKey));
      await tester.pumpAndSettle();
      expect(entryText('Ziraat Bankası'), findsOneWidget);
      expect(entryText('Gmail'), findsNothing);

      await tester.tap(find.byKey(VaultListScreen.favoritesChipKey));
      await tester.pumpAndSettle();
      // Yatay çip listesi tembel oluşturulur: önce kaydır.
      await tester.scrollUntilVisible(
        find.byKey(const Key('vault_category_work')),
        150,
        scrollable: find.descendant(
          of: find.byKey(VaultListScreen.filterChipsKey),
          matching: find.byType(Scrollable),
        ),
      );
      await tapVisible(tester, find.byKey(const Key('vault_category_work')));
      expect(find.text('Çalışma'), findsOneWidget);
      expect(entryText('Gmail'), findsNothing);
    });

    testWidgets('sıralama: son eklenen', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.tap(find.byKey(VaultListScreen.sortButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CheckedPopupMenuItem<EntrySort>,
          l10n.sortRecentlyAdded,
        ),
      );
      await tester.pumpAndSettle();
      final y = [
        'Çalışma',
        'Ziraat Bankası',
        'Gmail',
      ].map((t) => tester.getTopLeft(entryText(t)).dy).toList();
      expect(y, orderedEquals([...y]..sort()));
    });
  });

  group('Kayıt ekleme', () {
    testWidgets('zorunlu alanlar doğrulanır', (tester) async {
      final (_, repo) = await pumpApp(tester, unlocked);
      await tapVisible(tester, find.byKey(VaultListScreen.addButtonKey));
      await tester.tap(find.byKey(EntryEditScreen.saveKey));
      await tester.pumpAndSettle();
      expect(find.text(l10n.entryTitleRequired), findsOneWidget);
      expect(find.text(l10n.entryPasswordRequired), findsOneWidget);
      expect(await repo.watchEntries().first, isEmpty);
    });

    testWidgets('yeni kayıt eklenir ve listede görünür', (tester) async {
      final (_, repo) = await pumpApp(tester, unlocked);
      await tapVisible(tester, find.byKey(VaultListScreen.addButtonKey));
      await tester.enterText(find.byKey(EntryEditScreen.titleKey), 'Twitter');
      await tester.enterText(find.byKey(EntryEditScreen.usernameKey), 'kus');
      await tester.enterText(
        find.byKey(EntryEditScreen.passwordKey),
        'Kus-Şifre-9',
      );
      await tester.enterText(find.byKey(EntryEditScreen.notesKey), 'gizli not');
      await tester.tap(find.byKey(EntryEditScreen.saveKey));
      await tester.pumpAndSettle();

      expect(find.byType(VaultListScreen), findsOneWidget);
      expect(find.text('Twitter'), findsOneWidget);
      final saved = await repo.getEntry(1);
      expect(saved.password, 'Kus-Şifre-9');
      expect(saved.notes, 'gizli not');
    });

    testWidgets('kaydedilmemiş değişiklikte çıkış uyarısı', (tester) async {
      await pumpApp(tester, unlocked);
      await tapVisible(tester, find.byKey(VaultListScreen.addButtonKey));
      await tester.enterText(find.byKey(EntryEditScreen.titleKey), 'Yarım');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.entryDiscardTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('edit_discard_confirm')));
      await tester.pumpAndSettle();
      expect(find.byType(VaultListScreen), findsOneWidget);
    });
  });

  group('Kayıt detayı', () {
    Future<FakeVaultRepository> openDetail(WidgetTester tester) async {
      final repo = await seeded();
      await pumpApp(tester, unlocked, repository: repo);
      await tapEntry(tester, 'Ziraat Bankası');
      expect(find.byType(EntryDetailScreen), findsOneWidget);
      return repo;
    }

    testWidgets('şifre gizli başlar, göster/gizle çalışır', (tester) async {
      final repo = await openDetail(tester);
      expect(find.text('Banka-Şifre-2'), findsNothing);
      expect(repo.revealCalls, 0);
      expect(find.text('Müşteri no: 42'), findsOneWidget);

      await tester.tap(find.byKey(EntryDetailScreen.revealKey));
      await tester.pumpAndSettle();
      expect(find.text('Banka-Şifre-2'), findsOneWidget);

      await tester.tap(find.byKey(EntryDetailScreen.revealKey));
      await tester.pumpAndSettle();
      expect(find.text('Banka-Şifre-2'), findsNothing);
    });

    testWidgets('kopyala → panoya yazılır, 30 sn sonra silinir', (
      tester,
    ) async {
      await openDetail(tester);
      await tester.tap(find.byKey(EntryDetailScreen.copyPasswordKey));
      await tester.pump();
      expect(clipboardWrites, ['Banka-Şifre-2']);
      expect(find.text(l10n.copiedPassword(30)), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      expect(clipboardWrites, ['Banka-Şifre-2', '']);
      await tester.pumpAndSettle();
    });

    Future<void> deleteFromDetail(WidgetTester tester) async {
      await tester.tap(find.byKey(EntryDetailScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(EntryDetailScreen.deleteKey));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'silme: liste hemen güncellenir, "Geri al" kaydı geri getirir',
      (tester) async {
        final repo = await openDetail(tester);
        await deleteFromDetail(tester);
        expect(find.byType(VaultListScreen), findsOneWidget);
        expect(entryText('Ziraat Bankası'), findsNothing);
        expect(find.byKey(EntryDetailScreen.undoSnackKey), findsOneWidget);
        // Geri alma süresinde veritabanından henüz silinmez.
        expect(await repo.watchEntries().first, hasLength(3));
        await tester.tap(find.byKey(EntryDetailScreen.undoKey));
        await tester.pumpAndSettle();
        expect(entryText('Ziraat Bankası'), findsOneWidget);
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
        expect(await repo.watchEntries().first, hasLength(3));
      },
    );

    testWidgets('silme: süre dolunca kalıcı olarak silinir', (tester) async {
      final repo = await openDetail(tester);
      await deleteFromDetail(tester);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(await repo.watchEntries().first, hasLength(2));
      expect(entryText('Ziraat Bankası'), findsNothing);
    });

    testWidgets('silme: kilitlenince bekleyen silme hemen tamamlanır', (
      tester,
    ) async {
      final repo = await openDetail(tester);
      await deleteFromDetail(tester);
      expect(await repo.watchEntries().first, hasLength(3));
      await tester.tap(find.byKey(VaultListScreen.lockButtonKey));
      await tester.pumpAndSettle();
      expect(await repo.watchEntries().first, hasLength(2));
    });

    testWidgets('düzenleme: şifre değişince geçmişte görünür', (tester) async {
      await openDetail(tester);
      await tester.tap(find.byKey(EntryDetailScreen.editKey));
      await tester.pumpAndSettle();
      expect(find.text('Ziraat Bankası'), findsWidgets);
      await tester.enterText(
        find.byKey(EntryEditScreen.passwordKey),
        'Yeni-Banka-Şifre',
      );
      await tester.tap(find.byKey(EntryEditScreen.saveKey));
      await tester.pumpAndSettle();

      expect(find.byType(EntryDetailScreen), findsOneWidget);
      expect(find.text(l10n.entryHistoryCount(1)), findsOneWidget);
      await tester.tap(find.byKey(EntryDetailScreen.historyKey));
      await tester.pumpAndSettle();
      expect(find.text(l10n.historyInfo(10)), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();
      expect(find.text('Banka-Şifre-2'), findsOneWidget);
    });

    testWidgets('favori değiştirilebilir', (tester) async {
      final repo = await openDetail(tester);
      await tester.tap(find.byKey(EntryDetailScreen.favoriteKey));
      await tester.pumpAndSettle();
      expect((await repo.getEntry(2)).summary.isFavorite, isFalse);
    });
  });

  testWidgets('kilitle → giriş ekranı', (tester) async {
    await pumpApp(tester, unlocked, repository: await seeded());
    await tester.tap(find.byKey(VaultListScreen.lockButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
