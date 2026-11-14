import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_surfaces.dart';

/// Buzlu cam yüzey: altından geçen içeriği bulanıklaştırır ve zemin
/// renginde yarı saydam bir katmanla örter (alt gezinme çubuğu, sabit
/// arama başlığı).
///
/// [enabled] false iken tamamen saydamdır (bulanıklaştırma maliyeti de
/// olmaz); ör. başlığın altından henüz içerik geçmiyorsa.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.enabled = true,
    this.edge = GlassEdge.none,
  });

  final Widget child;
  final bool enabled;

  /// Hangi kenarda ince ayırıcı çizgi ve gölge olsun.
  final GlassEdge edge;

  static const double blur = 20;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final line = s.isDark
        ? s.highlight
        : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5);
    final border = switch (edge) {
      GlassEdge.top => Border(top: BorderSide(color: line)),
      GlassEdge.bottom => Border(bottom: BorderSide(color: line)),
      GlassEdge.none => null,
    };
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: enabled
            ? s.background.withValues(alpha: s.isDark ? 0.70 : 0.72)
            : s.background.withValues(alpha: 0),
        border: enabled ? border : null,
      ),
      child: child,
    );
    if (!enabled) return content;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}

enum GlassEdge { none, top, bottom }
