package com.iylabs.kilitdepo

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth ve biyometrik flutter_secure_storage, BiometricPrompt için
// FragmentActivity gerektirir.
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // SQLCipher (OpenSSL) yüklenmeden ÖNCE: M4 emülatör çökmesi düzeltmesi.
        EmulatorCompat.applyOpenSslWorkaround()

        // GÜVENLİK: FLAG_SECURE, Flutter ilk kareyi çizmeden ÖNCE ayarlanır:
        // ekran görüntüsü, ekran kaydı ve "son uygulamalar" önizlemesi
        // sistem düzeyinde engellenir.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CLIPBOARD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val clipboard =
                getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            when (call.method) {
                "copySensitive" -> {
                    val text = call.argument<String>("text") ?: ""
                    val clip = ClipData.newPlainText("KilitDepo", text)
                    // Android 13+: içerik "hassas" olarak işaretlenir; sistem
                    // kopyalama önizlemesinde şifre gösterilmez.
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        clip.description.extras = PersistableBundle().apply {
                            putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
                        }
                    } else {
                        clip.description.extras = PersistableBundle().apply {
                            putBoolean("android.content.extra.IS_SENSITIVE", true)
                        }
                    }
                    clipboard.setPrimaryClip(clip)
                    result.success(null)
                }
                "clear" -> {
                    // API 28+: panoyu boş metin yazmadan gerçekten temizler.
                    clipboard.clearPrimaryClip()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val CLIPBOARD_CHANNEL = "com.iylabs.kilitdepo/clipboard"
    }
}
