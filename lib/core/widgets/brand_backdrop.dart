import 'package:flutter/material.dart';

/// Giriş ve kurulum ekranlarının arka planı: üstte marka renginden zemine
/// yumuşak bir geçiş ve hafif bir ışıma. Kodla çizilir (görsel dosya yok),
/// temanın renklerini kullanır.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});

  final Widget child;

  static const Key backdropKey = Key('brand_backdrop');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          key: backdropKey,
          top: 0,
          left: 0,
          right: 0,
          height: 360,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.75),
                    scheme.surface.withValues(alpha: 0),
                  ],
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.9, -1.1),
                    radius: 1.1,
                    colors: [
                      scheme.tertiaryContainer.withValues(alpha: 0.55),
                      scheme.tertiaryContainer.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
