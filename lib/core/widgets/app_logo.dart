import 'package:flutter/material.dart';

import '../constants/app_info.dart';
import '../theme/app_theme.dart';

/// KilitDepo logosu: ortasında anahtar deliği olan kasa kapısı.
///
/// [showName] açıkken altında "KilitDepo" yazısı gösterilir.
/// "İY Labs" etiketi logonun ayrılmaz bir parçasıdır: kutucuğun İÇİNDE,
/// sağ alt köşede yer alır (SVG logo ve uygulama simgeleriyle aynı düzen)
/// ve logoyla birlikte ölçeklenir. Etiketsiz logo kullanılmaz. Çizim kod ile yapılır (ek paket yok);
/// uygulama ikonları aynı geometriden `tool/generate_brand_assets.py`
/// ile üretilir.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.showName = true});

  /// Kasa çiziminin yaklaşık boyutu; kutucuk bunun 1,5 katıdır.
  final double size;
  final bool showName;

  static const Key producerTagKey = Key('logo_producer_tag');

  /// Koyu temadaki kutucuk ve çizgi renkleri (tasarımdaki "Gece" sürümü).
  static const Color _darkTile = Color(0xFF1B2A26);
  static const Color _mint = Color(0xFF5DCAA5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileColor = isDark ? _darkTile : AppTheme.seed;
    final glyphColor = isDark ? _mint : Colors.white;
    final accent = isDark ? _mint : AppTheme.seed;
    final tile = size * 1.5;

    return Semantics(
      label: AppInfo.appName,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: tile,
            height: tile,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(tile * 0.233),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(tile * 0.68),
                  painter: VaultKeyholePainter(
                    color: glyphColor,
                    // Küçük boyutlarda menteşe ve ayaklar okunmaz; çizilmez.
                    showDetails: tile >= 64,
                  ),
                ),
                Positioned(
                  right: tile * 0.07,
                  bottom: tile * 0.065,
                  child: _ProducerTag(
                    key: producerTagKey,
                    tile: tile,
                    color: glyphColor,
                  ),
                ),
              ],
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 16),
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Kilit',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: 'Depo',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Logonun içindeki "İY Labs" etiketi: yarı saydam hap üzerinde yazı.
/// Boyutları kutucuğa oranlıdır (SVG logo: 360 birimlik kutucukta
/// 108×38 hap, 20 birim yazı).
class _ProducerTag extends StatelessWidget {
  const _ProducerTag({super.key, required this.tile, required this.color});

  final double tile;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: tile * 0.13,
    padding: EdgeInsets.symmetric(horizontal: tile * 0.045),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(tile),
    ),
    child: Text(
      AppInfo.producerLabel,
      textScaler: TextScaler.noScaling, // logonun parçası; ölçeklenmez
      style: TextStyle(
        color: color,
        fontSize: tile * 0.075,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
  );
}

/// Kasa kapısı + anahtar deliği çizimi, 100×100 birimlik ızgarada.
class VaultKeyholePainter extends CustomPainter {
  const VaultKeyholePainter({required this.color, this.showDetails = true});

  final Color color;
  final bool showDetails;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = showDetails ? 6 : 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Kasa gövdesi.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 20, 64, 58),
        const Radius.circular(10),
      ),
      stroke,
    );

    if (showDetails) {
      // Menteşeler ve ayaklar.
      canvas
        ..drawLine(const Offset(13, 34), const Offset(13, 42), stroke)
        ..drawLine(const Offset(13, 56), const Offset(13, 64), stroke)
        ..drawLine(const Offset(32, 78), const Offset(32, 84), stroke)
        ..drawLine(const Offset(72, 78), const Offset(72, 84), stroke);
    }

    // Anahtar deliği (küçük boyutlarda daha iri, okunsun diye).
    if (showDetails) {
      canvas.drawCircle(const Offset(52, 44), 7, fill);
      canvas.drawPath(
        Path()
          ..moveTo(48.5, 48)
          ..lineTo(55.5, 48)
          ..lineTo(58.5, 62)
          ..lineTo(45.5, 62)
          ..close(),
        fill,
      );
    } else {
      canvas.drawCircle(const Offset(52, 43), 10, fill);
      canvas.drawPath(
        Path()
          ..moveTo(47, 49)
          ..lineTo(57, 49)
          ..lineTo(61, 68)
          ..lineTo(43, 68)
          ..close(),
        fill,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(VaultKeyholePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.showDetails != showDetails;
}
