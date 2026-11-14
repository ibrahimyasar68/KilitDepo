import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Güvenli anahtar-değer deposu soyutlaması (testlerde bellek içi sürüm).
abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// iOS Keychain / Android Keystore destekli depo.
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore(this._storage);

  /// Kasa meta verisi (salt, KDF parametreleri, sarılmış DEK) için depo.
  ///
  /// GÜVENLİK KARARLARI:
  /// - iOS: `unlocked_this_device` → yalnızca cihaz kilidi açıkken okunur,
  ///   iCloud'a / yeni cihaza taşınmaz. `synchronizable: false`.
  /// - Android: Keystore ile sarılmış AES-GCM. `resetOnError: false` →
  ///   bir hata olduğunda kasa anahtarlarını SESSİZCE SİLMEZ; hata
  ///   kullanıcıya gösterilir.
  factory FlutterSecureKeyValueStore.vault() => FlutterSecureKeyValueStore(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: false,
        storageNamespace: 'kilitdepo_vault',
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
        synchronizable: false,
        accountName: 'com.iylabs.kilitdepo.vault',
      ),
    ),
  );

  /// Biyometrik giriş için DEK kopyasının tutulduğu depo.
  ///
  /// GÜVENLİK KARARLARI (donanım destekli biyometrik bağlama):
  /// - Android (API 28+): Keystore anahtarı `setUserAuthenticationRequired`
  ///   ile üretilir; yalnızca güçlü (Class 3) biyometri kabul edilir ve
  ///   HER okuma/yazma için yeniden doğrulama istenir.
  /// - iOS: Keychain öğesi `biometryCurrentSet` erişim kontrolüyle saklanır;
  ///   yeni bir parmak izi / yüz eklenirse öğe geçersiz olur.
  ///   `passcode` erişilebilirliği: cihazda şifre yoksa öğe oluşturulamaz.
  factory FlutterSecureKeyValueStore.biometric({
    required String promptTitle,
    required String promptSubtitle,
    required String promptCancel,
  }) => FlutterSecureKeyValueStore(
    FlutterSecureStorage(
      aOptions: AndroidOptions.biometric(
        enforceBiometrics: true,
        requireBiometricsPerOperation: true,
        biometricType: AndroidBiometricType.strongBiometricOnly,
        resetOnError: false,
        storageNamespace: 'kilitdepo_bio',
        biometricPromptTitle: promptTitle,
        biometricPromptSubtitle: promptSubtitle,
        biometricPromptNegativeButton: promptCancel,
      ),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.passcode,
        synchronizable: false,
        accountName: 'com.iylabs.kilitdepo.biometric',
        accessControlFlags: [AccessControlFlag.biometryCurrentSet],
      ),
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
