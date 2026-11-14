import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/app.dart';
import 'package:kilitdepo/core/constants/app_info.dart';
import 'package:kilitdepo/core/security/secure_clipboard.dart';
import 'package:kilitdepo/core/widgets/app_logo.dart';
import 'package:kilitdepo/core/widgets/producer_label.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/application/auth_providers.dart';
import 'package:kilitdepo/data/repositories/app_settings_repository.dart';
import 'package:kilitdepo/features/settings/presentation/settings_screen.dart';
import 'package:kilitdepo/features/vault/application/vault_providers.dart';
import 'package:kilitdepo/l10n/generated/app_localizations.dart';

import 'fake_vault_repository.dart';
import 'in_memory_store.dart';

final l10n = lookupAppLocalizations(const Locale('tr'));

/// Kriptografi ve platform eklentilerinden bağımsız sahte controller.
class FakeAuthController extends AuthController {
  FakeAuthController(this.initial, {this.unlockResult = UnlockResult.success});

  final AuthState initial;
  UnlockResult unlockResult;
  int createCalls = 0;
  int biometricCalls = 0;
  String? lastPassword;
  bool? lastEnableBiometric;

  @override
  AuthState build() => initial;

  @override
  Future<CreateVaultResult> createVault(
    String masterPassword, {
    required bool enableBiometric,
  }) async {
    createCalls++;
    lastPassword = masterPassword;
    lastEnableBiometric = enableBiometric;
    state = state.copyWith(status: AuthStatus.unlocked);
    return CreateVaultResult.success;
  }

  @override
  Future<UnlockResult> unlockWithPassword(String masterPassword) async {
    lastPassword = masterPassword;
    if (unlockResult == UnlockResult.success) {
      state = state.copyWith(status: AuthStatus.unlocked);
    }
    return unlockResult;
  }

  /// Verilirse biyometrik açma bu Completer tamamlanana kadar bekler
  /// (Android'de "İptal" düğmesinin hiç sonuç döndürmemesini taklit eder).
  Completer<UnlockResult>? biometricCompleter;

  @override
  Future<UnlockResult> unlockWithBiometric() async {
    biometricCalls++;
    final completer = biometricCompleter;
    if (completer != null) {
      final result = await completer.future;
      if (result == UnlockResult.success) {
        state = state.copyWith(status: AuthStatus.unlocked);
      }
      return result;
    }
    return UnlockResult.cancelled;
  }

  final List<LockReason> lockCalls = [];
  ChangePasswordResult changeResult = ChangePasswordResult.success;
  (String, String)? lastChange;

  @override
  Future<void> lock({LockReason reason = LockReason.manual}) async {
    lockCalls.add(reason);
    await ref.read(beforeLockProvider).runAll();
    state = state.copyWith(status: AuthStatus.locked);
  }

  BiometricChangeResult biometricResult = BiometricChangeResult.success;
  String? lastBiometricPassword;

  @override
  Future<BiometricChangeResult> enableBiometric(String masterPassword) async {
    lastBiometricPassword = masterPassword;
    if (biometricResult == BiometricChangeResult.success) {
      state = state.copyWith(biometricEnabled: true);
    }
    return biometricResult;
  }

  @override
  Future<void> disableBiometric() async {
    state = state.copyWith(biometricEnabled: false);
  }

  @override
  Future<ChangePasswordResult> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    lastChange = (currentPassword, newPassword);
    return changeResult;
  }
}

/// Testte panoya yazılan değerler ('' = temizleme).
final clipboardWrites = <String?>[];

/// Yerel kanal yerine yazılanları kaydeden pano.
class RecordingClipboardWriter implements ClipboardWriter {
  RecordingClipboardWriter(this.log);
  final List<String?> log;

  @override
  Future<void> copySensitive(String text, Duration expiresIn) async =>
      log.add(text);

  @override
  Future<void> clear() async => log.add('');
}

/// Uygulamayı sahte controller + sahte repository ile başlatır.
Future<(FakeAuthController, FakeVaultRepository)> pumpApp(
  WidgetTester tester,
  AuthState state, {
  UnlockResult unlockResult = UnlockResult.success,
  FakeVaultRepository? repository,
  bool settle = true,
  Duration autoLockTimeout = const Duration(minutes: 1),
  List<Override> extraOverrides = const [],
  InMemorySecureStore? store,
  bool guidePromptAlreadyShown = true,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  clipboardWrites.clear();
  final settingsStore = store ?? InMemorySecureStore();
  settingsStore.data.putIfAbsent(
    AppSettingsRepository.autoLockKey,
    () => '${autoLockTimeout.inSeconds}',
  );
  if (guidePromptAlreadyShown) {
    settingsStore.data[AppSettingsRepository.guidePromptKey] = 'true';
  }
  final fake = FakeAuthController(state, unlockResult: unlockResult);
  final repo = repository ?? FakeVaultRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...extraOverrides,
        vaultStoreProvider.overrideWithValue(settingsStore),
        appVersionProvider.overrideWith((ref) async => '1.0.0'),
        authControllerProvider.overrideWith(() => fake),
        secureClipboardProvider.overrideWith((ref) {
          final c = SecureClipboard(
            writer: RecordingClipboardWriter(clipboardWrites),
            listenLifecycle: false,
          );
          // Üretimdeki gibi: süre ayarı değişince güncellenir.
          ref.listen(clipboardClearDelayProvider, (_, next) {
            if (next.value != null) c.clearAfter = next.value!;
          }, fireImmediately: true);
          ref.onDispose(c.dispose);
          return c;
        }),
        vaultRepositoryProvider.overrideWith(
          (ref) =>
              ref.watch(authControllerProvider.select((s) => s.status)) ==
                  AuthStatus.unlocked
              ? repo
              : null,
        ),
      ],
      child: const KilitDepoApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return (fake, repo);
}

/// Ayarlar listesi tembel kurulur: ekran dışındaki satır bulunana kadar
/// kaydırır.
Future<void> scrollToSetting(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

/// Kasa listesindeki kayıt kartında başlık (favoriler şeridindeki aynı
/// başlık hariç).
Finder entryText(String title) => find.descendant(
  of: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('entry_tile_'),
  ),
  matching: find.text(title),
);

/// Kasa listesindeki kaydı ekranın ortasına kaydırıp açar (alt çubuğun
/// arkasında kalmasın).
Future<void> tapEntry(WidgetTester tester, String title) async {
  final finder = entryText(title);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Üretici etiketi: ekranın altında küçük etiket + logonun sağ alt
/// köşesinde etiket (logo gösteren ekranlarda).
void expectProducerLabel({bool onLogo = true}) {
  expect(find.byKey(ProducerLabel.labelKey), findsOneWidget);
  if (onLogo) expect(find.byKey(AppLogo.producerTagKey), findsOneWidget);
  expect(find.text(AppInfo.producerLabel), findsNWidgets(onLogo ? 2 : 1));
}

/// Alt gezinme çubuğundan bir sekmeyi açar.
Future<void> openTab(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Alt gezinme çubuğundan Ayarlar sekmesini açar.
Future<void> openSettings(WidgetTester tester) =>
    openTab(tester, 'nav_settings');
