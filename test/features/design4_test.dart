import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/widgets/colored_password_text.dart';
import 'package:kilitdepo/data/repositories/app_settings_repository.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/application/password_strength.dart';
import 'package:kilitdepo/features/generator/application/passphrase_generator.dart';
import 'package:kilitdepo/features/generator/data/turkish_words.dart';
import 'package:kilitdepo/features/generator/presentation/generator_panel.dart';
import 'package:kilitdepo/features/settings/presentation/settings_screen.dart';

import '../helpers/in_memory_store.dart';
import '../helpers/test_app.dart';

const unlocked = AuthState(status: AuthStatus.unlocked);

String generated(WidgetTester tester) => tester
    .widget<ColoredPasswordText>(find.byKey(GeneratorPanel.passwordKey))
    .password;

void main() {
  group('Kelime listesi', () {
    test('yalnızca a–z, 3–8 harf, tekrarsız, en az 2048 kelime', () {
      expect(turkishWords.length, greaterThanOrEqualTo(2048));
      expect(turkishWords.toSet(), hasLength(turkishWords.length));
      final pattern = RegExp(r'^[a-z]{3,8}$');
      for (final w in turkishWords) {
        expect(pattern.hasMatch(w), isTrue, reason: w);
      }
    });
  });

  group('Kelime tabanlı üretici', () {
    test('kelime sayısı, ayırıcı, büyük harf ve sayı kurallarına uyar', () {
      final gen = PassphraseGenerator(random: Random(1));
      const o = PassphraseOptions(wordCount: 4, separator: '.');
      final parts = gen.generate(o).split('.');
      expect(parts, hasLength(5));
      for (final w in parts.take(4)) {
        expect(w[0], w[0].toUpperCase());
        expect(turkishWords, contains(w.toLowerCase()));
      }
      expect(parts.last, matches(RegExp(r'^\d{2}$')));

      final plain = gen.generate(
        const PassphraseOptions(
          wordCount: 3,
          capitalize: false,
          addNumber: false,
        ),
      );
      final words = plain.split('-');
      expect(words, hasLength(3));
      expect(words.every(turkishWords.contains), isTrue);
    });

    test('güç seçim uzayından hesaplanır', () {
      final gen = PassphraseGenerator(words: List.generate(2048, (i) => '$i'));
      expect(
        gen.entropyBits(
          const PassphraseOptions(wordCount: 6, addNumber: false),
        ),
        closeTo(66, 0.001),
      );
      expect(
        gen.entropyBits(const PassphraseOptions(wordCount: 6)),
        closeTo(66 + log(100) / ln2, 0.001),
      );
    });

    test('seçenekler kodlanır / çözülür; bozuk değer reddedilir', () {
      const o = PassphraseOptions(wordCount: 7, separator: '_');
      final back = PassphraseOptions.decode(o.encode())!;
      expect(back.wordCount, 7);
      expect(back.separator, '_');
      expect(PassphraseOptions.decode('2|0|1|1'), isNull);
      expect(PassphraseOptions.decode('5|9|1|1'), isNull);
      expect(PassphraseOptions.decode(null), isNull);
    });

    test('bit → güç seviyesi', () {
      expect(PasswordStrengthEstimator.fromBits(30), PasswordStrength.veryWeak);
      expect(PasswordStrengthEstimator.fromBits(73), PasswordStrength.fair);
      expect(PasswordStrengthEstimator.fromBits(85), PasswordStrength.strong);
    });

    testWidgets('Kelimeler kipi: 6 kelime + sayı, gerçek güç; kip hatırlanır', (
      tester,
    ) async {
      final store = InMemorySecureStore();
      await pumpApp(tester, unlocked, store: store);
      await openTab(tester, 'nav_generator');
      await tester.tap(find.byKey(const Key('gen_mode_words')));
      await tester.pumpAndSettle();
      final parts = generated(tester).split('-');
      expect(parts, hasLength(7));
      expect(find.byKey(GeneratorPanel.entropyKey), findsOneWidget);
      expect(store.data[AppSettingsRepository.generatorModeKey], 'words');
      // Karakter sayısına göre "çok güçlü" görünürdü; gerçek güç "orta".
      expect(find.text(l10n.strengthLabel(l10n.strengthFair)), findsOneWidget);

      await tapVisible(tester, find.byKey(GeneratorPanel.separatorKey('_')));
      expect(generated(tester).split('_'), hasLength(7));
      expect(store.data[AppSettingsRepository.passphraseKey], '6|2|1|1');
    });

    testWidgets('kayıtlı kip ve kelime seçenekleriyle açılır', (tester) async {
      final store = InMemorySecureStore()
        ..data[AppSettingsRepository.generatorModeKey] = 'words'
        ..data[AppSettingsRepository.passphraseKey] = '3|1|0|0';
      await pumpApp(tester, unlocked, store: store);
      await openTab(tester, 'nav_generator');
      final parts = generated(tester).split('.');
      expect(parts, hasLength(3));
      expect(parts.every(turkishWords.contains), isTrue);
    });
  });

  group('Tam siyah zemin', () {
    testWidgets('anahtar kaydedilir ve koyu tema zemini siyah olur', (
      tester,
    ) async {
      final store = InMemorySecureStore();
      await pumpApp(tester, unlocked, store: store);
      await openSettings(tester);
      var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.darkTheme!.colorScheme.surface, isNot(Colors.black));
      await tapVisible(tester, find.byKey(SettingsScreen.trueBlackKey));
      expect(store.data[AppSettingsRepository.trueBlackKey], 'true');
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.darkTheme!.colorScheme.surface, Colors.black);
      // Açık tema etkilenmez.
      expect(app.theme!.colorScheme.surface, isNot(Colors.black));
    });
  });
}
