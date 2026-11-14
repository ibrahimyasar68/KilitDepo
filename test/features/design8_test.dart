import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/theme/app_theme.dart';
import 'package:kilitdepo/core/widgets/letter_avatar.dart';
import 'package:kilitdepo/core/widgets/spring_swap.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/generator/presentation/generator_panel.dart';
import 'package:kilitdepo/features/vault/presentation/entry_detail_screen.dart';

import '../helpers/test_app.dart';
import 'design_test.dart' show seeded;

const unlocked = AuthState(status: AuthStatus.unlocked);

void main() {
  group('Şekiller', () {
    test('düğmeler: normalde hap, basılıyken köşeli', () {
      expect(AppTheme.buttonShape.resolve({}), isA<StadiumBorder>());
      final pressed =
          AppTheme.buttonShape.resolve({WidgetState.pressed})
              as RoundedRectangleBorder;
      expect(
        pressed.borderRadius,
        BorderRadius.circular(AppTheme.pressedButtonRadius),
      );
      // Tema düğmeleri bu şekli kullanır.
      final theme = AppTheme.light();
      expect(
        theme.filledButtonTheme.style!.shape!.resolve({}),
        isA<StadiumBorder>(),
      );
      expect(
        theme.outlinedButtonTheme.style!.shape!.resolve({WidgetState.pressed}),
        isA<RoundedRectangleBorder>(),
      );
    });

    test('kart köşeleri 20', () {
      final shape = AppTheme.light().cardTheme.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
    });

    testWidgets('rozetler yuvarlatılmış kare', (tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(LetterAvatar).first,
              matching: find.byType(Container),
            )
            .first,
      );
      final deco = box.decoration! as BoxDecoration;
      expect(deco.shape, BoxShape.rectangle);
      expect(deco.borderRadius, LetterAvatar.shapeOf(40));
    });

    testWidgets('ayarlar: bölümlü liste (dış köşe büyük, iç küçük)', (
      tester,
    ) async {
      await pumpApp(tester, unlocked);
      await openSettings(tester);
      final group = l10n.settingsSecurity;
      BorderRadius radiusOf(int i) =>
          (tester
                      .widget<Card>(
                        find.byKey(Key('settings_segment_${group}_$i')),
                      )
                      .shape!
                  as RoundedRectangleBorder)
              .borderRadius
              .resolve(TextDirection.ltr);
      final first = radiusOf(0);
      expect(first.topLeft.x, 20);
      expect(first.bottomLeft.x, 6);
      expect(radiusOf(1).topLeft.x, 6);
      expect(radiusOf(3).bottomLeft.x, 20);
      // Satır ayırıcı çizgi yok.
      expect(
        find.descendant(
          of: find.byKey(Key('settings_segment_${group}_0')),
          matching: find.byType(Divider),
        ),
        findsNothing,
      );
    });
  });

  group('Yay hareketi', () {
    Future<void> openGmail(WidgetTester tester) async {
      await pumpApp(tester, unlocked, repository: await seeded());
      await tapEntry(tester, 'Gmail');
    }

    testWidgets('favori yıldızı yayla zıplar (ölçek 1\'i aşar)', (
      tester,
    ) async {
      await openGmail(tester);
      await tester.tap(find.byKey(EntryDetailScreen.favoriteKey));
      await tester.pump(); // durum güncellenir
      await tester.pump(); // geçiş başlar
      var maxScale = 0.0;
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final scales = tester
            .widgetList<ScaleTransition>(
              find.descendant(
                of: find.descendant(
                  of: find.byKey(EntryDetailScreen.favoriteKey),
                  matching: find.byType(SpringSwap),
                ),
                matching: find.byType(ScaleTransition),
              ),
            )
            .map((t) => t.scale.value);
        for (final v in scales) {
          if (v > maxScale) maxScale = v;
        }
      }
      expect(maxScale, greaterThan(1));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(EntryDetailScreen.favoriteKey),
          matching: find.byIcon(Icons.star),
        ),
        findsOneWidget,
      );
    });

    testWidgets('animasyonlar kapalıyken yıldız anında değişir', (
      tester,
    ) async {
      await openGmail(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pump();
      await tester.tap(find.byKey(EntryDetailScreen.favoriteKey));
      await tester.pump();
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(EntryDetailScreen.favoriteKey),
          matching: find.byIcon(Icons.star_outline),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('üretici: seçili karakter çipleri ana düğme renginde', (
    tester,
  ) async {
    await pumpApp(tester, unlocked);
    await openTab(tester, 'nav_generator');
    final primary = Theme.of(
      tester.element(find.byKey(GeneratorPanel.upperKey)),
    ).colorScheme.primary;
    final chip = tester.widget<FilterChip>(find.byKey(GeneratorPanel.upperKey));
    expect(chip.selected, isTrue);
    expect(chip.selectedColor, primary);
    // Seçim kaldırılınca sade görünüme döner.
    await tester.tap(find.byKey(GeneratorPanel.symbolsKey));
    await tester.pumpAndSettle();
    final off = tester.widget<FilterChip>(
      find.byKey(GeneratorPanel.symbolsKey),
    );
    expect(off.selected, isFalse);
  });
}
