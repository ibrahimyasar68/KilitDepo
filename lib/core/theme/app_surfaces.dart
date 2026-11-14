import 'package:flutter/material.dart';

/// Zemin, kart ve derinlik (gölge / parıltı) renkleri.
///
/// Tüm ekranlar aynı değerleri buradan okur; açık / koyu / tam siyah ve
/// Material You şemalarından otomatik türetilir.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.background,
    required this.card,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.shadow,
    required this.highlight,
    required this.isDark,
  });

  /// Sayfaların zemini (kartlardan bir ton koyu).
  final Color background;

  /// Kart yüzeyi (zeminden açık; öne çıkar).
  final Color card;

  /// Zemindeki yumuşak ışıma renkleri.
  final Color glowPrimary;
  final Color glowSecondary;

  /// Gölge rengi (açık temada petrol tonlu, koyu temada siyah).
  final Color shadow;

  /// Koyu temada kartların üst kenarındaki ince ışık.
  final Color highlight;

  final bool isDark;

  static const Color _petrolShadow = Color(0xFF0B3D30);

  factory AppSurfaces.fromScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final trueBlack = dark && scheme.surface == Colors.black;
    if (!dark) {
      return AppSurfaces(
        background: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.05),
          scheme.surfaceContainerHigh,
        ),
        card: scheme.surfaceContainerLowest,
        glowPrimary: scheme.primary.withValues(alpha: 0.10),
        glowSecondary: scheme.tertiary.withValues(alpha: 0.07),
        shadow: _petrolShadow,
        highlight: Colors.transparent,
        isDark: false,
      );
    }
    return AppSurfaces(
      background: trueBlack ? Colors.black : scheme.surfaceContainerLowest,
      card: scheme.surfaceContainer,
      glowPrimary: scheme.primary.withValues(alpha: trueBlack ? 0.07 : 0.12),
      glowSecondary: scheme.tertiary.withValues(alpha: trueBlack ? 0.04 : 0.07),
      shadow: Colors.black,
      highlight: Colors.white.withValues(alpha: 0.07),
      isDark: true,
    );
  }

  static AppSurfaces of(BuildContext context) =>
      Theme.of(context).extension<AppSurfaces>() ??
      AppSurfaces.fromScheme(Theme.of(context).colorScheme);

  /// Kartların iki katmanlı yumuşak gölgesi. [pressed]: basılıyken gölge
  /// içeri çekilir; [glow]: verilirse çevresinde renkli parıltı.
  List<BoxShadow> cardShadows({bool pressed = false, Color? glow}) {
    // Kullanıcı isteğiyle (12 Kasım) gölgeler bir kademe belirginleştirildi.
    final a = isDark ? 0.55 : 0.24;
    return [
      if (glow != null)
        BoxShadow(
          color: glow.withValues(alpha: isDark ? 0.45 : 0.35),
          blurRadius: 18,
          spreadRadius: 1,
        ),
      BoxShadow(
        color: shadow.withValues(alpha: pressed ? a * 0.5 : a),
        blurRadius: pressed ? 6 : 22,
        offset: Offset(0, pressed ? 2 : 9),
      ),
      BoxShadow(
        color: shadow.withValues(alpha: isDark ? 0.35 : 0.11),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }

  @override
  AppSurfaces copyWith({
    Color? background,
    Color? card,
    Color? glowPrimary,
    Color? glowSecondary,
    Color? shadow,
    Color? highlight,
    bool? isDark,
  }) => AppSurfaces(
    background: background ?? this.background,
    card: card ?? this.card,
    glowPrimary: glowPrimary ?? this.glowPrimary,
    glowSecondary: glowSecondary ?? this.glowSecondary,
    shadow: shadow ?? this.shadow,
    highlight: highlight ?? this.highlight,
    isDark: isDark ?? this.isDark,
  );

  @override
  AppSurfaces lerp(AppSurfaces? other, double t) {
    if (other == null) return this;
    return AppSurfaces(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      glowPrimary: Color.lerp(glowPrimary, other.glowPrimary, t)!,
      glowSecondary: Color.lerp(glowSecondary, other.glowSecondary, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
