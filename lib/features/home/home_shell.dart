import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:go_router/go_router.dart';

import '../../core/theme/motion.dart';
import '../../core/widgets/glass_surface.dart';

import '../../l10n/generated/app_localizations.dart';

/// Kasa açıkken ana iskelet: Kasa · Üretici · Rapor · Ayarlar.
/// Telefonda alt gezinme çubuğu, tablet ve yatay ekranda yan gezinme
/// çubuğu kullanılır.
///
/// Telefonda alt çubuk aşağı kaydırınca kompakt hâle gelir (yalnızca
/// simgeler, daha alçak); yukarı kaydırınca, en üste dönünce veya sekme
/// değişince açılır. Durum [ShellChrome] ile alt ekranlara iletilir
/// (ör. "+ Yeni kayıt" butonu da küçülür).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const Key vaultTabKey = Key('nav_vault');
  static const Key generatorTabKey = Key('nav_generator');
  static const Key reportTabKey = Key('nav_report');
  static const Key settingsTabKey = Key('nav_settings');
  static const Key railKey = Key('nav_rail');
  static const Key barKey = Key('nav_bar');

  /// Bu genişlikten itibaren alt çubuk yerine yan gezinme çubuğu.
  static const double railMinWidth = 600;

  /// Alt çubuğun açık ve kompakt yüksekliği.
  static const double barHeight = 80;
  static const double compactBarHeight = 56;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final ValueNotifier<bool> _compact = ValueNotifier(false);

  /// Yan çubuk düzeninde küçülme yok (her zaman açık).
  final ValueNotifier<bool> _railNotifier = ValueNotifier(false);

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void didUpdateWidget(HomeShell old) {
    super.didUpdateWidget(old);
    // Sekme değişince çubuk her zaman açılır.
    if (old.navigationShell.currentIndex != navigationShell.currentIndex) {
      _compact.value = false;
    }
  }

  @override
  void dispose() {
    _compact.dispose();
    _railNotifier.dispose();
    super.dispose();
  }

  void _select(int i) {
    _compact.value = false;
    navigationShell.goBranch(
      i,
      // Aynı sekmeye tekrar dokununca o sekmenin başına döner.
      initialLocation: i == navigationShell.currentIndex,
    );
  }

  /// Yalnızca dikey kaydırmalar: aşağı → kompakt, yukarı / en üst → açık.
  /// Yatay listeler (filtre çipleri, favoriler şeridi) etkilemez.
  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is UserScrollNotification) {
      if (n.direction == ScrollDirection.reverse) _compact.value = true;
      if (n.direction == ScrollDirection.forward) _compact.value = false;
    } else if (n is ScrollUpdateNotification &&
        n.metrics.pixels <= n.metrics.minScrollExtent) {
      _compact.value = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (
        HomeShell.vaultTabKey,
        Icons.shield_outlined,
        Icons.shield,
        l10n.navVault,
      ),
      (
        HomeShell.generatorTabKey,
        Icons.auto_awesome_outlined,
        Icons.auto_awesome,
        l10n.navGenerator,
      ),
      (
        HomeShell.reportTabKey,
        Icons.donut_large_outlined,
        Icons.donut_large,
        l10n.navReport,
      ),
      (
        HomeShell.settingsTabKey,
        Icons.settings_outlined,
        Icons.settings,
        l10n.navSettings,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tablet / yatay ekran: yan gezinme çubuğu.
        if (constraints.maxWidth >= HomeShell.railMinWidth) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    key: HomeShell.railKey,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final (_, icon, selectedIcon, label) in items)
                        NavigationRailDestination(
                          icon: Icon(icon),
                          selectedIcon: Icon(selectedIcon),
                          label: Text(label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: ShellChrome(
                    notifier: _railNotifier,
                    child: navigationShell,
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          // İçerik buzlu cam çubuğun altından akar.
          extendBody: true,
          body: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: ShellChrome(notifier: _compact, child: navigationShell),
          ),
          bottomNavigationBar: GlassSurface(
            edge: GlassEdge.top,
            child: ValueListenableBuilder<bool>(
              valueListenable: _compact,
              builder: (context, compact, _) => TweenAnimationBuilder<double>(
                tween: Tween(
                  end: compact
                      ? HomeShell.compactBarHeight
                      : HomeShell.barHeight,
                ),
                duration: AppMotion.of(context),
                curve: AppMotion.spring,
                builder: (context, height, _) => NavigationBar(
                  key: HomeShell.barKey,
                  height: height,
                  // Yazılar yalnızca çubuk tam açıkken; küçülürken önce
                  // gizlenir (taşma olmaz). Ekran okuyucu ve uzun basma
                  // ipucu sekme adını her zaman verir.
                  labelBehavior: !compact && height >= HomeShell.barHeight - 1
                      ? NavigationDestinationLabelBehavior.alwaysShow
                      : NavigationDestinationLabelBehavior.alwaysHide,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final (key, icon, selectedIcon, label) in items)
                      NavigationDestination(
                        key: key,
                        icon: Icon(icon),
                        selectedIcon: Icon(selectedIcon),
                        label: label,
                        tooltip: label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Kabuğun alt ekranlara ilettiği durum: alt çubuk kompakt mı?
class ShellChrome extends InheritedNotifier<ValueNotifier<bool>> {
  const ShellChrome({
    super.key,
    required ValueNotifier<bool> super.notifier,
    required super.child,
  });

  /// Kabuk dışında (ör. kök navigator'daki sayfalar) her zaman `false`.
  static bool compactOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ShellChrome>()
          ?.notifier
          ?.value ??
      false;
}
