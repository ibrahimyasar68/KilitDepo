/// Uygulama kimliği ve marka metinleri için TEK kaynak.
///
/// Uygulama adı ve üretici etiketi her yerde buradan okunmalıdır;
/// ekranlara elle yazılmamalıdır.
abstract final class AppInfo {
  /// Uygulama adı. Yazımı her yerde tam olarak "KilitDepo" olmalıdır.
  static const String appName = 'KilitDepo';

  /// Üretici adı.
  static const String producer = 'İY Labs';

  /// Üretici etiketi.
  static const String producerLabel = 'İY Labs';

  /// Ayarlar ekranının altındaki satır:
  /// "KilitDepo v1.0.0 · İY Labs"
  static String versionLine(String version) =>
      '$appName v$version · $producerLabel';

  /// Hakkında sayfasındaki telif satırı.
  static String copyright(int year) =>
      '© $year $producer. Tüm hakları saklıdır.';

  /// showLicensePage için applicationLegalese.
  static String legalese(int year) => '© $year $producer';
}
