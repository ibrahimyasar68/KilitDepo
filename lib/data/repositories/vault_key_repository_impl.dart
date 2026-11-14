import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../../core/constants/crypto_params.dart';
import '../../core/crypto/crypto_exceptions.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/crypto/kdf_params.dart';
import '../../core/storage/secure_key_value_store.dart';
import '../../domain/repositories/vault_key_repository.dart';
import '../models/vault_key_metadata.dart';

/// Güvenli depo anahtar adları.
abstract final class VaultStorageKeys {
  static const String metadata = 'vault.metadata.v1';
  static const String biometricEnabled = 'vault.biometric.enabled';
  static const String biometricDek = 'vault.biometric.dek';
}

class VaultKeyRepositoryImpl implements VaultKeyRepository {
  VaultKeyRepositoryImpl({
    required this._crypto,
    required this._vaultStore,
    required this._biometricStore,
    this._kdfParams = CryptoParams.defaultKdf,
  });

  final CryptoService _crypto;
  final SecureKeyValueStore _vaultStore;
  final SecureKeyValueStore _biometricStore;
  final KdfParams _kdfParams;

  @override
  Future<bool> isVaultInitialized() async =>
      (await _vaultStore.read(VaultStorageKeys.metadata)) != null;

  @override
  Future<SecretKeyData> createVault(String masterPassword) async {
    if (masterPassword.length < CryptoParams.minMasterPasswordLength) {
      throw ArgumentError('Ana şifre çok kısa.');
    }
    if (await isVaultInitialized()) {
      // Var olan kasanın üzerine yazmak tüm verinin kaybı demektir.
      throw const VaultAlreadyExistsException();
    }

    final dek = _crypto.generateDek();
    try {
      await _wrapAndStore(dek, masterPassword);
      return dek;
    } catch (_) {
      dek.destroy();
      rethrow;
    }
  }

  @override
  Future<void> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < CryptoParams.minMasterPasswordLength) {
      throw ArgumentError('Ana şifre çok kısa.');
    }
    // Mevcut şifreyi doğrulamanın tek yolu DEK'i açabilmektir.
    final dek = await unlockWithPassword(currentPassword);
    try {
      // Yeni rastgele salt + GÜNCEL varsayılan KDF parametreleri: eski
      // kasalar parametre yükseltmesini bu adımda alır. DEK değişmediği
      // için kayıtlar yeniden şifrelenmez ve biyometrik kopya geçerli kalır.
      await _wrapAndStore(dek, newPassword);
    } finally {
      dek.destroy();
    }
  }

  /// DEK'i [password]'den yeni salt ile türetilen anahtarla sarar ve
  /// meta veriyi tek bir yazma işlemiyle günceller.
  Future<void> _wrapAndStore(SecretKeyData dek, String password) async {
    final salt = _crypto.generateSalt();
    final kek = await _crypto.deriveKek(
      password: password,
      salt: salt,
      params: _kdfParams,
    );
    try {
      final draft = VaultKeyMetadata(
        version: VaultKeyMetadata.currentVersion,
        kdf: _kdfParams,
        salt: salt,
        wrappedDek: Uint8List(0), // AAD hesaplamasında kullanılmaz.
      );
      final wrapped = await _crypto.wrapDek(
        dek: dek,
        kek: kek,
        associatedData: draft.associatedData,
      );
      final metadata = VaultKeyMetadata(
        version: draft.version,
        kdf: draft.kdf,
        salt: draft.salt,
        wrappedDek: wrapped,
      );
      await _vaultStore.write(VaultStorageKeys.metadata, metadata.encode());
    } finally {
      kek.destroy();
    }
  }

  @override
  Future<SecretKeyData> unlockWithPassword(String masterPassword) async {
    final metadata = await _readMetadata();
    final kek = await _crypto.deriveKek(
      password: masterPassword,
      salt: metadata.salt,
      params: metadata.kdf,
    );
    try {
      return await _crypto.unwrapDek(
        wrappedDek: metadata.wrappedDek,
        kek: kek,
        associatedData: metadata.associatedData,
      );
    } on DecryptionFailedException {
      // GCM yanlış anahtarı ve bozulmuş veriyi ayırt etmez; kullanıcıya
      // gösterilecek en olası neden yanlış şifredir.
      throw const WrongMasterPasswordException();
    } on MalformedCiphertextException {
      throw const VaultKeyCorruptedException();
    } finally {
      kek.destroy();
    }
  }

  @override
  Future<bool> isBiometricEnabled() async =>
      (await _vaultStore.read(VaultStorageKeys.biometricEnabled)) == 'true';

  @override
  Future<void> enableBiometric(SecretKeyData dek) async {
    // DEK, biyometriye bağlı donanım anahtarıyla korunan depoya yazılır.
    await _biometricStore.write(
      VaultStorageKeys.biometricDek,
      base64Encode(dek.bytes),
    );
    await _vaultStore.write(VaultStorageKeys.biometricEnabled, 'true');
  }

  @override
  Future<void> discardNewVault() async {
    await disableBiometric();
    await _vaultStore.delete(VaultStorageKeys.metadata);
  }

  @override
  Future<void> disableBiometric() async {
    await _vaultStore.delete(VaultStorageKeys.biometricEnabled);
    await _biometricStore.delete(VaultStorageKeys.biometricDek);
  }

  @override
  Future<SecretKeyData?> unlockWithBiometric() async {
    // Okuma işlemi platformun biyometrik istemini tetikler.
    final String? encoded;
    try {
      encoded = await _biometricStore.read(VaultStorageKeys.biometricDek);
    } on PlatformException catch (e) {
      if (isBiometricCancellation(e)) throw const BiometricCancelledException();
      rethrow;
    }
    if (encoded == null) return null;
    final bytes = base64Decode(encoded);
    if (bytes.length != CryptoParams.dekLength) {
      throw const VaultKeyCorruptedException();
    }
    return SecretKeyData(bytes);
  }

  Future<VaultKeyMetadata> _readMetadata() async {
    final raw = await _vaultStore.read(VaultStorageKeys.metadata);
    if (raw == null) throw const VaultNotInitializedException();
    try {
      final metadata = VaultKeyMetadata.decode(raw);
      if (metadata.version != VaultKeyMetadata.currentVersion) {
        throw const VaultKeyCorruptedException();
      }
      return metadata;
    } on FormatException {
      throw const VaultKeyCorruptedException();
    } on TypeError {
      throw const VaultKeyCorruptedException();
    }
  }
}

/// Platform hatası kullanıcının biyometrik istemden vazgeçmesi mi?
///
/// - Android (flutter_secure_storage): mesaj
///   `Biometric authentication error [kod]: ...`; 5 = iptal edildi,
///   10 = kullanıcı iptal etti (geri tuşu / dışarı dokunma),
///   13 = olumsuz düğme. Diğer kodlar (ör. 7/9 çok fazla deneme, anahtar
///   geçersiz) gerçek hatadır.
/// - iOS: güvenlik durum kodu `errSecUserCanceled` (-128).
bool isBiometricCancellation(PlatformException e) {
  if (e.details == -128 || e.code == '-128') return true;
  final match = RegExp(
    r'Biometric authentication error \[(\d+)\]',
  ).firstMatch(e.message ?? '');
  if (match == null) return false;
  return const {5, 10, 13}.contains(int.parse(match.group(1)!));
}
