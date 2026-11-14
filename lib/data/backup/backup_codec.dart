import 'dart:convert';
import 'dart:typed_data';

import '../../core/constants/app_info.dart';
import '../../core/constants/crypto_params.dart';
import '../../core/crypto/crypto_exceptions.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/crypto/kdf_params.dart';
import '../../domain/entities/backup_entry.dart';
import '../../domain/entities/entry_category.dart';

/// Yedek şifresi yanlış veya dosya (başlık dahil) değiştirilmiş.
class BackupWrongPasswordException implements Exception {
  const BackupWrongPasswordException();
}

/// Dosya geçerli bir KilitDepo yedeği değil.
class BackupFormatException implements Exception {
  const BackupFormatException(this.reason);
  final String reason;
}

/// KilitDepo yedek dosyası biçimi (UTF-8 JSON):
///
/// ```
/// {
///   "format": "kilitdepo-backup",
///   "v": 1,
///   "kdf": { "alg": "argon2id", "m": 65536, "t": 6, "p": 4, "l": 32 },
///   "salt": "<base64, 16 byte>",
///   "data": "<base64 zarf: sürüm | nonce | şifreli metin | GCM etiketi>"
/// }
/// ```
///
/// GÜVENLİK:
/// - Anahtar: Argon2id(yedek şifresi, rastgele salt) — ana şifreden ve
///   kasa anahtarından TAMAMEN bağımsız.
/// - Şifreleme: AES-256-GCM. Başlık (biçim, sürüm, KDF, salt) AAD olarak
///   doğrulanır; değiştirilirse dosya açılmaz.
/// - Düz metin olarak YALNIZCA başlık bulunur; başlık/kullanıcı adı dahil
///   hiçbir kayıt bilgisi açıkta değildir.
class BackupCodec {
  BackupCodec(this._crypto, {this._kdf = CryptoParams.backupKdf});

  static const String formatName = 'kilitdepo-backup';
  static const int version = 1;
  static const String fileExtension = 'kilitdepo';

  final CryptoService _crypto;
  final KdfParams _kdf;

