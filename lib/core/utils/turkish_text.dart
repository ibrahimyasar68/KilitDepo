/// Türkçe'ye uygun küçük harfe çevirme, arama ve alfabetik sıralama.
///
/// Dart'ın `toLowerCase()` fonksiyonu "I" → "i" yapar (Türkçe'de "ı"
/// olmalı) ve SQLite'ın NOCASE karşılaştırması yalnızca ASCII'yi bilir.
abstract final class TurkishText {
  /// Türkçe alfabe (+ q, w, x) sırası.
  static const String _alphabet = 'abcçdefgğhıijklmnoöpqrsştuüvwxyz';

  static final Map<int, int> _order = {
    for (var i = 0; i < _alphabet.length; i++) _alphabet.codeUnitAt(i): i,
  };

  /// Türkçe kurallarıyla küçük harf.
  static String lower(String s) =>
      s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

  /// Arama için sadeleştirme: küçük harf + aksan katlama, böylece
  /// "sifre" araması "Şifre"yi, "istanbul" araması "Istanbul"u bulur.
  static String fold(String s) {
    final units = lower(s).codeUnits;
    final out = List<int>.filled(units.length, 0);
    for (var i = 0; i < units.length; i++) {
      out[i] = _foldMap[units[i]] ?? units[i];
    }
    return String.fromCharCodes(out);
  }

  /// Aksanlı harf → sade karşılığı (kod birimi düzeyinde).
  static final Map<int, int> _foldMap = {
    for (var i = 0; i < 'çğıöşüâîû'.length; i++)
      'çğıöşüâîû'.codeUnitAt(i): 'cgiosuaiu'.codeUnitAt(i),
  };

  /// [haystack] içinde [needle] var mı (büyük/küçük harf ve aksan duyarsız)?
  static bool containsFolded(String haystack, String needle) =>
      fold(haystack).contains(fold(needle));

  /// Türkçe alfabe sırasına göre karşılaştırma (büyük/küçük harf duyarsız).
  static int compare(String a, String b) =>
      compareLowered(lower(a), lower(b), a, b);

  /// [compare] ile aynı; küçük harfli hâller ([lower]) önceden hesaplanmışsa
  /// sıralamada her karşılaştırmada yeniden çevirmemek için.
  static int compareLowered(String la, String lb, String a, String b) {
    final n = la.length < lb.length ? la.length : lb.length;
    for (var i = 0; i < n; i++) {
      final wa = _weight(la.codeUnitAt(i));
      final wb = _weight(lb.codeUnitAt(i));
      if (wa != wb) return wa.compareTo(wb);
    }
    final byLength = la.length.compareTo(lb.length);
    return byLength != 0 ? byLength : a.compareTo(b);
  }

  /// Harf dışı karakterler (rakam, noktalama) harflerden önce gelir.
  static int _weight(int codeUnit) {
    final index = _order[codeUnit];
    return index != null ? 0x10000 + index : codeUnit;
  }
}
