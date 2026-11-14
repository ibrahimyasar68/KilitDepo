import 'dart:convert';
import 'dart:typed_data';

import '../../core/crypto/kdf_params.dart';

/// Güvenli depoda saklanan kasa meta verisi.
///
/// İçerik: biçim sürümü, KDF parametreleri, salt ve sarılmış DEK.
/// Hiçbiri tek başına gizli değildir; DEK yalnızca doğru ana şifreyle
/// türetilen anahtarla açılabilir. Ana şifre burada YOKTUR.
class VaultKeyMetadata {
  const VaultKeyMetadata({
    required this.version,
    required this.kdf,
    required this.salt,
    required this.wrappedDek,
  });

  factory VaultKeyMetadata.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return VaultKeyMetadata(
      version: json['v'] as int,
      kdf: KdfParams.fromJson(json['kdf'] as Map<String, dynamic>),
      salt: base64Decode(json['salt'] as String),
      wrappedDek: base64Decode(json['dek'] as String),
    );
  }

  static const int currentVersion = 1;

  final int version;
  final KdfParams kdf;
  final Uint8List salt;
  final Uint8List wrappedDek;

  String encode() => jsonEncode({
    'v': version,
    'kdf': kdf.toJson(),
    'salt': base64Encode(salt),
    'dek': base64Encode(wrappedDek),
  });

  /// DEK sarmada AAD: sürüm + KDF parametreleri + salt.
  /// Bu alanlardan biri depoda değiştirilirse DEK açılamaz.
  List<int> get associatedData =>
      utf8.encode('v=$version;${kdf.canonical};salt=${base64Encode(salt)}');
}
