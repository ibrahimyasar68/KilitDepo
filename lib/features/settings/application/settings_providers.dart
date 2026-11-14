import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/app_settings_repository.dart';
import '../../auth/application/auth_providers.dart' show vaultStoreProvider;

/// Ayarlar, kasa meta verisiyle aynı güvenli depoda tutulur.
final appSettingsProvider = Provider<AppSettingsRepository>(
  (ref) => AppSettingsRepository(ref.watch(vaultStoreProvider)),
);

/// Hareketsizlik kilidi süresi. Değiştirildikten sonra invalidate edilir.
final autoLockTimeoutProvider = FutureProvider<Duration>(
  (ref) => ref.watch(appSettingsProvider).autoLockTimeout(),
);

/// Pano temizleme süresi.
final clipboardClearDelayProvider = FutureProvider<Duration>(
  (ref) => ref.watch(appSettingsProvider).clipboardClearDelay(),
);

/// Tema (giriş ekranında da geçerli).
final themeModeProvider = FutureProvider<ThemeMode>(
  (ref) => ref.watch(appSettingsProvider).themeMode(),
);

/// Material You seçeneği açık mı?
final dynamicColorEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(appSettingsProvider).dynamicColor(),
);

/// Koyu temada tam siyah zemin (AMOLED) açık mı?
final trueBlackProvider = FutureProvider<bool>(
  (ref) => ref.watch(appSettingsProvider).trueBlack(),
);

/// Cihaz duvar kağıdı renklerini destekliyor mu? (Android 12+; iOS'ta
/// ve eski Android'de false.) Testlerde geçersiz kılınır.
final dynamicColorSupportedProvider = FutureProvider<bool>((ref) async {
  try {
    return await DynamicColorPlugin.getCorePalette() != null;
  } on Object {
    return false;
  }
});

/// Son başarılı yedeğin tarihi.
final lastBackupAtProvider = FutureProvider<DateTime?>(
  (ref) => ref.watch(appSettingsProvider).lastBackupAt(),
);
