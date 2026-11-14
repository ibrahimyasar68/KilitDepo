import 'package:flutter/material.dart';

import '../utils/turkish_text.dart';

/// Kaydın baş harfini renkli bir yuvarlak içinde gösterir.
///
/// Renk başlıktan deterministik olarak hesaplanır: aynı kayıt her zaman
/// aynı rengi alır. Paletin açık/koyu tema karşılıkları vardır.
class LetterAvatar extends StatelessWidget {
  const LetterAvatar({super.key, required this.title, this.size = 40});

  final String title;
  final double size;

  /// (açık zemin, açık metin, koyu zemin, koyu metin)
  static const List<(Color, Color, Color, Color)> _palette = [
    (
      Color(0xFFEEEDFE),
      Color(0xFF3C3489),
      Color(0xFF3C3489),
      Color(0xFFCECBF6),
    ),
    (
      Color(0xFFFAECE7),
      Color(0xFF712B13),
      Color(0xFF712B13),
      Color(0xFFF5C4B3),
    ),
    (
      Color(0xFFE6F1FB),
      Color(0xFF0C447C),
      Color(0xFF0C447C),
      Color(0xFFB5D4F4),
    ),
    (
      Color(0xFFE1F5EE),
      Color(0xFF085041),
      Color(0xFF085041),
      Color(0xFF9FE1CB),
    ),
    (
      Color(0xFFFBEAF0),
      Color(0xFF72243E),
      Color(0xFF72243E),
      Color(0xFFF4C0D1),
    ),
    (
      Color(0xFFFAEEDA),
      Color(0xFF633806),
      Color(0xFF633806),
      Color(0xFFFAC775),
    ),
    (
      Color(0xFFEAF3DE),
      Color(0xFF27500A),
      Color(0xFF27500A),
      Color(0xFFC0DD97),
    ),
  ];

  /// Gösterilecek harf (Türkçe büyük harf kurallarıyla).
  static String initialOf(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return '?';
    final first = trimmed.characters.first;
    return switch (first) {
      'i' => 'İ',
      'ı' => 'I',
      _ => first.toUpperCase(),
    };
  }

  /// Başlığa göre sabit palet indeksi (büyük/küçük harf duyarsız).
  static int colorIndexOf(String title) {
    var hash = 0;
    for (final unit in TurkishText.lower(title.trim()).codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % _palette.length;
  }

  /// Rozet şekli: köşeleri yumuşak kare (uygulama simgesindeki kutucukla
  /// uyumlu; Material 3 Expressive şekilleri).
  static BorderRadius shapeOf(double size) => BorderRadius.circular(size * 0.3);

  /// Başlıktan türetilen (zemin, ön plan) renkleri.
  static (Color, Color) colorsFor(String title, Brightness brightness) {
    final (lightBg, lightFg, darkBg, darkFg) = _palette[colorIndexOf(title)];
    return brightness == Brightness.dark
        ? (darkBg, darkFg)
        : (lightBg, lightFg);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (lightBg, lightFg, darkBg, darkFg) = _palette[colorIndexOf(title)];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? darkBg : lightBg,
        borderRadius: shapeOf(size),
      ),
      child: Text(
        initialOf(title),
        style: TextStyle(
          color: dark ? darkFg : lightFg,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
