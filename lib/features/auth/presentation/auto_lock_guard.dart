import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/security_params.dart';
import '../application/auth_controller.dart';
import '../application/auth_providers.dart';

/// Otomatik kilidi geçici olarak durduran işlem sayısı (ör. sistem dosya
/// seçicisi açıkken; seçici uygulamayı arka plana alır).
class AutoLockSuspension extends Notifier<int> {
  @override
  int build() => 0;

  void begin() => state = state + 1;
  void end() => state = state > 0 ? state - 1 : 0;
}

final autoLockSuspensionProvider = NotifierProvider<AutoLockSuspension, int>(
  AutoLockSuspension.new,
);

/// [action] çalışırken arka plana geçiş kilidi uygulanmaz.
///
/// GÜVENLİK: Kullanıcı seçici açıkken uygulamadan uzun süre ayrılırsa
/// (hareketsizlik süresinden uzun), geri döndüğünde kasa yine kilitlenir.
Future<T> runWithAutoLockSuspended<T>(
  WidgetRef ref,
  Future<T> Function() action,
) async {
  final suspension = ref.read(autoLockSuspensionProvider.notifier);
  suspension.begin();
  try {
    return await action();
  } finally {
    suspension.end();
  }
}

/// Otomatik kilit:
/// 1. Uygulama arka plana geçtiğinde (gizlendiğinde) kasa HEMEN kilitlenir.
///    Biyometrik istem gibi sistem pencereleri yalnızca "pasif" duruma
///    geçirir ve kilidi tetiklemez.
/// 2. Kasa açıkken ekrana dokunulmadan [autoLockTimeoutProvider] süresi
///    geçerse kilitlenir. Her dokunuş süreyi sıfırlar.
///
/// Otomatik kilitte pano temizlenmez (30 sn kuralı geçerlidir); aksi
/// hâlde şifreyi kopyalayıp başka uygulamaya geçmek mümkün olmazdı.
class AutoLockGuard extends ConsumerStatefulWidget {
  const AutoLockGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoLockGuard> createState() => _AutoLockGuardState();
}

class _AutoLockGuardState extends ConsumerState<AutoLockGuard> {
  late final AppLifecycleListener _lifecycle;
  Timer? _idleTimer;
  DateTime? _hiddenWhileSuspendedAt;

  bool get _unlocked =>
      ref.read(authControllerProvider).status == AuthStatus.unlocked;

  bool get _suspended => ref.read(autoLockSuspensionProvider) > 0;

  Duration get _timeout =>
      ref.read(autoLockTimeoutProvider).value ??
      SecurityParams.defaultAutoLockTimeout;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restartIdleTimer());
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _onHide() {
    if (_suspended) {
      // Sistem seçicisi açık: kilitleme, ama ne zaman gizlendiğini not et.
      _hiddenWhileSuspendedAt = DateTime.now();
      _idleTimer?.cancel();
      return;
    }
    _lockNow();
  }

  void _onShow() {
    final hiddenAt = _hiddenWhileSuspendedAt;
    _hiddenWhileSuspendedAt = null;
    if (hiddenAt != null && DateTime.now().difference(hiddenAt) > _timeout) {
      _lockNow();
      return;
    }
    _restartIdleTimer();
  }

  void _lockNow() {
    _idleTimer?.cancel();
    if (_unlocked) {
      ref
          .read(authControllerProvider.notifier)
          .lock(reason: LockReason.automatic);
    }
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    if (!mounted || !_unlocked) return;
    _idleTimer = Timer(_timeout, () {
      // Seçici açıkken hareketsizlik kilidi de ertelenir.
      if (_suspended) {
        _restartIdleTimer();
      } else {
        _lockNow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      authControllerProvider.select((s) => s.status),
      (_, _) => _restartIdleTimer(),
    );
    ref.listen(autoLockTimeoutProvider, (_, _) => _restartIdleTimer());
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restartIdleTimer(),
      child: widget.child,
    );
  }
}
