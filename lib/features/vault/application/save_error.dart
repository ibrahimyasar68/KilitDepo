// DriftRemoteException yalnızca bu kütüphaneden dışa açılıyor (deneysel
// işaretli); yalnızca türünü kontrol edip asıl hatayı çıkarmak için kullanılır.
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../../../core/crypto/crypto_exceptions.dart';

/// Kayıt kaydedilemediğinde kullanıcıya gösterilecek neden.
enum SaveFailureKind {
  locked,
  invalid,
  storageFull,
  busy,
  database,
  crypto,
  unknown,
}

/// Hata → neden. Hiçbir gizli veri (şifre, not, başlık) mesaja konmaz;
/// yalnızca hata türü ve SQLite sonuç kodu kullanılır.
({SaveFailureKind kind, String detail}) classifySaveError(Object error) {
  var e = error;
  // Veritabanı arka plan izolatında çalışır: asıl hata sarmalanmış gelir.
  if (e is DriftRemoteException) e = e.remoteCause;

  if (e is StateError) return (kind: SaveFailureKind.locked, detail: '');
  if (e is ArgumentError) return (kind: SaveFailureKind.invalid, detail: '');
  if (e is CryptoException) return (kind: SaveFailureKind.crypto, detail: '');
  if (e is SqliteException) {
    final code = e.resultCode;
    return switch (code) {
      13 => (kind: SaveFailureKind.storageFull, detail: '$code'), // SQLITE_FULL
      5 || 6 => (kind: SaveFailureKind.busy, detail: '$code'), // BUSY / LOCKED
      _ => (kind: SaveFailureKind.database, detail: '${e.extendedResultCode}'),
    };
  }
  return (kind: SaveFailureKind.unknown, detail: e.runtimeType.toString());
}
