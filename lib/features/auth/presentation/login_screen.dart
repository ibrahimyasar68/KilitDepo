import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/brand_backdrop.dart';
import '../../../core/widgets/producer_label.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';
import 'widgets/lockout_banner.dart';
import '../../../core/widgets/password_field.dart';

/// Giriş ekranı: ana şifre veya biyometrik açma.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const Key passwordKey = Key('login_password');
  static const Key unlockButtonKey = Key('login_unlock');
  static const Key biometricButtonKey = Key('login_biometric');
  static const Key aboutButtonKey = Key('login_about');
  static const Key guideButtonKey = Key('login_guide');

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  /// Ana şifreyle açma sürüyor.
  bool _busy = false;

  /// Biyometrik istem açık / sonucu bekleniyor. Ana şifre alanını
  /// KİLİTLEMEZ: kullanıcı her zaman ana şifreye dönebilmeli.
  bool _biometricPending = false;

  /// Her biyometrik denemenin kimliği (geç gelen sonuçları ayırt etmek için).
  int _biometricAttempt = 0;

  String? _error;
  bool _autoPrompted = false;

  late final AppLifecycleListener _lifecycle;
  Timer? _biometricWatchdog;

  /// Biyometrik pencere kapanıp uygulama öne döndükten sonra sonucun
  /// gelmesi için tanınan süre.
  static const Duration biometricGrace = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    // Biyometrik pencere açılınca uygulama "pasif" olur, kapanınca yeniden
    // "devam" eder. Android'de pencerenin "İptal" düğmesi (flutter_secure_storage
    // eklentisindeki bir hata yüzünden) HİÇBİR sonuç döndürmez; bu yüzden
    // uygulama öne döndükten kısa süre sonra hâlâ sonuç yoksa deneme iptal
    // sayılır ve ana şifre alanına dönülür.
    _lifecycle = AppLifecycleListener(
      onInactive: _onInactive,
      onResume: _onResume,
    );
    // Biyometri açıksa ekran açılır açılmaz bir kez sor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoPrompted) return;
      _autoPrompted = true;
      if (ref.read(authControllerProvider).biometricEnabled) {
        _unlockWithBiometric();
      }
    });
  }

  @override
  void dispose() {
    _biometricWatchdog?.cancel();
    _lifecycle.dispose();
    _passwordFocus.dispose();
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  /// Biyometrik pencere açıldı (uygulama pasif): bekleyen sayaç iptal.
  bool _promptSeen = false;

  void _onInactive() {
    if (!_biometricPending) return;
    _promptSeen = true;
    _biometricWatchdog?.cancel();
  }

  void _onResume() {
    // Yalnızca istem gerçekten görüldükten sonra öne dönüldüyse.
    if (!_biometricPending || !_promptSeen) return;
    final attempt = _biometricAttempt;
    _biometricWatchdog?.cancel();
    _biometricWatchdog = Timer(biometricGrace, () {
      if (mounted && _biometricPending && attempt == _biometricAttempt) {
        // "İptal" düğmesi sonuç döndürmedi: vazgeçme sayılır.
        _biometricFailed(showError: false);
      }
    });
  }

  /// Biyometri bitti ama açılmadı: ana şifre alanına dön. Kullanıcı
  /// kendisi vazgeçtiyse ([showError] false) uyarı GÖSTERİLMEZ; uyarı yalnızca
  /// gerçek bir hata / başarısızlıkta çıkar.
  void _biometricFailed({required bool showError}) {
    final l10n = AppLocalizations.of(context);
    _biometricWatchdog?.cancel();
    setState(() {
      _biometricPending = false;
      _error = showError ? l10n.loginBiometricFailed : null;
    });
    _passwordFocus.requestFocus();
  }

  Future<void> _unlockWithPassword() async {
    if (_busy || _password.text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(authControllerProvider.notifier)
        .unlockWithPassword(_password.text);
    if (!mounted) return;
    _password.clear();
    setState(() {
      _busy = false;
      _error = switch (result) {
        UnlockResult.success => null,
        UnlockResult.wrongPassword => l10n.loginWrongPassword,
        // Geri sayım ayrı bir uyarıda gösterilir.
        UnlockResult.lockedOut => null,
        UnlockResult.corrupted => l10n.loginCorrupted,
        UnlockResult.cancelled ||
        UnlockResult.error => l10n.commonUnexpectedError,
      };
    });
  }

  Future<void> _unlockWithBiometric() async {
    if (_busy || _biometricPending) return;
    final attempt = ++_biometricAttempt;
    _promptSeen = false;
    setState(() {
      _biometricPending = true;
      _error = null;
    });
    final result = await ref
        .read(authControllerProvider.notifier)
        .unlockWithBiometric();
    // Başarılıysa yönlendirme kendiliğinden olur (geç gelse bile).
    if (!mounted || result == UnlockResult.success) return;
    // Bu deneme zaten iptal sayıldıysa (ya da yenisi başladıysa) yok say.
    if (attempt != _biometricAttempt || !_biometricPending) return;
    _biometricFailed(showError: result != UnlockResult.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final biometricEnabled = ref.watch(
      authControllerProvider.select((s) => s.biometricEnabled),
    );
    final lockoutUntil = ref.watch(
      authControllerProvider.select((s) => s.lockoutUntil),
    );
    final lockedOut =
        lockoutUntil != null && lockoutUntil.isAfter(DateTime.now());

    final passwordSection = <Widget>[
      if (lockedOut) ...[
        LockoutBanner(until: lockoutUntil, onFinished: () => setState(() {})),
        const SizedBox(height: 16),
      ],
      PasswordField(
        key: LoginScreen.passwordKey,
        controller: _password,
        label: l10n.loginPasswordLabel,
        enabled: !_busy && !lockedOut,
        focusNode: _passwordFocus,
        errorText: _error,
        // Biyometri kapalıysa klavye hemen açılır (bir dokunuş eksik).
        autofocus: !biometricEnabled,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _unlockWithPassword(),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: LoginScreen.unlockButtonKey,
        onPressed: (_busy || lockedOut) ? null : _unlockWithPassword,
        child: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.loginUnlockButton),
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            key: LoginScreen.aboutButtonKey,
            tooltip: l10n.loginAbout,
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push(AppRoutes.about),
          ),
        ],
      ),
      body: BrandBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      const Center(child: AppLogo(size: 80)),
                      const SizedBox(height: 28),
                      Text(
                        l10n.loginTitle,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (biometricEnabled) ...[
                        // Biyometri açıksa ana eylem odur: büyük, dolu düğme.
                        Center(
                          child: IconButton.filled(
                            key: LoginScreen.biometricButtonKey,
                            tooltip: l10n.loginBiometricButton,
                            iconSize: 40,
                            padding: const EdgeInsets.all(20),
                            onPressed: _busy || _biometricPending
                                ? null
                                : _unlockWithBiometric,
                            icon: const Icon(Icons.fingerprint),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.loginBiometricButton,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                l10n.loginOrPassword,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      ...passwordSection,
                      const SizedBox(height: 16),
                      TextButton.icon(
                        key: LoginScreen.guideButtonKey,
                        onPressed: () => context.push(AppRoutes.guide),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(l10n.loginGuide),
                      ),
                    ],
                  ),
                ),
              ),
              const ProducerLabel(),
            ],
          ),
        ),
      ),
    );
  }
}
