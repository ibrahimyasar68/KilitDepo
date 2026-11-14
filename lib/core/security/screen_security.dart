import 'dart:io';

import 'package:screen_protector/screen_protector.dart';

/// Ekran görüntüsü / kayıt engeli ve uygulama değiştirici gizlemesi.
///
/// - Android: FLAG_SECURE yerel olarak MainActivity.onCreate içinde, Flutter
///   ilk kareyi çizmeden önce ayarlanır (ekran görüntüsü, kayıt ve "son
///   uygulamalar" önizlemesi engellenir). Burada ek bir şey gerekmez.
/// - iOS:
///   * Uygulama değiştiricide içerik bulanıklaştırılır (resmi yöntem).
///   * Ekran görüntüsü/kaydı siyah çıkar. PLATFORM KISITI: Apple bunun için
///     resmi bir API sunmaz; screen_protector "güvenli metin alanı"
///     yöntemini kullanır. Gelecekteki bir iOS sürümünde çalışmayı
///     bırakabilir; bu durumda uygulama çalışmaya devam eder, yalnızca
///     görüntüler siyah çıkmaz.
abstract final class ScreenSecurity {
  static Future<void> enable() async {
    if (!Platform.isIOS) return;
    try {
      await ScreenProtector.protectDataLeakageWithBlur();
      await ScreenProtector.preventScreenshotOn();
    } on Object {
      // Koruma etkinleştirilemezse uygulama yine açılır.
    }
  }
}
