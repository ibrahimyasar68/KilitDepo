# KilitDepo — Google Play'de yayımlama rehberi

Bu rehber, KilitDepo'yu Google Play Console'a yüklemek için gereken her adımı ve Play
Console'daki formlara verilecek yanıtları içerir. Mağaza metinleri ve görseller için:
[listing-tr.md](listing-tr.md).

> Kurallar zamanla değişebilir. Play Console bir adımda farklı bir şey isterse ekrandaki
> yönergeyi esas alın.

---

## 1. Yükleme (imza) anahtarını oluşturun — bir kez

Bu anahtar, uygulamanın güncellemelerini sizin yayımladığınızı kanıtlar. **Parolayı siz
belirleyin ve kimseyle paylaşmayın.** Anahtar dosyasını proje klasörünün dışında tutun.

Terminalde (macOS) şu komutları çalıştırın:

```bash
mkdir -p ~/keys
```

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkeypair -v -keystore ~/keys/kilitdepo-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Komut sizden bir **anahtar deposu parolası** ve ad/kuruluş bilgileri ister (ad: İY Labs,
ülke kodu: TR gibi). Anahtar parolası sorulursa aynı parolayı kullanabilirsiniz.

Ardından `android/key.properties.example` dosyasını **`android/key.properties`** adıyla
kopyalayıp kendi değerlerinizle doldurun:

```properties
storePassword=<belirlediğiniz parola>
keyPassword=<belirlediğiniz parola>
keyAlias=upload
storeFile=/Users/<kullanıcı adınız>/keys/kilitdepo-upload.jks
```

