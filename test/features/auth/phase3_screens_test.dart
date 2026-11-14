import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/presentation/change_password_screen.dart';
import 'package:kilitdepo/features/auth/presentation/login_screen.dart';
import 'package:kilitdepo/features/auth/presentation/widgets/lockout_banner.dart';
import 'package:kilitdepo/features/settings/presentation/settings_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';

import '../../helpers/test_app.dart';

const unlocked = AuthState(status: AuthStatus.unlocked);

void main() {
  group('Otomatik kilit', () {
    testWidgets('arka plana geçince hemen (otomatik) kilitlenir', (
      tester,
    ) async {
      final (fake, _) = await pumpApp(tester, unlocked);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(fake.lockCalls, isEmpty, reason: 'pasif durum kilitlememeli');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pumpAndSettle();
      expect(fake.lockCalls, [LockReason.automatic]);
      // Gizliyken kare çizilmez; öne gelince giriş ekranı görünür.
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('hareketsizlik süresi dolunca kilitlenir', (tester) async {
      final (fake, _) = await pumpApp(tester, unlocked);
      await tester.pump(const Duration(seconds: 59));
      expect(fake.lockCalls, isEmpty);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(fake.lockCalls, [LockReason.automatic]);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('dokunuş süreyi sıfırlar', (tester) async {
      final (fake, _) = await pumpApp(tester, unlocked);
      await tester.pump(const Duration(seconds: 50));
      await tester.tapAt(const Offset(200, 400));
      await tester.pump(const Duration(seconds: 50));
      expect(fake.lockCalls, isEmpty);
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
      expect(fake.lockCalls, [LockReason.automatic]);
    });

    testWidgets('ayarlanan süre kullanılır', (tester) async {
      final (fake, _) = await pumpApp(
        tester,
        unlocked,
        autoLockTimeout: const Duration(minutes: 5),
      );
      await tester.pump(const Duration(minutes: 4));
      expect(fake.lockCalls, isEmpty);
      await tester.pump(const Duration(minutes: 1, seconds: 1));
      await tester.pumpAndSettle();
      expect(fake.lockCalls, [LockReason.automatic]);
    });

    testWidgets('elle kilit "manual" nedeniyle yapılır', (tester) async {
      final (fake, _) = await pumpApp(tester, unlocked);
      await tester.tap(find.byKey(VaultListScreen.lockButtonKey));
      await tester.pumpAndSettle();
      expect(fake.lockCalls, [LockReason.manual]);
    });
  });

  group('Hatalı deneme beklemesi', () {
    testWidgets('beklemede geri sayım gösterilir, giriş kapalıdır', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AuthState(
          status: AuthStatus.locked,
          lockoutUntil: DateTime.now().add(const Duration(minutes: 5)),
        ),
        // Geri sayım her saniye yeniden çizdiği için "settle" olmaz.
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(LockoutBanner.bannerKey), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(LoginScreen.unlockButtonKey),
      );
      expect(button.onPressed, isNull);
      await tester.pump(const Duration(seconds: 1));
    });

    test('geri sayım biçimi', () {
      expect(LockoutBanner.format(const Duration(seconds: 30)), '00:30');
      expect(LockoutBanner.format(const Duration(minutes: 15)), '15:00');
      expect(LockoutBanner.format(const Duration(hours: 1)), '1:00:00');
    });
  });

  group('Ana şifre değiştirme ekranı', () {
    Future<FakeAuthController> open(WidgetTester tester) async {
      final (fake, _) = await pumpApp(tester, unlocked);
      await openSettings(tester);
      await tester.tap(find.text(l10n.changePasswordTitle));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      return fake;
    }

    Future<void> fill(
      WidgetTester tester,
      String current,
      String next,
      String confirm,
    ) async {
      await tester.enterText(
        find.byKey(ChangePasswordScreen.currentKey),
        current,
      );
      await tester.enterText(find.byKey(ChangePasswordScreen.newKey), next);
      await tester.enterText(
        find.byKey(ChangePasswordScreen.confirmKey),
        confirm,
      );
      await tapVisible(tester, find.byKey(ChangePasswordScreen.submitKey));
    }

    testWidgets('yeni şifre eskisiyle aynı olamaz', (tester) async {
      final fake = await open(tester);
      await fill(
        tester,
        'Aynı-Şifre-123456',
        'Aynı-Şifre-123456',
        'Aynı-Şifre-123456',
      );
      expect(find.text(l10n.changePasswordSameAsOld), findsOneWidget);
      expect(fake.lastChange, isNull);
    });

    testWidgets('kısa ve eşleşmeyen yeni şifre reddedilir', (tester) async {
      final fake = await open(tester);
      await fill(tester, 'Eski-Şifre-123456', 'kısa', 'kısa');
      expect(find.text(l10n.setupPasswordTooShort(10)), findsOneWidget);
      await fill(
        tester,
        'Eski-Şifre-123456',
        'Yeni-Şifre-123456',
        'Yeni-Şifre-654321',
      );
      expect(find.text(l10n.setupPasswordMismatch), findsOneWidget);
      expect(fake.lastChange, isNull);
    });

    testWidgets('yanlış mevcut şifre hatası gösterilir', (tester) async {
      final fake = await open(tester);
      fake.changeResult = ChangePasswordResult.wrongCurrentPassword;
      await fill(
        tester,
        'Yanlış-Şifre-1234',
        'Yeni-Şifre-123456',
        'Yeni-Şifre-123456',
      );
      expect(find.text(l10n.changePasswordWrongCurrent), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('başarıda Ayarlar ekranına döner', (tester) async {
      final fake = await open(tester);
      await fill(
        tester,
        'Eski-Şifre-123456',
        'Yeni-Şifre-123456',
        'Yeni-Şifre-123456',
      );
      expect(fake.lastChange, ('Eski-Şifre-123456', 'Yeni-Şifre-123456'));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text(l10n.changePasswordSuccess), findsOneWidget);
    });
  });
}
