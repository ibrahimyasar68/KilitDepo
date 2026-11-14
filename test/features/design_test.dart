import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/widgets/colored_password_text.dart';
import 'package:kilitdepo/core/widgets/letter_avatar.dart';
import 'package:kilitdepo/domain/entities/entry_category.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/generator/presentation/generator_panel.dart';
import 'package:kilitdepo/features/home/home_shell.dart';
import 'package:kilitdepo/features/vault/application/security_report.dart';
import 'package:kilitdepo/features/vault/presentation/entry_detail_screen.dart';
import 'package:kilitdepo/features/vault/presentation/entry_edit_screen.dart';
import 'package:kilitdepo/features/vault/presentation/security_report_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';
import 'package:kilitdepo/features/vault/presentation/widgets/vault_ui.dart';

import '../helpers/fake_vault_repository.dart';
import '../helpers/test_app.dart';

const unlocked = AuthState(status: AuthStatus.unlocked);

Future<FakeVaultRepository> seeded() async {
  final repo = FakeVaultRepository();
  await repo.addEntry(
    const EntryDraft(
      title: 'ziraat',
      username: 'z',
      password: 'Kx9#mQ2!vL7@pR4z',
    ),
  );
  await repo.addEntry(
    const EntryDraft(
      title: 'Gmail',
      username: 'g',
      password: 'Kx9#mQ2!vL7@pR4z',
    ),
  );
  await repo.addEntry(
    const EntryDraft(
      title: 'gitHub',
      username: 'h',
      password: 'Başka-Güçlü-77#Ab',
    ),
  );
  return repo;
}

