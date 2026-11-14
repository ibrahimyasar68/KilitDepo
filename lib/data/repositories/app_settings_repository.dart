import 'package:flutter/material.dart';

import '../../core/constants/security_params.dart';
import '../../core/storage/secure_key_value_store.dart';

/// Uygulama ayarları. Hiçbiri gizli değildir; kasa açılmadan da (ör. tema
/// giriş ekranında) okunabilmeleri için güvenli depodaki meta veri alanında
/// tutulurlar.
class AppSettingsRepository {
  AppSettingsRepository(this._store);

  static const String autoLockKey = 'settings.auto_lock_seconds';
  static const String clipboardKey = 'settings.clipboard_seconds';
  static const String themeKey = 'settings.theme';
  static const String lastBackupKey = 'settings.last_backup_at';
  static const String guidePromptKey = 'settings.guide_prompt_shown';
  static const String dynamicColorKey = 'settings.dynamic_color';
  static const String generatorKey = 'settings.generator';
  static const String passphraseKey = 'settings.passphrase';
  static const String generatorModeKey = 'settings.generator_mode';
  static const String trueBlackKey = 'settings.true_black';

  /// Ayarlar ekranında sunulan seçenekler. "Hiçbir zaman" bilinçli olarak
  /// yoktur: otomatik kilit ve pano temizleme tartışmasız gereksinimdir.
  static const List<Duration> autoLockOptions = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 30),
  ];

  static const List<Duration> clipboardOptions = [
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 45),
    Duration(seconds: 60),
    Duration(seconds: 90),
  ];

  final SecureKeyValueStore _store;

  Future<Duration> autoLockTimeout() => _readDuration(
    autoLockKey,
    autoLockOptions,
    SecurityParams.defaultAutoLockTimeout,
  );

  Future<void> setAutoLockTimeout(Duration value) =>
      _writeDuration(autoLockKey, value, autoLockOptions);

  Future<Duration> clipboardClearDelay() => _readDuration(
    clipboardKey,
    clipboardOptions,
    SecurityParams.clipboardClearDelay,
  );

  Future<void> setClipboardClearDelay(Duration value) =>
      _writeDuration(clipboardKey, value, clipboardOptions);

  Future<ThemeMode> themeMode() async {
    final raw = await _store.read(themeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _store.write(themeKey, mode.name);

  /// Son başarılı yedeğin tarihi (yalnızca tarih saklanır).
  Future<DateTime?> lastBackupAt() async {
    final raw = await _store.read(lastBackupKey);
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  Future<void> setLastBackupAt(DateTime value) =>
      _store.write(lastBackupKey, value.toUtc().toIso8601String());

  /// Material You: renkler duvar kağıdından alınsın mı? (Varsayılan:
  /// kapalı; marka rengi petrol yeşili korunur.)
  Future<bool> dynamicColor() async =>
      (await _store.read(dynamicColorKey)) == 'true';

  Future<void> setDynamicColor(bool value) =>
      _store.write(dynamicColorKey, '$value');

  /// Şifre üreticinin son seçenekleri (kodlanmış metin; çözümü
  /// `GeneratorOptions.decode`). Üretilen şifre ASLA saklanmaz.
  Future<String?> generatorOptions() => _store.read(generatorKey);

  Future<void> setGeneratorOptions(String encoded) =>
      _store.write(generatorKey, encoded);

  /// Kelime tabanlı üreticinin son seçenekleri (kodlanmış metin).
  Future<String?> passphraseOptions() => _store.read(passphraseKey);

  Future<void> setPassphraseOptions(String encoded) =>
      _store.write(passphraseKey, encoded);

  /// Üreticinin son kipi ("random" / "words").
  Future<String?> generatorMode() => _store.read(generatorModeKey);

  Future<void> setGeneratorMode(String mode) =>
      _store.write(generatorModeKey, mode);

  /// Koyu temada tam siyah zemin (AMOLED). Varsayılan: kapalı.
  Future<bool> trueBlack() async => (await _store.read(trueBlackKey)) == 'true';

  Future<void> setTrueBlack(bool value) => _store.write(trueBlackKey, '$value');

  Future<bool> guidePromptShown() async =>
      (await _store.read(guidePromptKey)) == 'true';

  Future<void> setGuidePromptShown() => _store.write(guidePromptKey, 'true');

  /// Kayıtlı değer seçeneklerden biri değilse varsayılan kullanılır
  /// (ör. depo elle değiştirilmişse kilidi kapatmak mümkün olmasın).
  Future<Duration> _readDuration(
    String key,
    List<Duration> options,
    Duration fallback,
  ) async {
    final seconds = int.tryParse(await _store.read(key) ?? '');
    if (seconds == null) return fallback;
    final value = Duration(seconds: seconds);
    return options.contains(value) ? value : fallback;
  }

  Future<void> _writeDuration(
    String key,
    Duration value,
    List<Duration> options,
  ) {
    if (!options.contains(value)) {
      throw ArgumentError('Geçersiz süre: $value');
    }
    return _store.write(key, '${value.inSeconds}');
  }
}
