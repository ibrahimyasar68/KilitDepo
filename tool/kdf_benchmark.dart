// Üretim Argon2id parametreleriyle süre ölçümü (geliştirme aracı).
// Çalıştırma: dart run tool/kdf_benchmark.dart
import 'package:kilitdepo/core/constants/crypto_params.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';

Future<void> main() async {
  final crypto = CryptoService();
  for (var i = 0; i < 3; i++) {
    final sw = Stopwatch()..start();
    await crypto.deriveKek(
      password: 'ölçüm-şifresi-123',
      salt: crypto.generateSalt(),
      params: CryptoParams.defaultKdf,
    );
    // ignore: avoid_print
    print('Argon2id (32 MiB, t=6, p=4): ${sw.elapsedMilliseconds} ms');
  }
}
