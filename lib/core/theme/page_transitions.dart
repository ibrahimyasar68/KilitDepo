import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import 'motion.dart';

/// Sayfalar saydam olduğu için, iki sayfanın aynı anda üst üste göründüğü
/// geçişlerde (iOS kayma) her sayfaya kendi zeminini verir.
class OpaquePageTransitionsBuilder extends PageTransitionsBuilder {
  const OpaquePageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    AppBackground(child: child),
  );
}

/// Material 3 "ortak eksen" (shared axis, yatay) sayfa geçişi.
///
/// Açılan sayfa sağdan hafifçe kayarak belirir; alttaki sayfa sola kayarak
/// solar. Geri dönüşte tersi olur. İki sayfa aynı anda yarı saydam
/// görünmesin diye önce eski sayfa solar, sonra yenisi belirir.
/// Sistemde "animasyonları kapat" açıksa geçiş yapılmaz.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _SharedAxisTransition extends StatelessWidget {
  const _SharedAxisTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  /// Kayma mesafesi (Material 3: 30 dp).
  static const double _shift = 30;

  static final _fadeIn = CurveTween(
    curve: const Interval(0.3, 1, curve: Curves.easeOut),
  );
  static final _fadeOut = CurveTween(
    curve: const Interval(0, 0.3, curve: Curves.easeIn),
  );
  // Kayma yayla (Material 3 Expressive "uzamsal yay"); solma düz kalır.
  static final _move = CurveTween(curve: AppMotion.spring);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final enter = animation.value;
        final cover = secondaryAnimation.value;
        // Giriş: sağdan (+30) yerine; üstüne sayfa açılınca: sola (−30).
        final dx =
            _shift * (1 - _move.transform(enter)) -
            _shift * _move.transform(cover);
        final opacity =
            _fadeIn.transform(enter) * (1 - _fadeOut.transform(cover));
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
    );
  }
}

/// Alt gezinme sekmeleri arasında Material 3 "solup belirme" (fade-through)
/// geçişi.
///
/// Her sekmenin gezinme yığını (kaydırma konumu, açık alt sayfalar) korunur:
/// tüm sekmeler ağaçta kalır, yalnızca etkin olan görünür ve dokunulabilir.
/// Gizli sekmelerin animasyonları ([TickerMode]) durdurulur.
class FadeThroughBranches extends StatefulWidget {
  const FadeThroughBranches({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<FadeThroughBranches> createState() => _FadeThroughBranchesState();
}

class _FadeThroughBranchesState extends State<FadeThroughBranches>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );

  /// Solmakta olan önceki sekme (animasyon sürerken).
  int? _previous;

  static final _fadeOut = Tween<double>(
    begin: 1,
    end: 0,
  ).chain(CurveTween(curve: const Interval(0, 0.35, curve: Curves.easeIn)));
  static final _fadeIn = CurveTween(
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );
  static final _scaleIn = Tween<double>(
    begin: 0.94,
    end: 1,
  ).chain(CurveTween(curve: const Interval(0.35, 1, curve: AppMotion.spring)));

  @override
  void didUpdateWidget(FadeThroughBranches old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _previous = null;
      _controller.value = 1;
      return;
    }
    _previous = old.currentIndex;
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted) setState(() => _previous = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _branch(i, widget.children[i]),
      ],
    );
  }

  /// Ağaç yapısı her sekme için hep aynıdır (durum kaybolmasın diye);
  /// yalnızca animasyon değerleri ve görünürlük değişir.
  Widget _branch(int i, Widget child) {
    final active = i == widget.currentIndex;
    final leaving = i == _previous;
    final Animation<double> opacity;
    final Animation<double> scale;
    if (active) {
      opacity = _controller.drive(_fadeIn);
      scale = _controller.drive(_scaleIn);
    } else if (leaving) {
      opacity = _controller.drive(_fadeOut);
      scale = const AlwaysStoppedAnimation(1);
    } else {
      opacity = const AlwaysStoppedAnimation(0);
      scale = const AlwaysStoppedAnimation(1);
    }
    return Offstage(
      offstage: !active && !leaving,
      child: TickerMode(
        enabled: active,
        child: IgnorePointer(
          ignoring: !active,
          child: FadeTransition(
            opacity: opacity,
            child: ScaleTransition(scale: scale, child: child),
          ),
        ),
      ),
    );
  }
}
