import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/core/widgets/colored_password_text.dart';
import 'package:kilitdepo/data/backup/backup_codec.dart';
import 'package:kilitdepo/domain/entities/backup_entry.dart';
import 'package:kilitdepo/domain/entities/entry_category.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/generator/presentation/generator_panel.dart';
import 'package:kilitdepo/features/generator/presentation/generator_screen.dart';
import 'package:kilitdepo/features/settings/application/backup_providers.dart';
import 'package:kilitdepo/features/settings/presentation/backup_screen.dart';
import 'package:kilitdepo/features/settings/presentation/settings_screen.dart';
import 'package:kilitdepo/features/vault/presentation/entry_edit_screen.dart';
import 'package:kilitdepo/features/vault/presentation/security_report_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';
import 'package:kilitdepo/features/vault/presentation/widgets/vault_ui.dart';

import '../helpers/fake_vault_repository.dart';
import '../helpers/in_memory_store.dart';
import '../helpers/test_app.dart';

const unlocked = AuthState(status: AuthStatus.unlocked);

class FakeGateway implements BackupFileGateway {
  Uint8List? saved;
  String? savedName;
  ({String name, Uint8List bytes})? toPick;

  /// Seçici açıkken testin araya girebilmesi için.
  Completer<void>? holdPick;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    savedName = fileName;
    saved = bytes;
    return true;
  }

  @override
  Future<({String name, Uint8List bytes})?> pick() async {
    await holdPick?.future;
    return toPick;
  }
}

Future<void> openMenu(WidgetTester tester, String label) => openTab(
  tester,
  label == l10n.generatorTitle ? 'nav_generator' : 'nav_report',
);

