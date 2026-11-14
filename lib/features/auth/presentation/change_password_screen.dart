import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/crypto_params.dart';
import '../../../core/widgets/password_field.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';
import 'widgets/lockout_banner.dart';
import 'widgets/password_strength_meter.dart';

/// Ana şifre değiştirme. (Faz 5'te Ayarlar ekranından açılacak.)
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  static const Key currentKey = Key('change_current');
  static const Key newKey = Key('change_new');
  static const Key confirmKey = Key('change_confirm');
  static const Key submitKey = Key('change_submit');

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _currentError;
  String? _error;

  @override
  void dispose() {
    for (final c in [_current, _new, _confirm]) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _currentError = null;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .changeMasterPassword(
          currentPassword: _current.text,
          newPassword: _new.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case ChangePasswordResult.success:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.changePasswordSuccess)),
        );
        context.pop();
      case ChangePasswordResult.wrongCurrentPassword:
        _current.clear();
        setState(() => _currentError = l10n.changePasswordWrongCurrent);
      case ChangePasswordResult.lockedOut:
        break; // Geri sayım uyarısı gösterilir.
      case ChangePasswordResult.error:
        setState(() => _error = l10n.commonUnexpectedError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lockoutUntil = ref.watch(
      authControllerProvider.select((s) => s.lockoutUntil),
    );
    final lockedOut =
        lockoutUntil != null && lockoutUntil.isAfter(DateTime.now());
    final enabled = !_busy && !lockedOut;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePasswordTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.changePasswordInfo,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (lockedOut) ...[
              LockoutBanner(
                until: lockoutUntil,
                onFinished: () => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],
            PasswordField(
              key: ChangePasswordScreen.currentKey,
              controller: _current,
              label: l10n.changePasswordCurrent,
              enabled: enabled,
              errorText: _currentError,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.setupPasswordRequired : null,
            ),
            const SizedBox(height: 16),
            PasswordField(
              key: ChangePasswordScreen.newKey,
              controller: _new,
              label: l10n.changePasswordNew,
              enabled: enabled,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.setupPasswordRequired;
                if (v.length < CryptoParams.minMasterPasswordLength) {
                  return l10n.setupPasswordTooShort(
                    CryptoParams.minMasterPasswordLength,
                  );
                }
                if (v == _current.text) return l10n.changePasswordSameAsOld;
                return null;
              },
            ),
            const SizedBox(height: 8),
            PasswordStrengthMeter(password: _new.text),
            const SizedBox(height: 16),
            PasswordField(
              key: ChangePasswordScreen.confirmKey,
              controller: _confirm,
              label: l10n.changePasswordConfirm,
              enabled: enabled,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  v != _new.text ? l10n.setupPasswordMismatch : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: ChangePasswordScreen.submitKey,
              onPressed: enabled ? _submit : null,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.changePasswordButton),
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              Text(
                l10n.changePasswordWorking,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
