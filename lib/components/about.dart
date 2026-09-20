import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/portfolio.dart';

class About extends StatelessComponent {
  const About({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'about', classes: 'section section-alt', [
      div(classes: 'wrap about-grid', [
        h2(classes: 'section-title', [.text('About')]),
        div(classes: 'prose', [
          for (final paragraph in profile.about) p([.text(paragraph)]),
          h3(classes: 'list-title', [.text('Experience')]),
          dl(classes: 'facts', [
            for (final job in experience)
              div(classes: 'fact', [
                dt([.text(job.years)]),
                dd([
                  span(classes: 'fact-title', [.text('${job.role}, ${job.place}')]),
                  span([.text(job.note)]),
                ]),
              ]),
          ]),
          h3(classes: 'list-title', [.text('Skills')]),
          dl(classes: 'facts', [
            for (final skill in skills)
              div(classes: 'fact', [
                dt([.text(skill.area)]),
                dd([.text(skill.items)]),
              ]),
          ]),
        ]),
      ]),
    ]);
  }
}
