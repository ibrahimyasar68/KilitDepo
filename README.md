# KilitDepo

Tamamen çevrimdışı, kişisel şifre yöneticisi (Flutter · Android + iOS). Üretici: İY Labs.

- İnternet izni yoktur; hiçbir veri cihazdan çıkmaz (yedek dosyası hariç, o da şifrelidir).
- Ana şifre → Argon2id → AES-256-GCM ile sarılmış veri anahtarı; veritabanı SQLCipher ile,
  şifre/not/eski şifreler ayrıca alan düzeyinde şifrelenir.
- Arayüz dili Türkçe (`lib/l10n/app_tr.arb`).

Ayrıntılı proje notları ve kararlar için: [devam.md](devam.md).

## Sık kullanılan komutlar

```bash
flutter test
flutter analyze
flutter gen-l10n                       # ARB değişince
dart run build_runner build            # drift tabloları değişince
flutter build apk --release
```
