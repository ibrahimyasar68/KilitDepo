import 'package:flutter/material.dart';

import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Derinlikli kart: iki katmanlı yumuşak gölge (açık tema) veya üst kenarda
/// ince ışık (koyu tema).
///
/// - [pressable]: parmak değdiğinde kart hafifçe küçülür ve gölgesi içeri
///   çekilir ("bastırma" hissi). Dokunma olaylarını tüketmez; içteki
///   düğmeler ve kaydırma hareketleri aynen çalışır.
/// - [glow]: verilirse kartın çevresinde o renkte parıltı (ör. seçili kart).
///
/// "Animasyonları kapat" açıksa basma animasyonu yapılmaz.
class DepthCard extends StatefulWidget {
  const DepthCard({
    super.key,
    required this.child,
    this.color,
    this.glow,
    this.pressable = false,
  });

  final Widget child;
  final Color? color;
  final Color? glow;
  final bool pressable;

  @override
  State<DepthCard> createState() => _DepthCardState();
}

class _DepthCardState extends State<DepthCard> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final pressed = _down && animate;
    final radius = BorderRadius.circular(AppTheme.radius);
    const duration = Duration(milliseconds: 140);

    Widget card = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: widget.color ?? s.card,
        borderRadius: radius,
        boxShadow: s.cardShadows(pressed: pressed, glow: widget.glow),
        border: s.isDark ? Border.all(color: s.highlight) : null,
      ),
      // Koyu temada üst kenardan aşağı doğru sönen ince ışık.
      foregroundDecoration: s.isDark
          ? BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, -0.2),
                colors: [s.highlight, s.highlight.withValues(alpha: 0)],
              ),
            )
          : null,
      child: ClipRRect(
        borderRadius: radius,
        child: Material(type: MaterialType.transparency, child: widget.child),
      ),
    );

    if (widget.pressable && animate) {
      card = Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        // Kaydırma başlayınca basma bırakılır.
        onPointerMove: (e) {
          if (e.delta.distanceSquared > 4) _set(false);
        },
        // Basınca hızla küçülür; bırakınca yayla, hafifçe esneyerek
        // yerine oturur.
        child: AnimatedScale(
          scale: pressed ? 0.97 : 1,
          duration: pressed ? duration : AppMotion.springDuration,
          curve: pressed ? Curves.easeOut : AppMotion.spring,
          child: card,
        ),
      );
    }
    return card;
  }
}

/// Öne çıkan öğelerin (ör. "+ Ekle" butonu) çevresinde yumuşak parıltı.
class GlowBox extends StatelessWidget {
  const GlowBox({super.key, required this.child, this.color});

  final Widget child;

  /// Varsayılan: temanın ana rengi.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final c = color ?? Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: s.isDark ? 0.35 : 0.30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
