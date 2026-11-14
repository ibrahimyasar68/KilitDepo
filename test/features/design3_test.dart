import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/widgets/brand_backdrop.dart';
import 'package:kilitdepo/core/widgets/colored_password_text.dart';
import 'package:kilitdepo/data/repositories/app_settings_repository.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/presentation/login_screen.dart';
import 'package:kilitdepo/features/generator/application/password_generator.dart';
import 'package:kilitdepo/features/generator/presentation/generator_panel.dart';
import 'package:kilitdepo/features/vault/presentation/entry_detail_screen.dart';
import 'package:kilitdepo/features/vault/presentation/entry_edit_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';

import '../helpers/in_memory_store.dart';
import '../helpers/test_app.dart';
import 'design_test.dart' show seeded;

const unlocked = AuthState(status: AuthStatus.unlocked);
const locked = AuthState(status: AuthStatus.locked);

/// Pano temizleme zamanlayıcısının bitmesini bekler.
Future<void> drainClipboard(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 30));
  await tester.pumpAndSettle();
}

void main() {
  group('Kasa listesi', () {
    testWidgets('karttaki düğme şifreyi tek dokunuşla kopyalar, ✓ gösterir', (
      tester,
    ) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.tap(find.byKey(const Key('entry_copy_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(clipboardWrites, ['Kx9#mQ2!vL7@pR4z']);
      expect(
        find.descendant(
          of: find.byKey(const Key('entry_copy_2')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      // Ayrıntı sayfası açılmaz.
      expect(find.byType(EntryDetailScreen), findsNothing);
      await drainClipboard(tester);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('uzun basınca işlem menüsü; kullanıcı adı kopyalanır', (
      tester,
    ) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.longPress(find.text('Gmail'));
      await tester.pumpAndSettle();
      expect(find.byKey(VaultListScreen.actionsSheetKey), findsOneWidget);
      await tester.tap(find.byKey(const Key('action_copy_username')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(VaultListScreen.actionsSheetKey), findsNothing);
      expect(clipboardWrites, ['g']);
      await drainClipboard(tester);
    });

    testWidgets('işlem menüsünden favoriye eklenir', (tester) async {
      final repo = await seeded();
      await pumpApp(tester, unlocked, repository: repo);
      await tester.longPress(find.text('Gmail'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('action_favorite')));
      await tester.pumpAndSettle();
      expect((await repo.getEntry(2)).summary.isFavorite, isTrue);
      expect(find.byKey(const Key('entry_star_2')), findsOneWidget);
    });

    testWidgets('filtre çipleri kayıt sayısını gösterir', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      expect(
        find.descendant(
          of: find.byKey(VaultListScreen.filterChipsKey),
          matching: find.textContaining('3', findRichText: true),
        ),
        findsWidgets,
      );
    });
  });

  group('Kayıt detayı', () {
    testWidgets('büyük düğmeler kullanıcı adını ve şifreyi kopyalar', (
      tester,
    ) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.tap(find.text('Gmail'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(EntryDetailScreen.copyUsernameKey));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(EntryDetailScreen.copyPasswordKey));
      await tester.pump(const Duration(milliseconds: 300));
      expect(clipboardWrites, ['g', 'Kx9#mQ2!vL7@pR4z']);
      await drainClipboard(tester);
    });

    testWidgets('sil düğmesi doğrudan görünmez, menüde', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.tap(find.text('Gmail'));
      await tester.pumpAndSettle();
      expect(find.byKey(EntryDetailScreen.deleteKey), findsNothing);
      await tester.tap(find.byKey(EntryDetailScreen.moreKey));
      await tester.pumpAndSettle();
      expect(find.byKey(EntryDetailScreen.deleteKey), findsOneWidget);
    });
  });

  group('Giriş ekranı', () {
    TextField field(WidgetTester tester) => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(LoginScreen.passwordKey),
        matching: find.byType(TextField),
      ),
    );

    testWidgets('biyometri kapalıyken şifre alanı odaklı açılır', (
      tester,
    ) async {
      await pumpApp(tester, locked);
      expect(field(tester).autofocus, isTrue);
      expect(find.byKey(BrandBackdrop.backdropKey), findsOneWidget);
    });

    testWidgets('biyometri açıkken klavye açılmaz, biyometri öne çıkar', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AuthState(
          status: AuthStatus.locked,
          biometricAvailable: true,
          biometricEnabled: true,
        ),
      );
      expect(field(tester).autofocus, isFalse);
      expect(find.byKey(LoginScreen.biometricButtonKey), findsOneWidget);
      expect(find.text(l10n.loginOrPassword), findsOneWidget);
    });
  });

  group('Şifre üretici', () {
    test('seçenekler kodlanır / çözülür; bozuk değer reddedilir', () {
      const o = GeneratorOptions(length: 32, symbols: false);
      final back = GeneratorOptions.decode(o.encode())!;
      expect(back.length, 32);
      expect(back.symbols, isFalse);
      expect(back.uppercase, isTrue);
      expect(GeneratorOptions.decode(null), isNull);
      expect(GeneratorOptions.decode('abc'), isNull);
      expect(GeneratorOptions.decode('4|1|1|1|1|0'), isNull); // çok kısa
      expect(GeneratorOptions.decode('20|0|0|0|0|1'), isNull); // grup yok
    });

    testWidgets('son seçenekler hatırlanır (şifre saklanmaz)', (tester) async {
      final store = InMemorySecureStore();
      await pumpApp(tester, unlocked, store: store);
      await openTab(tester, 'nav_generator');
      await tester.tap(find.byKey(GeneratorPanel.symbolsKey));
      await tester.pumpAndSettle();
      final saved = store.data[AppSettingsRepository.generatorKey]!;
      expect(saved, '20|1|1|1|0|0');
      final password = tester
          .widget<ColoredPasswordText>(find.byKey(GeneratorPanel.passwordKey))
          .password;
      expect(store.data.values.any((v) => v.contains(password)), isFalse);
    });

    testWidgets('kayıtlı seçeneklerle açılır', (tester) async {
      final store = InMemorySecureStore()
        ..data[AppSettingsRepository.generatorKey] = '12|0|0|1|0|0';
      await pumpApp(tester, unlocked, store: store);
      await openTab(tester, 'nav_generator');
      final password = tester
          .widget<ColoredPasswordText>(find.byKey(GeneratorPanel.passwordKey))
          .password;
      expect(password, matches(RegExp(r'^[0-9]{12}$')));
    });
  });

  group('Güvenlik raporu', () {
    testWidgets('"Değiştir" düğmesi düzenleme ekranını açar', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await openTab(tester, 'nav_report');
      final change = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('report_change_1_'),
      );
      await tapVisible(tester, change.first);
      expect(find.byType(EntryEditScreen), findsOneWidget);
    });
  });
}