  Future<Uint8List> encode(
    List<BackupEntry> entries,
    String backupPassword, {
    DateTime? now,
  }) async {
    if (backupPassword.length < CryptoParams.minBackupPasswordLength) {
      throw ArgumentError('Yedek şifresi çok kısa.');
    }
    final salt = _crypto.generateSalt();
    final key = await _crypto.deriveKek(
      password: backupPassword,
      salt: salt,
      params: _kdf,
    );
    try {
      final payload = utf8.encode(
        jsonEncode({
          'app': AppInfo.appName,
          'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
          'entries': [for (final e in entries) _entryToJson(e)],
        }),
      );
      final data = await _crypto.encrypt(
        payload,
        key: key,
        associatedData: _aad(_kdf, salt),
      );
      // En iyi çaba: düz metin tamponunu sıfırla.
      payload.fillRange(0, payload.length, 0);
      return Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'format': formatName,
            'v': version,
            'kdf': _kdf.toJson(),
            'salt': base64Encode(salt),
            'data': base64Encode(data),
          }),
        ),
      );
    } finally {
      key.destroy();
    }
  }

  Future<List<BackupEntry>> decode(
    Uint8List file,
    String backupPassword,
  ) async {
    final KdfParams kdf;
    final Uint8List salt;
    final Uint8List data;
    try {
      final header = jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
      if (header['format'] != formatName) {
        throw const BackupFormatException('biçim');
      }
      if (header['v'] != version) throw const BackupFormatException('sürüm');
      final kdfJson = header['kdf'] as Map<String, dynamic>;
      if (kdfJson['alg'] != 'argon2id') {
        throw const BackupFormatException('kdf');
      }
      kdf = KdfParams.fromJson(kdfJson);
      salt = base64Decode(header['salt'] as String);
      data = base64Decode(header['data'] as String);
    } on BackupFormatException {
      rethrow;
    } on Object {
      throw const BackupFormatException('okunamadı');
    }
    _checkKdfBounds(kdf);
    if (salt.length < CryptoParams.saltLength) {
      throw const BackupFormatException('salt');
    }

    final key = await _crypto.deriveKek(
      password: backupPassword,
      salt: salt,
      params: kdf,
    );
    final Uint8List clear;
    try {
      clear = await _crypto.decrypt(
        data,
        key: key,
        associatedData: _aad(kdf, salt),
      );
    } on DecryptionFailedException {
      throw const BackupWrongPasswordException();
    } on MalformedCiphertextException {
      throw const BackupFormatException('veri');
    } finally {
      key.destroy();
    }

    try {
      final payload = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      return [
        for (final e in payload['entries'] as List<dynamic>)
          _entryFromJson(e as Map<String, dynamic>),
      ];
    } on BackupFormatException {
      rethrow;
    } on Object {
      throw const BackupFormatException('içerik');
    } finally {
      clear.fillRange(0, clear.length, 0);
    }
  }

  /// Önerilen dosya adı: kilitdepo-yedek-2026-11-09.kilitdepo
  static String suggestedFileName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'kilitdepo-yedek-${now.year}-${two(now.month)}-${two(now.day)}'
        '.$fileExtension';
  }

  List<int> _aad(KdfParams kdf, List<int> salt) => utf8.encode(
    '$formatName;v=$version;${kdf.canonical};salt=${base64Encode(salt)}',
  );

  /// Kötü niyetli bir dosyanın aşırı bellek/süre isteyerek uygulamayı
  /// kilitlemesini önler (ör. m = 4 GB).
  void _checkKdfBounds(KdfParams k) {
    final ok =
        k.memoryKiB >= 8 &&
        k.memoryKiB <= 256 * 1024 &&
        k.iterations >= 1 &&
        k.iterations <= 20 &&
        k.parallelism >= 1 &&
        k.parallelism <= 16 &&
        k.hashLength == 32;
    if (!ok) throw const BackupFormatException('kdf sınırları');
  }

  Map<String, dynamic> _entryToJson(BackupEntry e) => {
    'uuid': e.uuid,
    'title': e.title,
    'username': e.username,
    'password': e.password,
    'url': e.url,
    'notes': e.notes,
    'category': e.category.key,
    'favorite': e.isFavorite,
    // İsteğe bağlı görünüm alanları (sürüm değişmez; eski yedeklerde yok,
    // eski uygulama sürümleri bu alanları yok sayar).
    if (e.iconKey != null) 'icon': e.iconKey,
    if (e.colorKey != null) 'color': e.colorKey,
    'createdAt': e.createdAt.toUtc().toIso8601String(),
    'updatedAt': e.updatedAt.toUtc().toIso8601String(),
    'history': [
      for (final h in e.history)
        {
          'password': h.password,
          'changedAt': h.changedAt.toUtc().toIso8601String(),
        },
    ],
  };

  BackupEntry _entryFromJson(Map<String, dynamic> j) {
    final uuid = j['uuid'] as String;
    final title = j['title'] as String;
    final password = j['password'] as String;
    if (uuid.isEmpty || uuid.length > 64 || title.trim().isEmpty) {
      throw const BackupFormatException('kayıt');
    }
    if (password.isEmpty) throw const BackupFormatException('kayıt');
    return BackupEntry(
      uuid: uuid,
      title: title,
      username: (j['username'] as String?) ?? '',
      password: password,
      url: j['url'] as String?,
      notes: j['notes'] as String?,
      category: EntryCategory.fromKey((j['category'] as String?) ?? ''),
      isFavorite: (j['favorite'] as bool?) ?? false,
      iconKey: j['icon'] is String ? j['icon'] as String : null,
      colorKey: j['color'] is String ? j['color'] as String : null,
      createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(j['updatedAt'] as String).toLocal(),
      history: [
        for (final h in (j['history'] as List<dynamic>? ?? const []))
          BackupHistoryItem(
            password: (h as Map<String, dynamic>)['password'] as String,
            changedAt: DateTime.parse(h['changedAt'] as String).toLocal(),
          ),
      ],
    );
  }
}
