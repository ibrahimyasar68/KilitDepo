import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Kayıt rozetleri için uygulamaya gömülü simge ve renk kataloğu.
///
/// GİZLİLİK: Simgeler uygulamanın içindedir; internetten site logosu
/// indirilmez (hangi sitelerde hesabınız olduğu dışarı sızmaz). Marka
/// logoları bilinçli olarak yoktur (telif / marka hakları).
///
/// Anahtarlar veritabanında ve yedekte saklanır: DEĞİŞTİRİLMEMELİ,
/// yalnızca yenileri eklenebilir. Bilinmeyen anahtar varsayılan gibi
/// gösterilir.
class EntryIconOption {
  const EntryIconOption(this.key, this.icon, this.label);

  final String key;
  final IconData icon;
  final String Function(AppLocalizations) label;
}

class EntryColorOption {
  const EntryColorOption(
    this.key, {
    required this.light,
    required this.dark,
    required this.label,
  });

  final String key;

  /// (zemin, ön plan) — açık ve koyu tema için ayrı, okunurluk denetlendi.
  final (Color, Color) light;
  final (Color, Color) dark;
  final String Function(AppLocalizations) label;

  (Color, Color) resolve(Brightness b) => b == Brightness.dark ? dark : light;
}

abstract final class EntryAppearanceCatalog {
  static const List<EntryIconOption> icons = [
    EntryIconOption('bank', Icons.account_balance, _lBank),
    EntryIconOption('card', Icons.credit_card, _lCard),
    EntryIconOption('wallet', Icons.account_balance_wallet, _lWallet),
    EntryIconOption('cart', Icons.shopping_cart, _lCart),
    EntryIconOption('bag', Icons.shopping_bag, _lBag),
    EntryIconOption('email', Icons.mail_outline, _lEmail),
    EntryIconOption('chat', Icons.chat_bubble_outline, _lChat),
    EntryIconOption('phone', Icons.phone_android, _lPhone),
    EntryIconOption('people', Icons.people_alt_outlined, _lPeople),
    EntryIconOption('work', Icons.work_outline, _lWork),
    EntryIconOption('school', Icons.school_outlined, _lSchool),
    EntryIconOption('game', Icons.sports_esports_outlined, _lGame),
    EntryIconOption('music', Icons.music_note, _lMusic),
    EntryIconOption('video', Icons.movie_outlined, _lVideo),
    EntryIconOption('photo', Icons.photo_camera_outlined, _lPhoto),
    EntryIconOption('cloud', Icons.cloud_outlined, _lCloud),
    EntryIconOption('computer', Icons.computer, _lComputer),
    EntryIconOption('code', Icons.code, _lCode),
    EntryIconOption('wifi', Icons.wifi, _lWifi),
    EntryIconOption('home', Icons.home_outlined, _lHome),
    EntryIconOption('car', Icons.directions_car_outlined, _lCar),
    EntryIconOption('flight', Icons.flight, _lFlight),
    EntryIconOption('health', Icons.local_hospital_outlined, _lHealth),
    EntryIconOption('fitness', Icons.fitness_center, _lFitness),
    EntryIconOption('food', Icons.restaurant, _lFood),
    EntryIconOption('coffee', Icons.coffee_outlined, _lCoffee),
    EntryIconOption('id', Icons.badge_outlined, _lId),
    EntryIconOption('shield', Icons.shield_outlined, _lShield),
    EntryIconOption('key', Icons.vpn_key_outlined, _lKey),
    EntryIconOption('lock', Icons.lock_outline, _lLock),
    EntryIconOption('star', Icons.star_outline, _lStar),
    EntryIconOption('globe', Icons.public, _lGlobe),
    EntryIconOption('book', Icons.menu_book_outlined, _lBook),
    EntryIconOption('news', Icons.newspaper, _lNews),
    EntryIconOption('gift', Icons.card_giftcard, _lGift),
    EntryIconOption('stock', Icons.show_chart, _lStock),
    EntryIconOption('pet', Icons.pets, _lPet),
    EntryIconOption('tools', Icons.build_outlined, _lTools),
  ];

