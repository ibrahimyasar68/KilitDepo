# KilitDepo — Google Play mağaza sayfası (Türkçe)

Play Console > Büyüme > Mağaza varlığı > Ana mağaza girişi bölümüne kopyalanacak metinler.
Karakter sınırları kontrol edildi (`python3 tool/check_store_listing.py`).

## Uygulama adı (en fazla 30 karakter)

```
KilitDepo
```

## Kısa açıklama (en fazla 80 karakter)

```
Şifreleriniz yalnızca cihazınızda: çevrimdışı, şifreli ve reklamsız kasa.
```

## Tam açıklama (en fazla 4000 karakter)

```
KilitDepo, şifrelerinizi yalnızca kendi telefonunuzda, güçlü şifrelemeyle saklayan çevrimdışı bir şifre yöneticisidir. Hesap açmanız gerekmez, bulut yoktur, reklam yoktur. Uygulamanın internet izni bile yoktur; verileriniz cihazınızdan çıkmaz.

TEK ANA ŞİFRE, TÜM ŞİFRELERİNİZ
• Kasanızı tek bir ana şifreyle ya da parmak izi / yüz tanıma ile açın.
• Kayıtlarınızı başlık, kullanıcı adı, adres, not ve kategoriyle düzenleyin.
• Kayıtlara simge ve renk vererek listede kolayca ayırt edin.
• Sık kullandıklarınız "Favoriler" şeridinde tek dokunuşla elinizin altında.

HIZLI VE KOLAY
• Şifreyi tek dokunuşla kopyalayın; pano belirlediğiniz süre sonunda (varsayılan 30 sn) otomatik temizlenir.
• Uzun basarak kullanıcı adı, şifre veya adresi kopyalayın, düzenleyin.
• Türkçe karakterlere duyarlı arama, kategori filtreleri ve sıralama.

GÜÇLÜ ŞİFRE ÜRETİCİ
• Rastgele şifreler: 8–64 karakter; büyük/küçük harf, rakam, sembol seçimi.
• Akılda kalan kelime tabanlı şifreler (ör. Kartal-Limon-Dere-Masa-Bulut-47); gücü gerçekçi olarak gösterilir.
• Karışabilecek karakterleri (0/O, 1/l) dışarıda bırakma seçeneği.

GÜVENLİK RAPORU
• Zayıf ve birden fazla yerde kullanılan şifreleri bulur, 100 üzerinden puan verir.
• Sorunlu kayıtlar listede işaretlenir; "Şifreyi değiştir" ile hemen düzeltirsiniz.

GÜVENLİK
• Ana şifreniz hiçbir yerde saklanmaz. Anahtar, Argon2id ile ana şifrenizden türetilir.
• Veritabanının tamamı SQLCipher ile, şifreler ve notlar ayrıca AES-256-GCM ile şifrelenir.
• Uygulama arka plana geçtiğinde ve belirlediğiniz hareketsizlik süresinde otomatik kilitlenir.
• Ekran görüntüsü ve son uygulamalar önizlemesi engellenir.
• Arka arkaya hatalı ana şifre denemelerinde artan bekleme süresi uygulanır.

YEDEKLEME VE TAŞIMA
• Ayrı bir yedek şifresiyle tamamen şifrelenmiş yedek dosyası oluşturun ve geri yükleyin.
• Chrome, Firefox, Safari, Bitwarden, 1Password, Proton Pass ve KeePass'tan dışa aktardığınız CSV dosyasıyla kayıtlarınızı kolayca taşıyın.

GİZLİLİK
• Hiçbir kişisel veri toplanmaz, paylaşılmaz veya bir sunucuya gönderilmez.
• Reklam, analiz veya izleme yazılımı yoktur.

ÖNEMLİ: Ana şifrenizi unutursanız verileriniz kurtarılamaz; bu, gerçek çevrimdışı güvenliğin doğal sonucudur. Düzenli yedek almanızı öneririz.

KilitDepo, İY Labs tarafından geliştirilmiştir. Uygulama içi Kullanma Talimatı tüm özellikleri adım adım anlatır.
```

## Sürüm notları (dil başına en fazla 500 karakter)

Play Console > sürüm oluştururken "Sürüm notları" alanına, dil etiketleriyle birlikte yapıştırın.

### Dahili test

```
<tr-TR>
İlk test sürümü.
</tr-TR>
```

### Üretim — 1.0.0 (ilk sürüm)

```
<tr-TR>
KilitDepo'nun ilk sürümü!

• Şifreleriniz yalnızca cihazınızda, güçlü şifrelemeyle saklanır; internet izni yoktur
• Ana şifre veya parmak izi / yüz tanıma ile açma
• Tek dokunuşla kopyalama, pano otomatik temizlenir
• Rastgele ve kelime tabanlı şifre üretici
• Zayıf ve tekrar kullanılan şifreleri bulan güvenlik raporu
• Şifreli yedek ve diğer uygulamalardan CSV ile aktarma
</tr-TR>
```

### Kısa seçenek

```
<tr-TR>
İlk sürüm: çevrimdışı, şifreli ve reklamsız şifre kasası. Biyometrik açma, şifre üretici, güvenlik raporu, şifreli yedek ve CSV ile aktarma.
</tr-TR>
```

Sonraki güncellemelerde yalnızca değişenleri kısaca yazın (ör.
`• Biyometri iptal edildiğinde gereksiz uyarı kaldırıldı • Favoriler daha kompakt gösteriliyor`).

## Diğer alanlar

| Alan | Değer |
|---|---|
| Uygulama kategorisi | Araçlar |
| Etiketler | Şifre yöneticisi, Güvenlik |
| E-posta (zorunlu, mağazada görünür) | **Sizin geliştirici e-postanız** (bu dosyaya yazılmadı) |
| Web sitesi (isteğe bağlı) | `https://github.com/ibrahimyasar68/KilitDepo` |
| Gizlilik politikası (zorunlu) | `https://github.com/ibrahimyasar68/KilitDepo/blob/main/docs/privacy-policy.md` |

## Grafikler

| Play alanı | Dosya | Ölçü |
|---|---|---|
| Uygulama simgesi | `store/graphics/icon-512.png` | 512×512, 32 bit PNG |
| Tanıtım görseli | `store/graphics/feature-graphic.png` | 1024×500, 24 bit PNG |
| Telefon ekran görüntüleri (2–8) | `store/screenshots/01…08-*.png` | 1080×1920 (9:16) |

Önerilen sıra: 01 kasa → 02 kayıt detayı → 03 şifre üretici → 04 kelime tabanlı şifre →
05 güvenlik raporu → 06 görünüm seçici → 07 giriş → 08 koyu tema.

Yeniden üretmek için:

```bash
python3 tool/generate_store_assets.py
flutter test tool/store/screenshots_test.dart --update-goldens
```
