import 'package:drift/drift.dart';

/// Şifre kayıtları.
///
/// GÜVENLİK: Tüm dosya SQLCipher ile şifrelidir. Ek olarak `password_enc`
/// ve `notes_enc` sütunları alan düzeyinde AES-256-GCM ile şifrelenir
/// (AAD: kaydın uuid'si + alan adı). Başlık, kullanıcı adı ve URL arama
/// yapılabilmesi için yalnızca SQLCipher ile korunur.
@DataClassName('EntryRow')
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get title => text()();
  TextColumn get username => text().withDefault(const Constant(''))();
  TextColumn get passwordEnc => text()();
  TextColumn get url => text().nullable()();
  TextColumn get notesEnc => text().nullable()();
  TextColumn get category => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Rozet simgesi / rengi (şema 2). Gizli değil; null = varsayılan.
  TextColumn get iconKey => text().nullable()();
  TextColumn get colorKey => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Eski şifreler. Kayıt silinince geçmişi de silinir.
@DataClassName('HistoryRow')
@TableIndex(name: 'password_history_entry_idx', columns: {#entryId})
class PasswordHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId =>
      integer().references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get oldPasswordEnc => text()();
  DateTimeColumn get changedAt => dateTime()();
}
