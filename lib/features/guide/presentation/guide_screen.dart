import 'package:flutter/material.dart';

import '../../../core/utils/turkish_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/guide_content.dart';

/// Kullanma Talimatı. Tamamen çevrimdışı; kasa verisine ERİŞMEZ ve kasa
/// kilitliyken de açılabilir.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key, this.sections = guideContentTr});

  final List<GuideSection> sections;

  static const Key searchKey = Key('guide_search');

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _query.trim();
    final visible = query.isEmpty
        ? widget.sections
        : widget.sections
              .where((s) => TurkishText.containsFolded(s.searchableText, query))
              .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.guideTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              key: GuideScreen.searchKey,
              controller: _search,
              hintText: l10n.guideSearchHint,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _search.clear();
                      _query = '';
                    }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.guideNoResults,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: visible.length,
                    itemBuilder: (context, i) => _SectionTile(
                      // Arama değişince eşleşen bölümler açık gelsin.
                      key: ValueKey('${visible[i].id}|${query.isNotEmpty}'),
                      section: visible[i],
                      index: widget.sections.indexOf(visible[i]) + 1,
                      expanded: query.isNotEmpty,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    super.key,
    required this.section,
    required this.index,
    required this.expanded,
  });

  final GuideSection section;
  final int index;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ExpansionTile(
      key: Key('guide_${section.id}'),
      initiallyExpanded: expanded,
      leading: Icon(section.icon, color: theme.colorScheme.primary),
      title: Text('$index. ${section.title}'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.summary, style: theme.textTheme.bodyMedium),
        if (section.steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.guideStepsTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (var i = 0; i < section.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    child: Text('${i + 1}', style: theme.textTheme.labelSmall),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(section.steps[i])),
                ],
              ),
            ),
        ],
        if (section.tips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.guideTipsTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final tip in section.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
        ],
        for (final f in section.faq)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.question, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(f.answer),
              ],
            ),
          ),
      ],
    );
  }
}
