import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/widgets/colored_password_text.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/presentation/setup_screen.dart';
import 'package:kilitdepo/features/generator/data/turkish_words.dart';

import '../helpers/test_app.dart';

const needsSetup = AuthState(status: AuthStatus.needsSetup);

String fieldText(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Future<void> fill(WidgetTester tester, String password) async {
  await tester.enterText(find.byKey(const Key('setup_password')), password);
  await tester.enterText(find.byKey(const Key('setup_confirm')), password);
  await tapVisible(tester, find.byKey(SetupScreen.nextButtonKey));
}

void main() {
  group('Ana şifre rehberliği', () {
    testWidgets('ipuçları açılır; öneri yalnızca ilk alana yazılır', (
      tester,
    ) async {
      await pumpApp(tester, needsSetup);
      await tapVisible(tester, find.text(l10n.setupTipsTitle));
      expect(find.text(l10n.setupTipWords), findsOneWidget);
      expect(find.text(l10n.setupTipPersonal), findsOneWidget);

      await tapVisible(tester, find.byKey(SetupScreen.suggestKey));
      final suggestion = tester
          .widget<ColoredPasswordText>(
            find.descendant(
              of: find.byKey(SetupScreen.suggestionKey),
              matching: find.byType(ColoredPasswordText),
            ),
          )
          .password;
      final parts = suggestion.split('-');
      expect(parts, hasLength(6)); // 5 kelime + sayı
      for (final w in parts.take(5)) {
        expect(turkishWords, contains(w.toLowerCase()));
      }

      await tapVisible(tester, find.byKey(SetupScreen.useSuggestionKey));
      expect(fieldText(tester, 'setup_password'), suggestion);
      expect(fieldText(tester, 'setup_confirm'), isEmpty);
      expect(find.text(l10n.setupSuggestionHint), findsOneWidget);
    });

    testWidgets('zayıf şifrede uyarı: "Değiştir" adımda tutar, "Yine de" '
        'ilerletir', (tester) async {
      await pumpApp(tester, needsSetup);
      await fill(tester, '1234567890');
      expect(find.byKey(SetupScreen.weakDialogKey), findsOneWidget);
      await tester.tap(find.text(l10n.setupWeakChange));
      await tester.pumpAndSettle();
      expect(find.text(l10n.setupStepPasswordTitle), findsOneWidget);

      await tapVisible(tester, find.byKey(SetupScreen.nextButtonKey));
      await tester.tap(find.byKey(SetupScreen.weakContinueKey));
      await tester.pumpAndSettle();
      expect(find.byKey(SetupScreen.acknowledgeKey), findsOneWidget);
    });

    testWidgets('güçlü şifrede uyarı çıkmaz; saklama listesi görünür', (
      tester,
    ) async {
      await pumpApp(tester, needsSetup);
      await fill(tester, 'Kartal-Limon-Dere-Masa-47');
      expect(find.byKey(SetupScreen.weakDialogKey), findsNothing);
      expect(find.byKey(SetupScreen.storeChecklistKey), findsOneWidget);
      expect(find.text(l10n.setupStorePaper), findsOneWidget);
      expect(find.text(l10n.setupStoreNoPhone), findsOneWidget);
      expect(find.text(l10n.setupStoreBackup), findsOneWidget);
    });
  });
}
