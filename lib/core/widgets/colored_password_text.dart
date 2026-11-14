import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Şifreyi eş genişlikli yazı tipiyle, rakamları ve sembolleri farklı
/// renkte gösterir. 0/O ve 1/l gibi karışan karakterler ayırt edilir.
class ColoredPasswordText extends StatelessWidget {
  const ColoredPasswordText(this.password, {super.key, this.fontSize = 16});

  final String password;
  final double fontSize;

  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _letter = RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]');

  /// Karakter türü: 0 = harf, 1 = rakam, 2 = sembol/boşluk.
  static int kindOf(String ch) {
    if (_digit.hasMatch(ch)) return 1;
    if (_letter.hasMatch(ch)) return 0;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final digitColor = dark ? const Color(0xFF85B7EB) : const Color(0xFF185FA5);
    final symbolColor = dark
        ? const Color(0xFFF0997B)
        : const Color(0xFF993C1D);
    final base = TextStyle(
      fontFamily: AppTheme.monoFontFamily,
      fontSize: fontSize,
      letterSpacing: 0.5,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (final ch in password.characters)
            TextSpan(
              text: ch,
              style: switch (kindOf(ch)) {
                1 => TextStyle(color: digitColor),
                2 => TextStyle(color: symbolColor),
                _ => null,
              },
            ),
        ],
      ),
      semanticsLabel: password,
    );
  }
}
