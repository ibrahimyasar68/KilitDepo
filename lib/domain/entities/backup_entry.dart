import 'package:flutter/foundation.dart';

import 'entry_category.dart';

/// Yedekteki eski şifre.
@immutable
class BackupHistoryItem {
  const BackupHistoryItem({required this.password, required this.changedAt});

  final String password;
  final DateTime changedAt;
}

/// Yedekteki tam kayıt (çözülmüş). Yalnızca yedek oluşturma / geri
/// yükleme sırasında kısa süre bellekte bulunur.
@immutable
class BackupEntry {
  const BackupEntry({
    required this.uuid,
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.notes,
    required this.category,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.history = const [],
    this.iconKey,
    this.colorKey,
  });

  final String uuid;
  final String title;
  final String username;
  final String password;
  final String? url;
  final String? notes;
  final EntryCategory category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// En yeniden eskiye.
  final List<BackupHistoryItem> history;

  /// Rozet simgesi / rengi (isteğe bağlı; eski yedeklerde yoktur).
  final String? iconKey;
  final String? colorKey;
}

/// İçe aktarma özeti.
@immutable
class ImportSummary {
  const ImportSummary({
    required this.added,
    required this.updated,
    required this.skipped,
  });

  /// Kasada olmayan, eklenecek / eklenen kayıtlar.
  final int added;

  /// Yedekteki sürümü daha yeni olduğu için güncellenecek / güncellenen.
  final int updated;

  /// Kasadaki sürüm aynı veya daha yeni olduğu için dokunulmayan.
  final int skipped;

  int get total => added + updated + skipped;
}
