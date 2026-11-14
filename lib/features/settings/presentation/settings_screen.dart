import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/security_params.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/producer_label.dart';
import '../../../data/repositories/app_settings_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/widgets/lockout_banner.dart';
import '../../vault/presentation/widgets/vault_ui.dart';

/// Uygulama sürümü (package_info_plus). Testlerde geçersiz kılınır.
final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

String formatDuration(AppLocalizations l10n, Duration d) =>
    d.inSeconds < 60 || d.inSeconds % 60 != 0
    ? l10n.durationSeconds(d.inSeconds)
    : l10n.durationMinutes(d.inMinutes);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Key biometricKey = Key('settings_biometric');
  static const Key autoLockKey = Key('settings_auto_lock');
  static const Key clipboardKey = Key('settings_clipboard');
  static const Key themeKey = Key('settings_theme');
  static const Key dynamicColorKey = Key('settings_dynamic_color');
  static const Key trueBlackKey = Key('settings_true_black');
  static const Key changePasswordKey = Key('settings_change_password');
  static const Key backupKey = Key('settings_backup');
  static const Key csvImportKey = Key('settings_csv_import');
  static const Key aboutKey = Key('settings_about');
  static const Key guideKey = Key('settings_guide');
  static const Key versionKey = Key('settings_version');

  Future<T?> _choose<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) label,
  }) => showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        RadioGroup<T>(
          groupValue: current,
          onChanged: (v) => Navigator.pop(context, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final o in options)
                RadioListTile<T>(
                  key: Key('option_${label(o)}'),
                  value: o,
                  title: Text(label(o)),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref, {
    required bool enable,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(authControllerProvider.notifier);
    if (!enable) {
      await controller.disableBiometric();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsBiometricDisabled)),
      );
      return;
    }
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _ConfirmPasswordDialog(),
    );
    if (password == null || password.isEmpty) return;
    final result = await controller.enableBiometric(password);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          BiometricChangeResult.success => l10n.settingsBiometricEnabled,
          BiometricChangeResult.wrongPassword => l10n.loginWrongPassword,
          BiometricChangeResult.lockedOut => l10n.loginLockedOut(
            LockoutBanner.format(
              (ref.read(authControllerProvider).lockoutUntil ?? DateTime.now())
                  .difference(DateTime.now()),
            ),
          ),
          BiometricChangeResult.unavailable =>
            l10n.settingsBiometricUnavailable,
          BiometricChangeResult.failed => l10n.settingsBiometricFailed,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final settings = ref.read(appSettingsProvider);
    final autoLock =
        ref.watch(autoLockTimeoutProvider).value ??
        SecurityParams.defaultAutoLockTimeout;
    final clipboard =
        ref.watch(clipboardClearDelayProvider).value ??
        SecurityParams.clipboardClearDelay;
    final theme = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final lastBackup = ref.watch(lastBackupAtProvider).value;
    final version = ref.watch(appVersionProvider).value;

    String themeLabel(ThemeMode m) => switch (m) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _SettingsGroup(
            title: l10n.settingsSecurity,
            children: [
              SwitchListTile(
                key: biometricKey,
                secondary: _IconBox(
                  icon: Icons.fingerprint,
                  color: scheme.primary,
                ),
                title: Text(l10n.settingsBiometric),
                subtitle: Text(
                  !auth.biometricAvailable
                      ? l10n.settingsBiometricUnavailable
                      : auth.biometricEnabled
                      ? l10n.settingsBiometricOn
                      : l10n.settingsBiometricOff,
                ),
                value: auth.biometricEnabled,
                onChanged: auth.biometricAvailable || auth.biometricEnabled
                    ? (v) => _toggleBiometric(context, ref, enable: v)
                    : null,
              ),
              ListTile(
                key: autoLockKey,
                leading: _IconBox(
                  icon: Icons.timer_outlined,
                  color: scheme.primary,
                ),
                title: Text(l10n.settingsAutoLock),
                subtitle: Text(
                  l10n.settingsAutoLockSubtitle(formatDuration(l10n, autoLock)),
                ),
                onTap: () async {
                  final picked = await _choose(
                    context,
                    title: l10n.settingsAutoLock,
                    options: AppSettingsRepository.autoLockOptions,
                    current: autoLock,
                    label: (d) => formatDuration(l10n, d),
                  );
                  if (picked == null) return;
                  await settings.setAutoLockTimeout(picked);
                  ref.invalidate(autoLockTimeoutProvider);
                },
              ),
              ListTile(
                key: clipboardKey,
                leading: _IconBox(
                  icon: Icons.content_paste_off,
                  color: scheme.primary,
                ),
                title: Text(l10n.settingsClipboard),
                subtitle: Text(
                  l10n.settingsClipboardSubtitle(
                    formatDuration(l10n, clipboard),
                  ),
                ),
                onTap: () async {
                  final picked = await _choose(
                    context,
                    title: l10n.settingsClipboard,
                    options: AppSettingsRepository.clipboardOptions,
                    current: clipboard,
                    label: (d) => formatDuration(l10n, d),
                  );
                  if (picked == null) return;
                  await settings.setClipboardClearDelay(picked);
                  ref.invalidate(clipboardClearDelayProvider);
                },
              ),
              ListTile(
                key: changePasswordKey,
                leading: _IconBox(icon: Icons.key, color: scheme.primary),
                title: Text(l10n.changePasswordTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.changePassword),
              ),
            ],
          ),
          _SettingsGroup(
            title: l10n.settingsAppearance,
            children: [
              // Tema: açılır pencere yerine satır içinde üç parçalı seçim.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _IconBox(
                          icon: Icons.palette_outlined,
                          color: scheme.tertiary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          l10n.settingsTheme,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      key: themeKey,
                      showSelectedIcon: false,
                      segments: [
                        for (final (mode, icon) in const [
                          (ThemeMode.system, Icons.brightness_auto_outlined),
                          (ThemeMode.light, Icons.light_mode_outlined),
                          (ThemeMode.dark, Icons.dark_mode_outlined),
                        ])
                          ButtonSegment(
                            value: mode,
                            icon: Icon(icon),
                            label: Text(
                              themeLabel(mode),
                              key: Key('theme_${mode.name}'),
                            ),
                          ),
                      ],
                      selected: {theme},
                      onSelectionChanged: (picked) async {
                        await settings.setThemeMode(picked.first);
                        ref.invalidate(themeModeProvider);
                      },
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                key: trueBlackKey,
                secondary: _IconBox(
                  icon: Icons.contrast,
                  color: scheme.tertiary,
                ),
                title: Text(l10n.settingsTrueBlack),
                subtitle: Text(l10n.settingsTrueBlackSubtitle),
                value: ref.watch(trueBlackProvider).value ?? false,
                onChanged: (v) async {
                  await settings.setTrueBlack(v);
                  ref.invalidate(trueBlackProvider);
                },
              ),
              // Material You: yalnızca destekleyen cihazlarda (Android 12+).
              if (ref.watch(dynamicColorSupportedProvider).value ?? false)
                SwitchListTile(
                  key: dynamicColorKey,
                  secondary: _IconBox(
                    icon: Icons.wallpaper_outlined,
                    color: scheme.tertiary,
                  ),
                  title: Text(l10n.settingsDynamicColor),
                  subtitle: Text(l10n.settingsDynamicColorSubtitle),
                  value: ref.watch(dynamicColorEnabledProvider).value ?? false,
                  onChanged: (v) async {
                    await settings.setDynamicColor(v);
                    ref.invalidate(dynamicColorEnabledProvider);
                  },
                ),
            ],
          ),
          _SettingsGroup(
            title: l10n.settingsData,
            children: [
              ListTile(
                key: backupKey,
                leading: _IconBox(
                  icon: Icons.backup_outlined,
                  color: scheme.secondary,
                ),
                title: Text(l10n.backupTitle),
                subtitle: Text(
                  lastBackup == null
                      ? l10n.settingsLastBackupNever
                      : l10n.settingsLastBackup(
                          formatDateTime(context, lastBackup),
                        ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.backup),
              ),
              ListTile(
                key: csvImportKey,
                leading: _IconBox(
                  icon: Icons.file_upload_outlined,
                  color: scheme.secondary,
                ),
                title: Text(l10n.csvImportTitle),
                subtitle: Text(l10n.csvImportSettingsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.csvImport),
              ),
            ],
          ),
          _SettingsGroup(
            title: l10n.settingsInfo,
            children: [
              ListTile(
                key: aboutKey,
                leading: _IconBox(
                  icon: Icons.info_outline,
                  color: scheme.outline,
                ),
                title: Text(l10n.aboutTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.about),
              ),
              ListTile(
                key: guideKey,
                leading: _IconBox(
                  icon: Icons.menu_book_outlined,
                  color: scheme.outline,
                ),
                title: Text(l10n.guideTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.guide),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ProducerLabel(
            key: versionKey,
            text: version == null
                ? AppInfo.producerLabel
                : AppInfo.versionLine(version),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ConfirmPasswordDialog extends StatefulWidget {
  const _ConfirmPasswordDialog();

  @override
  State<_ConfirmPasswordDialog> createState() => _ConfirmPasswordDialogState();
}

class _ConfirmPasswordDialogState extends State<_ConfirmPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.clear();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.settingsBiometricConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsBiometricConfirmBody),
          const SizedBox(height: 16),
          PasswordField(
            key: const Key('biometric_confirm_password'),
            controller: _controller,
            label: l10n.loginPasswordLabel,
            autofocus: true,
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          key: const Key('biometric_confirm_ok'),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.settingsConfirm),
        ),
      ],
    );
  }
}

/// Ayarlar bölümü: başlık + "bölümlü liste" (Material 3 Expressive).
///
/// Her satır kendi kartında, aralarında küçük boşluk; grubun dış köşeleri
/// büyük, iç köşeleri küçük. Ayırıcı çizgi yok.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  static const double outer = AppTheme.radius;
  static const double inner = 6;
  static const double gap = 3;

  /// [index]. satırın köşeleri (ilk: üst büyük, son: alt büyük).
  static BorderRadius radiusFor(int index, int count) {
    final top = index == 0 ? outer : inner;
    final bottom = index == count - 1 ? outer : inner;
    return BorderRadius.vertical(
      top: Radius.circular(top),
      bottom: Radius.circular(bottom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final side =
        (theme.cardTheme.shape as RoundedRectangleBorder?)?.side ??
        BorderSide.none;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: gap),
          Card(
            key: Key('settings_segment_${title}_$i'),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: radiusFor(i, children.length),
              side: side,
            ),
            child: children[i],
          ),
        ],
      ],
    );
  }
}

/// Satır başındaki renkli, yuvarlatılmış simge kutusu.
class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 20, color: color),
  );
}
