import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/turkish_words.dart';

/// Kelime tabanlı şifre seçenekleri (ör. `Kartal-Limon-Dere-Masa-Bulut-47`).
@immutable
class PassphraseOptions {
  const PassphraseOptions({
    this.wordCount = 6,
    this.separator = '-',
    this.capitalize = true,
    this.addNumber = true,
  });

  static const int minWords = 3;
  static const int maxWords = 8;

  /// Sunulan ayırıcılar. Boşluk bilinçli olarak yok: birçok sitede sorun
  /// çıkarır ve kopyalarken kolayca kaybolur.
  static const List<String> separators = ['-', '.', '_'];

  final int wordCount;
  final String separator;
  final bool capitalize;
  final bool addNumber;

  PassphraseOptions copyWith({
    int? wordCount,
    String? separator,
    bool? capitalize,
    bool? addNumber,
  }) => PassphraseOptions(
    wordCount: wordCount ?? this.wordCount,
    separator: separator ?? this.separator,
    capitalize: capitalize ?? this.capitalize,
    addNumber: addNumber ?? this.addNumber,
  );

  /// Saklamak için kısa metin: `kelime|ayırıcıSırası|büyük|sayı`.
  String encode() => [
    wordCount,
    separators.indexOf(separator),
    if (capitalize) 1 else 0,
    if (addNumber) 1 else 0,
  ].join('|');

  /// [encode] çıktısını çözer; bozuk / sınır dışı değerde `null`.
  static PassphraseOptions? decode(String? raw) {
    final parts = raw?.split('|');
    if (parts == null || parts.length != 4) return null;
    final count = int.tryParse(parts[0]);
    final sep = int.tryParse(parts[1]);
    if (count == null || count < minWords || count > maxWords) return null;
    if (sep == null || sep < 0 || sep >= separators.length) return null;
    return PassphraseOptions(
      wordCount: count,
      separator: separators[sep],
      capitalize: parts[2] == '1',
      addNumber: parts[3] == '1',
    );
  }
}

/// Kelime tabanlı şifre üretici.
///
/// GÜVENLİK:
/// - Kelimeler ve sayı işletim sisteminin CSPRNG'sinden (`Random.secure`)
///   eşit olasılıkla seçilir.
/// - Güç, karakterlerden değil seçim uzayından hesaplanır:
///   kelime sayısı × log2(liste boyutu) (+ sayı varsa log2(100)). Büyük harf
///   ve ayırıcı sabit kurallar olduğu için güce eklenmez (dürüst hesap).
class PassphraseGenerator {
  PassphraseGenerator({Random? random, List<String>? words})
    : _random = random ?? Random.secure(),
      _words = words ?? turkishWords;

  final Random _random;
  final List<String> _words;

  int get wordListSize => _words.length;

  String generate(PassphraseOptions o) {
    final parts = <String>[
      for (var i = 0; i < o.wordCount; i++)
        _format(_words[_random.nextInt(_words.length)], o.capitalize),
      if (o.addNumber) _random.nextInt(100).toString().padLeft(2, '0'),
    ];
    return parts.join(o.separator);
  }

  /// Seçeneklerin sağladığı gerçek entropi (bit).
  double entropyBits(PassphraseOptions o) =>
      o.wordCount * log(_words.length) / ln2 +
      (o.addNumber ? log(100) / ln2 : 0);

  static String _format(String word, bool capitalize) =>
      capitalize ? word[0].toUpperCase() + word.substring(1) : word;
}
