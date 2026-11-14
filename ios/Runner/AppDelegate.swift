import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KilitDepoClipboard") {
      SensitiveClipboard.register(messenger: registrar.messenger())
    }
  }
}

/// Hassas değerler için pano.
///
/// GÜVENLİK:
/// - `expirationDate`: iOS panoyu süre dolunca KENDİSİ temizler; uygulama
///   arka planda askıya alınmış olsa bile çalışır.
/// - `localOnly`: Evrensel Pano (Handoff) ile Mac/iPad'e aktarılmaz.
enum SensitiveClipboard {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.iylabs.kilitdepo/clipboard",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "copySensitive":
        guard let args = call.arguments as? [String: Any],
              let text = args["text"] as? String else {
          result(FlutterError(code: "bad_args", message: nil, details: nil))
          return
        }
        let millis = (args["expiresInMs"] as? Int) ?? 30_000
        let expiry = Date().addingTimeInterval(Double(millis) / 1000.0)
        UIPasteboard.general.setItems(
          [[UTType.plainText.identifier: text]],
          options: [.localOnly: true, .expirationDate: expiry]
        )
        result(nil)
      case "clear":
        UIPasteboard.general.items = []
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
