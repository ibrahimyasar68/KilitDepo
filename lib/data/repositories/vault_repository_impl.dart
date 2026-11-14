import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../core/constants/security_params.dart';
import '../../core/crypto/crypto_service.dart';
import '../../domain/entities/entry_category.dart';
import '../../domain/entities/password_entry.dart';
import '../../domain/repositories/vault_repository.dart';
import '../database/app_database.dart';

/// [VaultRepository] implementasyonu.
///
/// GÜVENLİK: Şifre, not ve eski şifreler alan anahtarıyla AES-256-GCM
/// kullanılarak şifrelenir. AAD = "kilitdepo/entry/{uuid}/{alan}"; böylece
/// bir kaydın şifreli değeri başka bir kayda veya başka bir alana
/// taşınırsa çözülemez.
class VaultRepositoryImpl implements VaultRepository {
  VaultRepositoryImpl({
    required this._db,
    required this._fieldKey,
    required this._crypto,
    DateTime Function()? clock,
    this._historyLimit = SecurityParams.passwordHistoryLimit,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final SecretKey _fieldKey;
  final CryptoService _crypto;
  final DateTime Function() _clock;
  final int _historyLimit;

  static const _password = 'password';
  static const _notes = 'notes';
  static const _history = 'history';

  @override
  Stream<List<EntrySummary>> watchEntries() => _db.entriesDao.watchAll().map(
    (rows) => rows.map(_toSummary).toList(growable: false),
  );

  @override
  Stream<EntryDetails?> watchEntry(int id) =>
      _db.entriesDao.watchById(id).asyncMap((row) async {
        if (row == null) return null;
        return EntryDetails(
          summary: _toSummary(row),
          notes: await _notesOf(row),
        );
      });

  @override
  Future<PasswordEntry> getEntry(int id) async {
    final row = await _requireRow(id);
    return PasswordEntry(
      summary: _toSummary(row),
      password: await _decrypt(row.passwordEnc, row.uuid, _password),
      notes: await _notesOf(row),
    );
  }

  @override
  Future<String> revealPassword(int id) async {
    final row = await _requireRow(id);
    return _decrypt(row.passwordEnc, row.uuid, _password);
  }

  @override
  Future<int> addEntry(EntryDraft draft) async {
    final d = _validate(draft);
    final uuid = _crypto.generateUuidV4();
    final now = _clock();
    return _db.entriesDao.insertEntry(
      EntriesCompanion.insert(
        uuid: uuid,
        title: d.title,
        username: Value(d.username),
        passwordEnc: await _encrypt(d.password, uuid, _password),
        url: Value(d.url),
        notesEnc: Value(await _encryptNotes(d.notes, uuid)),
        category: d.category.key,
        isFavorite: Value(d.isFavorite),
        iconKey: Value(d.iconKey),
        colorKey: Value(d.colorKey),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<int> addEntries(List<EntryDraft> drafts) => _db.transaction(() async {
    for (final d in drafts) {
      await addEntry(d);
    }
    return drafts.length;
  });

  @override
  Future<void> updateEntry(int id, EntryDraft draft) async {
    final d = _validate(draft);
    await _db.transaction(() async {
      final row = await _requireRow(id);
      final oldPassword = await _decrypt(row.passwordEnc, row.uuid, _password);
      final now = _clock();

      if (oldPassword != d.password) {
        await _db.entriesDao.insertHistory(
          PasswordHistoryCompanion.insert(
            entryId: id,
            oldPasswordEnc: await _encrypt(oldPassword, row.uuid, _history),
            changedAt: now,
          ),
        );
        await _db.entriesDao.pruneHistory(id, _historyLimit);
      }

      await _db.entriesDao.updateEntry(
        id,
        EntriesCompanion(
          title: Value(d.title),
          username: Value(d.username),
          passwordEnc: Value(await _encrypt(d.password, row.uuid, _password)),
          url: Value(d.url),
          notesEnc: Value(await _encryptNotes(d.notes, row.uuid)),
          category: Value(d.category.key),
          isFavorite: Value(d.isFavorite),
          iconKey: Value(d.iconKey),
          colorKey: Value(d.colorKey),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> deleteEntry(int id) async {
    final deleted = await _db.entriesDao.deleteEntry(id);
    if (deleted == 0) throw const EntryNotFoundException();
  }

  @override
  Future<void> setFavorite(int id, {required bool isFavorite}) =>
      // Favori değişikliği "son güncellenen" sıralamasını etkilemez.
      _db.entriesDao.updateEntry(
        id,
        EntriesCompanion(isFavorite: Value(isFavorite)),
      );

  @override
  Stream<List<PasswordHistoryItem>> watchHistory(int entryId) => _db.entriesDao
      .watchHistory(entryId)
      .map(
        (rows) => rows
            .map((r) => PasswordHistoryItem(id: r.id, changedAt: r.changedAt))
            .toList(growable: false),
      );

  @override
  Future<String> revealHistoryPassword(int historyId) async {
    final result = await _db.entriesDao.getHistoryWithUuid(historyId);
    if (result == null) throw const EntryNotFoundException();
    final (row, uuid) = result;
    return _decrypt(row.oldPasswordEnc, uuid, _history);
  }

  @override
  Future<List<({int id, String password})>> revealAllPasswords() async {
    final rows = await _db.entriesDao.getAll();
    return [
      for (final r in rows)
        (id: r.id, password: await _decrypt(r.passwordEnc, r.uuid, _password)),
    ];
  }

  @override
  Future<List<BackupEntry>> exportEntries() async {
    final rows = await _db.entriesDao.getAll();
    final out = <BackupEntry>[];
    for (final r in rows) {
      final history = await _db.entriesDao.historyOf(r.id);
      out.add(
        BackupEntry(
          uuid: r.uuid,
          title: r.title,
          username: r.username,
          password: await _decrypt(r.passwordEnc, r.uuid, _password),
          url: r.url,
          notes: await _notesOf(r),
          category: EntryCategory.fromKey(r.category),
          isFavorite: r.isFavorite,
          iconKey: r.iconKey,
          colorKey: r.colorKey,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
          history: [
            for (final h in history)
              BackupHistoryItem(
                password: await _decrypt(h.oldPasswordEnc, r.uuid, _history),
                changedAt: h.changedAt,
              ),
          ],
        ),
      );
    }
    return out;
  }

  @override
  Future<ImportSummary> previewImport(List<BackupEntry> entries) =>
      _merge(entries, write: false);

  @override
  Future<ImportSummary> importEntries(List<BackupEntry> entries) =>
      _db.transaction(() => _merge(entries, write: true));

  /// Birleştirme kuralı (tek yerde, önizleme ile aynı):
  /// - Kasada yoksa → eklenir (uuid, tarihler ve geçmiş korunur).
  /// - Varsa ve yedekteki daha yeni güncellenmişse → güncellenir; kasadaki
  ///   şifre farklıysa geçmişe yazılır, yedekteki geçmişten eksik olanlar
  ///   eklenir, kayıt başına son N eski şifre tutulur.
  /// - Aksi hâlde → dokunulmaz. Hiçbir kayıt silinmez.
  Future<ImportSummary> _merge(
    List<BackupEntry> entries, {
    required bool write,
  }) async {
    var added = 0, updated = 0, skipped = 0;
    for (final b in entries) {
      final local = await _db.entriesDao.getByUuid(b.uuid);
      if (local == null) {
        added++;
        if (write) await _insertFromBackup(b);
      } else if (b.updatedAt.isAfter(local.updatedAt)) {
        updated++;
        if (write) await _updateFromBackup(local, b);
      } else {
        skipped++;
      }
    }
    return ImportSummary(added: added, updated: updated, skipped: skipped);
  }

  Future<void> _insertFromBackup(BackupEntry b) async {
    final id = await _db.entriesDao.insertEntry(
      EntriesCompanion.insert(
        uuid: b.uuid,
        title: b.title,
        username: Value(b.username),
        passwordEnc: await _encrypt(b.password, b.uuid, _password),
        url: Value(b.url),
        notesEnc: Value(await _encryptNotes(b.notes, b.uuid)),
        category: b.category.key,
        isFavorite: Value(b.isFavorite),
        iconKey: Value(_cleanKey(b.iconKey)),
        colorKey: Value(_cleanKey(b.colorKey)),
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      ),
    );
    for (final h in b.history) {
      await _addHistory(id, b.uuid, h.password, h.changedAt);
    }
    await _db.entriesDao.pruneHistory(id, _historyLimit);
  }

  Future<void> _updateFromBackup(EntryRow local, BackupEntry b) async {
    final localPassword = await _decrypt(
      local.passwordEnc,
      local.uuid,
      _password,
    );
    final known = <String>{
      for (final h in await _db.entriesDao.historyOf(local.id))
        '${h.changedAt.millisecondsSinceEpoch}|'
            '${await _decrypt(h.oldPasswordEnc, local.uuid, _history)}',
    };
    if (localPassword != b.password) {
      await _addHistory(local.id, local.uuid, localPassword, _clock());
    }
    for (final h in b.history) {
      final key = '${h.changedAt.millisecondsSinceEpoch}|${h.password}';
      if (!known.contains(key) && h.password != b.password) {
        await _addHistory(local.id, local.uuid, h.password, h.changedAt);
      }
    }
    await _db.entriesDao.updateEntry(
      local.id,
      EntriesCompanion(
        title: Value(b.title),
        username: Value(b.username),
        passwordEnc: Value(await _encrypt(b.password, local.uuid, _password)),
        url: Value(b.url),
        notesEnc: Value(await _encryptNotes(b.notes, local.uuid)),
        category: Value(b.category.key),
        isFavorite: Value(b.isFavorite),
        iconKey: Value(_cleanKey(b.iconKey)),
        colorKey: Value(_cleanKey(b.colorKey)),
        updatedAt: Value(b.updatedAt),
      ),
    );
    await _db.entriesDao.pruneHistory(local.id, _historyLimit);
  }

  Future<void> _addHistory(
    int entryId,
    String uuid,
    String password,
    DateTime changedAt,
  ) async => _db.entriesDao.insertHistory(
    PasswordHistoryCompanion.insert(
      entryId: entryId,
      oldPasswordEnc: await _encrypt(password, uuid, _history),
      changedAt: changedAt,
    ),
  );

  // ---------------------------------------------------------------------

  Future<EntryRow> _requireRow(int id) async =>
      await _db.entriesDao.getById(id) ??
      (throw const EntryNotFoundException());

  EntrySummary _toSummary(EntryRow r) => EntrySummary(
    id: r.id,
    uuid: r.uuid,
    title: r.title,
    username: r.username,
    url: r.url,
    category: EntryCategory.fromKey(r.category),
    isFavorite: r.isFavorite,
    iconKey: r.iconKey,
    colorKey: r.colorKey,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  EntryDraft _validate(EntryDraft d) {
    final title = d.title.trim();
    if (title.isEmpty) throw ArgumentError('Başlık boş olamaz.');
    if (d.password.isEmpty) throw ArgumentError('Şifre boş olamaz.');
    String? emptyToNull(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();
    return EntryDraft(
      title: title,
      username: d.username.trim(),
      // Şifre ve not olduğu gibi saklanır (boşluklar anlamlı olabilir).
      password: d.password,
      url: emptyToNull(d.url),
      notes: (d.notes == null || d.notes!.trim().isEmpty) ? null : d.notes,
      category: d.category,
      isFavorite: d.isFavorite,
      iconKey: _cleanKey(d.iconKey),
      colorKey: _cleanKey(d.colorKey),
    );
  }

  /// Görünüm anahtarı: kısa, yalnızca harf/rakam/alt çizgi. Aksi hâlde
  /// (ör. elle değiştirilmiş yedek) varsayılana döner. Bilinmeyen ama
  /// geçerli biçimli anahtarlar arayüzde varsayılan gibi gösterilir.
  static String? _cleanKey(String? key) =>
      key != null && RegExp(r'^[a-z0-9_]{1,32}$').hasMatch(key) ? key : null;

  List<int> _aad(String uuid, String field) =>
      utf8.encode('kilitdepo/entry/$uuid/$field');

  Future<String> _encrypt(String value, String uuid, String field) => _crypto
      .encryptString(value, key: _fieldKey, associatedData: _aad(uuid, field));

  Future<String> _decrypt(String value, String uuid, String field) => _crypto
      .decryptString(value, key: _fieldKey, associatedData: _aad(uuid, field));

  Future<String?> _encryptNotes(String? notes, String uuid) async =>
      notes == null ? null : _encrypt(notes, uuid, _notes);

  Future<String?> _notesOf(EntryRow row) async =>
      row.notesEnc == null ? null : _decrypt(row.notesEnc!, row.uuid, _notes);
}
