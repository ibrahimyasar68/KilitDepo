# KilitDepo — Devam Notları

> Yeni bir oturumda kaldığımız yerden devam etmek için hazırlandı.
> Son güncelleme: **15 Kasım 2026**. Durum: Faz 1–5, tasarım turları (10c–10l), benzer uygulama
> araştırmasından çıkan öneriler ve CSV içe aktarma tamam; **323 test geçiyor**, `flutter analyze` temiz.
> **Release APK 13 Kasım 09:38'de derlendi** (78,4 MB, sürüm 1.0.0, İNTERNET izni yok, hâlâ debug anahtarıyla
> imzalı). iOS hiç derlenmedi (Xcode yok). Uygulama değişiklikleri emülatörde kullanıcı tarafından
> denenecek; Claude ekran görüntülerini test içinde gerçek fontlarla çizdirerek kontrol ediyor (§6).

---

## 1. Proje özeti

- **Ne:** Tamamen çevrimdışı, kişisel şifre yöneticisi (Flutter, Android + iOS).
- **Ad:** `KilitDepo` (yazım her yerde tam olarak böyle). **Paket/Bundle ID:** `com.iylabs.kilitdepo`.
- **Üretici:** İY Labs. Etiket metni: **"İY Labs"** (eskiden "iylabs tarafından üretildi" idi; değiştirildi).
  Uygulama adı, üretici ve etiket **yalnızca** `lib/core/constants/app_info.dart` içinde tanımlı.
- **Arayüz dili:** Türkçe. Metinler `lib/l10n/app_tr.arb` (ARB) içinde; `flutter gen-l10n` ile
  `lib/l10n/generated/` üretilir.
- **Kullanıcıyla çalışma şekli (ilk talimattan):**
  1. Her işten önce kısa plan sun, onay bekle.
  2. Bitince özetle, nasıl test edileceğini söyle, sonraki adım için onay iste.
  3. Güvenlikle ilgili belirsizlikte varsayım yapma, **sor**.
  4. Önemli güvenlik kararlarını kodda kısa yorumlarla açıkla.
  5. Bir gereksinim teknik olarak imkânsızsa açıkça söyle, alternatif öner.
  6. **Paket eklemeden/değiştirmeden önce sor.** Sürümler pubspec'te sabit (caret yok).
- Kullanıcı yanıtları Türkçe; kullanıcı kod yazmıyor, emülatörde/VS Code'da deniyor.

## 2. Ortam

