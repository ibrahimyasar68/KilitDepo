import 'dart:async';

import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/domain/repositories/vault_repository.dart';

/// Widget testleri için bellek içi, şifrelemesiz sahte repository.
class FakeVaultRepository implements VaultRepository {
  final Map<int, PasswordEntry> _entries = {};
  final Map<int, List<(int, String, DateTime)>> _history = {};
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;
  int _nextHistoryId = 1;
  DateTime _now = DateTime(2026, 1, 1, 12);

  int revealCalls = 0;
  int revealAllCalls = 0;

  DateTime _tick() => _now = _now.add(const Duration(minutes: 1));

  List<EntrySummary> get _summaries =>
      _entries.values.map((e) => e.summary).toList();

  @override
  Stream<List<EntrySummary>> watchEntries() async* {
    yield _summaries;
    yield* _changes.stream.map((_) => _summaries);
  }

  @override
  Stream<EntryDetails?> watchEntry(int id) async* {
    EntryDetails? current() {
      final e = _entries[id];
      return e == null
          ? null
          : EntryDetails(summary: e.summary, notes: e.notes);
    }

    yield current();
    yield* _changes.stream.map((_) => current());
  }

  @override
  Future<PasswordEntry> getEntry(int id) async =>
      _entries[id] ?? (throw const EntryNotFoundException());

  @override
  Future<String> revealPassword(int id) async {
    revealCalls++;
    return (await getEntry(id)).password;
  }

  @override
  Future<int> addEntry(EntryDraft d) async {
    final id = _nextId++;
    final now = _tick();
    _entries[id] = _build(id, 'uuid-$id', d, now, now);
    _changes.add(null);
    return id;
  }

  @override
  Future<int> addEntries(List<EntryDraft> drafts) async {
    for (final d in drafts) {
      await addEntry(d);
    }
    return drafts.length;
  }

  @override
  Future<void> updateEntry(int id, EntryDraft d) async {
    final old = await getEntry(id);
    final now = _tick();
    if (old.password != d.password) {
      (_history[id] ??= []).insert(0, (_nextHistoryId++, old.password, now));
    }
    _entries[id] = _build(id, old.summary.uuid, d, old.summary.createdAt, now);
    _changes.add(null);
  }

  @override
  Future<void> deleteEntry(int id) async {
    _entries.remove(id);
    _history.remove(id);
    _changes.add(null);
  }

  @override
  Future<void> setFavorite(int id, {required bool isFavorite}) async {
    final e = await getEntry(id);
    final s = e.summary;
    _entries[id] = _build(
      id,
      s.uuid,
      EntryDraft(
        title: s.title,
        username: s.username,
        password: e.password,
        url: s.url,
        notes: e.notes,
        category: s.category,
        isFavorite: isFavorite,
        iconKey: s.iconKey,
        colorKey: s.colorKey,
      ),
      s.createdAt,
      s.updatedAt,
    );
    _changes.add(null);
  }

  @override
  Stream<List<PasswordHistoryItem>> watchHistory(int entryId) async* {
    List<PasswordHistoryItem> current() => [
      for (final (id, _, at)
          in _history[entryId] ?? const <(int, String, DateTime)>[])
        PasswordHistoryItem(id: id, changedAt: at),
    ];
    yield current();
    yield* _changes.stream.map((_) => current());
  }

  @override
  Future<String> revealHistoryPassword(int historyId) async {
    for (final list in _history.values) {
      for (final (id, pw, _) in list) {
        if (id == historyId) return pw;
      }
    }
    throw const EntryNotFoundException();
  }

  @override
  Future<List<({int id, String password})>> revealAllPasswords() async {
    revealAllCalls++;
    return [
      for (final e in _entries.values) (id: e.summary.id, password: e.password),
    ];
  }

  @override
  Future<List<BackupEntry>> exportEntries() async => [
    for (final e in _entries.values)
      BackupEntry(
        uuid: e.summary.uuid,
        title: e.summary.title,
        username: e.summary.username,
        password: e.password,
        url: e.summary.url,
        notes: e.notes,
        category: e.summary.category,
        isFavorite: e.summary.isFavorite,
        iconKey: e.summary.iconKey,
        colorKey: e.summary.colorKey,
        createdAt: e.summary.createdAt,
        updatedAt: e.summary.updatedAt,
      ),
  ];

  @override
  Future<ImportSummary> previewImport(List<BackupEntry> entries) async {
    var added = 0, updated = 0, skipped = 0;
    for (final b in entries) {
      final local = _entries.values
          .where((e) => e.summary.uuid == b.uuid)
          .firstOrNull;
      if (local == null) {
        added++;
      } else if (b.updatedAt.isAfter(local.summary.updatedAt)) {
        updated++;
      } else {
        skipped++;
      }
    }
    return ImportSummary(added: added, updated: updated, skipped: skipped);
  }

  List<BackupEntry>? lastImport;

  @override
  Future<ImportSummary> importEntries(List<BackupEntry> entries) async {
    lastImport = entries;
    final summary = await previewImport(entries);
    for (final b in entries) {
      if (_entries.values.any((e) => e.summary.uuid == b.uuid)) continue;
      final id = _nextId++;
      _entries[id] = _build(
        id,
        b.uuid,
        EntryDraft(
          title: b.title,
          username: b.username,
          password: b.password,
          url: b.url,
          notes: b.notes,
          category: b.category,
          isFavorite: b.isFavorite,
          iconKey: b.iconKey,
          colorKey: b.colorKey,
        ),
        b.createdAt,
        b.updatedAt,
      );
    }
    _changes.add(null);
    return summary;
  }

  PasswordEntry _build(
    int id,
    String uuid,
    EntryDraft d,
    DateTime createdAt,
    DateTime updatedAt,
  ) {
    final notes = (d.notes == null || d.notes!.trim().isEmpty) ? null : d.notes;
    final url = (d.url == null || d.url!.trim().isEmpty) ? null : d.url;
    return PasswordEntry(
      summary: EntrySummary(
        id: id,
        uuid: uuid,
        title: d.title.trim(),
        username: d.username.trim(),
        url: url,
        category: d.category,
        isFavorite: d.isFavorite,
        iconKey: d.iconKey,
        colorKey: d.colorKey,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
      password: d.password,
      notes: notes,
    );
  }
}
