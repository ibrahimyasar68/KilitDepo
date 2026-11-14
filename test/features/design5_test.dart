import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/theme/app_surfaces.dart';
import 'package:kilitdepo/core/theme/app_theme.dart';
import 'package:kilitdepo/core/widgets/app_background.dart';
import 'package:kilitdepo/core/widgets/depth_card.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';

import '../helpers/test_app.dart';
import 'design_test.dart' show seeded;

const unlocked = AuthState(status: AuthStatus.unlocked);

void main() {
  group('Zemin ve yüzeyler', () {
    test('zemin kartlardan koyu; sayfalar saydam', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final s = theme.extension<AppSurfaces>()!;
        expect(theme.scaffoldBackgroundColor, Colors.transparent);
        expect(
          s.background.computeLuminance(),
          lessThan(s.card.computeLuminance()),
        );
      }
      // Tam siyah temada zemin siyah kalır.
      final black = AppTheme.dark(black: true).extension<AppSurfaces>()!;
      expect(black.background, Colors.black);
    });

    testWidgets('zemin + ışıma uygulama kökünde tek katman', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      expect(find.byKey(AppBackground.backgroundKey), findsOneWidget);
    });
  });

  group('Buzlu cam ve derinlik', () {
    testWidgets('alt çubuk bulanık; + butonu çubuğun üstünde', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      final blur = find.ancestor(
        of: find.byType(NavigationBar),
        matching: find.byType(BackdropFilter),
      );
      expect(blur, findsOneWidget);
      expect(tester.widget<BackdropFilter>(blur).filter, isA<ImageFilter>());
      final bar = tester.getRect(find.byType(NavigationBar));
      final fab = tester.getRect(find.byKey(VaultListScreen.addButtonKey));
      expect(fab.bottom, lessThanOrEqualTo(bar.top));
    });

    testWidgets('kayıtlar derinlikli kartta; seçili değilken parıltı yok', (
      tester,
    ) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      final cards = tester.widgetList<DepthCard>(find.byType(DepthCard));
      expect(cards, hasLength(3));
      expect(cards.every((c) => c.pressable && c.glow == null), isTrue);
    });

    test('basılıyken gölge içeri çekilir; parıltı ayrı katman', () {
      final s = AppTheme.light().extension<AppSurfaces>()!;
      final normal = s.cardShadows();
      final pressed = s.cardShadows(pressed: true);
      expect(pressed.first.blurRadius, lessThan(normal.first.blurRadius));
      expect(s.cardShadows(glow: Colors.green), hasLength(normal.length + 1));
    });

    testWidgets('rapor: yalnızca sorun olan özet kartı parlar', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await openTab(tester, 'nav_report');
      DepthCard card(String key) => tester.widget<DepthCard>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(DepthCard),
          matchRoot: true,
        ),
      );
      // Örnek kasada zayıf şifre yok, tekrar kullanılan var.
      expect(card('report_weak').glow, isNull);
      expect(card('report_reused').glow, isNotNull);
    });
  });
}
