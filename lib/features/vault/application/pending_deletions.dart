import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/vault_repository.dart';
import '../../auth/application/auth_providers.dart';
import 'vault_providers.dart';

/// Silmede "Geri al": kayıt listeden hemen kalkar, veritabanından
/// [undoWindow] sonra silinir.
///
/// GÜVENLİK:
/// - Bekleme süresince hiçbir şifre çözülmez veya bellekte tutulmaz; kayıt
///   zaten şifreli veritabanında durur, yalnızca kimliği (id) tutulur.
/// - Kasa kilitlenince (elle, hareketsizlik veya arka plana geçiş) bekleyen
///   silmeler veritabanı kapanmadan HEMEN tamamlanır ([beforeLockProvider]).
/// - Uygulama tam bu süre içinde zorla kapatılırsa kayıt silinmemiş kalır
///   (kullanıcıyla kabul edilen risk; veri kaybı yönünde değil).
///
/// Durum: listeden gizlenen kayıt kimlikleri. Silinen kayıtların kimliği de
/// oturum boyunca kümede kalır (kimlikler yeniden kullanılmaz); böylece
/// silme ile liste güncellemesi arasında kayıt bir an geri görünmez.
class PendingDeletions extends Notifier<Set<int>> {
  static const Duration undoWindow = Duration(seconds: 5);

  final Map<int, Timer> _timers = {};

  @override
  Set<int> build() {
    final hooks = ref.watch(beforeLockProvider);
    hooks.add(commitAll);
    ref.onDispose(() {
      hooks.remove(commitAll);
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  /// Silmeyi zamanlar; kayıt listeden hemen kalkar.
  void schedule(int id) {
    _timers[id]?.cancel();
    _timers[id] = Timer(undoWindow, () => unawaited(_commit(id)));
    state = {...state, id};
  }

  /// Süre dolmadıysa silmeyi iptal eder; kayıt listeye geri döner.
  bool undo(int id) {
    final timer = _timers.remove(id);
    if (timer == null) return false;
    timer.cancel();
    state = {...state}..remove(id);
    return true;
  }

  /// Bekleyen tüm silmeleri hemen tamamlar (kilitlemeden önce).
  Future<void> commitAll() async {
    for (final id in _timers.keys.toList()) {
      await _commit(id);
    }
  }

  Future<void> _commit(int id) async {
    _timers.remove(id)?.cancel();
    final repo = ref.read(vaultRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.deleteEntry(id);
    } on EntryNotFoundException {
      // Zaten silinmiş.
    }
  }
}

final pendingDeletionsProvider = NotifierProvider<PendingDeletions, Set<int>>(
  PendingDeletions.new,
);
