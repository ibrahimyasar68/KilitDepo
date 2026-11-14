/// Güvenlik davranışı sabitleri (Faz 5'te bir kısmı ayarlanabilir olacak).
abstract final class SecurityParams {
  /// Kopyalanan değerin panodan silinme süresi.
  static const Duration clipboardClearDelay = Duration(seconds: 30);

  /// Kayıt başına saklanan en fazla eski şifre sayısı.
  static const int passwordHistoryLimit = 10;

  /// Varsayılan hareketsizlik kilidi süresi (ayarlanabilir).
  static const Duration defaultAutoLockTimeout = Duration(minutes: 1);

  /// Beklemesiz hatalı deneme hakkı.
  static const int freeUnlockAttempts = 5;

  /// Ücretsiz denemeler bittikten sonraki her hatalı denemede uygulanan
  /// bekleme süreleri. Son değerde sabitlenir.
  static const List<Duration> unlockBackoff = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];
}
