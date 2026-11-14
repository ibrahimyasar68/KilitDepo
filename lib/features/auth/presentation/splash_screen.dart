import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/producer_label.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';

/// Açılış ekranı: logo + altta üretici etiketi.
/// Kasa durumu okunurken gösterilir; yönlendirmeyi router yapar.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(authControllerProvider.select((s) => s.status));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(),
                    const SizedBox(height: 32),
                    if (status == AuthStatus.error)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          l10n.commonUnexpectedError,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      )
                    else
                      Semantics(
                        label: l10n.splashLoading,
                        child: const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const ProducerLabel(),
          ],
        ),
      ),
    );
  }
}
