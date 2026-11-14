import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/password_strength.dart';

/// Şifre gücü göstergesi (çubuk + metin).
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password, this.bits});

  final String password;

  /// Bilinen gerçek entropi (ör. kelime tabanlı üretici). Verilirse
  /// karakterlere dayalı tahmin yerine bu kullanılır.
  final double? bits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final known = bits;
    final strength = known == null
        ? PasswordStrengthEstimator.estimate(password)
        : PasswordStrengthEstimator.fromBits(known);

    final (label, color, value) = switch (strength) {
      PasswordStrength.veryWeak => (l10n.strengthVeryWeak, scheme.error, 0.1),
      PasswordStrength.weak => (l10n.strengthWeak, Colors.deepOrange, 0.3),
      PasswordStrength.fair => (l10n.strengthFair, Colors.amber.shade700, 0.55),
      PasswordStrength.strong => (
        l10n.strengthStrong,
        Colors.lightGreen.shade700,
        0.8,
      ),
      PasswordStrength.veryStrong => (
        l10n.strengthVeryStrong,
        Colors.green.shade700,
        1.0,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: password.isEmpty ? 0 : value,
            minHeight: 6,
            color: color,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.strengthLabel(password.isEmpty ? '—' : label),
          key: const Key('strength_label'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
