import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Uygulamanın hareket dili (Material 3 Expressive yönünde yay fiziği).
abstract final class AppMotion {
  /// Hafif esneyen, hızlı yerleşen yay: çubuk ve buton boyut geçişleri.
  static const Curve spring = SpringCurve();

  static const Duration springDuration = Duration(milliseconds: 420);

  /// "Animasyonları kapat" açıksa sıfır süre.
  static Duration of(BuildContext context, [Duration d = springDuration]) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// Kritik altı sönümlü bir yay simülasyonunu [Curve] olarak sunar: hedefe
/// hızla gider, çok az aşar ve yerleşir.
class SpringCurve extends Curve {
  const SpringCurve({this.stiffness = 260, this.dampingRatio = 0.78});

  final double stiffness;
  final double dampingRatio;

  /// Eğrinin karşılık geldiği simülasyon süresi (saniye).
  static const double _seconds = 0.42;

  @override
  double transformInternal(double t) {
    final sim = SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: stiffness,
        ratio: dampingRatio,
      ),
      0,
      1,
      0,
    );
    return sim.x(t * _seconds);
  }
}
