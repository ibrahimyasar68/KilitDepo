import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Kopyalama düğmelerine kısa bir onay animasyonu ekler: kopyalandıktan
/// sonra simge ~1,5 saniye ✓ işaretine döner.
///
/// Zamanlayıcı yerine animasyon denetleyicisi kullanılır (widget kalkınca
/// birlikte durur). "Animasyonları kapat" açıksa da ✓ gösterilir, yalnızca
/// geçiş efekti yapılmaz.
class CopyFeedback extends StatefulWidget {
  const CopyFeedback({super.key, required this.onCopy, required this.builder});

  /// Asıl kopyalama işi. Başarıyla biterse ✓ gösterilir.
  final Future<void> Function() onCopy;

  /// [icon]: o anki simge (kopyala / ✓), [onPressed]: düğmeye bağlanacak
  /// işlev.
  final Widget Function(
    BuildContext context,
    Widget icon,
    VoidCallback onPressed,
  )
  builder;

  static const Duration showFor = Duration(milliseconds: 1500);

  @override
  State<CopyFeedback> createState() => _CopyFeedbackState();
}

class _CopyFeedbackState extends State<CopyFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CopyFeedback.showFor,
  )..addStatusListener((_) => setState(() {}));

  Future<void> _handle() async {
    await widget.onCopy();
    if (mounted) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copied = _controller.isAnimating;
    final icon = AnimatedSwitcher(
      duration: AppMotion.of(context, const Duration(milliseconds: 380)),
      // ✓ yayla "zıplayarak" belirir (ölçek 1'i hafifçe aşar).
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: AppMotion.spring),
        child: child,
      ),
      child: Icon(
        copied ? Icons.check_rounded : Icons.copy_rounded,
        key: ValueKey(copied),
      ),
    );
    return widget.builder(context, icon, _handle);
  }
}
