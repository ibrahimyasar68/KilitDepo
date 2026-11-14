import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/depth_card.dart';
import '../../../core/widgets/entry_avatar.dart';
import '../../../domain/entities/password_entry.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/security_report.dart';
import '../application/vault_providers.dart';
import 'widgets/vault_ui.dart';

/// Güvenlik raporu: puan halkası, özet kartları ve sorunlu kayıtlar.
/// Hiçbir şifre gösterilmez; yalnızca kayıt adları listelenir.
class SecurityReportScreen extends ConsumerWidget {
  const SecurityReportScreen({super.key});

  static const Key scoreKey = Key('report_score');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final report = ref.watch(securityReportProvider);
    final entries = {
      for (final e in ref.watch(entriesProvider).value ?? <EntrySummary>[])
        e.id: e,
    };

    // Boş / hata durumları alt çubuğun (buzlu cam, içeriğin üstünde)
    // arkasında kalmasın.
    Widget fill(Widget child) => SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: child,
      ),
    );

    final List<Widget> content = report.when(
      loading: () => [fill(const Center(child: CircularProgressIndicator()))],
      error: (_, _) => [
        fill(
          StatusView(
            icon: Icons.error_outline,
            title: l10n.commonUnexpectedError,
          ),
        ),
      ],
      data: (r) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        Widget tile(int id, String reason, Color reasonColor) {
          final e = entries[id];
          if (e == null) return const SizedBox.shrink();
          return ListTile(
            key: Key('report_entry_${id}_${reason.hashCode}'),
            leading: EntryAvatar.of(e),
            title: Text(e.title),
            subtitle: Text(reason, style: TextStyle(color: reasonColor)),
            // Sorunu çözmenin en kısa yolu: doğrudan düzenleme ekranı.
            trailing: FilledButton.tonal(
              // Aynı kayıt hem zayıf hem tekrar listesinde olabilir: anahtar
              // gerekçeyi de içerir.
              key: Key('report_change_${id}_${reason.hashCode}'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
              onPressed: () => context.push(AppRoutes.entryEdit(id)),
              child: Text(l10n.reportChangePassword),
            ),
            onTap: () => context.push(AppRoutes.entryDetail(id)),
          );
        }

        String reusedWith(int id, List<int> group) {
          final other = group.firstWhere((x) => x != id, orElse: () => id);
          return l10n.reportReusedWith(entries[other]?.title ?? '');
        }

        return [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.list(
              children: [
                _ScoreRing(key: scoreKey, score: r.score),
                const SizedBox(height: 8),
                Text(
                  _scoreLabel(l10n, r.score),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _CountCard(
                        key: const Key('report_weak'),
                        count: r.weakIds.length,
                        label: l10n.reportWeakCount,
                        color: scheme.errorContainer,
                        onColor: scheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CountCard(
                        key: const Key('report_reused'),
                        count: r.reusedGroups.fold(0, (n, g) => n + g.length),
                        label: l10n.reportReusedCount,
                        color: scheme.tertiaryContainer,
                        onColor: scheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (r.isClean)
                  StatusView(
                    icon: Icons.verified_user_outlined,
                    title: l10n.reportAllGood,
                    body: l10n.reportAllGoodBody,
                  )
                else ...[
                  if (r.weakIds.isNotEmpty) ...[
                    _SectionTitle(
                      title: l10n.reportWeakTitle,
                      body: l10n.reportWeakBody,
                    ),
                    for (final id in r.weakIds)
                      tile(id, l10n.strengthWeak, scheme.error),
                  ],
                  if (r.reusedGroups.isNotEmpty) ...[
                    _SectionTitle(
                      title: l10n.reportReusedTitle,
                      body: l10n.reportReusedBody,
                    ),
                    for (final group in r.reusedGroups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Text(
                          l10n.reportReusedGroup(group.length),
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      for (final id in group)
                        tile(id, reusedWith(id, group), scheme.tertiary),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ];
      },
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Kaydırınca küçülen büyük başlık.
          SliverAppBar.large(title: Text(l10n.reportTitle)),
          ...content,
        ],
      ),
    );
  }

  static String _scoreLabel(AppLocalizations l10n, int score) {
    if (score >= 90) return l10n.reportScoreExcellent;
    if (score >= 70) return l10n.reportScoreGood;
    if (score >= 40) return l10n.reportScoreFair;
    return l10n.reportScorePoor;
  }
}

/// Puan halkası: renk geçişli yay, dolma animasyonu ve sayarak artan puan.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = score >= 70
        ? scheme.primary
        : score >= 40
        ? scheme.tertiary
        : scheme.error;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 900);
    return Center(
      child: Semantics(
        label: '${l10n.reportScore}: $score / 100',
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: 176,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              painter: _RingPainter(
                progress: value,
                start: Color.lerp(color, scheme.surface, 0.45)!,
                end: color,
                track: scheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(value * 100).round()}',
                      style: theme.textTheme.displaySmall,
                    ),
                    Text(
                      '/ 100',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.start,
    required this.end,
    required this.track,
  });

  final double progress;
  final Color start;
  final Color end;
  final Color track;

  static const double stroke = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress;
    // Yayın arkasında aynı renkte bulanık parıltı.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = end.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Yay üstten başlar; renk geçişi yay boyunca açıktan koyuya.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: sweep,
          colors: [start, end],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.start != start ||
      old.end != end ||
      old.track != track;
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    super.key,
    required this.count,
    required this.label,
    required this.color,
    required this.onColor,
  });

  final int count;
  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sorun varsa özet kartı kendi renginde hafifçe parlar.
    return DepthCard(
      color: color,
      glow: count > 0 ? color : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: theme.textTheme.headlineMedium?.copyWith(color: onColor),
            ),
            Text(label, style: TextStyle(color: onColor)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
