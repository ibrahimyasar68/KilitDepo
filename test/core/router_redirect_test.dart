import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/router/app_router.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';

void main() {
  test('Hakkında ve Kullanma Talimatı her durumda erişilebilir', () {
    for (final status in AuthStatus.values) {
      expect(authRedirect(status, AppRoutes.about), isNull);
      expect(authRedirect(status, AppRoutes.guide), isNull);
    }
  });

  test('kilitliyken kasa ekranı giriş ekranına yönlenir', () {
    expect(authRedirect(AuthStatus.locked, AppRoutes.vault), AppRoutes.login);
  });

  test('kurulum gerekiyorsa kurulum ekranına yönlenir', () {
    expect(
      authRedirect(AuthStatus.needsSetup, AppRoutes.vault),
      AppRoutes.setup,
    );
    expect(
      authRedirect(AuthStatus.needsSetup, AppRoutes.login),
      AppRoutes.setup,
    );
  });

  test('açıkken giriş/kurulum ekranları kasaya yönlenir', () {
    expect(authRedirect(AuthStatus.unlocked, AppRoutes.login), AppRoutes.vault);
    expect(authRedirect(AuthStatus.unlocked, AppRoutes.setup), AppRoutes.vault);
    expect(authRedirect(AuthStatus.unlocked, AppRoutes.vault), isNull);
  });

  test('başlatılırken açılış ekranında kalır', () {
    expect(authRedirect(AuthStatus.initializing, AppRoutes.splash), isNull);
    expect(
      authRedirect(AuthStatus.initializing, AppRoutes.vault),
      AppRoutes.splash,
    );
  });
}
