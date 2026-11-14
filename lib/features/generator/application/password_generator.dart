import 'dart:math';

import 'package:flutter/foundation.dart';

/// Şifre üretici seçenekleri.
@immutable
class GeneratorOptions {
  const GeneratorOptions({
    this.length = 20,
    this.uppercase = true,
    this.lowercase = true,
    this.digits = true,
    this.symbols = true,
    this.excludeAmbiguous = false,
  });

  static const int minLength = 8;
  static const int maxLength = 64;

  final int length;
  final bool uppercase;
  final bool lowercase;
  final bool digits;
  final bool symbols;
  final bool excludeAmbiguous;

  bool get hasAnySet => uppercase || lowercase || digits || symbols;

  GeneratorOptions copyWith({
    int? length,
    bool? uppercase,
    bool? lowercase,
    bool? digits,
    bool? symbols,
    bool? excludeAmbiguous,
  }) => GeneratorOptions(
    length: length ?? this.length,
    uppercase: uppercase ?? this.uppercase,
    lowercase: lowercase ?? this.lowercase,
    digits: digits ?? this.digits,
    symbols: symbols ?? this.symbols,
    excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
  );

  /// Saklamak için kısa metin: `uzunluk|ABC|abc|123|#$%|benzer` (1/0).
  String encode() => [
    length,
    for (final b in [uppercase, lowercase, digits, symbols, excludeAmbiguous])
      b ? 1 : 0,
  ].join('|');

  /// [encode] çıktısını çözer. Bozuk / sınır dışı değerde `null` döner
  /// (varsayılanlar kullanılır).
  static GeneratorOptions? decode(String? raw) {
    final parts = raw?.split('|');
    if (parts == null || parts.length != 6) return null;
    final length = int.tryParse(parts[0]);
    if (length == null || length < minLength || length > maxLength) {
      return null;
    }
    final flags = parts.skip(1).map((p) => p == '1').toList();
    final options = GeneratorOptions(
      length: length,
      uppercase: flags[0],
      lowercase: flags[1],
      digits: flags[2],
      symbols: flags[3],
      excludeAmbiguous: flags[4],
    );
    return options.hasAnySet ? options : null;
  }
}

/// Güvenli rastgele şifre üretici.
///
/// GÜVENLİK:
/// - Kaynak: işletim sisteminin CSPRNG'si (`Random.secure`). `nextInt`
///   değerleri eşit dağılımlı üretir (modulo yanlılığı yok).
/// - Seçilen her karakter grubundan en az bir karakter bulunur; ardından
///   Fisher–Yates ile (yine CSPRNG kullanarak) karıştırılır.
/// - Kendi kriptografik algoritmamızı yazmıyoruz; yalnızca CSPRNG'den
///   karakter seçiyoruz.
class PasswordGenerator {
  PasswordGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String digitChars = '0123456789';
  static const String symbolChars = r'!@#$%^&*()-_=+[]{};:,.<>/?~';

  /// Birbirine karışabilecek karakterler.
  static const String ambiguous = 'O0oIl1|';

  /// Seçeneklere göre kullanılacak karakter grupları.
  static List<String> charsets(GeneratorOptions o) {
    String clean(String s) => o.excludeAmbiguous
        ? s.split('').where((c) => !ambiguous.contains(c)).join()
        : s;
    return [
      if (o.uppercase) clean(upper),
      if (o.lowercase) clean(lower),
      if (o.digits) clean(digitChars),
      if (o.symbols) clean(symbolChars),
    ];
  }

  String generate(GeneratorOptions options) {
    if (!options.hasAnySet) {
      throw ArgumentError('En az bir karakter grubu seçilmeli.');
    }
    final length = options.length.clamp(
      GeneratorOptions.minLength,
      GeneratorOptions.maxLength,
    );
    final sets = charsets(options);
    final all = sets.join();

    final chars = <String>[
      // Her gruptan en az bir karakter.
      for (final s in sets) s[_random.nextInt(s.length)],
    ];
    while (chars.length < length) {
      chars.add(all[_random.nextInt(all.length)]);
    }
    // Fisher–Yates karıştırma.
    for (var i = chars.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }
    return chars.join();
  }
}
