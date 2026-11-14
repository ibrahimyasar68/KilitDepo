import 'package:flutter/material.dart';

import '../theme/app_surfaces.dart';

/// Uygulamanın zemini: bir ton koyu taban rengi ve üzerinde yumuşak
/// ışımalar (sol üstte marka yeşili, sağ altta ikincil renk).
///
/// Uygulama kökünde bir kez çizilir; sayfalar saydamdır. Kodla çizilir
/// (görsel dosya yok) ve yeniden çizimi ayrı katmanda tutulur.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  static const Key backgroundKey = Key('app_background');

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: backgroundKey,
          child: DecoratedBox(
            decoration: BoxDecoration(color: s.background),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.1, -1.05),
                  radius: 1.25,
                  colors: [s.glowPrimary, s.glowPrimary.withValues(alpha: 0)],
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.2, 1.1),
                    radius: 1.1,
                    colors: [
                      s.glowSecondary,
                      s.glowSecondary.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
