import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_surfaces.dart';
import '../../../../domain/entities/entry_category.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/vault_query.dart';

extension EntryCategoryUi on EntryCategory {
  String label(AppLocalizations l10n) => switch (this) {
    EntryCategory.socialMedia => l10n.categorySocialMedia,
    EntryCategory.bank => l10n.categoryBank,
    EntryCategory.email => l10n.categoryEmail,
    EntryCategory.work => l10n.categoryWork,
    EntryCategory.other => l10n.categoryOther,
  };

  IconData get icon => switch (this) {
    EntryCategory.socialMedia => Icons.people_alt_outlined,
    EntryCategory.bank => Icons.account_balance_outlined,
    EntryCategory.email => Icons.alternate_email,
    EntryCategory.work => Icons.work_outline,
    EntryCategory.other => Icons.key_outlined,
  };
}

extension EntrySortUi on EntrySort {
  String label(AppLocalizations l10n) => switch (this) {
    EntrySort.alphabetical => l10n.sortAlphabetical,
    EntrySort.recentlyAdded => l10n.sortRecentlyAdded,
    EntrySort.recentlyUpdated => l10n.sortRecentlyUpdated,
    EntrySort.category => l10n.sortCategory,
  };
}

/// Tarih + saat, cihaz diline göre (Türkçe).
String formatDateTime(BuildContext context, DateTime value) {
  final m = MaterialLocalizations.of(context);
  final local = value.toLocal();
  return '${m.formatMediumDate(local)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
}

/// Değeri güvenli panoya kopyalar ve kullanıcıyı bilgilendirir.
///
/// Bildirim, pano temizlenene kadar görünür kalır: dairesel bir geri sayım
/// kalan süreyi gösterir ve "Şimdi temizle" ile pano hemen boşaltılabilir.
Future<void> copySecret(
  BuildContext context,
  WidgetRef ref,
  String value, {
  bool isPassword = true,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final clipboard = ref.read(secureClipboardProvider);
  await clipboard.copy(value);
  // Titreşim beklenmez; bildirim hemen görünür.
  unawaited(HapticFeedback.lightImpact());
  final duration = clipboard.clearAfter;
  final seconds = duration.inSeconds;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          children: [
            ClipboardCountdownRing(duration: duration),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isPassword
                    ? l10n.copiedPassword(seconds)
                    : l10n.copiedValue(seconds),
              ),
            ),
          ],
        ),
        // Düğmeli bildirimler Flutter'da varsayılan olarak kendiliğinden
        // kapanmaz (persist); pano temizlendiğinde (süre sonunda) kapansın.
        persist: false,
        action: SnackBarAction(
          label: l10n.clipboardClearNow,
          onPressed: clipboard.clearNow,
        ),
      ),
    );
}

/// Pano temizlenene kadar boşalan dairesel geri sayım.
class ClipboardCountdownRing extends StatelessWidget {
  const ClipboardCountdownRing({super.key, required this.duration});

  final Duration duration;

  static const Key ringKey = Key('clipboard_countdown');

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.inversePrimary;
    return TweenAnimationBuilder<double>(
      key: ringKey,
      tween: Tween(begin: 1, end: 0),
      duration: duration,
      builder: (context, value, _) => SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: 3,
          color: color,
          backgroundColor: color.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

/// Ortak boş / hata durumu görünümü.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyStateIllustration(icon: icon),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Boş / hata durumları için sade vektör çizim: yumuşak renk lekeleri,
/// küçük süs noktaları ve ortada yuvarlatılmış bir kart içinde simge.
/// Kod ile çizilir (görsel dosya yok); temanın renklerini kullanır.
class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({super.key, required this.icon});

  final IconData icon;

  static const Key illustrationKey = Key('empty_illustration');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      key: illustrationKey,
      width: 168,
      height: 136,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BlobPainter(
                primary: scheme.primaryContainer,
                secondary: scheme.tertiaryContainer,
                dots: scheme.primary,
              ),
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppSurfaces.of(context).card,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppSurfaces.of(context).cardShadows(),
            ),
            child: Icon(icon, size: 38, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter({
    required this.primary,
    required this.secondary,
    required this.dots,
  });

  final Color primary;
  final Color secondary;
  final Color dots;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas
      ..drawCircle(
        Offset(w * 0.5, h * 0.52),
        h * 0.46,
        Paint()..color = primary.withValues(alpha: 0.7),
      )
      ..drawCircle(
        Offset(w * 0.78, h * 0.28),
        h * 0.17,
        Paint()..color = secondary.withValues(alpha: 0.9),
      )
      ..drawCircle(
        Offset(w * 0.2, h * 0.78),
        h * 0.1,
        Paint()..color = secondary.withValues(alpha: 0.7),
      );
    final dot = Paint()..color = dots.withValues(alpha: 0.55);
    for (final (x, y, r) in const [
      (0.12, 0.3, 3.0),
      (0.9, 0.62, 2.5),
      (0.3, 0.1, 2.0),
      (0.7, 0.9, 2.0),
    ]) {
      canvas.drawCircle(Offset(w * x, h * y), r, dot);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.primary != primary || old.secondary != secondary || old.dots != dots;
}

/// Küçük uyarı rozeti ("Zayıf", "Tekrar").
class IssueBadge extends StatelessWidget {
  const IssueBadge({
    super.key,
    required this.label,
    required this.color,
    required this.onColor,
  });

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: onColor,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
