import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get commonCancel;

  /// No description provided for @commonUnexpectedError.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.'**
  String get commonUnexpectedError;

  /// No description provided for @splashLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor…'**
  String get splashLoading;

  /// No description provided for @setupSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kasanızı bu şifreyle açacaksınız. Uzun ve size özel bir şifre seçin.'**
  String get setupSubtitle;

  /// No description provided for @setupPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifre'**
  String get setupPasswordLabel;

  /// No description provided for @setupConfirmLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifre (tekrar)'**
  String get setupConfirmLabel;

  /// No description provided for @setupPasswordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifre en az {count} karakter olmalı.'**
  String setupPasswordTooShort(int count);

  /// No description provided for @setupPasswordMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor.'**
  String get setupPasswordMismatch;

  /// No description provided for @setupPasswordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir ana şifre girin.'**
  String get setupPasswordRequired;

  /// No description provided for @setupWarningBody.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifrenizi unutursanız verileriniz kurtarılamaz. KilitDepo şifrenizi hiçbir yerde saklamaz ve sıfırlayamaz.'**
  String get setupWarningBody;

  /// No description provided for @setupAcknowledge.
  ///
  /// In tr, this message translates to:
  /// **'Anladım, ana şifremi unutursam verilerimin kurtarılamayacağını kabul ediyorum.'**
  String get setupAcknowledge;

  /// No description provided for @setupAcknowledgeRequired.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için uyarıyı onaylayın.'**
  String get setupAcknowledgeRequired;

  /// No description provided for @setupEnableBiometric.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik girişi etkinleştir'**
  String get setupEnableBiometric;

  /// No description provided for @setupEnableBiometricHint.
  ///
  /// In tr, this message translates to:
  /// **'Parmak izi veya Face ID ile hızlı açma'**
  String get setupEnableBiometricHint;

  /// No description provided for @setupCreateButton.
  ///
  /// In tr, this message translates to:
  /// **'Kasayı oluştur'**
  String get setupCreateButton;

  /// No description provided for @setupCreating.
  ///
  /// In tr, this message translates to:
  /// **'Kasanız güvenli şekilde oluşturuluyor…'**
  String get setupCreating;

  /// No description provided for @setupBiometricFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kasa oluşturuldu ancak biyometrik giriş etkinleştirilemedi.'**
  String get setupBiometricFailed;

  /// No description provided for @strengthLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre gücü: {level}'**
  String strengthLabel(String level);

  /// No description provided for @strengthVeryWeak.
  ///
  /// In tr, this message translates to:
  /// **'Çok zayıf'**
  String get strengthVeryWeak;

  /// No description provided for @strengthWeak.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf'**
  String get strengthWeak;

  /// No description provided for @strengthFair.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get strengthFair;

  /// No description provided for @strengthStrong.
  ///
  /// In tr, this message translates to:
  /// **'Güçlü'**
  String get strengthStrong;

  /// No description provided for @strengthVeryStrong.
  ///
  /// In tr, this message translates to:
  /// **'Çok güçlü'**
  String get strengthVeryStrong;

  /// No description provided for @loginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kasanızı açın'**
  String get loginTitle;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifre'**
  String get loginPasswordLabel;

  /// No description provided for @loginUnlockButton.
  ///
  /// In tr, this message translates to:
  /// **'Kilidi aç'**
  String get loginUnlockButton;

  /// No description provided for @loginBiometricButton.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik ile aç'**
  String get loginBiometricButton;

  /// No description provided for @loginWrongPassword.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifre yanlış.'**
  String get loginWrongPassword;

  /// No description provided for @loginCorrupted.
  ///
  /// In tr, this message translates to:
  /// **'Kasa anahtarı okunamadı. Veriler bozulmuş olabilir.'**
  String get loginCorrupted;

  /// No description provided for @loginBiometricFailed.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik doğrulama yapılamadı. Ana şifrenizle giriş yapın.'**
  String get loginBiometricFailed;

  /// No description provided for @loginAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get loginAbout;

  /// No description provided for @loginGuide.
  ///
  /// In tr, this message translates to:
  /// **'Kullanma talimatı'**
  String get loginGuide;

  /// No description provided for @showPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi göster'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi gizle'**
  String get hidePassword;

  /// No description provided for @biometricPromptTitle.
  ///
  /// In tr, this message translates to:
  /// **'KilitDepo'**
  String get biometricPromptTitle;

  /// No description provided for @biometricPromptSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kasanızı açmak için kimliğinizi doğrulayın'**
  String get biometricPromptSubtitle;

  /// No description provided for @vaultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kasam'**
  String get vaultTitle;

  /// No description provided for @vaultLock.
  ///
  /// In tr, this message translates to:
  /// **'Kilitle'**
  String get vaultLock;

  /// No description provided for @aboutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get aboutTitle;

  /// No description provided for @guideTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanma Talimatı'**
  String get guideTitle;

  /// No description provided for @commonSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get commonEdit;

  /// No description provided for @commonRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get commonRetry;

  /// No description provided for @commonCopy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get commonCopy;

  /// No description provided for @vaultEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kasanız henüz boş'**
  String get vaultEmptyTitle;

  /// No description provided for @vaultEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'İlk şifrenizi ekleyerek başlayın. Tüm kayıtlar cihazınızda şifreli olarak saklanır.'**
  String get vaultEmptyBody;

  /// No description provided for @vaultAddFirst.
  ///
  /// In tr, this message translates to:
  /// **'Şifre ekle'**
  String get vaultAddFirst;

  /// No description provided for @vaultAdd.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kayıt'**
  String get vaultAdd;

  /// No description provided for @vaultSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Başlık, kullanıcı adı veya URL ara'**
  String get vaultSearchHint;

  /// No description provided for @vaultNoResultsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get vaultNoResultsTitle;

  /// No description provided for @vaultNoResultsBody.
  ///
  /// In tr, this message translates to:
  /// **'Aramanızı veya filtrelerinizi değiştirmeyi deneyin.'**
  String get vaultNoResultsBody;

  /// No description provided for @vaultClearFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri temizle'**
  String get vaultClearFilters;

  /// No description provided for @vaultLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlar yüklenemedi.'**
  String get vaultLoadError;

  /// No description provided for @vaultFilterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get vaultFilterAll;

  /// No description provided for @vaultFilterFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get vaultFilterFavorites;

  /// No description provided for @vaultSort.
  ///
  /// In tr, this message translates to:
  /// **'Sırala'**
  String get vaultSort;

  /// No description provided for @sortAlphabetical.
  ///
  /// In tr, this message translates to:
  /// **'Alfabetik (A–Z)'**
  String get sortAlphabetical;

  /// No description provided for @sortRecentlyAdded.
  ///
  /// In tr, this message translates to:
  /// **'Son eklenen'**
  String get sortRecentlyAdded;

  /// No description provided for @sortRecentlyUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Son güncellenen'**
  String get sortRecentlyUpdated;

  /// No description provided for @sortCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriye göre'**
  String get sortCategory;

  /// No description provided for @categorySocialMedia.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Medya'**
  String get categorySocialMedia;

  /// No description provided for @categoryBank.
  ///
  /// In tr, this message translates to:
  /// **'Banka'**
  String get categoryBank;

  /// No description provided for @categoryEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get categoryEmail;

  /// No description provided for @categoryWork.
  ///
  /// In tr, this message translates to:
  /// **'İş'**
  String get categoryWork;

  /// No description provided for @categoryOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get categoryOther;

  /// No description provided for @entryTitleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get entryTitleLabel;

  /// No description provided for @entryUsernameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı'**
  String get entryUsernameLabel;

  /// No description provided for @entryPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get entryPasswordLabel;

  /// No description provided for @entryUrlLabel.
  ///
  /// In tr, this message translates to:
  /// **'URL'**
  String get entryUrlLabel;

  /// No description provided for @entryNotesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get entryNotesLabel;

  /// No description provided for @entryCategoryLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get entryCategoryLabel;

  /// No description provided for @entryFavoriteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Favorilere ekle'**
  String get entryFavoriteLabel;

  /// No description provided for @entryTitleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlık zorunludur.'**
  String get entryTitleRequired;

  /// No description provided for @entryPasswordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre zorunludur.'**
  String get entryPasswordRequired;

  /// No description provided for @entryNewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kayıt'**
  String get entryNewTitle;

  /// No description provided for @entryEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydı düzenle'**
  String get entryEditTitle;

  /// No description provided for @entrySaved.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt kaydedildi.'**
  String get entrySaved;

  /// No description provided for @entryNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt bulunamadı. Silinmiş olabilir.'**
  String get entryNotFound;

  /// No description provided for @entryDiscardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklikler kaydedilmedi'**
  String get entryDiscardTitle;

  /// No description provided for @entryDiscardBody.
  ///
  /// In tr, this message translates to:
  /// **'Çıkarsanız yaptığınız değişiklikler kaybolacak.'**
  String get entryDiscardBody;

  /// No description provided for @entryDiscardConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Çık'**
  String get entryDiscardConfirm;

  /// No description provided for @entryKeepEditing.
  ///
  /// In tr, this message translates to:
  /// **'Düzenlemeye devam et'**
  String get entryKeepEditing;

  /// No description provided for @entryFavoriteAdd.
  ///
  /// In tr, this message translates to:
  /// **'Favorilere ekle'**
  String get entryFavoriteAdd;

  /// No description provided for @entryFavoriteRemove.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkar'**
  String get entryFavoriteRemove;

  /// No description provided for @entryShowPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi göster'**
  String get entryShowPassword;

  /// No description provided for @entryHidePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi gizle'**
  String get entryHidePassword;

  /// No description provided for @entryCopyPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi kopyala'**
  String get entryCopyPassword;

  /// No description provided for @entryCopyUsername.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adını kopyala'**
  String get entryCopyUsername;

  /// No description provided for @entryCopyUrl.
  ///
  /// In tr, this message translates to:
  /// **'URL\'yi kopyala'**
  String get entryCopyUrl;

  /// No description provided for @entryCreatedAt.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma'**
  String get entryCreatedAt;

  /// No description provided for @entryUpdatedAt.
  ///
  /// In tr, this message translates to:
  /// **'Son güncelleme'**
  String get entryUpdatedAt;

  /// No description provided for @entryHistory.
  ///
  /// In tr, this message translates to:
  /// **'Şifre geçmişi'**
  String get entryHistory;

  /// No description provided for @entryHistoryCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Önceki şifre yok} other{{count} önceki şifre}}'**
  String entryHistoryCount(int count);

  /// No description provided for @copiedPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre kopyalandı. {seconds} saniye sonra panodan silinecek.'**
  String copiedPassword(int seconds);

  /// No description provided for @copiedValue.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı. {seconds} saniye sonra panodan silinecek.'**
  String copiedValue(int seconds);

  /// No description provided for @historyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre geçmişi'**
  String get historyTitle;

  /// No description provided for @historyInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bu kaydın en fazla son {count} eski şifresi saklanır.'**
  String historyInfo(int count);

  /// No description provided for @historyEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu kaydın şifresi henüz hiç değiştirilmedi.'**
  String get historyEmpty;

  /// No description provided for @historyChangedAt.
  ///
  /// In tr, this message translates to:
  /// **'Değiştirilme: {date}'**
  String historyChangedAt(String date);

  /// No description provided for @loginLockedOut.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla hatalı deneme yapıldı. {time} sonra tekrar deneyebilirsiniz.'**
  String loginLockedOut(String time);

  /// No description provided for @changePasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifreyi değiştir'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlarınız yeniden şifrelenmez; yalnızca kasa anahtarı yeni ana şifrenizle yeniden korunur. Biyometrik giriş çalışmaya devam eder.'**
  String get changePasswordInfo;

  /// No description provided for @changePasswordCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut ana şifre'**
  String get changePasswordCurrent;

  /// No description provided for @changePasswordNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ana şifre'**
  String get changePasswordNew;

  /// No description provided for @changePasswordConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ana şifre (tekrar)'**
  String get changePasswordConfirm;

  /// No description provided for @changePasswordSameAsOld.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre mevcut şifreyle aynı olamaz.'**
  String get changePasswordSameAsOld;

  /// No description provided for @changePasswordButton.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi değiştir'**
  String get changePasswordButton;

  /// No description provided for @changePasswordWorking.
  ///
  /// In tr, this message translates to:
  /// **'Yeni anahtar türetiliyor…'**
  String get changePasswordWorking;

  /// No description provided for @changePasswordWrongCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut ana şifre yanlış.'**
  String get changePasswordWrongCurrent;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifreniz değiştirildi.'**
  String get changePasswordSuccess;

  /// No description provided for @generatorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre üretici'**
  String get generatorTitle;

  /// No description provided for @generatorRegenerate.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden üret'**
  String get generatorRegenerate;

  /// No description provided for @generatorLength.
  ///
  /// In tr, this message translates to:
  /// **'Uzunluk: {length}'**
  String generatorLength(int length);

  /// No description provided for @generatorUppercase.
  ///
  /// In tr, this message translates to:
  /// **'Büyük harf (A–Z)'**
  String get generatorUppercase;

  /// No description provided for @generatorLowercase.
  ///
  /// In tr, this message translates to:
  /// **'Küçük harf (a–z)'**
  String get generatorLowercase;

  /// No description provided for @generatorDigits.
  ///
  /// In tr, this message translates to:
  /// **'Rakam (0–9)'**
  String get generatorDigits;

  /// No description provided for @generatorSymbols.
  ///
  /// In tr, this message translates to:
  /// **'Sembol (!@#…)'**
  String get generatorSymbols;

  /// No description provided for @generatorExcludeAmbiguous.
  ///
  /// In tr, this message translates to:
  /// **'Karışabilecek karakterleri hariç tut (0 O o 1 l I |)'**
  String get generatorExcludeAmbiguous;

  /// No description provided for @generatorUse.
  ///
  /// In tr, this message translates to:
  /// **'Bu şifreyi kullan'**
  String get generatorUse;

  /// No description provided for @generatorGenerateButton.
  ///
  /// In tr, this message translates to:
  /// **'Şifre üret'**
  String get generatorGenerateButton;

  /// No description provided for @reportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik raporu'**
  String get reportTitle;

  /// No description provided for @reportAllGood.
  ///
  /// In tr, this message translates to:
  /// **'Her şey yolunda'**
  String get reportAllGood;

  /// No description provided for @reportAllGoodBody.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf veya tekrar kullanılan şifre bulunamadı.'**
  String get reportAllGoodBody;

  /// No description provided for @reportWeakTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf şifreler'**
  String get reportWeakTitle;

  /// No description provided for @reportWeakBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu şifreler kolay tahmin edilebilir. Şifre üreticiyle güçlü bir şifre oluşturmanız önerilir.'**
  String get reportWeakBody;

  /// No description provided for @reportReusedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar kullanılan şifreler'**
  String get reportReusedTitle;

  /// No description provided for @reportReusedBody.
  ///
  /// In tr, this message translates to:
  /// **'Aynı şifre birden fazla hesapta kullanılıyor. Biri ele geçirilirse diğerleri de risk altına girer.'**
  String get reportReusedBody;

  /// No description provided for @reportReusedGroup.
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıt aynı şifreyi kullanıyor'**
  String reportReusedGroup(int count);

  /// No description provided for @reportBanner.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 güvenlik uyarısı} other{{count} güvenlik uyarısı}}'**
  String reportBanner(int count);

  /// No description provided for @reportBannerAction.
  ///
  /// In tr, this message translates to:
  /// **'İncele'**
  String get reportBannerAction;

  /// No description provided for @backupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme'**
  String get backupTitle;

  /// No description provided for @backupIntro.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyası, ana şifrenizden ayrı bir yedek şifresiyle şifrelenir. Dosyayı nereye kaydedeceğinizi siz seçersiniz; KilitDepo hiçbir yere göndermez.'**
  String get backupIntro;

  /// No description provided for @backupExportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedek oluştur'**
  String get backupExportTitle;

  /// No description provided for @backupPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yedek şifresi'**
  String get backupPasswordLabel;

  /// No description provided for @backupPasswordConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Yedek şifresi (tekrar)'**
  String get backupPasswordConfirm;

  /// No description provided for @backupPasswordWarning.
  ///
  /// In tr, this message translates to:
  /// **'Yedek şifresini unutursanız yedek AÇILAMAZ. Ana şifrenizden farklı, güçlü bir şifre seçin ve güvenli bir yerde saklayın.'**
  String get backupPasswordWarning;

  /// No description provided for @backupExportButton.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği kaydet'**
  String get backupExportButton;

  /// No description provided for @backupExporting.
  ///
  /// In tr, this message translates to:
  /// **'Yedek şifreleniyor…'**
  String get backupExporting;

  /// No description provided for @backupExported.
  ///
  /// In tr, this message translates to:
  /// **'Yedek kaydedildi ({count} kayıt).'**
  String backupExported(int count);

  /// No description provided for @backupExportCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme iptal edildi.'**
  String get backupExportCancelled;

  /// No description provided for @backupEmptyVault.
  ///
  /// In tr, this message translates to:
  /// **'Kasanızda yedeklenecek kayıt yok.'**
  String get backupEmptyVault;

  /// No description provided for @backupImportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekten geri yükle'**
  String get backupImportTitle;

  /// No description provided for @backupImportBody.
  ///
  /// In tr, this message translates to:
  /// **'Yedekteki kayıtlar kasanızla birleştirilir. Hiçbir kayıt silinmez; aynı kayıt her iki yerde de varsa daha yakın tarihte güncellenmiş olan kalır.'**
  String get backupImportBody;

  /// No description provided for @backupChooseFile.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyası seç'**
  String get backupChooseFile;

  /// No description provided for @backupSelectedFile.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen dosya: {name}'**
  String backupSelectedFile(String name);

  /// No description provided for @backupDecryptButton.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği aç'**
  String get backupDecryptButton;

  /// No description provided for @backupDecrypting.
  ///
  /// In tr, this message translates to:
  /// **'Yedek çözülüyor…'**
  String get backupDecrypting;

  /// No description provided for @backupWrongPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yedek şifresi yanlış veya dosya değiştirilmiş.'**
  String get backupWrongPassword;

  /// No description provided for @backupInvalidFile.
  ///
  /// In tr, this message translates to:
  /// **'Bu dosya geçerli bir KilitDepo yedeği değil.'**
  String get backupInvalidFile;

  /// No description provided for @backupPreview.
  ///
  /// In tr, this message translates to:
  /// **'{total} kayıt bulundu: {added} yeni, {updated} güncellenecek, {skipped} değişmeyecek.'**
  String backupPreview(int total, int added, int updated, int skipped);

  /// No description provided for @backupImportButton.
  ///
  /// In tr, this message translates to:
  /// **'Kasaya aktar'**
  String get backupImportButton;

  /// No description provided for @backupImported.
  ///
  /// In tr, this message translates to:
  /// **'{added} kayıt eklendi, {updated} kayıt güncellendi.'**
  String backupImported(int added, int updated);

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsSecurity.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get settingsSecurity;

  /// No description provided for @settingsAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsAppearance;

  /// No description provided for @settingsData.
  ///
  /// In tr, this message translates to:
  /// **'Veri'**
  String get settingsData;

  /// No description provided for @settingsInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi'**
  String get settingsInfo;

  /// No description provided for @settingsBiometric.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş'**
  String get settingsBiometric;

  /// No description provided for @settingsBiometricOn.
  ///
  /// In tr, this message translates to:
  /// **'Parmak izi / Face ID ile açılabilir'**
  String get settingsBiometricOn;

  /// No description provided for @settingsBiometricOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get settingsBiometricOff;

  /// No description provided for @settingsBiometricUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda kullanılamıyor'**
  String get settingsBiometricUnavailable;

  /// No description provided for @settingsBiometricConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik girişi aç'**
  String get settingsBiometricConfirmTitle;

  /// No description provided for @settingsBiometricConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Güvenliğiniz için ana şifrenizi girin.'**
  String get settingsBiometricConfirmBody;

  /// No description provided for @settingsBiometricEnabled.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş açıldı.'**
  String get settingsBiometricEnabled;

  /// No description provided for @settingsBiometricDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş kapatıldı.'**
  String get settingsBiometricDisabled;

  /// No description provided for @settingsBiometricFailed.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş açılamadı.'**
  String get settingsBiometricFailed;

  /// No description provided for @settingsConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get settingsConfirm;

  /// No description provided for @settingsAutoLock.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik kilit'**
  String get settingsAutoLock;

  /// No description provided for @settingsAutoLockSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{duration} hareketsizlikten sonra'**
  String settingsAutoLockSubtitle(String duration);

  /// No description provided for @settingsClipboard.
  ///
  /// In tr, this message translates to:
  /// **'Pano temizleme'**
  String get settingsClipboard;

  /// No description provided for @settingsClipboardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalanan şifre {duration} sonra silinir'**
  String settingsClipboardSubtitle(String duration);

  /// No description provided for @settingsTheme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeDark;

  /// No description provided for @settingsLastBackupNever.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yedek alınmadı'**
  String get settingsLastBackupNever;

  /// No description provided for @settingsLastBackup.
  ///
  /// In tr, this message translates to:
  /// **'Son yedek: {date}'**
  String settingsLastBackup(String date);

  /// No description provided for @durationSeconds.
  ///
  /// In tr, this message translates to:
  /// **'{count} saniye'**
  String durationSeconds(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{count} dakika'**
  String durationMinutes(int count);

  /// No description provided for @aboutDescription.
  ///
  /// In tr, this message translates to:
  /// **'KilitDepo, şifrelerinizi yalnızca kendi cihazınızda, güçlü şifrelemeyle saklayan çevrimdışı bir şifre yöneticisidir. Hesaplarınızı tek bir yerde, kimseyle paylaşmadan güvenle yönetmek isteyen herkes için tasarlandı.'**
  String get aboutDescription;

  /// No description provided for @aboutVersion.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutPrivacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik ilkelerimiz'**
  String get aboutPrivacyTitle;

  /// No description provided for @aboutPrivacy1.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama internete bağlanmaz; hiçbir veri cihazınızdan çıkmaz.'**
  String get aboutPrivacy1;

  /// No description provided for @aboutPrivacy2.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı verisi toplanmaz; analitik veya reklam takibi yoktur.'**
  String get aboutPrivacy2;

  /// No description provided for @aboutPrivacy3.
  ///
  /// In tr, this message translates to:
  /// **'Tüm veriler AES-256 ile şifrelenir; ana şifreniz hiçbir yerde saklanmaz.'**
  String get aboutPrivacy3;

  /// No description provided for @aboutSecurityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get aboutSecurityTitle;

  /// No description provided for @aboutSecurity1.
  ///
  /// In tr, this message translates to:
  /// **'Argon2id: Ana şifrenizden anahtar üretir; tahmin denemelerini bilinçli olarak yavaşlatır.'**
  String get aboutSecurity1;

  /// No description provided for @aboutSecurity2.
  ///
  /// In tr, this message translates to:
  /// **'AES-256-GCM: Şifrelerinizi ve notlarınızı şifreler, en küçük değişikliği bile fark eder.'**
  String get aboutSecurity2;

  /// No description provided for @aboutSecurity3.
  ///
  /// In tr, this message translates to:
  /// **'SQLCipher: Veritabanı dosyasının tamamını şifreler.'**
  String get aboutSecurity3;

  /// No description provided for @aboutSecurity4.
  ///
  /// In tr, this message translates to:
  /// **'Donanım destekli anahtar saklama: Anahtarlar iOS Keychain ve Android Keystore ile korunur.'**
  String get aboutSecurity4;

  /// No description provided for @aboutLicenses.
  ///
  /// In tr, this message translates to:
  /// **'Açık kaynak lisansları'**
  String get aboutLicenses;

  /// No description provided for @guideSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Talimatlarda ara'**
  String get guideSearchHint;

  /// No description provided for @guideNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Aramanızla eşleşen bölüm bulunamadı.'**
  String get guideNoResults;

  /// No description provided for @guideStepsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Adımlar'**
  String get guideStepsTitle;

  /// No description provided for @guideTipsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İpuçları'**
  String get guideTipsTitle;

  /// No description provided for @guidePromptTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kasanız hazır'**
  String get guidePromptTitle;

  /// No description provided for @guidePromptBody.
  ///
  /// In tr, this message translates to:
  /// **'Kullanma talimatına göz atmak ister misiniz?'**
  String get guidePromptBody;

  /// No description provided for @guidePromptOpen.
  ///
  /// In tr, this message translates to:
  /// **'Talimatı aç'**
  String get guidePromptOpen;

  /// No description provided for @guidePromptLater.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get guidePromptLater;

  /// No description provided for @clipboardClearNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi temizle'**
  String get clipboardClearNow;

  /// No description provided for @navVault.
  ///
  /// In tr, this message translates to:
  /// **'Kasa'**
  String get navVault;

  /// No description provided for @navGenerator.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Üretici'**
  String get navGenerator;

  /// No description provided for @navReport.
  ///
  /// In tr, this message translates to:
  /// **'Rapor'**
  String get navReport;

  /// No description provided for @navSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get navSettings;

  /// No description provided for @swipeCopy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get swipeCopy;

  /// No description provided for @swipeFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favori'**
  String get swipeFavorite;

  /// No description provided for @reportScore.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik puanı'**
  String get reportScore;

  /// No description provided for @reportScoreExcellent.
  ///
  /// In tr, this message translates to:
  /// **'Mükemmel'**
  String get reportScoreExcellent;

  /// No description provided for @reportScoreGood.
  ///
  /// In tr, this message translates to:
  /// **'İyi, ama iyileştirilebilir'**
  String get reportScoreGood;

  /// No description provided for @reportScoreFair.
  ///
  /// In tr, this message translates to:
  /// **'Orta, iyileştirme gerekli'**
  String get reportScoreFair;

  /// No description provided for @reportScorePoor.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf, hemen ilgilenin'**
  String get reportScorePoor;

  /// No description provided for @reportWeakCount.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf şifre'**
  String get reportWeakCount;

  /// No description provided for @reportReusedCount.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar kullanılan'**
  String get reportReusedCount;

  /// No description provided for @reportReusedWith.
  ///
  /// In tr, this message translates to:
  /// **'{title} ile aynı'**
  String reportReusedWith(String title);

  /// No description provided for @setupStepOf.
  ///
  /// In tr, this message translates to:
  /// **'Adım {current}/{total}'**
  String setupStepOf(int current, int total);

  /// No description provided for @setupStepPasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifrenizi belirleyin'**
  String get setupStepPasswordTitle;

  /// No description provided for @setupStepWarningTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bunu bilmeniz önemli'**
  String get setupStepWarningTitle;

  /// No description provided for @setupStepWarningBody.
  ///
  /// In tr, this message translates to:
  /// **'KilitDepo şifrelerinizi yalnızca bu cihazda, ana şifrenizden türetilen bir anahtarla şifreler. Ana şifreniz hiçbir yerde saklanmaz; bu yüzden onu sıfırlayamayız veya size hatırlatamayız.'**
  String get setupStepWarningBody;

  /// No description provided for @setupStepBiometricTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı giriş'**
  String get setupStepBiometricTitle;

  /// No description provided for @setupStepBiometricBody.
  ///
  /// In tr, this message translates to:
  /// **'Kasanızı her seferinde ana şifre yazmadan, parmak izi veya yüz tanıma ile açabilirsiniz. Bu ayarı daha sonra Ayarlar\'dan değiştirebilirsiniz.'**
  String get setupStepBiometricBody;

  /// No description provided for @setupNext.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get setupNext;

  /// No description provided for @setupBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get setupBack;

  /// No description provided for @entrySectionAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get entrySectionAccount;

  /// No description provided for @entrySectionPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get entrySectionPassword;

  /// No description provided for @entrySectionOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get entrySectionOther;

  /// No description provided for @setupPreviousVaultMissing.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda önceki bir kasanın anahtarı bulundu ama kasa verisi yoktu (örneğin uygulama silinip yeniden yüklendiyse). Yeni bir kasa oluşturun; yedeğiniz varsa kurulumdan sonra Ayarlar > Yedekleme\'den geri yükleyebilirsiniz.'**
  String get setupPreviousVaultMissing;

  /// No description provided for @settingsDynamicColor.
  ///
  /// In tr, this message translates to:
  /// **'Duvar kağıdı renkleri'**
  String get settingsDynamicColor;

  /// No description provided for @settingsDynamicColorSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama renklerini telefonunuzun duvar kağıdına uydurur (Material You)'**
  String get settingsDynamicColorSubtitle;

  /// No description provided for @vaultSelectEntry.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıntılarını görmek için soldan bir kayıt seçin.'**
  String get vaultSelectEntry;

  /// No description provided for @detailCopyUsernameShort.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı'**
  String get detailCopyUsernameShort;

  /// No description provided for @detailCopyPasswordShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get detailCopyPasswordShort;

  /// No description provided for @entryMoreActions.
  ///
  /// In tr, this message translates to:
  /// **'Diğer işlemler'**
  String get entryMoreActions;

  /// No description provided for @loginOrPassword.
  ///
  /// In tr, this message translates to:
  /// **'veya ana şifreyle'**
  String get loginOrPassword;

  /// No description provided for @generatorLengthLabel.
  ///
  /// In tr, this message translates to:
  /// **'Uzunluk'**
  String get generatorLengthLabel;

  /// No description provided for @generatorCharsets.
  ///
  /// In tr, this message translates to:
  /// **'Karakterler'**
  String get generatorCharsets;

  /// No description provided for @reportChangePassword.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get reportChangePassword;

  /// No description provided for @settingsTrueBlack.
  ///
  /// In tr, this message translates to:
  /// **'Tam siyah zemin'**
  String get settingsTrueBlack;

  /// No description provided for @settingsTrueBlackSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Koyu temada zemin tam siyah olur (OLED ekranlarda pil tasarrufu)'**
  String get settingsTrueBlackSubtitle;

  /// No description provided for @commonUndo.
  ///
  /// In tr, this message translates to:
  /// **'Geri al'**
  String get commonUndo;

  /// No description provided for @entryDeletedUndo.
  ///
  /// In tr, this message translates to:
  /// **'\"{title}\" silindi'**
  String entryDeletedUndo(String title);

  /// No description provided for @generatorModeRandom.
  ///
  /// In tr, this message translates to:
  /// **'Rastgele'**
  String get generatorModeRandom;

  /// No description provided for @generatorModeWords.
  ///
  /// In tr, this message translates to:
  /// **'Kelimeler'**
  String get generatorModeWords;

  /// No description provided for @generatorWordCount.
  ///
  /// In tr, this message translates to:
  /// **'Kelime sayısı'**
  String get generatorWordCount;

  /// No description provided for @generatorWordCountValue.
  ///
  /// In tr, this message translates to:
  /// **'{count} kelime'**
  String generatorWordCountValue(int count);

  /// No description provided for @generatorSeparator.
  ///
  /// In tr, this message translates to:
  /// **'Ayırıcı'**
  String get generatorSeparator;

  /// No description provided for @generatorCapitalize.
  ///
  /// In tr, this message translates to:
  /// **'Kelimeleri büyük harfle başlat'**
  String get generatorCapitalize;

  /// No description provided for @generatorAddNumber.
  ///
  /// In tr, this message translates to:
  /// **'Sonuna sayı ekle'**
  String get generatorAddNumber;

  /// No description provided for @generatorEntropy.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini güç: yaklaşık {bits} bit'**
  String generatorEntropy(int bits);

  /// No description provided for @entryAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get entryAppearance;

  /// No description provided for @entryAppearanceDefault.
  ///
  /// In tr, this message translates to:
  /// **'Baş harf, otomatik renk'**
  String get entryAppearanceDefault;

  /// No description provided for @entryAppearanceIcon.
  ///
  /// In tr, this message translates to:
  /// **'Simge'**
  String get entryAppearanceIcon;

  /// No description provided for @entryAppearanceColor.
  ///
  /// In tr, this message translates to:
  /// **'Renk'**
  String get entryAppearanceColor;

  /// No description provided for @entryAppearanceLetter.
  ///
  /// In tr, this message translates to:
  /// **'Harf'**
  String get entryAppearanceLetter;

  /// No description provided for @entryAppearanceAuto.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik'**
  String get entryAppearanceAuto;

  /// No description provided for @entryAppearanceReset.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılana dön'**
  String get entryAppearanceReset;

  /// No description provided for @entryAppearanceDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get entryAppearanceDone;

  /// No description provided for @entryIconBank.
  ///
  /// In tr, this message translates to:
  /// **'Banka'**
  String get entryIconBank;

  /// No description provided for @entryIconCard.
  ///
  /// In tr, this message translates to:
  /// **'Kart'**
  String get entryIconCard;

  /// No description provided for @entryIconWallet.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan'**
  String get entryIconWallet;

  /// No description provided for @entryIconCart.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş'**
  String get entryIconCart;

  /// No description provided for @entryIconBag.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get entryIconBag;

  /// No description provided for @entryIconEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get entryIconEmail;

  /// No description provided for @entryIconChat.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlaşma'**
  String get entryIconChat;

  /// No description provided for @entryIconPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get entryIconPhone;

  /// No description provided for @entryIconPeople.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal'**
  String get entryIconPeople;

  /// No description provided for @entryIconWork.
  ///
  /// In tr, this message translates to:
  /// **'İş'**
  String get entryIconWork;

  /// No description provided for @entryIconSchool.
  ///
  /// In tr, this message translates to:
  /// **'Okul'**
  String get entryIconSchool;

  /// No description provided for @entryIconGame.
  ///
  /// In tr, this message translates to:
  /// **'Oyun'**
  String get entryIconGame;

  /// No description provided for @entryIconMusic.
  ///
  /// In tr, this message translates to:
  /// **'Müzik'**
  String get entryIconMusic;

  /// No description provided for @entryIconVideo.
  ///
  /// In tr, this message translates to:
  /// **'Video'**
  String get entryIconVideo;

  /// No description provided for @entryIconPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf'**
  String get entryIconPhoto;

  /// No description provided for @entryIconCloud.
  ///
  /// In tr, this message translates to:
  /// **'Bulut'**
  String get entryIconCloud;

  /// No description provided for @entryIconComputer.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayar'**
  String get entryIconComputer;

  /// No description provided for @entryIconCode.
  ///
  /// In tr, this message translates to:
  /// **'Yazılım'**
  String get entryIconCode;

  /// No description provided for @entryIconWifi.
  ///
  /// In tr, this message translates to:
  /// **'Wi-Fi'**
  String get entryIconWifi;

  /// No description provided for @entryIconHome.
  ///
  /// In tr, this message translates to:
  /// **'Ev'**
  String get entryIconHome;

  /// No description provided for @entryIconCar.
  ///
  /// In tr, this message translates to:
  /// **'Araba'**
  String get entryIconCar;

  /// No description provided for @entryIconFlight.
  ///
  /// In tr, this message translates to:
  /// **'Seyahat'**
  String get entryIconFlight;

  /// No description provided for @entryIconHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get entryIconHealth;

  /// No description provided for @entryIconFitness.
  ///
  /// In tr, this message translates to:
  /// **'Spor'**
  String get entryIconFitness;

  /// No description provided for @entryIconFood.
  ///
  /// In tr, this message translates to:
  /// **'Yemek'**
  String get entryIconFood;

  /// No description provided for @entryIconCoffee.
  ///
  /// In tr, this message translates to:
  /// **'Kafe'**
  String get entryIconCoffee;

  /// No description provided for @entryIconId.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik'**
  String get entryIconId;

  /// No description provided for @entryIconShield.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get entryIconShield;

  /// No description provided for @entryIconKey.
  ///
  /// In tr, this message translates to:
  /// **'Anahtar'**
  String get entryIconKey;

  /// No description provided for @entryIconLock.
  ///
  /// In tr, this message translates to:
  /// **'Kilit'**
  String get entryIconLock;

  /// No description provided for @entryIconStar.
  ///
  /// In tr, this message translates to:
  /// **'Yıldız'**
  String get entryIconStar;

  /// No description provided for @entryIconGlobe.
  ///
  /// In tr, this message translates to:
  /// **'Web'**
  String get entryIconGlobe;

  /// No description provided for @entryIconBook.
  ///
  /// In tr, this message translates to:
  /// **'Kitap'**
  String get entryIconBook;

  /// No description provided for @entryIconNews.
  ///
  /// In tr, this message translates to:
  /// **'Haber'**
  String get entryIconNews;

  /// No description provided for @entryIconGift.
  ///
  /// In tr, this message translates to:
  /// **'Hediye'**
  String get entryIconGift;

  /// No description provided for @entryIconStock.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım'**
  String get entryIconStock;

  /// No description provided for @entryIconPet.
  ///
  /// In tr, this message translates to:
  /// **'Evcil hayvan'**
  String get entryIconPet;

  /// No description provided for @entryIconTools.
  ///
  /// In tr, this message translates to:
  /// **'Araçlar'**
  String get entryIconTools;

  /// No description provided for @entryColorTeal.
  ///
  /// In tr, this message translates to:
  /// **'Petrol'**
  String get entryColorTeal;

  /// No description provided for @entryColorGreen.
  ///
  /// In tr, this message translates to:
  /// **'Yeşil'**
  String get entryColorGreen;

  /// No description provided for @entryColorOlive.
  ///
  /// In tr, this message translates to:
  /// **'Zeytin'**
  String get entryColorOlive;

  /// No description provided for @entryColorBlue.
  ///
  /// In tr, this message translates to:
  /// **'Mavi'**
  String get entryColorBlue;

  /// No description provided for @entryColorIndigo.
  ///
  /// In tr, this message translates to:
  /// **'Lacivert'**
  String get entryColorIndigo;

  /// No description provided for @entryColorPurple.
  ///
  /// In tr, this message translates to:
  /// **'Mor'**
  String get entryColorPurple;

  /// No description provided for @entryColorPink.
  ///
  /// In tr, this message translates to:
  /// **'Pembe'**
  String get entryColorPink;

  /// No description provided for @entryColorRed.
  ///
  /// In tr, this message translates to:
  /// **'Kırmızı'**
  String get entryColorRed;

  /// No description provided for @entryColorOrange.
  ///
  /// In tr, this message translates to:
  /// **'Turuncu'**
  String get entryColorOrange;

  /// No description provided for @entryColorAmber.
  ///
  /// In tr, this message translates to:
  /// **'Kehribar'**
  String get entryColorAmber;

  /// No description provided for @entryColorBrown.
  ///
  /// In tr, this message translates to:
  /// **'Kahverengi'**
  String get entryColorBrown;

  /// No description provided for @entryColorSlate.
  ///
  /// In tr, this message translates to:
  /// **'Gri'**
  String get entryColorSlate;

  /// No description provided for @vaultQuickAccess.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get vaultQuickAccess;

  /// No description provided for @entryOpenDetails.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıntıları aç'**
  String get entryOpenDetails;

  /// No description provided for @issueWeakBadge.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf'**
  String get issueWeakBadge;

  /// No description provided for @issueReusedBadge.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get issueReusedBadge;

  /// No description provided for @detailIssueWeak.
  ///
  /// In tr, this message translates to:
  /// **'Bu şifre zayıf; tahmin edilmesi kolay olabilir.'**
  String get detailIssueWeak;

  /// No description provided for @detailIssueReused.
  ///
  /// In tr, this message translates to:
  /// **'Bu şifre şu kayıtlarda da kullanılıyor: {titles}'**
  String detailIssueReused(String titles);

  /// No description provided for @detailIssueChange.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi değiştir'**
  String get detailIssueChange;

  /// No description provided for @setupTipsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İyi bir ana şifre nasıl seçilir?'**
  String get setupTipsTitle;

  /// No description provided for @setupTipWords.
  ///
  /// In tr, this message translates to:
  /// **'4–6 rastgele kelime kullanın: hem güçlü hem yazması kolay.'**
  String get setupTipWords;

  /// No description provided for @setupTipUnique.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir yerde kullandığınız şifreyi kullanmayın.'**
  String get setupTipUnique;

  /// No description provided for @setupTipPersonal.
  ///
  /// In tr, this message translates to:
  /// **'Adınız, doğum tarihiniz, takımınız gibi kişisel bilgilerden kaçının.'**
  String get setupTipPersonal;

  /// No description provided for @setupSuggest.
  ///
  /// In tr, this message translates to:
  /// **'Bana bir öneri üret'**
  String get setupSuggest;

  /// No description provided for @setupSuggestionUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullan'**
  String get setupSuggestionUse;

  /// No description provided for @setupSuggestionAnother.
  ///
  /// In tr, this message translates to:
  /// **'Başka öneri'**
  String get setupSuggestionAnother;

  /// No description provided for @setupSuggestionHint.
  ///
  /// In tr, this message translates to:
  /// **'Öneriyi kullanırsanız tekrar alanını kendiniz yazın; böylece şifreyi bir kez de elinizle yazmış olursunuz.'**
  String get setupSuggestionHint;

  /// No description provided for @setupWeakTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ana şifre zayıf'**
  String get setupWeakTitle;

  /// No description provided for @setupWeakBody.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifreniz tüm kasanızı korur. Daha uzun bir şifre ya da birkaç rastgele kelime önerilir.'**
  String get setupWeakBody;

  /// No description provided for @setupWeakChange.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi değiştir'**
  String get setupWeakChange;

  /// No description provided for @setupWeakContinue.
  ///
  /// In tr, this message translates to:
  /// **'Yine de devam et'**
  String get setupWeakContinue;

  /// No description provided for @setupStoreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ana şifrenizi nasıl saklamalısınız?'**
  String get setupStoreTitle;

  /// No description provided for @setupStorePaper.
  ///
  /// In tr, this message translates to:
  /// **'Kâğıda yazın ve güvenli bir yerde saklayın.'**
  String get setupStorePaper;

  /// No description provided for @setupStoreNoPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun notlarına veya fotoğraflarına kaydetmeyin.'**
  String get setupStoreNoPhone;

  /// No description provided for @setupStoreBackup.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli yedek alın (Ayarlar > Yedekleme).'**
  String get setupStoreBackup;

  /// No description provided for @csvImportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başka uygulamadan içe aktar'**
  String get csvImportTitle;

  /// No description provided for @csvImportSettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Chrome, Safari, Bitwarden, 1Password… (CSV dosyası)'**
  String get csvImportSettingsSubtitle;

  /// No description provided for @csvImportIntro.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir şifre yöneticisinden veya tarayıcıdan dışa aktardığınız CSV dosyasındaki kayıtları kasanıza ekler. Mevcut kayıtlarınız silinmez veya değiştirilmez.'**
  String get csvImportIntro;

  /// No description provided for @csvImportPlainWarning.
  ///
  /// In tr, this message translates to:
  /// **'CSV dosyaları şifrelerinizi düz metin olarak içerir. İçe aktardıktan sonra dosyayı mutlaka silin ve kimseyle paylaşmayın.'**
  String get csvImportPlainWarning;

  /// No description provided for @csvImportHowTo.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl dışa aktarılacağını Kullanma Talimatı\'ndaki \"Başka uygulamadan aktarma\" bölümünde bulabilirsiniz.'**
  String get csvImportHowTo;

  /// No description provided for @csvImportPick.
  ///
  /// In tr, this message translates to:
  /// **'CSV dosyası seç'**
  String get csvImportPick;

  /// No description provided for @csvImportReading.
  ///
  /// In tr, this message translates to:
  /// **'Dosya okunuyor…'**
  String get csvImportReading;

  /// No description provided for @csvImportFormatLabel.
  ///
  /// In tr, this message translates to:
  /// **'Algılanan biçim: {format}'**
  String csvImportFormatLabel(String format);

  /// No description provided for @csvFormatChrome.
  ///
  /// In tr, this message translates to:
  /// **'Chrome / Edge / Brave'**
  String get csvFormatChrome;

  /// No description provided for @csvFormatFirefox.
  ///
  /// In tr, this message translates to:
  /// **'Firefox'**
  String get csvFormatFirefox;

  /// No description provided for @csvFormatApple.
  ///
  /// In tr, this message translates to:
  /// **'Safari / Apple Passwords'**
  String get csvFormatApple;

  /// No description provided for @csvFormatBitwarden.
  ///
  /// In tr, this message translates to:
  /// **'Bitwarden'**
  String get csvFormatBitwarden;

  /// No description provided for @csvFormatOnePassword.
  ///
  /// In tr, this message translates to:
  /// **'1Password'**
  String get csvFormatOnePassword;

  /// No description provided for @csvFormatProtonPass.
  ///
  /// In tr, this message translates to:
  /// **'Proton Pass'**
  String get csvFormatProtonPass;

  /// No description provided for @csvFormatKeePass.
  ///
  /// In tr, this message translates to:
  /// **'KeePass / KeePassXC'**
  String get csvFormatKeePass;

  /// No description provided for @csvFormatGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Genel CSV'**
  String get csvFormatGeneric;

  /// No description provided for @csvImportToAdd.
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıt eklenecek'**
  String csvImportToAdd(int count);

  /// No description provided for @csvImportDuplicates.
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıt zaten kasada olduğu için atlanacak'**
  String csvImportDuplicates(int count);

  /// No description provided for @csvImportNoPassword.
  ///
  /// In tr, this message translates to:
  /// **'{count} satır şifresi boş olduğu için atlanacak'**
  String csvImportNoPassword(int count);

  /// No description provided for @csvImportTotp.
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıttaki 2 adımlı doğrulama (TOTP) anahtarı güvenlik nedeniyle aktarılmayacak'**
  String csvImportTotp(int count);

  /// No description provided for @csvImportNothing.
  ///
  /// In tr, this message translates to:
  /// **'Eklenecek yeni kayıt yok.'**
  String get csvImportNothing;

  /// No description provided for @csvImportPreviewList.
  ///
  /// In tr, this message translates to:
  /// **'Eklenecek kayıtlar'**
  String get csvImportPreviewList;

  /// No description provided for @csvImportMore.
  ///
  /// In tr, this message translates to:
  /// **'+{count} kayıt daha'**
  String csvImportMore(int count);

  /// No description provided for @csvImportConfirm.
  ///
  /// In tr, this message translates to:
  /// **'İçe aktar'**
  String get csvImportConfirm;

  /// No description provided for @csvImportOtherFile.
  ///
  /// In tr, this message translates to:
  /// **'Başka dosya seç'**
  String get csvImportOtherFile;

  /// No description provided for @csvImportImporting.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlar şifrelenerek ekleniyor…'**
  String get csvImportImporting;

  /// No description provided for @csvImportDone.
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıt kasanıza eklendi.'**
  String csvImportDone(int count);

  /// No description provided for @csvImportDeleteReminder.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi orijinal CSV dosyasını silin: dosya şifrelerinizi düz metin olarak içeriyor ve KilitDepo onu sizin yerinize silemez.'**
  String get csvImportDeleteReminder;

  /// No description provided for @csvImportFinish.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get csvImportFinish;

  /// No description provided for @csvImportErrorEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Dosyada içe aktarılacak kayıt bulunamadı.'**
  String get csvImportErrorEmpty;

  /// No description provided for @csvImportErrorEncoding.
  ///
  /// In tr, this message translates to:
  /// **'Dosya okunamadı. Lütfen CSV (UTF-8) biçiminde dışa aktarın.'**
  String get csvImportErrorEncoding;

  /// No description provided for @csvImportErrorTooLarge.
  ///
  /// In tr, this message translates to:
  /// **'Dosya çok büyük (en fazla 10 MB ve 10.000 kayıt).'**
  String get csvImportErrorTooLarge;

  /// No description provided for @csvImportErrorColumns.
  ///
  /// In tr, this message translates to:
  /// **'Bu dosya tanınamadı: başlık/adres ve şifre sütunları bulunamadı.'**
  String get csvImportErrorColumns;

  /// No description provided for @csvImportScreenTitle.
  ///
  /// In tr, this message translates to:
  /// **'CSV\'den içe aktar'**
  String get csvImportScreenTitle;

  /// No description provided for @entrySaveErrorLocked.
  ///
  /// In tr, this message translates to:
  /// **'Kasa kilitlendiği için kaydedilemedi. Kilidi açıp tekrar deneyin.'**
  String get entrySaveErrorLocked;

  /// No description provided for @entrySaveErrorInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemedi: başlık ve şifre alanları boş olamaz.'**
  String get entrySaveErrorInvalid;

  /// No description provided for @entrySaveErrorStorageFull.
  ///
  /// In tr, this message translates to:
  /// **'Cihazda yeterli boş alan olmadığı için kaydedilemedi.'**
  String get entrySaveErrorStorageFull;

  /// No description provided for @entrySaveErrorBusy.
  ///
  /// In tr, this message translates to:
  /// **'Veritabanı şu an meşgul olduğu için kaydedilemedi. Birkaç saniye sonra tekrar deneyin.'**
  String get entrySaveErrorBusy;

  /// No description provided for @entrySaveErrorDatabase.
  ///
  /// In tr, this message translates to:
  /// **'Veritabanına yazılamadı (hata kodu: {code}). Lütfen tekrar deneyin.'**
  String entrySaveErrorDatabase(String code);

  /// No description provided for @entrySaveErrorCrypto.
  ///
  /// In tr, this message translates to:
  /// **'Şifreleme sırasında bir sorun oluştuğu için kaydedilemedi.'**
  String get entrySaveErrorCrypto;

  /// No description provided for @entrySaveErrorUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt kaydedilemedi (ayrıntı: {detail}). Lütfen tekrar deneyin.'**
  String entrySaveErrorUnknown(String detail);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
