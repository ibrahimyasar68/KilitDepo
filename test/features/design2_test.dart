import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/widgets/depth_card.dart';
import 'package:kilitdepo/core/licenses/native_licenses.dart';
import 'package:kilitdepo/core/theme/app_theme.dart';
import 'package:kilitdepo/core/theme/page_transitions.dart';
import 'package:kilitdepo/core/widgets/colored_password_text.dart';
import 'package:kilitdepo/data/repositories/app_settings_repository.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/home/home_shell.dart';
import 'package:kilitdepo/features/settings/application/settings_providers.dart';
import 'package:kilitdepo/features/settings/presentation/settings_screen.dart';
import 'package:kilitdepo/features/vault/application/pending_deletions.dart';
import 'package:kilitdepo/features/vault/presentation/entry_detail_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';
import 'package:kilitdepo/features/vault/presentation/widgets/vault_ui.dart';

import '../helpers/fake_vault_repository.dart';
import '../helpers/in_memory_store.dart';
import '../helpers/test_app.dart';

const unlocked = AuthState(status: AuthStatus.unlocked);

Future<FakeVaultRepository> seeded() async {
  final repo = FakeVaultRepository();
  await repo.addEntry(
    const EntryDraft(title: 'Gmail', username: 'g', password: 'Gizli-1'),
  );
  await repo.addEntry(
    const EntryDraft(title: 'Ziraat', username: 'z', password: 'Gizli-2'),
  );
  return repo;
}

