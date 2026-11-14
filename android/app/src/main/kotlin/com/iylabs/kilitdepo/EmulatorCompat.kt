package com.iylabs.kilitdepo

import android.os.Build
import android.system.Os
import java.io.File

/**
 * Yalnızca Android EMÜLATÖRÜNDE uygulanan uyumluluk düzeltmesi.
 *
 * Sorun: Apple M4 Mac'lerde çalışan Android emülatörü, işlemcinin SVE/SVE2
 * desteklediğini bildirir (`/proc/cpuinfo` içinde `sve2`), ancak bu komutları
 * çalıştıramaz. SQLCipher'ın içerdiği OpenSSL, kütüphane yüklenirken SVE'yi
 * yoklar ve süreç SIGILL ("Illegal instruction") ile çöker.
 *
 * Çözüm: OpenSSL, `OPENSSL_armcap` ortam değişkeni varsa işlemciyi yoklamaz
 * ve bu değeri kullanır. Değer, emülatörün GERÇEKTEN desteklediği özelliklerden
 * (AES, PMULL, SHA1/256/512) hesaplanır; SVE dahil edilmez.
 *
 * GÜVENLİK: Şifreleme algoritmaları değişmez; yalnızca emülatörde SVE
 * hızlandırması kullanılmaz. Gerçek cihazlarda bu kod hiçbir şey yapmaz.
 */
object EmulatorCompat {
    // OpenSSL arm_arch.h bit değerleri.
    private const val ARMV7_NEON = 1 shl 0
    private const val ARMV8_AES = 1 shl 2
    private const val ARMV8_SHA1 = 1 shl 3
    private const val ARMV8_SHA256 = 1 shl 4
    private const val ARMV8_PMULL = 1 shl 5
    private const val ARMV8_SHA512 = 1 shl 6

    fun applyOpenSslWorkaround() {
        if (!isEmulator()) return
        if (Os.getenv("OPENSSL_armcap") != null) return
        val features = cpuFeatures()
        if ("sve" !in features && "sve2" !in features) return

        var caps = 0
        if ("asimd" in features) caps = caps or ARMV7_NEON
        if ("aes" in features) caps = caps or ARMV8_AES
        if ("pmull" in features) caps = caps or ARMV8_PMULL
        if ("sha1" in features) caps = caps or ARMV8_SHA1
        if ("sha2" in features) caps = caps or ARMV8_SHA256
        if ("sha512" in features) caps = caps or ARMV8_SHA512
        Os.setenv("OPENSSL_armcap", "0x" + Integer.toHexString(caps), true)
    }

    /** Android emülatörü ("ranchu"/"goldfish" sanal donanımı). */
    private fun isEmulator(): Boolean =
        Build.HARDWARE == "ranchu" ||
            Build.HARDWARE == "goldfish" ||
            Build.PRODUCT.startsWith("sdk_gphone")

    private fun cpuFeatures(): Set<String> = try {
        File("/proc/cpuinfo").readLines()
            .firstOrNull { it.startsWith("Features") }
            ?.substringAfter(':')
            ?.trim()
            ?.split(Regex("\\s+"))
            ?.toSet()
            ?: emptySet()
    } catch (_: Exception) {
        emptySet()
    }
}
