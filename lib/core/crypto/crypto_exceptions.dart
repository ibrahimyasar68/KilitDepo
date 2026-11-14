/// Kriptografi katmanının fırlattığı hatalar.
///
/// Hata mesajları hiçbir zaman anahtar, şifre veya düz metin içermez.
sealed class CryptoException implements Exception {
  const CryptoException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Kimlik doğrulama etiketi tutmadı: yanlış anahtar ya da bozulmuş veri.
/// AES-GCM bu iki durumu bilinçli olarak ayırt etmez.
class DecryptionFailedException extends CryptoException {
  const DecryptionFailedException()
    : super('Şifre çözme başarısız (yanlış anahtar veya bozulmuş veri).');
}

/// Veri biçimi tanınmıyor (çok kısa, bilinmeyen sürüm vb.).
class MalformedCiphertextException extends CryptoException {
  const MalformedCiphertextException(super.message);
}
