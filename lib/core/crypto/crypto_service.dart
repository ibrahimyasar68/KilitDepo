import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../constants/crypto_params.dart';
import 'crypto_exceptions.dart';
import 'kdf_params.dart';

/// DEK'ten türetilen, amaca özel alt anahtarlar.
class VaultSubkeys {
  const VaultSubkeys({required this.databaseKey, required this.fieldKey});

  /// SQLCipher veritabanı anahtarı.
  final SecretKeyData databaseKey;

  /// Alan düzeyinde (şifre, eski şifre) AES-GCM anahtarı.
  final SecretKeyData fieldKey;

  void destroy() {
    databaseKey.destroy();
    fieldKey.destroy();
  }
}

/// KilitDepo'nun tüm kriptografik işlemleri.
///
/// GÜVENLİK: Kendi algoritmamızı YAZMIYORUZ. Tüm ilkel işlemler
/// `package:cryptography` üzerinden yapılır; bu sınıf yalnızca onları
/// doğru parametrelerle bir araya getirir.
///
/// Şifreli veri biçimi ("zarf"):
///   [1 byte sürüm][12 byte nonce][şifreli metin][16 byte GCM etiketi]
/// Sürüm byte'ı AAD'ye de eklenir; böylece değiştirilemez.
class CryptoService {
  CryptoService({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  final AesGcm _aes = AesGcm.with256bits(
    nonceLength: CryptoParams.gcmNonceLength,
  );
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Kriptografik olarak güvenli rastgele byte'lar.
  Uint8List randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  /// RFC 4122 sürüm 4 (rastgele) UUID.
  String generateUuidV4() {
    final b = randomBytes(16);
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Yeni bir Argon2id salt'ı üretir.
  Uint8List generateSalt() => randomBytes(CryptoParams.saltLength);

  /// Yeni bir 256-bit veri anahtarı (DEK) üretir.
  SecretKeyData generateDek() =>
      SecretKeyData(randomBytes(CryptoParams.dekLength));

  /// Ana şifreden anahtar şifreleme anahtarı (KEK) türetir.
  ///
  /// Argon2id saf Dart ile çalıştığı için yavaştır; arayüzü dondurmamak
  /// için ayrı bir isolate'ta çalıştırılır.
  Future<SecretKeyData> deriveKek({
    required String password,
    required List<int> salt,
    required KdfParams params,
  }) async {
    if (salt.length < CryptoParams.saltLength) {
      throw ArgumentError('Salt en az ${CryptoParams.saltLength} byte olmalı.');
    }
    final saltCopy = Uint8List.fromList(salt);
    final bytes = await Isolate.run(
      () => _argon2idInIsolate(password, saltCopy, params),
      debugName: 'kdf',
    );
    return SecretKeyData(bytes);
  }

  /// DEK'i KEK ile AES-256-GCM kullanarak sarar.
  ///
  /// [associatedData] (ör. KDF parametreleri) şifrelenmez ama doğrulanır.
  Future<Uint8List> wrapDek({
    required SecretKey dek,
    required SecretKey kek,
    List<int> associatedData = const [],
  }) async {
    final dekBytes = await dek.extractBytes();
    return encrypt(
      dekBytes,
      key: kek,
      associatedData: _wrapAad(associatedData),
    );
  }

  /// Sarılmış DEK'i açar. Yanlış KEK (yanlış ana şifre) veya bozulmuş
  /// veride [DecryptionFailedException] fırlatır.
  Future<SecretKeyData> unwrapDek({
    required List<int> wrappedDek,
    required SecretKey kek,
    List<int> associatedData = const [],
  }) async {
    final bytes = await decrypt(
      wrappedDek,
      key: kek,
      associatedData: _wrapAad(associatedData),
    );
    if (bytes.length != CryptoParams.dekLength) {
      throw const MalformedCiphertextException('DEK uzunluğu geçersiz.');
    }
    return SecretKeyData(bytes);
  }

  /// DEK'ten HKDF-SHA256 ile amaca özel alt anahtarlar türetir.
  Future<VaultSubkeys> deriveSubkeys(SecretKey dek) async {
    Future<SecretKeyData> derive(String info) async {
      final key = await _hkdf.deriveKey(
        secretKey: dek,
        nonce: const <int>[],
        info: utf8.encode(info),
      );
      return SecretKeyData(await key.extractBytes());
    }

    return VaultSubkeys(
      databaseKey: await derive(CryptoParams.hkdfDatabaseInfo),
      fieldKey: await derive(CryptoParams.hkdfFieldInfo),
    );
  }

  /// AES-256-GCM ile şifreler. Her çağrıda yeni rastgele nonce kullanılır.
  Future<Uint8List> encrypt(
    List<int> plaintext, {
    required SecretKey key,
    List<int> associatedData = const [],
  }) async {
    final nonce = randomBytes(CryptoParams.gcmNonceLength);
    final box = await _aes.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
      aad: _envelopeAad(associatedData),
    );
    final out = BytesBuilder(copy: false)
      ..addByte(CryptoParams.envelopeVersion)
      ..add(box.nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return out.toBytes();
  }

  /// [encrypt] ile üretilmiş zarfı çözer.
  Future<Uint8List> decrypt(
    List<int> envelope, {
    required SecretKey key,
    List<int> associatedData = const [],
  }) async {
    const header = 1 + CryptoParams.gcmNonceLength;
    if (envelope.length < header + CryptoParams.gcmMacLength) {
      throw const MalformedCiphertextException('Şifreli veri çok kısa.');
    }
    if (envelope[0] != CryptoParams.envelopeVersion) {
      throw const MalformedCiphertextException('Bilinmeyen biçim sürümü.');
    }
    final macStart = envelope.length - CryptoParams.gcmMacLength;
    final box = SecretBox(
      envelope.sublist(header, macStart),
      nonce: envelope.sublist(1, header),
      mac: Mac(envelope.sublist(macStart)),
    );
    try {
      final clear = await _aes.decrypt(
        box,
        secretKey: key,
        aad: _envelopeAad(associatedData),
      );
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw const DecryptionFailedException();
    }
  }

  /// Metni şifreleyip base64 olarak döndürür (veritabanı alanları için).
  Future<String> encryptString(
    String plaintext, {
    required SecretKey key,
    List<int> associatedData = const [],
  }) async => base64Encode(
    await encrypt(
      utf8.encode(plaintext),
      key: key,
      associatedData: associatedData,
    ),
  );

  /// [encryptString] çıktısını çözer.
  Future<String> decryptString(
    String encoded, {
    required SecretKey key,
    List<int> associatedData = const [],
  }) async {
    final Uint8List bytes;
    try {
      bytes = base64Decode(encoded);
    } on FormatException {
      throw const MalformedCiphertextException('Geçersiz base64.');
    }
    return utf8.decode(
      await decrypt(bytes, key: key, associatedData: associatedData),
    );
  }

  List<int> _envelopeAad(List<int> associatedData) => [
    CryptoParams.envelopeVersion,
    ...associatedData,
  ];

  List<int> _wrapAad(List<int> associatedData) => [
    ...utf8.encode(CryptoParams.dekWrapContext),
    0,
    ...associatedData,
  ];
}

/// Isolate içinde çalışan Argon2id. Üst düzey fonksiyon olmalı.
///
/// NOT: Ana şifre UTF-8'e çevrilir. Dart'ta Unicode normalizasyonu
/// (NFC) yerleşik olmadığından uygulanmaz; Türkçe klavyeler bileşik
/// karakter üretmediği için pratikte sorun beklenmez.
Future<Uint8List> _argon2idInIsolate(
  String password,
  Uint8List salt,
  KdfParams params,
) async {
  final algorithm = Argon2id(
    memory: params.memoryKiB,
    iterations: params.iterations,
    parallelism: params.parallelism,
    hashLength: params.hashLength,
  );
  final passwordBytes = Uint8List.fromList(utf8.encode(password));
  try {
    final key = await algorithm.deriveKey(
      secretKey: SecretKeyData(passwordBytes),
      nonce: salt,
    );
    return Uint8List.fromList(await key.extractBytes());
  } finally {
    // En iyi çaba: şifre byte'larını bellekte sıfırla.
    passwordBytes.fillRange(0, passwordBytes.length, 0);
  }
}
