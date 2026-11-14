import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_surfaces.dart';
import 'page_transitions.dart';

/// Material 3 tema (açık / koyu).
///
/// Ana renk petrol yeşili: güven çağrıştırır ve şifre yöneticilerinde
/// yaygın olan maviden ayrışır. Köşeler yumuşak (16), yüzeyler kart tabanlı.
abstract final class AppTheme {
  static const Color seed = Color(0xFF0F6E56);

  /// Kart, buton (FAB) ve panel köşeleri (Material 3 Expressive: daha
  /// yumuşak, büyük köşeler).
  static const double radius = 20;

  /// Metin alanlarının köşesi (alanlar fazla yuvarlak olunca okunurluk düşer).
  static const double fieldRadius = 16;

  /// Hap biçimli düğmeler basılınca bu köşeye "sertleşir" (şekil değişimi).
  static const double pressedButtonRadius = 12;

  /// Düğmelerin şekli: normalde hap, basılıyken köşeli dikdörtgene yakın.
  /// Material düğmeleri şekil değişimini kendisi canlandırır.
  static final WidgetStateProperty<OutlinedBorder> buttonShape =
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(pressedButtonRadius),
              )
            : const StadiumBorder(),
      );

  /// Arayüz ve şifre yazı tipleri (pubspec.yaml'da gömülü).
  static const String fontFamily = 'Inter';
  static const String monoFontFamily = 'JetBrainsMono';

  // Marka temaları bir kez hesaplanır: `ColorScheme.fromSeed` ton paleti
  // üretir ve uygulama kökü her yeniden çizildiğinde tekrarlanmamalıdır.
  static final ThemeData _light = _build(
    ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
  );
  static final ThemeData _dark = _build(
    ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
  );

  static final ThemeData _black = _build(
    trueBlack(
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
    ),
  );

  static ThemeData light() => _light;

  /// Koyu tema; [black] açıksa zemin tam siyah (AMOLED).
  static ThemeData dark({bool black = false}) => black ? _black : _dark;

  /// Verilen renk şemasıyla tema (Material You için).
  static ThemeData fromScheme(ColorScheme scheme) => _build(scheme);

  /// Koyu şemanın yüzeylerini tam siyaha çeker. Kartlar ve paneller
  /// zeminden ayırt edilsin diye kademeli olarak çok koyu griler kullanır.
  /// OLED ekranlarda siyah pikseller ışık yaymaz (pil tasarrufu).
  static ColorScheme trueBlack(ColorScheme scheme) => scheme.copyWith(
    surface: Colors.black,
    surfaceDim: Colors.black,
    surfaceContainerLowest: Colors.black,
    surfaceContainerLow: const Color(0xFF0B0B0B),
    surfaceContainer: const Color(0xFF121212),
    surfaceContainerHigh: const Color(0xFF1A1A1A),
    surfaceContainerHighest: const Color(0xFF242424),
  );

  static ThemeData _build(ColorScheme scheme) {
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final surfaces = AppSurfaces.fromScheme(scheme);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      extensions: [surfaces],
      // Sayfalar saydam: zemin ve ışıma uygulama kökünde tek katman olarak
      // çizilir (AppBackground). Geçişlerde iki sayfa arasında zemin sabit
      // kalır.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: surfaces.background,
      // Başlık çubukları zeminin üzerinde saydam; altından içerik geçince
      // zemin renginde opak bir yüzeye döner (bulanıklık olmadan yarı
      // saydamlık, altındaki yazıyı "hayalet" gibi gösteriyordu).
      appBarTheme: AppBarTheme(
        backgroundColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.scrolledUnder)
              ? surfaces.background
              : Colors.transparent,
        ),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ).copyWith(shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      // Kartlar zeminden açık ve yumuşak gölgeli (açık tema). Koyu temada
      // gölge görünmediği için ince bir ışık kenarı derinlik verir.
      cardTheme: CardThemeData(
        elevation: surfaces.isDark ? 0 : 3,
        shadowColor: surfaces.shadow.withValues(alpha: 0.55),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: surfaces.isDark
              ? BorderSide(color: surfaces.highlight)
              : BorderSide.none,
        ),
        color: surfaces.card,
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: rounded,
        elevation: 2,
        highlightElevation: 1,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaces.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      // Sayfa geçişleri: Android'de Material 3 ortak eksen; iOS'ta sistemin
      // kendi geçişi (kenardan kaydırarak geri dönme hareketi korunur).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SharedAxisPageTransitionsBuilder(),
          TargetPlatform.linux: SharedAxisPageTransitionsBuilder(),
          TargetPlatform.windows: SharedAxisPageTransitionsBuilder(),
          // Kayan geçişte iki sayfa üst üste görünür: her sayfa kendi
          // zeminini taşır.
          TargetPlatform.iOS: OpaquePageTransitionsBuilder(
            CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.macOS: OpaquePageTransitionsBuilder(
            CupertinoPageTransitionsBuilder(),
          ),
        },
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
        ),
      ),
    );
    return base.copyWith(textTheme: _textTheme(base.textTheme));
  }

  /// Uygulamaya özgü yazı ölçeği: başlıklar daha kalın ve sıkı, gövde
  /// metni biraz daha ferah. Büyük sayılarda eşit genişlikli rakamlar
  /// kullanılır (geri sayım ve puan değişirken metin kıpırdamaz).
  static TextTheme _textTheme(TextTheme t) {
    const tabular = [FontFeature.tabularFigures()];
    TextStyle? heading(TextStyle? s, double spacing) => s?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: spacing,
      fontFeatures: tabular,
    );
    TextStyle? title(TextStyle? s, double spacing) =>
        s?.copyWith(fontWeight: FontWeight.w600, letterSpacing: spacing);
    TextStyle? body(TextStyle? s) => s?.copyWith(height: 1.45);
    return t.copyWith(
      displayLarge: heading(t.displayLarge, -1),
      displayMedium: heading(t.displayMedium, -0.8),
      displaySmall: heading(t.displaySmall, -0.6),
      headlineLarge: heading(t.headlineLarge, -0.5),
      headlineMedium: heading(t.headlineMedium, -0.4),
      headlineSmall: heading(t.headlineSmall, -0.3),
      titleLarge: title(t.titleLarge, -0.2),
      titleMedium: title(t.titleMedium, -0.1),
      titleSmall: title(t.titleSmall, 0),
      labelLarge: title(t.labelLarge, 0.1),
      bodyLarge: body(t.bodyLarge),
      bodyMedium: body(t.bodyMedium),
    );
  }
}
