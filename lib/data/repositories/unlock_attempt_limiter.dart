import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/constants/security_params.dart';
import '../../core/storage/secure_key_value_store.dart';

/// Hatalı ana şifre denemelerini sınırlar (artan bekleme süresi).
///
/// Sayaç güvenli depoda tutulur; uygulama kapatılıp açılsa da korunur.
///
/// SINIRLAR (bilinçli): Bu, uygulama arayüzünden yapılan denemelere karşı
/// bir korumadır. Cihaz saati ileri alınarak bekleme kısaltılabilir;
/// cihaz verisini kopyalayan bir saldırgan bu sınırı tamamen atlar. Asıl
/// koruma Argon2id maliyeti ve güçlü ana şifredir. Saat GERİ alınırsa
/// bekleme en fazla son kademe süresine kırpılır.
class UnlockAttemptLimiter {
  UnlockAttemptLimiter(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const String storageKey = 'auth.unlock_attempts.v1';

  final SecureKeyValueStore _store;
  final DateTime Function() _clock;

  /// Bekleme bitiş zamanı; bekleme yoksa null.
  Future<DateTime?> lockedUntil() async {
    final state = await _read();
    final until = state.lockedUntil;
    if (until == null) return null;
    final now = _clock();
    if (!until.isAfter(now)) return null;
    final cap = now.add(SecurityParams.unlockBackoff.last);
    return until.isAfter(cap) ? cap : until;
  }

  /// Hatalı denemeyi kaydeder ve (varsa) yeni bekleme bitişini döndürür.
  Future<DateTime?> recordFailure() async {
    final state = await _read();
    final failures = state.failures + 1;
    DateTime? until;
    final over = failures - SecurityParams.freeUnlockAttempts;
    if (over >= 0) {
      final table = SecurityParams.unlockBackoff;
      until = _clock().add(
        table[over < table.length ? over : table.length - 1],
      );
    }
    await _store.write(
      storageKey,
      jsonEncode({'f': failures, 'u': until?.toUtc().toIso8601String()}),
    );
    return until;
  }

  @visibleForTesting
  Future<int> failureCount() async => (await _read()).failures;

  Future<void> reset() => _store.delete(storageKey);

  Future<({int failures, DateTime? lockedUntil})> _read() async {
    final raw = await _store.read(storageKey);
    if (raw == null) return (failures: 0, lockedUntil: null);
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final u = json['u'] as String?;
      return (
        failures: json['f'] as int,
        lockedUntil: u == null ? null : DateTime.parse(u).toLocal(),
      );
    } on Object {
      // Bozuk kayıt: sayacı sıfırlamak yerine en sıkı kademeyi uygula.
      return (
        failures:
            SecurityParams.freeUnlockAttempts +
            SecurityParams.unlockBackoff.length,
        lockedUntil: _clock().add(SecurityParams.unlockBackoff.last),
      );
    }
  }
}
