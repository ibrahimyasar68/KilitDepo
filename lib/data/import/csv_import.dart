import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'csv_parser.dart';

/// Tanınan dışa aktarma biçimleri (yalnızca önizlemede gösterilir; eşleme
/// sütun adlarına göre yapılır).
enum CsvImportFormat {
  chrome,
  firefox,
  apple,
  bitwarden,
  onePassword,
  protonPass,
  keePass,
  generic,
}

/// İçe aktarılacak bir kayıt (düz metin; yalnızca işlem süresince bellekte).
@immutable
class CsvImportCandidate {
  const CsvImportCandidate({
    required this.title,
    required this.username,
    required this.password,
    this.url,
    this.notes,
    this.isFavorite = false,
  });

  final String title;
  final String username;
  final String password;
  final String? url;
  final String? notes;
  final bool isFavorite;
}

/// CSV'nin çözümlenmiş hâli.
@immutable
class CsvImportParse {
  const CsvImportParse({
    required this.format,
    required this.candidates,
    required this.skippedNoPassword,
    required this.totpDropped,
  });

  final CsvImportFormat format;
  final List<CsvImportCandidate> candidates;

  /// Şifresi boş olduğu için atlanan satırlar (ör. güvenli notlar, kartlar).
  final int skippedNoPassword;

  /// 2 adımlı doğrulama (TOTP) anahtarı içeren ve bu anahtarı AKTARILMAYAN
  /// satır sayısı.
  final int totpDropped;
}

enum CsvImportError { empty, encoding, tooLarge, missingColumns }

class CsvImportException implements Exception {
  const CsvImportException(this.reason);

  final CsvImportError reason;
}

/// Başka şifre yöneticilerinin / tarayıcıların CSV dışa aktarımlarını okur.
///
/// GÜVENLİK:
/// - Yalnızca bellekte çalışır; hiçbir şeyi diske yazmaz.
/// - TOTP gizli anahtarları bilinçli olarak aktarılmaz (şifreyle aynı yerde
///   saklanırsa iki adımlı doğrulamanın koruması zayıflar); sayısı bildirilir.
/// - Satır ve boyut sınırları kötü niyetli dev dosyalara karşıdır.
abstract final class CsvImporter {
  static const int maxBytes = 10 * 1024 * 1024;
  static const int maxRows = 10000;

  // Sütun adı eşanlamlıları (küçük harf, boşluklar tek).
  static const _title = {
    'title',
    'name',
    'başlık',
    'baslik',
    'ad',
    'site',
    'hesap',
    'account',
  };
  static const _username = {
    'username',
    'user',
    'login',
    'login_username',
    'kullanıcı adı',
    'kullanici adi',
    'kullanıcı',
    'kullanici',
    'user name',
  };
  static const _email = {'email', 'e-mail', 'e-posta', 'eposta'};
  static const _password = {
    'password',
    'login_password',
    'pass',
    'şifre',
    'sifre',
    'parola',
  };
  static const _url = {
    'url',
    'uri',
    'login_uri',
    'website',
    'web site',
    'web sitesi',
    'adres',
    'site url',
  };
  static const _notes = {
    'notes',
    'note',
    'notlar',
    'not',
    'açıklama',
    'aciklama',
    'comments',
  };
  static const _totp = {'totp', 'otpauth', 'login_totp', 'otp', 'otp auth'};
  static const _favorite = {'favorite', 'favourite', 'favori'};

  /// Bayt dizisini çözer (UTF-8; olmazsa Latin-1) ve çözümler.
  static CsvImportParse parseBytes(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const CsvImportException(CsvImportError.tooLarge);
    }
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      try {
        text = latin1.decode(bytes);
      } on FormatException {
        throw const CsvImportException(CsvImportError.encoding);
      }
    }
    return parse(text);
  }

  static CsvImportParse parse(String text) {
    final List<List<String>> rows;
    try {
      rows = CsvParser.parse(text, maxRows: maxRows + 1);
    } on CsvTooLargeException {
      throw const CsvImportException(CsvImportError.tooLarge);
    }
    if (rows.length < 2) throw const CsvImportException(CsvImportError.empty);

    final header = [
      for (final h in rows.first)
        h.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
    ];
    int? col(Set<String> names) {
      for (var i = 0; i < header.length; i++) {
        if (names.contains(header[i])) return i;
      }
      return null;
    }

    final cTitle = col(_title);
    final cUser = col(_username);
    final cEmail = col(_email);
    final cPass = col(_password);
    final cUrl = col(_url);
    final cNotes = col(_notes);
    final cTotp = col(_totp);
    final cFav = col(_favorite);

    // Şifre şart; başlık yoksa adresten (ör. Firefox) türetilir.
    if (cPass == null || (cTitle == null && cUrl == null)) {
      throw const CsvImportException(CsvImportError.missingColumns);
    }

    String cell(List<String> row, int? i) =>
        i == null || i >= row.length ? '' : row[i].trim();

    final candidates = <CsvImportCandidate>[];
    var skipped = 0;
    var totp = 0;
    for (final row in rows.skip(1)) {
      // Şifre boşluk dahil olduğu gibi alınır; yalnızca tamamen boşsa atlanır.
      final password = cPass < row.length ? row[cPass] : '';
      if (password.trim().isEmpty) {
        skipped++;
        continue;
      }
      if (cell(row, cTotp).isNotEmpty) totp++;
      final url = cell(row, cUrl);
      final username = cell(row, cUser).isNotEmpty
          ? cell(row, cUser)
          : cell(row, cEmail);
      var title = cell(row, cTitle);
      if (title.isEmpty) title = _hostOf(url) ?? '';
      if (title.isEmpty) title = username;
      if (title.isEmpty) title = '?';
      final notes = cell(row, cNotes);
      final fav = cell(row, cFav).toLowerCase();
      candidates.add(
        CsvImportCandidate(
          title: title,
          username: username,
          password: password,
          url: url.isEmpty ? null : url,
          notes: notes.isEmpty ? null : notes,
          isFavorite: const {'1', 'true', 'yes', 'evet', 'x'}.contains(fav),
        ),
      );
    }
    return CsvImportParse(
      format: detectFormat(header),
      candidates: candidates,
      skippedNoPassword: skipped,
      totpDropped: totp,
    );
  }

  /// Başlık satırına göre biçim tahmini (yalnızca bilgi amaçlı).
  static CsvImportFormat detectFormat(List<String> header) {
    final h = header.toSet();
    if (h.contains('login_password')) return CsvImportFormat.bitwarden;
    if (h.contains('httprealm') || h.contains('formactionorigin')) {
      return CsvImportFormat.firefox;
    }
    if (h.contains('group') && h.contains('last modified')) {
      return CsvImportFormat.keePass;
    }
    if (h.contains('vault') && h.contains('createtime')) {
      return CsvImportFormat.protonPass;
    }
    if (h.contains('archived') ||
        (h.contains('favorite') && h.contains('otpauth'))) {
      return CsvImportFormat.onePassword;
    }
    if (h.contains('otpauth') && h.contains('title')) {
      return CsvImportFormat.apple;
    }
    if (h.containsAll({'name', 'url', 'username', 'password'})) {
      return CsvImportFormat.chrome;
    }
    return CsvImportFormat.generic;
  }

  static String? _hostOf(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url.contains('://') ? url : 'https://$url');
    final host = uri?.host ?? '';
    if (host.isEmpty) return null;
    return host.startsWith('www.') ? host.substring(4) : host;
  }
}
