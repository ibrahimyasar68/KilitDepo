import 'package:cryptography/cryptography.dart';

/// Ana şifre yanlış.
class WrongMasterPasswordException implements Exception {
  const WrongMasterPasswordException();
}

/// Kasa henüz oluşturulmamış.
class VaultNotInitializedException implements Exception {
  const VaultNotInitializedException();
}

/// Kasa zaten var (yeniden oluşturma engellenir).
class VaultAlreadyExistsException implements Exception {
  const VaultAlreadyExistsException();
}

/// Saklanan anahtar verisi okunamıyor / bozuk.
/// Kullanıcı biyometrik istemden kendisi vazgeçti ("İptal", geri tuşu).
/// Hata değildir; giriş ekranı uyarı göstermez.
class BiometricCancelledException implements Exception {
  const BiometricCancelledException();
}

class VaultKeyCorruptedException implements Exception {
  const VaultKeyCorruptedException();
}

/// Kasa anahtarlarının (DEK) yaşam döngüsü.
///
/// Ana şifre bu arayüzden içeri girer ama HİÇBİR ZAMAN saklanmaz;
/// yalnızca ondan türetilen anahtarla sarılmış DEK saklanır.
abstract interface class VaultKeyRepository {
  Future<bool> isVaultInitialized();

  /// Yeni kasa oluşturur ve açık DEK'i döndürür.
  Future<SecretKeyData> createVault(String masterPassword);

  /// Ana şifreyle DEK'i açar.
  /// Yanlış şifrede [WrongMasterPasswordException] fırlatır.
  Future<SecretKeyData> unlockWithPassword(String masterPassword);

  /// Ana şifreyi değiştirir: mevcut şifreyle DEK açılır, yeni şifreden
  /// yeni salt + güncel KDF parametreleriyle türetilen anahtarla yeniden
  /// sarılır. Yanlış mevcut şifrede [WrongMasterPasswordException].
  Future<void> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Yeni oluşturulan ama açılamayan kasanın anahtar bilgilerini siler
  /// (sarılmış DEK, biyometrik kopya). YALNIZCA kasa oluşturma yarıda
  /// kaldığında, içinde hiç kayıt yokken kullanılır.
  Future<void> discardNewVault();

  Future<bool> isBiometricEnabled();

  /// DEK'in bir kopyasını biyometriye bağlı depoya yazar.
  Future<void> enableBiometric(SecretKeyData dek);

  Future<void> disableBiometric();

  /// Biyometrik doğrulamayla DEK'i okur. Kullanıcı iptal ederse veya
  /// biyometri değiştiyse null döner.
  Future<SecretKeyData?> unlockWithBiometric();
}
