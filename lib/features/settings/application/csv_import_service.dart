import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/import/csv_import.dart';
import '../../../domain/entities/password_entry.dart';
import '../../../domain/repositories/vault_repository.dart';

/// CSV dosyasını seçip okuyan ve dosya seçicinin bıraktığı GEÇİCİ KOPYAYI
/// her durumda silen katman.
///
/// GÜVENLİK: file_picker seçilen dosyanın bir kopyasını uygulamanın geçici
/// klasörüne yazar (Android: önbellek/file_picker, iOS: tmp). Şifreli
/// yedekte sorun değildir; düz metin CSV'de bu kopya bırakılmamalıdır.
/// Kullanıcının ORİJİNAL dosyasına asla dokunulmaz: yalnızca geçici
/// klasördeki kopya silinir.
class CsvFileReader {
  CsvFileReader({
    required this.pick,
    required this.deleteFile,
    required this.clearTemporaryFiles,
    required this.tempRoots,
  });

  /// Dosya seçici: (yol, okuyucu, boyut) ya da iptalde null.
  final Future<PickedCsv?> Function() pick;
  final Future<void> Function(String path) deleteFile;
  final Future<void> Function() clearTemporaryFiles;

  /// Silinmesine izin verilen geçici klasör kökleri.
  final List<String> tempRoots;

  /// [path] dosya seçicinin geçici kopyası mı? (Kullanıcının kendi dosyası
  /// asla silinmesin diye yalnızca bu durumda silinir.)
  bool isTemporaryCopy(String path) =>
      path.contains('/file_picker/') ||
      tempRoots.any((root) => root.isNotEmpty && path.startsWith(root));

  /// Dosyayı seçtirir ve baytlarını döndürür; iptalde null. Ne olursa
  /// olsun (hata dahil) geçici kopya silinir.
  Future<Uint8List?> read() async {
    PickedCsv? file;
    try {
      file = await pick();
      if (file == null) return null;
      if (file.size > CsvImporter.maxBytes) {
        throw const CsvImportException(CsvImportError.tooLarge);
      }
      return await file.readBytes();
    } finally {
      final path = file?.path;
      if (path != null && isTemporaryCopy(path)) {
        try {
          await deleteFile(path);
        } on Object {
          // Silinemezse aşağıdaki genel temizlik dener.
        }
      }
      try {
        await clearTemporaryFiles();
      } on Object {
        // En iyi çaba.
      }
    }
  }

  /// Gerçek dosya seçiciyle.
  factory CsvFileReader.platform() => CsvFileReader(
    pick: () async {
      final f = await FilePicker.pickFile();
      if (f == null) return null;
      return PickedCsv(
        path: f.path,
        size: await f.length() ?? (CsvImporter.maxBytes + 1),
        readBytes: f.readAsBytes,
      );
    },
    deleteFile: (path) async {
      final file = File(path);
      if (await file.exists()) await file.delete();
    },
    clearTemporaryFiles: FilePicker.clearTemporaryFiles,
    tempRoots: [Directory.systemTemp.path],
  );
}

@immutable
class PickedCsv {
  const PickedCsv({
    required this.path,
    required this.size,
    required this.readBytes,
  });

  final String? path;
  final int size;
  final Future<Uint8List> Function() readBytes;
}

final csvFileReaderProvider = Provider<CsvFileReader>(
  (ref) => CsvFileReader.platform(),
);

/// Önizleme: eklenecekler ve atlananlar.
@immutable
class CsvImportPreview {
  const CsvImportPreview({
    required this.format,
    required this.toAdd,
    required this.duplicates,
    required this.skippedNoPassword,
    required this.totpDropped,
  });

  final CsvImportFormat format;
  final List<CsvImportCandidate> toAdd;

  /// Kasada (veya dosyada daha önce) birebir aynısı olduğu için atlananlar.
  final int duplicates;
  final int skippedNoPassword;
  final int totpDropped;
}

/// Tekrar kontrolü ve toplu ekleme.
class CsvImportService {
  const CsvImportService(this._repo);

  final VaultRepository _repo;

  static String _key(String title, String username, String? url, String pw) =>
      [title.trim(), username.trim(), (url ?? '').trim(), pw].join('\u0000');

  /// Başlık, kullanıcı adı, adres ve şifresi birebir aynı olan kayıtlar
  /// (kasada ya da dosyanın kendi içinde) atlanır. Hiçbir şey yazılmaz.
  /// Kasadaki şifreler yalnızca bu karşılaştırma için kısa süre çözülür.
  Future<CsvImportPreview> preview(CsvImportParse parsed) async {
    final summaries = await _repo.watchEntries().first;
    final passwords = {
      for (final p in await _repo.revealAllPasswords()) p.id: p.password,
    };
    final seen = <String>{
      for (final s in summaries)
        _key(s.title, s.username, s.url, passwords[s.id] ?? ''),
    };
    passwords.clear();

    final toAdd = <CsvImportCandidate>[];
    var duplicates = 0;
    for (final c in parsed.candidates) {
      if (seen.add(_key(c.title, c.username, c.url, c.password))) {
        toAdd.add(c);
      } else {
        duplicates++;
      }
    }
    seen.clear();
    return CsvImportPreview(
      format: parsed.format,
      toAdd: toAdd,
      duplicates: duplicates,
      skippedNoPassword: parsed.skippedNoPassword,
      totpDropped: parsed.totpDropped,
    );
  }

  /// Önizlemedeki kayıtları tek işlemde ekler (kategori: Diğer).
  Future<int> commit(List<CsvImportCandidate> candidates) => _repo.addEntries([
    for (final c in candidates)
      EntryDraft(
        title: c.title,
        username: c.username,
        password: c.password,
        url: c.url,
        notes: c.notes,
        isFavorite: c.isFavorite,
      ),
  ]);
}
