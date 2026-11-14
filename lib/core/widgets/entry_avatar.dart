import 'package:flutter/material.dart';

import '../../domain/entities/password_entry.dart';
import 'entry_appearance.dart';
import 'letter_avatar.dart';

/// Kaydın rozeti: kullanıcının seçtiği simge ve renk; seçilmediyse baş harf
/// ve başlıktan türetilen renk (eski görünümle birebir aynı).
class EntryAvatar extends StatelessWidget {
  const EntryAvatar({
    super.key,
    required this.title,
    this.iconKey,
    this.colorKey,
    this.size = 40,
    this.fallbackIcon,
  });

  EntryAvatar.of(
    EntrySummary entry, {
    Key? key,
    double size = 40,
    IconData? fallbackIcon,
  }) : this(
         key: key,
         title: entry.title,
         iconKey: entry.iconKey,
         colorKey: entry.colorKey,
         size: size,
         fallbackIcon: fallbackIcon,
       );

  final String title;
  final String? iconKey;
  final String? colorKey;
  final double size;

  /// Kayda simge seçilmemişse harf yerine gösterilecek açıklayıcı simge
  /// (ör. kategorinin simgesi; favoriler şeridi).
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final icon = EntryAppearanceCatalog.icon(iconKey);
    final color = EntryAppearanceCatalog.color(colorKey);
    final iconData = icon?.icon ?? fallbackIcon;
    if (iconData == null && color == null) {
      return LetterAvatar(title: title, size: size);
    }
    final brightness = Theme.of(context).brightness;
    final (bg, fg) =
        color?.resolve(brightness) ?? LetterAvatar.colorsFor(title, brightness);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: LetterAvatar.shapeOf(size),
      ),
      child: iconData != null
          ? Icon(iconData, size: size * 0.5, color: fg)
          : Text(
              LetterAvatar.initialOf(title),
              style: TextStyle(
                color: fg,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