- `key.properties` ve `.jks` dosyası git'e girmez (`.gitignore`'da). GitHub'a göndermeyin.
- **Yedekleyin:** `.jks` dosyasını ve parolayı güvenli bir yerde saklayın (ör. şifreli USB
  bellek + parola KilitDepo'nun kendisinde). Play Uygulama İmzalama kullanıldığı için bu anahtar
  kaybolursa Play Console'dan yükleme anahtarı sıfırlama istenebilir; yine de saklayın.

## 2. Yayın paketini (AAB) derleyin

```bash
flutter build appbundle --release
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`

`key.properties` yoksa derleme uyarı verir ve paket **debug anahtarıyla** imzalanır — Play
bunu kabul etmez. İmzayı kontrol etmek için:

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/jarsigner" -verify -verbose:summary build/app/outputs/bundle/release/app-release.aab
```

Çıktıda `CN=Android Debug` değil, sizin girdiğiniz ad görünmelidir.

**Her güncellemede** `pubspec.yaml` içindeki sürümü artırın: `version: 1.0.1+2` (artı
işaretinden sonraki sayı — sürüm kodu — her yüklemede büyümek zorundadır).

## 3. Geliştirici hesabı ve uygulama oluşturma

1. [play.google.com/console](https://play.google.com/console) adresinde geliştirici hesabı açın
   (tek seferlik kayıt ücreti, kimlik doğrulama).
2. **Uygulama oluştur:** Ad `KilitDepo`, varsayılan dil **Türkçe – tr-TR**, tür **Uygulama**,
   **Ücretsiz**. Beyanları onaylayın.

> **Ücretsiz/ücretli kararı:** Ücretsiz yayımlanan bir uygulama sonradan ücretliye
> çevrilemez.

## 4. Kurulum formları (Gösterge tablosu > "Uygulamanızı kurun")

| Form | Yanıt |
|---|---|
| **Gizlilik politikası** | `https://github.com/ibrahimyasar68/KilitDepo/blob/main/docs/privacy-policy.md` |
| **Uygulama erişimi** | "Tüm işlevler özel erişim olmadan kullanılabilir". (Giriş bilgisi yok; inceleyici ilk açılışta kendi ana şifresini belirleyerek kasa oluşturur.) |
| **Reklamlar** | Hayır, uygulamamda reklam yok |
| **İçerik derecelendirmesi** | Kategori: **Yardımcı Program / Verimlilik / İletişim / Diğer**. Şiddet, cinsellik, küfür, uyuşturucu, kumar: **hayır**. Kullanıcılar arası iletişim / içerik paylaşımı: **hayır**. Konum paylaşımı: **hayır**. Dijital ürün satın alma: **hayır**. |
| **Hedef kitle** | **18 yaş ve üzeri** (çocuklara yönelik değil) |
| **Haber uygulaması** | Hayır |
| **COVID-19 / sağlık / finans / kamu** | Hayır (finansal hizmet sunmuyor; yalnızca kullanıcının kendi şifrelerini saklıyor) |
| **Veri güvenliği** | Aşağıdaki bölüm |
| **Uygulama kategorisi** | Araçlar · iletişim e-postası: sizin geliştirici e-postanız |

### Veri güvenliği formu

| Soru | Yanıt |
|---|---|
| Uygulamanız gerekli kullanıcı verisi türlerinden herhangi birini topluyor veya paylaşıyor mu? | **Hayır** |

"Hayır" seçildiğinde şifreleme ve silme soruları sorulmaz. Neden doğru:

- Uygulamanın **internet izni yok**; hiçbir veri cihazdan çıkmaz (Play'in tanımına göre
  "toplama", verinin cihazdan geliştiriciye veya üçüncü tarafa aktarılmasıdır).
- Yalnızca cihazda işlenen veriler "toplanan veri" sayılmaz.
- Reklam/analiz/çökme raporu SDK'sı yok.

> İnceleyici sorarsa: "Tüm veriler yalnızca cihazda, şifreli saklanır; uygulamanın INTERNET izni
> yoktur (AndroidManifest'te `tools:node="remove"` ile kaldırılmıştır)."

## 5. Mağaza sayfası

Büyüme > Mağaza varlığı > Ana mağaza girişi: [listing-tr.md](listing-tr.md) içindeki ad, kısa ve
tam açıklama; `store/graphics/` (simge, tanıtım görseli) ve `store/screenshots/` (8 telefon
ekran görüntüsü). Tablet görüntüleri isteğe bağlıdır.

## 6. Test ve yayın sırası

1. **Dahili test** (Test > Dahili test): AAB'yi yükleyin, kendinizi test kullanıcısı olarak
   ekleyin, Play'den kurup deneyin. Play burada imzayı ve hedef API düzeyini kontrol eder.
2. **Kapalı test:** **Kasım 2023'ten sonra açılan kişisel geliştirici hesaplarında**, üretime
   geçmeden önce **en az 12 test kullanıcısının 14 gün boyunca** kapalı teste katılmış olması
   gerekir (kurumsal hesaplarda bu şart yoktur). Test kullanıcılarını e-posta listesiyle ekleyin.
3. **Üretim:** Ülkeler (Türkiye veya tümü), sürüm notları (ör. "İlk sürüm"), incelemeye gönder.
   İlk inceleme birkaç gün sürebilir.

## 7. Uygulamanın teknik özellikleri (bilgi)

| Özellik | Değer |
|---|---|
| Paket adı | `com.iylabs.kilitdepo` (**yayından sonra değiştirilemez**) |
| Sürüm | 1.0.0 (sürüm kodu 1) |
| En düşük / hedef Android | 9 (API 28) / 16 (API 36) |
| İzinler | Yalnızca biyometri (`USE_BIOMETRIC`, `USE_FINGERPRINT`); **INTERNET yok** |
| Kod gizleme | Yok (zorunlu değil) |
| Yerel hata ayıklama sembolleri | AAB içinde (Play uyarısı çıkmaz) |
| Play Uygulama İmzalama | Kullanılır (önerilen varsayılan) |

## 8. Kontrol listesi

- [ ] Yükleme anahtarı oluşturuldu ve yedeklendi
- [ ] `android/key.properties` dolduruldu (git'e eklenmedi)
- [ ] `flutter build appbundle --release` → imza kontrolü `CN=Android Debug` DEĞİL
- [ ] Gizlilik politikası bağlantısı tarayıcıda açılıyor
- [ ] Mağaza metinleri ve görseller yüklendi
- [ ] Veri güvenliği, içerik derecelendirme, hedef kitle, reklam, uygulama erişimi formları
- [ ] Dahili test → (gerekiyorsa 14 günlük kapalı test) → üretim
