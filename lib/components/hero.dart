import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/portfolio.dart';

class Hero extends StatelessComponent {
  const Hero({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'top', classes: 'hero', [
      div(classes: 'wrap', [
        h1(classes: 'hero-title', [
          for (final line in profile.headline)
            span(classes: 'hero-line', [
              span([.text(line)]),
            ]),
        ]),
        div(classes: 'hero-body', [
          p(classes: 'hero-lead', [.text(profile.intro)]),
          div(classes: 'hero-actions', [
            a(classes: 'btn btn-solid', href: '#work', [.text('See my work')]),
            a(classes: 'btn btn-line', href: '#contact', [.text('Get in touch')]),
          ]),
        ]),
        dl(classes: 'hero-meta', [
          for (final fact in profile.facts)
            div([
              dt([.text(fact.label)]),
              dd([.text(fact.value)]),
            ]),
        ]),
      ]),
    ]);
  }
}