void main() {
  group('LetterAvatar', () {
    test('Türkçe baş harf kuralları', () {
      expect(LetterAvatar.initialOf('istanbul'), 'İ');
      expect(LetterAvatar.initialOf('ısparta'), 'I');
      expect(LetterAvatar.initialOf('  gmail'), 'G');
      expect(LetterAvatar.initialOf(''), '?');
    });

    test('aynı başlık her zaman aynı renk (büyük/küçük harf duyarsız)', () {
      expect(
        LetterAvatar.colorIndexOf('Gmail'),
        LetterAvatar.colorIndexOf('gmail'),
      );
      final indexes = {
        for (final t in [
          'Gmail',
          'Ziraat',
          'Twitter',
          'Banka',
          'İş',
          'Netflix',
        ])
          LetterAvatar.colorIndexOf(t),
      };
      expect(indexes.length, greaterThan(1), reason: 'renkler çeşitlenmeli');
    });
  });

  test('ColoredPasswordText karakter türleri', () {
    expect(ColoredPasswordText.kindOf('a'), 0);
    expect(ColoredPasswordText.kindOf('Ş'), 0);
    expect(ColoredPasswordText.kindOf('0'), 1);
    expect(ColoredPasswordText.kindOf('#'), 2);
  });

  test('güvenlik puanı: uyarısız kayıt oranı', () {
    expect(SecurityReport.empty.score, 100);
    final r = analyzePasswords([
      (id: 1, password: '123'),
      (id: 2, password: 'Kx9#mQ2!vL7@pR4zT8&w'),
      (id: 3, password: 'Kx9#mQ2!vL7@pR4zT8&w'),
      (id: 4, password: 'Başka-Güçlü-77#AbCd'),
    ]);
    expect(r.score, 25); // 4 kayıttan yalnızca 1'i sorunsuz
  });

  testWidgets('alt gezinme çubuğunda dört sekme', (tester) async {
    await pumpApp(tester, unlocked);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final key in [
      HomeShell.vaultTabKey,
      HomeShell.generatorTabKey,
      HomeShell.reportTabKey,
      HomeShell.settingsTabKey,
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
  });

  testWidgets('liste: harf rozetleri ve Türkçe harf başlıkları', (
    tester,
  ) async {
    await pumpApp(tester, unlocked, repository: await seeded());
    expect(find.byType(LetterAvatar), findsNWidgets(3));
    // Gmail ve gitHub aynı "G" başlığı altında, ziraat "Z" altında.
    expect(find.text('G'), findsWidgets);
    expect(find.text('Z'), findsWidgets);
  });

  testWidgets('sağa kaydırma şifreyi kopyalar, kayıt listede kalır', (
    tester,
  ) async {
    await pumpApp(tester, unlocked, repository: await seeded());
    await tester.drag(
      find.byKey(const Key('entry_tile_2')),
      const Offset(500, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(clipboardWrites, ['Kx9#mQ2!vL7@pR4z']);
    expect(find.byKey(ClipboardCountdownRing.ringKey), findsOneWidget);
    expect(entryText('Gmail'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
  });

  testWidgets('sola kaydırma favori durumunu değiştirir', (tester) async {
    final repo = await seeded();
    await pumpApp(tester, unlocked, repository: repo);
    await tester.drag(
      find.byKey(const Key('entry_tile_2')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect((await repo.getEntry(2)).summary.isFavorite, isTrue);
    expect(entryText('Gmail'), findsOneWidget);
  });

  testWidgets('detay: açılınca şifre renkli ve güç göstergeli', (tester) async {
    await pumpApp(tester, unlocked, repository: await seeded());
    await tester.tap(entryText('Gmail'));
    await tester.pumpAndSettle();
    expect(find.byType(EntryDetailScreen), findsOneWidget);
    expect(find.byType(ColoredPasswordText), findsNothing);
    await tester.tap(find.byKey(EntryDetailScreen.revealKey));
    await tester.pumpAndSettle();
    expect(find.byType(ColoredPasswordText), findsOneWidget);
    expect(find.byKey(const Key('strength_label')), findsOneWidget);
  });

  testWidgets('rapor sekmesi: puan halkası ve "ile aynı" açıklaması', (
    tester,
  ) async {
    await pumpApp(tester, unlocked, repository: await seeded());
    await openTab(tester, 'nav_report');
    expect(find.byType(SecurityReportScreen), findsOneWidget);
    expect(find.byKey(SecurityReportScreen.scoreKey), findsOneWidget);
    expect(find.text('33'), findsOneWidget); // 3 kayıttan 1'i sorunsuz
    // Grubun son satırına kadar kaydır (ilk satır önbellekte kalır).
    await tester.scrollUntilVisible(
      find.text(l10n.reportReusedWith('ziraat')),
      200,
    );
    expect(find.text(l10n.reportReusedWith('ziraat')), findsOneWidget);
    expect(find.text(l10n.reportReusedWith('Gmail')), findsOneWidget);
  });

  testWidgets('kasa listesinde eski ⋮ menüsü yok', (tester) async {
    await pumpApp(tester, unlocked);
    expect(find.byType(VaultListScreen), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('form: kategori çipleri ve canlı güç göstergesi', (tester) async {
    final (_, repo) = await pumpApp(tester, unlocked);
    await tapVisible(tester, find.byKey(VaultListScreen.addButtonKey));
    expect(find.text(l10n.entrySectionAccount), findsOneWidget);
    await tester.enterText(find.byKey(EntryEditScreen.titleKey), 'Ziraat');
    await tester.enterText(find.byKey(EntryEditScreen.passwordKey), 'aaaa');
    await tester.pump();
    expect(
      find.text(l10n.strengthLabel(l10n.strengthVeryWeak)),
      findsOneWidget,
    );
    await tapVisible(tester, find.byKey(const Key('category_bank')));
    await tester.tap(find.byKey(EntryEditScreen.saveKey));
    await tester.pumpAndSettle();
    expect((await repo.getEntry(1)).summary.category, EntryCategory.bank);
  });

  testWidgets('üretici: renkli gösterim, hızlı seçim yok', (tester) async {
    await pumpApp(tester, unlocked);
    await openTab(tester, 'nav_generator');
    final shown = tester
        .widget<ColoredPasswordText>(find.byKey(GeneratorPanel.passwordKey))
        .password;
    expect(shown.length, 20);
    expect(find.byKey(GeneratorPanel.lengthKey), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('sıralı belirme: "animasyonları kapat" açıksa animasyon yok', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StaggeredFadeIn(index: 3, child: Text('satır')),
        ),
      ),
    );
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('satır'), findsOneWidget);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: StaggeredFadeIn(index: 3, child: Text('satır')),
      ),
    );
    expect(find.byType(Opacity), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });
}
