import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_service.dart';
import '../../../core/security/secure_clipboard.dart';
import '../../../core/storage/secure_key_value_store.dart';
import '../../../data/database/vault_database_opener.dart';
import '../../../data/repositories/unlock_attempt_limiter.dart';
import '../../../data/repositories/vault_key_repository_impl.dart';
import '../../../data/vault_session.dart';
import '../../../domain/repositories/vault_key_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/settings_providers.dart';
import 'biometric_service.dart';

export '../../settings/application/settings_providers.dart';

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

/// Açık kasa oturumu (DEK, alt anahtarlar, veritabanı). Tek sahip.
final vaultSessionProvider = Provider<VaultSession>((ref) {
  final session = VaultSession(
    crypto: ref.watch(cryptoServiceProvider),
    openDatabase: openVaultDatabase,
  );
  ref.onDispose(session.close);
  return session;
});

/// Panoya kopyalama + otomatik temizleme. Süre ayarı değişince bekleyen
/// temizleme kaybolmasın diye nesne yeniden oluşturulmaz, süresi güncellenir.
final secureClipboardProvider = Provider<SecureClipboard>((ref) {
  final clipboard = SecureClipboard();
  ref.listen(clipboardClearDelayProvider, (_, next) {
    final value = next.value;
    if (value != null) clipboard.clearAfter = value;
  }, fireImmediately: true);
  ref.onDispose(clipboard.dispose);
  return clipboard;
});

/// Anahtarı olmayan (açılamayan) kasa veritabanı dosyasını siler.
/// Testlerde geçersiz kılınır.
final vaultDatabaseDeleterProvider = Provider<Future<void> Function()>(
  (ref) => deleteVaultDatabaseFiles,
);

/// Kasa veritabanı dosyası var mı? Testlerde geçersiz kılınır.
final vaultDatabaseExistsProvider = Provider<Future<bool> Function()>(
  (ref) => vaultDatabaseExists,
);

final vaultStoreProvider = Provider<SecureKeyValueStore>(
  (ref) => FlutterSecureKeyValueStore.vault(),
);

final biometricStoreProvider = Provider<SecureKeyValueStore>((ref) {
  // Sağlayıcılar BuildContext dışında oluşturulduğu için metinler doğrudan
  // Türkçe yerelleştirmeden okunur.
  final l10n = lookupAppLocalizations(const Locale('tr'));
  return FlutterSecureKeyValueStore.biometric(
    promptTitle: l10n.biometricPromptTitle,
    promptSubtitle: l10n.biometricPromptSubtitle,
    promptCancel: l10n.commonCancel,
  );
});

final vaultKeyRepositoryProvider = Provider<VaultKeyRepository>(
  (ref) => VaultKeyRepositoryImpl(
    crypto: ref.watch(cryptoServiceProvider),
    vaultStore: ref.watch(vaultStoreProvider),
    biometricStore: ref.watch(biometricStoreProvider),
  ),
);

final unlockAttemptLimiterProvider = Provider<UnlockAttemptLimiter>(
  (ref) => UnlockAttemptLimiter(ref.watch(vaultStoreProvider)),
);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => LocalAuthBiometricService(),
);

/// Açılış ekranının en az ne kadar görüneceği (testlerde sıfırlanır).
final splashMinDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 300),
);

/// Kasa kapanmadan önce tamamlanması gereken işler (ör. geri alma süresi
/// dolmamış silmeler). Kilitleme her zaman önce bunları bekler; böylece
/// hiçbir iş kapanmış veritabanına yazmaya çalışmaz.
final beforeLockProvider = Provider<BeforeLockHooks>(
  (ref) => BeforeLockHooks(),
);

class BeforeLockHooks {
  final Set<Future<void> Function()> _hooks = {};

  void add(Future<void> Function() hook) => _hooks.add(hook);

  void remove(Future<void> Function() hook) => _hooks.remove(hook);

  /// Tüm işleri çalıştırır. Biri hata verse de kilitleme engellenmez.
  Future<void> runAll() async {
    for (final hook in _hooks.toList()) {
      try {
        await hook();
      } on Object {
        // Kilitlemenin önüne geçmez.
      }
    }
  }
}
