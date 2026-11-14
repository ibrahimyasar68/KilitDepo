import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/motion.dart';
import '../../../core/widgets/colored_password_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/widgets/password_strength_meter.dart';
import '../application/passphrase_generator.dart';
import '../application/password_generator.dart';

final passwordGeneratorProvider = Provider<PasswordGenerator>(
  (ref) => PasswordGenerator(),
);

final passphraseGeneratorProvider = Provider<PassphraseGenerator>(
  (ref) => PassphraseGenerator(),
);

/// Üretici kipi: rastgele karakterler veya kelimeler.
enum GeneratorMode { random, words }

/// Seçenekler + üretilen şifre. Hem tam ekran üreticide hem de kayıt
/// formundaki alt panelde kullanılır.
class GeneratorPanel extends ConsumerStatefulWidget {
  const GeneratorPanel({super.key, required this.actions});

  /// Üretilen şifreyle çalışan butonlar (Kopyala / Kullan).
  final Widget Function(BuildContext context, String password) actions;

  static const Key passwordKey = Key('gen_password');

  static const Key regenerateKey = Key('gen_regenerate');
  static const Key modeKey = Key('gen_mode');
  static const Key lengthKey = Key('gen_length');
  static const Key upperKey = Key('gen_upper');
  static const Key lowerKey = Key('gen_lower');
  static const Key digitsKey = Key('gen_digits');
  static const Key symbolsKey = Key('gen_symbols');
  static const Key ambiguousKey = Key('gen_ambiguous');
  static const Key wordCountKey = Key('gen_word_count');
  static const Key capitalizeKey = Key('gen_capitalize');
  static const Key numberKey = Key('gen_number');
  static const Key entropyKey = Key('gen_entropy');

  static Key separatorKey(String s) => Key('gen_sep_$s');

  @override
  ConsumerState<GeneratorPanel> createState() => _GeneratorPanelState();
}

class _GeneratorPanelState extends ConsumerState<GeneratorPanel> {
  GeneratorMode _mode = GeneratorMode.random;
  GeneratorOptions _options = const GeneratorOptions();
  PassphraseOptions _words = const PassphraseOptions();
  late String _password;

