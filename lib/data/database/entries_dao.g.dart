// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries_dao.dart';

// ignore_for_file: type=lint
mixin _$EntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $EntriesTable get entries => attachedDatabase.entries;
  $PasswordHistoryTable get passwordHistory => attachedDatabase.passwordHistory;
  EntriesDaoManager get managers => EntriesDaoManager(this);
}

class EntriesDaoManager {
  final _$EntriesDaoMixin _db;
  EntriesDaoManager(this._db);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db.attachedDatabase, _db.entries);
  $$PasswordHistoryTableTableManager get passwordHistory =>
      $$PasswordHistoryTableTableManager(
        _db.attachedDatabase,
        _db.passwordHistory,
      );
}