- macOS (Apple **M4**), Flutter **3.47.9** / Dart **3.13.7** (oturum başında 3.35.6'dan yükseltildi).
- VS Code + Dart/Flutter eklentileri kurulu. `.vscode/launch.json`: debug/profile/release.
- Android emülatörü: `flutter_emulator` / `Pixel_6` (Android 14, arm64). Android lisansları onaylı.
- **Xcode ve CocoaPods kurulu değil** → iOS derlenemiyor/denenemiyor.
- Kullanıcının emülatöründe başka İY Labs uygulamaları da var (BebeSepeti, MathSpin…).

## 3. Teknik yığın (pubspec.yaml — sürümler sabit)

| Paket | Sürüm | Not |
|---|---|---|
| flutter_riverpod | 3.5.0 | Kod üretimsiz, elle provider'lar |
| go_router | 18.1.3 | `StatefulShellRoute` (alt çubuk/yan çubuk) |
| drift / drift_dev | 2.35.4 / 2.35.3 | `build.yaml`: tarihler metin olarak saklanır |
| sqlite3 | 3.9.1 | **SQLCipher** `hooks.user_defines.sqlite3.source: sqlcipher` ile (eski `sqlcipher_flutter_libs` EOL olduğu için) |
| flutter_secure_storage | 11.2.0 | Biyometrik bağlama destekli |
| cryptography | 2.9.0 | Argon2id + AES-256-GCM + HKDF |
| local_auth | 3.0.2 | Yalnızca biyometri uygunluğu kontrolü |
| screen_protector | 1.5.3 | **Yalnızca iOS** için kullanılıyor (Android'de kendi kodumuz) |
| package_info_plus | 10.2.2 | Sürüm bilgisi |
| file_picker | 13.3.2 | Yedek kaydet/seç (izin gerektirmez) |
| dynamic_color | **1.9.0** | 2.x `material_ui` paketine geçtiği için Flutter 3.47 ile uyumsuz; 1.9.0'da sabitlendi |
| flutter_native_splash (dev) | 2.4.8 | |
| build_runner, mocktail, flutter_lints (dev) | 2.17.1, 1.0.5, 6.0.0 | |

Gömülü yazı tipleri: **Inter** (400/500/600/700) ve **JetBrains Mono** (400/500) — `assets/fonts/`.

## 4. Mimari (feature-first, Clean Architecture'a yakın)

```
lib/
  core/      constants (app_info, crypto_params, security_params), crypto (CryptoService),
             security (secure_clipboard, screen_security), storage, theme, router, utils
             (turkish_text), widgets (app_logo, letter_avatar, colored_password_text…), licenses
  data/      database (drift: tables, dao, SQLCipher opener), repositories (vault_key,
             vault, app_settings, unlock_attempt_limiter), backup (backup_codec), vault_session
  domain/    entities (password_entry, backup_entry, entry_category), repository arayüzleri
  features/  auth, vault, generator, settings, about, guide, home (HomeShell)
```

- Gezinme: `HomeShell` — telefonda alt çubuk (Kasa · Üretici · Rapor · Ayarlar), ≥600 px yan çubuk.
  Kasa sekmesinde ≥840 px liste+detay iki sütun. Kayıt detay/düzenle/geçmiş, yedekleme ve ana şifre
  değiştirme tam ekran (kök navigator) açılır. Hakkında ve Kullanma Talimatı kilitliyken de açılır.
- Yönlendirme kuralı: `authRedirect()` (`core/router/app_router.dart`).

## 5. Güvenlik tasarımı (uygulanmış)

- **Anahtarlar:** Ana şifre → Argon2id (32 MiB, t=6, p=4, 16 B salt) → KEK. Rastgele 256-bit **DEK**,
  KEK ile AES-256-GCM sarılır; AAD = sürüm + KDF parametreleri + salt. Meta veri
  `flutter_secure_storage`'da (iOS `unlocked_this_device`, Android `resetOnError: false`).
- DEK'ten HKDF ile iki alt anahtar: **SQLCipher anahtarı** (ham `x'..'` anahtar) ve **alan anahtarı**.
- **Alan düzeyi şifreleme:** şifre, notlar ve eski şifreler AES-256-GCM; AAD =
  `kilitdepo/entry/{uuid}/{alan}`. Başlık/kullanıcı adı/URL yalnızca SQLCipher ile korunur (arama için).
- SQLCipher yüklenemezse veritabanı **şifresiz açılmaz** (`cipher_version` kontrolü), `secure_delete` açık.
- **Biyometri:** DEK kopyası biyometriye bağlı depoda (Android `AndroidOptions.biometric`, güçlü biyometri,
  her işlemde doğrulama; iOS `biometryCurrentSet`). Ayarlar'dan açmak **ana şifre ister**.
- **Otomatik kilit:** arka plana geçince hemen; hareketsizlikte (varsayılan 1 dk, 30 sn–30 dk). Dosya
  seçici açıkken askıya alınır (uzun ayrılışta yine kilitlenir).
- **Pano:** varsayılan 30 sn (15–90 sn) sonra temizlenir. iOS'ta yerel `expirationDate` + `localOnly`,
  Android 13+ "hassas içerik" işareti (`MainActivity.kt`, `AppDelegate.swift`). Elle kilitte pano hemen
  temizlenir, otomatik kilitte 30 sn kuralı geçerli (kopyala-yapıştır akışı için).
- **Hatalı deneme:** 5 ücretsiz, sonra 30 sn → 1 dk → 5 dk → 15 dk → 1 sa (sabit). Kalıcı sayaç.
- **Ekran koruması:** Android `FLAG_SECURE` (`MainActivity.onCreate`, Flutter'dan önce). iOS
  `screen_protector` (bulanıklaştırma + ekran görüntüsünü siyah yapma).
- **İnternet:** Ana manifest INTERNET'i `tools:node="remove"` ile kaldırıyor; release APK'da izin yok
  (aapt ile doğrulandı). `allowBackup=false`, veri çıkarma kuralları kapalı.
- **Yedek:** ayrı yedek şifresi, Argon2id **64 MiB**/t=6/p=4, AES-256-GCM, başlık AAD ile doğrulanır,
  düz metin yalnızca başlık. Aşırı KDF parametreli dosya reddedilir; 50 MB sınırı. İçe aktarma
  **birleştirir** (daha yeni `updatedAt` kazanır, hiçbir kayıt silinmez); geçmiş de yedeklenir.
- **Şifre geçmişi:** kayıt başına son 10.
- **Silme (ertelenmiş):** onay yok; kayıt 5 sn "Geri al" süresince yalnızca gizlenir (şifre çözülmez),
  sonra silinir; kilitlenince bekleyen silmeler veritabanı kapanmadan tamamlanır (`beforeLockProvider`).
- **CSV içe aktarma:** düz metin yalnızca bellekte; file_picker'ın geçici kopyası her durumda silinir;
  TOTP anahtarları aktarılmaz; CSV'ye dışa aktarma yok (§10k).
- **Uyarı rozetleri / rapor:** yalnızca kayıt kimlikleri tutulur; ek şifre çözülmez.
- **Kayıt görünümü (simge/renk) ve kategori:** gizli değil, yalnızca SQLCipher ile korunur.
- **Kasa oluşturma geri alma:** veritabanı açılamazsa anahtar bilgileri + yarım DB silinir. **Yetim kasa**
  (anahtar var, DB dosyası yok — ör. iOS yeniden kurulum): açılışta temizlenir, kurulum ekranında not.

## 6. Bilinen tuzaklar / önemli ayarlar

- `android/gradle.properties`: **`android.builtInKotlin=true`** olmalı (yoksa `screen_protector`
  Kotlin kodu derlenmez). Derlemede "plugins that apply KGP: screen_protector" uyarısı normal.
- **M4 emülatör çökmesi:** OpenSSL (SQLCipher) emülatörün yanlış SVE bildirimi yüzünden SIGILL veriyordu.
  `EmulatorCompat.kt` yalnızca emülatörde `OPENSSL_armcap` ayarlıyor. Gerçek cihazda etkisiz.
- Testlerde fontlar kutu (Ahem) çizilir ve gölgeler bulanıksız (`debugDisableShadows`), BackdropFilter
  görünmez çizilir. **Görsel kontrol yöntemi:** geçici bir `test/zz_*_test.dart` içinde Inter/JetBrains
  Mono/MaterialIcons fontlarını `FontLoader` ile yükleyip (`MI_FONT` = Flutter SDK
  `bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf`), `debugDisableShadows = false` yapıp
  `matchesGoldenFile` + `--update-goldens` ile PNG almak; çıktıyı scratchpad'e taşıyıp test dosyasını
  projeden silmek (projede `zz_*` bırakma).
- **Animasyon tuzakları:** sıfır süreli `AnimatedSize` düzen hatası verir, sıfır süreli
  `AnimatedSwitcher` eski/yeni çocuğu bir kare üst üste gösterir → animasyonlar kapalıyken bunları hiç
  kullanma (`_AddButton`, `SpringSwap`). Yay eğrisi 1'i aşar: **FadeTransition / opaklığa verme**
  (assert), yalnızca konum/ölçek.
- **file_picker** seçilen dosyayı uygulama geçici klasörüne kopyalar (Android `cache/file_picker/`, iOS
  tmp). Düz metin dosyalarda bu kopya silinmeli (`CsvFileReader`).
- Sayfalar saydam (zemin `AppBackground` kökte): yeni ekran eklerken `Scaffold` arka planı verme; alt
  çubuk içeriğin üstünde (`extendBody`) olduğu için sekme ekranlarında alt boşluğa
  `MediaQuery.paddingOf(context).bottom` ekle.
- Test yardımcıları: favoriler şeridi yüzünden aynı başlık iki kez görünebilir → `entryText(title)` /
  `tapEntry(tester, title)`; Ayarlar listesi tembel → `scrollToSetting(...)`.
- Uygulamanın ekran görüntüsü `FLAG_SECURE` yüzünden siyah çıkar (adb screencap dahil); başlatıcı ve
  Android 12 sistem açılış ekranı yakalanabiliyor.
- Uzun `flutter test` çalıştırmalarında arka planda çalıştırıp `exit=` satırını beklemek pratik oldu.

## 7. Marka / logo

- Logo: petrol yeşili (#0F6E56) kutucukta **kasa kapısı + anahtar deliği**; koyu temada "Gece" renkleri.
  Kullanıcı tarafından eklendi (`lib/core/widgets/app_logo.dart` → `VaultKeyholePainter`).
- **"İY Labs" etiketi logonun parçası.** Etiketsiz logo yok (etiketsiz dosyalar silindi, seçenek
  kaldırıldı).
  - **Tüm logolar uygulama içi logo (AppLogo) düzeninde:** kasa tam ortada, küçük etiket kutucuğun sağ alt
    köşesinde, kasaya değmez (kullanıcı bunu bir ekran görüntüsüyle istedi).
  - iOS ve eski Android simgeleri: AppLogo ile birebir aynı oranlar.
  - Daire maskeli olanlar (Android uyarlanabilir simge, Android 12+ açılış): karenin köşesi daireyle
    kesildiği için etiket görünür dairenin sağ alt kenarında; kasa ~%85 boyutunda (0.38). Betik etiketin
    dairede kalmasını ve kasaya değmemesini denetler. Temalı simge (monochrome) ön katmanı kullanır.
- Ekranların altındaki küçük `ProducerLabel` de duruyor (kullanıcı "ikisi de kalsın" dedi).
- Üretim: `python3 tool/generate_brand_assets.py` (Pillow; etiket fontu `assets/fonts/Inter-Bold.ttf`)
  → iOS AppIcon, Android mipmap + uyarlanabilir simge (+ temalı/monochrome), `assets/brand/*`.
  Ardından `dart run flutter_native_splash:create`.

## 8. Tasarım (uygulanmış)

> **Güncel hâl için §10c–10l'ye bakın** (aşağıdaki paragraf ilk tasarım turunu anlatır; harf grupları,
> 12/16/20/32 hazır uzunluk ve 16 px köşeler artık yok).

Özet (güncel): koyu petrol tonlu zemin + ışıma, derinlikli kartlar (20 köşe), hap düğmeler (basınca
köşeleşir), yuvarlatılmış kare rozetler (simge/renk seçilebilir), favoriler şeridi, yerinde uyarı
rozetleri, buzlu cam ve kaydırınca küçülen alt çubuk, yay (spring) hareketi, Ayarlar'da bölümlü liste,
üreticide Rastgele/Kelimeler kipi, AMOLED seçeneği.

İlk tur: Petrol yeşili Material 3 tema (16 px köşeler), Inter/JetBrains Mono, alt/yan gezinme, harf rozetleri
(Türkçe baş harf, deterministik renk), harf grupları, kaydırma kısayolları (sağ: kopyala, sol: favori),
renkli şifre (rakam mavi, sembol turuncu), pano geri sayım halkası + "Şimdi temizle", Hero geçişi,
adımlı kurulum (2–3 adım), kartlı kayıt formu + kategori çipleri + canlı güç göstergesi, üretici
(büyük renkli gösterim, 12/16/20/32 hazır uzunluk), puanlı güvenlik raporu (uyarısız kayıt oranı),
şifre geçmişi zaman çizelgesi, kartlı Ayarlar, küçülen büyük başlık (Kasa, Rapor), sıralı belirme
(animasyon kapatma ayarına uyar), tablet/yatay düzen, boş durum çizimleri, isteğe bağlı Material You.

## 9. Testler

- `test/` altında birim + widget testleri; **323 test**. Yardımcılar: `test/helpers/test_app.dart`
  (`pumpApp`, `FakeAuthController`, `openTab`, `openSettings`, `expectProducerLabel`, `tapVisible`,
  `scrollToSetting`, `entryText`, `tapEntry`), tasarım turlarının testleri `test/features/design*_test.dart`,
  CSV: `test/data/csv_import_test.dart`, `test/features/csv_import_screen_test.dart`,
  `fake_vault_repository.dart`, `in_memory_store.dart` (`fastTestKdf`).
- SQLCipher testleri host'ta gerçekten çalışıyor (`vault_database_test.dart`).

## 10. Sık kullanılan komutlar

```bash
flutter test
flutter analyze
flutter gen-l10n                       # ARB değişince
dart run build_runner build            # drift tabloları değişince
python3 tool/generate_brand_assets.py  # logo/simge değişince
dart run flutter_native_splash:create  # açılış ekranı
dart run tool/kdf_benchmark.dart       # Argon2id süresi (Mac AOT ~250 ms)
flutter build apk --release            # izin kontrolü: aapt dump permissions …
```

## 10b. Temizlik ve hızlandırma turu (10 Kasım 2026)

- Ölü kod silindi: `countHistory`, `VaultQuery.hasFilters`, `AppInfo.packageId`, `AppTheme.splash*`,
  `EntrySummary.hasNotes`, `PasswordHistoryItem.entryId`, kullanılmayan 8 ARB metni. README Türkçe.
  Yalnızca testte kullanılan `failureCount` / `hasPendingClear` → `@visibleForTesting`.
- Açılış ekranı en az süresi 800 → **300 ms**.
- Güvenlik raporu yalnızca kayıt kümesi veya `updatedAt` değişince yeniden hesaplanır (favori
  değişikliği tüm şifreleri çözdürmez).
- Kasa listesi `SliverList.builder` (tembel) + `findChildIndexCallback`.
- Arama/sıralama anahtarları kayıt başına bir kez (`Expando`, `vault_query.dart`); `TurkishText.fold`
  hızlandı, `compareLowered` eklendi; güç ölçer RegExp'leri statik; marka temaları önbellekte.
- Teklif edilip **kullanıcı tarafından reddedilenler (yapılmayacak, tekrar önerme):** B5 APK bölme
  (`--split-per-abi` / `.aab`, `--obfuscate --split-debug-info`), B6 SQLCipher WAL kipi, B7 Argon2id
  ölçümü / yerel Argon2. (Bilgi: release hâlâ debug anahtarıyla imzalanıyor.)
- Hız değerlendirmesi için VS Code'da debug değil **profile/release** kullanılmalı.

## 10c. Arayüz değişiklikleri (10 Kasım 2026, kullanıcı isteği)

- **En az şifre uzunluğu 10** (ana şifre VE yedek şifresi; `CryptoParams`). Kullanma talimatı metni güncel.
- Kasa listesinde **baş harf gruplandırması kaldırıldı**; her kayıt bir **Card** içinde (kaydırma arka
  planı kart köşelerine kırpılır, iki sütunda seçili kart `secondaryContainer`).
- Üreticideki **"Hızlı seçim"** (12/16/20/32) kaldırıldı; uzunluk yalnızca kaydırıcıyla.
- **Geçiş animasyonları** (`lib/core/theme/page_transitions.dart`): sekmeler arasında fade-through
  (`FadeThroughBranches`, `StatefulShellRoute.navigatorContainerBuilder`; sekme yığınları korunur),
  sayfalarda Material 3 shared axis (Android). iOS'ta sistem geçişi (kenardan geri kaydırma için).
  İkisi de "animasyonları kapat" ayarına uyar. Ek paket kullanılmadı.

## 10d. Tasarım turu 2 — 1. ve 2. grup (10 Kasım 2026)

- **Kullanım hızı:** kasa kartında tek dokunuşla şifre kopyalama düğmesi (`entry_copy_{id}`), uzun basınca
  işlem paneli (`showEntryActions`: kullanıcı adı/şifre/URL kopyala, favori, düzenle), arama + filtre
  çipleri kaydırınca üstte sabit (`_PinnedHeader`), çiplerde kategori simgesi + sayı. Detayda büyük
  "Kullanıcı adı" / "Şifre" kopyalama düğmeleri; **Sil** üç nokta menüsünde (`detail_more`). Kopyalanınca
  simge ✓ olur (`core/widgets/copy_feedback.dart`). Girişte biyometri kapalıysa şifre alanı odaklı.
- **Görünüm:** özel yazı ölçeği (`AppTheme._textTheme`, eşit genişlikli rakamlar), kartlarda ince kenar,
  basınca küçülme (`pressable_scale.dart`), giriş/kurulumda renk geçişli arka plan (`brand_backdrop.dart`),
  biyometri girişte ana eylem. Üretici: dört karakter çipi (ABC/abc/123/#$%) + büyük uzunluk; **son seçenekler
  `settings.generator` anahtarında saklanır** (şifre değil). Ayarlar'da tema satır içi `SegmentedButton`.
  Raporda renk geçişli, sayarak dolan puan halkası ve "Değiştir" düğmesi (düzenleme ekranını açar).

## 10e. Tasarım turu 2 — 3. grup (10 Kasım 2026)

- **Silmede "Geri al" (ertelenmiş silme):** onay penceresi kaldırıldı. `PendingDeletions`
  (`features/vault/application/pending_deletions.dart`) kaydı listeden hemen gizler, 5 sn sonra siler.
  Bu sürede şifre çözülmez/bellekte tutulmaz (yalnızca id). **Kilitlenince** (elle, hareketsizlik, arka plan)
  bekleyen silmeler veritabanı kapanmadan tamamlanır: `beforeLockProvider` kancası
  (`AuthController.lock` başında). Kabul edilen risk: tam o 5 sn'de uygulama zorla kapanırsa kayıt kalır.
  `entriesProvider` artık gizlenenleri süzen bir `Provider`; ham akış `storedEntriesProvider`.
- **Kelime tabanlı şifre:** üreticide "Rastgele / Kelimeler" kipi. Liste `features/generator/data/turkish_words.dart`
  (**2334 kelime**, tarafımızca hazırlandı, yalnızca a–z, 3–8 harf; kurallar testte denetlenir). Varsayılan
  6 kelime + 2 haneli sayı, ayırıcı `- . _`, büyük harf seçeneği. Güç **seçim uzayından** (kelime × log2(N)
  + sayı) hesaplanır, ≈ bit gösterilir (`PasswordStrengthMeter(bits:)`). Kip ve seçenekler saklanır
  (`settings.generator_mode`, `settings.passphrase`).
- **AMOLED:** Ayarlar > Görünüm "Tam siyah zemin" (`settings.true_black`, `AppTheme.trueBlack`), Material You ile de çalışır.
- **Son kullanılanlar bölümü: kullanıcı istemedi (yapılmayacak).**
- Kullanma talimatı (silme, kopyalama, uzun basma, kelime kipi) güncellendi.

## 10f. Zemin, derinlik ve efektler (10 Kasım 2026)

- **Zemin:** `AppSurfaces` (ThemeExtension, `core/theme/app_surfaces.dart`) zemin/kart/gölge/parıltı renklerini
  şemadan türetir. Açık temada zemin petrol tonlu gri-yeşil, kartlar beyaz; koyu temada zemin bir ton koyu,
  kartlar açık; tam siyahta zemin siyah. **Sayfalar (Scaffold) saydam**; zemin + yumuşak ışıma uygulama kökünde
  tek katman (`AppBackground`, `MaterialApp.builder`). iOS kayma geçişinde her sayfa kendi zeminini taşır
  (`OpaquePageTransitionsBuilder`). Başlık çubukları saydam, altından içerik geçince zemin renginde.
- **Derinlik:** `DepthCard` (`core/widgets/depth_card.dart`): iki katmanlı yumuşak gölge (açık), üst kenar ışığı
  (koyu), basınca küçülme + gölgenin içeri çekilmesi, seçili kartta parıltı. Genel `Card` teması da gölgeli.
  `GlowBox`: "+ Yeni kayıt" çevresinde parıltı. Raporda yalnızca sorun olan özet kartı parlar; puan halkasında
  bulanık parıltı. Eski `PressableScale` silindi.
- **Buzlu cam:** `GlassSurface` — alt gezinme çubuğu (Scaffold `extendBody`) ve kasadaki sabit arama başlığı.
  Çubuk içeriğin üstünde olduğu için sekme ekranlarına `MediaQuery.paddingOf(context).bottom` kadar alt boşluk,
  boş/hata durumlarına da aynı boşluk eklendi; FAB bu fark kadar yukarı alınır (Scaffold kendisi almıyor).
- Testlerde gölgeler bulanıksız, BackdropFilter görünmez çizilir; görsel kontrol gerçek fontlarla golden
  çıktısı alınarak yapıldı (geçici test, projede bırakılmadı).

## 10g. Hızlı erişim, kayıt görünümü, yerinde uyarılar (11 Kasım 2026)

Benzer uygulama araştırmasından (1Password, Apple Passwords, Proton Pass, Bitwarden…) seçilen 1–3. öneriler.
- **Favoriler şeridi** (`_FavoritesStrip`, kasa listesi): arama/filtre yokken ve favori varken görünür.
  Dokununca şifre kopyalanır, uzun basınca işlem paneli ("Ayrıntıları aç" eklendi; panel artık
  `isScrollControlled` + kaydırılabilir).
- **Kayda özel simge/renk:** `core/widgets/entry_appearance.dart` (38 gömülü simge, 12 renk; anahtarlar
  DEĞİŞTİRİLMEZ), `EntryAvatar` (seçim yoksa eski `LetterAvatar` ile birebir aynı). Formda "Görünüm" satırı →
  `appearance_sheet.dart` ("Tamam" altta sabit). İnternetten logo yok, marka logosu yok.
  **Veritabanı şema 2:** `entries.icon_key`, `entries.color_key` (nullable; `onUpgrade` ile eklenir, testte
  gerçek SQLCipher dosyasıyla doğrulandı). Depo geçersiz anahtarı (`^[a-z0-9_]{1,32}$` dışı) atar.
  **Yedek:** isteğe bağlı `icon` / `color` alanları; biçim sürümü 1 kaldı (geriye/ileriye uyumlu).
- **Yerinde uyarılar:** `entryIssuesProvider` (rapordan; ek şifre çözmez). Listede "Zayıf"/"Tekrar"
  rozeti (`IssueBadge`), detayda uyarı kartı ("şu kayıtlarla aynı" + "Şifreyi değiştir").
- Test yardımcıları: `entryText(title)` (listedeki kart; şerit hariç), `tapEntry(tester, title)`.
- Otomatik doldurma (Faz 6): **kullanıcı 11 Kasım 2026'da pas geçti** — kendisi istemedikçe önerme.

## 10h. Kaydırınca küçülen alt çubuk (11 Kasım 2026)

- `HomeShell` artık Stateful: dikey `UserScrollNotification` aşağı → kompakt (80 → 56, yazılar gizli,
  ipucu = sekme adı), yukarı / en üst / sekme değişimi → açık. Yatay kaydırmalar yok sayılır. Yan çubuk
  düzeninde küçülme yok. Durum `ShellChrome` (InheritedNotifier) ile alt ekranlara iletilir.
- "+ Yeni kayıt" (`_AddButton`) kompaktta yalnızca "+" (AnimatedSize). **Animasyonlar kapalıyken
  AnimatedSize kullanılmaz** (sıfır süreyle Flutter düzen hatası veriyor).
- `core/theme/motion.dart`: `AppMotion.spring` (SpringSimulation tabanlı Curve) ve `AppMotion.of(context)`
  (animasyon kapalıysa sıfır süre).
- Büyük başlık (SliverAppBar.large) altından içerik geçerken artık **opak** (yarı saydamlık bulanıklık
  olmadan "hayalet" yazı gösteriyordu).

## 10i. Yay hareketi ve şekiller — M3 Expressive (11 Kasım 2026)

- **Şekiller:** `AppTheme.radius` 16 → **20** (kart, FAB, DepthCard); metin alanları `fieldRadius` 16; alt
  paneller üstte 28. Dolu/çerçeveli düğmeler **hap**; basılıyken köşe 12'ye "sertleşir"
  (`AppTheme.buttonShape`, Material şekil geçişini kendisi canlandırır). Rozetler (Letter/EntryAvatar)
  **yuvarlatılmış kare** (`LetterAvatar.shapeOf` = boyut × 0,3).
- **Ayarlar bölümlü liste:** her satır ayrı Card (anahtar `settings_segment_{grup}_{i}`), 3 pt boşluk, dış
  köşe 20 / iç köşe 6, ayırıcı yok.
- **Yay (`AppMotion.spring`) nerede:** kart bırakma (basma hızlı easeOut), kopyala ✓, favori yıldızı
  (`SpringSwap`; detay + liste), liste belirme kayması, sekme geçişi büyümesi, sayfa geçişi kayması,
  üreticide yeni şifre ölçeği. **Bilinçli olarak yok:** saydamlık/renk (yay 1'i aşar; FadeTransition'a
  verilmemeli), puan halkası/sayaçlar/geri sayım (değer bir an yanlış görünmesin).
- Animasyonlar kapalıyken `SpringSwap` ve `_AddButton` doğrudan çocuğu döndürür (AnimatedSwitcher /
  AnimatedSize sıfır süreyle sorun çıkarıyor).

## 10j. Kurulumda ana şifre rehberliği (11 Kasım 2026)

- 1. adım: "İyi bir ana şifre nasıl seçilir?" açılır kartı (3 ipucu) + "Bana bir öneri üret"
  (`SetupScreen.suggestionOptions`: 5 kelime + sayı, Türkçe liste). "Kullan" **yalnızca ilk alanı** doldurur,
  tekrar alanı boşaltılır (kullanıcı kendisi yazar). Öneri yalnızca bellekte; dispose'da bırakılır.
- Zayıf ana şifre (güç "Çok zayıf"/"Zayıf"): **engellemez, uyarır** — "Şifreyi değiştir" / "Yine de devam et".
  En az 10 karakter kuralı aynen.
- 2. adım: somut saklama listesi (kâğıda yaz, telefonda saklama, yedek al); eski `setupStepWarningTip` silindi.
- Kurulum kaydırma alanına üst/alt solma (ShaderMask).
- **Kullanıcı kararı: "ara ara ana şifre iste" hatırlatması YAPILMAYACAK (tekrar önerme).**

## 10k. CSV içe aktarma (11 Kasım 2026)

- Ayarlar > Veri > "Başka uygulamadan içe aktar" → `CsvImportScreen` (`/settings/import-csv`): bilgi →
  dosya → önizleme (şifre gösterilmez) → içe aktar → "orijinal dosyayı silin" hatırlatması.
- `data/import/csv_parser.dart` (bağımlılıksız RFC 4180: tırnak, alan içi satır sonu, `,`/`;`/sekme
  algılama, BOM) ve `csv_import.dart` (`CsvImporter`: sütun adı eşanlamlıları TR/EN; Chrome, Firefox,
  Apple, Bitwarden, 1Password, Proton Pass, KeePass algılama; Firefox'ta başlık adresten). Sınırlar:
  10 MB, 10.000 satır. UTF-8, olmazsa Latin-1.
- **Kullanıcı kararları:** birebir aynı (başlık+kullanıcı adı+adres+şifre) kayıtlar atlanır (kasada veya
  dosyada); **TOTP anahtarları aktarılmaz**, sayısı bildirilir. CSV'ye DIŞA aktarma yok.
- **Güvenlik bulgusu:** file_picker seçilen dosyayı uygulamanın geçici klasörüne kopyalıyor (Android
  `cache/file_picker/`, iOS tmp). `CsvFileReader` okuduktan sonra bu kopyayı her durumda (hata/iptal
  dahil) siler + `FilePicker.clearTemporaryFiles()`; kullanıcının orijinal dosyasına dokunmaz
  (yalnızca `/file_picker/` veya sistem tmp altındaki yollar).
- `VaultRepository.addEntries` (tek işlem; biri geçersizse hiçbiri eklenmez). Dosya seçerken otomatik
  kilit askıya alınır (`runWithAutoLockSuspended`). Kategori: Diğer.
- Kullanma talimatına "Başka uygulamadan aktarma" bölümü eklendi.

## 10l. Küçük düzeltme (11 Kasım 2026)

- Üreticide seçili karakter çipleri (ABC/abc/123/#$%) ve kelime kipindeki seçili ayırıcı çipi artık ana düğme
  renginde (`primary` zemin, `onPrimary` yazı, kenarlık yok); seçili olmayanlar sade.

## 10m. Gerçek cihaz düzeltmeleri (12 Kasım 2026)

Kullanıcı gerçek telefonda denedi, iki hata bildirdi:
- **Biyometri "İptal" → ana şifreye dönülemiyordu.** Kök neden: `flutter_secure_storage` 11.2.0 Android
  kodu `BiometricPrompt` olumsuz düğmesine BOŞ dinleyici bağlıyor (`(dialog, which) -> {}`); "İptal"e
  basınca platform çağrısı hiç tamamlanmıyor (geri tuşu / dışarı dokunma `onAuthenticationError` ile
  dönüyor). Giriş ekranı beklerken `_busy` ile şifre alanını kilitlediği için kalıcı takılma oluyordu.
  Düzeltme (`login_screen.dart`): biyometri bekleme durumu (`_biometricPending`) şifre alanını/düğmesini
  kilitlemez; istem görüldükten (`inactive`) sonra uygulama öne dönünce (`resumed`) 800 ms içinde sonuç
  gelmezse deneme iptal sayılır, hata gösterilir, şifre alanına odaklanılır, biyometri düğmesi yeniden
  etkin olur. Geç gelen başarı yine kabul edilir. Eklenti güncellenirse bu davranışı yeniden kontrol et.
- **Pano bildirimi 30 sn sonra kapanmıyordu.** Kök neden: Flutter'da düğmeli `SnackBar`'lar varsayılan
  `persist: true` (süre işlemez). Pano bildirimi ve silme "Geri al" bildirimi `persist: false` yapıldı
  (Geri al da 5 sn sonra kapanıyor; önceden silme olduğu hâlde ekranda kalıyordu). **Yeni düğmeli
  SnackBar eklerken `persist: false` unutma.**
- `PasswordField`'a `focusNode` eklendi; `FakeAuthController.biometricCompleter` ile "hiç dönmeyen"
  biyometri test edilebilir (`device_fixes_test.dart`).

## 10n. Gerçek cihaz geri bildirimi 2 (13 Kasım 2026)

- **Biyometri iptalinde uyarı yok:** `isBiometricCancellation` (vault_key_repository_impl.dart; Android
  kod 5/10/13, iOS -128) → `BiometricCancelledException` → `UnlockResult.cancelled`; giriş ekranı yalnızca
  gerçek hatada (`UnlockResult.error`: çok fazla deneme, anahtar geçersiz, donanım) `loginBiometricFailed`
  gösterir; "İptal" düğmesi (sonuç döndürmeyen) zamanlayıcı yolu da sessiz. (Bu kısım ve alttaki menü adı
  diskte başka bir oturumda yapılmıştı; testleri bu turda eklendi.)
- Alt menü: **"Şifre Üretici"** (`navGenerator`); talimat metni de güncel.
- **Kayıt hatasının nedeni:** `features/vault/application/save_error.dart` (`classifySaveError`: kilitli,
  boş alan, disk dolu, veritabanı meşgul, veritabanı kodu, şifreleme, bilinmeyen=tür adı; gizli veri
  yok). Formda ayrı mesajlar (6 sn). Ekranı kapatma artık try dışında (kayıt başarılıyken gezinme hatası
  "kaydedilemedi" gösteriyordu — olası gerçek neden). Kullanıcının cihazındaki asıl hata yeniden
  üretilemedi; yeni mesajdaki ayrıntı/kod sorulacak.
- **Favoriler şeridi:** hap biçimli küçük kutular (yükseklik ~56): açıklayıcı simge (kayda seçilen, yoksa
  kategori simgesi — `EntryAvatar.fallbackIcon`) + başlık + küçük kopyala simgesi; şerit gölgeleri
  kırpmaz (`Clip.none`).
- **Gölgeler artırıldı:** `cardShadows` açık 0,18→0,24 (blur 22, offset 9), koyu 0,45→0,55; Card teması
  elevation 3, gölge rengi 0,55.

## 10o. Google Play hazırlığı (15 Kasım 2026)

- **İmza:** `android/app/build.gradle.kts` `android/key.properties` varsa yayın derlemesini o anahtarla
  imzalar; yoksa uyarı verip debug anahtarı kullanır (Play kabul etmez). Şablon:
  `android/key.properties.example`. Anahtarı **kullanıcı kendisi** oluşturur (komut rehberde;
  Android Studio JBR `keytool`, alias `upload`, dosya `~/keys/kilitdepo-upload.jks`). Claude parolayı
  görmez / girmez. `key.properties` ve `*.jks` gitignore'da.
- `ndk { debugSymbolLevel = "SYMBOL_TABLE" }` (AAB'de semboller). Kod gizleme yok.
- **AAB zorunlu** (Play yeni uygulamada APK almıyor) — B5 reddi bu yüzden yayın için geçersiz; kullanıcıya
  açıklandı. `flutter build appbundle --release` → 73,4 MB (şu an debug imzalı, anahtar bekleniyor).
- `store/`: `listing-tr.md` (ad/kısa/tam açıklama; `python3 tool/check_store_listing.py` sınır
  kontrolü), `graphics/icon-512.png` + `feature-graphic.png` (`python3 tool/generate_store_assets.py`),
  `screenshots/01…08` 1080×1920 (`flutter test tool/store/screenshots_test.dart --update-goldens`; örnek
  veriler marka adı içermez), `play-console-rehberi.md` (form yanıtları: veri toplanmıyor, 18+, reklam
  yok, Araçlar; kişisel hesaplarda 12 test kullanıcısı / 14 gün kapalı test).
- `docs/privacy-policy.md` (TR + EN özet). Mağazadaki bağlantı GitHub'daki bu dosya; **GitHub'a gönderilmesi
  kullanıcı onayına bağlı.**

## 11. Açık işler (öncelik sırasıyla öneri)

1. **iOS doğrulama:** Kullanıcı Xcode + CocoaPods kurunca (`sudo xcode-select …`, `brew install
   cocoapods`) iOS'ta derle; pano kanalı (Swift), ekran koruması, Face ID, simge/açılış ekranını dene.
2. **screen_protector'ı kaldırma:** Kullanıcı kararı: **iOS'ta test edilebilene kadar kalsın.** Sonra iOS
   bulanıklaştırma + ekran görüntüsü engelini kendi Swift kodumuza taşı (ScreenProtectorKit'in
   belgelenmemiş "güvenli metin alanı" yöntemi; dikkatli test gerekir).
3. **Faz 6 (kullanıcı "şimdilik yapma" demişti; mimari hazır):** KeePass `.kdbx` dışa aktarma, TOTP.
   **Otomatik doldurma (Android Autofill / iOS AutoFill): kullanıcı 11 Kasım'da pas geçti — istemedikçe
   önerme.** Her kaydın kalıcı `uuid`'si var; **şema sürümü 2** (drift `onUpgrade`; yeni sütun eklerken
   3'e çıkar ve geçiş testi yaz, bkz. `design6_test.dart`).
3b. **Yayın:** dosyalar hazır (§10o). Kalan: kullanıcı yükleme anahtarını oluşturacak, `key.properties`
   dolduracak; ardından imzalı AAB derlenip doğrulanacak. Her güncellemede `pubspec.yaml` sürüm kodu artmalı.
   (Obfuscate önerisi reddedildi — tekrar önerme.)
4. Küçük: küçük logolarda (kurulum, giriş) "İY Labs" yazısı okunmayacak kadar küçük — kullanıcı
   istemedikçe dokunma.

## 12. Oturumda alınan kullanıcı kararları (özet)

- Flutter güncellendi; SQLCipher `sqlite3` hooks ile; Riverpod kod üretimsiz.
- Notlar da alan düzeyinde şifreli; pano temizleme Faz 2'de; geçmiş son 10; aranabilir alanlar SQLCipher.
- Otomatik kilitte pano 30 sn kuralı; bekleme tablosu 30 sn→1 sa; veri silme yok; iOS screen_protector.
- Yedek: file_picker; birleştirme; yedekte 64 MiB; geçmiş dahil.
- Biyometri açarken ana şifre; süre seçenekleri onaylı; son yedek tarihi gösterilir.
- B1 (kurulum geri alma) yapıldı; B2'de paket kaldı; alt etiket ve logo etiketi ikisi de kalsın.
- Tasarım: petrol yeşili, alt gezinme, Inter, Material You seçenek olarak (varsayılan kapalı).
- 10–11 Kasım tasarım/özellik kararları: B5 APK bölme, B6 WAL, B7 Argon2 ölçümü reddedildi; en az şifre
  uzunluğu 10; ertelenmiş silme (5 sn); kendi Türkçe kelime listesi (2334, ASCII); AMOLED ayrı anahtar;
  **"son kullanılanlar" istenmedi**; zemin iki temada koyu + yumuşak gölge + tüm efektler; araştırma
  önerileri 1–3 (favori şeridi: dokununca kopyalar; simge/renk; yerinde uyarılar); küçülen alt çubuk
  (kompakt, gizlenmez); yay hareketi + yuvarlatılmış kare rozet + Ayarlar bölümlü liste; ana şifre
  rehberliği (zayıf şifre engellemez, uyarır; **"ara ara ana şifre iste" hatırlatması istenmedi**); CSV
  içe aktarma (birebir aynılar atlanır, TOTP aktarılmaz); otomatik doldurma pas geçildi; üreticide seçili
  çipler (karakterler + ayırıcı) ana düğme renginde.
- **Git / GitHub:** 14 Kasım 2026'da kullanıcının isteğiyle proje git deposu yapıldı ve
  `git@github.com:ibrahimyasar68/KilitDepo.git` (dal `main`) adresine gönderildi (SSH anahtarı
  `~/.ssh/id_ed25519_skorekran`). Depo içi kimlik: `ibrahimyasar68` /
  `ibrahimyasar68@users.noreply.github.com` (kişisel e-posta herkese açık commit'lere yazılmasın diye).
  **Yine de kullanıcı istemedikçe commit / push yapma.**
