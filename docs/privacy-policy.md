# KilitDepo Gizlilik Politikası

**Yürürlük tarihi:** 15 Kasım 2026
**Geliştirici:** İY Labs
**Uygulama:** KilitDepo (Android paket adı: `com.iylabs.kilitdepo`)

KilitDepo, şifrelerinizi yalnızca kendi cihazınızda saklayan çevrimdışı bir şifre
yöneticisidir. Bu politika, uygulamanın verilerinizle ne yaptığını — ve ne yapmadığını —
açıklar.

## 1. Topladığımız veriler

**Hiçbir kişisel veri toplamıyoruz.** KilitDepo:

- Sizden hesap, e-posta, telefon numarası veya başka bir kimlik bilgisi istemez.
- Hiçbir veriyi bir sunucuya, buluta veya üçüncü bir tarafa göndermez.
- **İnternet izni istemez**; bu nedenle teknik olarak internete bağlanamaz.
- Reklam, analiz, çökme raporlama veya izleme yazılımı içermez.

## 2. Cihazınızda saklanan veriler

Uygulamaya girdiğiniz kayıtlar (başlık, kullanıcı adı, şifre, adres, notlar, kategori,
simge/renk tercihleri ve şifre geçmişi) **yalnızca cihazınızda**, şifrelenmiş olarak saklanır:

- Veritabanının tamamı SQLCipher ile; şifreler, notlar ve eski şifreler ayrıca AES-256-GCM ile
  şifrelenir.
- Şifreleme anahtarı, ana şifrenizden Argon2id ile türetilir. **Ana şifreniz hiçbir yerde
  saklanmaz**; bu nedenle biz de dahil hiç kimse onu bilemez veya sıfırlayamaz.
- Uygulama ayarları (tema, otomatik kilit süresi gibi) cihazın güvenli depolama alanında tutulur.

Bu verilere geliştirici olarak **erişimimiz yoktur**.

## 3. İzinler ve cihaz özellikleri

- **Biyometri (parmak izi / yüz tanıma):** İsteğe bağlıdır. Doğrulamayı işletim sistemi yapar;
  KilitDepo biyometrik verilerinize hiçbir zaman erişmez, yalnızca "doğrulandı / doğrulanmadı"
  sonucunu alır.
- **Pano:** Bir şifreyi kopyaladığınızda pano, seçtiğiniz süre sonunda (varsayılan 30 saniye)
  otomatik temizlenir.
- **Dosya seçici:** Yedek kaydederken veya yedek / CSV dosyası açarken yalnızca sizin seçtiğiniz
  dosyaya erişilir. Uygulama genel depolama izni istemez.
- **Ekran koruması:** Ekran görüntüsü alınması ve son uygulamalar önizlemesi engellenir.

## 4. Yedekler ve içe aktarma

- Yedek dosyaları, belirlediğiniz ayrı bir yedek şifresiyle tamamen şifrelenir ve yalnızca
  **sizin seçtiğiniz yere** kaydedilir. Yedeği nerede sakladığınız sizin kontrolünüzdedir.
- Başka uygulamalardan CSV içe aktarırken dosya yalnızca bellekte okunur; dosya seçicinin
  oluşturduğu geçici kopya hemen silinir. CSV dosyaları düz metin olduğu için, içe aktardıktan
  sonra orijinal dosyayı silmeniz önerilir.
- Android'in otomatik bulut yedeklemesi bu uygulama için kapalıdır.

## 5. Verilerin silinmesi

Tüm verileriniz yalnızca cihazınızdadır. Uygulamayı kaldırdığınızda veya uygulama verilerini
temizlediğinizde kasanız kalıcı olarak silinir. Tek tek kayıtları uygulama içinden
silebilirsiniz. Bizde silinmesi gereken hiçbir veriniz bulunmaz.

## 6. Çocuklar

KilitDepo çocuklara yönelik değildir ve hiç kimseden — çocuklar dahil — kişisel veri toplamaz.

## 7. Değişiklikler

Bu politika değişirse güncel hâli bu sayfada yayımlanır ve yürürlük tarihi güncellenir.

## 8. İletişim

Sorularınız için Google Play'deki uygulama sayfasında yer alan geliştirici e-posta adresinden
bize ulaşabilirsiniz.

---

# KilitDepo Privacy Policy (English summary)

**Effective date:** November 15, 2026 · **Developer:** İY Labs · **App:** KilitDepo (`com.iylabs.kilitdepo`)

- **We collect no personal data.** No accounts, no servers, no analytics, no ads, no tracking.
  The app does not request the Internet permission and cannot connect to the internet.
- Everything you enter is stored **only on your device**, encrypted (SQLCipher database; passwords
  and notes additionally AES-256-GCM). The key is derived from your master password with Argon2id;
  the master password itself is never stored. We have no access to your data.
- **Biometrics** are optional and handled by the operating system; the app never receives biometric
  data. The clipboard is cleared automatically after a chosen delay. Only files you pick are
  accessed; no broad storage permission is requested. Screenshots are blocked.
- **Backups** are fully encrypted with a separate backup password and saved only where you choose.
  CSV imports are read in memory and the picker's temporary copy is deleted immediately.
- **Deletion:** uninstalling the app or clearing its data permanently deletes your vault.
- The app is not directed at children. Changes to this policy will be published on this page.
- Contact: the developer e-mail address shown on the app's Google Play page.
