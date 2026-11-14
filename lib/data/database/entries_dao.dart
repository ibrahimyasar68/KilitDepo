import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables.dart';

part 'entries_dao.g.dart';

/// Kayıt ve geçmiş tabloları için veri erişimi.
/// Bu katman yalnızca şifreli değerlerle çalışır; şifreleme repository'dedir.
@DriftAccessor(tables: [Entries, PasswordHistory])
class EntriesDao extends DatabaseAccessor<AppDatabase> with _$EntriesDaoMixin {
  EntriesDao(super.attachedDatabase);

  Stream<List<EntryRow>> watchAll() => select(entries).watch();

  Future<List<EntryRow>> getAll() => select(entries).get();

  Future<EntryRow?> getByUuid(String uuid) =>
      (select(entries)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

  /// Kaydın geçmişi, en yeniden eskiye.
  Future<List<HistoryRow>> historyOf(int entryId) =>
      (select(passwordHistory)
            ..where((t) => t.entryId.equals(entryId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.changedAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .get();

  Stream<EntryRow?> watchById(int id) =>
      (select(entries)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<EntryRow?> getById(int id) =>
      (select(entries)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertEntry(EntriesCompanion entry) =>
      into(entries).insert(entry);

  Future<void> updateEntry(int id, EntriesCompanion entry) =>
      (update(entries)..where((t) => t.id.equals(id))).write(entry);

  /// Kaydı ve geçmişini siler. CASCADE'e ek olarak geçmiş açıkça silinir
  /// (canlı sorguların güncellenmesi ve ek güvence için).
  Future<int> deleteEntry(int id) => transaction(() async {
    await (delete(passwordHistory)..where((t) => t.entryId.equals(id))).go();
    return (delete(entries)..where((t) => t.id.equals(id))).go();
  });

  Future<void> insertHistory(PasswordHistoryCompanion row) =>
      into(passwordHistory).insert(row);

  /// Kayıt başına yalnızca en yeni [keep] eski şifreyi bırakır.
  Future<void> pruneHistory(int entryId, int keep) async {
    final keepIds =
        await (selectOnly(passwordHistory)
              ..addColumns([passwordHistory.id])
              ..where(passwordHistory.entryId.equals(entryId))
              ..orderBy([
                OrderingTerm.desc(passwordHistory.changedAt),
                OrderingTerm.desc(passwordHistory.id),
              ])
              ..limit(keep))
            .map((r) => r.read(passwordHistory.id)!)
            .get();
    await (delete(
      passwordHistory,
    )..where((t) => t.entryId.equals(entryId) & t.id.isNotIn(keepIds))).go();
  }

  /// En yeniden eskiye (değişiklik tarihine, eşitlikte id'ye göre).
  Stream<List<HistoryRow>> watchHistory(int entryId) =>
      (select(passwordHistory)
            ..where((t) => t.entryId.equals(entryId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.changedAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch();

  /// Geçmiş satırı ve ait olduğu kaydın uuid'si (AAD için).
  Future<(HistoryRow, String)?> getHistoryWithUuid(int historyId) async {
    final query = select(passwordHistory).join([
      innerJoin(entries, entries.id.equalsExp(passwordHistory.entryId)),
    ])..where(passwordHistory.id.equals(historyId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(passwordHistory), row.readTable(entries).uuid);
  }
}
