import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/theme/motion.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/home/home_shell.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';

import '../helpers/fake_vault_repository.dart';
import '../helpers/test_app.dart';

const unlocked = AuthState(status: AuthStatus.unlocked);

/// Kaydırılabilecek kadar çok kayıt.
Future<FakeVaultRepository> manyEntries() async {
  final repo = FakeVaultRepository();
  for (var i = 0; i < 30; i++) {
    await repo.addEntry(
      EntryDraft(
        title: 'Kayıt ${i.toString().padLeft(2, '0')}',
        username: 'kullanici$i',
        password: 'Benzersiz-Sifre-$i-Xy9!',
      ),
    );
  }
  return repo;
}

double barHeight(WidgetTester tester) =>
    tester.getSize(find.byKey(HomeShell.barKey)).height;

bool fabExtended(WidgetTester tester) => tester
    .widget<FloatingActionButton>(find.byKey(VaultListScreen.addButtonKey))
    .isExtended;

Finder get list => find.byType(CustomScrollView).first;

void main() {
  test('yay eğrisi 0 → 1, hafif aşma ile yerleşir', () {
    expect(AppMotion.spring.transform(0), 0);
    expect(AppMotion.spring.transform(1), 1);
    final samples = [
      for (var i = 1; i < 20; i++) AppMotion.spring.transform(i / 20),
    ];
    expect(samples.reduce((a, b) => a > b ? a : b), greaterThan(1));
    expect(samples.last, closeTo(1, 0.05));
  });

  testWidgets('aşağı kaydırınca çubuk ve buton küçülür, yukarı açılır', (
    tester,
  ) async {
    await pumpApp(tester, unlocked, repository: await manyEntries());
    expect(barHeight(tester), HomeShell.barHeight);
    expect(fabExtended(tester), isTrue);
    expect(find.text(l10n.navVault), findsOneWidget);

    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(barHeight(tester), HomeShell.compactBarHeight);
    expect(fabExtended(tester), isFalse);
    // Yazılar gizli; sekme adı ipucu olarak duruyor.
    expect(
      tester.widget<NavigationBar>(find.byKey(HomeShell.barKey)).labelBehavior,
      NavigationDestinationLabelBehavior.alwaysHide,
    );
    expect(find.byTooltip(l10n.navVault), findsOneWidget);

    await tester.drag(list, const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(barHeight(tester), HomeShell.barHeight);
    expect(fabExtended(tester), isTrue);
  });

  testWidgets('sekme değişince çubuk açılır', (tester) async {
    await pumpApp(tester, unlocked, repository: await manyEntries());
    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(barHeight(tester), HomeShell.compactBarHeight);
    await tester.tap(find.byKey(HomeShell.generatorTabKey));
    await tester.pumpAndSettle();
    expect(barHeight(tester), HomeShell.barHeight);
  });

  testWidgets('yatay kaydırma (filtre çipleri) çubuğu etkilemez', (
    tester,
  ) async {
    await pumpApp(tester, unlocked, repository: await manyEntries());
    await tester.drag(
      find.byKey(VaultListScreen.filterChipsKey),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(barHeight(tester), HomeShell.barHeight);
  });

  testWidgets('animasyonlar kapalıyken de doğru boyuta geçer', (tester) async {
    await pumpApp(tester, unlocked, repository: await manyEntries());
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    await tester.drag(list, const Offset(0, -400));
    await tester.pump();
    await tester.pump();
    expect(barHeight(tester), HomeShell.compactBarHeight);
  });
}
