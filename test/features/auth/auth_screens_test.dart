import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/constants/app_info.dart';
import 'package:kilitdepo/core/widgets/app_logo.dart';
import 'package:kilitdepo/features/about/presentation/about_screen.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/presentation/login_screen.dart';
import 'package:kilitdepo/features/auth/presentation/setup_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Açılış ekranı', () {
    testWidgets('logo ve üretici etiketi görünür', (tester) async {
      await pumpApp(
        tester,
        const AuthState.initializing(),
        settle: false, // Dönen gösterge yüzünden settle olmaz.
      );
      expect(find.text(AppInfo.appName), findsOneWidget);
      expectProducerLabel();
    });
  });

  group('Ana şifre oluşturma (adım adım)', () {
    const needsSetup = AuthState(status: AuthStatus.needsSetup);
    const withBiometric = AuthState(
      status: AuthStatus.needsSetup,
      biometricAvailable: true,
    );
    const strong = 'Uzun-ve-Güçlü-Şifre-42';

    Future<void> fillPassword(
      WidgetTester tester,
      String password,
      String confirm,
    ) async {
      await tester.enterText(find.byKey(const Key('setup_password')), password);
      await tester.enterText(find.byKey(const Key('setup_confirm')), confirm);
      await tapVisible(tester, find.byKey(SetupScreen.nextButtonKey));
    }

    testWidgets('ilk adım: başlık, ilerleme ve üretici etiketi', (
      tester,
    ) async {
      await pumpApp(tester, needsSetup);
      expect(find.byType(SetupScreen), findsOneWidget);
      expect(find.text(l10n.setupStepPasswordTitle), findsOneWidget);
      expect(find.text(l10n.setupStepOf(1, 2)), findsOneWidget);
      expect(find.byKey(SetupScreen.progressKey), findsOneWidget);
      expectProducerLabel();
    });

    testWidgets('önceki kasa verisi yoksa açıklama gösterilir', (tester) async {
      await pumpApp(
        tester,
        const AuthState(
          status: AuthStatus.needsSetup,
          previousVaultMissing: true,
        ),
      );
      expect(find.byKey(SetupScreen.previousVaultNoticeKey), findsOneWidget);
    });

    testWidgets('normal kurulumda açıklama yok', (tester) async {
      await pumpApp(tester, needsSetup);
      expect(find.byKey(SetupScreen.previousVaultNoticeKey), findsNothing);
    });

    testWidgets('10 karakterden kısa şifreyle ilerlenemez', (tester) async {
      final (fake, _) = await pumpApp(tester, needsSetup);
      await fillPassword(tester, 'kısa', 'kısa');
      expect(find.text(l10n.setupPasswordTooShort(10)), findsOneWidget);
      expect(find.text(l10n.setupStepOf(1, 2)), findsOneWidget);
      expect(fake.createCalls, 0);
    });

    testWidgets('şifreler eşleşmezse ilerlenemez', (tester) async {
      final (fake, _) = await pumpApp(tester, needsSetup);
      await fillPassword(tester, strong, '$strong!');
      expect(find.text(l10n.setupPasswordMismatch), findsOneWidget);
      expect(fake.createCalls, 0);
    });

    testWidgets('güç göstergesi şifreye göre güncellenir', (tester) async {
      await pumpApp(tester, needsSetup);
      await tester.enterText(find.byKey(const Key('setup_password')), 'aaaa');
      await tester.pump();
      expect(
        find.text(l10n.strengthLabel(l10n.strengthVeryWeak)),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('setup_password')),
        'Mavi-Kedi.Uçan*Bulut_42!',
      );
      await tester.pump();
      expect(
        find.text(l10n.strengthLabel(l10n.strengthVeryWeak)),
        findsNothing,
      );
    });

    testWidgets('uyarı onaylanmadan kasa oluşturulmaz', (tester) async {
      final (fake, _) = await pumpApp(tester, needsSetup);
      await fillPassword(tester, strong, strong);
      expect(find.text(l10n.setupStepWarningTitle), findsOneWidget);
      expect(find.text(l10n.setupWarningBody), findsOneWidget);
      await tapVisible(tester, find.byKey(SetupScreen.createButtonKey));
      expect(find.text(l10n.setupAcknowledgeRequired), findsOneWidget);
      expect(fake.createCalls, 0);
    });

    testWidgets('Geri ile önceki adıma dönülür, girilen şifre korunur', (
      tester,
    ) async {
      await pumpApp(tester, needsSetup);
      await fillPassword(tester, strong, strong);
      await tapVisible(tester, find.byKey(SetupScreen.backButtonKey));
      expect(find.text(l10n.setupStepPasswordTitle), findsOneWidget);
      expect(find.text(strong), findsWidgets);
    });

    testWidgets('biyometri yoksa 2 adım: onayla kasa oluşturulur', (
      tester,
    ) async {
      final (fake, _) = await pumpApp(tester, needsSetup);
      await fillPassword(tester, strong, strong);
      await tapVisible(tester, find.byKey(SetupScreen.acknowledgeKey));
      expect(find.byKey(SetupScreen.biometricSwitchKey), findsNothing);
      await tapVisible(tester, find.byKey(SetupScreen.createButtonKey));
      expect(fake.createCalls, 1);
      expect(fake.lastPassword, strong);
      expect(fake.lastEnableBiometric, isFalse);
      expect(find.byType(VaultListScreen), findsOneWidget);
    });

    testWidgets('biyometri varsa 3. adımda seçilir', (tester) async {
      final (fake, _) = await pumpApp(tester, withBiometric);
      expect(find.text(l10n.setupStepOf(1, 3)), findsOneWidget);
      await fillPassword(tester, strong, strong);
      await tapVisible(tester, find.byKey(SetupScreen.acknowledgeKey));
      await tapVisible(tester, find.byKey(SetupScreen.nextButtonKey));
      expect(find.text(l10n.setupStepOf(3, 3)), findsOneWidget);
      await tapVisible(tester, find.byKey(SetupScreen.biometricSwitchKey));
      await tapVisible(tester, find.byKey(SetupScreen.createButtonKey));
      expect(fake.createCalls, 1);
      expect(fake.lastEnableBiometric, isTrue);
    });
  });

  group('Giriş ekranı', () {
    const locked = AuthState(status: AuthStatus.locked);

    testWidgets('üretici etiketi ve "i" ikonu görünür', (tester) async {
      await pumpApp(tester, locked);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byKey(LoginScreen.aboutButtonKey), findsOneWidget);
      expectProducerLabel();
    });

    testWidgets('yanlış şifrede hata gösterilir, kilitli kalır', (
      tester,
    ) async {
      await pumpApp(tester, locked, unlockResult: UnlockResult.wrongPassword);
      await tester.enterText(
        find.byKey(LoginScreen.passwordKey),
        'yanlış-şifre-123',
      );
      await tapVisible(tester, find.byKey(LoginScreen.unlockButtonKey));
      expect(find.text(l10n.loginWrongPassword), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('doğru şifreyle kasa açılır', (tester) async {
      await pumpApp(tester, locked);
      await tester.enterText(
        find.byKey(LoginScreen.passwordKey),
        'Uzun-ve-Güçlü-Şifre-42',
      );
      await tapVisible(tester, find.byKey(LoginScreen.unlockButtonKey));
      expect(find.byType(VaultListScreen), findsOneWidget);
    });

    testWidgets('kilitliyken Hakkında açılır ve etiket görünür', (
      tester,
    ) async {
      await pumpApp(tester, locked);
      await tapVisible(tester, find.byKey(LoginScreen.aboutButtonKey));
      expect(find.text(l10n.aboutTitle), findsOneWidget);
      // Hakkında'da etiket belirgin (büyük, birincil renkte) gösterilir.
      expect(find.byKey(AboutScreen.producerKey), findsOneWidget);
      expect(find.byKey(AppLogo.producerTagKey), findsOneWidget);
      expect(find.text(AppInfo.producerLabel), findsNWidgets(2));
    });

    testWidgets('kilitliyken Kullanma Talimatı açılır', (tester) async {
      await pumpApp(tester, locked);
      await tapVisible(tester, find.byKey(LoginScreen.guideButtonKey));
      expect(find.text(l10n.guideTitle), findsOneWidget);
    });

    testWidgets('biyometri kapalıysa buton yok ve istem açılmaz', (
      tester,
    ) async {
      final (fake, _) = await pumpApp(tester, locked);
      expect(find.byKey(LoginScreen.biometricButtonKey), findsNothing);
      expect(fake.biometricCalls, 0);
    });

    testWidgets(
      'biyometri açıksa bir kez otomatik sorulur; iptalde uyarı yok',
      (tester) async {
        final (fake, _) = await pumpApp(
          tester,
          const AuthState(status: AuthStatus.locked, biometricEnabled: true),
        );
        expect(fake.biometricCalls, 1);
        expect(find.byKey(LoginScreen.biometricButtonKey), findsOneWidget);
        // Kullanıcı vazgeçti: hata gibi görünmesin.
        expect(find.text(l10n.loginBiometricFailed), findsNothing);
      },
    );
  });

  group('Kasa', () {
    testWidgets('kilitle → giriş ekranına döner', (tester) async {
      await pumpApp(tester, const AuthState(status: AuthStatus.unlocked));
      expect(find.byType(VaultListScreen), findsOneWidget);
      await tester.tap(find.byKey(VaultListScreen.lockButtonKey));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
