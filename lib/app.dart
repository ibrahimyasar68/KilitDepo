import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_info.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'features/auth/presentation/auto_lock_guard.dart';
import 'features/settings/application/settings_providers.dart';
import 'l10n/generated/app_localizations.dart';

class KilitDepoApp extends ConsumerWidget {
  const KilitDepoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Material You (isteğe bağlı): açıksa ve cihaz destekliyorsa renkler
    // duvar kağıdından alınır; aksi hâlde marka rengi (petrol yeşili).
    final useDynamic = ref.watch(dynamicColorEnabledProvider).value ?? false;
    final black = ref.watch(trueBlackProvider).value ?? false;
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: AppInfo.appName,
          debugShowCheckedModeBanner: false,
          theme: useDynamic && lightDynamic != null
              ? AppTheme.fromScheme(lightDynamic.harmonized())
              : AppTheme.light(),
          darkTheme: useDynamic && darkDynamic != null
              ? AppTheme.fromScheme(
                  black
                      ? AppTheme.trueBlack(darkDynamic.harmonized())
                      : darkDynamic.harmonized(),
                )
              : AppTheme.dark(black: black),
          // Kullanıcının seçtiği tema (giriş ekranında da geçerli).
          themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.system,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: ref.watch(routerProvider),
          // Zemin + ışıma tüm sayfaların arkasında tek katman.
          builder: (context, child) => AppBackground(
            child: AutoLockGuard(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
