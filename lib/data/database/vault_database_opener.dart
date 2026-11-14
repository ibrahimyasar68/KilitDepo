import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// SQLCipher yüklenmemiş (veritabanı şifresiz açılacaktı).
class SqlCipherUnavailableException implements Exception {
  const SqlCipherUnavailableException();
}

/// Kasa veritabanı dosyasının adı.
const String vaultDatabaseFileName = 'kilitdepo.db';

/// Uygulamanın kasa veritabanını açar.
///
/// Dosya Application Support klasöründedir (iOS'ta Dosyalar uygulamasında
/// görünmez; Android'de uygulamaya özel alandadır).
Future<AppDatabase> openVaultDatabase(SecretKeyData databaseKey) async =>
    openVaultDatabaseFile(await vaultDatabaseFile(), databaseKey);

/// Kasa veritabanı dosyasının konumu.
Future<File> vaultDatabaseFile() async {
  final dir = await getApplicationSupportDirectory();
  return File('${dir.path}${Platform.pathSeparator}$vaultDatabaseFileName');
}

/// Kasa veritabanı dosyası var mı?
Future<bool> vaultDatabaseExists() async =>
    (await vaultDatabaseFile()).exists();

/// Kasa veritabanını ve SQLite yan dosyalarını (-wal, -shm, -journal)
/// siler. YALNIZCA anahtarı olmayan (açılamayan) bir dosyayı temizlemek
/// için kullanılır: yeni kasa oluşturulurken veya oluşturma yarıda kalınca.
Future<void> deleteVaultDatabaseFiles() async {
  final file = await vaultDatabaseFile();
  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final f = File('${file.path}$suffix');
    if (f.existsSync()) await f.delete();
  }
}

/// Verilen dosyayı SQLCipher ile açar.
///
/// GÜVENLİK KARARLARI:
/// - Anahtar ham 256-bit olarak verilir (`x'..'`): DEK'ten HKDF ile
///   türetilmiş güçlü bir anahtar olduğu için SQLCipher'ın kendi PBKDF2
///   adımı atlanır.
/// - `cipher_version` boşsa SQLCipher yüklenmemiştir: veritabanını
///   ŞİFRESİZ açmak yerine hata fırlatılır (fail closed).
/// - Yanlış anahtarda ilk okuma hata verir; sessizce boş veritabanı
///   oluşturulmaz.
/// - `secure_delete`: silinen veriler dosyada sıfırlarla ezilir.
///
/// PLATFORM KISITI: Anahtarın hex hâli değiştirilemez bir Dart String'i
/// olarak kısa süre bellekte bulunur ve sıfırlanamaz.
Future<AppDatabase> openVaultDatabaseFile(
  File file,
  SecretKeyData databaseKey,
) async {
  final hexKey = databaseKey.bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  final executor = NativeDatabase.createInBackground(
    file,
    setup: (db) {
      final version = db.select('PRAGMA cipher_version');
      if (version.isEmpty || '${version.first.values.first}'.isEmpty) {
        throw const SqlCipherUnavailableException();
      }
      db.execute("PRAGMA key = \"x'$hexKey'\"");
      // Anahtarı doğrula: yanlışsa burada SqliteException fırlar.
      db.select('SELECT count(*) FROM sqlite_master');
      db.execute('PRAGMA secure_delete = ON');
    },
  );

  final database = AppDatabase(executor);
  try {
    // Bağlantıyı hemen aç; anahtar/SQLCipher hataları burada yakalanır.
    await database.customSelect('SELECT 1').get();
    return database;
  } catch (_) {
    await database.close();
    rethrow;
  }
}
