import 'dart:math';

/// Şifre gücü seviyeleri.
enum PasswordStrength { veryWeak, weak, fair, strong, veryStrong }

/// Basit, çevrimdışı şifre gücü tahmini.
///
/// Bu bir kriptografik işlem değildir; yalnızca kullanıcıya geri bildirim
/// verir. Karakter havuzuna göre kaba entropi hesaplanır, tekrar eden
/// karakterler, ardışık diziler ve çok yaygın kalıplar için ceza uygulanır.
abstract final class PasswordStrengthEstimator {
  static const List<String> _commonFragments = [
    'password',
    'sifre',
    'şifre',
    'parola',
    'qwerty',
    'asdf',
    'zxcv',
    '123456',
    'abc123',
    'admin',
    'letmein',
    'iloveyou',
    'galatasaray',
    'fenerbahce',
    'besiktas',
    'trabzon',
    'kilitdepo',
  ];

  // Bir kez derlenir (her tuş vuruşunda ve raporda yeniden derlenmez).
  static final RegExp _lower = RegExp(r'[a-zçğıöşü]');
  static final RegExp _upper = RegExp(r'[A-ZÇĞİÖŞÜ]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _symbol = RegExp(r'[^a-zA-Z0-9çğıöşüÇĞİÖŞÜ]');

  /// Yaklaşık entropi (bit).
  static double entropyBits(String password) {
    if (password.isEmpty) return 0;

    var pool = 0;
    if (password.contains(_lower)) pool += 32;
    if (password.contains(_upper)) pool += 32;
    if (password.contains(_digit)) pool += 10;
    if (password.contains(_symbol)) pool += 33;

    // Tekrar eden ve ardışık karakterler etkin uzunluğu düşürür.
    var effectiveLength = 0.0;
    for (var i = 0; i < password.length; i++) {
      if (i > 0) {
        final prev = password.codeUnitAt(i - 1);
        final cur = password.codeUnitAt(i);
        if (cur == prev) {
          effectiveLength += 0.25;
          continue;
        }
        if ((cur - prev).abs() == 1) {
          effectiveLength += 0.5;
          continue;
        }
      }
      effectiveLength += 1;
    }

    var bits = effectiveLength * (log(pool) / ln2);

    final lower = password.toLowerCase();
    for (final fragment in _commonFragments) {
      if (lower.contains(fragment)) bits -= fragment.length * 3;
    }
    return max(0, bits);
  }

  static PasswordStrength estimate(String password) =>
      fromBits(entropyBits(password));

  /// Entropi (bit) → seviye. Kelime tabanlı üretici gerçek entropiyi
  /// bildiği için bunu doğrudan kullanır.
  static PasswordStrength fromBits(double bits) {
    if (bits < 40) return PasswordStrength.veryWeak;
    if (bits < 60) return PasswordStrength.weak;
    if (bits < 80) return PasswordStrength.fair;
    if (bits < 100) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}
