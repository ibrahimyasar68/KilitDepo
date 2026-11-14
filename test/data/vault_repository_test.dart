import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/crypto/crypto_exceptions.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/data/database/app_database.dart';
import 'package:kilitdepo/data/repositories/vault_repository_impl.dart';
import 'package:kilitdepo/domain/entities/entry_category.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/domain/repositories/vault_repository.dart';

void main() {
  late AppDatabase db;
  late VaultRepositoryImpl repo;
  late DateTime now;
  final crypto = CryptoService();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 3, 1, 10);
    repo = VaultRepositoryImpl(
      db: db,
      fieldKey: crypto.generateDek(),
      crypto: crypto,
      clock: () => now = now.add(const Duration(seconds: 1)),
    );
  });

  tearDown(() => db.close());

  const draft = EntryDraft(
    title: '  Banka Hesabı ',
    username: 'ibrahim@ornek.com',
    password: 'Çok-Gizli-Şifre-1!',
    url: 'https://banka.ornek',
    notes: 'Kurtarma kodu: 1234-5678',
    category: EntryCategory.bank,
  );

  Future<List<QueryRow>> rawEntries() =>
      db.customSelect('SELECT * FROM entries').get();

  test('ekle → listede görünür, alanlar doğru', () async {
    final id = await repo.addEntry(draft);
    final list = await repo.watchEntries().first;
    expect(list, hasLength(1));
    final e = list.single;
    expect(e.id, id);
    expect(e.title, 'Banka Hesabı'); // kırpıldı
    expect(e.category, EntryCategory.bank);
    expect(e.uuid, matches(RegExp(r'^[0-9a-f-]{36}$')));
  });

  test('şifre ve not veritabanında düz metin olarak bulunmaz', () async {
    await repo.addEntry(draft);
    final row = (await rawEntries()).single.data;
    final all = row.values.join('|');
    expect(all, isNot(contains(draft.password)));
    expect(all, isNot(contains('1234-5678')));
    // Aranabilir alanlar (yalnızca SQLCipher korumalı) düz metindir.
    expect(row['title'], 'Banka Hesabı');
  });

  test('şifre göster / tam kayıt çözülür', () async {
    final id = await repo.addEntry(draft);
    expect(await repo.revealPassword(id), draft.password);
    final full = await repo.getEntry(id);
    expect(full.password, draft.password);
    expect(full.notes, draft.notes);
    final details = await repo.watchEntry(id).first;
    expect(details!.notes, draft.notes);
  });

  test('boş not ve URL null olarak saklanır', () async {
    final id = await repo.addEntry(
      const EntryDraft(title: 'X', username: '', password: 'p', notes: '  '),
    );
    final row = (await rawEntries()).single.data;
    expect(row['notes_enc'], isNull);
    expect(row['url'], isNull);
    expect((await repo.getEntry(id)).notes, isNull);
  });

  test('başlık veya şifre boşsa reddedilir', () {
    expect(
      () => repo.addEntry(
        const EntryDraft(title: ' ', username: '', password: 'p'),
      ),
      throwsArgumentError,
    );
    expect(
      () => repo.addEntry(
        const EntryDraft(title: 'A', username: '', password: ''),
      ),
      throwsArgumentError,
    );
  });

  test('şifreli değer başka kayda taşınırsa çözülemez (AAD)', () async {
    final a = await repo.addEntry(draft);
    final b = await repo.addEntry(
      const EntryDraft(title: 'B', username: '', password: 'başka'),
    );
    await db.customStatement(
      'UPDATE entries SET password_enc = '
      '(SELECT password_enc FROM entries WHERE id = ?) WHERE id = ?',
      [a, b],
    );
    expect(
      () => repo.revealPassword(b),
      throwsA(isA<DecryptionFailedException>()),
    );
  });

  test('not alanı şifre alanına taşınırsa çözülemez (alan AAD)', () async {
    final id = await repo.addEntry(draft);
    await db.customStatement(
      'UPDATE entries SET password_enc = notes_enc WHERE id = ?',
      [id],
    );
    expect(
      () => repo.revealPassword(id),
      throwsA(isA<DecryptionFailedException>()),
    );
  });

  group('güncelleme ve geçmiş', () {
    EntryDraft withPassword(String pw) => EntryDraft(
      title: draft.title,
      username: draft.username,
      password: pw,
      url: draft.url,
      notes: draft.notes,
      category: draft.category,
    );

    test('şifre değişince eskisi geçmişe yazılır', () async {
      final id = await repo.addEntry(draft);
      final before = (await repo.getEntry(id)).summary;
      await repo.updateEntry(id, withPassword('Yeni-Şifre-2'));

      expect(await repo.revealPassword(id), 'Yeni-Şifre-2');
      final history = await repo.watchHistory(id).first;
      expect(history, hasLength(1));
      expect(
        await repo.revealHistoryPassword(history.single.id),
        draft.password,
      );
      final after = (await repo.getEntry(id)).summary;
      expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
      expect(after.createdAt, before.createdAt);
    });

    test('şifre aynıysa geçmişe yazılmaz', () async {
      final id = await repo.addEntry(draft);
      await repo.updateEntry(
        id,
        EntryDraft(
          title: 'Yeni başlık',
          username: draft.username,
          password: draft.password,
        ),
      );
      expect(await repo.watchHistory(id).first, isEmpty);
      expect((await repo.getEntry(id)).summary.title, 'Yeni başlık');
    });

    test('kayıt başına yalnızca son 10 eski şifre saklanır', () async {
      final id = await repo.addEntry(withPassword('sifre-0'));
      for (var i = 1; i <= 12; i++) {
        await repo.updateEntry(id, withPassword('sifre-$i'));
      }
      final history = await repo.watchHistory(id).first;
      expect(history, hasLength(10));
      final revealed = [
        for (final h in history) await repo.revealHistoryPassword(h.id),
      ];
      // En yeniden eskiye: 11, 10, ..., 2 (0 ve 1 silindi).
      expect(revealed, [for (var i = 11; i >= 2; i--) 'sifre-$i']);
    });

    test('geçmiş sınırı diğer kayıtları etkilemez', () async {
      final a = await repo.addEntry(withPassword('a0'));
      final b = await repo.addEntry(withPassword('b0'));
      await repo.updateEntry(b, withPassword('b1'));
      for (var i = 1; i <= 11; i++) {
        await repo.updateEntry(a, withPassword('a$i'));
      }
      expect(await repo.watchHistory(b).first, hasLength(1));
    });

    test('geçmişteki şifre veritabanında düz metin değil', () async {
      final id = await repo.addEntry(draft);
      await repo.updateEntry(id, withPassword('Yeni-Şifre-2'));
      final rows = await db
          .customSelect('SELECT * FROM password_history')
          .get();
      expect(rows.single.data.values.join(), isNot(contains(draft.password)));
    });
  });

  test('sil → kayıt ve geçmişi kaldırılır', () async {
    final id = await repo.addEntry(draft);
    await repo.updateEntry(
      id,
      EntryDraft(title: 'x', username: '', password: 'yeni'),
    );
    await repo.deleteEntry(id);
    expect(await repo.watchEntries().first, isEmpty);
    expect(await repo.watchEntry(id).first, isNull);
    final history = await db
        .customSelect('SELECT * FROM password_history')
        .get();
    expect(history, isEmpty);
  });

  test('olmayan kayıt → EntryNotFoundException', () {
    expect(
      () => repo.revealPassword(999),
      throwsA(isA<EntryNotFoundException>()),
    );
    expect(() => repo.deleteEntry(999), throwsA(isA<EntryNotFoundException>()));
  });

  test('favori değişikliği güncellenme tarihini değiştirmez', () async {
    final id = await repo.addEntry(draft);
    final before = (await repo.getEntry(id)).summary;
    await repo.setFavorite(id, isFavorite: true);
    final after = (await repo.getEntry(id)).summary;
    expect(after.isFavorite, isTrue);
    expect(after.updatedAt, before.updatedAt);
  });

  test('yanlış alan anahtarıyla şifre çözülemez', () async {
    final id = await repo.addEntry(draft);
    final other = VaultRepositoryImpl(
      db: db,
      fieldKey: crypto.generateDek(),
      crypto: crypto,
    );
    expect(
      () => other.revealPassword(id),
      throwsA(isA<DecryptionFailedException>()),
    );
  });

  test('canlı liste ekleme sonrası güncellenir', () async {
    final stream = repo.watchEntries();
    final expectation = expectLater(
      stream.map((l) => l.length),
      emitsThrough(1),
    );
    await repo.addEntry(draft);
    await expectation;
  });

  test('base64 çıktısı beklenen biçimde (sürüm byte\'ı)', () async {
    await repo.addEntry(draft);
    final enc = (await rawEntries()).single.read<String>('password_enc');
    expect(base64Decode(enc).first, 1);
  });
}
