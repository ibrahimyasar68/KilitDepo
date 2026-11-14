import 'package:flutter/material.dart';

import '../constants/app_info.dart';

/// Üretici etiketi ("İY Labs").
///
/// Küçük, sade ve ikincil renkte; içerikle yarışmaz.
class ProducerLabel extends StatelessWidget {
  const ProducerLabel({super.key, this.text});

  /// Varsayılan etiket yerine gösterilecek metin
  /// (ör. Ayarlar'daki sürüm satırı).
  final String? text;

  static const Key labelKey = Key('producer_label');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text ?? AppInfo.producerLabel,
        key: labelKey,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
