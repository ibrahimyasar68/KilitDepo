import 'package:cryptography/cryptography.dart';

import '../core/crypto/crypto_service.dart';
import 'database/app_database.dart';

typedef VaultDatabaseOpener = Future<AppDatabase> Function(SecretKeyData key);

/// Açık kasa oturumu: DEK, alt anahtarlar ve şifreli veritabanı bağlantısı.
///
/// Tüm anahtarlar YALNIZCA bellekte ve yalnızca kasa açıkken bulunur.
/// [close] çağrıldığında veritabanı kapatılır ve anahtar byte'ları
/// sıfırlanır.
///
/// PLATFORM KISITI: Dart çöp toplayıcısı nesneleri taşıyıp kopya
/// bırakabileceği için sıfırlama "en iyi çaba"dır.
class VaultSession {
  VaultSession({required this._crypto, required this._openDatabase});

  final CryptoService _crypto;
  final VaultDatabaseOpener _openDatabase;

  SecretKeyData? _dek;
  VaultSubkeys? _subkeys;
  AppDatabase? _database;

  bool get isOpen => _database != null;

  SecretKeyData get dek => _require(_dek);
  SecretKeyData get fieldKey => _require(_subkeys?.fieldKey);
  AppDatabase get database => _require(_database);

  /// DEK'in sahipliğini alır, alt anahtarları türetir ve veritabanını açar.
  Future<void> open(SecretKeyData dek) async {
    await close();
    _dek = dek;
    try {
      final subkeys = await _crypto.deriveSubkeys(dek);
      _subkeys = subkeys;
      _database = await _openDatabase(subkeys.databaseKey);
      // Veritabanı anahtarı artık bağlantıda; bellekteki kopyayı sil.
      subkeys.databaseKey.destroy();
    } catch (_) {
      await close();
      rethrow;
    }
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    try {
      await db?.close();
    } finally {
      _subkeys?.destroy();
      _subkeys = null;
      _dek?.destroy();
      _dek = null;
    }
  }

  T _require<T>(T? value) {
    if (value == null) throw StateError('Kasa kilitli.');
    return value;
  }
}
