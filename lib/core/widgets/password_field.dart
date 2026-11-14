import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Göster/gizle düğmeli şifre alanı.
///
/// GÜVENLİK: Otomatik doldurma, öneri ve otomatik düzeltme kapalıdır;
/// klavye şifreyi öğrenmez / önbelleğe almaz (enableIMEPersonalizedLearning).
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? errorText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: const <String>[],
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
