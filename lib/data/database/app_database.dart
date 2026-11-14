import 'package:drift/drift.dart';

import 'entries_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Entries, PasswordHistory], daos: [EntriesDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Şema sürümü. Yeni alanlar (ör. TOTP) eklenirken artırılır ve
  /// [migration] içinde onUpgrade adımı yazılır.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // 1 → 2: rozet simgesi ve rengi (isteğe bağlı sütunlar). Mevcut
      // kayıtlar olduğu gibi kalır (null = varsayılan görünüm).
      if (from < 2) {
        await m.addColumn(entries, entries.iconKey);
        await m.addColumn(entries, entries.colorKey);
      }
    },
    beforeOpen: (details) async {
      // Geçmişin kayıtla birlikte silinmesi (ON DELETE CASCADE) için.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