/// Tablet (yatay) boyutunda uygulama.
Future<FakeVaultRepository> pumpTablet(WidgetTester tester) async {
  final repo = await seeded();
  await pumpApp(tester, unlocked, repository: repo);
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  _transitionTests();
  group('Yazı tipleri', () {
    test('tema Inter, şifreler JetBrains Mono', () {
      expect(
        AppTheme.light().textTheme.bodyMedium!.fontFamily,
        AppTheme.fontFamily,
      );
      expect(AppTheme.fontFamily, 'Inter');
      expect(AppTheme.monoFontFamily, 'JetBrainsMono');
    });

    testWidgets('renkli şifre eş genişlikli yazı tipiyle çizilir', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ColoredPasswordText('Ab1!')),
      );
      final rich = tester.widget<Text>(find.byType(Text));
      expect(rich.textSpan!.style!.fontFamily, 'JetBrainsMono');
    });

    test('yazı tipi lisansları kayıtlı', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerNativeLicenses();
      final packages = <String>{};
      await for (final entry in LicenseRegistry.licenses) {
        packages.addAll(entry.packages);
      }
      expect(
        packages,
        containsAll(['Inter (yazı tipi)', 'JetBrains Mono (yazı tipi)']),
      );
    });
  });

  group('Material You', () {
    testWidgets('destekleyen cihazda seçenek görünür ve kaydedilir', (
      tester,
    ) async {
      final store = InMemorySecureStore();
      await pumpApp(
        tester,
        unlocked,
        store: store,
        extraOverrides: [
          dynamicColorSupportedProvider.overrideWith((ref) async => true),
        ],
      );
      await openSettings(tester);
      await tapVisible(tester, find.byKey(SettingsScreen.dynamicColorKey));
      await tester.pumpAndSettle();
      expect(store.data[AppSettingsRepository.dynamicColorKey], 'true');
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(SettingsScreen.dynamicColorKey))
            .value,
        isTrue,
      );
    });

    testWidgets('desteklemeyen cihazda (iOS, eski Android) seçenek yok', (
      tester,
    ) async {
      await pumpApp(
        tester,
        unlocked,
        extraOverrides: [
          dynamicColorSupportedProvider.overrideWith((ref) async => false),
        ],
      );
      await openSettings(tester);
      expect(find.byKey(SettingsScreen.dynamicColorKey), findsNothing);
    });

    test('varsayılan kapalı (marka rengi korunur)', () async {
      final repo = AppSettingsRepository(InMemorySecureStore());
      expect(await repo.dynamicColor(), isFalse);
    });
  });

  group('Tablet / yatay ekran', () {
    testWidgets('yan gezinme çubuğu, alt çubuk yok', (tester) async {
      await pumpTablet(tester);
      expect(find.byKey(HomeShell.railKey), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('kayda dokununca ayrıntı yanda açılır (sayfa açılmaz)', (
      tester,
    ) async {
      await pumpTablet(tester);
      expect(find.byKey(VaultListScreen.detailPlaceholderKey), findsOneWidget);
      await tester.tap(find.text('Ziraat'));
      await tester.pumpAndSettle();
      // Liste hâlâ görünür, ayrıntı yanında.
      expect(find.byType(VaultListScreen), findsOneWidget);
      final detail = tester.widget<EntryDetailScreen>(
        find.byType(EntryDetailScreen),
      );
      expect(detail.embedded, isTrue);
      expect(detail.entryId, 2);
      expect(find.byKey(VaultListScreen.detailPlaceholderKey), findsNothing);
    });

    testWidgets('yandaki ayrıntıdan silince seçim temizlenir', (tester) async {
      final repo = await pumpTablet(tester);
      await tester.tap(find.text('Ziraat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(EntryDetailScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(EntryDetailScreen.deleteKey));
      await tester.pumpAndSettle();
      await tester.pump(PendingDeletions.undoWindow);
      await tester.pumpAndSettle();
      expect(await repo.watchEntries().first, hasLength(1));
      expect(find.byKey(VaultListScreen.detailPlaceholderKey), findsOneWidget);
      expect(find.byType(VaultListScreen), findsOneWidget);
    });
  });

  testWidgets('boş kasada çizim gösterilir', (tester) async {
    await pumpApp(tester, unlocked);
    expect(find.byKey(EmptyStateIllustration.illustrationKey), findsOneWidget);
  });
}

void _transitionTests() {
  group('Liste görünümü', () {
    testWidgets('her kayıt bir kartta; harf başlıkları yok', (tester) async {
      final repo = await seeded();
      await pumpApp(tester, unlocked, repository: repo);
      for (final id in [1, 2]) {
        expect(
          find.ancestor(
            of: find.byKey(Key('entry_tile_$id')),
            matching: find.byType(DepthCard),
          ),
          findsOneWidget,
        );
      }
      // Harfler yalnızca rozetlerde görünür; eski gruplandırmadaki "G" ve
      // "Z" başlıkları artık yok.
      expect(find.text('G'), findsOneWidget);
      expect(find.text('Z'), findsOneWidget);
    });
  });

  group('Geçiş animasyonları', () {
    testWidgets('sekme değişince solup belirir; sekmenin durumu korunur', (
      tester,
    ) async {
      final repo = await seeded();
      await pumpApp(tester, unlocked, repository: repo);
      await tester.enterText(
        find.byKey(VaultListScreen.searchFieldKey),
        'gmail',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HomeShell.generatorTabKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Geçiş sürerken önceki sekme hâlâ görünür (soluyor).
      expect(find.byKey(VaultListScreen.searchFieldKey), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(VaultListScreen.searchFieldKey), findsNothing);

      await tester.tap(find.byKey(HomeShell.vaultTabKey));
      await tester.pumpAndSettle();
      // Arama metni ve filtrelenmiş liste kaybolmadı.
      expect(find.text('gmail'), findsOneWidget);
      expect(find.byKey(const Key('entry_tile_2')), findsNothing);
    });

    testWidgets('sayfa geçişi: "animasyonları kapat" açıksa animasyon yok', (
      tester,
    ) async {
      const builder = SharedAxisPageTransitionsBuilder();
      Widget host({required bool disable}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disable),
          child: Builder(
            builder: (context) => builder.buildTransitions<void>(
              MaterialPageRoute<void>(builder: (_) => const SizedBox()),
              context,
              const AlwaysStoppedAnimation(0.5),
              const AlwaysStoppedAnimation(0),
              const Text('sayfa'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(host(disable: true));
      expect(
        find.ancestor(of: find.text('sayfa'), matching: find.byType(Opacity)),
        findsNothing,
      );
      await tester.pumpWidget(host(disable: false));
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('sayfa'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, inExclusiveRange(0, 1));
    });
  });
}
