import 'package:flutter/material.dart';

/// Kullanma talimatı bölümü.
///
/// İçerik koddan ayrı, yapılandırılmış veri olarak tutulur: ileride çeviri
/// için bu dosyanın dil başına bir kopyası (veya ARB/JSON karşılığı)
/// oluşturulması yeterlidir. Ekran kodu değişmez.
@immutable
class GuideSection {
  const GuideSection({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    this.steps = const [],
    this.tips = const [],
    this.faq = const [],
  });

  final String id;
  final IconData icon;
  final String title;
  final String summary;
  final List<String> steps;
  final List<String> tips;
  final List<GuideFaq> faq;

  /// Arama için tüm metin.
  String get searchableText => [
    title,
    summary,
    ...steps,
    ...tips,
    for (final f in faq) ...[f.question, f.answer],
  ].join('\n');
}

@immutable
class GuideFaq {
  const GuideFaq(this.question, this.answer);

  final String question;
  final String answer;
}

/// Türkçe kullanma talimatı (tamamen çevrimdışı, uygulama içinde gömülü).
const List<GuideSection> guideContentTr = [
  GuideSection(
    id: 'welcome',
    icon: Icons.waving_hand_outlined,
    title: "KilitDepo'ya hoş geldiniz",
    summary:
        'KilitDepo, şifrelerinizi yalnızca kendi cihazınızda, güçlü '
        'şifrelemeyle saklayan bir şifre yöneticisidir. İnternete hiç '
        'bağlanmaz; verileriniz cihazınızdan çıkmaz. Tek bir ana şifreyle '
        'tüm hesaplarınıza ait şifrelere güvenle ulaşırsınız.',
  ),
  GuideSection(
    id: 'setup',
    icon: Icons.key_outlined,
    title: 'İlk kurulum ve ana şifre oluşturma',
    summary:
        'Ana şifre, kasanızın tek anahtarıdır. KilitDepo bu şifreyi hiçbir '
        'yerde saklamaz; yalnızca siz bilirsiniz.',
    steps: [
      'Uygulamayı ilk açtığınızda "Ana şifre oluşturun" ekranı gelir.',
      'En az 10 karakterlik bir ana şifre yazın. Güç göstergesi şifrenizin '
          'ne kadar sağlam olduğunu gösterir.',
      'Fikir lazımsa "İyi bir ana şifre nasıl seçilir?" kartını açın; '
          '"Bana bir öneri üret" ile kelimelerden oluşan bir öneri alabilirsiniz. '
          '"Kullan" öneriyi yalnızca ilk alana yazar.',
      'Şifreyi ikinci alana kendiniz tekrar yazın.',
      'Şifreniz zayıfsa bir uyarı çıkar; değiştirmeniz önerilir, ama '
          '"Yine de devam et" ile ilerleyebilirsiniz.',
      '"Ana şifrenizi unutursanız verileriniz kurtarılamaz" uyarısını ve '
          'saklama önerilerini (kâğıda yazın, telefonda saklamayın, yedek '
          'alın) okuyup onay kutusunu işaretleyin.',
      'Cihazınız destekliyorsa biyometrik girişi bu adımda açabilirsiniz.',
      '"Kasayı oluştur"a dokunun. Anahtar türetilirken birkaç saniye '
          'beklemeniz normaldir.',
    ],
    tips: [
      'Birkaç rastgele kelimeden oluşan uzun bir cümle hem güçlü hem de '
          'akılda kalıcıdır (ör. "Mavi-Kedi.Uçan*Bulut_42").',
      'Ana şifrenizi başka hiçbir hesapta kullanmayın.',
      'Doğum tarihi, isim veya "123456" gibi tahmin edilebilir ifadelerden '
          'kaçının.',
      'Ana şifrenizi bir kâğıda yazıp güvenli, kimsenin erişemeyeceği bir '
          'yerde saklamayı düşünebilirsiniz.',
    ],
  ),
  GuideSection(
    id: 'add',
    icon: Icons.add_circle_outline,
    title: 'Şifre ekleme',
    summary:
        'Her hesap için başlık, kullanıcı adı ve şifre içeren bir kayıt '
        'oluşturursunuz.',
    steps: [
      'Kasa ekranında sağ alttaki "Yeni kayıt" butonuna dokunun.',
      'Başlık (ör. "Banka") ve şifre alanlarını doldurun; bu ikisi zorunludur.',
      'İsterseniz kullanıcı adı, URL ve notlar ekleyin.',
      'Uygun kategoriyi seçin: Sosyal Medya, Banka, E-posta, İş veya Diğer.',
      'Güçlü bir şifre için "Şifre üret" butonunu kullanabilirsiniz.',
      'Sağ üstteki "Kaydet"e dokunun.',
    ],
    tips: [
      'Notlar alanı da şifreli saklanır; kurtarma kodları gibi bilgileri '
          'buraya yazabilirsiniz.',
    ],
  ),
  GuideSection(
    id: 'list',
    icon: Icons.manage_search,
    title: 'Şifreleri listeleme, sıralama, arama ve filtreleme',
    summary:
        'Kasa ekranı tüm kayıtlarınızı gösterir. Şifreler listede asla '
        'görünmez.',
    steps: [
      'Arama kutusuna yazarak başlık, kullanıcı adı veya URL içinde arayın. '
          'Türkçe karakterleri yazmanız gerekmez: "sifre" yazınca "Şifre" de '
          'bulunur.',
      'Sağ üstteki sıralama simgesiyle alfabetik, son eklenen, son '
          'güncellenen veya kategoriye göre sıralayın.',
      'Arama kutusunun altındaki çiplerle kategori seçin ya da yalnızca '
          'favorileri gösterin.',
      'Bir kayda dokunarak ayrıntılarını açın.',
      'Favorilere eklediğiniz kayıtlar listenin üstündeki "Favoriler" '
          'şeridinde görünür; birine dokununca şifresi kopyalanır, uzun '
          'basınca diğer seçenekler açılır.',
      'Kaydın sağındaki kopyala simgesi şifreyi tek dokunuşla kopyalar.',
      'Zayıf veya başka kayıtla aynı şifreyi kullanan kayıtlarda "Zayıf" / '
          '"Tekrar" etiketi görünür; kayda dokunup "Şifreyi değiştir" ile '
          'hemen düzeltebilirsiniz.',
      'Bir kayda uzun basınca kullanıcı adını, şifreyi veya URL\'yi '
          'kopyalama, favori ve düzenleme seçenekleri açılır.',
      'Kısayollar: bir kaydı sağa kaydırınca şifresi kopyalanır, sola '
          'kaydırınca favorilere eklenir veya çıkarılır.',
    ],
  ),
  GuideSection(
    id: 'edit',
    icon: Icons.edit_note,
    title: 'Şifre düzenleme, silme ve geçmişi görüntüleme',
    summary:
        'Kayıtlarınızı istediğiniz zaman güncelleyebilir veya '
        'silebilirsiniz. Eski şifreler geçmişte saklanır.',
    steps: [
      'Kaydın ayrıntı ekranında kalem simgesiyle düzenlemeyi açın, '
          'değişiklikleri yapıp "Kaydet"e dokunun.',
      'Düzenleme ekranındaki "Görünüm" satırından kayda simge ve renk '
          'seçebilirsiniz; kayıtlarınızı listede daha kolay ayırt edersiniz. '
          'Simgeler uygulamanın içindedir, internet kullanılmaz.',
      'Şifreyi değiştirdiğinizde eski şifre otomatik olarak "Şifre geçmişi" '
          'bölümüne eklenir. Her kayıt için son 10 eski şifre saklanır.',
      'Geçmişi görmek için ayrıntı ekranındaki "Şifre geçmişi" satırına '
          'dokunun.',
      'Silmek için ayrıntı ekranında sağ üstteki üç nokta menüsünden '
          '"Sil"i seçin. Birkaç saniye boyunca çıkan bildirimdeki "Geri al" '
          'ile kaydı geri getirebilirsiniz; süre dolunca veya kasa '
          'kilitlenince kayıt ve geçmişi kalıcı olarak silinir.',
    ],
  ),
  GuideSection(
    id: 'copy',
    icon: Icons.copy_outlined,
    title: 'Şifreyi kopyalama',
    summary:
        'Şifreyi tek dokunuşla kopyalayıp başka bir uygulamaya '
        'yapıştırabilirsiniz.',
    steps: [
      'Ayrıntı ekranındaki "Şifre" butonuna (veya listede kaydın sağındaki '
          'kopyala simgesine) dokunun.',
      'Giriş yapacağınız uygulamaya geçip şifreyi yapıştırın.',
      'Kopyalanan şifre 30 saniye sonra panodan otomatik olarak silinir. Bu '
          'süreyi Ayarlar > Pano temizleme bölümünden değiştirebilirsiniz.',
    ],
    tips: [
      'Göz simgesiyle şifreyi ekranda da görebilirsiniz; tekrar dokunarak '
          'gizleyin.',
      '"Kilitle" butonuyla kasayı kilitlediğinizde pano hemen temizlenir.',
    ],
  ),
  GuideSection(
    id: 'generator',
    icon: Icons.auto_awesome,
    title: 'Şifre üretici kullanımı',
    summary:
        'KilitDepo, tahmin edilmesi neredeyse imkânsız rastgele '
        'şifreler veya akılda kalan kelime tabanlı şifreler üretebilir.',
    steps: [
      'Alt çubuktaki "Şifre Üretici" sekmesini açın ya da kayıt formundaki '
          '"Şifre üret" butonuna dokunun.',
      'Üstten "Rastgele" ya da "Kelimeler" kipini seçin. Son seçimleriniz '
          'hatırlanır.',
      'Rastgele kipte uzunluğu (8–64) kaydırıcıyla seçin.',
      'Büyük harf, küçük harf, rakam ve sembol seçeneklerini ihtiyacınıza '
          'göre açıp kapatın.',
      '"Karışabilecek karakterleri hariç tut" seçeneği 0/O veya 1/l gibi '
          'karakterleri çıkarır; şifreyi elle yazacaksanız işinize yarar.',
      'Yenile simgesiyle yeni bir şifre üretin; kopyalayın veya kayda '
          'kullanın.',
    ],
    tips: [
      'Mümkünse en az 16 karakter ve tüm karakter türlerini kullanın.',
      'Kelimeler kipi "Kartal-Limon-Dere-Masa-Bulut-47" gibi, elle yazması '
          've hatırlaması kolay şifreler üretir. Güç, kelime sayısına göre '
          'gerçekçi olarak gösterilir; en az 6 kelime önerilir.',
    ],
  ),
  GuideSection(
    id: 'biometric',
    icon: Icons.fingerprint,
    title: 'Biyometrik giriş (parmak izi / Face ID) açma',
    summary:
        'Kasanızı her seferinde ana şifre yazmadan, parmak izi veya '
        'yüz tanıma ile açabilirsiniz.',
    steps: [
      'Önce cihazınızın ayarlarından bir ekran kilidi ve parmak izi ya da '
          'Face ID tanımlayın.',
      'KilitDepo\'da Ayarlar > Biyometrik giriş anahtarını açın.',
      'Güvenliğiniz için ana şifrenizi bir kez girin.',
      'Artık giriş ekranında "Biyometrik ile aç" butonunu kullanabilirsiniz.',
    ],
    tips: [
      'Cihazınıza yeni bir parmak izi veya yüz eklenirse biyometrik giriş '
          'güvenlik gereği devre dışı kalabilir; ana şifrenizle girip yeniden '
          'açabilirsiniz.',
      'Biyometrik giriş açık olsa da ana şifreniz her zaman çalışır.',
    ],
  ),
  GuideSection(
    id: 'security',
    icon: Icons.lock_clock_outlined,
    title: 'Otomatik kilit ve güvenlik ayarları',
    summary: 'KilitDepo, siz unutsanız bile kasanızı kendiliğinden kilitler.',
    steps: [
      'Uygulamadan çıktığınızda veya başka bir uygulamaya geçtiğinizde kasa '
          'hemen kilitlenir.',
      'Ekrana belirli bir süre dokunmazsanız da kilitlenir. Bu süreyi '
          'Ayarlar > Otomatik kilit bölümünden seçebilirsiniz (30 saniye – '
          '30 dakika).',
      'Ana şifre arka arkaya 5 kez yanlış girilirse, bir sonraki deneme için '
          'giderek uzayan bir süre (30 saniyeden 1 saate kadar) beklemeniz '
          'gerekir.',
      'Ekran görüntüsü ve ekran kaydı engellenir; uygulama değiştiricide '
          'içerik gizlenir.',
      'Ana şifrenizi Ayarlar > Ana şifreyi değiştir bölümünden '
          'değiştirebilirsiniz.',
    ],
  ),
  GuideSection(
    id: 'backup',
    icon: Icons.backup_outlined,
    title: 'Yedekleme ve geri yükleme',
    summary:
        'Telefonunuz kaybolur, bozulur veya değişirse kayıtlarınızı '
        'yedekten geri yükleyebilirsiniz.',
    steps: [
      'Ayarlar > Yedekleme bölümünü açın.',
      'Ana şifrenizden FARKLI, güçlü bir yedek şifresi belirleyin ve iki kez '
          'yazın.',
      '"Yedeği kaydet"e dokunun ve dosyayı nereye kaydedeceğinizi seçin '
          '(ör. bilgisayarınız veya harici bir disk).',
      'Geri yüklemek için aynı bölümde "Yedek dosyası seç"e dokunun, yedek '
          'şifresini girin ve önizlemeyi kontrol edip "Kasaya aktar"a '
          'dokunun.',
      'Geri yükleme kayıtlarınızı birleştirir; hiçbir kayıt silinmez.',
    ],
    tips: [
      'Yedek şifresini unutursanız yedek açılamaz. Bu şifreyi güvenli bir '
          'yerde saklayın.',
      'Yedek dosyası tamamen şifrelidir; yine de yalnızca güvendiğiniz '
          'yerlerde saklayın.',
      'Önemli değişikliklerden sonra ve düzenli aralıklarla (ör. ayda bir) '
          'yedek alın. Son yedek tarihini Ayarlar\'da görebilirsiniz.',
    ],
  ),
  GuideSection(
    id: 'csv-import',
    icon: Icons.file_upload_outlined,
    title: 'Başka uygulamadan aktarma',
    summary:
        'Tarayıcınızdaki veya başka bir şifre yöneticisindeki kayıtları tek '
        'tek yazmadan KilitDepo\'ya ekleyebilirsiniz.',
    steps: [
      'Kullandığınız uygulamada şifreleri "CSV" olarak dışa aktarın. Örnek: '
          'Chrome\'da Ayarlar > Google Şifre Yöneticisi > Ayarlar > '
          '"Şifreleri dışa aktar"; Bitwarden\'da Ayarlar > Kasa > "Kasayı '
          'dışa aktar" (.csv). Diğer uygulamalarda ayarlardaki "Dışa aktar / '
          'Export" seçeneğini arayın.',
      'KilitDepo\'da Ayarlar > Veri > "Başka uygulamadan içe aktar"ı açın '
          've "CSV dosyası seç"e dokunun.',
      'Önizlemede kaç kaydın ekleneceğini ve hangilerinin atlanacağını '
          'görürsünüz; şifreler gösterilmez. "İçe aktar"a dokunun.',
      'Kasanızda birebir aynısı olan kayıtlar atlanır; mevcut kayıtlarınız '
          'silinmez veya değiştirilmez. Eklenen kayıtların kategorisi '
          '"Diğer" olur.',
      'İşlem bitince orijinal CSV dosyasını MUTLAKA silin (indirilenler, '
          'paylaşılan klasörler, e-posta ekleri dahil).',
    ],
    tips: [
      'CSV dosyası şifrelerinizi düz metin olarak içerir; kimseyle '
          'paylaşmayın, buluta yüklemeyin.',
      'Dosyadaki 2 adımlı doğrulama (TOTP) anahtarları güvenlik nedeniyle '
          'aktarılmaz; bunları ayrı bir doğrulama uygulamasında tutun.',
      'Chrome, Firefox, Safari, Bitwarden, 1Password, Proton Pass ve '
          'KeePass dosyaları otomatik tanınır.',
    ],
  ),
  GuideSection(
    id: 'forgot',
    icon: Icons.help_outline,
    title: 'Ana şifremi unuttum, ne olur?',
    summary:
        'KilitDepo ana şifrenizi hiçbir yerde saklamaz ve kimseye göndermez. '
        'Bu, verilerinizi en güçlü şekilde korur; ama aynı zamanda ana '
        'şifreyi unutursanız kasadaki verilerin kurtarılamayacağı anlamına '
        'gelir. Bizim de dahil hiç kimse kasanızı açamaz.',
    steps: [
      'Önce sakin olun ve sık kullandığınız şifre kalıplarını düşünün; '
          'büyük/küçük harf ve klavye dilini kontrol edin.',
      'Biyometrik giriş açıksa kasanızı hâlâ parmak izi veya Face ID ile '
          'açabilirsiniz. Hemen Ayarlar > Yedekleme bölümünden yeni bir yedek '
          'alın (yedek, ana şifreden ayrı bir yedek şifresi kullanır).',
      'Daha önce yedek aldıysanız: uygulamanın verilerini silip yeni bir '
          'kasa oluşturun ve yedeği yedek şifresiyle geri yükleyin.',
      'Hiçbiri mümkün değilse kasayı sıfırlayıp yeniden başlamanız gerekir.',
    ],
    tips: [
      'Düzenli yedek almak, ana şifre unutulduğunda tek güvenli kurtuluş '
          'yoludur.',
      'Ana şifrenizi kâğıda yazıp güvenli bir yerde saklamak iyi bir '
          'önlemdir.',
    ],
  ),
  GuideSection(
    id: 'tips',
    icon: Icons.tips_and_updates_outlined,
    title: 'Güvenlik ipuçları',
    summary:
        'Birkaç basit alışkanlık hesaplarınızı çok daha güvenli hâle '
        'getirir.',
    tips: [
      'Her hesap için farklı bir şifre kullanın. Güvenlik raporu, tekrar '
          'kullanılan şifreleri size gösterir.',
      'Cihazınızda mutlaka bir ekran kilidi (PIN, desen veya şifre) kullanın.',
      'Zayıf şifreleri şifre üreticiyle güçlü şifrelerle değiştirin.',
      'Mümkün olan her hesapta iki adımlı doğrulamayı açın.',
      'Ana şifrenizi kimseyle paylaşmayın; KilitDepo sizden asla e-posta veya '
          'mesajla şifre istemez.',
      'Cihazınızın işletim sistemini güncel tutun.',
    ],
  ),
  GuideSection(
    id: 'faq',
    icon: Icons.quiz_outlined,
    title: 'Sıkça sorulan sorular',
    summary: 'En çok merak edilen konular.',
    faq: [
      GuideFaq(
        'Verilerim buluta veya bir sunucuya gönderiliyor mu?',
        'Hayır. KilitDepo internete bağlanmaz; uygulamanın internet izni bile '
            'yoktur. Tüm veriler yalnızca cihazınızda, şifreli olarak durur.',
      ),
      GuideFaq(
        'Telefonumu değiştirirsem kayıtlarıma nasıl ulaşırım?',
        'Eski cihazda Ayarlar > Yedekleme ile bir yedek alın, dosyayı yeni '
            'cihaza aktarın ve orada yedek şifresiyle geri yükleyin.',
      ),
      GuideFaq(
        'Ana şifremi başkası öğrenirse ne yapmalıyım?',
        'Hemen Ayarlar > Ana şifreyi değiştir bölümünden yeni bir ana şifre '
            'belirleyin. Önemli hesaplarınızın şifrelerini de değiştirmeniz '
            'önerilir.',
      ),
      GuideFaq(
        'Kopyaladığım şifre neden panodan kayboldu?',
        'Güvenlik için kopyalanan şifre belirli bir süre (varsayılan 30 '
            'saniye) sonra panodan silinir. Süreyi Ayarlar\'dan '
            'değiştirebilirsiniz.',
      ),
      GuideFaq(
        'Neden ekran görüntüsü alamıyorum?',
        'Şifrelerinizin yanlışlıkla paylaşılmasını veya başka uygulamalarca '
            'okunmasını önlemek için KilitDepo ekran görüntüsünü ve ekran '
            'kaydını engeller.',
      ),
      GuideFaq(
        'Kasa neden sürekli kilitleniyor?',
        'Uygulamadan çıktığınızda veya belirli bir süre dokunmadığınızda kasa '
            'kendini kilitler. Hareketsizlik süresini Ayarlar > Otomatik kilit '
            'bölümünden uzatabilirsiniz.',
      ),
      GuideFaq(
        'Uygulamayı silersem ne olur?',
        'Uygulamayı silmek kasanızı da kalıcı olarak siler. Silmeden önce '
            'mutlaka yedek alın.',
      ),
      GuideFaq(
        'Kullandığınız şifreleme güvenli mi?',
        'KilitDepo, yaygın olarak kabul görmüş standartları kullanır: anahtar '
            'üretimi için Argon2id, şifreleme için AES-256-GCM ve veritabanı '
            'için SQLCipher. Ayrıntılar Hakkında sayfasındadır.',
      ),
    ],
  ),
];
