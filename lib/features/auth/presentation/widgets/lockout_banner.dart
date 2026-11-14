import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Hatalı denemeler sonrası bekleme süresini geri sayımla gösterir.
class LockoutBanner extends StatefulWidget {
  const LockoutBanner({
    super.key,
    required this.until,
    required this.onFinished,
  });

  final DateTime until;
  final VoidCallback onFinished;

  static const Key bannerKey = Key('lockout_banner');

  /// "mm:ss" veya "s:mm:ss" biçiminde kalan süre.
  static String format(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  State<LockoutBanner> createState() => _LockoutBannerState();
}

class _LockoutBannerState extends State<LockoutBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!widget.until.isAfter(DateTime.now())) {
        _timer?.cancel();
        widget.onFinished();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final remaining = widget.until.difference(DateTime.now());
    return Card(
      key: LockoutBanner.bannerKey,
      elevation: 0,
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.loginLockedOut(LockoutBanner.format(remaining)),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
