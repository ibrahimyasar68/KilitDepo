import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/security/secure_clipboard.dart';

import '../helpers/test_app.dart' show RecordingClipboardWriter;

void main() {
  late List<String?> writes;
  late SecureClipboard c;

  setUp(() {
    writes = [];
    c = SecureClipboard(
      writer: RecordingClipboardWriter(writes),
      listenLifecycle: false,
    );
  });

  tearDown(() => c.dispose());

  test('varsayılan süre 30 saniye', () {
    expect(c.clearAfter, const Duration(seconds: 30));
  });

  // testWidgets zamanlayıcıları sahte saatle çalıştırır (tester.pump).
  testWidgets('kopyalanır ve 30 sn sonra temizlenir', (tester) async {
    await c.copy('gizli');
    expect(writes, ['gizli']);

    await tester.pump(const Duration(seconds: 29));
    expect(writes, ['gizli']);

    await tester.pump(const Duration(seconds: 1));
    expect(writes, ['gizli', '']);
    expect(c.hasPendingClear, isFalse);
  });

  testWidgets('yeni kopyalama süreyi baştan başlatır', (tester) async {
    await c.copy('bir');
    await tester.pump(const Duration(seconds: 20));
    await c.copy('iki');
    await tester.pump(const Duration(seconds: 20));
    expect(writes, ['bir', 'iki']);
    await tester.pump(const Duration(seconds: 10));
    expect(writes, ['bir', 'iki', '']);
  });

  testWidgets('clearNow hemen temizler; bekleyen yoksa panoya dokunmaz', (
    tester,
  ) async {
    await c.clearNow();
    expect(writes, isEmpty);

    await c.copy('gizli');
    await c.clearNow();
    expect(writes, ['gizli', '']);

    await tester.pump(const Duration(seconds: 60));
    expect(writes, ['gizli', '']); // zamanlayıcı iptal edildi
  });
}
