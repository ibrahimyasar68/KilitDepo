import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/presentation/login_screen.dart';
import 'package:kilitdepo/features/vault/presentation/entry_detail_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';

import '../helpers/test_app.dart';
import 'design_test.dart' show seeded;

const unlocked = AuthState(status: AuthStatus.unlocked);
const lockedWithBiometric = AuthState(
  status: AuthStatus.locked,
  biometricAvailable: true,
  biometricEnabled: true,
);

TextField passwordField(WidgetTester tester) => tester.widget<TextField>(
  find.descendant(
    of: find.byKey(LoginScreen.passwordKey),
    matching: find.byType(TextField),
  ),
);

IconButton biometricButton(WidgetTester tester) =>
    tester.widget<IconButton>(find.byKey(LoginScreen.biometricButtonKey));

/// Android biyometrik penceresinin açılıp (pasif) kapanmasını (devam) taklit
/// eder.
Future<void> showAndDismissPrompt(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  await tester.pump();
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

void main() {
  group('Biyometri "İptal" düğmesi sonuç döndürmese de', () {
    testWidgets('beklerken ana şifre alanı kullanılabilir kalır', (
      tester,
    ) async {
      final (fake, _) = await pumpApp(tester, lockedWithBiometric);
      fake.biometricCompleter = Completer<UnlockResult>(); // hiç dönmez
      await tester.tap(find.byKey(LoginScreen.biometricButtonKey));
      await tester.pump();
      expect(passwordField(tester).enabled, isTrue);
      expect(biometricButton(tester).onPressed, isNull); // tekrar basılamaz

      // Ana şifreyle giriş yapılabilir.
      await tester.enterText(find.byKey(LoginScreen.passwordKey), 'Ana-Sifre');
      await tester.tap(find.byKey(LoginScreen.unlockButtonKey));
      await tester.pumpAndSettle();
      expect(fake.state.status, AuthStatus.unlocked);
    });

    testWidgets('pencere kapanınca deneme iptal sayılır, ana şifreye dönülür', (
      tester,
    ) async {
      final (fake, _) = await pumpApp(tester, lockedWithBiometric);
      fake.biometricCompleter = Completer<UnlockResult>();
      await tester.tap(find.byKey(LoginScreen.biometricButtonKey));
      await tester.pump();

      await showAndDismissPrompt(tester);
      await tester.pump(const Duration(milliseconds: 900));
      // İptal hata değildir: uyarı gösterilmez.
      expect(find.text(l10n.loginBiometricFailed), findsNothing);
      expect(
        biometricButton(tester).onPressed,
        isNotNull,
      ); // yeniden denenebilir
      // Klavye için ana şifre alanı odaklanır.
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(LoginScreen.passwordKey),
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      // Eklenti sonradan bir şey döndürse de sorun çıkmaz.
      fake.biometricCompleter!.complete(UnlockResult.cancelled);
      await tester.pumpAndSettle();
      expect(find.text(l10n.loginBiometricFailed), findsNothing);
    });

    testWidgets('sonuç süre içinde gelirse (başarı) normal açılır', (
      tester,
    ) async {
      final (fake, _) = await pumpApp(tester, lockedWithBiometric);
      fake.biometricCompleter = Completer<UnlockResult>();
      await tester.tap(find.byKey(LoginScreen.biometricButtonKey));
      await tester.pump();
      await showAndDismissPrompt(tester);
      await tester.pump(const Duration(milliseconds: 200));
      fake.biometricCompleter!.complete(UnlockResult.success);
      await tester.pumpAndSettle();
      expect(fake.state.status, AuthStatus.unlocked);
      expect(find.byType(VaultListScreen), findsOneWidget);
    });
  });

  group('Bildirimler kendiliğinden kapanır', () {
    testWidgets('pano bildirimi 30 sn sonra kapanır', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tester.tap(find.byKey(const Key('entry_copy_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(clipboardWrites.last, ''); // pano da temizlendi
    });

    testWidgets('"Geri al" bildirimi silme süresi dolunca kapanır', (
      tester,
    ) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tapEntry(tester, 'Gmail');
      await tester.tap(find.byKey(EntryDetailScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(EntryDetailScreen.deleteKey));
      await tester.pumpAndSettle();
      expect(find.byKey(EntryDetailScreen.undoSnackKey), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.byKey(EntryDetailScreen.undoSnackKey), findsNothing);
    });
  });
}
