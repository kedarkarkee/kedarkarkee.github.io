import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/portfolio.dart';

// The only interactive part of the page, so it is the only @client component.
// Everything else is pre-rendered HTML.
@client
class WorkSection extends StatefulComponent {
  const WorkSection({super.key});

  @override
  State<WorkSection> createState() => WorkSectionState();
}

class WorkSectionState extends State<WorkSection> {
  String selected = categories.first;

  @override
  Component build(BuildContext context) {
    final visible = selected == categories.first
        ? projects
        : projects.where((item) => item.category == selected).toList();

    return section(id: 'work', classes: 'section', [
      div(classes: 'wrap', [
        div(classes: 'work-head', [
          h2(classes: 'section-title', [.text('Selected work')]),
          div(
            classes: 'filters',
            attributes: {'role': 'group', 'aria-label': 'Filter projects'},
            [
              for (final category in categories)
                button(
                  classes: category == selected ? 'filter filter-active' : 'filter',
                  attributes: {
                    'type': 'button',
                    'aria-pressed': '${category == selected}',
                  },
                  onClick: () => setState(() => selected = category),
                  [.text(category)],
                ),
            ],
          ),
        ]),
        div(
          classes: 'project-list',
          attributes: {'aria-live': 'polite'},
          [
            for (final item in visible) ProjectRow(project: item, key: ValueKey(item.title)),
          ],
        ),
      ]),
    ]);
  }
}

class ProjectRow extends StatelessComponent {
  const ProjectRow({required this.project, super.key});

  final Project project;

  @override
  Component build(BuildContext context) {
    return a(
      classes: 'project',
      href: project.url,
      attributes: {'target': '_blank', 'rel': 'noopener noreferrer'},
      [
        span(
          classes: 'swatch tone-${project.tone}',
          attributes: {'aria-hidden': 'true'},
          [.text(project.title[0])],
        ),
        div(classes: 'project-main', [
          h3(classes: 'project-title', [.text(project.title)]),
          p(classes: 'project-summary', [.text(project.summary)]),
        ]),
        div(classes: 'project-meta', [
          span(classes: 'project-year', [.text('${project.year}')]),
          span(classes: 'project-tags', [.text(project.tags)]),
        ]),
      ],
    );
  }
}
