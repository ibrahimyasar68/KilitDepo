import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Uygulamaya gömülü native kütüphanelerin lisanslarını Flutter'ın
/// lisans sayfasına (showLicensePage) ekler.
///
/// Dart paketlerinin lisansları otomatik eklenir; ancak package:sqlite3'ün
/// derleme sırasında indirdiği SQLCipher ikilisi ve (Android'de) ona bağlı
/// OpenSSL bu listeye kendiliğinden girmez. Lisansları bu bildirimlerin
/// dağıtımla birlikte sunulmasını gerektirir. Metinler resmi depolardan
/// alınmıştır (assets/licenses/).
void registerNativeLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'SQLCipher',
    ], await rootBundle.loadString('assets/licenses/sqlcipher.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'OpenSSL',
    ], await rootBundle.loadString('assets/licenses/openssl.txt'));
    // Gömülü yazı tipleri (SIL Open Font License 1.1).
    yield LicenseEntryWithLineBreaks(const [
      'Inter (yazı tipi)',
    ], await rootBundle.loadString('assets/licenses/inter.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'JetBrains Mono (yazı tipi)',
    ], await rootBundle.loadString('assets/licenses/jetbrains_mono.txt'));
  });
}
