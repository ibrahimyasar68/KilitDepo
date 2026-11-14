import 'package:kilitdepo/core/crypto/kdf_params.dart';
import 'package:kilitdepo/core/storage/secure_key_value_store.dart';

/// Testler için bellek içi güvenli depo.
class InMemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> data = {};

  /// true ise okuma işlemi hata fırlatır (ör. biyometri iptali).
  bool failReads = false;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw Exception('okuma başarısız');
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// Testleri hızlandırmak için düşük maliyetli Argon2id parametreleri.
/// ÜRETİMDE KULLANILMAZ.
const KdfParams fastTestKdf = KdfParams(
  memoryKiB: 64,
  iterations: 1,
  parallelism: 1,
  hashLength: 32,
);
