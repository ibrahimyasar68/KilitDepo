import '../crypto/kdf_params.dart';

/// Kriptografik sabitler. Tüm değerler tek yerde tutulur.
abstract final class CryptoParams {
  /// Ana şifreden anahtar türetme (Argon2id) varsayılanları:
  /// 32 MiB bellek, 6 iterasyon, 4 paralellik, 32 byte çıktı.
  static const KdfParams defaultKdf = KdfParams(
    memoryKiB: 32 * 1024,
    iterations: 6,
    parallelism: 4,
    hashLength: 32,
  );

  /// Yedek dosyası için Argon2id: yedek cihazdan çıkabildiği (bulut,
  /// bilgisayar) için çevrimdışı saldırıya daha açıktır; bellek iki katı.
  static const KdfParams backupKdf = KdfParams(
    memoryKiB: 64 * 1024,
    iterations: 6,
    parallelism: 4,
    hashLength: 32,
  );

  /// Yedek şifresi için en az karakter sayısı.
  static const int minBackupPasswordLength = 10;

  /// Argon2id salt uzunluğu (byte).
  static const int saltLength = 16;

  /// Veri anahtarı (DEK) uzunluğu: 256 bit.
  static const int dekLength = 32;

  /// AES-GCM nonce uzunluğu (96 bit, NIST önerisi).
  static const int gcmNonceLength = 12;

  /// AES-GCM kimlik doğrulama etiketi uzunluğu (128 bit).
  static const int gcmMacLength = 16;

  /// Şifreli veri biçim sürümü (ilk byte).
  static const int envelopeVersion = 1;

  /// Ana şifre için en az karakter sayısı.
  static const int minMasterPasswordLength = 10;

  /// DEK sarma işleminde kullanılan bağlam etiketi (AAD).
  static const String dekWrapContext = 'kilitdepo/dek-wrap/v1';

  /// DEK'ten HKDF ile türetilen alt anahtarların bağlam etiketleri.
  /// Aynı anahtarı iki farklı amaçla kullanmamak için ayrı alt anahtarlar.
  static const String hkdfDatabaseInfo = 'kilitdepo/sqlcipher/v1';
  static const String hkdfFieldInfo = 'kilitdepo/field-aead/v1';
}
