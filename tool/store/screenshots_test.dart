// Google Play telefon ekran görüntülerini üretir (1080x1920, 9:16).
//
// Uygulama ekran görüntüsünü engellediği (FLAG_SECURE) için görüntüler
// gerçek yazı tipleriyle test ortamında çizilir. Örnek kayıtlar sahtedir ve
// marka adı içermez. Çalıştırma (proje kökünden):
//
//   flutter test tool/store/screenshots_test.dart --update-goldens
//
// Çıktı: store/screenshots/*.png
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/data/repositories/app_settings_repository.dart';
import 'package:kilitdepo/domain/entities/entry_category.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/vault/presentation/entry_detail_screen.dart';
import 'package:kilitdepo/features/vault/presentation/entry_edit_screen.dart';

import '../../test/helpers/fake_vault_repository.dart';
import '../../test/helpers/in_memory_store.dart';
import '../../test/helpers/test_app.dart';

const _out = '../../store/screenshots';

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
    );
  }
  await loader.load();
}

String _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  // flutter/bin/cache/dart-sdk/bin/dart → flutter
  return File(
    Platform.resolvedExecutable,
  ).parent.parent.parent.parent.parent.path;
}

Future<FakeVaultRepository> _sampleVault() async {
  final repo = FakeVaultRepository();
  const entries = [
    EntryDraft(
      title: 'Banka Hesabı',
      username: 'ahmet.yilmaz',
      password: 'Vt7#qLm2!xR9@kPz',
      category: EntryCategory.bank,
      isFavorite: true,
      iconKey: 'bank',
      colorKey: 'blue',
    ),
    EntryDraft(
      title: 'E-posta',
      username: 'ahmet@ornek.com',
      password: 'Kartal-Limon-Dere-Masa-Bulut-47',
      category: EntryCategory.email,
      isFavorite: true,
      iconKey: 'email',
      colorKey: 'red',
      url: 'https://posta.ornek.com',
      notes: 'Kurtarma kodları kasadaki notta.',
    ),
    EntryDraft(
      title: 'Oyun Hesabı',
      username: 'oyuncu_42',
      password: 'Gx4!mN8#pQ2&wT6z',
      isFavorite: true,
      iconKey: 'game',
      colorKey: 'purple',
    ),
    EntryDraft(
      title: 'Alışveriş Sitesi',
      username: 'ahmet@ornek.com',
      password: 'Ortak-Sifre-2023!',
      iconKey: 'cart',
      colorKey: 'orange',
    ),
    EntryDraft(
      title: 'Bulut Depolama',
      username: 'ahmet.y',
      password: 'Zr8%cV3!nB7^hJ1q',
      iconKey: 'cloud',
      colorKey: 'teal',
    ),
    EntryDraft(
      title: 'Eski Forum',
      username: 'ahmet',
      password: 'Ortak-Sifre-2023!',
    ),
    EntryDraft(
      title: 'Ev Wi-Fi',
      username: '',
      password: '1234abcd',
      iconKey: 'wifi',
    ),
    EntryDraft(
      title: 'İş Portalı',
      username: 'a.yilmaz',
      password: 'Mq5@tY9!dF3#sL8w',
      category: EntryCategory.work,
    ),
  ];
  for (final e in entries) {
    await repo.addEntry(e);
  }
  return repo;
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.625;
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$_out/$name.png'),
  );
  // Test çerçevesi bu ayarın her testin sonunda eski hâlinde olmasını ister.
  debugDisableShadows = true;
}

Future<void> _start(
  WidgetTester tester, {
  bool dark = false,
  AuthState state = const AuthState(status: AuthStatus.unlocked),
  FakeVaultRepository? repo,
}) async {
  // Gerçek (bulanık) gölgeler çizilsin.
  debugDisableShadows = false;
  final store = InMemorySecureStore()
    ..data[AppSettingsRepository.themeKey] = dark ? 'dark' : 'light';
  await pumpApp(
    tester,
    state,
    repository: repo ?? await _sampleVault(),
    store: store,
  );
  await _phone(tester);
}

void main() {
  setUpAll(() async {
    await _font('Inter', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/fonts/Inter-$w.ttf',
    ]);
    await _font('JetBrainsMono', [
      'assets/fonts/JetBrainsMono-Regular.ttf',
      'assets/fonts/JetBrainsMono-Medium.ttf',
    ]);
    await _font('MaterialIcons', [
      '${_flutterRoot()}/bin/cache/artifacts/material_fonts/'
          'MaterialIcons-Regular.otf',
    ]);
  });

  testWidgets('01 kasa', (tester) async {
    await _start(tester);
    await _shot(tester, '01-kasa');
  });

  testWidgets('02 kayit detayi', (tester) async {
    await _start(tester);
    await tapEntry(tester, 'Alışveriş Sitesi');
    await _shot(tester, '02-kayit-detayi');
  });

  testWidgets('03 sifre uretici', (tester) async {
    await _start(tester);
    await openTab(tester, 'nav_generator');
    await _shot(tester, '03-sifre-uretici');
  });

  testWidgets('04 kelime tabanli sifre', (tester) async {
    await _start(tester);
    await openTab(tester, 'nav_generator');
    await tester.tap(find.byKey(const Key('gen_mode_words')));
    await tester.pumpAndSettle();
    await _shot(tester, '04-kelime-tabanli-sifre');
  });

  testWidgets('05 guvenlik raporu', (tester) async {
    await _start(tester);
    await openTab(tester, 'nav_report');
    await _shot(tester, '05-guvenlik-raporu');
  });

  testWidgets('06 gorunum secici', (tester) async {
    await _start(tester);
    await tapEntry(tester, 'Bulut Depolama');
    await tester.tap(find.byKey(EntryDetailScreen.editKey));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(EntryEditScreen.appearanceKey));
    await _shot(tester, '06-gorunum-secici');
  });

  testWidgets('07 giris', (tester) async {
    await _start(
      tester,
      dark: true,
      state: const AuthState(
        status: AuthStatus.locked,
        biometricAvailable: true,
        biometricEnabled: true,
      ),
    );
    await _shot(tester, '07-giris');
  });

  testWidgets('08 koyu tema', (tester) async {
    await _start(tester, dark: true);
    await _shot(tester, '08-koyu-tema');
  });
}
