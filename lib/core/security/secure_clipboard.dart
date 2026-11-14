import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../constants/security_params.dart';

/// Panoya yazan alt katman (yerel kod veya Flutter'ın genel panosu).
abstract interface class ClipboardWriter {
  Future<void> copySensitive(String text, Duration expiresIn);
  Future<void> clear();
}

/// Yerel kanal üzerinden hassas pano (bkz. MainActivity.kt / AppDelegate.swift):
/// - iOS: sistem düzeyinde son kullanma tarihi + yalnızca bu cihaz
///   (Evrensel Pano kapalı).
/// - Android 13+: "hassas içerik" işareti (önizlemede gösterilmez);
///   temizleme `clearPrimaryClip` ile.
/// Kanal yoksa (ör. testler) Flutter'ın genel panosuna düşer.
class PlatformClipboardWriter implements ClipboardWriter {
  static const MethodChannel _channel = MethodChannel(
    'com.iylabs.kilitdepo/clipboard',
  );

  @override
  Future<void> copySensitive(String text, Duration expiresIn) async {
    try {
      await _channel.invokeMethod<void>('copySensitive', {
        'text': text,
        'expiresInMs': expiresIn.inMilliseconds,
      });
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clear');
    } on MissingPluginException {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  }
}

/// Hassas değerleri panoya kopyalar ve belirli süre sonra panoyu temizler.
///
/// GÜVENLİK / PLATFORM KISITLARI:
/// - Pano içeriği temizlemeden önce OKUNMAZ: iOS 16+ okuma sırasında
///   "yapıştırma izni" istemi gösterir, Android 10+ ise arka planda okumaya
///   izin vermez. Bu yüzden süre dolunca pano koşulsuz boşaltılır.
/// - Uygulama arka plandayken Dart zamanlayıcısı çalışmayabilir:
///   iOS'ta yerel son kullanma tarihi bu açığı kapatır; ayrıca uygulama öne
///   geldiğinde süresi dolmuş pano hemen temizlenir.
/// - Elle kilitlemede pano hemen temizlenir; otomatik kilitte 30 sn kuralı
///   geçerlidir (bkz. AuthController.lock).
class SecureClipboard {
  SecureClipboard({
    this.clearAfter = SecurityParams.clipboardClearDelay,
    ClipboardWriter? writer,
    DateTime Function()? clock,
    bool listenLifecycle = true,
  }) : _writer = writer ?? PlatformClipboardWriter(),
       _clock = clock ?? DateTime.now {
    if (listenLifecycle) {
      _lifecycle = AppLifecycleListener(onResume: _clearIfExpired);
    }
  }

  /// Temizleme süresi (ayarlardan değiştirilebilir; sonraki kopyalamada
  /// geçerli olur).
  Duration clearAfter;
  final ClipboardWriter _writer;
  final DateTime Function() _clock;
  AppLifecycleListener? _lifecycle;
  Timer? _timer;
  DateTime? _clearAt;

  /// Temizleme bekleniyor mu?
  @visibleForTesting
  bool get hasPendingClear => _clearAt != null;

  Future<void> copy(String value) async {
    await _writer.copySensitive(value, clearAfter);
    _timer?.cancel();
    _clearAt = _clock().add(clearAfter);
    _timer = Timer(clearAfter, clearNow);
  }

  /// Bekleyen bir kopyalama varsa panoyu hemen temizler.
  Future<void> clearNow() async {
    _timer?.cancel();
    _timer = null;
    if (_clearAt == null) return;
    _clearAt = null;
    await _writer.clear();
  }

  void _clearIfExpired() {
    final at = _clearAt;
    if (at != null && !_clock().isBefore(at)) clearNow();
  }

  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
  }
}
