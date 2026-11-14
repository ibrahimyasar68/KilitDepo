import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/constants/crypto_params.dart';
import 'package:kilitdepo/core/crypto/crypto_exceptions.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/core/crypto/kdf_params.dart';

import '../../helpers/in_memory_store.dart';

void main() {
  late CryptoService crypto;

  setUp(() => crypto = CryptoService());

  group('Sabitler', () {
    test('varsayılan Argon2id parametreleri gereksinimle aynı', () {
      expect(CryptoParams.defaultKdf.memoryKiB, 32 * 1024);
      expect(CryptoParams.defaultKdf.iterations, 6);
      expect(CryptoParams.defaultKdf.parallelism, 4);
      expect(CryptoParams.defaultKdf.hashLength, 32);
      expect(CryptoParams.saltLength, 16);
      expect(CryptoParams.dekLength, 32);
    });
  });

  group('Rastgelelik', () {
    test('salt 16 byte ve her seferinde farklı', () {
      final a = crypto.generateSalt();
      final b = crypto.generateSalt();
      expect(a, hasLength(16));
      expect(a, isNot(equals(b)));
    });

    test('DEK 256 bit ve her seferinde farklı', () {
      final a = crypto.generateDek();
      final b = crypto.generateDek();
      expect(a.bytes, hasLength(32));
      expect(a.bytes, isNot(equals(b.bytes)));
    });
  });

  group('Argon2id', () {
    // RFC 9106 §5.3 resmi Argon2id test vektörü: kullandığımız kütüphanenin
    // standarda uygun çıktı ürettiğini doğrular.
    test('RFC 9106 test vektörü', () async {
      final algorithm = Argon2id(
        memory: 32,
        iterations: 3,
        parallelism: 4,
        hashLength: 32,
      );
      final key = await algorithm.deriveKey(
        secretKey: SecretKeyData(List.filled(32, 0x01)),
        nonce: List.filled(16, 0x02),
        optionalSecret: List.filled(8, 0x03),
        associatedData: List.filled(12, 0x04),
      );
      final hex = (await key.extractBytes())
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(
        hex,
        '0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659',
      );
    });

    test('aynı şifre + salt aynı anahtarı üretir', () async {
      final salt = crypto.generateSalt();
      final a = await crypto.deriveKek(
        password: 'doğru-at-pil-zımba',
        salt: salt,
        params: fastTestKdf,
      );
      final b = await crypto.deriveKek(
        password: 'doğru-at-pil-zımba',
        salt: salt,
        params: fastTestKdf,
      );
      expect(a.bytes, equals(b.bytes));
      expect(a.bytes, hasLength(32));
    });

    test('farklı salt farklı anahtar üretir', () async {
      final a = await crypto.deriveKek(
        password: 'aynı-şifre-123',
        salt: crypto.generateSalt(),
        params: fastTestKdf,
      );
      final b = await crypto.deriveKek(
        password: 'aynı-şifre-123',
        salt: crypto.generateSalt(),
        params: fastTestKdf,
      );
      expect(a.bytes, isNot(equals(b.bytes)));
    });

    test('farklı şifre farklı anahtar üretir', () async {
      final salt = crypto.generateSalt();
      final a = await crypto.deriveKek(
        password: 'şifre-bir-1234',
        salt: salt,
        params: fastTestKdf,
      );
      final b = await crypto.deriveKek(
        password: 'şifre-iki-1234',
        salt: salt,
        params: fastTestKdf,
      );
      expect(a.bytes, isNot(equals(b.bytes)));
    });

    test('kısa salt reddedilir', () {
      expect(
        () => crypto.deriveKek(
          password: 'x',
          salt: Uint8List(8),
          params: fastTestKdf,
        ),
        throwsArgumentError,
      );
    });
  });

  group('AES-256-GCM şifrele/çöz', () {
    test('şifrele → çöz aynı veriyi verir', () async {
      final key = crypto.generateDek();
      final clear = utf8.encode('Gizli şifre: Ğ€ü 🔐');
      final env = await crypto.encrypt(clear, key: key);
      expect(await crypto.decrypt(env, key: key), equals(clear));
    });

    test('zarf biçimi: sürüm + nonce + metin + etiket', () async {
      final key = crypto.generateDek();
      final env = await crypto.encrypt(List.filled(10, 7), key: key);
      expect(env[0], CryptoParams.envelopeVersion);
      expect(env.length, 1 + 12 + 10 + 16);
    });

    test(
      'aynı veri iki kez şifrelenince farklı çıktı (rastgele nonce)',
      () async {
        final key = crypto.generateDek();
        final a = await crypto.encrypt([1, 2, 3], key: key);
        final b = await crypto.encrypt([1, 2, 3], key: key);
        expect(a, isNot(equals(b)));
      },
    );

    test('boş veri şifrelenip çözülebilir', () async {
      final key = crypto.generateDek();
      final env = await crypto.encrypt(const [], key: key);
      expect(await crypto.decrypt(env, key: key), isEmpty);
    });

    test('yanlış anahtar → DecryptionFailedException', () async {
      final env = await crypto.encrypt([1, 2, 3], key: crypto.generateDek());
      expect(
        () => crypto.decrypt(env, key: crypto.generateDek()),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('şifreli metinde tek bit değişikliği → hata', () async {
      final key = crypto.generateDek();
      final env = await crypto.encrypt(utf8.encode('merhaba dünya'), key: key);
      final tampered = Uint8List.fromList(env)..[15] ^= 0x01;
      expect(
        () => crypto.decrypt(tampered, key: key),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('etikette değişiklik → hata', () async {
      final key = crypto.generateDek();
      final env = await crypto.encrypt([9, 9, 9], key: key);
      final tampered = Uint8List.fromList(env)..[env.length - 1] ^= 0x80;
      expect(
        () => crypto.decrypt(tampered, key: key),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('nonce değişikliği → hata', () async {
      final key = crypto.generateDek();
      final env = await crypto.encrypt([9, 9, 9], key: key);
      final tampered = Uint8List.fromList(env)..[1] ^= 0x01;
      expect(
        () => crypto.decrypt(tampered, key: key),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('farklı AAD → hata', () async {
      final key = crypto.generateDek();
      final env = await crypto.encrypt(
        [1],
        key: key,
        associatedData: utf8.encode('kayıt:1'),
      );
      expect(
        () => crypto.decrypt(
          env,
          key: key,
          associatedData: utf8.encode('kayıt:2'),
        ),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('kesilmiş veri → MalformedCiphertextException', () async {
      final key = crypto.generateDek();
      expect(
        () => crypto.decrypt(Uint8List(10), key: key),
        throwsA(isA<MalformedCiphertextException>()),
      );
    });

    test('bilinmeyen sürüm → MalformedCiphertextException', () async {
      final key = crypto.generateDek();
      final env = await crypto.encrypt([1, 2], key: key);
      final bad = Uint8List.fromList(env)..[0] = 99;
      expect(
        () => crypto.decrypt(bad, key: key),
        throwsA(isA<MalformedCiphertextException>()),
      );
    });

    test('encryptString / decryptString', () async {
      final key = crypto.generateDek();
      final enc = await crypto.encryptString('P@ssw0rd-ışık', key: key);
      expect(enc, isNot(contains('P@ssw0rd')));
      expect(await crypto.decryptString(enc, key: key), 'P@ssw0rd-ışık');
    });

    test('geçersiz base64 → MalformedCiphertextException', () {
      expect(
        () => crypto.decryptString('***', key: crypto.generateDek()),
        throwsA(isA<MalformedCiphertextException>()),
      );
    });
  });

  group('DEK sarma / açma', () {
    Future<SecretKeyData> kek(String pw, Uint8List salt) =>
        crypto.deriveKek(password: pw, salt: salt, params: fastTestKdf);

    test('sar → aç aynı DEK\'i verir', () async {
      final salt = crypto.generateSalt();
      final dek = crypto.generateDek();
      final k = await kek('ana-şifre-12345', salt);
      final wrapped = await crypto.wrapDek(dek: dek, kek: k);
      expect(wrapped, isNot(containsAllInOrder(dek.bytes)));
      final opened = await crypto.unwrapDek(wrappedDek: wrapped, kek: k);
      expect(opened.bytes, equals(dek.bytes));
    });

    test('yanlış ana şifre → DecryptionFailedException', () async {
      final salt = crypto.generateSalt();
      final dek = crypto.generateDek();
      final wrapped = await crypto.wrapDek(
        dek: dek,
        kek: await kek('doğru-şifre-123', salt),
      );
      expect(
        () async => crypto.unwrapDek(
          wrappedDek: wrapped,
          kek: await kek('yanlış-şifre-123', salt),
        ),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('AAD (KDF parametreleri) değişirse açılamaz', () async {
      final k = await kek('ana-şifre-12345', crypto.generateSalt());
      final wrapped = await crypto.wrapDek(
        dek: crypto.generateDek(),
        kek: k,
        associatedData: utf8.encode(CryptoParams.defaultKdf.canonical),
      );
      const weaker = KdfParams(
        memoryKiB: 8,
        iterations: 1,
        parallelism: 1,
        hashLength: 32,
      );
      expect(
        () => crypto.unwrapDek(
          wrappedDek: wrapped,
          kek: k,
          associatedData: utf8.encode(weaker.canonical),
        ),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('sarılmış DEK bozulursa açılamaz', () async {
      final k = await kek('ana-şifre-12345', crypto.generateSalt());
      final wrapped = await crypto.wrapDek(dek: crypto.generateDek(), kek: k);
      final tampered = Uint8List.fromList(wrapped)..[20] ^= 0xFF;
      expect(
        () => crypto.unwrapDek(wrappedDek: tampered, kek: k),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('sarma bağlamı genel şifrelemeden ayrıdır', () async {
      // DEK zarfı, normal decrypt ile (bağlam AAD'si olmadan) açılamamalı.
      final k = await kek('ana-şifre-12345', crypto.generateSalt());
      final wrapped = await crypto.wrapDek(dek: crypto.generateDek(), kek: k);
      expect(
        () => crypto.decrypt(wrapped, key: k),
        throwsA(isA<DecryptionFailedException>()),
      );
    });
  });

  group('HKDF alt anahtarları', () {
    test('deterministik, birbirinden ve DEK\'ten farklı', () async {
      final dek = crypto.generateDek();
      final a = await crypto.deriveSubkeys(dek);
      final b = await crypto.deriveSubkeys(dek);
      expect(a.databaseKey.bytes, equals(b.databaseKey.bytes));
      expect(a.fieldKey.bytes, equals(b.fieldKey.bytes));
      expect(a.databaseKey.bytes, isNot(equals(a.fieldKey.bytes)));
      expect(a.databaseKey.bytes, isNot(equals(dek.bytes)));
      expect(a.databaseKey.bytes, hasLength(32));
    });

    test('destroy sonrası anahtara erişilemez', () async {
      final keys = await crypto.deriveSubkeys(crypto.generateDek());
      keys.destroy();
      expect(() => keys.fieldKey.bytes, throwsStateError);
    });
  });
}
