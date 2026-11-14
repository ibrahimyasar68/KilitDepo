import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Çocuk değişince (anahtarı farklı olunca) yeni hâli yayla "zıplatarak"
/// gösterir (ör. favori yıldızı). İlk gösterimde animasyon yapılmaz.
/// "Animasyonları kapat" açıksa anında değişir.
class SpringSwap extends StatelessWidget {
  const SpringSwap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      // Animasyonlar kapalıysa eski ve yeni hâl bir an bile üst üste
      // görünmesin: doğrudan yeni hâl.
      MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSwitcher(
          duration: AppMotion.of(context),
          reverseDuration: AppMotion.of(
            context,
            const Duration(milliseconds: 120),
          ),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: AppMotion.spring),
            child: child,
          ),
          child: child,
        );
}
