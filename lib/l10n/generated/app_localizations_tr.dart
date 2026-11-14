// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonUnexpectedError =>
      'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get splashLoading => 'Yükleniyor…';

  @override
  String get setupSubtitle =>
      'Kasanızı bu şifreyle açacaksınız. Uzun ve size özel bir şifre seçin.';

  @override
  String get setupPasswordLabel => 'Ana şifre';

  @override
  String get setupConfirmLabel => 'Ana şifre (tekrar)';

  @override
  String setupPasswordTooShort(int count) {
    return 'Ana şifre en az $count karakter olmalı.';
  }

  @override
  String get setupPasswordMismatch => 'Şifreler eşleşmiyor.';

  @override
  String get setupPasswordRequired => 'Lütfen bir ana şifre girin.';

  @override
  String get setupWarningBody =>
      'Ana şifrenizi unutursanız verileriniz kurtarılamaz. KilitDepo şifrenizi hiçbir yerde saklamaz ve sıfırlayamaz.';

  @override
  String get setupAcknowledge =>
      'Anladım, ana şifremi unutursam verilerimin kurtarılamayacağını kabul ediyorum.';

  @override
  String get setupAcknowledgeRequired => 'Devam etmek için uyarıyı onaylayın.';

  @override
  String get setupEnableBiometric => 'Biyometrik girişi etkinleştir';

  @override
  String get setupEnableBiometricHint =>
      'Parmak izi veya Face ID ile hızlı açma';

  @override
  String get setupCreateButton => 'Kasayı oluştur';

  @override
  String get setupCreating => 'Kasanız güvenli şekilde oluşturuluyor…';

  @override
  String get setupBiometricFailed =>
      'Kasa oluşturuldu ancak biyometrik giriş etkinleştirilemedi.';

  @override
  String strengthLabel(String level) {
    return 'Şifre gücü: $level';
  }

  @override
  String get strengthVeryWeak => 'Çok zayıf';

  @override
  String get strengthWeak => 'Zayıf';

  @override
  String get strengthFair => 'Orta';

  @override
  String get strengthStrong => 'Güçlü';

  @override
  String get strengthVeryStrong => 'Çok güçlü';

  @override
  String get loginTitle => 'Kasanızı açın';

  @override
  String get loginPasswordLabel => 'Ana şifre';

  @override
  String get loginUnlockButton => 'Kilidi aç';

  @override
  String get loginBiometricButton => 'Biyometrik ile aç';

  @override
  String get loginWrongPassword => 'Ana şifre yanlış.';

  @override
  String get loginCorrupted =>
      'Kasa anahtarı okunamadı. Veriler bozulmuş olabilir.';

  @override
  String get loginBiometricFailed =>
      'Biyometrik doğrulama yapılamadı. Ana şifrenizle giriş yapın.';

  @override
  String get loginAbout => 'Hakkında';

  @override
  String get loginGuide => 'Kullanma talimatı';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get biometricPromptTitle => 'KilitDepo';

  @override
  String get biometricPromptSubtitle =>
      'Kasanızı açmak için kimliğinizi doğrulayın';

  @override
  String get vaultTitle => 'Kasam';

  @override
  String get vaultLock => 'Kilitle';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get guideTitle => 'Kullanma Talimatı';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonCopy => 'Kopyala';

  @override
  String get vaultEmptyTitle => 'Kasanız henüz boş';

  @override
  String get vaultEmptyBody =>
      'İlk şifrenizi ekleyerek başlayın. Tüm kayıtlar cihazınızda şifreli olarak saklanır.';

  @override
  String get vaultAddFirst => 'Şifre ekle';

  @override
  String get vaultAdd => 'Yeni kayıt';

  @override
  String get vaultSearchHint => 'Başlık, kullanıcı adı veya URL ara';

  @override
  String get vaultNoResultsTitle => 'Sonuç bulunamadı';

  @override
  String get vaultNoResultsBody =>
      'Aramanızı veya filtrelerinizi değiştirmeyi deneyin.';

  @override
  String get vaultClearFilters => 'Filtreleri temizle';

  @override
  String get vaultLoadError => 'Kayıtlar yüklenemedi.';

  @override
  String get vaultFilterAll => 'Tümü';

  @override
  String get vaultFilterFavorites => 'Favoriler';

  @override
  String get vaultSort => 'Sırala';

  @override
  String get sortAlphabetical => 'Alfabetik (A–Z)';

  @override
  String get sortRecentlyAdded => 'Son eklenen';

  @override
  String get sortRecentlyUpdated => 'Son güncellenen';

  @override
  String get sortCategory => 'Kategoriye göre';

  @override
  String get categorySocialMedia => 'Sosyal Medya';

  @override
  String get categoryBank => 'Banka';

  @override
  String get categoryEmail => 'E-posta';

  @override
  String get categoryWork => 'İş';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get entryTitleLabel => 'Başlık';

  @override
  String get entryUsernameLabel => 'Kullanıcı adı';

  @override
  String get entryPasswordLabel => 'Şifre';

  @override
  String get entryUrlLabel => 'URL';

  @override
  String get entryNotesLabel => 'Notlar';

  @override
  String get entryCategoryLabel => 'Kategori';

  @override
  String get entryFavoriteLabel => 'Favorilere ekle';

  @override
  String get entryTitleRequired => 'Başlık zorunludur.';

  @override
  String get entryPasswordRequired => 'Şifre zorunludur.';

  @override
  String get entryNewTitle => 'Yeni kayıt';

  @override
  String get entryEditTitle => 'Kaydı düzenle';

  @override
  String get entrySaved => 'Kayıt kaydedildi.';

  @override
  String get entryNotFound => 'Bu kayıt bulunamadı. Silinmiş olabilir.';

  @override
  String get entryDiscardTitle => 'Değişiklikler kaydedilmedi';

  @override
  String get entryDiscardBody =>
      'Çıkarsanız yaptığınız değişiklikler kaybolacak.';

  @override
  String get entryDiscardConfirm => 'Çık';

  @override
  String get entryKeepEditing => 'Düzenlemeye devam et';

  @override
  String get entryFavoriteAdd => 'Favorilere ekle';

  @override
  String get entryFavoriteRemove => 'Favorilerden çıkar';

  @override
  String get entryShowPassword => 'Şifreyi göster';

  @override
  String get entryHidePassword => 'Şifreyi gizle';

  @override
  String get entryCopyPassword => 'Şifreyi kopyala';

  @override
  String get entryCopyUsername => 'Kullanıcı adını kopyala';

  @override
  String get entryCopyUrl => 'URL\'yi kopyala';

  @override
  String get entryCreatedAt => 'Oluşturulma';

  @override
  String get entryUpdatedAt => 'Son güncelleme';

  @override
  String get entryHistory => 'Şifre geçmişi';

  @override
  String entryHistoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count önceki şifre',
      zero: 'Önceki şifre yok',
    );
    return '$_temp0';
  }

  @override
  String copiedPassword(int seconds) {
    return 'Şifre kopyalandı. $seconds saniye sonra panodan silinecek.';
  }

  @override
  String copiedValue(int seconds) {
    return 'Kopyalandı. $seconds saniye sonra panodan silinecek.';
  }

  @override
  String get historyTitle => 'Şifre geçmişi';

  @override
  String historyInfo(int count) {
    return 'Bu kaydın en fazla son $count eski şifresi saklanır.';
  }

  @override
  String get historyEmpty => 'Bu kaydın şifresi henüz hiç değiştirilmedi.';

  @override
  String historyChangedAt(String date) {
    return 'Değiştirilme: $date';
  }

  @override
  String loginLockedOut(String time) {
    return 'Çok fazla hatalı deneme yapıldı. $time sonra tekrar deneyebilirsiniz.';
  }

  @override
  String get changePasswordTitle => 'Ana şifreyi değiştir';

  @override
  String get changePasswordInfo =>
      'Kayıtlarınız yeniden şifrelenmez; yalnızca kasa anahtarı yeni ana şifrenizle yeniden korunur. Biyometrik giriş çalışmaya devam eder.';

  @override
  String get changePasswordCurrent => 'Mevcut ana şifre';

  @override
  String get changePasswordNew => 'Yeni ana şifre';

  @override
  String get changePasswordConfirm => 'Yeni ana şifre (tekrar)';

  @override
  String get changePasswordSameAsOld =>
      'Yeni şifre mevcut şifreyle aynı olamaz.';

  @override
  String get changePasswordButton => 'Şifreyi değiştir';

  @override
  String get changePasswordWorking => 'Yeni anahtar türetiliyor…';

  @override
  String get changePasswordWrongCurrent => 'Mevcut ana şifre yanlış.';

  @override
  String get changePasswordSuccess => 'Ana şifreniz değiştirildi.';

  @override
  String get generatorTitle => 'Şifre üretici';

  @override
  String get generatorRegenerate => 'Yeniden üret';

  @override
  String generatorLength(int length) {
    return 'Uzunluk: $length';
  }

  @override
  String get generatorUppercase => 'Büyük harf (A–Z)';

  @override
  String get generatorLowercase => 'Küçük harf (a–z)';

  @override
  String get generatorDigits => 'Rakam (0–9)';

  @override
  String get generatorSymbols => 'Sembol (!@#…)';

  @override
  String get generatorExcludeAmbiguous =>
      'Karışabilecek karakterleri hariç tut (0 O o 1 l I |)';

  @override
  String get generatorUse => 'Bu şifreyi kullan';

  @override
  String get generatorGenerateButton => 'Şifre üret';

  @override
  String get reportTitle => 'Güvenlik raporu';

  @override
  String get reportAllGood => 'Her şey yolunda';

  @override
  String get reportAllGoodBody =>
      'Zayıf veya tekrar kullanılan şifre bulunamadı.';

  @override
  String get reportWeakTitle => 'Zayıf şifreler';

  @override
  String get reportWeakBody =>
      'Bu şifreler kolay tahmin edilebilir. Şifre üreticiyle güçlü bir şifre oluşturmanız önerilir.';

  @override
  String get reportReusedTitle => 'Tekrar kullanılan şifreler';

  @override
  String get reportReusedBody =>
      'Aynı şifre birden fazla hesapta kullanılıyor. Biri ele geçirilirse diğerleri de risk altına girer.';

  @override
  String reportReusedGroup(int count) {
    return '$count kayıt aynı şifreyi kullanıyor';
  }

  @override
  String reportBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count güvenlik uyarısı',
      one: '1 güvenlik uyarısı',
    );
    return '$_temp0';
  }

  @override
  String get reportBannerAction => 'İncele';

  @override
  String get backupTitle => 'Yedekleme';

  @override
  String get backupIntro =>
      'Yedek dosyası, ana şifrenizden ayrı bir yedek şifresiyle şifrelenir. Dosyayı nereye kaydedeceğinizi siz seçersiniz; KilitDepo hiçbir yere göndermez.';

  @override
  String get backupExportTitle => 'Yedek oluştur';

  @override
  String get backupPasswordLabel => 'Yedek şifresi';

  @override
  String get backupPasswordConfirm => 'Yedek şifresi (tekrar)';

  @override
  String get backupPasswordWarning =>
      'Yedek şifresini unutursanız yedek AÇILAMAZ. Ana şifrenizden farklı, güçlü bir şifre seçin ve güvenli bir yerde saklayın.';

  @override
  String get backupExportButton => 'Yedeği kaydet';

  @override
  String get backupExporting => 'Yedek şifreleniyor…';

  @override
  String backupExported(int count) {
    return 'Yedek kaydedildi ($count kayıt).';
  }

  @override
  String get backupExportCancelled => 'Kaydetme iptal edildi.';

  @override
  String get backupEmptyVault => 'Kasanızda yedeklenecek kayıt yok.';

  @override
  String get backupImportTitle => 'Yedekten geri yükle';

  @override
  String get backupImportBody =>
      'Yedekteki kayıtlar kasanızla birleştirilir. Hiçbir kayıt silinmez; aynı kayıt her iki yerde de varsa daha yakın tarihte güncellenmiş olan kalır.';

  @override
  String get backupChooseFile => 'Yedek dosyası seç';

  @override
  String backupSelectedFile(String name) {
    return 'Seçilen dosya: $name';
  }

  @override
  String get backupDecryptButton => 'Yedeği aç';

  @override
  String get backupDecrypting => 'Yedek çözülüyor…';

  @override
  String get backupWrongPassword =>
      'Yedek şifresi yanlış veya dosya değiştirilmiş.';

  @override
  String get backupInvalidFile =>
      'Bu dosya geçerli bir KilitDepo yedeği değil.';

  @override
  String backupPreview(int total, int added, int updated, int skipped) {
    return '$total kayıt bulundu: $added yeni, $updated güncellenecek, $skipped değişmeyecek.';
  }

  @override
  String get backupImportButton => 'Kasaya aktar';

  @override
  String backupImported(int added, int updated) {
    return '$added kayıt eklendi, $updated kayıt güncellendi.';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsSecurity => 'Güvenlik';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsData => 'Veri';

  @override
  String get settingsInfo => 'Bilgi';

  @override
  String get settingsBiometric => 'Biyometrik giriş';

  @override
  String get settingsBiometricOn => 'Parmak izi / Face ID ile açılabilir';

  @override
  String get settingsBiometricOff => 'Kapalı';

  @override
  String get settingsBiometricUnavailable => 'Bu cihazda kullanılamıyor';

  @override
  String get settingsBiometricConfirmTitle => 'Biyometrik girişi aç';

  @override
  String get settingsBiometricConfirmBody =>
      'Güvenliğiniz için ana şifrenizi girin.';

  @override
  String get settingsBiometricEnabled => 'Biyometrik giriş açıldı.';

  @override
  String get settingsBiometricDisabled => 'Biyometrik giriş kapatıldı.';

  @override
  String get settingsBiometricFailed => 'Biyometrik giriş açılamadı.';

  @override
  String get settingsConfirm => 'Onayla';

  @override
  String get settingsAutoLock => 'Otomatik kilit';

  @override
  String settingsAutoLockSubtitle(String duration) {
    return '$duration hareketsizlikten sonra';
  }

  @override
  String get settingsClipboard => 'Pano temizleme';

  @override
  String settingsClipboardSubtitle(String duration) {
    return 'Kopyalanan şifre $duration sonra silinir';
  }

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get settingsLastBackupNever => 'Henüz yedek alınmadı';

  @override
  String settingsLastBackup(String date) {
    return 'Son yedek: $date';
  }

  @override
  String durationSeconds(int count) {
    return '$count saniye';
  }

  @override
  String durationMinutes(int count) {
    return '$count dakika';
  }

  @override
  String get aboutDescription =>
      'KilitDepo, şifrelerinizi yalnızca kendi cihazınızda, güçlü şifrelemeyle saklayan çevrimdışı bir şifre yöneticisidir. Hesaplarınızı tek bir yerde, kimseyle paylaşmadan güvenle yönetmek isteyen herkes için tasarlandı.';

  @override
  String aboutVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get aboutPrivacyTitle => 'Gizlilik ilkelerimiz';

  @override
  String get aboutPrivacy1 =>
      'Uygulama internete bağlanmaz; hiçbir veri cihazınızdan çıkmaz.';

  @override
  String get aboutPrivacy2 =>
      'Kullanıcı verisi toplanmaz; analitik veya reklam takibi yoktur.';

  @override
  String get aboutPrivacy3 =>
      'Tüm veriler AES-256 ile şifrelenir; ana şifreniz hiçbir yerde saklanmaz.';

  @override
  String get aboutSecurityTitle => 'Güvenlik';

  @override
  String get aboutSecurity1 =>
      'Argon2id: Ana şifrenizden anahtar üretir; tahmin denemelerini bilinçli olarak yavaşlatır.';

  @override
  String get aboutSecurity2 =>
      'AES-256-GCM: Şifrelerinizi ve notlarınızı şifreler, en küçük değişikliği bile fark eder.';

  @override
  String get aboutSecurity3 =>
      'SQLCipher: Veritabanı dosyasının tamamını şifreler.';

  @override
  String get aboutSecurity4 =>
      'Donanım destekli anahtar saklama: Anahtarlar iOS Keychain ve Android Keystore ile korunur.';

  @override
  String get aboutLicenses => 'Açık kaynak lisansları';

  @override
  String get guideSearchHint => 'Talimatlarda ara';

  @override
  String get guideNoResults => 'Aramanızla eşleşen bölüm bulunamadı.';

  @override
  String get guideStepsTitle => 'Adımlar';

  @override
  String get guideTipsTitle => 'İpuçları';

  @override
  String get guidePromptTitle => 'Kasanız hazır';

  @override
  String get guidePromptBody => 'Kullanma talimatına göz atmak ister misiniz?';

  @override
  String get guidePromptOpen => 'Talimatı aç';

  @override
  String get guidePromptLater => 'Şimdi değil';

  @override
  String get clipboardClearNow => 'Şimdi temizle';

  @override
  String get navVault => 'Kasa';

  @override
  String get navGenerator => 'Şifre Üretici';

  @override
  String get navReport => 'Rapor';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get swipeCopy => 'Kopyala';

  @override
  String get swipeFavorite => 'Favori';

  @override
  String get reportScore => 'Güvenlik puanı';

  @override
  String get reportScoreExcellent => 'Mükemmel';

  @override
  String get reportScoreGood => 'İyi, ama iyileştirilebilir';

  @override
  String get reportScoreFair => 'Orta, iyileştirme gerekli';

  @override
  String get reportScorePoor => 'Zayıf, hemen ilgilenin';

  @override
  String get reportWeakCount => 'Zayıf şifre';

  @override
  String get reportReusedCount => 'Tekrar kullanılan';

  @override
  String reportReusedWith(String title) {
    return '$title ile aynı';
  }

  @override
  String setupStepOf(int current, int total) {
    return 'Adım $current/$total';
  }

  @override
  String get setupStepPasswordTitle => 'Ana şifrenizi belirleyin';

  @override
  String get setupStepWarningTitle => 'Bunu bilmeniz önemli';

  @override
  String get setupStepWarningBody =>
      'KilitDepo şifrelerinizi yalnızca bu cihazda, ana şifrenizden türetilen bir anahtarla şifreler. Ana şifreniz hiçbir yerde saklanmaz; bu yüzden onu sıfırlayamayız veya size hatırlatamayız.';

  @override
  String get setupStepBiometricTitle => 'Hızlı giriş';

  @override
  String get setupStepBiometricBody =>
      'Kasanızı her seferinde ana şifre yazmadan, parmak izi veya yüz tanıma ile açabilirsiniz. Bu ayarı daha sonra Ayarlar\'dan değiştirebilirsiniz.';

  @override
  String get setupNext => 'İleri';

  @override
  String get setupBack => 'Geri';

  @override
  String get entrySectionAccount => 'Hesap';

  @override
  String get entrySectionPassword => 'Şifre';

  @override
  String get entrySectionOther => 'Diğer';

  @override
  String get setupPreviousVaultMissing =>
      'Bu cihazda önceki bir kasanın anahtarı bulundu ama kasa verisi yoktu (örneğin uygulama silinip yeniden yüklendiyse). Yeni bir kasa oluşturun; yedeğiniz varsa kurulumdan sonra Ayarlar > Yedekleme\'den geri yükleyebilirsiniz.';

  @override
  String get settingsDynamicColor => 'Duvar kağıdı renkleri';

  @override
  String get settingsDynamicColorSubtitle =>
      'Uygulama renklerini telefonunuzun duvar kağıdına uydurur (Material You)';

  @override
  String get vaultSelectEntry =>
      'Ayrıntılarını görmek için soldan bir kayıt seçin.';

  @override
  String get detailCopyUsernameShort => 'Kullanıcı adı';

  @override
  String get detailCopyPasswordShort => 'Şifre';

  @override
  String get entryMoreActions => 'Diğer işlemler';

  @override
  String get loginOrPassword => 'veya ana şifreyle';

  @override
  String get generatorLengthLabel => 'Uzunluk';

  @override
  String get generatorCharsets => 'Karakterler';

  @override
  String get reportChangePassword => 'Değiştir';

  @override
  String get settingsTrueBlack => 'Tam siyah zemin';

  @override
  String get settingsTrueBlackSubtitle =>
      'Koyu temada zemin tam siyah olur (OLED ekranlarda pil tasarrufu)';

  @override
  String get commonUndo => 'Geri al';

  @override
  String entryDeletedUndo(String title) {
    return '\"$title\" silindi';
  }

  @override
  String get generatorModeRandom => 'Rastgele';

  @override
  String get generatorModeWords => 'Kelimeler';

  @override
  String get generatorWordCount => 'Kelime sayısı';

  @override
  String generatorWordCountValue(int count) {
    return '$count kelime';
  }

  @override
  String get generatorSeparator => 'Ayırıcı';

  @override
  String get generatorCapitalize => 'Kelimeleri büyük harfle başlat';

  @override
  String get generatorAddNumber => 'Sonuna sayı ekle';

  @override
  String generatorEntropy(int bits) {
    return 'Tahmini güç: yaklaşık $bits bit';
  }

  @override
  String get entryAppearance => 'Görünüm';

  @override
  String get entryAppearanceDefault => 'Baş harf, otomatik renk';

  @override
  String get entryAppearanceIcon => 'Simge';

  @override
  String get entryAppearanceColor => 'Renk';

  @override
  String get entryAppearanceLetter => 'Harf';

  @override
  String get entryAppearanceAuto => 'Otomatik';

  @override
  String get entryAppearanceReset => 'Varsayılana dön';

  @override
  String get entryAppearanceDone => 'Tamam';

  @override
  String get entryIconBank => 'Banka';

  @override
  String get entryIconCard => 'Kart';

  @override
  String get entryIconWallet => 'Cüzdan';

  @override
  String get entryIconCart => 'Alışveriş';

  @override
  String get entryIconBag => 'Mağaza';

  @override
  String get entryIconEmail => 'E-posta';

  @override
  String get entryIconChat => 'Mesajlaşma';

  @override
  String get entryIconPhone => 'Telefon';

  @override
  String get entryIconPeople => 'Sosyal';

  @override
  String get entryIconWork => 'İş';

  @override
  String get entryIconSchool => 'Okul';

  @override
  String get entryIconGame => 'Oyun';

  @override
  String get entryIconMusic => 'Müzik';

  @override
  String get entryIconVideo => 'Video';

  @override
  String get entryIconPhoto => 'Fotoğraf';

  @override
  String get entryIconCloud => 'Bulut';

  @override
  String get entryIconComputer => 'Bilgisayar';

  @override
  String get entryIconCode => 'Yazılım';

  @override
  String get entryIconWifi => 'Wi-Fi';

  @override
  String get entryIconHome => 'Ev';

  @override
  String get entryIconCar => 'Araba';

  @override
  String get entryIconFlight => 'Seyahat';

  @override
  String get entryIconHealth => 'Sağlık';

  @override
  String get entryIconFitness => 'Spor';

  @override
  String get entryIconFood => 'Yemek';

  @override
  String get entryIconCoffee => 'Kafe';

  @override
  String get entryIconId => 'Kimlik';

  @override
  String get entryIconShield => 'Güvenlik';

  @override
  String get entryIconKey => 'Anahtar';

  @override
  String get entryIconLock => 'Kilit';

  @override
  String get entryIconStar => 'Yıldız';

  @override
  String get entryIconGlobe => 'Web';

  @override
  String get entryIconBook => 'Kitap';

  @override
  String get entryIconNews => 'Haber';

  @override
  String get entryIconGift => 'Hediye';

  @override
  String get entryIconStock => 'Yatırım';

  @override
  String get entryIconPet => 'Evcil hayvan';

  @override
  String get entryIconTools => 'Araçlar';

  @override
  String get entryColorTeal => 'Petrol';

  @override
  String get entryColorGreen => 'Yeşil';

  @override
  String get entryColorOlive => 'Zeytin';

  @override
  String get entryColorBlue => 'Mavi';

  @override
  String get entryColorIndigo => 'Lacivert';

  @override
  String get entryColorPurple => 'Mor';

  @override
  String get entryColorPink => 'Pembe';

  @override
  String get entryColorRed => 'Kırmızı';

  @override
  String get entryColorOrange => 'Turuncu';

  @override
  String get entryColorAmber => 'Kehribar';

  @override
  String get entryColorBrown => 'Kahverengi';

  @override
  String get entryColorSlate => 'Gri';

  @override
  String get vaultQuickAccess => 'Favoriler';

  @override
  String get entryOpenDetails => 'Ayrıntıları aç';

  @override
  String get issueWeakBadge => 'Zayıf';

  @override
  String get issueReusedBadge => 'Tekrar';

  @override
  String get detailIssueWeak =>
      'Bu şifre zayıf; tahmin edilmesi kolay olabilir.';

  @override
  String detailIssueReused(String titles) {
    return 'Bu şifre şu kayıtlarda da kullanılıyor: $titles';
  }

  @override
  String get detailIssueChange => 'Şifreyi değiştir';

  @override
  String get setupTipsTitle => 'İyi bir ana şifre nasıl seçilir?';

  @override
  String get setupTipWords =>
      '4–6 rastgele kelime kullanın: hem güçlü hem yazması kolay.';

  @override
  String get setupTipUnique =>
      'Başka bir yerde kullandığınız şifreyi kullanmayın.';

  @override
  String get setupTipPersonal =>
      'Adınız, doğum tarihiniz, takımınız gibi kişisel bilgilerden kaçının.';

  @override
  String get setupSuggest => 'Bana bir öneri üret';

  @override
  String get setupSuggestionUse => 'Kullan';

  @override
  String get setupSuggestionAnother => 'Başka öneri';

  @override
  String get setupSuggestionHint =>
      'Öneriyi kullanırsanız tekrar alanını kendiniz yazın; böylece şifreyi bir kez de elinizle yazmış olursunuz.';

  @override
  String get setupWeakTitle => 'Bu ana şifre zayıf';

  @override
  String get setupWeakBody =>
      'Ana şifreniz tüm kasanızı korur. Daha uzun bir şifre ya da birkaç rastgele kelime önerilir.';

  @override
  String get setupWeakChange => 'Şifreyi değiştir';

  @override
  String get setupWeakContinue => 'Yine de devam et';

  @override
  String get setupStoreTitle => 'Ana şifrenizi nasıl saklamalısınız?';

  @override
  String get setupStorePaper => 'Kâğıda yazın ve güvenli bir yerde saklayın.';

  @override
  String get setupStoreNoPhone =>
      'Telefonun notlarına veya fotoğraflarına kaydetmeyin.';

  @override
  String get setupStoreBackup => 'Düzenli yedek alın (Ayarlar > Yedekleme).';

  @override
  String get csvImportTitle => 'Başka uygulamadan içe aktar';

  @override
  String get csvImportSettingsSubtitle =>
      'Chrome, Safari, Bitwarden, 1Password… (CSV dosyası)';

  @override
  String get csvImportIntro =>
      'Başka bir şifre yöneticisinden veya tarayıcıdan dışa aktardığınız CSV dosyasındaki kayıtları kasanıza ekler. Mevcut kayıtlarınız silinmez veya değiştirilmez.';

  @override
  String get csvImportPlainWarning =>
      'CSV dosyaları şifrelerinizi düz metin olarak içerir. İçe aktardıktan sonra dosyayı mutlaka silin ve kimseyle paylaşmayın.';

  @override
  String get csvImportHowTo =>
      'Nasıl dışa aktarılacağını Kullanma Talimatı\'ndaki \"Başka uygulamadan aktarma\" bölümünde bulabilirsiniz.';

  @override
  String get csvImportPick => 'CSV dosyası seç';

  @override
  String get csvImportReading => 'Dosya okunuyor…';

  @override
  String csvImportFormatLabel(String format) {
    return 'Algılanan biçim: $format';
  }

  @override
  String get csvFormatChrome => 'Chrome / Edge / Brave';

  @override
  String get csvFormatFirefox => 'Firefox';

  @override
  String get csvFormatApple => 'Safari / Apple Passwords';

  @override
  String get csvFormatBitwarden => 'Bitwarden';

  @override
  String get csvFormatOnePassword => '1Password';

  @override
  String get csvFormatProtonPass => 'Proton Pass';

  @override
  String get csvFormatKeePass => 'KeePass / KeePassXC';

  @override
  String get csvFormatGeneric => 'Genel CSV';

  @override
  String csvImportToAdd(int count) {
    return '$count kayıt eklenecek';
  }

  @override
  String csvImportDuplicates(int count) {
    return '$count kayıt zaten kasada olduğu için atlanacak';
  }

  @override
  String csvImportNoPassword(int count) {
    return '$count satır şifresi boş olduğu için atlanacak';
  }

  @override
  String csvImportTotp(int count) {
    return '$count kayıttaki 2 adımlı doğrulama (TOTP) anahtarı güvenlik nedeniyle aktarılmayacak';
  }

  @override
  String get csvImportNothing => 'Eklenecek yeni kayıt yok.';

  @override
  String get csvImportPreviewList => 'Eklenecek kayıtlar';

  @override
  String csvImportMore(int count) {
    return '+$count kayıt daha';
  }

  @override
  String get csvImportConfirm => 'İçe aktar';

  @override
  String get csvImportOtherFile => 'Başka dosya seç';

  @override
  String get csvImportImporting => 'Kayıtlar şifrelenerek ekleniyor…';

  @override
  String csvImportDone(int count) {
    return '$count kayıt kasanıza eklendi.';
  }

  @override
  String get csvImportDeleteReminder =>
      'Şimdi orijinal CSV dosyasını silin: dosya şifrelerinizi düz metin olarak içeriyor ve KilitDepo onu sizin yerinize silemez.';

  @override
  String get csvImportFinish => 'Tamam';

  @override
  String get csvImportErrorEmpty => 'Dosyada içe aktarılacak kayıt bulunamadı.';

  @override
  String get csvImportErrorEncoding =>
      'Dosya okunamadı. Lütfen CSV (UTF-8) biçiminde dışa aktarın.';

  @override
  String get csvImportErrorTooLarge =>
      'Dosya çok büyük (en fazla 10 MB ve 10.000 kayıt).';

  @override
  String get csvImportErrorColumns =>
      'Bu dosya tanınamadı: başlık/adres ve şifre sütunları bulunamadı.';

  @override
  String get csvImportScreenTitle => 'CSV\'den içe aktar';

  @override
  String get entrySaveErrorLocked =>
      'Kasa kilitlendiği için kaydedilemedi. Kilidi açıp tekrar deneyin.';

  @override
  String get entrySaveErrorInvalid =>
      'Kaydedilemedi: başlık ve şifre alanları boş olamaz.';

  @override
  String get entrySaveErrorStorageFull =>
      'Cihazda yeterli boş alan olmadığı için kaydedilemedi.';

  @override
  String get entrySaveErrorBusy =>
      'Veritabanı şu an meşgul olduğu için kaydedilemedi. Birkaç saniye sonra tekrar deneyin.';

  @override
  String entrySaveErrorDatabase(String code) {
    return 'Veritabanına yazılamadı (hata kodu: $code). Lütfen tekrar deneyin.';
  }

  @override
  String get entrySaveErrorCrypto =>
      'Şifreleme sırasında bir sorun oluştuğu için kaydedilemedi.';

  @override
  String entrySaveErrorUnknown(String detail) {
    return 'Kayıt kaydedilemedi (ayrıntı: $detail). Lütfen tekrar deneyin.';
  }
}
