import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/data/repositories/unlock_attempt_limiter.dart';

import '../helpers/in_memory_store.dart';

void main() {
  late InMemorySecureStore store;
  late DateTime now;
  late UnlockAttemptLimiter limiter;

  setUp(() {
    store = InMemorySecureStore();
    now = DateTime(2026, 5, 1, 12);
    limiter = UnlockAttemptLimiter(store, clock: () => now);
  });

  Future<Duration?> failAndWait() async {
    final until = await limiter.recordFailure();
    return until?.difference(now);
  }

  test('ilk 4 hatada bekleme yok, 5. hatadan itibaren artan bekleme', () async {
    for (var i = 0; i < 4; i++) {
      expect(await failAndWait(), isNull);
    }
    expect(await limiter.lockedUntil(), isNull);
    expect(await failAndWait(), const Duration(seconds: 30)); // 5.
    expect(await failAndWait(), const Duration(minutes: 1)); // 6.
    expect(await failAndWait(), const Duration(minutes: 5)); // 7.
    expect(await failAndWait(), const Duration(minutes: 15)); // 8.
    expect(await failAndWait(), const Duration(hours: 1)); // 9.
    expect(await failAndWait(), const Duration(hours: 1)); // sabit
  });

  test('bekleme süresi dolunca tekrar denenebilir', () async {
    for (var i = 0; i < 5; i++) {
      await limiter.recordFailure();
    }
    expect(await limiter.lockedUntil(), now.add(const Duration(seconds: 30)));
    now = now.add(const Duration(seconds: 30));
    expect(await limiter.lockedUntil(), isNull);
  });

  test('sayaç kalıcıdır (yeni nesne aynı depodan okur)', () async {
    for (var i = 0; i < 5; i++) {
      await limiter.recordFailure();
    }
    final restarted = UnlockAttemptLimiter(store, clock: () => now);
    expect(await restarted.failureCount(), 5);
    expect(await restarted.lockedUntil(), isNotNull);
  });

  test('başarıda sıfırlanır', () async {
    for (var i = 0; i < 6; i++) {
      await limiter.recordFailure();
    }
    await limiter.reset();
    expect(await limiter.failureCount(), 0);
    expect(await limiter.lockedUntil(), isNull);
  });

  test('saat geri alınırsa bekleme 1 saatle sınırlanır', () async {
    for (var i = 0; i < 9; i++) {
      await limiter.recordFailure();
    }
    now = now.subtract(const Duration(days: 30));
    final until = await limiter.lockedUntil();
    expect(until!.difference(now), const Duration(hours: 1));
  });

  test('bozuk kayıt sayacı sıfırlamaz, en sıkı kademeyi uygular', () async {
    store.data[UnlockAttemptLimiter.storageKey] = 'bozuk{';
    final until = await limiter.lockedUntil();
    expect(until!.difference(now), const Duration(hours: 1));
  });
}
