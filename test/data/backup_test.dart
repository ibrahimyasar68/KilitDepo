import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/constants/crypto_params.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/data/backup/backup_codec.dart';
import 'package:kilitdepo/data/database/app_database.dart';
import 'package:kilitdepo/data/repositories/vault_repository_impl.dart';
import 'package:kilitdepo/domain/entities/entry_category.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/domain/repositories/vault_repository.dart';

import '../helpers/in_memory_store.dart';

void main() {
  final crypto = CryptoService();
  final codec = BackupCodec(crypto, kdf: fastTestKdf);
  const backupPassword = 'Ayrı-Yedek-Şifresi-2026';

  BackupEntry sample({
    String uuid = 'u-1',
    String password = 'Gizli-Şifre-1!',
    DateTime? updatedAt,
    List<BackupHistoryItem> history = const [],
  }) => BackupEntry(
    uuid: uuid,
    title: 'Banka Hesabı',
    username: 'ibrahim',
    password: password,
    url: 'https://banka.ornek',
    notes: 'Kurtarma kodu 9999',
    category: EntryCategory.bank,
    isFavorite: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime.utc(2026, 2, 1),
    history: history,
  );

  group('BackupCodec', () {
    test('üretim parametreleri: 64 MB, 6 iterasyon, 4 paralellik', () {
      expect(CryptoParams.backupKdf.memoryKiB, 64 * 1024);
      expect(CryptoParams.backupKdf.iterations, 6);
      expect(CryptoParams.backupKdf.parallelism, 4);
    });

    test('şifrele → çöz aynı veriyi verir (geçmiş dahil)', () async {
      final entry = sample(
        history: [
          BackupHistoryItem(
            password: 'Eski-Şifre',
            changedAt: DateTime.utc(2026, 1, 15),
          ),
        ],
      );
      final file = await codec.encode([entry], backupPassword);
      final back = (await codec.decode(file, backupPassword)).single;
      expect(back.uuid, entry.uuid);
      expect(back.title, entry.title);
      expect(back.password, entry.password);
      expect(back.notes, entry.notes);
      expect(back.category, EntryCategory.bank);
      expect(back.isFavorite, isTrue);
      expect(back.updatedAt.toUtc(), entry.updatedAt);
      expect(back.history.single.password, 'Eski-Şifre');
    });

    test('dosyada düz metin bulunmaz; yalnızca başlık açıktır', () async {
      final file = await codec.encode([sample()], backupPassword);
      final text = utf8.decode(file);
      for (final secret in [
        'Banka Hesabı',
        'ibrahim',
        'Gizli-Şifre-1!',
        'Kurtarma',
        'banka.ornek',
      ]) {
        expect(text.contains(secret), isFalse, reason: secret);
      }
      final header = jsonDecode(text) as Map<String, dynamic>;
      expect(header.keys.toSet(), {'format', 'v', 'kdf', 'salt', 'data'});
    });

    test('yanlış yedek şifresi', () async {
      final file = await codec.encode([sample()], backupPassword);
      expect(
        () => codec.decode(file, 'yanlış-yedek-şifresi'),
        throwsA(isA<BackupWrongPasswordException>()),
      );
    });

    test('başlık (KDF) değiştirilirse açılmaz', () async {
      final file = await codec.encode([sample()], backupPassword);
      final header = jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
      (header['kdf'] as Map<String, dynamic>)['t'] = 2;
      final tampered = Uint8List.fromList(utf8.encode(jsonEncode(header)));
      expect(
        () => codec.decode(tampered, backupPassword),
        throwsA(isA<BackupWrongPasswordException>()),
      );
    });

    test('şifreli veri bozulursa açılmaz', () async {
      final file = await codec.encode([sample()], backupPassword);
      final header = jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
      final data = base64Decode(header['data'] as String);
      data[data.length ~/ 2] ^= 0x01;
      header['data'] = base64Encode(data);
      expect(
        () => codec.decode(
          Uint8List.fromList(utf8.encode(jsonEncode(header))),
          backupPassword,
        ),
        throwsA(isA<BackupWrongPasswordException>()),
      );
    });

    test('geçersiz dosyalar reddedilir', () async {
      Future<void> bad(String content) => expectLater(
        codec.decode(Uint8List.fromList(utf8.encode(content)), backupPassword),
        throwsA(isA<BackupFormatException>()),
      );
      await bad('bu bir yedek değil');
      await bad('{"format":"baska","v":1}');
      await bad(
        '{"format":"kilitdepo-backup","v":99,"kdf":{},"salt":"","data":""}',
      );
    });

    test('aşırı KDF parametreli dosya reddedilir (DoS koruması)', () async {
      final file = await codec.encode([sample()], backupPassword);
      final header = jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
      (header['kdf'] as Map<String, dynamic>)['m'] = 4 * 1024 * 1024; // 4 GB
      expect(
        () => codec.decode(
          Uint8List.fromList(utf8.encode(jsonEncode(header))),
          backupPassword,
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('kısa yedek şifresi reddedilir', () {
      expect(() => codec.encode([sample()], 'kısa'), throwsArgumentError);
    });

    test('dosya adı', () {
      expect(
        BackupCodec.suggestedFileName(DateTime(2026, 11, 9)),
        'kilitdepo-yedek-2026-11-09.kilitdepo',
      );
    });
  });

  group('Dışa / içe aktarma ve birleştirme', () {
    late AppDatabase db;
    late VaultRepositoryImpl repo;
    late DateTime now;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      now = DateTime(2026, 6, 1);
      repo = VaultRepositoryImpl(
        db: db,
        fieldKey: crypto.generateDek(),
        crypto: crypto,
        clock: () => now = now.add(const Duration(seconds: 1)),
      );
    });

    tearDown(() => db.close());

    test('dışa aktar → başka kasaya içe aktar: aynı veri', () async {
      final id = await repo.addEntry(
        const EntryDraft(
          title: 'Gmail',
          username: 'ibo',
          password: 'ilk-sifre',
          notes: 'not',
          category: EntryCategory.email,
        ),
      );
      await repo.updateEntry(
        id,
        const EntryDraft(
          title: 'Gmail',
          username: 'ibo',
          password: 'ikinci-sifre',
          notes: 'not',
          category: EntryCategory.email,
        ),
      );
      final exported = await repo.exportEntries();
      final file = await codec.encode(exported, backupPassword);

      // İki AYRI bellek içi veritabanı (iki cihazı temsil eder); drift'in
      // "aynı sınıf iki kez" uyarısı burada bilinçli olarak geçersiz.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );
      final otherDb = AppDatabase(NativeDatabase.memory());
      addTearDown(otherDb.close);
      final other = VaultRepositoryImpl(
        db: otherDb,
        fieldKey: crypto.generateDek(), // farklı kasa anahtarı
        crypto: crypto,
      );
      final decoded = await codec.decode(file, backupPassword);
      expect((await other.previewImport(decoded)).added, 1);
      final result = await other.importEntries(decoded);
      expect(result.added, 1);

      final e = (await other.watchEntries().first).single;
      expect(e.uuid, exported.single.uuid);
      expect(await other.revealPassword(e.id), 'ikinci-sifre');
      expect((await other.getEntry(e.id)).notes, 'not');
      final history = await other.watchHistory(e.id).first;
      expect(await other.revealHistoryPassword(history.single.id), 'ilk-sifre');
    });

    test(
      'yedekteki daha yeniyse güncellenir; kasadaki şifre geçmişe yazılır',
      () async {
        await repo.importEntries([sample(password: 'kasa-sifresi')]);
        final newer = sample(
          password: 'yedek-sifresi',
          updatedAt: DateTime.utc(2026, 3, 1),
        );
        final preview = await repo.previewImport([newer]);
        expect((preview.added, preview.updated, preview.skipped), (0, 1, 0));
        await repo.importEntries([newer]);

        final e = (await repo.watchEntries().first).single;
        expect(await repo.revealPassword(e.id), 'yedek-sifresi');
        final history = await repo.watchHistory(e.id).first;
        expect(
          await repo.revealHistoryPassword(history.first.id),
          'kasa-sifresi',
        );
      },
    );

    test('kasadaki daha yeni veya aynıysa dokunulmaz', () async {
      await repo.importEntries([
        sample(password: 'kasa', updatedAt: DateTime.utc(2026, 5, 1)),
      ]);
      final older = sample(
        password: 'eski-yedek',
        updatedAt: DateTime.utc(2026, 4, 1),
      );
      final r = await repo.importEntries([older]);
      expect((r.added, r.updated, r.skipped), (0, 0, 1));
      final e = (await repo.watchEntries().first).single;
      expect(await repo.revealPassword(e.id), 'kasa');
    });

    test('içe aktarma hiçbir kaydı silmez', () async {
      await repo.addEntry(
        const EntryDraft(title: 'Yalnız kasada', username: '', password: 'x'),
      );
      await repo.importEntries([sample()]);
      expect(await repo.watchEntries().first, hasLength(2));
    });

    test('içe aktarılan geçmiş de son 10 ile sınırlanır', () async {
      await repo.importEntries([
        sample(
          history: [
            for (var i = 0; i < 15; i++)
              BackupHistoryItem(
                password: 'eski-$i',
                changedAt: DateTime.utc(2025, 1, 1).add(Duration(days: i)),
              ),
          ],
        ),
      ]);
      final e = (await repo.watchEntries().first).single;
      final history = await repo.watchHistory(e.id).first;
      expect(history, hasLength(10));
      // En yeni 10: eski-14 … eski-5.
      expect(await repo.revealHistoryPassword(history.first.id), 'eski-14');
      expect(await repo.revealHistoryPassword(history.last.id), 'eski-5');
    });

    test('revealAllPasswords tüm kayıtları döndürür', () async {
      await repo.addEntry(
        const EntryDraft(title: 'A', username: '', password: 'a-1'),
      );
      await repo.addEntry(
        const EntryDraft(title: 'B', username: '', password: 'b-2'),
      );
      final all = await repo.revealAllPasswords();
      expect(all.map((e) => e.password).toSet(), {'a-1', 'b-2'});
    });
  });
}
