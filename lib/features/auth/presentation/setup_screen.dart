import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/crypto_params.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/colored_password_text.dart';
import '../../../core/widgets/brand_backdrop.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/producer_label.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../generator/application/passphrase_generator.dart';
import '../../generator/presentation/generator_panel.dart';
import '../application/auth_controller.dart';
import '../application/password_strength.dart';
import 'widgets/password_strength_meter.dart';

/// İlk açılış: adım adım ana şifre oluşturma.
///
/// 1. Ana şifre + tekrar (güç göstergesiyle)
/// 2. "Kurtarılamaz" uyarısı + onay kutusu
/// 3. Biyometrik giriş (yalnızca cihaz destekliyorsa; yoksa adım atlanır)
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  static const Key acknowledgeKey = Key('setup_acknowledge');
  static const Key createButtonKey = Key('setup_create');
  static const Key biometricSwitchKey = Key('setup_biometric');
  static const Key nextButtonKey = Key('setup_next');
  static const Key backButtonKey = Key('setup_back');
  static const Key progressKey = Key('setup_progress');
  static const Key previousVaultNoticeKey = Key('setup_previous_vault');
  static const Key tipsKey = Key('setup_tips');
  static const Key suggestKey = Key('setup_suggest');
  static const Key suggestionKey = Key('setup_suggestion');
  static const Key useSuggestionKey = Key('setup_use_suggestion');
  static const Key weakDialogKey = Key('setup_weak_dialog');
  static const Key weakContinueKey = Key('setup_weak_continue');
  static const Key storeChecklistKey = Key('setup_store_checklist');

  /// Önerilen ana şifre: 5 kelime + sayı (≈ 62 bit), her klavyede yazılır.
  static const PassphraseOptions suggestionOptions = PassphraseOptions(
    wordCount: 5,
  );

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int _step = 0;
  bool _acknowledged = false;
  bool _showAckError = false;
  bool _enableBiometric = false;
  bool _busy = false;
  String? _error;

  /// Ekranda gösterilen ana şifre önerisi (yalnızca bellekte; hiçbir yere
  /// yazılmaz). Ekran koruması (FLAG_SECURE) ekran görüntüsünü engeller.
  String? _suggestion;

  @override
  void dispose() {
    // En iyi çaba: alanları ve öneriyi boşalt.
    _suggestion = null;
    _password.clear();
    _confirm.clear();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  int _totalSteps(bool biometricAvailable) => biometricAvailable ? 3 : 2;

  bool _isLastStep(bool biometricAvailable) =>
      _step == _totalSteps(biometricAvailable) - 1;

  Future<void> _next(bool biometricAvailable) async {
    switch (_step) {
      case 0:
        if (!_passwordFormKey.currentState!.validate()) return;
        // Zayıf şifre engellenmez, uyarılır (en az uzunluk kuralı ayrıca
        // doğrulayıcıda zorunlu).
        if (!await _confirmIfWeak()) return;
      case 1:
        if (!_acknowledged) {
          setState(() => _showAckError = true);
          return;
        }
    }
    if (_isLastStep(biometricAvailable)) {
      _submit();
    } else {
      setState(() => _step++);
    }
  }

  /// Ana şifre zayıfsa uyarır; "Yine de devam et" denirse true.
  Future<bool> _confirmIfWeak() async {
    final strength = PasswordStrengthEstimator.estimate(_password.text);
    if (strength.index > PasswordStrength.weak.index) return true;
    final l10n = AppLocalizations.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: SetupScreen.weakDialogKey,
        icon: const Icon(Icons.gpp_maybe_outlined),
        title: Text(l10n.setupWeakTitle),
        content: Text(l10n.setupWeakBody),
        actions: [
          TextButton(
            key: SetupScreen.weakContinueKey,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.setupWeakContinue),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.setupWeakChange),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  void _suggest() => setState(
    () => _suggestion = ref
        .read(passphraseGeneratorProvider)
        .generate(SetupScreen.suggestionOptions),
  );

  /// Öneriyi YALNIZCA ilk alana yazar; tekrar alanını kullanıcı kendisi
  /// yazar (şifreyi en az bir kez elle yazıp okumuş olur).
  void _useSuggestion() {
    final value = _suggestion;
    if (value == null) return;
    setState(() {
      _password.text = value;
      _confirm.clear();
    });
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .createVault(_password.text, enableBiometric: _enableBiometric);
      _password.clear();
      _confirm.clear();
      if (result == CreateVaultResult.successWithoutBiometric) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.setupBiometricFailed)),
        );
      }
      // Yönlendirmeyi router yapar (durum: unlocked).
    } on Object {
      if (mounted) setState(() => _error = l10n.commonUnexpectedError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final biometricAvailable = ref.watch(
      authControllerProvider.select((s) => s.biometricAvailable),
    );
    final total = _totalSteps(biometricAvailable);
    final step = _step.clamp(0, total - 1);
    final last = step == total - 1;

    return PopScope(
      // Sistem "geri" tuşu önce önceki adıma döner.
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: BrandBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.setupStepOf(step + 1, total),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StepProgress(
                        key: SetupScreen.progressKey,
                        current: step,
                        total: total,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  // Kaydırılan içerik ilerleme çubuğunun altında keskin
                  // kesilmesin: üst ve alt kenarda yumuşak solma.
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0, 0.04, 0.96, 1],
                    ).createShader(rect),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(step),
                          child: switch (step) {
                            0 => _buildPasswordStep(l10n, theme),
                            1 => _buildWarningStep(l10n, theme),
                            _ => _buildBiometricStep(l10n, theme),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      if (step > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            key: SetupScreen.backButtonKey,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            onPressed: _busy ? null : _back,
                            child: Text(l10n.setupBack),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          key: last
                              ? SetupScreen.createButtonKey
                              : SetupScreen.nextButtonKey,
                          onPressed: _busy
                              ? null
                              : () => _next(biometricAvailable),
                          child: _busy
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  last
                                      ? l10n.setupCreateButton
                                      : l10n.setupNext,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_busy)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.setupCreating,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const ProducerLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(
    ThemeData theme,
    IconData icon,
    String title,
    String? body,
  ) => Column(
    children: [
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          icon,
          size: 36,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        style: theme.textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      if (body != null) ...[
        const SizedBox(height: 8),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
      const SizedBox(height: 24),
    ],
  );

  Widget _buildPasswordStep(AppLocalizations l10n, ThemeData theme) => Form(
    key: _passwordFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AppLogo(size: 64, showName: false)),
        const SizedBox(height: 16),
        Text(
          l10n.setupStepPasswordTitle,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.setupSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (ref.watch(
          authControllerProvider.select((s) => s.previousVaultMissing),
        )) ...[
          const SizedBox(height: 16),
          Card(
            key: SetupScreen.previousVaultNoticeKey,
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.setupPreviousVaultMissing,
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        PasswordField(
          key: const Key('setup_password'),
          controller: _password,
          label: l10n.setupPasswordLabel,
          enabled: !_busy,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.setupPasswordRequired;
            }
            if (value.length < CryptoParams.minMasterPasswordLength) {
              return l10n.setupPasswordTooShort(
                CryptoParams.minMasterPasswordLength,
              );
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        PasswordStrengthMeter(password: _password.text),
        const SizedBox(height: 12),
        _tipsCard(l10n, theme),
        const SizedBox(height: 16),
        PasswordField(
          key: const Key('setup_confirm'),
          controller: _confirm,
          label: l10n.setupConfirmLabel,
          enabled: !_busy,
          textInputAction: TextInputAction.done,
          validator: (value) =>
              value != _password.text ? l10n.setupPasswordMismatch : null,
        ),
      ],
    ),
  );

  /// "İyi bir ana şifre nasıl seçilir?" ipuçları + kelime önerisi.
  Widget _tipsCard(AppLocalizations l10n, ThemeData theme) {
    final scheme = theme.colorScheme;
    final suggestion = _suggestion;
    return Card(
      key: SetupScreen.tipsKey,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(Icons.tips_and_updates_outlined, color: scheme.primary),
        title: Text(l10n.setupTipsTitle, style: theme.textTheme.titleSmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final tip in [
            l10n.setupTipWords,
            l10n.setupTipUnique,
            l10n.setupTipPersonal,
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tip, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (suggestion == null)
            OutlinedButton.icon(
              key: SetupScreen.suggestKey,
              onPressed: _busy ? null : _suggest,
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.setupSuggest),
            )
          else ...[
            Container(
              key: SetupScreen.suggestionKey,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ColoredPasswordText(suggestion, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _suggest,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      l10n.setupSuggestionAnother,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: SetupScreen.useSuggestionKey,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: _busy ? null : _useSuggestion,
                    icon: const Icon(Icons.check),
                    label: Text(
                      l10n.setupSuggestionUse,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.setupSuggestionHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningStep(AppLocalizations l10n, ThemeData theme) {
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          theme,
          Icons.warning_amber_rounded,
          l10n.setupStepWarningTitle,
          null,
        ),
        Card(
          color: scheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.setupWarningBody,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.setupStepWarningBody,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Somut saklama listesi.
        Card(
          key: SetupScreen.storeChecklistKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.setupStoreTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                for (final (icon, text, good) in [
                  (Icons.edit_note, l10n.setupStorePaper, true),
                  (
                    Icons.no_photography_outlined,
                    l10n.setupStoreNoPhone,
                    false,
                  ),
                  (Icons.backup_outlined, l10n.setupStoreBackup, true),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          icon,
                          size: 22,
                          color: good ? scheme.primary : scheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(text, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          key: SetupScreen.acknowledgeKey,
          value: _acknowledged,
          onChanged: _busy
              ? null
              : (v) => setState(() {
                  _acknowledged = v ?? false;
                  if (_acknowledged) _showAckError = false;
                }),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.setupAcknowledge, style: theme.textTheme.bodyMedium),
          subtitle: _showAckError
              ? Text(
                  l10n.setupAcknowledgeRequired,
                  style: TextStyle(color: scheme.error),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildBiometricStep(AppLocalizations l10n, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _stepHeader(
        theme,
        Icons.fingerprint,
        l10n.setupStepBiometricTitle,
        l10n.setupStepBiometricBody,
      ),
      Card(
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          key: SetupScreen.biometricSwitchKey,
          value: _enableBiometric,
          onChanged: _busy ? null : (v) => setState(() => _enableBiometric = v),
          secondary: const Icon(Icons.fingerprint),
          title: Text(l10n.setupEnableBiometric),
          subtitle: Text(l10n.setupEnableBiometricHint),
        ),
      ),
    ],
  );
}

/// Bölümlü ilerleme göstergesi.
class _StepProgress extends StatelessWidget {
  const _StepProgress({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              decoration: BoxDecoration(
                color: i <= current
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
