import 'package:flutter/material.dart';

import '../../../../core/widgets/entry_appearance.dart';
import '../../../../core/widgets/entry_avatar.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Kayıt görünümü (simge + renk) seçimi.
typedef EntryAppearance = ({String? icon, String? color});

/// Simge ve renk seçme paneli. "Tamam" ile seçimi döndürür; kapatılırsa
/// `null` (değişiklik yok).
Future<EntryAppearance?> showAppearanceSheet(
  BuildContext context, {
  required String title,
  required EntryAppearance initial,
}) => showModalBottomSheet<EntryAppearance>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _AppearanceSheet(title: title, initial: initial),
);

class _AppearanceSheet extends StatefulWidget {
  const _AppearanceSheet({required this.title, required this.initial});

  final String title;
  final EntryAppearance initial;

  @override
  State<_AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends State<_AppearanceSheet> {
  late String? _icon = widget.initial.icon;
  late String? _color = widget.initial.color;

  static const Key previewKey = Key('appearance_preview');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    // Seçenekler kaydırılır; "Tamam" her zaman altta görünür kalır.
    return Column(
      key: const Key('appearance_sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Canlı önizleme.
                Center(
                  child: EntryAvatar(
                    key: previewKey,
                    title: widget.title,
                    iconKey: _icon,
                    colorKey: _color,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.entryAppearanceIcon,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Choice(
                      key: const Key('appearance_icon_letter'),
                      tooltip: l10n.entryAppearanceLetter,
                      selected: _icon == null,
                      onTap: () => setState(() => _icon = null),
                      child: Text(
                        'Aa',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    for (final o in EntryAppearanceCatalog.icons)
                      _Choice(
                        key: Key('appearance_icon_${o.key}'),
                        tooltip: o.label(l10n),
                        selected: _icon == o.key,
                        onTap: () => setState(() => _icon = o.key),
                        child: Icon(o.icon, color: theme.colorScheme.onSurface),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.entryAppearanceColor,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Choice(
                      key: const Key('appearance_color_auto'),
                      tooltip: l10n.entryAppearanceAuto,
                      selected: _color == null,
                      onTap: () => setState(() => _color = null),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    for (final o in EntryAppearanceCatalog.colors)
                      _Choice(
                        key: Key('appearance_color_${o.key}'),
                        tooltip: o.label(l10n),
                        selected: _color == o.key,
                        fill: o.resolve(brightness).$1,
                        onTap: () => setState(() => _color = o.key),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: o.resolve(brightness).$2,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            10 + MediaQuery.paddingOf(context).bottom,
          ),
          // Büyük yazı boyutunda da taşmasın: sol düğme esner.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton(
                  key: const Key('appearance_reset'),
                  onPressed: () => setState(() {
                    _icon = null;
                    _color = null;
                  }),
                  child: Text(
                    l10n.entryAppearanceReset,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('appearance_done'),
                style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                onPressed: () =>
                    Navigator.pop(context, (icon: _icon, color: _color)),
                child: Text(l10n.entryAppearanceDone),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Yuvarlak seçim düğmesi; seçiliyken ana renkte halka.
class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    required this.child,
    this.fill,
  });

  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 26,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill ?? scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
