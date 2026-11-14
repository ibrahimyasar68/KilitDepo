import 'package:local_auth/local_auth.dart';

/// Cihazın biyometrik yeteneklerini sorgular.
///
/// NOT: Asıl güvenlik, DEK'in biyometriye bağlı donanım anahtarıyla
/// saklanmasından gelir (bkz. FlutterSecureKeyValueStore.biometric).
/// Burası yalnızca seçeneğin gösterilip gösterilmeyeceğine karar verir.
abstract interface class BiometricService {
  Future<bool> isAvailable();
}

class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final types = await _auth.getAvailableBiometrics();
      // Android'de yalnızca güçlü (Class 3) biyometri kabul ediyoruz.
      return types.contains(BiometricType.strong) ||
          types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.face);
    } on Exception {
      return false;
    }
  }
}
