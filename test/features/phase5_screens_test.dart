import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/constants/app_info.dart';
import 'package:kilitdepo/core/licenses/native_licenses.dart';
import 'package:kilitdepo/core/widgets/producer_label.dart';
import 'package:kilitdepo/data/repositories/app_settings_repository.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/about/presentation/about_screen.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/presentation/login_screen.dart';
import 'package:kilitdepo/features/guide/data/guide_content.dart';
import 'package:kilitdepo/features/guide/presentation/guide_screen.dart';
import 'package:kilitdepo/features/settings/presentation/settings_screen.dart';
import 'package:kilitdepo/features/vault/presentation/entry_detail_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';

import '../helpers/fake_vault_repository.dart';
import '../helpers/in_memory_store.dart';
import '../helpers/test_app.dart';

const unlocked = AuthState(status: AuthStatus.unlocked);
const locked = AuthState(status: AuthStatus.locked);

Future<void> choose(WidgetTester tester, Key tile, String option) async {
  await tapVisible(tester, find.byKey(tile));
  await tester.tap(find.byKey(Key('option_$option')));
  await tester.pumpAndSettle();
}

void main() {
  group('Ayarlar', () {
    testWidgets('alt çubuktan açılır; altta sürüm + üretici etiketi', (
      tester,
    ) async {
      await pumpApp(tester, unlocked);
      await openSettings(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(SettingsScreen.versionKey),
        200,
      );
      expect(find.text('KilitDepo v1.0.0 · İY Labs'), findsOneWidget);
      expect(AppInfo.versionLine('1.0.0'), contains(AppInfo.producerLabel));
    });

    testWidgets('otomatik kilit süresi kaydedilir ve uygulanır', (
      tester,
    ) async {
      final store = InMemorySecureStore();
      await pumpApp(tester, unlocked, store: store);
      await openSettings(tester);
      await choose(tester, SettingsScreen.autoLockKey, l10n.durationMinutes(5));
      expect(store.data[AppSettingsRepository.autoLockKey], '300');
      expect(
        find.text(l10n.settingsAutoLockSubtitle(l10n.durationMinutes(5))),
        findsOneWidget,
      );
    });

    testWidgets('pano süresi değişince kopyalama o sürede temizlenir', (
      tester,
    ) async {
      final store = InMemorySecureStore();
      final repo = FakeVaultRepository();
      await repo.addEntry(
        const EntryDraft(title: 'Gmail', username: '', password: 'Gizli-1'),
      );
      await pumpApp(tester, unlocked, store: store, repository: repo);
      await openSettings(tester);
      await choose(
        tester,
        SettingsScreen.clipboardKey,
        l10n.durationSeconds(15),
      );
      expect(store.data[AppSettingsRepository.clipboardKey], '15');

      await openTab(tester, 'nav_vault');
      await tester.tap(find.text('Gmail'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(EntryDetailScreen.copyPasswordKey));
      await tester.pump();
      expect(find.text(l10n.copiedPassword(15)), findsOneWidget);
      await tester.pump(const Duration(seconds: 15));
      expect(clipboardWrites, ['Gizli-1', '']);
      await tester.pumpAndSettle();
    });

    testWidgets('tema seçimi uygulamaya yansır ve kaydedilir', (tester) async {
      final store = InMemorySecureStore();
      await pumpApp(tester, unlocked, store: store);
      await openSettings(tester);
      await tapVisible(tester, find.byKey(const Key('theme_dark')));
      await tester.pumpAndSettle();
      expect(store.data[AppSettingsRepository.themeKey], 'dark');
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('tema giriş ekranında da geçerli', (tester) async {
      final store = InMemorySecureStore()
        ..data[AppSettingsRepository.themeKey] = 'dark';
      await pumpApp(tester, locked, store: store);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('biyometri yoksa anahtar kapalı ve devre dışı', (tester) async {
      await pumpApp(tester, unlocked);
      await openSettings(tester);
      final tile = tester.widget<SwitchListTile>(
        find.byKey(SettingsScreen.biometricKey),
      );
      expect(tile.onChanged, isNull);
      expect(find.text(l10n.settingsBiometricUnavailable), findsOneWidget);
    });

    testWidgets('biyometriyi açmak ana şifre ister', (tester) async {
      final (fake, _) = await pumpApp(
        tester,
        const AuthState(status: AuthStatus.unlocked, biometricAvailable: true),
      );
      await openSettings(tester);
      await tester.tap(find.byKey(SettingsScreen.biometricKey));
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsBiometricConfirmBody), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('biometric_confirm_password')),
        'Ana-Şifre-12345',
      );
      await tester.tap(find.byKey(const Key('biometric_confirm_ok')));
      await tester.pumpAndSettle();
      expect(fake.lastBiometricPassword, 'Ana-Şifre-12345');
      expect(find.text(l10n.settingsBiometricEnabled), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(SettingsScreen.biometricKey))
            .value,
        isTrue,
      );
    });

    testWidgets('biyometri iptal edilirse açılmaz', (tester) async {
      final (fake, _) = await pumpApp(
        tester,
        const AuthState(status: AuthStatus.unlocked, biometricAvailable: true),
      );
      await openSettings(tester);
      await tester.tap(find.byKey(SettingsScreen.biometricKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();
      expect(fake.lastBiometricPassword, isNull);
    });

    testWidgets('biyometriyi kapatmak şifre istemez', (tester) async {
      await pumpApp(
        tester,
        const AuthState(
          status: AuthStatus.unlocked,
          biometricAvailable: true,
          biometricEnabled: true,
        ),
      );
      await openSettings(tester);
      await tester.tap(find.byKey(SettingsScreen.biometricKey));
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsBiometricDisabled), findsOneWidget);
    });

    testWidgets('yedek alınmadıysa belirtilir', (tester) async {
      await pumpApp(tester, unlocked);
      await openSettings(tester);
      await scrollToSetting(tester, find.byKey(SettingsScreen.backupKey));
      expect(find.text(l10n.settingsLastBackupNever), findsOneWidget);
    });

    testWidgets('son yedek tarihi gösterilir', (tester) async {
      final store = InMemorySecureStore()
        ..data[AppSettingsRepository.lastBackupKey] = DateTime.utc(
          2026,
          11,
          1,
        ).toIso8601String();
      await pumpApp(tester, unlocked, store: store);
      await openSettings(tester);
      await scrollToSetting(tester, find.byKey(SettingsScreen.backupKey));
      expect(find.textContaining('Son yedek:'), findsOneWidget);
    });
  });

  group('Hakkında', () {
    testWidgets('kilitliyken giriş ekranından açılır; içerik tam', (
      tester,
    ) async {
      await pumpApp(tester, locked);
      await tester.tap(find.byKey(LoginScreen.aboutButtonKey));
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text(AppInfo.appName), findsOneWidget);
      expect(find.text(l10n.aboutVersion('1.0.0')), findsOneWidget);
      expect(find.byKey(AboutScreen.producerKey), findsOneWidget);
      expect(find.text(l10n.aboutPrivacyTitle), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(AboutScreen.copyrightKey),
        200,
      );
      expect(find.text(l10n.aboutSecurityTitle), findsOneWidget);
      final year = DateTime.now().year;
      expect(
        find.text('© $year İY Labs. Tüm hakları saklıdır.'),
        findsOneWidget,
      );
    });

    testWidgets('lisans sayfası KilitDepo adıyla açılır', (tester) async {
      await pumpApp(tester, locked);
      await tester.tap(find.byKey(LoginScreen.aboutButtonKey));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(AboutScreen.licensesKey), 200);
      await tapVisible(tester, find.byKey(AboutScreen.licensesKey));
      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text(AppInfo.appName), findsWidgets);
    });

    testWidgets('Ayarlar\'dan da açılır', (tester) async {
      await pumpApp(tester, unlocked);
      await openSettings(tester);
      await tester.scrollUntilVisible(find.byKey(SettingsScreen.aboutKey), 200);
      await tapVisible(tester, find.byKey(SettingsScreen.aboutKey));
      expect(find.byType(AboutScreen), findsOneWidget);
    });

    test('SQLCipher ve OpenSSL lisansları kayıtlı', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerNativeLicenses();
      final packages = <String>{};
      await for (final entry in LicenseRegistry.licenses) {
        packages.addAll(entry.packages);
      }
      expect(packages, containsAll(['SQLCipher', 'OpenSSL']));
    });
  });

  group('Kullanma Talimatı', () {
    test('14 bölüm, istenen sırada; SSS en az 5 soru', () {
      expect(guideContentTr.map((s) => s.id).toList(), [
        'welcome',
        'setup',
        'add',
        'list',
        'edit',
        'copy',
        'generator',
        'biometric',
        'security',
        'backup',
        'csv-import',
        'forgot',
        'tips',
        'faq',
      ]);
      final faq = guideContentTr.firstWhere((s) => s.id == 'faq').faq;
      expect(faq.length, greaterThanOrEqualTo(5));
      for (final s in guideContentTr) {
        expect(s.title, isNotEmpty);
        expect(s.summary, isNotEmpty);
      }
      // Web bağlantısı yok (tamamen çevrimdışı).
      for (final s in guideContentTr) {
        expect(s.searchableText.contains('http'), isFalse);
      }
    });

    testWidgets('kilitliyken açılır, bölümler genişletilebilir', (
      tester,
    ) async {
      await pumpApp(tester, locked);
      await tapVisible(tester, find.byKey(LoginScreen.guideButtonKey));
      expect(find.byType(GuideScreen), findsOneWidget);
      expect(find.byType(ExpansionTile), findsWidgets);
      await tester.tap(find.byKey(const Key('guide_welcome')));
      await tester.pumpAndSettle();
      expect(find.textContaining('İnternete hiç'), findsOneWidget);
    });

    testWidgets('arama Türkçe karakterden bağımsız filtreler', (tester) async {
      await pumpApp(tester, locked);
      await tapVisible(tester, find.byKey(LoginScreen.guideButtonKey));
      await tester.enterText(find.byKey(GuideScreen.searchKey), 'URETICI');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide_generator')), findsOneWidget);
      expect(find.byKey(const Key('guide_welcome')), findsNothing);

      await tester.enterText(find.byKey(GuideScreen.searchKey), 'zzzyyyxxx');
      await tester.pumpAndSettle();
      expect(find.text(l10n.guideNoResults), findsOneWidget);
    });
  });

  group('Tek seferlik talimat önerisi', () {
    testWidgets('ilk açılışta bir kez gösterilir, sonra sorulmaz', (
      tester,
    ) async {
      final store = InMemorySecureStore();
      await pumpApp(
        tester,
        unlocked,
        store: store,
        guidePromptAlreadyShown: false,
      );
      expect(find.byKey(VaultListScreen.guidePromptKey), findsOneWidget);
      await tester.tap(find.text(l10n.guidePromptLater));
      await tester.pumpAndSettle();
      expect(find.byKey(VaultListScreen.guidePromptKey), findsNothing);
      expect(store.data[AppSettingsRepository.guidePromptKey], 'true');

      // Yeniden başlatma: aynı depo → tekrar sorulmaz.
      await pumpApp(
        tester,
        unlocked,
        store: store,
        guidePromptAlreadyShown: false,
      );
      expect(find.byKey(VaultListScreen.guidePromptKey), findsNothing);
    });

    testWidgets('"Talimatı aç" kullanma talimatını açar', (tester) async {
      await pumpApp(tester, unlocked, guidePromptAlreadyShown: false);
      await tester.tap(find.text(l10n.guidePromptOpen));
      await tester.pumpAndSettle();
      expect(find.byType(GuideScreen), findsOneWidget);
    });
  });

  group('Üretici etiketi yerleri', () {
    testWidgets('açılış ekranında küçük etiket', (tester) async {
      await pumpApp(tester, const AuthState.initializing(), settle: false);
      expect(find.byKey(ProducerLabel.labelKey), findsOneWidget);
    });

    testWidgets('giriş ekranında küçük etiket', (tester) async {
      await pumpApp(tester, locked);
      expect(find.byKey(ProducerLabel.labelKey), findsOneWidget);
    });
  });
}
