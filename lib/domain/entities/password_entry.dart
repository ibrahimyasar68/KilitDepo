import 'package:flutter/foundation.dart';

import 'entry_category.dart';

/// Listeleme için kayıt özeti. HİÇBİR gizli alan (şifre, not) içermez;
/// liste ekranında şifreler çözülmez.
@immutable
class EntrySummary {
  const EntrySummary({
    required this.id,
    required this.uuid,
    required this.title,
    required this.username,
    required this.url,
    required this.category,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.iconKey,
    this.colorKey,
  });

  final int id;

  /// Kalıcı rastgele kimlik (alan şifrelemesinde AAD, ileride .kdbx).
  final String uuid;
  final String title;
  final String username;
  final String? url;
  final EntryCategory category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Kullanıcının seçtiği rozet simgesi / rengi (anahtar). `null`: varsayılan
  /// (baş harf ve başlıktan türetilen renk). Gizli değildir; kategori gibi
  /// yalnızca SQLCipher ile korunur.
  final String? iconKey;
  final String? colorKey;
}

/// Detay ekranı için özet + çözülmüş not. Şifre burada da YOKTUR;
/// yalnızca göster/kopyala anında ayrıca çözülür.
@immutable
class EntryDetails {
  const EntryDetails({required this.summary, required this.notes});

  final EntrySummary summary;
  final String? notes;
}

/// Tam kayıt (düzenleme formu için). Şifre ve not çözülmüş hâldedir;
/// yalnızca kısa süre bellekte tutulmalıdır.
@immutable
class PasswordEntry {
  const PasswordEntry({
    required this.summary,
    required this.password,
    required this.notes,
  });

  final EntrySummary summary;
  final String password;
  final String? notes;
}

/// Yeni kayıt / güncelleme için girdi.
@immutable
class EntryDraft {
  const EntryDraft({
    required this.title,
    required this.username,
    required this.password,
    this.url,
    this.notes,
    this.category = EntryCategory.other,
    this.isFavorite = false,
    this.iconKey,
    this.colorKey,
  });

  final String title;
  final String username;
  final String password;
  final String? url;
  final String? notes;
  final EntryCategory category;
  final bool isFavorite;
  final String? iconKey;
  final String? colorKey;
}

/// Şifre geçmişi öğesi (eski şifre YOK; ayrıca çözülür).
@immutable
class PasswordHistoryItem {
  const PasswordHistoryItem({required this.id, required this.changedAt});

  final int id;
  final DateTime changedAt;
}
