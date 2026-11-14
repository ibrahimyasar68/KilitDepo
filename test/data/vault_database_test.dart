import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/data/database/app_database.dart';
import 'package:kilitdepo/data/database/vault_database_opener.dart';

void main() {
  late Directory tmp;
  late File file;
  final crypto = CryptoService();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('kilitdepo_db_test');
    file = File('${tmp.path}/vault.db');
  });

  tearDown(() async => tmp.delete(recursive: true));

  Future<void> insertMarker(AppDatabase db) => db.customStatement(
    "INSERT INTO entries (uuid, title, username, password_enc, category, "
    "is_favorite, created_at, updated_at) VALUES ('u1', 'GIZLI-BASLIK-XYZ', "
    "'', 'x', 'other', 0, '2026-01-01T00:00:00.000', "
    "'2026-01-01T00:00:00.000')",
  );

  test('SQLCipher yüklü (cipher_version boş değil)', () async {
    final db = await openVaultDatabaseFile(file, crypto.generateDek());
    final rows = await db.customSelect('PRAGMA cipher_version').get();
    expect(rows, isNotEmpty);
    expect('${rows.first.data.values.first}', isNotEmpty);
    await db.close();
  });

  test('doğru anahtarla yeniden açılır, veri korunur', () async {
    final key = crypto.generateDek();
    final db = await openVaultDatabaseFile(file, key);
    await insertMarker(db);
    await db.close();

    final again = await openVaultDatabaseFile(
      file,
      SecretKeyData(List.of(key.bytes)),
    );
    final rows = await again.customSelect('SELECT title FROM entries').get();
    expect(rows.single.read<String>('title'), 'GIZLI-BASLIK-XYZ');
    await again.close();
  });

  test('yanlış anahtarla açılamaz', () async {
    final db = await openVaultDatabaseFile(file, crypto.generateDek());
    await insertMarker(db);
    await db.close();

    await expectLater(
      openVaultDatabaseFile(file, crypto.generateDek()),
      throwsA(anything),
    );
  });

  test('dosya diskte şifreli (düz metin ve SQLite başlığı yok)', () async {
    final db = await openVaultDatabaseFile(file, crypto.generateDek());
    await insertMarker(db);
    await db.close();

    final bytes = await file.readAsBytes();
    final asText = String.fromCharCodes(bytes);
    expect(asText.contains('GIZLI-BASLIK-XYZ'), isFalse);
    expect(asText.startsWith('SQLite format 3'), isFalse);
  });
}