void main() {
  final fastCodec = BackupCodec(CryptoService(), kdf: fastTestKdf);

  List<Override> backupOverrides(FakeGateway gateway) => [
    backupFileGatewayProvider.overrideWithValue(gateway),
    backupCodecProvider.overrideWithValue(fastCodec),
  ];

  group('Şifre üretici', () {
    testWidgets('menüden açılır, kopyala panoya yazar', (tester) async {
      await pumpApp(tester, unlocked);
      await openMenu(tester, l10n.generatorTitle);
      expect(find.byType(GeneratorScreen), findsOneWidget);
      final first = tester
          .widget<ColoredPasswordText>(find.byKey(GeneratorPanel.passwordKey))
          .password;
      expect(first.length, 20);

      await tester.tap(find.byKey(GeneratorPanel.regenerateKey));
      await tester.pumpAndSettle(); // geçiş animasyonu bitsin
      final second = tester
          .widget<ColoredPasswordText>(find.byKey(GeneratorPanel.passwordKey))
          .password;
      expect(second, isNot(first));

      await tester.ensureVisible(find.byKey(GeneratorScreen.copyKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GeneratorScreen.copyKey));
      await tester.pump();
      expect(clipboardWrites, [second]);
      expect(find.byKey(ClipboardCountdownRing.ringKey), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(clipboardWrites, [second, '']);
      await tester.pumpAndSettle();
    });

    testWidgets('formdaki "Şifre üret" alanı doldurur', (tester) async {
      await pumpApp(tester, unlocked);
      await tapVisible(tester, find.byKey(VaultListScreen.addButtonKey));
      await tapVisible(tester, find.byKey(EntryEditScreen.generateKey));
      final generated = tester
          .widget<ColoredPasswordText>(find.byKey(GeneratorPanel.passwordKey))
          .password;
      await tapVisible(tester, find.byKey(const Key('gen_use')));
      final field = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(EntryEditScreen.passwordKey),
          matching: find.byType(EditableText),
        ),
      );
      expect(field.controller.text, generated);
    });
  });

  group('Güvenlik raporu', () {
    Future<FakeVaultRepository> seeded() async {
      final repo = FakeVaultRepository();
      await repo.addEntry(
        const EntryDraft(title: 'Zayıf', username: '', password: '1234'),
      );
      await repo.addEntry(
        const EntryDraft(
          title: 'Bir',
          username: '',
          password: 'Aynı-Güçlü-Şifre-2026!',
        ),
      );
      await repo.addEntry(
        const EntryDraft(
          title: 'İki',
          username: '',
          password: 'Aynı-Güçlü-Şifre-2026!',
        ),
      );
      return repo;
    }

    testWidgets('listede uyarı şeridi, dokununca rapor', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      expect(find.text(l10n.reportBanner(3)), findsOneWidget);
      await tester.tap(find.byKey(VaultListScreen.securityBannerKey));
      await tester.pumpAndSettle();
      expect(find.byType(SecurityReportScreen), findsOneWidget);
      expect(find.byKey(const Key('report_weak')), findsOneWidget);
      expect(find.byKey(const Key('report_reused')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(l10n.reportReusedGroup(2)),
        200,
      );
      expect(find.text(l10n.reportReusedGroup(2)), findsOneWidget);
      // Rapor ekranında şifreler gösterilmez.
      expect(find.textContaining('Aynı-Güçlü'), findsNothing);
    });

    testWidgets('sorun yoksa şerit yok, rapor "her şey yolunda"', (
      tester,
    ) async {
      final repo = FakeVaultRepository();
      await repo.addEntry(
        const EntryDraft(
          title: 'Tek',
          username: '',
          password: 'Kx9#mQ2!vL7@pR4zT8&w',
        ),
      );
      await pumpApp(tester, unlocked, repository: repo);
      expect(find.byKey(VaultListScreen.securityBannerKey), findsNothing);
      await openMenu(tester, l10n.reportTitle);
      expect(find.text(l10n.reportAllGood), findsOneWidget);
    });
  });

  group('Yedekleme', () {
    Future<void> openBackup(
      WidgetTester tester,
      FakeGateway gateway, {
      FakeVaultRepository? repo,
    }) async {
      await pumpApp(
        tester,
        unlocked,
        repository: repo,
        extraOverrides: backupOverrides(gateway),
      );
      await openSettings(tester);
      await scrollToSetting(tester, find.byKey(SettingsScreen.backupKey));
      await tapVisible(tester, find.byKey(SettingsScreen.backupKey));
      expect(find.byType(BackupScreen), findsOneWidget);
    }

    testWidgets('dışa aktarma: şifre doğrulanır, dosya kaydedilir', (
      tester,
    ) async {
      final repo = FakeVaultRepository();
      await repo.addEntry(
        const EntryDraft(
          title: 'Gmail',
          username: 'ibo',
          password: 'Gizli-1',
          category: EntryCategory.email,
        ),
      );
      final gateway = FakeGateway();
      await openBackup(tester, gateway, repo: repo);

      await tester.enterText(find.byKey(const Key('backup_password')), 'kısa');
      await tester.enterText(find.byKey(const Key('backup_confirm')), 'kısa');
      await tapVisible(tester, find.byKey(const Key('backup_export')));
      expect(find.text(l10n.setupPasswordTooShort(10)), findsOneWidget);
      expect(gateway.saved, isNull);

      await tester.enterText(
        find.byKey(const Key('backup_password')),
        'Ayrı-Yedek-Şifresi-1',
      );
      await tester.enterText(
        find.byKey(const Key('backup_confirm')),
        'Ayrı-Yedek-Şifresi-1',
      );
      await tester.ensureVisible(find.byKey(const Key('backup_export')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('backup_export')));
        // Argon2id gerçek isolate'ta çalışır.
        for (var i = 0; i < 100 && gateway.saved == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(gateway.savedName, endsWith('.kilitdepo'));
      expect(find.text(l10n.backupExported(1)), findsOneWidget);
      final decoded = await tester.runAsync(
        () => fastCodec.decode(gateway.saved!, 'Ayrı-Yedek-Şifresi-1'),
      );
      expect(decoded!.single.password, 'Gizli-1');
    });

    Future<Uint8List> backupFile() async => fastCodec.encode([
      BackupEntry(
        uuid: 'yedek-1',
        title: 'Yedekten Gelen',
        username: 'u',
        password: 'Yedek-Şifre-1',
        url: null,
        notes: null,
        category: EntryCategory.other,
        isFavorite: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ], 'Ayrı-Yedek-Şifresi-1');

    Future<void> decrypt(WidgetTester tester, String password) async {
      await tester.enterText(
        find.byKey(const Key('backup_import_password')),
        password,
      );
      await tester.ensureVisible(find.byKey(const Key('backup_decrypt')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('backup_decrypt')));
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find.byKey(const Key('backup_preview')).evaluate().isNotEmpty ||
              find.byKey(const Key('backup_error')).evaluate().isNotEmpty) {
            break;
          }
        }
      });
      await tester.pumpAndSettle();
    }

    testWidgets('içe aktarma: önizleme sonra kasaya aktarma', (tester) async {
      final gateway = FakeGateway();
      final file = (await tester.runAsync(backupFile))!;
      gateway.toPick = (name: 'yedek.kilitdepo', bytes: file);
      final repo = FakeVaultRepository();
      await openBackup(tester, gateway, repo: repo);

      await tapVisible(tester, find.byKey(const Key('backup_pick')));
      expect(
        find.text(l10n.backupSelectedFile('yedek.kilitdepo')),
        findsOneWidget,
      );
      await decrypt(tester, 'Ayrı-Yedek-Şifresi-1');
      expect(find.text(l10n.backupPreview(1, 1, 0, 0)), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('backup_import')));
      expect(find.text(l10n.backupImported(1, 0)), findsOneWidget);
      expect(repo.lastImport!.single.title, 'Yedekten Gelen');
    });

    testWidgets('yanlış yedek şifresi hatası', (tester) async {
      final gateway = FakeGateway();
      final file = (await tester.runAsync(backupFile))!;
      gateway.toPick = (name: 'yedek.kilitdepo', bytes: file);
      await openBackup(tester, gateway);
      await tapVisible(tester, find.byKey(const Key('backup_pick')));
      await decrypt(tester, 'yanlış-yedek-şifresi');
      expect(find.text(l10n.backupWrongPassword), findsOneWidget);
    });

    testWidgets('dosya seçici açıkken arka plan kilidi uygulanmaz', (
      tester,
    ) async {
      final gateway = FakeGateway()..holdPick = Completer<void>();
      final (fake, _) = await pumpApp(
        tester,
        unlocked,
        extraOverrides: backupOverrides(gateway),
      );
      await openSettings(tester);
      await scrollToSetting(tester, find.byKey(SettingsScreen.backupKey));
      await tapVisible(tester, find.byKey(SettingsScreen.backupKey));
      await tester.ensureVisible(find.byKey(const Key('backup_pick')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('backup_pick')));
      await tester.pump();

      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      expect(fake.lockCalls, isEmpty);

      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      gateway.holdPick!.complete();
      await tester.pumpAndSettle();
      expect(fake.lockCalls, isEmpty);
      expect(find.byType(BackupScreen), findsOneWidget);
    });
  });
}
