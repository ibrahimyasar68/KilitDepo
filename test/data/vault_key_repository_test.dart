import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/data/models/vault_key_metadata.dart';
import 'package:kilitdepo/data/repositories/vault_key_repository_impl.dart';
import 'package:kilitdepo/domain/repositories/vault_key_repository.dart';

import '../helpers/in_memory_store.dart';

void main() {
  late InMemorySecureStore vaultStore;
  late InMemorySecureStore bioStore;
  late VaultKeyRepositoryImpl repo;

  const password = 'çok-güçlü-ana-şifre-2026';

  setUp(() {
    vaultStore = InMemorySecureStore();
    bioStore = InMemorySecureStore();
    repo = VaultKeyRepositoryImpl(
      crypto: CryptoService(),
      vaultStore: vaultStore,
      biometricStore: bioStore,
      kdfParams: fastTestKdf,
    );
  });

  test('başlangıçta kasa yok', () async {
    expect(await repo.isVaultInitialized(), isFalse);
  });

  test('kasa oluştur → aynı şifreyle aynı DEK açılır', () async {
    final dek = await repo.createVault(password);
    expect(await repo.isVaultInitialized(), isTrue);
    final opened = await repo.unlockWithPassword(password);
    expect(opened.bytes, equals(dek.bytes));
  });

  test('ana şifre ve DEK depoda düz metin olarak bulunmaz', () async {
    final dek = await repo.createVault(password);
    final raw = vaultStore.data.values.join('|');
    expect(raw, isNot(contains(password)));
    expect(raw, isNot(contains(base64Encode(dek.bytes))));
    final meta = VaultKeyMetadata.decode(
      vaultStore.data[VaultStorageKeys.metadata]!,
    );
    expect(meta.salt, hasLength(16));
    expect(meta.kdf, fastTestKdf);
  });

  test('yanlış şifre → WrongMasterPasswordException', () async {
    await repo.createVault(password);
    expect(
      () => repo.unlockWithPassword('yanlış-ana-şifre-2026'),
      throwsA(isA<WrongMasterPasswordException>()),
    );
  });

  test('kasa yokken açma → VaultNotInitializedException', () {
    expect(
      () => repo.unlockWithPassword(password),
      throwsA(isA<VaultNotInitializedException>()),
    );
  });

  test('var olan kasanın üzerine yazılamaz', () async {
    await repo.createVault(password);
    expect(
      () => repo.createVault('başka-bir-şifre-2026'),
      throwsA(isA<VaultAlreadyExistsException>()),
    );
  });

  test('10 karakterden kısa şifre reddedilir', () {
    expect(() => repo.createVault('kısa-şif'), throwsArgumentError);
  });

  test('bozuk meta veri → VaultKeyCorruptedException', () async {
    vaultStore.data[VaultStorageKeys.metadata] = '{bozuk';
    expect(
      () => repo.unlockWithPassword(password),
      throwsA(isA<VaultKeyCorruptedException>()),
    );
  });

  test('depodaki KDF parametreleri değiştirilirse açılamaz', () async {
    await repo.createVault(password);
    final json =
        jsonDecode(vaultStore.data[VaultStorageKeys.metadata]!)
            as Map<String, dynamic>;
    (json['kdf'] as Map<String, dynamic>)['t'] = 2;
    vaultStore.data[VaultStorageKeys.metadata] = jsonEncode(json);
    expect(
      () => repo.unlockWithPassword(password),
      throwsA(isA<WrongMasterPasswordException>()),
    );
  });

  group('ana şifre değiştirme', () {
    const newPassword = 'yepyeni-ana-şifre-2027';

    test('aynı DEK yeni şifreyle açılır, eski şifre çalışmaz', () async {
      final dek = await repo.createVault(password);
      final before = vaultStore.data[VaultStorageKeys.metadata];
      await repo.changeMasterPassword(
        currentPassword: password,
        newPassword: newPassword,
      );
      final opened = await repo.unlockWithPassword(newPassword);
      expect(opened.bytes, equals(dek.bytes));
      expect(
        () => repo.unlockWithPassword(password),
        throwsA(isA<WrongMasterPasswordException>()),
      );
      // Yeni salt kullanıldı.
      final after = VaultKeyMetadata.decode(
        vaultStore.data[VaultStorageKeys.metadata]!,
      );
      expect(after.salt, isNot(VaultKeyMetadata.decode(before!).salt));
    });

    test('yanlış mevcut şifrede hiçbir şey değişmez', () async {
      await repo.createVault(password);
      final before = vaultStore.data[VaultStorageKeys.metadata];
      await expectLater(
        repo.changeMasterPassword(
          currentPassword: 'yanlış-ana-şifre-2026',
          newPassword: newPassword,
        ),
        throwsA(isA<WrongMasterPasswordException>()),
      );
      expect(vaultStore.data[VaultStorageKeys.metadata], before);
    });

    test('kısa yeni şifre reddedilir', () async {
      await repo.createVault(password);
      expect(
        () => repo.changeMasterPassword(
          currentPassword: password,
          newPassword: 'kısa',
        ),
        throwsArgumentError,
      );
    });

    test('biyometrik kopya geçerli kalır', () async {
      final dek = await repo.createVault(password);
      await repo.enableBiometric(dek);
      await repo.changeMasterPassword(
        currentPassword: password,
        newPassword: newPassword,
      );
      expect((await repo.unlockWithBiometric())!.bytes, equals(dek.bytes));
    });
  });

  group('biyometrik', () {
    test('etkinleştir → biyometrik açma aynı DEK\'i verir', () async {
      final dek = await repo.createVault(password);
      await repo.enableBiometric(dek);
      expect(await repo.isBiometricEnabled(), isTrue);
      // DEK, kasa meta deposuna DEĞİL biyometrik depoya yazılır.
      expect(
        vaultStore.data.values.join(),
        isNot(contains(base64Encode(dek.bytes))),
      );
      final opened = await repo.unlockWithBiometric();
      expect(opened!.bytes, equals(dek.bytes));
    });

    test('devre dışı bırak → biyometrik kopya silinir', () async {
      final dek = await repo.createVault(password);
      await repo.enableBiometric(dek);
      await repo.disableBiometric();
      expect(await repo.isBiometricEnabled(), isFalse);
      expect(bioStore.data, isEmpty);
      expect(await repo.unlockWithBiometric(), isNull);
    });
  });
}
