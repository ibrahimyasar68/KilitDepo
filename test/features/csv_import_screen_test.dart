import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/data/import/csv_import.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/settings/application/csv_import_service.dart';
import 'package:kilitdepo/features/settings/presentation/csv_import_screen.dart';
import 'package:kilitdepo/features/settings/presentation/settings_screen.dart';

import '../helpers/fake_vault_repository.dart';
import '../helpers/test_app.dart';
import 'design_test.dart' show seeded;

const unlocked = AuthState(status: AuthStatus.unlocked);

const cachePath = '/data/user/0/com.iylabs.kilitdepo/cache/file_picker/1/a.csv';
const userPath = '/storage/emulated/0/Download/a.csv';

/// Silme / temizlik çağrılarını kaydeden sahte okuyucu.
class Recorder {
  final deleted = <String>[];
  var cleared = 0;

  CsvFileReader reader(
    String? path,
    Future<Uint8List> Function() bytes, {
    int size = 100,
    bool cancel = false,
  }) => CsvFileReader(
    pick: () async =>
        cancel ? null : PickedCsv(path: path, size: size, readBytes: bytes),
    deleteFile: (p) async => deleted.add(p),
    clearTemporaryFiles: () async => cleared++,
    tempRoots: const ['/private/var/mobile/tmp'],
  );
}

Uint8List csv(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('Geçici kopya temizliği', () {
    test('seçicinin önbellek kopyası okunduktan sonra silinir', () async {
      final r = Recorder();
      final bytes = await r.reader(cachePath, () async => csv('x')).read();
      expect(bytes, isNotNull);
      expect(r.deleted, [cachePath]);
      expect(r.cleared, 1);
    });

    test('kullanıcının kendi dosyasına ASLA dokunulmaz', () async {
      final r = Recorder();
      await r.reader(userPath, () async => csv('x')).read();
      expect(r.deleted, isEmpty);
      expect(r.cleared, 1);
    });

    test('okuma hatasında ve boyut aşımında da silinir', () async {
      final r = Recorder();
      await expectLater(
        r.reader(cachePath, () async => throw Exception('okunamadı')).read(),
        throwsException,
      );
      expect(r.deleted, [cachePath]);

      final r2 = Recorder();
      await expectLater(
        r2
            .reader(
              cachePath,
              () async => csv('x'),
              size: CsvImporter.maxBytes + 1,
            )
            .read(),
        throwsA(isA<CsvImportException>()),
      );
      expect(r2.deleted, [cachePath]);
      expect(r2.cleared, 1);
    });

    test('iptalde de geçici klasör temizlenir', () async {
      final r = Recorder();
      expect(
        await r.reader(null, () async => csv('x'), cancel: true).read(),
        isNull,
      );
      expect(r.cleared, 1);
    });
  });

  group('Tekrar kontrolü', () {
    test('kasada ve dosyada birebir aynı olanlar atlanır', () async {
      final repo = await seeded(); // Gmail / g / Kx9#mQ2!vL7@pR4z
      final parsed = CsvImporter.parse(
        'name,url,username,password\n'
        'Gmail,,g,Kx9#mQ2!vL7@pR4z\n' // kasada var
        'Yeni,,y,Pw-1\n'
        'Yeni,,y,Pw-1\n' // dosyada tekrar
        'Gmail,,g,Farkli-Sifre\n', // şifre farklı → eklenir
      );
      final preview = await CsvImportService(repo).preview(parsed);
      expect(preview.duplicates, 2);
      expect(preview.toAdd.map((c) => c.password), ['Pw-1', 'Farkli-Sifre']);

      expect(await CsvImportService(repo).commit(preview.toAdd), 2);
      expect(await repo.watchEntries().first, hasLength(5));
    });
  });

  group('Ekran', () {
    Future<FakeVaultRepository> open(
      WidgetTester tester,
      CsvFileReader reader,
    ) async {
      final repo = await seeded();
      await pumpApp(
        tester,
        unlocked,
        repository: repo,
        extraOverrides: [csvFileReaderProvider.overrideWithValue(reader)],
      );
      await openSettings(tester);
      await scrollToSetting(tester, find.byKey(SettingsScreen.csvImportKey));
      await tapVisible(tester, find.byKey(SettingsScreen.csvImportKey));
      expect(find.byType(CsvImportScreen), findsOneWidget);
      expect(find.text(l10n.csvImportPlainWarning), findsOneWidget);
      return repo;
    }

    testWidgets('önizleme (şifre yok) → içe aktar → silme hatırlatması', (
      tester,
    ) async {
      final r = Recorder();
      final repo = await open(
        tester,
        r.reader(
          cachePath,
          () async => csv(
            'Title,URL,Username,Password,Notes,OTPAuth\n'
            'Banka,https://banka.com,ali,Banka-Sifre-1,,otpauth://x\n'
            'Gmail,,g,Kx9#mQ2!vL7@pR4z,,\n',
          ),
        ),
      );
      await tapVisible(tester, find.byKey(CsvImportScreen.pickKey));
      expect(find.byKey(CsvImportScreen.previewKey), findsOneWidget);
      expect(
        find.text(l10n.csvImportFormatLabel(l10n.csvFormatApple)),
        findsOneWidget,
      );
      expect(find.text(l10n.csvImportToAdd(1)), findsOneWidget);
      expect(find.text(l10n.csvImportDuplicates(1)), findsOneWidget);
      expect(find.text(l10n.csvImportTotp(1)), findsOneWidget);
      expect(find.text('Banka'), findsOneWidget);
      // Önizlemede şifre gösterilmez.
      expect(find.textContaining('Banka-Sifre-1'), findsNothing);
      expect(r.deleted, [cachePath]);

      await tapVisible(tester, find.byKey(CsvImportScreen.confirmKey));
      expect(find.byKey(CsvImportScreen.doneKey), findsOneWidget);
      expect(find.text(l10n.csvImportDone(1)), findsOneWidget);
      expect(find.text(l10n.csvImportDeleteReminder), findsOneWidget);
      final all = await repo.watchEntries().first;
      expect(all.map((e) => e.title), contains('Banka'));
      expect(await repo.revealPassword(all.last.id), 'Banka-Sifre-1');

      await tapVisible(tester, find.byKey(CsvImportScreen.finishKey));
      expect(find.byType(CsvImportScreen), findsNothing);
    });

    testWidgets('tanınmayan dosyada açık hata mesajı', (tester) async {
      final r = Recorder();
      await open(tester, r.reader(cachePath, () async => csv('a,b\n1,2\n')));
      await tapVisible(tester, find.byKey(CsvImportScreen.pickKey));
      expect(find.byKey(CsvImportScreen.errorKey), findsOneWidget);
      expect(find.text(l10n.csvImportErrorColumns), findsOneWidget);
      expect(r.deleted, [cachePath]);
    });
  });
}