  /// Kullanıcı kayıtlı seçenekler yüklenmeden bir şey değiştirdiyse
  /// yüklenen değerler onun seçiminin üzerine yazılmaz.
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _password = _generate();
    unawaited(_restore());
  }

  /// Son kullanılan kip ve seçenekleri geri yükler. Üretilen şifre hiçbir
  /// zaman saklanmaz.
  Future<void> _restore() async {
    final settings = ref.read(appSettingsProvider);
    GeneratorMode? mode;
    GeneratorOptions? options;
    PassphraseOptions? words;
    try {
      final rawMode = await settings.generatorMode();
      mode = GeneratorMode.values.where((m) => m.name == rawMode).firstOrNull;
      options = GeneratorOptions.decode(await settings.generatorOptions());
      words = PassphraseOptions.decode(await settings.passphraseOptions());
    } on Object {
      return; // Okunamazsa varsayılanlarla devam.
    }
    if (!mounted || _touched) return;
    if (mode == null && options == null && words == null) return;
    setState(() {
      _mode = mode ?? _mode;
      _options = options ?? _options;
      _words = words ?? _words;
      _password = _generate();
    });
  }

  String _generate() => switch (_mode) {
    GeneratorMode.random =>
      ref.read(passwordGeneratorProvider).generate(_options),
    GeneratorMode.words =>
      ref.read(passphraseGeneratorProvider).generate(_words),
  };

  /// Ayar yazma hatası üreticiyi etkilemez.
  void _save(Future<void> Function() write) =>
      unawaited(write().catchError((Object _) {}));

  void _setMode(GeneratorMode mode) {
    _touched = true;
    _save(() => ref.read(appSettingsProvider).setGeneratorMode(mode.name));
    setState(() {
      _mode = mode;
      _password = _generate();
    });
  }

  void _update(GeneratorOptions next) {
    // En az bir grup seçili kalmalı.
    if (!next.hasAnySet) return;
    _touched = true;
    _save(
      () => ref.read(appSettingsProvider).setGeneratorOptions(next.encode()),
    );
    setState(() {
      _options = next;
      _password = _generate();
    });
  }

  void _updateWords(PassphraseOptions next) {
    _touched = true;
    _save(
      () => ref.read(appSettingsProvider).setPassphraseOptions(next.encode()),
    );
    setState(() {
      _words = next;
      _password = _generate();
    });
  }

  void _regenerate() => setState(() => _password = _generate());

  @override
  void dispose() {
    _password = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final passphrase = ref.read(passphraseGeneratorProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<GeneratorMode>(
          key: GeneratorPanel.modeKey,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: GeneratorMode.random,
              icon: const Icon(Icons.password),
              label: Text(
                l10n.generatorModeRandom,
                key: const Key('gen_mode_random'),
              ),
            ),
            ButtonSegment(
              value: GeneratorMode.words,
              icon: const Icon(Icons.text_fields),
              label: Text(
                l10n.generatorModeWords,
                key: const Key('gen_mode_words'),
              ),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => _setMode(s.first),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
            child: Row(
              children: [
                Expanded(
                  // Yeniden üretince kısa bir geçiş animasyonu.
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(
                      context,
                      const Duration(milliseconds: 320),
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.94, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: AppMotion.spring,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                    child: Align(
                      key: ValueKey(_password),
                      alignment: Alignment.centerLeft,
                      child: ColoredPasswordText(
                        _password,
                        key: GeneratorPanel.passwordKey,
                        fontSize: _mode == GeneratorMode.words ? 18 : 22,
                      ),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  key: GeneratorPanel.regenerateKey,
                  tooltip: l10n.generatorRegenerate,
                  icon: const Icon(Icons.refresh),
                  onPressed: _regenerate,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Kelime kipinde güç karakterlerden değil, seçim uzayından
        // hesaplanır (karakter sayısına göre tahmin abartılı olurdu).
        if (_mode == GeneratorMode.words) ...[
          PasswordStrengthMeter(
            password: _password,
            bits: passphrase.entropyBits(_words),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.generatorEntropy(passphrase.entropyBits(_words).floor()),
            key: GeneratorPanel.entropyKey,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else
          PasswordStrengthMeter(password: _password),
        const SizedBox(height: 20),
        if (_mode == GeneratorMode.random)
          ..._randomOptions(l10n, theme)
        else
          ..._wordOptions(l10n, theme),
        const SizedBox(height: 16),
        widget.actions(context, _password),
      ],
    );
  }

  /// Uzunluk ya da kelime sayısı: başlık + büyük rakam + kaydırıcı.
  List<Widget> _countSlider({
    required ThemeData theme,
    required Key key,
    required String title,
    required String semantics,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) => [
    Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const Spacer(),
        Text(
          '$value',
          semanticsLabel: semantics,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    ),
    Slider(
      key: key,
      value: value.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      divisions: max - min,
      label: '$value',
      onChanged: (v) => onChanged(v.round()),
    ),
  ];

  List<Widget> _randomOptions(AppLocalizations l10n, ThemeData theme) {
    final o = _options;

    // Karakter grupları: tek satırda kısa, simgesel çipler.
    Widget charset(
      Key key,
      String label,
      String tooltip,
      bool value,
      GeneratorOptions next,
    ) => FilterChip(
      key: key,
      tooltip: tooltip,
      showCheckmark: false,
      // Seçili gruplar ana düğme renginde (belirgin); seçili olmayanlar sade.
      selectedColor: theme.colorScheme.primary,
      side: value ? BorderSide.none : null,
      label: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.monoFontFamily,
          fontWeight: FontWeight.w600,
          color: value ? theme.colorScheme.onPrimary : null,
        ),
      ),
      selected: value,
      onSelected: (_) => _update(next),
    );

    return [
      ..._countSlider(
        theme: theme,
        key: GeneratorPanel.lengthKey,
        title: l10n.generatorLengthLabel,
        semantics: l10n.generatorLength(o.length),
        value: o.length,
        min: GeneratorOptions.minLength,
        max: GeneratorOptions.maxLength,
        onChanged: (v) => _update(o.copyWith(length: v)),
      ),
      const SizedBox(height: 8),
      Text(l10n.generatorCharsets, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          charset(
            GeneratorPanel.upperKey,
            'ABC',
            l10n.generatorUppercase,
            o.uppercase,
            o.copyWith(uppercase: !o.uppercase),
          ),
          charset(
            GeneratorPanel.lowerKey,
            'abc',
            l10n.generatorLowercase,
            o.lowercase,
            o.copyWith(lowercase: !o.lowercase),
          ),
          charset(
            GeneratorPanel.digitsKey,
            '123',
            l10n.generatorDigits,
            o.digits,
            o.copyWith(digits: !o.digits),
          ),
          charset(
            GeneratorPanel.symbolsKey,
            '#\$%',
            l10n.generatorSymbols,
            o.symbols,
            o.copyWith(symbols: !o.symbols),
          ),
        ],
      ),
      const SizedBox(height: 4),
      SwitchListTile(
        key: GeneratorPanel.ambiguousKey,
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.generatorExcludeAmbiguous),
        value: o.excludeAmbiguous,
        onChanged: (_) =>
            _update(o.copyWith(excludeAmbiguous: !o.excludeAmbiguous)),
      ),
    ];
  }

  List<Widget> _wordOptions(AppLocalizations l10n, ThemeData theme) {
    final w = _words;
    return [
      ..._countSlider(
        theme: theme,
        key: GeneratorPanel.wordCountKey,
        title: l10n.generatorWordCount,
        semantics: l10n.generatorWordCountValue(w.wordCount),
        value: w.wordCount,
        min: PassphraseOptions.minWords,
        max: PassphraseOptions.maxWords,
        onChanged: (v) => _updateWords(w.copyWith(wordCount: v)),
      ),
      const SizedBox(height: 8),
      Text(l10n.generatorSeparator, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final s in PassphraseOptions.separators)
            ChoiceChip(
              key: GeneratorPanel.separatorKey(s),
              showCheckmark: false,
              selectedColor: theme.colorScheme.primary,
              side: w.separator == s ? BorderSide.none : null,
              label: Text(
                ' $s ',
                style: TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  fontWeight: FontWeight.w600,
                  color: w.separator == s ? theme.colorScheme.onPrimary : null,
                ),
              ),
              selected: w.separator == s,
              onSelected: (_) => _updateWords(w.copyWith(separator: s)),
            ),
        ],
      ),
      const SizedBox(height: 4),
      SwitchListTile(
        key: GeneratorPanel.capitalizeKey,
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.generatorCapitalize),
        value: w.capitalize,
        onChanged: (v) => _updateWords(w.copyWith(capitalize: v)),
      ),
      SwitchListTile(
        key: GeneratorPanel.numberKey,
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.generatorAddNumber),
        value: w.addNumber,
        onChanged: (v) => _updateWords(w.copyWith(addNumber: v)),
      ),
    ];
  }
}
