/// Kayıt kategorileri.
///
/// Veritabanına Türkçe ad yerine sabit [key] yazılır; görünen adlar
/// yerelleştirme dosyasından gelir (çeviri için).
enum EntryCategory {
  socialMedia('social'),
  bank('bank'),
  email('email'),
  work('work'),
  other('other');

  const EntryCategory(this.key);

  final String key;

  /// Bilinmeyen anahtarlar [other] olarak yorumlanır (ileri uyumluluk).
  static EntryCategory fromKey(String key) => EntryCategory.values.firstWhere(
    (c) => c.key == key,
    orElse: () => EntryCategory.other,
  );
}