  static const List<EntryColorOption> colors = [
    EntryColorOption(
      'teal',
      light: (Color(0xFFE0F2EF), Color(0xFF0B5E52)),
      dark: (Color(0xFF0B4F45), Color(0xFFA8E6DA)),
      label: _cTeal,
    ),
    EntryColorOption(
      'green',
      light: (Color(0xFFE3F4E1), Color(0xFF1F6B2A)),
      dark: (Color(0xFF1C5424), Color(0xFFB4E3AE)),
      label: _cGreen,
    ),
    EntryColorOption(
      'olive',
      light: (Color(0xFFEEF1DC), Color(0xFF4F5A12)),
      dark: (Color(0xFF444D10), Color(0xFFD5DE9C)),
      label: _cOlive,
    ),
    EntryColorOption(
      'blue',
      light: (Color(0xFFE1EEFB), Color(0xFF0D4C8C)),
      dark: (Color(0xFF0C3F73), Color(0xFFB3D3F5)),
      label: _cBlue,
    ),
    EntryColorOption(
      'indigo',
      light: (Color(0xFFE6E8FA), Color(0xFF2E3A8C)),
      dark: (Color(0xFF283273), Color(0xFFC3C9F5)),
      label: _cIndigo,
    ),
    EntryColorOption(
      'purple',
      light: (Color(0xFFEFE6FA), Color(0xFF5B2C8F)),
      dark: (Color(0xFF4C2577), Color(0xFFD6C2F2)),
      label: _cPurple,
    ),
    EntryColorOption(
      'pink',
      light: (Color(0xFFFBE6F0), Color(0xFF8C1F55)),
      dark: (Color(0xFF731A47), Color(0xFFF4BCD6)),
      label: _cPink,
    ),
    EntryColorOption(
      'red',
      light: (Color(0xFFFBE4E2), Color(0xFF9A2219)),
      dark: (Color(0xFF7F1C15), Color(0xFFF5B8B1)),
      label: _cRed,
    ),
    EntryColorOption(
      'orange',
      light: (Color(0xFFFDEBDC), Color(0xFF8F4100)),
      dark: (Color(0xFF753600), Color(0xFFF8C79E)),
      label: _cOrange,
    ),
    EntryColorOption(
      'amber',
      light: (Color(0xFFFCF1D4), Color(0xFF6E4E00)),
      dark: (Color(0xFF5C4100), Color(0xFFF2D88A)),
      label: _cAmber,
    ),
    EntryColorOption(
      'brown',
      light: (Color(0xFFF1E8E2), Color(0xFF5E3C28)),
      dark: (Color(0xFF4E3222), Color(0xFFDCC5B5)),
      label: _cBrown,
    ),
    EntryColorOption(
      'slate',
      light: (Color(0xFFE7ECEF), Color(0xFF37474F)),
      dark: (Color(0xFF2E3B42), Color(0xFFC5D1D8)),
      label: _cSlate,
    ),
  ];

  static EntryIconOption? icon(String? key) =>
      key == null ? null : icons.where((o) => o.key == key).firstOrNull;

  static EntryColorOption? color(String? key) =>
      key == null ? null : colors.where((o) => o.key == key).firstOrNull;
}

String _lBank(AppLocalizations l) => l.entryIconBank;
String _lCard(AppLocalizations l) => l.entryIconCard;
String _lWallet(AppLocalizations l) => l.entryIconWallet;
String _lCart(AppLocalizations l) => l.entryIconCart;
String _lBag(AppLocalizations l) => l.entryIconBag;
String _lEmail(AppLocalizations l) => l.entryIconEmail;
String _lChat(AppLocalizations l) => l.entryIconChat;
String _lPhone(AppLocalizations l) => l.entryIconPhone;
String _lPeople(AppLocalizations l) => l.entryIconPeople;
String _lWork(AppLocalizations l) => l.entryIconWork;
String _lSchool(AppLocalizations l) => l.entryIconSchool;
String _lGame(AppLocalizations l) => l.entryIconGame;
String _lMusic(AppLocalizations l) => l.entryIconMusic;
String _lVideo(AppLocalizations l) => l.entryIconVideo;
String _lPhoto(AppLocalizations l) => l.entryIconPhoto;
String _lCloud(AppLocalizations l) => l.entryIconCloud;
String _lComputer(AppLocalizations l) => l.entryIconComputer;
String _lCode(AppLocalizations l) => l.entryIconCode;
String _lWifi(AppLocalizations l) => l.entryIconWifi;
String _lHome(AppLocalizations l) => l.entryIconHome;
String _lCar(AppLocalizations l) => l.entryIconCar;
String _lFlight(AppLocalizations l) => l.entryIconFlight;
String _lHealth(AppLocalizations l) => l.entryIconHealth;
String _lFitness(AppLocalizations l) => l.entryIconFitness;
String _lFood(AppLocalizations l) => l.entryIconFood;
String _lCoffee(AppLocalizations l) => l.entryIconCoffee;
String _lId(AppLocalizations l) => l.entryIconId;
String _lShield(AppLocalizations l) => l.entryIconShield;
String _lKey(AppLocalizations l) => l.entryIconKey;
String _lLock(AppLocalizations l) => l.entryIconLock;
String _lStar(AppLocalizations l) => l.entryIconStar;
String _lGlobe(AppLocalizations l) => l.entryIconGlobe;
String _lBook(AppLocalizations l) => l.entryIconBook;
String _lNews(AppLocalizations l) => l.entryIconNews;
String _lGift(AppLocalizations l) => l.entryIconGift;
String _lStock(AppLocalizations l) => l.entryIconStock;
String _lPet(AppLocalizations l) => l.entryIconPet;
String _lTools(AppLocalizations l) => l.entryIconTools;

String _cTeal(AppLocalizations l) => l.entryColorTeal;
String _cGreen(AppLocalizations l) => l.entryColorGreen;
String _cOlive(AppLocalizations l) => l.entryColorOlive;
String _cBlue(AppLocalizations l) => l.entryColorBlue;
String _cIndigo(AppLocalizations l) => l.entryColorIndigo;
String _cPurple(AppLocalizations l) => l.entryColorPurple;
String _cPink(AppLocalizations l) => l.entryColorPink;
String _cRed(AppLocalizations l) => l.entryColorRed;
String _cOrange(AppLocalizations l) => l.entryColorOrange;
String _cAmber(AppLocalizations l) => l.entryColorAmber;
String _cBrown(AppLocalizations l) => l.entryColorBrown;
String _cSlate(AppLocalizations l) => l.entryColorSlate;
