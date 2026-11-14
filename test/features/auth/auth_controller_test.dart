import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/core/security/secure_clipboard.dart';
import 'package:kilitdepo/data/database/app_database.dart';
import 'package:kilitdepo/data/repositories/unlock_attempt_limiter.dart';
import 'package:kilitdepo/data/repositories/vault_key_repository_impl.dart';
import 'package:kilitdepo/data/vault_session.dart';
import 'package:kilitdepo/domain/repositories/vault_key_repository.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/application/auth_providers.dart';
import 'package:kilitdepo/features/auth/application/biometric_service.dart';

import '../../helpers/in_memory_store.dart';

class _NoBiometrics implements BiometricService {
  @override
  Future<bool> isAvailable() async => false;
}

class _RecordingWriter implements ClipboardWriter {
  final List<String> events = [];
  @override
  Future<void> copySensitive(String text, Duration expiresIn) async =>
      events.add('copy');
  @override
  Future<void> clear() async => events.add('clear');
}

/// Gerçek AuthController + gerçek kripto (hızlı KDF) + bellek içi depo/DB.
void main() {
  const password = 'Doğru-Ana-Şifre-2026';
  late InMemorySecureStore vaultStore;
  late _RecordingWriter clipboard;
  late ProviderContainer container;

  /// Veritabanı açma başarısız olsun mu? (Kasa oluşturma geri alma testi.)
  var failOpen = false;
  var deleteCalls = 0;

  /// Veritabanı dosyası diskte var mı? (Yetim kasa testi.)
  var dbExists = true;

  ProviderContainer build() {
    final crypto = CryptoService();
    return ProviderContainer(
      overrides: [
        vaultStoreProvider.overrideWithValue(vaultStore),
        biometricStoreProvider.overrideWithValue(InMemorySecureStore()),
        vaultKeyRepositoryProvider.overrideWithValue(
          VaultKeyRepositoryImpl(
            crypto: crypto,
            vaultStore: vaultStore,
            biometricStore: InMemorySecureStore(),
            kdfParams: fastTestKdf,
          ),
        ),
        biometricServiceProvider.overrideWithValue(_NoBiometrics()),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        // Üretimdeki gibi: sağlayıcı kapanınca oturum (ve veritabanı) kapanır.
        vaultSessionProvider.overrideWith((ref) {
          final session = VaultSession(
            crypto: crypto,
            openDatabase: (_) async {
              if (failOpen) throw StateError('SQLCipher yüklenemedi');
              return AppDatabase(NativeDatabase.memory());
            },
          );
          ref.onDispose(session.close);
          return session;
        }),
        vaultDatabaseDeleterProvider.overrideWithValue(
          () async => deleteCalls++,
        ),
        vaultDatabaseExistsProvider.overrideWithValue(() async => dbExists),
        secureClipboardProvider.overrideWithValue(
          SecureClipboard(writer: clipboard, listenLifecycle: false),
        ),
      ],
    );
  }

  Future<AuthController> ready() async {
    final c = container.read(authControllerProvider.notifier);
    while (container.read(authControllerProvider).status ==
        AuthStatus.initializing) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return c;
  }

  AuthState state() => container.read(authControllerProvider);

  setUp(() async {
    dbExists = true;
    failOpen = false;
    deleteCalls = 0;
    vaultStore = InMemorySecureStore();
    clipboard = _RecordingWriter();
    container = build();
    final c = await ready();
    await c.createVault(password, enableBiometric: false);
    await c.lock();
  });

  /// Veritabanını kapatmayı BEKLEYEREK container'ı kapatır
  /// (onDispose içindeki close beklenmez).
  Future<void> disposeContainer() async {
    await container.read(vaultSessionProvider).close();
    container.dispose();
  }

  tearDown(disposeContainer);

  test('5 hatalı denemeden sonra giriş beklemeye alınır', () async {
    final c = await ready();
    for (var i = 0; i < 4; i++) {
      expect(
        await c.unlockWithPassword('yanlış-$i-xxxxxx'),
        UnlockResult.wrongPassword,
      );
      expect(state().lockoutUntil, isNull);
    }
    expect(
      await c.unlockWithPassword('yanlış-5-xxxxxx'),
      UnlockResult.wrongPassword,
    );
    expect(state().lockoutUntil, isNotNull);

    // Beklemede doğru şifre bile denenmez.
    expect(await c.unlockWithPassword(password), UnlockResult.lockedOut);
    expect(state().status, AuthStatus.locked);
  });

  test('bekleme uygulama yeniden açılınca da geçerli', () async {
    final c = await ready();
    for (var i = 0; i < 5; i++) {
      await c.unlockWithPassword('yanlış-$i-xxxxxx');
    }
    await disposeContainer();
    container = build();
    await ready();
    expect(state().lockoutUntil, isNotNull);
  });

  test('başarılı giriş sayacı sıfırlar', () async {
    final c = await ready();
    for (var i = 0; i < 3; i++) {
      await c.unlockWithPassword('yanlış-$i-xxxxxx');
    }
    expect(await c.unlockWithPassword(password), UnlockResult.success);
    final limiter = UnlockAttemptLimiter(vaultStore);
    expect(await limiter.failureCount(), 0);
  });

  test('elle kilit panoyu temizler, otomatik kilit temizlemez', () async {
    final c = await ready();
    await c.unlockWithPassword(password);
    await container.read(secureClipboardProvider).copy('gizli');

    await c.lock(reason: LockReason.automatic);
    expect(clipboard.events, ['copy']);
    expect(container.read(vaultSessionProvider).isOpen, isFalse);

    await c.unlockWithPassword(password);
    await c.lock();
    expect(clipboard.events, ['copy', 'clear']);
  });

  group('ana şifre değiştirme', () {
    test('yeni şifre çalışır, eskisi çalışmaz', () async {
      final c = await ready();
      await c.unlockWithPassword(password);
      expect(
        await c.changeMasterPassword(
          currentPassword: password,
          newPassword: 'Yepyeni-Ana-Şifre-99',
        ),
        ChangePasswordResult.success,
      );
      await c.lock();
      expect(await c.unlockWithPassword(password), UnlockResult.wrongPassword);
      expect(
        await c.unlockWithPassword('Yepyeni-Ana-Şifre-99'),
        UnlockResult.success,
      );
    });

    test('yanlış mevcut şifre reddedilir ve hatalı deneme sayılır', () async {
      final c = await ready();
      await c.unlockWithPassword(password);
      expect(
        await c.changeMasterPassword(
          currentPassword: 'yanlış-mevcut-şifre',
          newPassword: 'Yepyeni-Ana-Şifre-99',
        ),
        ChangePasswordResult.wrongCurrentPassword,
      );
      expect(await UnlockAttemptLimiter(vaultStore).failureCount(), 1);
      await c.lock();
      expect(await c.unlockWithPassword(password), UnlockResult.success);
    });
  });

  group('kasa oluşturma yarıda kalırsa geri alınır', () {
    setUp(() async {
      // setUp'taki kasayı temizleyip sıfırdan başla.
      await disposeContainer();
      vaultStore = InMemorySecureStore();
      deleteCalls = 0;
      container = build();
    });

    test('veritabanı açılamazsa anahtar bilgileri silinir, yeniden '
        'denenebilir', () async {
      final c = await ready();
      expect(state().status, AuthStatus.needsSetup);

      failOpen = true;
      await expectLater(
        c.createVault(password, enableBiometric: false),
        throwsStateError,
      );
      // Yarım kasa bırakılmadı.
      expect(vaultStore.data[VaultStorageKeys.metadata], isNull);
      expect(state().status, AuthStatus.needsSetup);
      expect(deleteCalls, 2, reason: 'öncesinde ve geri almada temizlik');

      // Sorun giderilince kurulum tekrar yapılabiliyor.
      failOpen = false;
      await c.createVault(password, enableBiometric: false);
      expect(state().status, AuthStatus.unlocked);
      expect(vaultStore.data[VaultStorageKeys.metadata], isNotNull);
    });

    test(
      'var olan kasanın üzerine oluşturma reddedilir, dosya silinmez',
      () async {
        final c = await ready();
        await c.createVault(password, enableBiometric: false);
        final callsAfterCreate = deleteCalls;
        await expectLater(
          c.createVault('Başka-Bir-Şifre-2026', enableBiometric: false),
          throwsA(isA<VaultAlreadyExistsException>()),
        );
        expect(deleteCalls, callsAfterCreate);
      },
    );
  });

  group('yetim kasa (anahtar var, veri dosyası yok)', () {
    test(
      'açılışta kurulum ekranına döner, anahtar bilgileri silinir',
      () async {
        await disposeContainer();
        dbExists = false; // ör. iOS'ta yeniden kurulum
        container = build();
        await ready();
        expect(state().status, AuthStatus.needsSetup);
        expect(state().previousVaultMissing, isTrue);
        expect(vaultStore.data[VaultStorageKeys.metadata], isNull);
        expect(await UnlockAttemptLimiter(vaultStore).failureCount(), 0);
      },
    );

    test('veri dosyası varsa normal giriş ekranı', () async {
      await disposeContainer();
      dbExists = true;
      container = build();
      await ready();
      expect(state().status, AuthStatus.locked);
      expect(state().previousVaultMissing, isFalse);
      expect(vaultStore.data[VaultStorageKeys.metadata], isNotNull);
    });
  });
}
