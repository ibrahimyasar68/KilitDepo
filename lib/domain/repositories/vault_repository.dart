import '../entities/backup_entry.dart';
import '../entities/password_entry.dart';

export '../entities/backup_entry.dart';

class EntryNotFoundException implements Exception {
  const EntryNotFoundException();
}

/// Şifre kayıtları deposu.
///
/// Gizli alanlar (şifre, not, eski şifreler) bu katmanın altında
/// şifrelenir/çözülür; arayüz şifreli veriyle hiç karşılaşmaz.
abstract interface class VaultRepository {
  /// Tüm kayıtların özetleri (canlı).
  Stream<List<EntrySummary>> watchEntries();

  /// Tek kaydın detayı (canlı). Silinmişse null.
  Stream<EntryDetails?> watchEntry(int id);

  /// Düzenleme için tam kayıt.
  Future<PasswordEntry> getEntry(int id);

  /// Kaydın şifresini çözer (göster/kopyala anında).
  Future<String> revealPassword(int id);

  Future<int> addEntry(EntryDraft draft);

  /// Birden çok kaydı tek işlemde ekler (CSV içe aktarma). Biri başarısız
  /// olursa hiçbiri eklenmez. Eklenen kayıt sayısını döndürür.
  Future<int> addEntries(List<EntryDraft> drafts);

  /// Şifre değiştiyse eskisi geçmişe yazılır (kayıt başına son N tane).
  Future<void> updateEntry(int id, EntryDraft draft);

  Future<void> deleteEntry(int id);

  Future<void> setFavorite(int id, {required bool isFavorite});

  /// Kaydın şifre geçmişi, en yeniden eskiye (canlı).
  Stream<List<PasswordHistoryItem>> watchHistory(int entryId);

  Future<String> revealHistoryPassword(int historyId);

  /// Tüm kayıtların çözülmüş şifreleri. YALNIZCA güvenlik analizi için;
  /// sonuç kısa süre bellekte tutulmalı ve hemen bırakılmalıdır.
  Future<List<({int id, String password})>> revealAllPasswords();

  /// Yedek için tüm kayıtlar (gizli alanlar ve geçmiş çözülmüş hâlde).
  Future<List<BackupEntry>> exportEntries();

  /// İçe aktarmanın ne yapacağını hesaplar (hiçbir şey yazmaz).
  Future<ImportSummary> previewImport(List<BackupEntry> entries);

  /// Yedeği kasayla birleştirir. Hiçbir kayıt silinmez; aynı kayıt varsa
  /// daha yakın tarihte güncellenmiş olan kalır.
  Future<ImportSummary> importEntries(List<BackupEntry> entries);
}
